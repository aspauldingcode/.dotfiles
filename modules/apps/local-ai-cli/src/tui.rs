//! Interactive rice TUI for local Ollama chat (ratatui / crossterm).

use std::io::{self, Stdout};
use std::path::PathBuf;
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use crossterm::event::{
    self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent, KeyEventKind,
    KeyModifiers, MouseEvent, MouseEventKind,
};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Padding, Paragraph, Wrap};
use ratatui::{Frame, Terminal};

use crate::{base_url, chat_turn, run_shell, ChatMsg, AGENT_SYSTEM_PROMPT};

#[derive(Clone, Copy, PartialEq, Eq)]
enum Role {
    User,
    Assistant,
    System,
    Shell,
}

struct Bubble {
    role: Role,
    text: String,
}

struct Palette {
    bg: Color,
    surface: Color,
    border: Color,
    fg: Color,
    muted: Color,
    accent: Color,
    user: Color,
    assistant: Color,
    danger: Color,
}

impl Default for Palette {
    fn default() -> Self {
        Self {
            bg: Color::Rgb(0x1b, 0x27, 0x3b),
            surface: Color::Rgb(0x3d, 0x48, 0x5a),
            border: Color::Rgb(0x5f, 0x69, 0x79),
            fg: Color::Rgb(0xc5, 0xcc, 0xd6),
            muted: Color::Rgb(0x81, 0x8a, 0x98),
            accent: Color::Rgb(0x8b, 0xa4, 0xb0),
            user: Color::Rgb(0xa3, 0xbe, 0x8c),
            assistant: Color::Rgb(0x88, 0xc0, 0xd0),
            danger: Color::Rgb(0xbf, 0x61, 0x6a),
        }
    }
}

fn parse_hex(s: &str) -> Option<Color> {
    let h = s.trim().trim_start_matches('#');
    if h.len() != 6 {
        return None;
    }
    let r = u8::from_str_radix(&h[0..2], 16).ok()?;
    let g = u8::from_str_radix(&h[2..4], 16).ok()?;
    let b = u8::from_str_radix(&h[4..6], 16).ok()?;
    Some(Color::Rgb(r, g, b))
}

fn load_palette() -> Palette {
    let mut pal = Palette::default();
    let path = env_colors_toml();
    let Ok(text) = std::fs::read_to_string(&path) else {
        return pal;
    };
    let mut in_palette = false;
    let mut map = std::collections::HashMap::<String, String>::new();
    for line in text.lines() {
        let t = line.trim();
        if t.starts_with('[') {
            in_palette = t == "[palette]";
            continue;
        }
        if !in_palette || t.is_empty() || t.starts_with('#') {
            continue;
        }
        if let Some((k, v)) = t.split_once('=') {
            let mut val = v.trim().trim_matches('"').to_string();
            if !val.starts_with('#') && val.len() == 6 {
                val = format!("#{val}");
            }
            map.insert(k.trim().to_string(), val);
        }
    }
    if let Some(c) = map.get("base00").and_then(|h| parse_hex(h)) {
        pal.bg = c;
    }
    if let Some(c) = map.get("base01").and_then(|h| parse_hex(h)) {
        pal.surface = c;
    }
    if let Some(c) = map.get("base02").and_then(|h| parse_hex(h)) {
        pal.border = c;
    }
    if let Some(c) = map.get("base03").and_then(|h| parse_hex(h)) {
        pal.muted = c;
    }
    if let Some(c) = map.get("base05").and_then(|h| parse_hex(h)) {
        pal.fg = c;
    }
    if let Some(c) = map.get("base0D").and_then(|h| parse_hex(h)) {
        pal.accent = c;
        pal.assistant = c;
    }
    if let Some(c) = map.get("base0B").and_then(|h| parse_hex(h)) {
        pal.user = c;
    }
    if let Some(c) = map.get("base08").and_then(|h| parse_hex(h)) {
        pal.danger = c;
    }
    pal
}

fn env_colors_toml() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_COLORS_TOML") {
        return PathBuf::from(p);
    }
    if let Ok(home) = std::env::var("HOME") {
        return PathBuf::from(home).join("colors.toml");
    }
    PathBuf::from("colors.toml")
}

enum WorkerMsg {
    Assistant(String),
    Shell { cmd: String, output: String },
    Done,
    Failed(String),
}

