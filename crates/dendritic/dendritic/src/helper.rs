//! Root privileged helper daemon — allowlisted WireGuard ops only.

use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{bail, Context, Result};
use dendritic_ipc::{
    authorize_peer, bind_listener, peer_cred, read_msg, validate_wg_iface, write_msg, Request,
    Response, DEFAULT_SOCK,
};

fn conf_path(iface: &str) -> PathBuf {
    PathBuf::from(format!("/etc/wireguard/{iface}.conf"))
}

fn install_conf(iface: &str, source: &Path) -> Result<()> {
    validate_wg_iface(iface).map_err(|e| anyhow::anyhow!("{e}"))?;
    if !source.is_file() {
        bail!("source conf missing: {}", source.display());
    }
    let dest_dir = Path::new("/etc/wireguard");
    std::fs::create_dir_all(dest_dir)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(dest_dir, std::fs::Permissions::from_mode(0o700));
    }
    let dest = conf_path(iface);
    std::fs::copy(source, &dest).with_context(|| {
        format!(
            "copy {} → {}",
            source.display(),
            dest.display()
        )
    })?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(&dest, std::fs::Permissions::from_mode(0o600))?;
    }
    Ok(())
}

fn find_wg_quick() -> Result<PathBuf> {
    if let Ok(p) = which("wg-quick") {
        return Ok(p);
    }
    for cand in [
        "/run/current-system/sw/bin/wg-quick",
        "/etc/profiles/per-user/8amps/bin/wg-quick",
        "/etc/profiles/per-user/alex/bin/wg-quick",
    ] {
        let p = PathBuf::from(cand);
        if p.is_file() {
            return Ok(p);
        }
    }
    bail!("wg-quick not found on PATH")
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

fn wg_quick(iface: &str, action: &str) -> Result<()> {
    validate_wg_iface(iface).map_err(|e| anyhow::anyhow!("{e}"))?;
    let wq = find_wg_quick()?;
    if action == "up" {
        let _ = Command::new(&wq).args(["down", iface]).status();
    }
    let status = Command::new(&wq)
        .args([action, iface])
        .status()
        .with_context(|| format!("exec {} {action} {iface}", wq.display()))?;
    if !status.success() && action != "down" {
        bail!("wg-quick {action} {iface} failed: {status}");
    }
    Ok(())
}

fn handle(req: Request) -> Response {
    match req {
        Request::Ping { id } => Response::ok(id, serde_json::json!({"pong": true})),
        Request::WgInstallConf { id, iface, source } => match install_conf(&iface, &source) {
            Ok(()) => Response::ok(id, serde_json::json!({"path": conf_path(&iface)})),
            Err(e) => Response::err(id, e.to_string()),
        },
        Request::WgUp { id, iface } => match wg_quick(&iface, "up") {
            Ok(()) => Response::ok(id, serde_json::json!({"iface": iface, "state": "up"})),
            Err(e) => Response::err(id, e.to_string()),
        },
        Request::WgDown { id, iface } => match wg_quick(&iface, "down") {
            Ok(()) => Response::ok(id, serde_json::json!({"iface": iface, "state": "down"})),
            Err(e) => Response::err(id, e.to_string()),
        },
    }
}

pub fn run(sock: Option<PathBuf>) -> Result<()> {
    if unsafe { libc::geteuid() } != 0 {
        bail!("dendritic helper must run as root (launchd daemon / systemd)");
    }
    let path = sock.unwrap_or_else(|| PathBuf::from(DEFAULT_SOCK));
    let listener = bind_listener(&path).with_context(|| format!("bind {}", path.display()))?;
    eprintln!("dendritic-helper: listening on {}", path.display());

    for conn in listener.incoming() {
        let mut stream = match conn {
            Ok(s) => s,
            Err(e) => {
                eprintln!("dendritic-helper: accept: {e}");
                continue;
            }
        };
        let peer = match peer_cred(&stream) {
            Ok(p) => p,
            Err(e) => {
                eprintln!("dendritic-helper: peercred: {e}");
                continue;
            }
        };
        if let Err(e) = authorize_peer(peer) {
            let _ = write_msg(&mut stream, &Response::err(0, e.to_string()));
            continue;
        }
        let req: Request = match read_msg(&mut stream) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("dendritic-helper: read: {e}");
                continue;
            }
        };
        let resp = handle(req);
        if let Err(e) = write_msg(&mut stream, &resp) {
            eprintln!("dendritic-helper: write: {e}");
        }
    }
    Ok(())
}
