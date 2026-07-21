//! Native menubar / tray applet — no window, no iced.
//! macOS: NSStatusItem + NSMenu via tray-icon/muda (+ winit runloop).
//! Linux: StatusNotifier + gtk menu via tray-icon (gtk main thread only).
mod ui_contract;

use serde::Deserialize;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tray_icon::menu::{Menu, MenuEvent, MenuItem, PredefinedMenuItem};
use tray_icon::{Icon, TrayIcon, TrayIconBuilder};
use ui_contract::{
    Action, DendriticFacts, TOOLTIP_IDLE, build_dendritic_rows, build_status_lines,
    merge_status_lines,
};

#[cfg(target_os = "macos")]
use winit::application::ApplicationHandler;
#[cfg(target_os = "macos")]
use winit::event::StartCause;
#[cfg(target_os = "macos")]
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
#[cfg(target_os = "macos")]
use winit::platform::macos::{ActivationPolicy, EventLoopBuilderExtMacOS};

#[derive(Debug, Clone, Default, Deserialize)]
struct SyncStatus {
    #[serde(default = "default_state")]
    state: String,
    #[serde(default = "default_direction")]
    direction: String,
    #[serde(default)]
    message: String,
    #[serde(default)]
    #[allow(dead_code)]
    updated_at: Option<String>,
    #[serde(default)]
    ahead_behind: Option<String>,
    #[serde(default)]
    error: Option<String>,
    #[serde(default)]
    materialized: Vec<String>,
    #[serde(default)]
    last_materialize_at: Option<String>,
    /// Soft edge cases from pass-materialize (missing/stale secrets) — not sync hard errors.
    #[serde(default)]
    materialize_warnings: Vec<String>,
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
    sync_log: PathBuf,
    dendritic_status: PathBuf,
    dendritic_lock: PathBuf,
    collect_bin: Option<PathBuf>,
    sync_bin: Option<PathBuf>,
    switch_peer_bin: Option<PathBuf>,
}

impl Env {
    fn from_env() -> Self {
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
        let cache = home.join(".cache");
        let opt_bin = |key: &str| std::env::var_os(key).map(PathBuf::from);
        Self {
            status_file: std::env::var_os("PASS_STORE_SYNC_STATUS")
                .map(PathBuf::from)
                .unwrap_or_else(|| cache.join("pass-store-sync.status")),
            lock_dir: std::env::var_os("PASS_STORE_SYNC_LOCK")
                .map(PathBuf::from)
                .unwrap_or_else(|| cache.join("pass-store-sync.lock")),
            sync_log: cache.join("pass-store-sync.log"),
            dendritic_status: std::env::var_os("DENDRITIC_TRAY_STATUS")
                .map(PathBuf::from)
                .unwrap_or_else(|| cache.join("dendritic-tray.status")),
            dendritic_lock: cache.join("dendritic-tray.lock"),
            collect_bin: opt_bin("DENDRITIC_TRAY_COLLECT"),
            sync_bin: opt_bin("DENDRITIC_TRAY_SYNC"),
            switch_peer_bin: opt_bin("DENDRITIC_TRAY_SWITCH_PEER"),
        }
    }
}

