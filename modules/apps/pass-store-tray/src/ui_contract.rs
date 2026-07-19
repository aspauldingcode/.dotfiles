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
    Quit,
}

impl Action {
    pub const fn label(self) -> &'static str {
        match self {
            Self::OpenQtPass => "Open QtPass",
            Self::OpenSyncLog => "Open sync log",
            Self::Quit => "Quit",
        }
    }

    /// Ordered action rows after the status block + separators.
    pub const ALL: &[Action] = &[Self::OpenQtPass, Self::OpenSyncLog, Self::Quit];
}

pub const TOOLTIP_IDLE: &str = "pass sync";

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
/// Expected: `KEY empty → ~/path`, `stale env remains → ~/path`, `skip unsafe…`
pub fn warning_rows(raw: &str) -> Vec<String> {
    let raw = raw.trim();
    if let Some((left, _right)) = raw.split_once(" → ") {
        let left = left.trim();
        let key = left
            .strip_suffix(" empty")
            .unwrap_or(left)
            .trim();
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

/// Build minimal status rows: skip zeros / idle-ok; one fact per row.
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

    // Active sync / rebuild — only while in progress.
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

    // Git divergence — omit when both zero.
    if ahead > 0 {
        rows.push(format!("ahead {ahead}"));
    }
    if behind > 0 {
        rows.push(format!("behind {behind}"));
    }

    // Warnings — one key per issue; omit entirely when zero.
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

    // Change paths — omit when 0 or when the set is large (fleet PSKs).
    // Small sets: one truncated leaf per item, never side-by-side.
    if !materialized.is_empty() && materialized.len() <= MAX_PATH_ROWS {
        for p in materialized {
            rows.push(ellipsize(&path_leaf(p), MENU_COLS));
        }
    }

    // Drop boring sync chatter ("pull: up to date", "0 warning(s)") — icon covers ok.
    let _ = message;

    let tooltip = {
        let mut parts: Vec<String> = vec!["pass sync".into()];
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
        assert!(lines.rows.is_empty(), "ok state → actions only: {:?}", lines.rows);
    }

    #[test]
    fn warnings_and_paths_are_separate_rows() {
        let mats = vec![
            ".config/dendritic/wifi/Bubbles.psk".into(),
            ".config/guildforge/env".into(),
        ];
        let lines = build_status_lines(
            false,
            false,
            "idle",
            "none",
            "materialized 2 file(s); 2 warning(s)",
            Some("ahead 0, behind 0"),
            None,
            None,
            &mats,
            None,
            &[
                "DISCORD_TOKEN empty → ~/.config/guildforge/env".into(),
                "GUILD_ID empty → ~/.config/guildforge/env".into(),
            ],
        );
        assert!(lines.rows.iter().all(|r| !r.contains(" · ") && !r.contains(", ")));
        assert!(lines.rows.iter().any(|r| r == "DISCORD_TOKEN"));
        assert!(lines.rows.iter().any(|r| r == "GUILD_ID"));
        assert!(lines.rows.iter().any(|r| r == "Bubbles.psk"));
        assert!(lines.rows.iter().any(|r| r == "env"));
        for row in &lines.rows {
            assert!(row.chars().count() <= MENU_COLS, "{row}");
        }
    }

    #[test]
    fn large_file_set_omitted() {
        let mats: Vec<String> = (0..19)
            .map(|i| format!(".config/dendritic/wifi/WIFI_{i}.psk"))
            .collect();
        let lines = build_status_lines(
            false,
            false,
            "idle",
            "none",
            "",
            Some("ahead 0, behind 0"),
            None,
            None,
            &mats,
            None,
            &[],
        );
        assert!(lines.rows.is_empty());
    }

    #[test]
    fn warning_key_not_full_path() {
        let rows = warning_rows("DISCORD_TOKEN empty → ~/.config/guildforge/env");
        assert_eq!(rows, vec!["DISCORD_TOKEN".to_string()]);
    }
}
