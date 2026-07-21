//! Length-prefixed JSON IPC over a Unix domain socket + peer credential auth.

use std::io::{Read, Write};
use std::os::unix::io::AsRawFd;
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use thiserror::Error;

pub const DEFAULT_SOCK: &str = "/var/run/dendritic/helper.sock";
pub const ALLOWED_WG_IFACE: &str = "dendritic";

#[derive(Debug, Error)]
pub enum IpcError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("json: {0}")]
    Json(#[from] serde_json::Error),
    #[error("peer rejected: {0}")]
    PeerRejected(String),
    #[error("protocol: {0}")]
    Protocol(String),
    #[error("{0}")]
    Other(String),
}

pub type Result<T> = std::result::Result<T, IpcError>;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "method", rename_all = "snake_case")]
pub enum Request {
    Ping { id: u64 },
    WgInstallConf { id: u64, iface: String, source: PathBuf },
    WgUp { id: u64, iface: String },
    WgDown { id: u64, iface: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Response {
    pub id: u64,
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<serde_json::Value>,
}

impl Response {
    pub fn ok(id: u64, result: impl Serialize) -> Self {
        Self {
            id,
            ok: true,
            error: None,
            result: Some(serde_json::to_value(result).unwrap_or(serde_json::Value::Null)),
        }
    }

    pub fn err(id: u64, msg: impl Into<String>) -> Self {
        Self {
            id,
            ok: false,
            error: Some(msg.into()),
            result: None,
        }
    }
}

pub fn write_msg(stream: &mut UnixStream, value: &impl Serialize) -> Result<()> {
    let bytes = serde_json::to_vec(value)?;
    if bytes.len() > 1 << 20 {
        return Err(IpcError::Protocol("message too large".into()));
    }
    let len = (bytes.len() as u32).to_be_bytes();
    stream.write_all(&len)?;
    stream.write_all(&bytes)?;
    stream.flush()?;
    Ok(())
}

pub fn read_msg<T: for<'de> Deserialize<'de>>(stream: &mut UnixStream) -> Result<T> {
    let mut len_buf = [0u8; 4];
    stream.read_exact(&mut len_buf)?;
    let len = u32::from_be_bytes(len_buf) as usize;
    if len == 0 || len > 1 << 20 {
        return Err(IpcError::Protocol(format!("bad length {len}")));
    }
    let mut buf = vec![0u8; len];
    stream.read_exact(&mut buf)?;
    Ok(serde_json::from_slice(&buf)?)
}

#[derive(Debug, Clone, Copy)]
pub struct PeerCred {
    pub uid: u32,
    pub gid: u32,
    pub pid: u32,
}

pub fn peer_cred(stream: &UnixStream) -> Result<PeerCred> {
    let fd = stream.as_raw_fd();
    unsafe { peer_cred_fd(fd) }
}

#[cfg(target_os = "macos")]
unsafe fn peer_cred_fd(fd: libc::c_int) -> Result<PeerCred> {
    // LOCAL_PEERCRED / xucred
    const LOCAL_PEERCRED: libc::c_int = 0x001;
    // xucred layout (sys/ucred.h)
    #[repr(C)]
    struct Xucred {
        cr_version: u32,
        cr_uid: u32,
        cr_ngroups: i16,
        cr_groups: [u32; 16],
    }
    let mut cred = Xucred {
        cr_version: 0,
        cr_uid: 0,
        cr_ngroups: 0,
        cr_groups: [0; 16],
    };
    let mut len = std::mem::size_of::<Xucred>() as libc::socklen_t;
    let rc = libc::getsockopt(
        fd,
        libc::SOL_LOCAL,
        LOCAL_PEERCRED,
        &mut cred as *mut _ as *mut libc::c_void,
        &mut len,
    );
    if rc != 0 {
        return Err(IpcError::Io(std::io::Error::last_os_error()));
    }
    Ok(PeerCred {
        uid: cred.cr_uid,
        gid: cred.cr_groups[0],
        pid: 0,
    })
}

#[cfg(target_os = "linux")]
unsafe fn peer_cred_fd(fd: libc::c_int) -> Result<PeerCred> {
    let mut cred = libc::ucred {
        pid: 0,
        uid: 0,
        gid: 0,
    };
    let mut len = std::mem::size_of::<libc::ucred>() as libc::socklen_t;
    let rc = libc::getsockopt(
        fd,
        libc::SOL_SOCKET,
        libc::SO_PEERCRED,
        &mut cred as *mut _ as *mut libc::c_void,
        &mut len,
    );
    if rc != 0 {
        return Err(IpcError::Io(std::io::Error::last_os_error()));
    }
    Ok(PeerCred {
        uid: cred.uid,
        gid: cred.gid,
        pid: cred.pid as u32,
    })
}

#[cfg(not(any(target_os = "macos", target_os = "linux")))]
unsafe fn peer_cred_fd(_fd: libc::c_int) -> Result<PeerCred> {
    Err(IpcError::Other("peer credentials unsupported".into()))
}

/// Accept connections from console users (non-root) or root itself.
pub fn authorize_peer(peer: PeerCred) -> Result<()> {
    if peer.uid == 0 {
        return Ok(());
    }
    // Reject nobody / invalid.
    if peer.uid == u32::MAX {
        return Err(IpcError::PeerRejected("invalid uid".into()));
    }
    Ok(())
}

pub fn bind_listener(path: &Path) -> Result<UnixListener> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let _ = std::fs::set_permissions(parent, std::fs::Permissions::from_mode(0o755));
        }
    }
    let _ = std::fs::remove_file(path);
    let listener = UnixListener::bind(path)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o660));
    }
    Ok(listener)
}

pub fn connect(path: &Path) -> Result<UnixStream> {
    Ok(UnixStream::connect(path)?)
}

pub fn validate_wg_iface(iface: &str) -> Result<()> {
    if iface != ALLOWED_WG_IFACE {
        return Err(IpcError::Other(format!(
            "iface '{iface}' not allowlisted (only '{ALLOWED_WG_IFACE}')"
        )));
    }
    Ok(())
}