fn load_status(path: &Path) -> SyncStatus {
    match std::fs::read_to_string(path) {
        Ok(raw) => serde_json::from_str(&raw).unwrap_or_else(|_| SyncStatus {
            state: "error".into(),
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
    let Ok(out) = Command::new("ps").args(["-ax", "-o", "command="]).output() else {
        return false;
    };
    let text = String::from_utf8_lossy(&out.stdout);
    // Match real rebuild invocations only — bare "nh os" false-positives on
    // diagnostic shells / ssh heredocs that merely mention the strings.
    const PATS: &[&str] = &[
        "nh darwin switch",
        "nh os switch",
        "darwin-rebuild switch",
        "nixos-rebuild switch",
        "nix-darwin-rebuild switch",
    ];
    for line in text.lines() {
        let low = line.to_lowercase();
        if low.contains("pass-store-tray")
            || low.contains("grep")
            || low.contains("rg ")
            || low.contains("cursor")
        {
            continue;
        }
        if PATS.iter().any(|p| low.contains(p)) {
            return true;
        }
    }
    false
}

fn icon_kind(status: &SyncStatus, rebuilding: bool, lock: bool, facts: &DendriticFacts) -> IconKind {
    if rebuilding {
        return IconKind::Rebuild;
    }
    if status.error.as_ref().is_some_and(|e| !e.is_empty()) || status.state == "error" {
        return IconKind::Error;
    }
    if facts.job_state == "error" {
        return IconKind::Error;
    }
    // Missing/stale materialize secrets — same attention glyph as error (no amber on template icons).
    if !status.materialize_warnings.is_empty() {
        return IconKind::Error;
    }
    if facts.flake_dirty || facts.flake_behind > 0 || !facts.wg_up || !facts.fleet_offline.is_empty()
    {
        return IconKind::Error;
    }
    if facts.job_state == "syncing" || facts.job_state == "switching" {
        return IconKind::Up;
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

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticStatusFile {
    #[serde(default)]
    theme: DendriticTheme,
    #[serde(default)]
    llm: DendriticLlm,
    #[serde(default)]
    wg: DendriticWg,
    #[serde(default)]
    fleet: Vec<DendriticFleetHost>,
    #[serde(default)]
    flake: DendriticFlake,
    #[serde(default)]
    job: DendriticJob,
    #[serde(default)]
    #[allow(dead_code)]
    updated_at: Option<String>,
    #[serde(default)]
    host: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticTheme {
    #[serde(default)]
    variant: String,
    #[serde(default)]
    phase: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticLlm {
    #[serde(default)]
    ok: bool,
    #[serde(default)]
    models: u32,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticWg {
    #[serde(default)]
    up: bool,
    #[serde(default)]
    peer_ok: bool,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticFleetHost {
    #[serde(default)]
    host: String,
    #[serde(default)]
    status: String,
    #[serde(default)]
    flake_rev: String,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticFlake {
    #[serde(default)]
    rev: String,
    #[serde(default)]
    dirty: bool,
    #[serde(default)]
    ahead: u32,
    #[serde(default)]
    behind: u32,
    #[serde(default)]
    nixpkgs_age_days: Option<u32>,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct DendriticJob {
    #[serde(default = "default_state")]
    state: String,
    #[serde(default)]
    message: String,
}

fn load_dendritic(path: &Path) -> DendriticStatusFile {
    match std::fs::read_to_string(path) {
        Ok(raw) => serde_json::from_str(&raw).unwrap_or_default(),
        Err(_) => DendriticStatusFile::default(),
    }
}

fn dendritic_facts(d: &DendriticStatusFile) -> DendriticFacts {
    let mut offline = Vec::new();
    let mut stale = Vec::new();
    let mut peer_behind = Vec::new();
    for h in &d.fleet {
        if h.host.is_empty() || h.host == d.host {
            continue;
        }
        match h.status.as_str() {
            "offline" => offline.push(h.host.clone()),
            "stale" => stale.push(h.host.clone()),
            _ => {}
        }
        if !d.flake.rev.is_empty()
            && !h.flake_rev.is_empty()
            && h.flake_rev != d.flake.rev
            && h.status != "offline"
        {
            peer_behind.push(h.host.clone());
        }
    }
    DendriticFacts {
        job_state: d.job.state.clone(),
        job_message: d.job.message.clone(),
        theme_variant: d.theme.variant.clone(),
        theme_phase: d.theme.phase.clone(),
        llm_ok: d.llm.ok,
        llm_models: d.llm.models,
        wg_up: d.wg.up,
        wg_peer_ok: d.wg.peer_ok,
        fleet_offline: offline,
        fleet_stale: stale,
        flake_dirty: d.flake.dirty,
        flake_ahead: d.flake.ahead,
        flake_behind: d.flake.behind,
        nixpkgs_age_days: d.flake.nixpkgs_age_days,
        peer_flake_behind: peer_behind,
    }
}

fn status_stale(path: &Path, max_secs: u64) -> bool {
    match std::fs::metadata(path).and_then(|m| m.modified()) {
        Ok(t) => t.elapsed().map(|d| d.as_secs() > max_secs).unwrap_or(true),
        Err(_) => true,
    }
}

fn spawn_bin(bin: &Option<PathBuf>) {
    let Some(path) = bin else {
        return;
    };
    let _ = Command::new(path)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn();
}

fn make_icon(kind: IconKind) -> Icon {
    // macOS menu-bar style: black silhouette + alpha. Marked as template so
    // AppKit tints for light/dark menu bar (no baked-in green/blue/amber).
    // Linux: light ink for typical dark panels (no template API).
    let size = 32u32;
    let mut rgba = vec![0u8; (size * size * 4) as usize];
    #[cfg(target_os = "macos")]
    let (r, g, b) = (0u8, 0u8, 0u8);
    #[cfg(not(target_os = "macos"))]
    let (r, g, b) = (0xe8u8, 0xe8u8, 0xe8u8);

    let put = |rgba: &mut [u8], x: i32, y: i32, a: u8| {
        if !(0..size as i32).contains(&x) || !(0..size as i32).contains(&y) || a == 0 {
            return;
        }
        let i = ((y as u32 * size + x as u32) * 4) as usize;
        // Max-alpha composite so overlapping strokes stay solid silhouette.
        if a > rgba[i + 3] {
            rgba[i] = r;
            rgba[i + 1] = g;
            rgba[i + 2] = b;
            rgba[i + 3] = a;
        }
    };
    let fill_rect = |rgba: &mut [u8], x0: i32, y0: i32, x1: i32, y1: i32| {
        for y in y0..y1 {
            for x in x0..x1 {
                put(rgba, x, y, 255);
            }
        }
    };
    // Soft edge for a cleaner SF-Symbol-like silhouette.
    let stroke_disk = |rgba: &mut [u8], cx: f32, cy: f32, rad: f32| {
        let r0 = rad - 0.6;
        let r1 = rad + 0.6;
        let min_x = (cx - r1).floor() as i32;
        let max_x = (cx + r1).ceil() as i32;
        let min_y = (cy - r1).floor() as i32;
        let max_y = (cy + r1).ceil() as i32;
        for y in min_y..=max_y {
            for x in min_x..=max_x {
                let dx = x as f32 + 0.5 - cx;
                let dy = y as f32 + 0.5 - cy;
                let d = (dx * dx + dy * dy).sqrt();
                if d <= r0 {
                    put(rgba, x, y, 255);
                } else if d < r1 {
                    let t = (r1 - d) / (r1 - r0);
                    put(rgba, x, y, (t * 255.0) as u8);
                }
            }
        }
    };

    match kind {
        IconKind::Up => {
            for y in 4..16 {
                let half = (y - 4) / 2;
                for x in (16 - half)..(16 + half) {
                    put(&mut rgba, x, y, 255);
                }
            }
            fill_rect(&mut rgba, 13, 14, 19, 28);
        }
        IconKind::Down => {
            for y in 16..28 {
                let half = (28 - y) / 2;
                for x in (16 - half)..(16 + half) {
                    put(&mut rgba, x, y, 255);
                }
            }
            fill_rect(&mut rgba, 13, 4, 19, 18);
        }
        IconKind::Error => {
            fill_rect(&mut rgba, 14, 6, 18, 20);
            fill_rect(&mut rgba, 14, 22, 18, 26);
        }
        IconKind::Rebuild => {
            // Open circular arrow (silhouette spinner).
            for y in 4..28 {
                for x in 4..28 {
                    let dx = x - 16;
                    let dy = y - 16;
                    let d2 = dx * dx + dy * dy;
                    if (64..121).contains(&d2) && !(x > 16 && y < 16) {
                        put(&mut rgba, x, y, 255);
                    }
                }
            }
            fill_rect(&mut rgba, 16, 4, 26, 10);
        }
        IconKind::Idle => {
            // Checkmark silhouette (no green fill).
            for t in 0..10 {
                put(&mut rgba, 8 + t, 16 + t / 2, 255);
                put(&mut rgba, 8 + t, 17 + t / 2, 255);
                put(&mut rgba, 8 + t, 18 + t / 2, 255);
            }
            for t in 0..16 {
                put(&mut rgba, 18 + t, 20 - t, 255);
                put(&mut rgba, 18 + t, 21 - t, 255);
                put(&mut rgba, 18 + t, 22 - t, 255);
            }
            // Soft tips (AA) — end of check is ~(32,5) clipped by put.
            stroke_disk(&mut rgba, 8.5, 16.5, 1.3);
            stroke_disk(&mut rgba, 31.0, 6.0, 1.3);
        }
    }
    Icon::from_rgba(rgba, size, size).expect("icon rgba")
}

fn apply_icon(tray: &TrayIcon, kind: IconKind) {
    let icon = make_icon(kind);
    #[cfg(target_os = "macos")]
    {
        let _ = tray.set_icon_with_as_template(Some(icon), true);
    }
    #[cfg(not(target_os = "macos"))]
    {
        let _ = tray.set_icon(Some(icon));
    }
}

fn open_qtpass() {
    #[cfg(target_os = "macos")]
    {
        let _ = Command::new("open").args(["-a", "QtPass"]).spawn();
    }
    #[cfg(not(target_os = "macos"))]
        let _ = Command::new("qtpass")
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn();
}

fn open_sync_log(path: &Path) {
    let path = path.display().to_string();
    #[cfg(target_os = "macos")]
    {
        let _ = Command::new("open").args(["-t", &path]).spawn();
    }
    #[cfg(not(target_os = "macos"))]
    {
        let _ = Command::new("xdg-open")
            .arg(&path)
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn();
    }
}

struct MenuActions {
    qtpass: MenuItem,
    log: MenuItem,
    sync_flake: MenuItem,
    switch_peer: MenuItem,
    quit: MenuItem,
}

struct NativeTray {
    env: Env,
    tray: TrayIcon,
    status_rows: Vec<MenuItem>,
    actions: MenuActions,
    icon_kind: IconKind,
    /// Rebuild when status row set changes (omit zero/ok rows).
    rows_fp: String,
    quit: Arc<AtomicBool>,
    last_collect: std::time::Instant,
}

impl NativeTray {
    fn compose_menu(status_texts: &[String]) -> (Menu, Vec<MenuItem>, MenuActions) {
        let status_rows: Vec<MenuItem> = status_texts
            .iter()
            .map(|t| MenuItem::new(t, false, None))
            .collect();
        let actions = MenuActions {
            qtpass: MenuItem::new(Action::OpenQtPass.label(), true, None),
            log: MenuItem::new(Action::OpenSyncLog.label(), true, None),
            sync_flake: MenuItem::new(Action::SyncFlake.label(), true, None),
            switch_peer: MenuItem::new(Action::SwitchPeer.label(), true, None),
            quit: MenuItem::new(Action::Quit.label(), true, None),
        };

        let menu = Menu::new();
        for row in &status_rows {
            let _ = menu.append(row);
        }
        if !status_rows.is_empty() {
            let _ = menu.append(&PredefinedMenuItem::separator());
        }
        debug_assert_eq!(Action::ALL.len(), 5);
        let _ = menu.append(&actions.qtpass);
        let _ = menu.append(&actions.log);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&actions.sync_flake);
        let _ = menu.append(&actions.switch_peer);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&actions.quit);

        (menu, status_rows, actions)
    }

    fn build(env: Env, quit: Arc<AtomicBool>) -> Self {
        let (menu, status_rows, actions) = Self::compose_menu(&[]);

        let tray = TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip(TOOLTIP_IDLE)
            .with_icon(make_icon(IconKind::Idle))
            .with_icon_as_template(cfg!(target_os = "macos"))
            .build()
            .expect("create tray icon");

        let mut app = Self {
            env,
            tray,
            status_rows,
            actions,
            icon_kind: IconKind::Idle,
            rows_fp: String::new(),
            quit,
            last_collect: std::time::Instant::now()
                .checked_sub(Duration::from_secs(60))
                .unwrap_or_else(std::time::Instant::now),
        };
        app.refresh();
        app
    }

    fn apply_lines(&mut self, lines: &ui_contract::StatusLines) {
        let fp = ui_contract::rows_fingerprint(&lines.rows);
        if fp != self.rows_fp {
            let (menu, status_rows, actions) = Self::compose_menu(&lines.rows);
            self.status_rows = status_rows;
            self.actions = actions;
            self.rows_fp = fp;
            self.tray.set_menu(Some(Box::new(menu)));
        } else {
            for (item, text) in self.status_rows.iter().zip(lines.rows.iter()) {
                item.set_text(text.clone());
            }
        }
        let _ = self.tray.set_tooltip(Some(lines.tooltip.clone()));
    }

    fn maybe_collect(&mut self) {
        if !status_stale(&self.env.dendritic_status, 45)
            && self.last_collect.elapsed() < Duration::from_secs(30)
        {
            return;
        }
        if self.last_collect.elapsed() < Duration::from_secs(10) {
            return;
        }
        self.last_collect = std::time::Instant::now();
        spawn_bin(&self.env.collect_bin);
    }

    fn refresh(&mut self) {
        self.maybe_collect();
        let status = load_status(&self.env.status_file);
        let dendritic = load_dendritic(&self.env.dendritic_status);
        let facts = dendritic_facts(&dendritic);
        let rebuilding = rebuild_running();
        let lock = self.env.lock_dir.exists() || self.env.dendritic_lock.exists();
        let kind = icon_kind(&status, rebuilding, lock, &facts);
        if kind != self.icon_kind {
            self.icon_kind = kind;
            apply_icon(&self.tray, kind);
        }

        let pass_lines = build_status_lines(
            rebuilding,
            self.env.lock_dir.exists(),
            &status.state,
            &status.direction,
            &status.message,
            status.ahead_behind.as_deref(),
            status.updated_at.as_deref(),
            status.error.as_deref(),
            &status.materialized,
            status.last_materialize_at.as_deref(),
            &status.materialize_warnings,
        );
        let drows = build_dendritic_rows(&facts);
        let lines = merge_status_lines(pass_lines, &drows);
        self.apply_lines(&lines);
    }

    fn handle_menu(&mut self) {
        while let Ok(ev) = MenuEvent::receiver().try_recv() {
            let id = ev.id;
            if id == self.actions.qtpass.id() {
                open_qtpass();
            } else if id == self.actions.log.id() {
                open_sync_log(&self.env.sync_log);
            } else if id == self.actions.sync_flake.id() {
                spawn_bin(&self.env.sync_bin);
            } else if id == self.actions.switch_peer.id() {
                spawn_bin(&self.env.switch_peer_bin);
            } else if id == self.actions.quit.id() {
                self.quit.store(true, Ordering::SeqCst);
            }
        }
    }
}

#[cfg(target_os = "macos")]
struct App {
    tray: Option<NativeTray>,
    quit: Arc<AtomicBool>,
}

#[cfg(target_os = "macos")]
impl ApplicationHandler for App {
    fn new_events(&mut self, event_loop: &ActiveEventLoop, cause: StartCause) {
        if cause == StartCause::Init {
            self.tray = Some(NativeTray::build(Env::from_env(), self.quit.clone()));
            event_loop.set_control_flow(ControlFlow::WaitUntil(
                std::time::Instant::now() + Duration::from_secs(2),
            ));
        }
    }

    fn resumed(&mut self, _event_loop: &ActiveEventLoop) {}

    fn window_event(
        &mut self,
        _event_loop: &ActiveEventLoop,
        _window_id: winit::window::WindowId,
        _event: winit::event::WindowEvent,
    ) {
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        if self.quit.load(Ordering::SeqCst) {
            event_loop.exit();
            return;
        }
        if let Some(tray) = &mut self.tray {
            tray.handle_menu();
            tray.refresh();
        }
        event_loop.set_control_flow(ControlFlow::WaitUntil(
            std::time::Instant::now() + Duration::from_secs(2),
        ));
    }
}

fn main() {
    let quit = Arc::new(AtomicBool::new(false));

    #[cfg(target_os = "linux")]
    {
        // tray-icon requires gtk on the same thread as the icon.
        gtk::init().expect("gtk init");
        let mut tray = NativeTray::build(Env::from_env(), quit.clone());
        while !quit.load(Ordering::SeqCst) {
            tray.handle_menu();
            tray.refresh();
            while gtk::events_pending() {
                gtk::main_iteration_do(false);
            }
            std::thread::sleep(Duration::from_millis(200));
        }
    }

    #[cfg(target_os = "macos")]
    {
        // Accessory = menubar agent: no Dock tile, no Cmd-Tab app entry.
        // Default Regular policy is why `.pass-store-tray-wrapped` showed in Dock.
        let mut builder = EventLoop::builder();
        builder.with_activation_policy(ActivationPolicy::Accessory);
        let event_loop = builder.build().expect("event loop");
        let mut app = App {
            tray: None,
            quit,
        };
        if let Err(err) = event_loop.run_app(&mut app) {
            eprintln!("pass-store-tray: event loop error: {err:?}");
            std::process::exit(1);
        }
    }
}
