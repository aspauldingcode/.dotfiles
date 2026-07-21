//! Wallpaper pack apply in pure Rust (no bash/python/jq).
//!
//! Desktop + auth surfaces are driven from the same pack when
//! `dendritic.wallpaper.enable` is on:
//!   - Desktop: day-of-year / next / named (macos-wallpaper / swaybg)
//!   - Linux gtkgreet/gtklock: **same image as desktop** (auth-path + /var/lib/dendritic/auth)
//!   - macOS Idle lock: next pack entry ≠ desktop (Index.plist)

use std::path::{Path, PathBuf};
use std::process::Command;

use serde::Deserialize;

use crate::ide;
use crate::observe::colors_toml_path;
use crate::state::{self, Variant};

#[derive(Debug, Deserialize)]
struct Manifest {
    wallpapers: Vec<Entry>,
}

#[derive(Debug, Clone, Deserialize)]
struct Entry {
    name: String,
    image: String,
    /// Pre-blurred crop for gtklock glass; falls back to `image` if absent.
    #[serde(default)]
    blur: Option<String>,
    colors: Colors,
}

#[derive(Debug, Clone, Deserialize)]
struct Colors {
    dark: String,
    light: String,
}

fn pack_dir() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_WALLPAPER_PACK") {
        return PathBuf::from(p);
    }
    // HM installs symlink here
    if let Some(home) = state::home_dir() {
        let p = home.join(".config/dendritic/wallpaper-pack");
        if p.is_dir() || p.is_symlink() {
            return p;
        }
    }
    PathBuf::from("/etc/dendritic/wallpaper-pack")
}

fn load_manifest() -> Result<Manifest, String> {
    let path = pack_dir().join("manifest.json");
    let raw = std::fs::read_to_string(&path).map_err(|e| format!("read {}: {e}", path.display()))?;
    serde_json::from_str(&raw).map_err(|e| format!("parse manifest: {e}"))
}

/// Civil (y, m, d) from days since Unix epoch (Howard Hinnant).
fn civil_from_days(z: i64) -> (i64, u32, u32) {
    let z = z + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 }.div_euclid(146_097);
    let doe = (z - era * 146_097) as u64;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    (y, m as u32, d as u32)
}

/// Day-of-year 1..=366 (UTC; matches prior `date +%j` for same calendar day in UTC).
fn day_of_year() -> usize {
    use std::time::{SystemTime, UNIX_EPOCH};
    let days = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64 / 86_400)
        .unwrap_or(0);
    let (y, m, d) = civil_from_days(days);
    let leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
    let cumul = [0u32, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let mut doy = cumul[(m as usize) - 1] + d;
    if leap && m > 2 {
        doy += 1;
    }
    doy as usize
}

fn day_index(count: usize) -> usize {
    if count == 0 {
        return 0;
    }
    (day_of_year().saturating_sub(1)) % count
}

fn wallpaper_scale() -> String {
    std::env::var("DENDRITIC_WALLPAPER_SCALE").unwrap_or_else(|_| "fill".into())
}

/// Explicit light↔dark image pairs in the curated pack.
fn counterpart(name: &str) -> Option<&'static str> {
    match name {
        "catppuccin-latte" => Some("catppuccin-mocha"),
        "catppuccin-mocha" => Some("catppuccin-latte"),
        "nineish-solarized-light" => Some("nineish-solarized-dark"),
        "nineish-solarized-dark" => Some("nineish-solarized-light"),
        "simple-light-gray" => Some("simple-dark-gray"),
        "simple-dark-gray" => Some("simple-light-gray"),
        _ => None,
    }
}

/// Heuristic polarity from wallpaper name (None = neutral / either ok).
fn name_polarity(name: &str) -> Option<Variant> {
    let n = name.to_ascii_lowercase();
    if n.contains("latte") || n.contains("light") {
        return Some(Variant::Light);
    }
    if n.contains("mocha") || n.contains("dark") || n == "dracula" {
        return Some(Variant::Dark);
    }
    None
}

