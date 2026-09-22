//! Fast-activate prebuilt Darwin profiles / NixOS specialisations (no rebuild).

use std::path::Path;
use std::process::Command;

use crate::state::{self, Variant};

/// Fast-activate a prebuilt profile / NixOS specialisation.
///
/// `specialise` is only true for explicit `set` / `toggle` / `apply`.
/// Supervise reconcile stays on the hot layer so it cannot loop
/// `switch-to-configuration` every poll.
pub fn activate(variant: Variant, specialise: bool) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    {
        let _ = specialise;
        return activate_darwin_prebuilt(variant);
    }
    #[cfg(target_os = "linux")]
    {
        return activate_nixos_specialisation(variant, specialise);
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        let _ = (variant, specialise);
        Ok(())
    }
}

#[cfg(target_os = "macos")]
fn activate_darwin_prebuilt(variant: Variant) -> Result<(), String> {
    // Prebuilt profile swap requires root; the HM supervise agent only owns the hot layer.
    let uid = Command::new("/usr/bin/id")
        .arg("-u")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .and_then(|s| s.trim().parse::<u32>().ok())
        .unwrap_or(1);
    if uid != 0 {
        return Ok(());
    }

    let path_file = state::system_state_dir().join(format!("prebuilt-{}-path", variant.as_str()));
    if !path_file.is_file() {
        eprintln!(
            "dendritic-appearance: no prebuilt for {variant} (nh darwin switch once to cache)"
        );
        return Ok(());
    }
    let prebuilt = std::fs::read_to_string(&path_file)
        .map_err(|e| e.to_string())?
        .trim()
        .to_string();
    let activate = Path::new(&prebuilt).join("activate");
    if !activate.is_file() {
        return Err(format!("missing activate in {prebuilt}"));
    }

    let flag = state::system_state_dir().join("fast-activate");
    let _ = std::fs::write(&flag, b"");
    let status = Command::new(&activate)
        .status()
        .map_err(|e| format!("activate: {e}"))?;
    let _ = std::fs::remove_file(&flag);
    if !status.success() {
        return Err(format!(
            "prebuilt activate failed ({})",
            status.code().unwrap_or(-1)
        ));
    }
    let _ = state::write_appearance_variant(variant);
    Ok(())
}

#[cfg(target_os = "linux")]
fn activate_nixos_specialisation(variant: Variant, specialise: bool) -> Result<(), String> {
    if !specialise {
        return Ok(());
    }

    let uid = Command::new("id")
        .arg("-u")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .and_then(|s| s.trim().parse::<u32>().ok())
        .unwrap_or(1);

    let name = variant.as_str();
    // Prefer the default system profile so we always switch the *base*
    // generation's light/dark specs (not a nested spec of the current one).
    let candidates = [
        format!("/nix/var/nix/profiles/system/specialisation/{name}/bin/switch-to-configuration"),
        format!("/run/current-system/specialisation/{name}/bin/switch-to-configuration"),
    ];
    for bin in candidates {
        let p = Path::new(&bin);
        if p.is_file() {
            eprintln!("dendritic-appearance: specialisation {name} (no rebuild)");
            let st = if uid == 0 {
                Command::new(p).arg("test").status()
            } else {
                Command::new("sudo")
                    .arg("-n")
                    .arg(p)
                    .arg("test")
                    .status()
            }
            .map_err(|e| e.to_string())?;
            if st.success() {
                return Ok(());
            }
            eprintln!(
                "dendritic-appearance: specialisation {name} failed ({})",
                st.code().unwrap_or(-1)
            );
        }
    }
    Ok(())
}
