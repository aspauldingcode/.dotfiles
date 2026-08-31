//! Hot-write TintedBrowse palette tokens into Vesktop QuickCSS.
//!
//! Discord chrome stays native. The LUT rewriter (Chrome extension /
//! inject.js) walks authored CSS colors — same pipeline as TintedBrowse.

use std::path::{Path, PathBuf};

use crate::palette::load_palette;
use crate::state;
use crate::tinted;

fn vesktop_root() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_VESKTOP_DIR") {
        return PathBuf::from(p);
    }
    let home = state::home_dir().unwrap_or_else(|| PathBuf::from("."));
    #[cfg(target_os = "macos")]
    {
        home.join("Library/Application Support/vesktop")
    }
    #[cfg(not(target_os = "macos"))]
    {
        home.join(".config/vesktop")
    }
}

fn write_replace(path: &Path, body: &str) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    if path.is_file() && !path.is_symlink() {
        if let Ok(prev) = std::fs::read_to_string(path) {
            if prev == body {
                return Ok(());
            }
        }
    }
    let _ = std::fs::remove_file(path);
    std::fs::write(path, body).map_err(|e| format!("write {}: {e}", path.display()))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o644));
    }
    Ok(())
}

fn patch_splash(path: &Path, b00: &str, b0d: &str) {
    let raw = std::fs::read_to_string(path).unwrap_or_else(|_| "{}".into());
    let mut data: serde_json::Value = serde_json::from_str(&raw).unwrap_or(serde_json::json!({}));
    if let Some(obj) = data.as_object_mut() {
        obj.insert("splashBackground".into(), serde_json::json!(b00));
        obj.insert(
            "splashColor".into(),
            serde_json::json!(format!("{b0d}; --fg-semi-trans: transparent")),
        );
        obj.insert("splashTheming".into(), serde_json::json!(true));
        let _ = std::fs::remove_file(path);
        if let Ok(s) = serde_json::to_string_pretty(&data) {
            let _ = std::fs::write(path, s);
        }
    }
}

pub fn apply_from_colors(colors_path: &Path) -> Result<(), String> {
    let p = load_palette(colors_path)?;
    let css = tinted::palette_css(&p)?;
    let root = vesktop_root();
    if !root.is_dir() {
        return Ok(());
    }
    write_replace(&root.join("settings/quickCss.css"), &css)?;
    // Drop leftover Stylix chrome themes so Discord stays native for the LUT.
    for stale in [
        "themes/stylix.css",
        "themes/dendritic-overrides.css",
    ] {
        let _ = std::fs::remove_file(root.join(stale));
    }
    if let (Some(b00), Some(b0d)) = (p.get("base00"), p.get("base0D")) {
        patch_splash(&root.join("settings.json"), b00, b0d);
    }
    eprintln!(
        "dendritic-appearance: vesktop palette {}",
        root.join("settings/quickCss.css").display()
    );
    Ok(())
}
