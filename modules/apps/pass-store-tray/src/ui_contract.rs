//! Single UI contract for macOS NSMenu + Linux StatusNotifier menus.
//! Both frontends must use these labels/actions so the applet never drifts.
//!
//! Rules:
//! - Omit rows when the value is zero / empty / idle-ok (icon already says ok).
//! - One fact per menu item — never side-by-side joins.
//! - Truncate keys/paths; never dump comma-joined path lists.
//! - Icons (check / up / down / rebuild / !) stay in the glyph renderer.

/// Soft cap for menu item text (chars).
pub const MENU_COLS: usize = 36;

/// Soft cap for tooltip lines (chars).
pub const TOOLTIP_COLS: usize = 36;

/// Max warning rows before overflow marker.
pub const MAX_WARN_ROWS: usize = 6;

/// Max materialized path rows before overflow marker.
pub const MAX_PATH_ROWS: usize = 6;

/// Clickable actions — keep this set tiny (native menu, not a window).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    OpenQtPass,
    OpenSyncLog,
    /// Submenu parent label (not a click target by itself).
    ConnectDevice,
    ConnectWireGuard,
    ConnectPassGuide,
    ConnectSetupGuide,
    SyncFlake,
    SwitchPeer,
    Quit,
}

impl Action {
    pub const fn label(self) -> &'static str {
        match self {
            Self::OpenQtPass => "Open QtPass",
            Self::OpenSyncLog => "Open sync log",
            Self::ConnectDevice => "Connect device",
            Self::ConnectWireGuard => "WireGuard for iPhone…",
            Self::ConnectPassGuide => "Pass store for iPhone…",
            Self::ConnectSetupGuide => "Setup guide…",
            Self::SyncFlake => "Sync flake…",
            Self::SwitchPeer => "Switch peer…",
            Self::Quit => "Quit",
        }
    }

    /// Top-level actions (Connect device is a submenu; children listed separately).
    pub const ALL: &[Action] = &[
        Self::OpenQtPass,
        Self::OpenSyncLog,
        Self::ConnectDevice,
        Self::SyncFlake,
        Self::SwitchPeer,
        Self::Quit,
    ];

    pub const CONNECT_CHILDREN: &[Action] = &[
        Self::ConnectWireGuard,
        Self::ConnectPassGuide,
        Self::ConnectSetupGuide,
    ];
}

pub const TOOLTIP_IDLE: &str = "dendritic";

/// Truncate to `max` chars with a single ellipsis when needed.
pub fn ellipsize(s: &str, max: usize) -> String {
    if max == 0 {
        return String::new();
    }
    let count = s.chars().count();
    if count <= max {
        return s.to_string();
    }
    if max == 1 {
        return "…".into();
    }
    let keep = max - 1;
    let mut out: String = s.chars().take(keep).collect();
    out.push('…');
    out
}

/// Word-ish wrap for tooltips; hard-breaks overlong tokens.
pub fn wrap_text(s: &str, cols: usize) -> String {
    if cols == 0 || s.is_empty() {
        return s.to_string();
    }
    let mut lines: Vec<String> = Vec::new();
    for para in s.split('\n') {
        if para.is_empty() {
            lines.push(String::new());
            continue;
        }
        let mut cur = String::new();
        for word in para.split_whitespace() {
            if word.chars().count() > cols {
                if !cur.is_empty() {
                    lines.push(cur);
                    cur = String::new();
                }
                let mut chunk = String::new();
                for ch in word.chars() {
                    if chunk.chars().count() >= cols {
                        lines.push(chunk);
                        chunk = String::new();
                    }
                    chunk.push(ch);
                }
                if !chunk.is_empty() {
                    cur = chunk;
                }
                continue;
            }
            let next_len =
                cur.chars().count() + if cur.is_empty() { 0 } else { 1 } + word.chars().count();
            if !cur.is_empty() && next_len > cols {
                lines.push(cur);
                cur = word.to_string();
            } else if cur.is_empty() {
                cur = word.to_string();
            } else {
                cur.push(' ');
                cur.push_str(word);
            }
        }
        if !cur.is_empty() {
            lines.push(cur);
        }
    }
    lines.join("\n")
}