/// When toggling appearance, keep the same pack slot unless the image is
/// clearly the wrong polarity — then prefer its pair (latte→mocha, etc.).
fn resolve_current_index(manifest: &Manifest, variant: Variant) -> (usize, &'static str) {
    let count = manifest.wallpapers.len();
    let fallback = day_index(count);
    let cur_name = state::read_wallpaper_name();
    let cur_idx = cur_name
        .as_ref()
        .and_then(|n| manifest.wallpapers.iter().position(|e| e.name == *n))
        .unwrap_or(fallback);

    let Some(name) = cur_name.as_deref() else {
        return (cur_idx, "current");
    };
    let Some(pol) = name_polarity(name) else {
        return (cur_idx, "current");
    };
    if pol == variant {
        return (cur_idx, "current");
    }
    if let Some(pair) = counterpart(name) {
        if let Some(pidx) = manifest.wallpapers.iter().position(|e| e.name == pair) {
            return (pidx, "pair");
        }
    }
    // No pair: first wallpaper whose name matches the target polarity.
    if let Some(pidx) = manifest
        .wallpapers
        .iter()
        .position(|e| name_polarity(&e.name) == Some(variant))
    {
        return (pidx, "polarity");
    }
    (cur_idx, "current")
}

/// Lock index: always ≠ desktop when the pack has >1 entries.
fn lock_index(manifest: &Manifest, desktop_idx: Option<usize>) -> usize {
    let count = manifest.wallpapers.len();
    if count == 0 {
        return 0;
    }
    match desktop_idx {
        Some(i) if count > 1 => (i + 1) % count,
        Some(i) => i,
        None if count > 1 => (day_index(count) + 1) % count,
        None => 0,
    }
}

fn pick_lock_entry<'a>(manifest: &'a Manifest, desktop_idx: Option<usize>) -> Result<&'a Entry, String> {
    let idx = lock_index(manifest, desktop_idx);
    let entry = manifest
        .wallpapers
        .get(idx)
        .ok_or_else(|| "empty wallpaper pack".to_string())?;
    if !Path::new(&entry.image).is_file() {
        return Err(format!("missing image {}", entry.image));
    }
    Ok(entry)
}

pub fn apply(variant: Variant, target: &str) -> Result<(), String> {
    let manifest = load_manifest()?;
    let count = manifest.wallpapers.len();
    if count == 0 {
        return Err("empty wallpaper pack".into());
    }

    let (idx, mode) = match target {
        "daily" | "" => (day_index(count), "daily"),
        "next" => {
            let cur = state::read_wallpaper_name()
                .and_then(|n| manifest.wallpapers.iter().position(|e| e.name == n))
                .unwrap_or(0);
            ((cur + 1) % count, "next")
        }
        "current" => resolve_current_index(&manifest, variant),
        name => {
            let idx = manifest
                .wallpapers
                .iter()
                .position(|e| e.name == name)
                .ok_or_else(|| format!("unknown wallpaper '{name}'"))?;
            (idx, "named")
        }
    };

    let entry = &manifest.wallpapers[idx];
    let colors_src = match variant {
        Variant::Dark => &entry.colors.dark,
        Variant::Light => &entry.colors.light,
    };
    if !Path::new(colors_src).is_file() {
        return Err(format!("missing colors file {colors_src}"));
    }
    if !Path::new(&entry.image).is_file() {
        return Err(format!("missing image {}", entry.image));
    }

    let colors_dst = colors_toml_path();
    let _ = std::fs::remove_file(&colors_dst);
    std::fs::copy(colors_src, &colors_dst).map_err(|e| format!("copy colors: {e}"))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&colors_dst, std::fs::Permissions::from_mode(0o644));
    }

    set_os_wallpaper(&entry.image)?;

    // Linux auth (gtkgreet/gtklock) = desktop 1:1. macOS Idle stays ≠ desktop.
    publish_auth_wallpaper(entry)?;
    let (lock_name, lock_image) = {
        #[cfg(target_os = "macos")]
        {
            let lock = pick_lock_entry(&manifest, Some(idx))?;
            apply_lock_wallpaper(lock)?;
            (lock.name.clone(), lock.image.clone())
        }
        #[cfg(not(target_os = "macos"))]
        {
            (entry.name.clone(), entry.image.clone())
        }
    };

    let _ = ide::patch_from_colors(&colors_dst);
    let _ = crate::tmux::apply_from_colors(&colors_dst);
    let _ = crate::qt::apply_from_colors(&colors_dst);
    state::write_wallpaper_state(
        &entry.name,
        &entry.image,
        variant,
        mode,
        idx,
        Some(&lock_name),
        Some(&lock_image),
    );

    eprintln!(
        "dendritic-appearance: wallpaper {} ({variant}, {mode}); auth={}",
        entry.name, entry.name
    );
    Ok(())
}

