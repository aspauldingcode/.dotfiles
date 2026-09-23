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

/// Bump when clone/sign procedure changes so a broken dest is replaced.
const CLONE_GEN: &str = "ditto-v1";

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

fn bundle_ok(app: &Path) -> bool {
    app.join("Contents/MacOS/Spotify").is_file() && !app.join("Spotify.app").exists()
}

fn force_rm(path: &Path) {
    if !path.exists() {
        return;
    }
    let _ = Command::new("/usr/bin/chflags")
        .args(["-R", "nouchg,noschg"])
        .arg(path)
        .status();
    let _ = Command::new("/bin/chmod")
        .args(["-R", "u+w"])
        .arg(path)
        .status();
    let _ = Command::new("/bin/rm").args(["-rf"]).arg(path).status();
}

fn adhoc_sign(app: &Path) -> Result<(), String> {
    let _ = Command::new("/usr/bin/xattr")
        .args(["-cr"])
        .arg(app)
        .status();
    let st = Command::new("/usr/bin/codesign")
        .args(["--force", "--sign", "-"])
        .arg(app)
        .status()
        .map_err(|e| format!("codesign Spotify.app: {e}"))?;
    if !st.success() {
        return Err("codesign Spotify.app failed".into());
    }
    Ok(())
}

/// `ditto` into a staging dir, then replace dest. Never `cp -R` onto an
/// existing `.app`: BSD cp nests `Spotify.app/Spotify.app` and Dock then
/// launches the outer husk (no `Contents/MacOS` → "damaged or incomplete").
fn copy_app(src: &Path, dest: &Path) -> Result<(), String> {
    let staging = dest.with_file_name("Spotify.app.staging");
    force_rm(&staging);
    let st = Command::new("/usr/bin/ditto")
        .arg(src)
        .arg(&staging)
        .status()
        .map_err(|e| format!("ditto Spotify.app: {e}"))?;
    if !st.success() {
        force_rm(&staging);
        return Err("ditto Spotify.app failed".into());
    }
    if !bundle_ok(&staging) {
        force_rm(&staging);
        return Err("ditto Spotify.app incomplete (missing Contents/MacOS/Spotify)".into());
    }
    let _ = Command::new("/bin/chmod")
        .args(["-R", "u+w"])
        .arg(&staging)
        .status();
    if let Err(e) = adhoc_sign(&staging) {
        force_rm(&staging);
        return Err(e);
    }
    force_rm(dest);
    std::fs::rename(&staging, dest).map_err(|e| {
        force_rm(&staging);
        format!("mv Spotify.app: {e}")
    })?;
    Ok(())
}

/// Complete writable clone of the store bundle. Returns whether dest was replaced.
fn ensure_clone() -> Result<(PathBuf, bool), String> {
    let src = store_app().ok_or_else(|| "no Spotify.app (install spicetify first)".to_string())?;
    let src_real = resolve_src(&src);
    let dest = live_app();
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    let marker = dest.parent().unwrap_or(Path::new(".")).join("spotify-src");
    let prev = std::fs::read_to_string(&marker).unwrap_or_default();
    let want = format!("{}\n{CLONE_GEN}", src_real.display());
    let cloned = prev.trim() != want || !bundle_ok(&dest);
    if cloned {
        copy_app(&src_real, &dest)?;
        let _ = std::fs::write(&marker, format!("{want}\n"));
    }
    Ok((dest, cloned))
}

/// Link `tinted-palette.css` in index.html the same way Spicetify
/// links `colors.css`. Dynamic `<link>` / extra `extensions/*.js` are
/// unreliable in Spotify's CEF (CSP / interceptor). Do not rewrite
/// `dendritic-tint.js` — modifying a registered extension script
/// prevents it from executing.
fn ensure_palette_html(index_html: &Path, bust: &str) -> Result<bool, String> {
    let Ok(html) = std::fs::read_to_string(index_html) else {
        return Ok(false);
    };
    let mut next = html;
    let mut changed = false;

    const COLORS: &str = "<link rel='stylesheet' class='userCSS' href='colors.css'>";
    let user_want = format!("href='user.css?tb={bust}'");
    if next.contains("href='user.css'>") {
        next = next.replace("href='user.css'>", &format!("{user_want}>"));
        changed = true;
    } else if !next.contains(&user_want) {
        if let Some(i) = next.find("href='user.css?") {
            if let Some(j) = next[i + 6..].find('\'') {
                let old = next[i..i + 6 + j + 1].to_string();
                next = next.replace(&old, &user_want);
                changed = true;
            }
        }
    }

    if !next.contains("tinted-palette.css") {
        if next.contains(COLORS) {
            next = next.replace(COLORS, &format!("{COLORS}\n<link rel='stylesheet' class='userCSS' href='tinted-palette.css'>"));
            changed = true;
        }
    }

    if changed {
        std::fs::write(index_html, next)
            .map_err(|e| format!("write {}: {e}", index_html.display()))?;
    }
    Ok(changed)
}

const USER_CSS_MARK_START: &str = "/*dendritic-palette*/";
const USER_CSS_MARK_END: &str = "/*dendritic-palette-end*/";

/// Spicetify always serves `user.css`. Extra files next to xpui 404 in
/// CEF even when linked from index.html; writing tokens here is what
/// actually reaches `getComputedStyle` for the LUT inject.
fn write_user_css_palette(user_css: &Path, css: &str) -> Result<bool, String> {
    let prev = std::fs::read_to_string(user_css).unwrap_or_default();
    let rest = if let Some(i) = prev.find(USER_CSS_MARK_END) {
        prev[i + USER_CSS_MARK_END.len()..]
            .trim_start_matches(['\n', '\r'])
            .to_string()
    } else if prev.contains(USER_CSS_MARK_START) {
        String::new()
    } else {
        prev.clone()
    };
    let block = format!("{USER_CSS_MARK_START}\n{css}{USER_CSS_MARK_END}\n");
    let next = format!("{block}{rest}");
    if next == prev {
        return Ok(false);
    }
    write_if_changed(user_css, &next)
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
        let (dest, cloned) = match ensure_clone() {
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
        let js = tinted::palette_js(&p)?;
        let ext = xpui.join("extensions");
        let mut changed = false;
        // Root copies: same-origin relative URLs if CEF maps them.
        // extensions/: Spicetify script interceptor; fetch/script of
        // these paths is what actually works in Spotify's CEF.
        for (dir, name, body) in [
            (xpui.as_path(), "tinted-palette.json", json.as_str()),
            (xpui.as_path(), "tinted-palette.css", css.as_str()),
            (ext.as_path(), "tinted-palette.json", json.as_str()),
            (ext.as_path(), "tinted-palette.css", css.as_str()),
            (ext.as_path(), "tinted-palette.js", js.as_str()),
        ] {
            changed |= write_if_changed(&dir.join(name), body)?;
        }
        if changed {
            eprintln!(
                "dendritic-appearance: spotify palette {}",
                ext.join("tinted-palette.js").display()
            );
        }
        changed |= write_user_css_palette(&xpui.join("user.css"), &css)?;
        let bust: String = p
            .get("base00")
            .map(|s| s.trim_start_matches('#').chars().take(8).collect())
            .unwrap_or_else(|| "palette".into());
        changed |= ensure_palette_html(&xpui.join("index.html"), &bust)?;
        if cloned || changed {
            if let Err(e) = adhoc_sign(&dest) {
                eprintln!("dendritic-appearance: spotify sign: {e}");
            }
        }
        Ok(())
    }
}
