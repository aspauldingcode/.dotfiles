//! Observe + verify global appearance consistency.

use std::path::PathBuf;

use crate::machine::Observation;
use crate::palette::load_palette;
use crate::state::{self, Variant};

pub fn colors_toml_path() -> PathBuf {
    std::env::var_os("DENDRITIC_COLORS_FILE")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            state::home_dir()
                .map(|h| h.join("colors.toml"))
                .unwrap_or_else(|| PathBuf::from("colors.toml"))
        })
}

pub fn read_colors_variant() -> Option<Variant> {
    let text = std::fs::read_to_string(colors_toml_path()).ok()?;
    let mut in_stylix = false;
    for line in text.lines() {
        let t = line.trim();
        if t.starts_with('[') {
            in_stylix = t == "[stylix]";
            continue;
        }
        if in_stylix && t.starts_with("variant") {
            if let Some((_, v)) = t.split_once('=') {
                return Variant::parse(v.trim().trim_matches('"'));
            }
        }
    }
    None
}

pub fn observe() -> Observation {
    let host = detect_host();
    let recorded = state::read_recorded_variant();
    let colors_variant = read_colors_variant();
    let wallpaper_variant = state::read_wallpaper_variant();
    let wallpaper_name = state::read_wallpaper_name();

    let mut reasons = Vec::new();
    match recorded {
        Some(r) if r != host => reasons.push(format!("recorded={r:?} != host={host:?}")),
        None => reasons.push("recorded variant missing".into()),
        _ => {}
    }
    match colors_variant {
        Some(c) if c != host => reasons.push(format!("colors.toml={c:?} != host={host:?}")),
        None => reasons.push("colors.toml variant missing".into()),
        _ => {}
    }
    match wallpaper_variant {
        Some(w) if w != host => reasons.push(format!("wallpaper.json={w:?} != host={host:?}")),
        None => {
            // Wallpaper state may be absent on first boot; treat as desync so we apply.
            reasons.push("wallpaper.json variant missing".into());
        }
        _ => {}
    }

    // Palette must parse if colors exist (corrupt file = desync).
    if colors_toml_path().is_file() {
        if let Err(e) = load_palette(&colors_toml_path()) {
            reasons.push(format!("colors.toml unreadable: {e}"));
        }
    }

    Observation {
        host,
        recorded,
        colors_variant,
        wallpaper_variant,
        wallpaper_name,
        reasons,
    }
}

fn detect_host() -> Variant {
    #[cfg(target_os = "macos")]
    {
        crate::macos::detect().unwrap_or(Variant::Light)
    }
    #[cfg(target_os = "linux")]
    {
        crate::linux::detect_host()
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        state::read_recorded_variant().unwrap_or(Variant::Dark)
    }
}