/// Blur path for an entry (auth-blur.png when present).
fn entry_blur(entry: &Entry) -> &str {
    entry
        .blur
        .as_deref()
        .filter(|p| Path::new(p).is_file())
        .unwrap_or(entry.image.as_str())
}

/// World-readable desktop-current paths for greeter (uid greeter) + gtklock.
/// Dir created by NixOS tmpfiles (`/var/lib/dendritic/auth`, group users).
fn publish_auth_wallpaper(entry: &Entry) -> Result<(), String> {
    let blur = entry_blur(entry);
    let dir = PathBuf::from("/var/lib/dendritic/auth");
    if dir.is_dir() {
        let tsv = format!("{}\t{}\n", entry.image, blur);
        let path = dir.join("current.tsv");
        if let Err(e) = std::fs::write(&path, &tsv) {
            eprintln!(
                "dendritic-appearance: warn: write {}: {e}",
                path.display()
            );
        } else {
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let _ = std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o644));
            }
        }
    }
    // Always mirror under user state for non-greeter consumers.
    if let Some(home) = state::home_dir() {
        let udir = home.join(".local/state/dendritic/auth");
        let _ = std::fs::create_dir_all(&udir);
        let _ = std::fs::write(udir.join("current.tsv"), format!("{}\t{}\n", entry.image, blur));
    }
    Ok(())
}

fn set_os_wallpaper(image: &str) -> Result<(), String> {
    let scale = wallpaper_scale();
    #[cfg(target_os = "macos")]
    {
        let wallpaper = std::env::var("DENDRITIC_MACOS_WALLPAPER_BIN")
            .unwrap_or_else(|_| "wallpaper".into());
        let st = Command::new(&wallpaper)
            .args(["set", image, "--scale", &scale])
            .status()
            .map_err(|e| format!("{wallpaper}: {e}"))?;
        if !st.success() {
            return Err(format!("{wallpaper} set failed"));
        }
        return Ok(());
    }
    #[cfg(target_os = "linux")]
    {
        // Kill every swaybg (not just exact name match failures / multi-instance).
        let _ = Command::new("pkill").args(["-x", "swaybg"]).status();
        let _ = Command::new("pkill").args(["swaybg"]).status();
        std::thread::sleep(std::time::Duration::from_millis(250));
        let child = Command::new("swaybg")
            .args(["-i", image, "-m", &scale])
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("swaybg: {e}"))?;
        std::mem::forget(child);
        return Ok(());
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        let _ = image;
        Ok(())
    }
}

/// Apply lock wallpaper for the current platform.
fn apply_lock_wallpaper(entry: &Entry) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    {
        // Desktop `wallpaper set` rewrites Index.plist; wait before patching Idle.
        std::thread::sleep(std::time::Duration::from_millis(400));
        set_macos_lock_wallpaper(&entry.image)?;
        return Ok(());
    }
    #[cfg(target_os = "linux")]
    {
        // Linux gtklock/gtkgreet use desktop-current via auth-path / current.tsv.
        let _ = entry;
        Ok(())
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        let _ = entry;
        Ok(())
    }
}