struct App {
    model: String,
    base: String,
    bubbles: Vec<Bubble>,
    input: String,
    cursor: usize,
    /// Lines up from the bottom of the transcript (0 = pinned to newest).
    scroll_from_bottom: u16,
    status: String,
    busy: bool,
    rx: Option<Receiver<WorkerMsg>>,
    tick: Instant,
    spinner: usize,
    palette: Palette,
    should_quit: bool,
}

impl App {
    fn new(model: String) -> Self {
        let base = base_url();
        Self {
            model,
            base: base.clone(),
            bubbles: vec![Bubble {
                role: Role::System,
                text: format!(
                    "local ollama · {base}\nnative run_shell tools · ```run``` fallback\n/run <cmd> · esc quit · ^l clear · ↑↓ / mouse scroll"
                ),
            }],
            input: String::new(),
            cursor: 0,
            scroll_from_bottom: 0,
            status: "ready".into(),
            busy: false,
            rx: None,
            tick: Instant::now(),
            spinner: 0,
            palette: load_palette(),
            should_quit: false,
        }
    }

    fn api_history(&self) -> Vec<ChatMsg> {
        let mut msgs = vec![ChatMsg {
            role: "system".into(),
            content: AGENT_SYSTEM_PROMPT.into(),
            tool_calls: Vec::new(),
        }];
        let mut i = 0;
        while i < self.bubbles.len() {
            match self.bubbles[i].role {
                Role::System => {
                    i += 1;
                }
                Role::User => {
                    msgs.push(ChatMsg::user(self.bubbles[i].text.clone()));
                    i += 1;
                }
                Role::Assistant => {
                    let content = self.bubbles[i].text.clone();
                    i += 1;
                    let mut tools = Vec::new();
                    let mut results = Vec::new();
                    while i < self.bubbles.len() && self.bubbles[i].role == Role::Shell {
                        let (cmd, output) = split_shell_bubble(&self.bubbles[i].text);
                        tools.push(crate::ToolCall {
                            name: "run_shell".into(),
                            arguments: serde_json::json!({ "command": cmd }),
                        });
                        results.push(output);
                        i += 1;
                    }
                    if tools.is_empty() {
                        msgs.push(ChatMsg::assistant(content));
                    } else {
                        msgs.push(ChatMsg::assistant_with_tools(content, tools));
                        for output in results {
                            msgs.push(ChatMsg::tool_result(output));
                        }
                    }
                }
                Role::Shell => {
                    let (cmd, output) = split_shell_bubble(&self.bubbles[i].text);
                    msgs.push(ChatMsg::assistant_with_tools(
                        String::new(),
                        vec![crate::ToolCall {
                            name: "run_shell".into(),
                            arguments: serde_json::json!({ "command": cmd }),
                        }],
                    ));
                    msgs.push(ChatMsg::tool_result(output));
                    i += 1;
                }
            }
        }
        msgs
    }

    fn scroll_by(&mut self, delta: i32) {
        if delta > 0 {
            self.scroll_from_bottom = self.scroll_from_bottom.saturating_add(delta as u16);
        } else {
            self.scroll_from_bottom = self
                .scroll_from_bottom
                .saturating_sub((-delta) as u16);
        }
    }

