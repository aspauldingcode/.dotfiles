use serde::Serialize;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
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

#[derive(Serialize)]
pub struct WaybarStatus {
    pub text: String,
    pub tooltip: String,
    pub class: String,
}

pub fn appearance_variant_path() -> std::path::PathBuf {
    // Prefer system path (written by launchd/root sync); fall back to user state.
    let sys = std::path::PathBuf::from("/var/lib/dendritic/appearance-variant");
    if sys.parent().is_some_and(|p| p.is_dir()) {
        return sys;
    }
    user_state_dir().join("appearance-variant")
}

pub fn applied_variant_path() -> std::path::PathBuf {
    user_state_dir().join("appearance-applied")
}

pub fn wallpaper_state_path() -> std::path::PathBuf {
    user_state_dir().join("wallpaper.json")
}

fn user_state_dir() -> std::path::PathBuf {
    if let Some(xdg) = std::env::var_os("XDG_STATE_HOME") {
        return std::path::PathBuf::from(xdg).join("dendritic");
    }
    std::env::var_os("HOME")
        .map(|h| std::path::PathBuf::from(h).join(".local/state/dendritic"))
        .unwrap_or_else(|| std::path::PathBuf::from("/tmp/dendritic"))
}

pub fn write_appearance_variant(v: Variant) -> Result<(), i32> {
    let path = appearance_variant_path();
    if let Some(parent) = path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    // /var/lib may need root; if write fails, write user mirror too.
    match std::fs::write(&path, format!("{}\n", v.as_str())) {
        Ok(()) => Ok(()),
        Err(e) => {
            let user = user_state_dir().join("appearance-variant");
            let _ = std::fs::create_dir_all(user_state_dir());
            std::fs::write(&user, format!("{}\n", v.as_str())).map_err(|e2| {
                eprintln!("dendritic-appearance: write variant failed: {e} / {e2}");
                1
            })?;
            // Also export for child processes in this session.
            std::env::set_var("DENDRITIC_THEME_VARIANT", v.as_str());
            Ok(())
        }
    }
}

pub fn write_applied_variant(v: Variant) -> Result<(), i32> {
    let _ = std::fs::create_dir_all(user_state_dir());
    std::fs::write(applied_variant_path(), format!("{}\n", v.as_str())).map_err(|e| {
        eprintln!("dendritic-appearance: write applied failed: {e}");
        1
    })
}

pub fn read_applied_variant() -> Option<Variant> {
    for path in [
        appearance_variant_path(),
        applied_variant_path(),
        user_state_dir().join("appearance-variant"),
    ] {
        if let Ok(s) = std::fs::read_to_string(path) {
            if let Some(v) = Variant::parse(s.trim()) {
                return Some(v);
            }
        }
    }
    None
}

pub fn read_wallpaper_name() -> Option<String> {
    let path = wallpaper_state_path();
    let raw = std::fs::read_to_string(path).ok()?;
    let v: serde_json::Value = serde_json::from_str(&raw).ok()?;
    v.get("name")?.as_str().map(|s| s.to_string())
}
