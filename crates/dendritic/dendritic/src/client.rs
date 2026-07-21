//! User-space client for the privileged helper.

use std::path::PathBuf;

use anyhow::{bail, Context, Result};
use dendritic_ipc::{connect, read_msg, write_msg, Request, Response, DEFAULT_SOCK};

fn sock_path() -> PathBuf {
    std::env::var_os("DENDRITIC_HELPER_SOCK")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(DEFAULT_SOCK))
}

fn roundtrip(req: Request) -> Result<Response> {
    let path = sock_path();
    let mut stream = connect(&path).with_context(|| {
        format!(
            "connect {}: is com.aspauldingcode.dendritic-helper running?",
            path.display()
        )
    })?;
    write_msg(&mut stream, &req)?;
    let resp: Response = read_msg(&mut stream)?;
    if !resp.ok {
        bail!(resp.error.unwrap_or_else(|| "helper error".into()));
    }
    Ok(resp)
}

pub fn ping() -> Result<()> {
    let resp = roundtrip(Request::Ping { id: 1 })?;
    println!("{}", serde_json::to_string_pretty(&resp)?);
    Ok(())
}

pub fn wg_install_conf(iface: String, source: PathBuf) -> Result<()> {
    let source = source.canonicalize().unwrap_or(source);
    let resp = roundtrip(Request::WgInstallConf {
        id: 2,
        iface,
        source,
    })?;
    println!("{}", serde_json::to_string_pretty(&resp)?);
    Ok(())
}

pub fn wg_up(iface: String) -> Result<()> {
    let resp = roundtrip(Request::WgUp { id: 3, iface })?;
    println!("{}", serde_json::to_string_pretty(&resp)?);
    Ok(())
}

pub fn wg_down(iface: String) -> Result<()> {
    let resp = roundtrip(Request::WgDown { id: 4, iface })?;
    println!("{}", serde_json::to_string_pretty(&resp)?);
    Ok(())
}