    fn submit(&mut self) {
        if self.busy {
            return;
        }
        let prompt = self.input.trim().to_string();
        if prompt.is_empty() {
            return;
        }
        self.input.clear();
        self.cursor = 0;

        // Direct shell: `/run whoami` or `!whoami`
        if let Some(cmd) = prompt
            .strip_prefix("/run ")
            .or_else(|| prompt.strip_prefix("!"))
            .map(str::trim)
            .filter(|c| !c.is_empty())
        {
            self.bubbles.push(Bubble {
                role: Role::User,
                text: prompt.clone(),
            });
            let output = run_shell(cmd);
            self.bubbles.push(Bubble {
                role: Role::Shell,
                text: format!("$ {cmd}\n{output}"),
            });
            self.status = "ready".into();
            return;
        }

        self.bubbles.push(Bubble {
            role: Role::User,
            text: prompt,
        });
        self.busy = true;
        self.status = "thinking".into();
        self.scroll_from_bottom = 0;

        let base = self.base.clone();
        let model = self.model.clone();
        let mut history = self.api_history();
        let (tx, rx) = mpsc::channel();
        self.rx = Some(rx);
        thread::spawn(move || {
            const MAX_ROUNDS: usize = 8;
            for _ in 0..MAX_ROUNDS {
                let turn = match chat_turn(&base, &model, &history) {
                    Ok(t) => t,
                    Err(e) => {
                        let _ = tx.send(WorkerMsg::Failed(e.to_string()));
                        return;
                    }
                };

                let content = turn.content.trim().to_string();
                if !content.is_empty() {
                    let _ = tx.send(WorkerMsg::Assistant(content.clone()));
                }

                if turn.tool_calls.is_empty() {
                    if content.is_empty() {
                        let _ = tx.send(WorkerMsg::Failed("empty model response".into()));
                    } else {
                        let _ = tx.send(WorkerMsg::Done);
                    }
                    return;
                }

                history.push(ChatMsg::assistant_with_tools(
                    content,
                    turn.tool_calls.clone(),
                ));

                let mut ran_any = false;
                for tc in &turn.tool_calls {
                    let Some(cmd) = tc.shell_command() else {
                        let _ = tx.send(WorkerMsg::Failed(format!(
                            "unsupported tool call: {}",
                            tc.name
                        )));
                        return;
                    };
                    ran_any = true;
                    let output = run_shell(&cmd);
                    let _ = tx.send(WorkerMsg::Shell {
                        cmd: cmd.clone(),
                        output: output.clone(),
                    });
                    history.push(ChatMsg::tool_result(output));
                }
                if !ran_any {
                    let _ = tx.send(WorkerMsg::Done);
                    return;
                }
            }
            let _ = tx.send(WorkerMsg::Done);
        });
    }

    fn poll_worker(&mut self) {
        loop {
            let Some(rx) = self.rx.as_ref() else {
                return;
            };
            match rx.try_recv() {
                Ok(WorkerMsg::Assistant(reply)) => {
                    self.bubbles.push(Bubble {
                        role: Role::Assistant,
                        text: reply,
                    });
                    self.status = "thinking".into();
                }
                Ok(WorkerMsg::Shell { cmd, output }) => {
                    self.bubbles.push(Bubble {
                        role: Role::Shell,
                        text: format!("$ {cmd}\n{output}"),
                    });
                    self.status = "running".into();
                }
                Ok(WorkerMsg::Done) => {
                    self.busy = false;
                    self.rx = None;
                    self.status = "ready".into();
                    return;
                }
                Ok(WorkerMsg::Failed(err)) => {
                    self.bubbles.push(Bubble {
                        role: Role::System,
                        text: format!("✗ error · {err}"),
                    });
                    self.busy = false;
                    self.rx = None;
                    self.status = "error".into();
                    return;
                }
                Err(TryRecvError::Empty) => return,
                Err(TryRecvError::Disconnected) => {
                    self.busy = false;
                    self.rx = None;
                    self.status = "error".into();
                    return;
                }
            }
        }
    }

    fn clear_chat(&mut self) {
        if self.busy {
            return;
        }
        self.bubbles.retain(|b| b.role == Role::System);
        if self.bubbles.is_empty() {
            self.bubbles.push(Bubble {
                role: Role::System,
                text: "cleared · new session".into(),
            });
        }
        self.status = "cleared".into();
    }

    fn on_key(&mut self, key: KeyEvent) {
        if key.kind != KeyEventKind::Press {
            return;
        }
        match (key.modifiers, key.code) {
            (KeyModifiers::CONTROL, KeyCode::Char('c')) | (_, KeyCode::Esc) => {
                self.should_quit = true;
            }
            (KeyModifiers::CONTROL, KeyCode::Char('l')) => self.clear_chat(),
            (_, KeyCode::Enter) => self.submit(),
            (_, KeyCode::Backspace) => {
                if self.cursor > 0 {
                    let idx = prev_char_boundary(&self.input, self.cursor);
                    self.input.drain(idx..self.cursor);
                    self.cursor = idx;
                }
            }
            (_, KeyCode::Delete) => {
                if self.cursor < self.input.len() {
                    let end = next_char_boundary(&self.input, self.cursor);
                    self.input.drain(self.cursor..end);
                }
            }
            (_, KeyCode::Left) => {
                self.cursor = prev_char_boundary(&self.input, self.cursor);
            }
            (_, KeyCode::Right) => {
                self.cursor = next_char_boundary(&self.input, self.cursor);
            }
            (_, KeyCode::Home) => self.cursor = 0,
            (_, KeyCode::End) => self.cursor = self.input.len(),
            // Chat scroll: up/PageUp → older (away from bottom); down → newer.
            (_, KeyCode::Up) => self.scroll_by(1),
            (_, KeyCode::Down) => self.scroll_by(-1),
            (_, KeyCode::PageUp) => self.scroll_by(8),
            (_, KeyCode::PageDown) => self.scroll_by(-8),
            (KeyModifiers::CONTROL, KeyCode::Char('u')) => {
                self.input.clear();
                self.cursor = 0;
            }
            (_, KeyCode::Char(c)) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.input.insert(self.cursor, c);
                self.cursor += c.len_utf8();
            }
            _ => {}
        }
    }

    fn on_mouse(&mut self, mouse: MouseEvent) {
        match mouse.kind {
            MouseEventKind::ScrollUp => self.scroll_by(3),
            MouseEventKind::ScrollDown => self.scroll_by(-3),
            _ => {}
        }
    }
}

