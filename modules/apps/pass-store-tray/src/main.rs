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
use ui_contract::{Action, TOOLTIP_IDLE};

#[cfg(target_os = "macos")]
use winit::application::ApplicationHandler;
#[cfg(target_os = "macos")]
use winit::event::StartCause;
#[cfg(target_os = "macos")]
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};

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
            sync_log: cache.join("pass-store-sync.log"),
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
        if !(0..size as i32).contains(&x) || !(0..size as i32).contains(&y) {
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

struct NativeTray {
    env: Env,
    tray: TrayIcon,
    status_headline: MenuItem,
    status_detail: MenuItem,
    status_mat: MenuItem,
    item_qtpass: MenuItem,
    item_log: MenuItem,
    item_quit: MenuItem,
    icon_kind: IconKind,
    quit: Arc<AtomicBool>,
}

impl NativeTray {
    fn build(env: Env, quit: Arc<AtomicBool>) -> Self {
        let status_headline = MenuItem::new(ui_contract::status::HEADLINE, false, None);
        let status_detail = MenuItem::new(ui_contract::status::DETAIL, false, None);
        let status_mat = MenuItem::new(ui_contract::status::MATERIALIZED, false, None);
        let item_qtpass = MenuItem::new(Action::OpenQtPass.label(), true, None);
        let item_log = MenuItem::new(Action::OpenSyncLog.label(), true, None);
        let item_quit = MenuItem::new(Action::Quit.label(), true, None);

        let menu = Menu::new();
        // Status block (read-only)
        let _ = menu.append(&status_headline);
        let _ = menu.append(&status_detail);
        let _ = menu.append(&status_mat);
        let _ = menu.append(&PredefinedMenuItem::separator());
        // Actions from shared contract order (QtPass, sync log, then Quit)
        debug_assert_eq!(Action::ALL[0], Action::OpenQtPass);
        debug_assert_eq!(Action::ALL[1], Action::OpenSyncLog);
        debug_assert_eq!(Action::ALL[2], Action::Quit);
        let _ = menu.append(&item_qtpass);
        let _ = menu.append(&item_log);
        let _ = menu.append(&PredefinedMenuItem::separator());
        let _ = menu.append(&item_quit);

        let tray = TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip(TOOLTIP_IDLE)
            .with_icon(make_icon(IconKind::Idle))
            .build()
            .expect("create tray icon");

        let mut app = Self {
            env,
            tray,
            status_headline,
            status_detail,
            status_mat,
            item_qtpass,
            item_log,
            item_quit,
            icon_kind: IconKind::Idle,
            quit,
        };
        app.refresh();
        app
    }

    fn refresh(&mut self) {
        let status = load_status(&self.env.status_file);
        let rebuilding = rebuild_running();
        let lock = self.env.lock_dir.exists();
        let kind = icon_kind(&status, rebuilding, lock);
        if kind != self.icon_kind {
            self.icon_kind = kind;
            let _ = self.tray.set_icon(Some(make_icon(kind)));
        }

        let err = status.error.as_deref().filter(|e| !e.is_empty());
        let headline = if rebuilding {
            "Rebuilding system…".to_string()
        } else if lock {
            format!("Syncing ({})…", status.direction)
        } else if let Some(e) = err {
            format!("Error: {e}")
        } else {
            format!("{} · {}", status.state, status.direction)
        };

        let ab = status.ahead_behind.as_deref().unwrap_or("unknown");
        let updated = status.updated_at.as_deref().unwrap_or("—");
        let detail = format!("{} · {} · {}", status.message, ab, updated);

        let mats = if status.materialized.is_empty() {
            "(none)".into()
        } else {
            status.materialized.join(", ")
        };
        let last_mat = status.last_materialize_at.as_deref().unwrap_or("—");
        let mat_line = format!("Materialized: {mats} @ {last_mat}");

        self.status_headline.set_text(headline.clone());
        self.status_detail.set_text(detail);
        self.status_mat.set_text(mat_line);
        let _ = self
            .tray
            .set_tooltip(Some(format!("pass sync: {headline}")));
    }

    fn handle_menu(&mut self) {
        while let Ok(ev) = MenuEvent::receiver().try_recv() {
            let id = ev.id;
            if id == self.item_qtpass.id() {
                open_qtpass();
            } else if id == self.item_log.id() {
                open_sync_log(&self.env.sync_log);
            } else if id == self.item_quit.id() {
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
        let event_loop = EventLoop::new().expect("event loop");
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
