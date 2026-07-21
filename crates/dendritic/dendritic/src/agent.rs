//! Day-to-day agent entrypoints — stable `dendritic <cmd>` for launchd/systemd.
//! Delegates to wrapped scripts/bins from the Nix profile when present.

use std::path::PathBuf;
use std::process::{Command, Stdio};

use anyhow::{bail, Context, Result};

fn which(bin: &str) -> Option<PathBuf> {
    let path = std::env::var_os("PATH")?;
    for dir in std::env::split_paths(&path) {
        let cand = dir.join(bin);
        if cand.is_file() {
            return Some(cand);
        }
    }
    None
}

fn run_bin(bin: &str, args: &[&str]) -> Result<()> {
    let path = which(bin).with_context(|| format!("missing {bin} on PATH"))?;
    let status = Command::new(path)
        .args(args)
        .stdin(Stdio::null())
        .status()
        .with_context(|| format!("exec {bin}"))?;
    if !status.success() {
        bail!("{bin} exited {status}");
    }
    Ok(())
}

fn run_script_env(script_env: &str, fallback_bin: &str, args: &[&str]) -> Result<()> {
    if let Ok(p) = std::env::var(script_env) {
        let pb = PathBuf::from(&p);
        if pb.is_file() {
            let status = if pb.extension().and_then(|s| s.to_str()) == Some("sh") {
                Command::new("bash").arg(&pb).args(args).status()?
            } else {
                Command::new(&pb).args(args).status()?
            };
            if !status.success() {
                bail!("{} failed: {status}", pb.display());
            }
            return Ok(());
        }
    }
    run_bin(fallback_bin, args)
}

pub fn pass_sync() -> Result<()> {
    run_script_env("DENDRITIC_PASS_STORE_SYNC", "pass-store-sync", &[])
}

pub fn pass_watch() -> Result<()> {
    run_script_env("DENDRITIC_PASS_STORE_WATCH", "pass-store-watch", &[])
}

pub fn pass_notify() -> Result<()> {
    run_script_env(
        "DENDRITIC_PASS_STORE_SYNC_NOTIFY",
        "pass-store-sync-notify",
        &[],
    )
}

pub fn gpg_preset() -> Result<()> {
    run_script_env("DENDRITIC_GPG_PRESET", "gpg-preset-from-sops", &[])
}

pub fn fleet_heartbeat() -> Result<()> {
    run_script_env("DENDRITIC_FLEET_HEARTBEAT", "fleet-heartbeat", &[])
}

pub fn wifi_ensure() -> Result<()> {
    run_bin("dendritic-wifi-ensure", &[])
}

pub fn eduroam_ensure() -> Result<()> {
    run_bin("dendritic-eduroam-ensure", &[])
}

pub fn eduroam_rotate() -> Result<()> {
    run_bin("dendritic-eduroam-rotate", &[])
}

pub fn auth_rotate(auto: bool, yes: bool, extra: &[String]) -> Result<()> {
    let mut args: Vec<&str> = Vec::new();
    if auto {
        args.push("--auto");
    }
    if yes {
        args.push("--yes");
    }
    let owned: Vec<&str> = extra.iter().map(String::as_str).collect();
    args.extend(owned);
    run_bin("pass-rotate-cli-auth", &args)
}

pub fn android_converge() -> Result<()> {
    run_script_env("DENDRITIC_ANDROID_CONVERGE", "android-converge", &[])
}

pub fn tray_collect() -> Result<()> {
    run_script_env("DENDRITIC_TRAY_COLLECT", "dendritic-tray-collect", &[])
}

pub fn tray_sync() -> Result<()> {
    run_script_env("DENDRITIC_TRAY_SYNC", "dendritic-tray-sync", &[])
}

pub fn tray_switch_peer() -> Result<()> {
    run_script_env("DENDRITIC_TRAY_SWITCH_PEER", "dendritic-tray-switch-peer", &[])
}

pub fn tray_connect_device(args: &[String]) -> Result<()> {
    let owned: Vec<&str> = args.iter().map(String::as_str).collect();
    run_script_env(
        "DENDRITIC_TRAY_CONNECT_DEVICE",
        "dendritic-connect-device",
        &owned,
    )
}