fn split_shell_bubble(text: &str) -> (String, String) {
    let cmd_line = text.lines().next().unwrap_or("$");
    let cmd = cmd_line
        .strip_prefix("$ ")
        .unwrap_or(cmd_line)
        .to_string();
    let output = text
        .split_once('\n')
        .map(|(_, rest)| rest.to_string())
        .unwrap_or_default();
    (cmd, output)
}

fn prev_char_boundary(s: &str, idx: usize) -> usize {
    if idx == 0 {
        return 0;
    }
    let mut i = idx - 1;
    while i > 0 && !s.is_char_boundary(i) {
        i -= 1;
    }
    i
}

fn next_char_boundary(s: &str, idx: usize) -> usize {
    if idx >= s.len() {
        return s.len();
    }
    let mut i = idx + 1;
    while i < s.len() && !s.is_char_boundary(i) {
        i += 1;
    }
    i
}

fn spinner_frame(i: usize) -> &'static str {
    const FRAMES: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
    FRAMES[i % FRAMES.len()]
}

fn build_lines(app: &App) -> Vec<Line<'static>> {
    let mut lines = Vec::new();
    for bubble in &app.bubbles {
        let (glyph, label, color) = match bubble.role {
            Role::User => ("❯", "you", app.palette.user),
            Role::Assistant => ("◆", "model", app.palette.assistant),
            Role::Shell => ("$", "shell", app.palette.accent),
            Role::System => (
                "✦",
                "sys",
                if bubble.text.starts_with('✗') {
                    app.palette.danger
                } else {
                    app.palette.muted
                },
            ),
        };
        lines.push(Line::from(vec![
            Span::styled(
                format!("{glyph} "),
                Style::default().fg(color).add_modifier(Modifier::BOLD),
            ),
            Span::styled(
                format!("{label}"),
                Style::default()
                    .fg(color)
                    .add_modifier(Modifier::BOLD | Modifier::DIM),
            ),
        ]));
        for raw in bubble.text.split('\n') {
            lines.push(Line::from(Span::styled(
                format!("  {raw}"),
                Style::default().fg(app.palette.fg),
            )));
        }
        lines.push(Line::from(""));
    }
    if app.busy {
        lines.push(Line::from(vec![
            Span::styled(
                format!("{} ", spinner_frame(app.spinner)),
                Style::default().fg(app.palette.accent),
            ),
            Span::styled(
                "generating…",
                Style::default()
                    .fg(app.palette.muted)
                    .add_modifier(Modifier::ITALIC),
            ),
        ]));
    }
    lines
}

