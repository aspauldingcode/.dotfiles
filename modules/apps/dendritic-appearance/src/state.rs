use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Variant {
    Light,
    Dark,
}

impl Variant {
    pub fn parse(s: &str) -> Option<Self> {
        match s.trim().to_ascii_lowercase().as_str() {
            "light" => Some(Self::Light),
            "dark" => Some(Self::Dark),
            _ => None,
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::Light => "light",
            Self::Dark => "dark",
        }
    }

    pub fn opposite(self) -> Self {
        match self {
            Self::Light => Self::Dark,
            Self::Dark => Self::Light,
        }
    }
}

impl std::fmt::Display for Variant {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

#[derive(Serialize)]
pub struct WaybarStatus {
    pub text: String,
    pub tooltip: String,
    pub class: String,
}

pub fn home_dir() -> Option<PathBuf> {
    if let Ok(h) = std::env::var("DENDRITIC_HOME") {
        return Some(PathBuf::from(h));
    }
    if let Ok(h) = std::env::var("HOME") {
        return Some(PathBuf::from(h));
    }
    // launchd daemon as root: resolve target user home
    if let Ok(user) = std::env::var("DENDRITIC_USER") {
        #[cfg(target_os = "macos")]
        {
            return Some(PathBuf::from(format!("/Users/{user}")));
        }
        #[cfg(target_os = "linux")]
        {
            return Some(PathBuf::from(format!("/home/{user}")));
        }
    }
    None
}

pub fn system_state_dir() -> PathBuf {
    PathBuf::from("/var/lib/dendritic")
}

pub fn user_state_dir() -> PathBuf {
    if let Some(xdg) = std::env::var_os("XDG_STATE_HOME") {
        return PathBuf::from(xdg).join("dendritic");
    }
    home_dir()
        .map(|h| h.join(".local/state/dendritic"))
        .unwrap_or_else(|| PathBuf::from("/tmp/dendritic"))
}

pub fn appearance_variant_path() -> PathBuf {
    // User path is authoritative for the HM supervise agent.
    // `/var/lib/dendritic` is only a root-writable mirror (system watch / activate).
    user_state_dir().join("appearance-variant")
}

pub fn applied_variant_path() -> PathBuf {
    user_state_dir().join("appearance-applied")
}

pub fn machine_phase_path() -> PathBuf {
    user_state_dir().join("appearance-phase.json")
}

pub fn wallpaper_state_path() -> PathBuf {
    user_state_dir().join("wallpaper.json")
}

pub fn write_appearance_variant(v: Variant) -> Result<(), String> {
    let _ = std::fs::create_dir_all(user_state_dir());
    let user_path = appearance_variant_path();
    std::fs::write(&user_path, format!("{}\n", v.as_str())).map_err(|e| e.to_string())?;

    // Best-effort system mirror (root-only). Never treat failure as fatal —
    // reads prefer the user path so a stale system file cannot desync us.
    let sys = system_state_dir().join("appearance-variant");
    if system_state_dir().is_dir() {
        let _ = std::fs::write(&sys, format!("{}\n", v.as_str()));
    }
    std::env::set_var("DENDRITIC_THEME_VARIANT", v.as_str());
    Ok(())
}

pub fn write_applied_variant(v: Variant) -> Result<(), String> {
    let _ = std::fs::create_dir_all(user_state_dir());
    std::fs::write(applied_variant_path(), format!("{}\n", v.as_str())).map_err(|e| e.to_string())
}

pub fn read_recorded_variant() -> Option<Variant> {
    for path in [
        appearance_variant_path(),
        applied_variant_path(),
        // Legacy / root mirror — only if user paths are missing.
        system_state_dir().join("appearance-variant"),
    ] {
        if let Ok(s) = std::fs::read_to_string(&path) {
            if let Some(v) = Variant::parse(s.trim()) {
                return Some(v);
            }
        }
    }
    None
}

pub fn read_wallpaper_name() -> Option<String> {
    let raw = std::fs::read_to_string(wallpaper_state_path()).ok()?;
    let v: serde_json::Value = serde_json::from_str(&raw).ok()?;
    v.get("name")?.as_str().map(|s| s.to_string())
}

pub fn read_wallpaper_variant() -> Option<Variant> {
    let raw = std::fs::read_to_string(wallpaper_state_path()).ok()?;
    let v: serde_json::Value = serde_json::from_str(&raw).ok()?;
    Variant::parse(v.get("variant")?.as_str()?)
}

pub fn write_wallpaper_state(
    name: &str,
    image: &str,
    variant: Variant,
    mode: &str,
    index: usize,
    lock_name: Option<&str>,
    lock_image: Option<&str>,
) {
    let _ = std::fs::create_dir_all(user_state_dir());
    let mut obj = serde_json::json!({
        "name": name,
        "image": image,
        "variant": variant.as_str(),
        "mode": mode,
        "index": index,
        "applied": now_secs(),
    });
    if let Some(n) = lock_name {
        obj["lock_name"] = serde_json::json!(n);
    }
    if let Some(i) = lock_image {
        obj["lock_image"] = serde_json::json!(i);
    }
    let _ = std::fs::write(
        wallpaper_state_path(),
        serde_json::to_string_pretty(&obj).unwrap_or_default(),
    );
}

pub fn write_phase_snapshot(status: &impl Serialize) {
    let _ = std::fs::create_dir_all(user_state_dir());
    if let Ok(s) = serde_json::to_string_pretty(status) {
        let _ = std::fs::write(machine_phase_path(), s);
    }
}

fn now_secs() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    format!("{secs}")
}