/// macOS Sonoma+: set Idle (lock / screen-saver still) image in Wallpaper Index.plist.
#[cfg(target_os = "macos")]
fn set_macos_lock_wallpaper(image: &str) -> Result<(), String> {
    use plist::{Dictionary, Value};
    use std::time::SystemTime;

    let home = state::home_dir().ok_or_else(|| "no home directory".to_string())?;
    let index_path = home.join("Library/Application Support/com.apple.wallpaper/Store/Index.plist");
    if !index_path.is_file() {
        return Err(format!(
            "missing {} (open System Settings → Wallpaper once)",
            index_path.display()
        ));
    }

    let mut root =
        Value::from_file(&index_path).map_err(|e| format!("read Index.plist: {e}"))?;

    let file_url = path_as_file_url(image)?;
    let mut cfg = Dictionary::new();
    cfg.insert("type".into(), Value::String("imageFile".into()));
    let mut url = Dictionary::new();
    url.insert("relative".into(), Value::String(file_url));
    cfg.insert("url".into(), Value::Dictionary(url));

    let mut cfg_buf = Vec::new();
    Value::Dictionary(cfg)
        .to_writer_binary(&mut cfg_buf)
        .map_err(|e| format!("encode Idle Configuration: {e}"))?;
    let cfg_data = Value::Data(cfg_buf);

    let sample_eov = find_desktop_eov(&root);
    let now = Value::Date(SystemTime::now().into());
    let patched = patch_idle_nodes(&mut root, &cfg_data, sample_eov.as_ref(), &now);
    if patched == 0 {
        return Err("no Idle nodes found in Index.plist".into());
    }

    let tmp = index_path.with_extension("plist.tmp");
    root.to_file_binary(&tmp)
        .map_err(|e| format!("write {}: {e}", tmp.display()))?;
    // Validate before replace.
    let _ = Value::from_file(&tmp).map_err(|e| format!("validate tmp Index.plist: {e}"))?;
    std::fs::rename(&tmp, &index_path).map_err(|e| format!("replace Index.plist: {e}"))?;

    let _ = Command::new("killall").arg("WallpaperAgent").status();
    eprintln!("dendritic-appearance: macOS lock wallpaper ({patched} Idle nodes)");
    Ok(())
}

#[cfg(target_os = "macos")]
fn path_as_file_url(path: &str) -> Result<String, String> {
    let p = Path::new(path)
        .canonicalize()
        .map_err(|e| format!("canonicalize {path}: {e}"))?;
    // Match Python Path.as_uri() / existing Index.plist encoding.
    let mut url = String::from("file://");
    for comp in p.components() {
        use std::path::Component;
        match comp {
            Component::RootDir => {}
            Component::Normal(s) => {
                url.push('/');
                url.push_str(&urlencoding_path_component(&s.to_string_lossy()));
            }
            _ => {}
        }
    }
    if !url.starts_with("file:///") {
        url = format!("file://{}", p.display());
    }
    Ok(url)
}

