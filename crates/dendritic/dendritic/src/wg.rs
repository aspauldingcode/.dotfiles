//! WireGuard ensure orchestration (conf via existing script; privilege via helper IPC).

use std::path::PathBuf;
use std::process::Command;

use anyhow::{bail, Context, Result};

use crate::client;

fn find_ensure_script() -> Result<PathBuf> {
    if let Ok(p) = std::env::var("DENDRITIC_WG_ENSURE") {
        let pb = PathBuf::from(p);
        if pb.is_file() {
            return Ok(pb);
        }
    }
    if let Ok(p) = which("dendritic-wg-ensure") {
        return Ok(p);
    }
    // Repo-relative when developing.
    for root in [
        std::env::var_os("DOTFILES_ROOT").map(PathBuf::from),
        Some(PathBuf::from("/etc/nix-darwin/.dotfiles")),
        Some(PathBuf::from("/etc/nixos/.dotfiles")),
    ]
    .into_iter()
    .flatten()
    {
        let cand = root.join("scripts/dendritic-wg-ensure.sh");
        if cand.is_file() {
            return Ok(cand);
        }
    }
    bail!("dendritic-wg-ensure not found (set DENDRITIC_WG_ENSURE)")
}

fn which(bin: &str) -> Result<PathBuf> {
    let path = std::env::var_os("PATH").unwrap_or_default();
    for dir in std::env::split_paths(&path) {
        let cand = dir.join(bin);
        if cand.is_file() {
            return Ok(cand);
        }
    }
    bail!("{bin} not found")
}

/// Build conf (bash/pass) then install+up via privileged helper when available.
pub fn ensure(no_up: bool) -> Result<()> {
    let script = find_ensure_script()?;
    let mut cmd = if script.extension().and_then(|s| s.to_str()) == Some("sh") {
        let mut c = Command::new("bash");
        c.arg(&script);
        c
    } else {
        Command::new(&script)
    };
    cmd.env("WG_SUDO_INTERACTIVE", "0");
    cmd.env("WG_PREFER_DENDRITIC_HELPER", "1");
    if no_up {
        cmd.env("WG_ENSURE_NO_UP", "1");
    }
    let status = cmd
        .status()
        .with_context(|| format!("run {}", script.display()))?;
    if !status.success() {
        // Conf may still have been written to XDG; try helper install+up.
        if !no_up {
            let _ = try_helper_bringup();
        }
        bail!("wg ensure script failed: {status}");
    }
    Ok(())
}

fn try_helper_bringup() -> Result<()> {
    let home = std::env::var_os("HOME").map(PathBuf::from).unwrap_or_default();
    let user_conf = home
        .join(".config/dendritic/wireguard/dendritic.conf");
    if user_conf.is_file() {
        client::wg_install_conf("dendritic".into(), user_conf)?;
        client::wg_up("dendritic".into())?;
    }
    Ok(())
}

pub fn install_conf(iface: String, source: PathBuf) -> Result<()> {
    client::wg_install_conf(iface, source)
}

pub fn up(iface: String) -> Result<()> {
    client::wg_up(iface)
}

pub fn down(iface: String) -> Result<()> {
    client::wg_down(iface)
}