/// Shorten home-relative paths for display.
pub fn short_path(p: &str) -> String {
    let p = p.trim();
    for prefix in ["~/.config/", ".config/", "~/"] {
        if let Some(rest) = p.strip_prefix(prefix) {
            return rest.to_string();
        }
    }
    p.to_string()
}

/// Basename-ish leaf for long paths (`dendritic/wifi/Bubbles.psk` → `Bubbles.psk`).
pub fn path_leaf(p: &str) -> String {
    let p = short_path(p);
    p.rsplit('/').next().unwrap_or(&p).to_string()
}

/// Parse `ahead N, behind M` → non-zero counts only.
pub fn parse_ahead_behind(raw: Option<&str>) -> (u32, u32) {
    let Some(raw) = raw else {
        return (0, 0);
    };
    let mut ahead = 0u32;
    let mut behind = 0u32;
    for part in raw.split(',') {
        let part = part.trim().to_ascii_lowercase();
        if let Some(rest) = part.strip_prefix("ahead ") {
            ahead = rest.trim().parse().unwrap_or(0);
        } else if let Some(rest) = part.strip_prefix("behind ") {
            behind = rest.trim().parse().unwrap_or(0);
        }
    }
    (ahead, behind)
}

/// Warning → key only (truncated). No path on the same line.
pub fn warning_rows(raw: &str) -> Vec<String> {
    let raw = raw.trim();
    if let Some((left, _right)) = raw.split_once(" → ") {
        let left = left.trim();
        let key = left.strip_suffix(" empty").unwrap_or(left).trim();
        if key.starts_with("stale env") {
            return vec![ellipsize("stale env", MENU_COLS)];
        }
        return vec![ellipsize(key, MENU_COLS)];
    }
    if let Some(rest) = raw.strip_prefix("skip unsafe path:") {
        return vec![ellipsize(&format!("skip {}", rest.trim()), MENU_COLS)];
    }
    if let Some(rest) = raw.strip_prefix("skip unsafe env path:") {
        return vec![ellipsize(&format!("skip {}", rest.trim()), MENU_COLS)];
    }
    vec![ellipsize(raw, MENU_COLS)]
}

#[derive(Debug, Clone)]
pub struct StatusLines {
    /// Disabled status rows only — empty when fully healthy (icon = check).
    pub rows: Vec<String>,
    pub tooltip: String,
}

/// Fingerprint for menu rebuild (row count + text).
pub fn rows_fingerprint(rows: &[String]) -> String {
    rows.join("\n")
}

/// Build minimal pass-store status rows: skip zeros / idle-ok; one fact per row.
pub fn build_status_lines(
    rebuilding: bool,
    lock: bool,
    state: &str,
    direction: &str,
    message: &str,
    ahead_behind: Option<&str>,
    _updated_at: Option<&str>,
    error: Option<&str>,
    materialized: &[String],
    _last_materialize_at: Option<&str>,
    warnings: &[String],
) -> StatusLines {
    let err = error.filter(|e| !e.is_empty());
    let (ahead, behind) = parse_ahead_behind(ahead_behind);
    let mut rows: Vec<String> = Vec::new();

    if rebuilding {
        rows.push("Rebuilding…".into());
    } else if lock {
        let dir = if direction.is_empty() || direction == "none" {
            "…"
        } else {
            direction
        };
        rows.push(ellipsize(&format!("Syncing ({dir})…"), MENU_COLS));
    } else if state != "idle" && state != "error" && !state.is_empty() {
        rows.push(ellipsize(state, MENU_COLS));
    }

    if let Some(e) = err {
        rows.push(ellipsize(&format!("Error: {e}"), MENU_COLS));
    }

    if ahead > 0 {
        rows.push(format!("pass ahead {ahead}"));
    }
    if behind > 0 {
        rows.push(format!("pass behind {behind}"));
    }

    let mut warn_shown = 0usize;
    for w in warnings {
        if warn_shown >= MAX_WARN_ROWS {
            let extra = warnings.len().saturating_sub(warn_shown);
            if extra > 0 {
                rows.push(format!("…+{extra} more"));
            }
            break;
        }
        rows.extend(warning_rows(w));
        warn_shown += 1;
    }

    if !materialized.is_empty() && materialized.len() <= MAX_PATH_ROWS {
        for p in materialized {
            rows.push(ellipsize(&path_leaf(p), MENU_COLS));
        }
    }

    let _ = message;

    let tooltip = {
        let mut parts: Vec<String> = vec!["dendritic".into()];
        if rows.is_empty() {
            parts.push("ok".into());
        } else {
            parts.extend(rows.iter().cloned());
        }
        wrap_text(&parts.join("\n"), TOOLTIP_COLS)
    };

    StatusLines { rows, tooltip }
}

