//! Pass store sync tray — iced UI + tray-icon menubar (Darwin / Linux).
use iced::widget::{button, column, container, row, text, Space};
use iced::{
    time, window, Alignment, Color, Element, Length, Subscription, Task, Theme,
};
use serde::Deserialize;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::Arc;
use std::time::Duration;
use tray_icon::menu::{Menu, MenuEvent, MenuItem, PredefinedMenuItem};
use tray_icon::{Icon, TrayIcon, TrayIconBuilder};

#[derive(Debug, Clone, Default, Deserialize)]
struct SyncStatus {
    #[serde(default = "default_state")]
    state: String,
    #[serde(default = "default_direction")]
    direction: String,
    #[serde(default)]
    message: String,
    #[serde(default)]
    updated_at: Option<String>,
    #[serde(default)]
    ahead_behind: Option<String>,
    #[serde(default)]
    error: Option<String>,
    #[serde(default)]
    materialized: Vec<String>,
    #[serde(default)]
    last_materialize_at: Option<String>,
}

fn default_state() -> String {
    "idle".into()
}
fn default_direction() -> String {
    "none".into()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum IconKind {
    Idle,
    Up,
    Down,
    Error,
    Rebuild,
}

struct Env {
    status_file: PathBuf,
    lock_dir: PathBuf,
    sync_script: String,
    materialize_script: String,
    password_store_dir: String,
    sync_log: PathBuf,
}

impl Env {
    fn from_env() -> Self {
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
        let cache = home.join(".cache");
        Self {
            status_file: std::env::var_os("PASS_STORE_SYNC_STATUS")
                .map(PathBuf::from)
                .unwrap_or_else(|| cache.join("pass-store-sync.status")),
            lock_dir: std::env::var_os("PASS_STORE_SYNC_LOCK")
                .map(PathBuf::from)
                .unwrap_or_else(|| cache.join("pass-store-sync.lock")),
            sync_script: std::env::var("PASS_STORE_SYNC_SCRIPT").unwrap_or_default(),
            materialize_script: std::env::var("PASS_MATERIALIZE_SCRIPT").unwrap_or_default(),
            password_store_dir: std::env::var("PASSWORD_STORE_DIR")
                .unwrap_or_else(|_| home.join(".password-store").display().to_string()),
            sync_log: cache.join("pass-store-sync.log"),
        }
    }
}

struct PassTray {
    env: Arc<Env>,
    status: SyncStatus,
    rebuilding: bool,
    headline: String,
    detail: String,
    mat_line: String,
    icon_kind: IconKind,
    window_visible: bool,
    tray: Option<TrayIcon>,
    // Keep menu items alive for id matching.
    item_show: MenuItem,
    item_pull: MenuItem,
    item_mat: MenuItem,
    item_qtpass: MenuItem,
    item_log: MenuItem,
    item_quit: MenuItem,
}

#[derive(Debug, Clone)]
enum Message {
    Tick,
    Pull,
    Materialize,
    OpenQtPass,
    OpenLog,
    ShowWindow,
    HideWindow,
    Quit,
}

fn load_status(path: &Path) -> SyncStatus {
    match std::fs::read_to_string(path) {
        Ok(raw) => serde_json::from_str(&raw).unwrap_or_else(|_| SyncStatus {
            state: "error".into(),
            direction: "none".into(),
            message: "status unreadable".into(),
            error: Some("bad status json".into()),
            ..Default::default()
        }),
        Err(_) => SyncStatus {
            message: "no status yet".into(),
            ..Default::default()
        },
    }
}

fn rebuild_running() -> bool {
    let out = Command::new("ps")
        .args(["-ax", "-o", "command="])
        .output()
        .ok();
    let Some(out) = out else {
        return false;
    };
    let text = String::from_utf8_lossy(&out.stdout);
    const PATS: &[&str] = &[
        "nh darwin",
        "nh os",
        "darwin-rebuild",
        "nixos-rebuild",
        "nix-darwin-rebuild",
    ];
    for line in text.lines() {
        let low = line.to_lowercase();
        if low.contains("pass-store-tray") {
            continue;
        }
        if PATS.iter().any(|p| low.contains(p)) {
            return true;
        }
    }
    false
}

fn icon_kind(status: &SyncStatus, rebuilding: bool, lock: bool) -> IconKind {
    if rebuilding {
        return IconKind::Rebuild;
    }
    if status.error.as_ref().is_some_and(|e| !e.is_empty()) || status.state == "error" {
        return IconKind::Error;
    }
    if status.state == "uploading" || (lock && status.direction == "up") {
        return IconKind::Up;
    }
    if status.state == "downloading" || (lock && status.direction == "down") {
        return IconKind::Down;
    }
    if status.state != "idle" && status.direction == "up" {
        return IconKind::Up;
    }
    if status.state != "idle" && status.direction == "down" {
        return IconKind::Down;
    }
    IconKind::Idle
}

/// Paint a simple 32×32 RGBA glyph for the tray.
fn make_icon(kind: IconKind) -> Icon {
    let size = 32u32;
    let mut rgba = vec![0u8; (size * size * 4) as usize];
    let (r, g, b) = match kind {
        IconKind::Idle => (0x22, 0xc5, 0x5e),
        IconKind::Up | IconKind::Down => (0x3b, 0x82, 0xf6),
        IconKind::Error => (0xef, 0x44, 0x44),
        IconKind::Rebuild => (0xf5, 0x9e, 0x0b),
    };
    let put = |rgba: &mut [u8], x: i32, y: i32| {
        if x < 0 || y < 0 || x >= size as i32 || y >= size as i32 {
            return;
        }
        let i = ((y as u32 * size + x as u32) * 4) as usize;
        rgba[i] = r;
        rgba[i + 1] = g;
        rgba[i + 2] = b;
        rgba[i + 3] = 255;
    };
    let fill_rect = |rgba: &mut [u8], x0: i32, y0: i32, x1: i32, y1: i32| {
        for y in y0..y1 {
            for x in x0..x1 {
                put(rgba, x, y);
            }
        }
    };
    match kind {
        IconKind::Up => {
            // Arrow up triangle + stem
            for y in 4..16 {
                let half = (y - 4) / 2;
                for x in (16 - half)..(16 + half) {
                    put(&mut rgba, x, y);
                }
            }
            fill_rect(&mut rgba, 13, 14, 19, 28);
        }
        IconKind::Down => {
            for y in 16..28 {
                let half = (28 - y) / 2;
                for x in (16 - half)..(16 + half) {
                    put(&mut rgba, x, y);
                }
            }
            fill_rect(&mut rgba, 13, 4, 19, 18);
        }
        IconKind::Error => {
            fill_rect(&mut rgba, 14, 6, 18, 20);
            fill_rect(&mut rgba, 14, 22, 18, 26);
        }
        IconKind::Rebuild => {
            // thick ring segment
            for y in 4..28 {
                for x in 4..28 {
                    let dx = x - 16;
                    let dy = y - 16;
                    let d2 = dx * dx + dy * dy;
                    if (64..121).contains(&d2) && !(x > 16 && y < 16) {
                        put(&mut rgba, x, y);
                    }
                }
            }
            fill_rect(&mut rgba, 16, 4, 26, 10);
        }
        IconKind::Idle => {
            // check mark
            for t in 0..10 {
                put(&mut rgba, 8 + t, 16 + t / 2);
                put(&mut rgba, 8 + t, 17 + t / 2);
            }
            for t in 0..16 {
                put(&mut rgba, 18 + t, 20 - t);
                put(&mut rgba, 18 + t, 21 - t);
            }
        }
    }
    Icon::from_rgba(rgba, size, size).expect("icon rgba")
}

fn run_bg(program: &str, args: &[&str], extra_env: &[(&str, &str)]) {
    if program.is_empty() {
        return;
    }
    let mut cmd = Command::new(program);
    cmd.args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    for (k, v) in extra_env {
        cmd.env(k, v);
    }
    let _ = cmd.spawn();
}

impl PassTray {
    fn new() -> (Self, Task<Message>) {
        let env = Arc::new(Env::from_env());

        let item_show = MenuItem::new("Show status", true, None);
        let item_pull = MenuItem::new("Pull now", true, None);
        let item_mat = MenuItem::new("Rematerialize secrets", true, None);
        let item_qtpass = MenuItem::new("Open QtPass", true, None);
        let item_log = MenuItem::new("Open sync log", true, None);
        let item_quit = MenuItem::new("Quit", true, None);

        let menu = Menu::new();
        let _ = menu.append(&item_show);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&item_pull);
        let _ = menu.append(&item_mat);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&item_qtpass);
        let _ = menu.append(&item_log);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&item_quit);

        let tray = TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip("pass store sync")
            .with_icon(make_icon(IconKind::Idle))
            .build()
            .ok();

        let mut app = Self {
            env,
            status: SyncStatus::default(),
            rebuilding: false,
            headline: "…".into(),
            detail: String::new(),
            mat_line: String::new(),
            icon_kind: IconKind::Idle,
            window_visible: true,
            tray,
            item_show,
            item_pull,
            item_mat,
            item_qtpass,
            item_log,
            item_quit,
        };
        app.refresh();
        (app, Task::none())
    }

    fn refresh(&mut self) {
        self.status = load_status(&self.env.status_file);
        self.rebuilding = rebuild_running();
        let lock = self.env.lock_dir.exists();
        let kind = icon_kind(&self.status, self.rebuilding, lock);
        if kind != self.icon_kind {
            self.icon_kind = kind;
            if let Some(tray) = &self.tray {
                let _ = tray.set_icon(Some(make_icon(kind)));
            }
        }

        let err = self.status.error.as_deref().filter(|e| !e.is_empty());
        self.headline = if self.rebuilding {
            "Rebuilding system…".into()
        } else if lock {
            format!("Syncing ({})…", self.status.direction)
        } else if let Some(e) = err {
            format!("Error: {e}")
        } else {
            format!("{} · {}", self.status.state, self.status.direction)
        };

        let ab = self.status.ahead_behind.as_deref().unwrap_or("unknown");
        let updated = self.status.updated_at.as_deref().unwrap_or("—");
        self.detail = format!("{} · {} · {}", self.status.message, ab, updated);

        let mats = if self.status.materialized.is_empty() {
            "(none)".into()
        } else {
            self.status.materialized.join(", ")
        };
        let last_mat = self
            .status
            .last_materialize_at
            .as_deref()
            .unwrap_or("—");
        self.mat_line = format!("Materialized: {mats} @ {last_mat}");

        if let Some(tray) = &self.tray {
            let _ = tray.set_tooltip(Some(format!("pass sync: {}\n{}", self.headline, self.status.message)));
        }
    }

    fn poll_menu(&self) -> Option<Message> {
        let Ok(ev) = MenuEvent::receiver().try_recv() else {
            return None;
        };
        let id = ev.id;
        if id == self.item_show.id() {
            Some(Message::ShowWindow)
        } else if id == self.item_pull.id() {
            Some(Message::Pull)
        } else if id == self.item_mat.id() {
            Some(Message::Materialize)
        } else if id == self.item_qtpass.id() {
            Some(Message::OpenQtPass)
        } else if id == self.item_log.id() {
            Some(Message::OpenLog)
        } else if id == self.item_quit.id() {
            Some(Message::Quit)
        } else {
            None
        }
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        if let Some(msg) = self.poll_menu() {
            // Drain one menu event first when tick fires; also handle explicit.
            if matches!(message, Message::Tick) {
                return self.update(msg);
            }
        }

        match message {
            Message::Tick => {
                while let Some(msg) = self.poll_menu() {
                    let _ = self.update(msg);
                }
                self.refresh();
                Task::none()
            }
            Message::Pull => {
                run_bg(
                    "bash",
                    &[&self.env.sync_script],
                    &[
                        ("PASS_STORE_SYNC_MODE", "pull"),
                        ("PASSWORD_STORE_DIR", &self.env.password_store_dir),
                    ],
                );
                Task::none()
            }
            Message::Materialize => {
                run_bg(
                    "bash",
                    &[&self.env.materialize_script],
                    &[("PASSWORD_STORE_DIR", &self.env.password_store_dir)],
                );
                Task::none()
            }
            Message::OpenQtPass => {
                #[cfg(target_os = "macos")]
                {
                    let _ = Command::new("open").args(["-a", "QtPass"]).spawn();
                }
                #[cfg(not(target_os = "macos"))]
                {
                    let _ = Command::new("qtpass").spawn();
                }
                Task::none()
            }
            Message::OpenLog => {
                let path = self.env.sync_log.display().to_string();
                #[cfg(target_os = "macos")]
                {
                    let _ = Command::new("open").args(["-t", &path]).spawn();
                }
                #[cfg(not(target_os = "macos"))]
                {
                    if Command::new("xdg-open").arg(&path).spawn().is_err() {
                        let _ = Command::new("xdg-open").arg(&path).spawn();
                    }
                }
                Task::none()
            }
            Message::ShowWindow => {
                self.window_visible = true;
                window::get_latest().then(|id: Option<window::Id>| match id {
                    Some(id) => Task::batch([
                        window::change_mode(id, window::Mode::Windowed),
                        window::gain_focus(id),
                    ]),
                    None => Task::none(),
                })
            }
            Message::HideWindow => {
                self.window_visible = false;
                window::get_latest().then(|id: Option<window::Id>| match id {
                    Some(id) => window::change_mode(id, window::Mode::Hidden),
                    None => Task::none(),
                })
            }
            Message::Quit => iced::exit(),
        }
    }

    fn view(&self) -> Element<'_, Message> {
        let title = text("Pass store sync")
            .size(20)
            .style(|_theme: &Theme| text::Style {
                color: Some(Color::from_rgb8(0x22, 0xc5, 0x5e)),
            });

        let body = column![
            title,
            Space::with_height(8),
            text(&self.headline).size(16),
            text(&self.detail).size(13),
            text(&self.mat_line).size(13),
            Space::with_height(12),
            row![
                button("Pull now").on_press(Message::Pull),
                Space::with_width(8),
                button("Rematerialize").on_press(Message::Materialize),
            ],
            Space::with_height(8),
            row![
                button("QtPass").on_press(Message::OpenQtPass),
                Space::with_width(8),
                button("Sync log").on_press(Message::OpenLog),
                Space::with_width(8),
                button("Hide").on_press(Message::HideWindow),
            ],
            Space::with_height(8),
            button("Quit").on_press(Message::Quit),
        ]
        .spacing(4)
        .padding(16)
        .align_x(Alignment::Start);

        container(body)
            .width(Length::Fill)
            .height(Length::Fill)
            .into()
    }

    fn subscription(&self) -> Subscription<Message> {
        Subscription::batch([
            time::every(Duration::from_secs(2)).map(|_| Message::Tick),
            iced::event::listen_with(|event, status, _id| {
                if status == iced::event::Status::Captured {
                    return None;
                }
                match event {
                    iced::Event::Window(window::Event::CloseRequested) => Some(Message::HideWindow),
                    _ => None,
                }
            }),
        ])
    }
}

fn main() -> iced::Result {
    #[cfg(target_os = "linux")]
    {
        // tray-icon on Linux needs gtk main context; init before iced.
        gtk::init().expect("gtk init");
    }

    iced::application("pass-store-tray", PassTray::update, PassTray::view)
        .subscription(PassTray::subscription)
        .theme(|_| Theme::Dark)
        .window(window::Settings {
            size: iced::Size::new(380.0, 280.0),
            resizable: false,
            exit_on_close_request: false,
            ..Default::default()
        })
        .run_with(PassTray::new)
}
