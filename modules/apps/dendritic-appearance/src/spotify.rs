//! Hot-write TintedBrowse palette JSON into the Spotify clone.
//!
//! Does not remap `--spice-*`. The Spicetify extension runs the same
//! LUT rewriter as TintedBrowse against Spotify's native CSS.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::palette::load_palette;
use crate::state;
use crate::tinted;

fn live_app() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_SPOTIFY_LIVE") {
        return PathBuf::from(p);
    }
    state::user_state_dir().join("Spotify.app")
}

fn store_app() -> Option<PathBuf> {
    if let Ok(p) = std::env::var("DENDRITIC_SPOTIFY_APP") {
        let pb = PathBuf::from(p);
        if pb.exists() {
            return Some(pb);
        }
    }
    let home = state::home_dir()?;
    let hm = home.join("Applications/Home Manager Apps/Spotify.app");
    if hm.exists() {
        return Some(hm);
    }
    None
}

fn resolve_src(app: &Path) -> PathBuf {
    std::fs::canonicalize(app).unwrap_or_else(|_| app.to_path_buf())
}

/// APFS clonefile when src generation changes.
fn ensure_clone() -> Result<PathBuf, String> {
    let src = store_app().ok_or_else(|| "no Spotify.app (install spicetify first)".to_string())?;
    let src_real = resolve_src(&src);
    let dest = live_app();
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    let marker = dest.parent().unwrap_or(Path::new(".")).join("spotify-src");
    let prev = std::fs::read_to_string(&marker).unwrap_or_default();
    let want = format!("{}\nlut-v1", src_real.display());
    if prev.trim() != want || !dest.exists() {
        let _ = Command::new("/bin/chmod")
            .args(["-R", "u+w"])
            .arg(&dest)
            .status();
        let _ = std::fs::remove_dir_all(&dest);
        let st = Command::new("/bin/cp")
            .args([
                "-cR",
                src_real.to_str().unwrap_or(""),
                dest.to_str().unwrap_or(""),
            ])
            .status()
            .map_err(|e| format!("cp Spotify.app: {e}"))?;
        if !st.success() {
            return Err("cp -cR Spotify.app failed".into());
        }
        let _ = Command::new("/bin/chmod")
            .args(["-R", "u+w"])
            .arg(&dest)
            .status();
        let _ = std::fs::write(&marker, format!("{want}\n"));
    }
    Ok(dest)
}

fn write_if_changed(path: &Path, body: &str) -> Result<bool, String> {
    if path.is_file() {
        if let Ok(prev) = std::fs::read_to_string(path) {
            if prev == body {
                return Ok(false);
            }
        }
    }
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    let _ = std::fs::remove_file(path);
    std::fs::write(path, body).map_err(|e| format!("write {}: {e}", path.display()))?;
    Ok(true)
}

pub fn apply_from_colors(colors_path: &Path) -> Result<(), String> {
    #[cfg(not(target_os = "macos"))]
    {
        let _ = colors_path;
        return Ok(());
    }
    #[cfg(target_os = "macos")]
    {
        let p: HashMap<String, String> = load_palette(colors_path)?;
        let dest = match ensure_clone() {
            Ok(d) => d,
            Err(e) => {
                eprintln!("dendritic-appearance: spotify skip: {e}");
                return Ok(());
            }
        };
        let xpui = dest.join("Contents/Resources/Apps/xpui");
        if !xpui.is_dir() {
            eprintln!(
                "dendritic-appearance: spotify missing xpui {}",
                xpui.display()
            );
            return Ok(());
        }
        let json = tinted::palette_json(&p)?;
        let css = tinted::palette_css(&p)?;
        let json_path = xpui.join("tinted-palette.json");
        let css_path = xpui.join("tinted-palette.css");
        let changed_json = write_if_changed(&json_path, &json)?;
        let changed_css = write_if_changed(&css_path, &css)?;
        if changed_json || changed_css {
            eprintln!(
                "dendritic-appearance: spotify palette {}",
                json_path.display()
            );
        }
        Ok(())
    }
}
