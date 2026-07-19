//! Apply declarative profile photo (macOS Open Directory + Linux AccountsService/.face).

use std::path::{Path, PathBuf};
use std::process::Command;

use crate::state;

fn default_image() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_PROFILE_IMAGE") {
        return PathBuf::from(p);
    }
    if let Some(home) = state::home_dir() {
        for cand in [
            home.join(".config/dendritic/profile.jpg"),
            home.join("Library/Application Support/dendritic/profile.jpg"),
        ] {
            if cand.is_file() {
                return cand;
            }
        }
    }
    PathBuf::from("/etc/dendritic/profile.jpg")
}

fn resolve_user(explicit: Option<&str>) -> String {
    if let Some(u) = explicit {
        return u.to_string();
    }
    if let Ok(u) = std::env::var("DENDRITIC_USER") {
        if !u.is_empty() {
            return u;
        }
    }
    if let Ok(u) = std::env::var("USER") {
        if !u.is_empty() {
            return u;
        }
    }
    whoami().unwrap_or_else(|| "unknown".into())
}

fn whoami() -> Option<String> {
    let out = Command::new("id").arg("-un").output().ok()?;
    if !out.status.success() {
        return None;
    }
    let s = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if s.is_empty() {
        None
    } else {
        Some(s)
    }
}

/// `avatar apply [--user NAME] [--image PATH]`
pub fn apply(args: &[String]) -> Result<(), String> {
    let mut user = None;
    let mut image = None;
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--user" => {
                i += 1;
                user = args.get(i).map(|s| s.as_str());
            }
            "--image" => {
                i += 1;
                image = args.get(i).map(|s| s.as_str());
            }
            other => return Err(format!("unknown avatar arg: {other}")),
        }
        i += 1;
    }

    let username = resolve_user(user);
    let image_path = image
        .map(PathBuf::from)
        .unwrap_or_else(default_image);

    if !image_path.is_file() {
        return Err(format!("profile image missing: {}", image_path.display()));
    }

    #[cfg(target_os = "macos")]
    {
        apply_macos(&username, &image_path)?;
    }
    #[cfg(target_os = "linux")]
    {
        apply_linux(&username, &image_path)?;
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        let _ = (username, image_path);
    }

    Ok(())
}

