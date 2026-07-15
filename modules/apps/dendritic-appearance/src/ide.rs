//! Hot-patch IDE settings.json from colors.toml (replaces Python helper).

use std::path::{Path, PathBuf};

use serde_json::{json, Map, Value};

use crate::palette::load_palette;
use crate::state;

pub fn patch_from_colors(colors: &Path) -> Result<usize, String> {
    let palette = load_palette(colors)?;
    let g = |k: &str| {
        palette
            .get(k)
            .cloned()
            .or_else(|| palette.get("base05").cloned())
            .unwrap_or_else(|| "#ffffff".into())
    };
    let mut patch = Map::new();
    for (k, v) in [
        ("titleBar.activeBackground", g("base00")),
        ("titleBar.activeForeground", g("base05")),
        ("titleBar.inactiveBackground", g("base01")),
        ("titleBar.inactiveForeground", g("base04")),
        ("activityBar.background", g("base00")),
        ("activityBar.foreground", g("base05")),
        ("sideBar.background", g("base00")),
        ("sideBar.foreground", g("base05")),
        ("editor.background", g("base00")),
        ("editor.foreground", g("base05")),
        ("editor.lineHighlightBackground", g("base01")),
        ("editor.selectionBackground", g("base02")),
        ("editorCursor.foreground", g("base05")),
        ("editorWidget.background", g("base01")),
        ("panel.background", g("base00")),
        ("statusBar.background", g("base01")),
        ("statusBar.foreground", g("base05")),
        ("tab.activeBackground", g("base01")),
        ("tab.inactiveBackground", g("base00")),
        ("tab.activeForeground", g("base05")),
        ("tab.inactiveForeground", g("base04")),
        ("terminal.background", g("base00")),
        ("terminal.foreground", g("base05")),
        ("focusBorder", g("base0D")),
        ("button.background", g("base0D")),
        ("button.foreground", g("base00")),
        ("list.activeSelectionBackground", g("base02")),
        ("list.hoverBackground", g("base01")),
    ] {
        patch.insert(k.into(), Value::String(v));
    }

    let mut n = 0;
    for path in candidate_settings() {
        if !path.is_file() {
            continue;
        }
        let raw = match std::fs::read_to_string(&path) {
            Ok(s) => s,
            Err(_) => continue,
        };
        let mut data: Value = match serde_json::from_str(&raw) {
            Ok(v) => v,
            Err(_) => continue,
        };
        let obj = match data.as_object_mut() {
            Some(o) => o,
            None => continue,
        };
        let existing = obj
            .entry("workbench.colorCustomizations")
            .or_insert_with(|| json!({}));
        if let Some(map) = existing.as_object_mut() {
            for (k, v) in &patch {
                map.insert(k.clone(), v.clone());
            }
        } else {
            *existing = Value::Object(patch.clone());
        }
        // Best-effort chmod + write; skip RO nix-managed files.
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            if let Ok(meta) = std::fs::metadata(&path) {
                let mut perms = meta.permissions();
                perms.set_mode(perms.mode() | 0o200);
                let _ = std::fs::set_permissions(&path, perms);
            }
        }
        match std::fs::write(&path, serde_json::to_string_pretty(&data).unwrap_or_default() + "\n")
        {
            Ok(()) => {
                eprintln!("dendritic-appearance: patched {}", path.display());
                n += 1;
            }
            Err(e) => eprintln!("dendritic-appearance: skip {}: {e}", path.display()),
        }
    }
    Ok(n)
}

fn candidate_settings() -> Vec<PathBuf> {
    let Some(home) = state::home_dir() else {
        return Vec::new();
    };
    vec![
        home.join("Library/Application Support/Cursor/User/settings.json"),
        home.join("Library/Application Support/Antigravity/User/settings.json"),
        home.join("Library/Application Support/Code/User/settings.json"),
        home.join(".config/Cursor/User/settings.json"),
        home.join(".config/Antigravity/User/settings.json"),
        home.join(".config/Code/User/settings.json"),
    ]
}
