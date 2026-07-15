//! Wallpaper pack apply in pure Rust (no bash/python/jq).

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

#[derive(Debug, Deserialize)]
struct Entry {
    name: String,
    image: String,
    colors: Colors,
}

#[derive(Debug, Deserialize)]
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
    let _ = ide::patch_from_colors(&colors_dst);
    state::write_wallpaper_state(&entry.name, &entry.image, variant, mode, idx);

    eprintln!(
        "dendritic-appearance: wallpaper {} ({variant}, {mode})",
        entry.name
    );
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

pub fn list() -> Result<(), String> {
    let manifest = load_manifest()?;
    for e in &manifest.wallpapers {
        println!("{}\t{}", e.name, e.image);
    }
    Ok(())
}
