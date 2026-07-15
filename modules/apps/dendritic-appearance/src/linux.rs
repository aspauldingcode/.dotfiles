//! Linux appearance detect/set + NixOS specialisation fast-activate.

use std::path::Path;
use std::process::Command;

use crate::state::{self, Variant};

pub fn detect() -> Result<Variant, i32> {
    // 1) Our state file (Waybar toggle / previous apply)
    if let Some(v) = state::read_applied_variant() {
        return Ok(v);
    }
    // 2) GNOME/GTK color-scheme if present
    if let Ok(o) = Command::new("gsettings")
        .args(["get", "org.gnome.desktop.interface", "color-scheme"])
        .output()
    {
        if o.status.success() {
            let s = String::from_utf8_lossy(&o.stdout).to_ascii_lowercase();
            if s.contains("dark") {
                return Ok(Variant::Dark);
            }
            if s.contains("light") || s.contains("default") {
                return Ok(Variant::Light);
            }
        }
    }
    // 3) Prefer dark for rice hosts
    Ok(Variant::Dark)
}

pub fn set(v: Variant) -> Result<(), i32> {
    let scheme = match v {
        Variant::Dark => "prefer-dark",
        Variant::Light => "prefer-light",
    };
    let _ = Command::new("gsettings")
        .args(["set", "org.gnome.desktop.interface", "color-scheme", scheme])
        .status();
    let gtk = match v {
        Variant::Dark => "Adwaita-dark",
        Variant::Light => "Adwaita",
    };
    let _ = Command::new("gsettings")
        .args(["set", "org.gnome.desktop.interface", "gtk-theme", gtk])
        .status();
    Ok(())
}

pub fn try_specialisation_activate(v: Variant) {
    // Prefer current system profile specialisation (already built).
    let name = v.as_str();
    let candidates = [
        format!("/run/current-system/specialisation/{name}/bin/switch-to-configuration"),
        format!("/nix/var/nix/profiles/system/specialisation/{name}/bin/switch-to-configuration"),
    ];
    for bin in candidates {
        let p = Path::new(&bin);
        if p.is_file() {
            eprintln!("dendritic-appearance: activating specialisation {name} (no rebuild)");
            let _ = Command::new(p).arg("test").status();
            return;
        }
    }
}