#[cfg(target_os = "macos")]
fn apply_macos(username: &str, image: &Path) -> Result<(), String> {
    // Durable path outside the nix store (survives GC; Picture attribute needs a stable file).
    let library = PathBuf::from("/Library/User Pictures/Dendritic");
    let durable = library.join("profile.jpg");
    let _ = Command::new("mkdir").args(["-p", library.to_str().unwrap()]).status();

    // Prefer sips (always on macOS) to normalize JPEG ≤512px for JPEGPhoto.
    let staged = std::env::temp_dir().join(format!("dendritic-avatar-{username}.jpg"));
    let sips = Command::new("sips")
        .args([
            "-s",
            "format",
            "jpeg",
            "-Z",
            "512",
            &image.to_string_lossy(),
            "--out",
            &staged.to_string_lossy(),
        ])
        .status()
        .map_err(|e| format!("sips: {e}"))?;
    if !sips.success() {
        // Fall back to raw copy if sips fails.
        std::fs::copy(image, &staged).map_err(|e| format!("copy stage: {e}"))?;
    }

    std::fs::copy(&staged, &durable).map_err(|e| {
        format!(
            "install {}: {e} (daemon must run as root to write /Library/User Pictures)",
            durable.display()
        )
    })?;
    let _ = Command::new("chmod").args(["644", durable.to_str().unwrap()]).status();

    // Also refresh the per-user Application Support copy (HM may consume it).
    if let Some(home) = state::home_dir() {
        let user_copy = home.join("Library/Application Support/dendritic/profile.jpg");
        let _ = std::fs::create_dir_all(user_copy.parent().unwrap());
        let _ = std::fs::copy(&durable, &user_copy);
    }

    let user_path = format!("/Users/{username}");

    // Wipe both attrs then re-set — otherwise stale JPEGPhoto wins over Picture.
    let _ = Command::new("dscl")
        .args([".", "-delete", &user_path, "JPEGPhoto"])
        .status();
    let _ = Command::new("dscl")
        .args([".", "-delete", &user_path, "Picture"])
        .status();

    let st = Command::new("dscl")
        .args([
            ".",
            "-create",
            &user_path,
            "Picture",
            durable.to_str().unwrap(),
        ])
        .status()
        .map_err(|e| format!("dscl Picture: {e}"))?;
    if !st.success() {
        return Err(
            "dscl create Picture failed (need root launchd daemon — darwin-rebuild installs it)"
                .into(),
        );
    }

    // Embed JPEGPhoto via dsimport so System Settings / login chrome stay filled.
    let import = std::env::temp_dir().join(format!("dendritic-dsimport-{username}"));
    let body = format!(
        "0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto\n{username}:{}\n",
        durable.display()
    );
    std::fs::write(&import, body).map_err(|e| format!("write dsimport: {e}"))?;
    let st = Command::new("dsimport")
        .args([import.to_str().unwrap(), "/Local/Default", "M"])
        .status()
        .map_err(|e| format!("dsimport: {e}"))?;
    let _ = std::fs::remove_file(&import);
    let _ = std::fs::remove_file(&staged);
    if !st.success() {
        return Err("dsimport JPEGPhoto failed".into());
    }

    let _ = Command::new("dscacheutil").arg("-flushcache").status();
    eprintln!(
        "dendritic-appearance: avatar {username} → {}",
        durable.display()
    );
    Ok(())
}

#[cfg(target_os = "linux")]
fn apply_linux(username: &str, image: &Path) -> Result<(), String> {
    let image_s = image.to_str().unwrap_or("");
    // AccountsService icon (gtklock-userinfo / greetd) — needs root.
    let icon = PathBuf::from(format!("/var/lib/AccountsService/icons/{username}"));
    let icon_s = icon.to_string_lossy().into_owned();
    let _ = Command::new("sudo")
        .args(["-n", "mkdir", "-p", "/var/lib/AccountsService/icons"])
        .status();
    let copied = Command::new("sudo")
        .args(["-n", "cp", "-f", image_s, &icon_s])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    if copied {
        let _ = Command::new("sudo")
            .args(["-n", "chmod", "644", &icon_s])
            .status();
        let user_cfg = format!("/var/lib/AccountsService/users/{username}");
        let body = format!("[User]\nSession=\nIcon={icon_s}\nSystemAccount=false\n");
        let _ = Command::new("sudo")
            .args(["-n", "tee", &user_cfg])
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .and_then(|mut c| {
                use std::io::Write;
                if let Some(mut stdin) = c.stdin.take() {
                    let _ = stdin.write_all(body.as_bytes());
                }
                c.wait()
            });
    } else if let Err(e) = std::fs::copy(image, &icon) {
        // Quiet when unprivileged — CSS avatar still works from stylix auth template.
        let _ = e;
    }

    // Classic ~/.face — skip when HM symlinks into the nix store (immutable).
    if let Some(home) = state::home_dir() {
        let face = home.join(".face");
        let face_icon = home.join(".face.icon");
        let store_link = std::fs::read_link(&face)
            .map(|t| t.to_string_lossy().contains("/nix/store/"))
            .unwrap_or(false);
        if !store_link {
            if let Err(e) = std::fs::copy(image, &face) {
                if e.raw_os_error() != Some(30) {
                    eprintln!("dendritic-appearance: .face skip: {e}");
                }
            } else {
                let _ = std::fs::copy(&face, &face_icon);
            }
        }
    }

    eprintln!(
        "dendritic-appearance: avatar {username} → {}",
        image.display()
    );
    Ok(())
}