fn ui(frame: &mut Frame, app: &App) {
    let pal = &app.palette;
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(5),
            Constraint::Length(3),
            Constraint::Length(1),
        ])
        .split(frame.area());

    let header = Paragraph::new(Line::from(vec![
        Span::styled("◈ ", Style::default().fg(pal.accent)),
        Span::styled(
            "chat",
            Style::default()
                .fg(pal.fg)
                .add_modifier(Modifier::BOLD),
        ),
        Span::styled(" · ", Style::default().fg(pal.muted)),
        Span::styled(&app.model, Style::default().fg(pal.assistant)),
        Span::styled(" · ", Style::default().fg(pal.muted)),
        Span::styled(&app.status, Style::default().fg(pal.muted)),
    ]))
    .block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(pal.border))
            .title(Span::styled(" dendritic ", Style::default().fg(pal.accent)))
            .padding(Padding::horizontal(1)),
    )
    .style(Style::default().bg(pal.bg));
    frame.render_widget(header, chunks[0]);

    let lines = build_lines(app);
    let view_h = chunks[1].height.saturating_sub(2) as usize;
    let total = lines.len();
    let max_from_bottom = total.saturating_sub(view_h.max(1));
    let from_bottom = (app.scroll_from_bottom as usize).min(max_from_bottom);
    let scroll_top = (max_from_bottom - from_bottom) as u16;
    let chat = Paragraph::new(lines)
        .wrap(Wrap { trim: false })
        .scroll((scroll_top, 0))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(pal.border))
                .title(Span::styled(" transcript ", Style::default().fg(pal.muted)))
                .padding(Padding::horizontal(1)),
        )
        .style(Style::default().bg(pal.bg).fg(pal.fg));
    frame.render_widget(chat, chunks[1]);

    let (before, after) = app.input.split_at(app.cursor.min(app.input.len()));
    let input_line = if app.busy {
        Line::from(Span::styled(
            "  … waiting on model",
            Style::default()
                .fg(pal.muted)
                .add_modifier(Modifier::ITALIC),
        ))
    } else {
        Line::from(vec![
            Span::styled("❯ ", Style::default().fg(pal.user)),
            Span::styled(before.to_string(), Style::default().fg(pal.fg)),
            Span::styled("▌", Style::default().fg(pal.accent)),
            Span::styled(after.to_string(), Style::default().fg(pal.fg)),
        ])
    };
    let input = Paragraph::new(input_line).block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(if app.busy {
                pal.muted
            } else {
                pal.accent
            }))
            .title(Span::styled(" prompt ", Style::default().fg(pal.user)))
            .padding(Padding::horizontal(1)),
    )
    .style(Style::default().bg(pal.surface));
    frame.render_widget(input, chunks[2]);

    let help = Paragraph::new(Line::from(vec![
        Span::styled(" ↵", Style::default().fg(pal.accent)),
        Span::styled(" send  ", Style::default().fg(pal.muted)),
        Span::styled("esc", Style::default().fg(pal.accent)),
        Span::styled(" quit  ", Style::default().fg(pal.muted)),
        Span::styled("^l", Style::default().fg(pal.accent)),
        Span::styled(" clear  ", Style::default().fg(pal.muted)),
        Span::styled("/run", Style::default().fg(pal.accent)),
        Span::styled(" shell  ", Style::default().fg(pal.muted)),
        Span::styled("↑↓", Style::default().fg(pal.accent)),
        Span::styled(" scroll", Style::default().fg(pal.muted)),
    ]))
    .style(Style::default().bg(pal.bg));
    frame.render_widget(help, chunks[3]);
}

fn setup_terminal() -> Result<Terminal<CrosstermBackend<Stdout>>> {
    enable_raw_mode().context("enable raw mode")?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture).context("enter alt screen")?;
    let backend = CrosstermBackend::new(stdout);
    Terminal::new(backend).context("create terminal")
}

fn restore_terminal(terminal: &mut Terminal<CrosstermBackend<Stdout>>) -> Result<()> {
    disable_raw_mode().ok();
    execute!(
        terminal.backend_mut(),
        DisableMouseCapture,
        LeaveAlternateScreen
    )
    .ok();
    terminal.show_cursor().ok();
    Ok(())
}

/// Run the interactive chat TUI. Returns when the user quits.
pub fn run(model: String) -> Result<()> {
    let mut terminal = setup_terminal()?;
    let mut app = App::new(model);
    let tick_rate = Duration::from_millis(80);
    let result = (|| -> Result<()> {
        loop {
            app.poll_worker();
            if app.tick.elapsed() >= tick_rate {
                app.tick = Instant::now();
                if app.busy {
                    app.spinner = app.spinner.wrapping_add(1);
                }
            }
            terminal.draw(|f| ui(f, &app))?;
            if app.should_quit {
                break;
            }
            if event::poll(Duration::from_millis(50))? {
                match event::read()? {
                    Event::Key(key) => app.on_key(key),
                    Event::Mouse(mouse) => app.on_mouse(mouse),
                    Event::Resize(_, _) => {}
                    _ => {}
                }
            }
        }
        Ok(())
    })();
    restore_terminal(&mut terminal)?;
    result
}
