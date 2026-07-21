//! Hot-patch IDE settings.json from colors.toml (replaces Python helper).
//!
//! Cursor / VS Code / Antigravity settings are often HM nix-store symlinks.
//! Those are immutable — we used to skip them, so wallpaper rotates never
//! reached Cursor. Same pattern as Ghostty/`~/.colors.toml`: read through
//! the symlink, remove it, write a mutable file. `settings.json` is watched
//! live, so no Reload Window is needed.
//!
//! Full `workbench.colorCustomizations` are rebuilt from the Stylix VS Code
//! base16 map (`vscode-base16-map.json`, generated from stylix theme.nix) so
//! every wallpaper rotate updates the whole UI, not a chrome subset.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::OnceLock;

use serde_json::{json, Map, Value};

use crate::palette::load_palette;
use crate::state;

/// vscode-key → [base0X] or [base0X, alphaHex]
static BASE16_MAP: OnceLock<HashMap<String, Vec<String>>> = OnceLock::new();

fn base16_map() -> &'static HashMap<String, Vec<String>> {
    BASE16_MAP.get_or_init(|| {
        serde_json::from_str(include_str!("vscode-base16-map.json")).unwrap_or_default()
    })
}

pub fn patch_from_colors(colors: &Path) -> Result<usize, String> {
    // prev unused for full rebuild; keep signature for wallpaper call site.
    patch_from_colors_remap(colors, None)
}

/// Rebuild IDE colors from `colors`. `prev` is accepted for API compat with
/// wallpaper apply (full Stylix-map rebuild does not need a remap).
pub fn patch_from_colors_remap(
    colors: &Path,
    _prev: Option<&HashMap<String, String>>,
) -> Result<usize, String> {
    let palette = load_palette(colors)?;
    let customs = build_color_customizations(&palette);

    let mut n = 0;
    for path in candidate_settings() {
        if !path_exists_or_symlink(&path) {
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
        obj.insert(
            "workbench.colorCustomizations".into(),
            Value::Object(customs.clone()),
        );

        // Materialize HM nix-store symlink → writable file (Ghostty pattern).
        let was_store_link = is_nix_store_symlink(&path);
        if was_store_link {
            let _ = std::fs::remove_file(&path);
        } else {
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                if let Ok(meta) = std::fs::metadata(&path) {
                    let mut perms = meta.permissions();
                    perms.set_mode(perms.mode() | 0o200);
                    let _ = std::fs::set_permissions(&path, perms);
                }
            }
        }
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        match std::fs::write(
            &path,
            serde_json::to_string_pretty(&data).unwrap_or_default() + "\n",
        ) {
            Ok(()) => {
                eprintln!(
                    "dendritic-appearance: patched {}{}",
                    path.display(),
                    if was_store_link {
                        " (materialized HM symlink)"
                    } else {
                        ""
                    }
                );
                n += 1;
            }
            Err(e)
                if e.kind() == std::io::ErrorKind::PermissionDenied
                    || e.raw_os_error() == Some(30) => {}
            Err(e) => eprintln!("dendritic-appearance: skip {}: {e}", path.display()),
        }
    }
    Ok(n)
}

fn build_color_customizations(palette: &HashMap<String, String>) -> Map<String, Value> {
    let mut out = Map::new();
    let lookup = |slot: &str| -> Option<String> {
        palette
            .get(slot)
            .or_else(|| palette.get(&slot.to_ascii_lowercase()))
            .or_else(|| palette.get(&slot.to_ascii_uppercase()))
            .cloned()
    };
    for (key, spec) in base16_map() {
        let Some(slot) = spec.first() else {
            continue;
        };
        let Some(mut hex) = lookup(slot) else {
            continue;
        };
        if !hex.starts_with('#') {
            hex = format!("#{hex}");
        }
        // Optional alpha suffix (e.g. "C0" → #rrggbbC0), matching Stylix theme.nix.
        if let Some(alpha) = spec.get(1).filter(|a| !a.is_empty()) {
            hex = format!("{hex}{alpha}");
        }
        out.insert(key.clone(), json!(hex));
    }
    // Ensure chrome keys exist even if map parse failed.
    if let Some(b00) = lookup("base00") {
        out.entry("editor.background")
            .or_insert_with(|| json!(ensure_hash(&b00)));
    }
    out
}

fn ensure_hash(hex: &str) -> String {
    if hex.starts_with('#') {
        hex.to_string()
    } else {
        format!("#{hex}")
    }
}

fn is_nix_store_symlink(path: &Path) -> bool {
    match std::fs::symlink_metadata(path) {
        Ok(meta) if meta.file_type().is_symlink() => std::fs::read_link(path)
            .map(|t| t.to_string_lossy().contains("/nix/store/"))
            .unwrap_or(false),
        _ => false,
    }
}

fn path_exists_or_symlink(path: &Path) -> bool {
    path.exists()
        || std::fs::symlink_metadata(path)
            .map(|m| m.file_type().is_symlink())
            .unwrap_or(false)
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