/// Dendritic tray extras (theme / llm / wg / fleet / android / flake / job).
#[derive(Debug, Clone, Default)]
pub struct DendriticFacts {
    pub job_state: String,
    pub job_message: String,
    pub theme_variant: String,
    pub theme_phase: String,
    pub llm_ok: bool,
    pub llm_models: u32,
    pub wg_up: bool,
    pub wg_peer_ok: bool,
    pub fleet_offline: Vec<String>,
    pub fleet_stale: Vec<String>,
    pub flake_dirty: bool,
    pub flake_ahead: u32,
    pub flake_behind: u32,
    pub nixpkgs_age_days: Option<u32>,
    pub peer_flake_behind: Vec<String>,
    /// oneplus6t / nix-android converge snapshot
    pub android_device: String,
    pub android_reachable: bool,
    pub android_state: String,
    pub android_message: String,
    pub android_lease_holder: String,
    pub android_status_age_secs: Option<u64>,
    pub android_present: bool,
}

pub fn build_dendritic_rows(f: &DendriticFacts) -> Vec<String> {
    let mut rows = Vec::new();
    if !f.job_state.is_empty() && f.job_state != "idle" {
        if f.job_state == "error" {
            rows.push(ellipsize(
                &format!("Job: {}", if f.job_message.is_empty() { "error" } else { &f.job_message }),
                MENU_COLS,
            ));
        } else {
            rows.push(ellipsize(
                &format!(
                    "{}…",
                    if f.job_message.is_empty() {
                        f.job_state.as_str()
                    } else {
                        f.job_message.as_str()
                    }
                ),
                MENU_COLS,
            ));
        }
    }
    if f.flake_dirty {
        rows.push("flake dirty".into());
    }
    if f.flake_ahead > 0 {
        rows.push(format!("flake ahead {}", f.flake_ahead));
    }
    if f.flake_behind > 0 {
        rows.push(format!("flake behind {}", f.flake_behind));
    }
    if let Some(days) = f.nixpkgs_age_days {
        if days >= 14 {
            rows.push(format!("nixpkgs {days}d old"));
        }
    }
    for h in &f.peer_flake_behind {
        rows.push(ellipsize(&format!("{h} rev behind"), MENU_COLS));
    }
    if !f.wg_up {
        rows.push("wg down".into());
    } else if !f.wg_peer_ok {
        rows.push("wg peer unreachable".into());
    }
    if !f.llm_ok {
        rows.push("ollama down".into());
    }
    if !f.theme_phase.is_empty() && f.theme_phase != "synced" {
        rows.push(ellipsize(&format!("theme {}", f.theme_phase), MENU_COLS));
    }
    for h in &f.fleet_offline {
        // Phone has dedicated android rows; skip duplicate fleet offline.
        if !f.android_device.is_empty() && h == &f.android_device {
            continue;
        }
        rows.push(ellipsize(&format!("{h} offline"), MENU_COLS));
    }
    for h in &f.fleet_stale {
        if !f.android_device.is_empty() && h == &f.android_device {
            continue;
        }
        rows.push(ellipsize(&format!("{h} stale"), MENU_COLS));
    }
    if f.android_present {
        let dev = if f.android_device.is_empty() {
            "oneplus6t"
        } else {
            f.android_device.as_str()
        };
        if !f.android_reachable {
            rows.push(ellipsize(&format!("{dev} unreachable"), MENU_COLS));
        } else if f.android_state == "error" {
            let msg = if f.android_message.is_empty() {
                "error".into()
            } else {
                f.android_message.clone()
            };
            rows.push(ellipsize(&format!("{dev} {msg}"), MENU_COLS));
        } else if f.android_state == "running" {
            rows.push(ellipsize(&format!("{dev} converging…"), MENU_COLS));
        } else if f.android_state == "skipped" && !f.android_lease_holder.is_empty() {
            rows.push(ellipsize(
                &format!("{dev} leased by {}", f.android_lease_holder),
                MENU_COLS,
            ));
        } else if let Some(age) = f.android_status_age_secs {
            // Converge agent should refresh ~15m; stale file while phone is up.
            if age > 45 * 60 {
                rows.push(ellipsize(&format!("{dev} status stale"), MENU_COLS));
            }
        }
    }
    rows
}

