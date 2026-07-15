//! macOS: detect/set without osascript. Tint from colors.toml.

use std::path::Path;
use std::process::Command;

use crate::palette::{hex_to_tint_str, load_palette};
use crate::state::Variant;

pub fn detect() -> Result<Variant, i32> {
    // NSGlobalDomain / -g is the live host truth. Avoid passing a bare
    // `.GlobalPreferences` path (defaults treats that as a missing domain).
    let output = Command::new("/usr/bin/defaults")
        .args(["read", "-g", "AppleInterfaceStyle"])
        .output();
    match output {
        Ok(o) if o.status.success() => {
            let s = String::from_utf8_lossy(&o.stdout).to_ascii_lowercase();
            Ok(if s.contains("dark") {
                Variant::Dark
            } else {
                Variant::Light
            })
        }
        // Key missing ⇒ light
        _ => Ok(Variant::Light),
    }
}

pub fn set(v: Variant) -> Result<(), i32> {
    if skylight_set(v) {
        sync_defaults_key(v);
        return Ok(());
    }
    eprintln!("dendritic-appearance: SkyLight unavailable; defaults fallback");
    sync_defaults_key(v);
    let _ = Command::new("/usr/bin/killall")
        .args(["cfprefsd", "SystemUIServer"])
        .status();
    Ok(())
}

fn sync_defaults_key(v: Variant) {
    match v {
        Variant::Dark => {
            let _ = Command::new("/usr/bin/defaults")
                .args(["write", "-g", "AppleInterfaceStyle", "-string", "Dark"])
                .status();
        }
        Variant::Light => {
            let _ = Command::new("/usr/bin/defaults")
                .args(["delete", "-g", "AppleInterfaceStyle"])
                .status();
            let _ = Command::new("/usr/bin/defaults")
                .args(["delete", "-g", "AppleInterfaceStyleSwitchesAutomatically"])
                .status();
        }
    }
}

fn skylight_set(v: Variant) -> bool {
    unsafe {
        let lib = match libloading::Library::new(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
        ) {
            Ok(l) => l,
            Err(_) => return false,
        };
        if let Ok(f) = lib
            .get::<unsafe extern "C" fn(u8)>(b"SLSSetAppearanceThemeSwitchesAutomatically")
        {
            f(0);
        }
        if let Ok(f) = lib.get::<unsafe extern "C" fn(u8)>(b"SLSSetAppearanceThemeLegacy") {
            f(match v {
                Variant::Dark => 1,
                Variant::Light => 0,
            });
            return true;
        }
        if let Ok(f) = lib.get::<unsafe extern "C" fn(i64)>(b"SLSSetAppearanceTheme") {
            f(match v {
                Variant::Dark => 1,
                Variant::Light => 0,
            });
            return true;
        }
    }
    false
}

pub fn apply_tint_from_colors_toml(path: &Path) -> Result<(), i32> {
    let palette = load_palette(path).map_err(|e| {
        eprintln!("dendritic-appearance: {e}");
        1
    })?;
    let hex = palette
        .get("base0D")
        .or_else(|| palette.get("base0E"))
        .ok_or(1)?;
    let tint = hex_to_tint_str(hex).map_err(|_| 1)?;

    defaults_write_str("AppleIconAppearanceTintColor", "Other")?;
    defaults_write_str("AppleIconAppearanceCustomTintColor", &tint)?;
    defaults_write_str("AppleHighlightColor", &tint)?;
    defaults_write_int("AppleAccentColor", 4)?;
    defaults_write_str("AppleAccentColorVariant", &tint)?;
    defaults_write_str("AppleIconAppearanceStyle", "Tinted")?;
    defaults_write_str("AppleIconAppearanceMode", "Auto")?;

    let _ = Command::new("/usr/bin/killall")
        .args(["Dock", "Finder", "SystemUIServer"])
        .status();
    Ok(())
}

fn defaults_write_str(key: &str, value: &str) -> Result<(), i32> {
    let st = Command::new("/usr/bin/defaults")
        .args(["write", "-g", key, "-string", value])
        .status()
        .map_err(|_| 1)?;
    if st.success() {
        Ok(())
    } else {
        Err(1)
    }
}

fn defaults_write_int(key: &str, value: i32) -> Result<(), i32> {
    let st = Command::new("/usr/bin/defaults")
        .args(["write", "-g", key, "-int", &value.to_string()])
        .status()
        .map_err(|_| 1)?;
    if st.success() {
        Ok(())
    } else {
        Err(1)
    }
}
