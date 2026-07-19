//! Linux host appearance.

use std::process::Command;

use crate::state::{self, Variant};

/// Source of truth on Linux: committed dendritic state, then gsettings.
pub fn detect_host() -> Variant {
    if let Some(v) = state::read_recorded_variant() {
        return v;
    }
    if let Ok(o) = Command::new("gsettings")
        .args(["get", "org.gnome.desktop.interface", "color-scheme"])
        .output()
    {
        if o.status.success() {
            let s = String::from_utf8_lossy(&o.stdout).to_ascii_lowercase();
            if s.contains("prefer-dark") || s.contains("dark") {
                return Variant::Dark;
            }
            if s.contains("prefer-light") || s.contains("light") {
                return Variant::Light;
            }
        }
    }
    Variant::Dark
}

pub fn set(v: Variant) -> Result<(), i32> {
    let scheme = match v {
        Variant::Dark => "prefer-dark",
        Variant::Light => "prefer-light",
    };
    let _ = Command::new("gsettings")
        .args(["set", "org.gnome.desktop.interface", "color-scheme", scheme])
        .status();
    // Persist first so detect_host is deterministic even without gsettings.
    let _ = state::write_appearance_variant(v);
    Ok(())
}