#[cfg(target_os = "macos")]
fn urlencoding_path_component(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

#[cfg(target_os = "macos")]
fn find_desktop_eov(value: &plist::Value) -> Option<plist::Value> {
    match value {
        plist::Value::Dictionary(dict) => {
            if let Some(desktop) = dict.get("Desktop") {
                if let Some(plist::Value::Dictionary(content)) =
                    desktop.as_dictionary().and_then(|d| d.get("Content"))
                {
                    if let Some(eov) = content.get("EncodedOptionValues") {
                        return Some(eov.clone());
                    }
                }
            }
            for v in dict.values() {
                if let Some(found) = find_desktop_eov(v) {
                    return Some(found);
                }
            }
            None
        }
        plist::Value::Array(arr) => {
            for v in arr {
                if let Some(found) = find_desktop_eov(v) {
                    return Some(found);
                }
            }
            None
        }
        _ => None,
    }
}

#[cfg(target_os = "macos")]
fn patch_idle_nodes(
    value: &mut plist::Value,
    cfg_data: &plist::Value,
    sample_eov: Option<&plist::Value>,
    now: &plist::Value,
) -> usize {
    let mut count = 0;
    match value {
        plist::Value::Dictionary(dict) => {
            if let Some(idle) = dict.get_mut("Idle") {
                if let Some(idle_dict) = idle.as_dictionary_mut() {
                    if let Some(content) = idle_dict.get_mut("Content") {
                        if let Some(content_dict) = content.as_dictionary_mut() {
                            if let Some(choices) = content_dict.get_mut("Choices") {
                                if let Some(arr) = choices.as_array_mut() {
                                    if let Some(choice) = arr.get_mut(0) {
                                        if let Some(choice_dict) = choice.as_dictionary_mut() {
                                            choice_dict.insert(
                                                "Provider".into(),
                                                plist::Value::String(
                                                    "com.apple.wallpaper.choice.image".into(),
                                                ),
                                            );
                                            choice_dict.insert(
                                                "Files".into(),
                                                plist::Value::Array(vec![]),
                                            );
                                            choice_dict
                                                .insert("Configuration".into(), cfg_data.clone());
                                            if let Some(eov) = sample_eov {
                                                content_dict.insert(
                                                    "EncodedOptionValues".into(),
                                                    eov.clone(),
                                                );
                                            }
                                            idle_dict.insert("LastSet".into(), now.clone());
                                            idle_dict.insert("LastUse".into(), now.clone());
                                            count += 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for (k, v) in dict.iter_mut() {
                if k == "Idle" {
                    continue;
                }
                count += patch_idle_nodes(v, cfg_data, sample_eov, now);
            }
        }
        plist::Value::Array(arr) => {
            for v in arr.iter_mut() {
                count += patch_idle_nodes(v, cfg_data, sample_eov, now);
            }
        }
        _ => {}
    }
    count
}

pub fn list() -> Result<(), String> {
    let manifest = load_manifest()?;
    for e in &manifest.wallpapers {
        println!("{}\t{}", e.name, e.image);
    }
    Ok(())
}

/// Desktop-current wallpaper for Linux gtkgreet/gtklock (1:1 with swaybg).
/// Prints `image\tblur`.
pub fn resolve_auth() -> Result<(), String> {
    // Prefer published pointer (survives greeter without $HOME of alex).
    for path in [
        PathBuf::from("/var/lib/dendritic/auth/current.tsv"),
        state::home_dir()
            .map(|h| h.join(".local/state/dendritic/auth/current.tsv"))
            .unwrap_or_default(),
    ] {
        if path.is_file() {
            if let Ok(raw) = std::fs::read_to_string(&path) {
                let line = raw.lines().next().unwrap_or("").trim();
                if !line.is_empty() {
                    let mut parts = line.split('\t');
                    if let (Some(image), Some(blur)) = (parts.next(), parts.next()) {
                        if Path::new(image).is_file() {
                            println!("{image}\t{blur}");
                            eprintln!("dendritic-appearance: auth wallpaper (published)");
                            return Ok(());
                        }
                    }
                }
            }
        }
    }

    let manifest = load_manifest()?;
    let cur_idx = state::read_wallpaper_name()
        .and_then(|n| manifest.wallpapers.iter().position(|e| e.name == *n))
        .unwrap_or(0);
    let entry = manifest
        .wallpapers
        .get(cur_idx)
        .ok_or_else(|| "empty wallpaper pack".to_string())?;
    let blur = entry_blur(entry);
    println!("{}\t{}", entry.image, blur);
    eprintln!(
        "dendritic-appearance: auth wallpaper {} (= desktop)",
        entry.name
    );
    Ok(())
}

/// Pack entry for the lock screen.
/// - Linux: same as desktop (`resolve_auth`) for gtklock 1:1.
/// - macOS: next pack entry ≠ desktop (Idle Index.plist).
pub fn resolve_lock() -> Result<(), String> {
    #[cfg(target_os = "linux")]
    {
        return resolve_auth();
    }
    #[cfg(not(target_os = "linux"))]
    {
        let manifest = load_manifest()?;
        let cur_idx = state::read_wallpaper_name()
            .and_then(|n| manifest.wallpapers.iter().position(|e| e.name == *n));
        let entry = pick_lock_entry(&manifest, cur_idx)?;
        let blur = entry_blur(entry);

        println!("{}\t{}", entry.image, blur);
        eprintln!(
            "dendritic-appearance: lock wallpaper {} (desktop={})",
            entry.name,
            cur_idx
                .map(|i| manifest.wallpapers[i].name.as_str())
                .unwrap_or("none")
        );
        Ok(())
    }
}

/// Re-apply lock wallpaper only (desktop unchanged). Useful after System Settings drift.
pub fn apply_lock_only() -> Result<(), String> {
    let manifest = load_manifest()?;
    let cur_idx = state::read_wallpaper_name()
        .and_then(|n| manifest.wallpapers.iter().position(|e| e.name == *n));
    let entry = pick_lock_entry(&manifest, cur_idx)?;
    apply_lock_wallpaper(entry)?;

    // Preserve desktop fields; refresh lock_* in wallpaper.json.
    if let Ok(raw) = std::fs::read_to_string(state::wallpaper_state_path()) {
        if let Ok(mut v) = serde_json::from_str::<serde_json::Value>(&raw) {
            v["lock_name"] = serde_json::json!(entry.name);
            v["lock_image"] = serde_json::json!(entry.image);
            let _ = std::fs::write(
                state::wallpaper_state_path(),
                serde_json::to_string_pretty(&v).unwrap_or_default(),
            );
        }
    }

    eprintln!("dendritic-appearance: lock-only {}", entry.name);
    Ok(())
}