/// Merge pass + dendritic rows; rebuild tooltip.
pub fn merge_status_lines(pass: StatusLines, dendritic_rows: &[String]) -> StatusLines {
    let mut rows = pass.rows;
    rows.extend(dendritic_rows.iter().cloned());
    let tooltip = {
        let mut parts: Vec<String> = vec!["dendritic".into()];
        if rows.is_empty() {
            parts.push("ok".into());
        } else {
            parts.extend(rows.iter().cloned());
        }
        wrap_text(&parts.join("\n"), TOOLTIP_COLS)
    };
    StatusLines { rows, tooltip }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ellipsize_caps() {
        assert_eq!(ellipsize("hello", 10), "hello");
        assert_eq!(ellipsize("abcdefghij", 5).chars().count(), 5);
        assert!(ellipsize("abcdefghij", 5).ends_with('…'));
    }

    #[test]
    fn ahead_behind_skips_zero() {
        assert_eq!(parse_ahead_behind(Some("ahead 0, behind 0")), (0, 0));
        assert_eq!(parse_ahead_behind(Some("ahead 2, behind 0")), (2, 0));
        assert_eq!(parse_ahead_behind(Some("ahead 0, behind 3")), (0, 3));
    }

    #[test]
    fn healthy_idle_has_no_status_rows() {
        let lines = build_status_lines(
            false,
            false,
            "idle",
            "none",
            "pull: up to date",
            Some("ahead 0, behind 0"),
            Some("2026-07-15T15:31:24Z"),
            None,
            &[],
            None,
            &[],
        );
        assert!(
            lines.rows.is_empty(),
            "ok state → actions only: {:?}",
            lines.rows
        );
    }

    #[test]
    fn dendritic_rows_omit_healthy() {
        let f = DendriticFacts {
            llm_ok: true,
            wg_up: true,
            wg_peer_ok: true,
            theme_phase: "synced".into(),
            ..Default::default()
        };
        assert!(build_dendritic_rows(&f).is_empty());
    }

    #[test]
    fn android_unreachable_row() {
        let f = DendriticFacts {
            llm_ok: true,
            wg_up: true,
            wg_peer_ok: true,
            theme_phase: "synced".into(),
            android_present: true,
            android_device: "oneplus6t".into(),
            android_reachable: false,
            ..Default::default()
        };
        let rows = build_dendritic_rows(&f);
        assert!(rows.iter().any(|r| r.contains("oneplus6t unreachable")));
    }

    #[test]
    fn actions_include_sync() {
        assert!(Action::ALL.contains(&Action::SyncFlake));
        assert!(Action::ALL.contains(&Action::SwitchPeer));
        assert!(Action::ALL.contains(&Action::ConnectDevice));
        assert_eq!(Action::ALL.len(), 6);
        assert_eq!(Action::CONNECT_CHILDREN.len(), 3);
    }
}
