//! Wallpaper pack apply in pure Rust (no bash/python/jq).
//!
//! Daily: one theme family + one scenic pair (day-of-year).
//! Appearance (light/dark) selects the pole of both, then lutgen-rs recolors
//! the photo to that palette (Gaussian Hald CLUT; no nearest-neighbor).

use std::path::{Path, PathBuf};
use std::process::Command;

use serde::Deserialize;

use crate::ide;
use crate::observe::colors_toml_path;
use crate::state::{self, Variant};

#[derive(Debug, Deserialize)]
struct Manifest {
    #[serde(default)]
    themes: Vec<Theme>,
    #[serde(default)]
    pairs: Vec<Pair>,
    wallpapers: Vec<Entry>,
}

#[derive(Debug, Clone, Deserialize)]
struct Theme {
    name: String,
    colors: VariantPaths,
    #[serde(default)]
    gowall: VariantPaths,
    #[serde(default)]
    lutgen: VariantPaths,
}

#[derive(Debug, Clone, Deserialize, Default)]
struct VariantPaths {
    #[serde(default)]
    dark: String,
    #[serde(default)]
    light: String,
}

#[derive(Debug, Clone, Deserialize)]
struct Pair {
    id: String,
    light: String,
    dark: String,
}

#[derive(Debug, Clone, Deserialize)]
struct Entry {
    name: String,
    image: String,
    #[serde(default)]
    blur: Option<String>,
    #[serde(default)]
    pair: Option<String>,
}

impl Theme {
    fn colors(&self, variant: Variant) -> &str {
        match variant {
            Variant::Dark => &self.colors.dark,
            Variant::Light => &self.colors.light,
        }
    }

    fn gowall(&self, variant: Variant) -> &str {
        match variant {
            Variant::Dark => &self.gowall.dark,
            Variant::Light => &self.gowall.light,
        }
    }

    fn lutgen_palette(&self, variant: Variant) -> Option<&str> {
        let name = match variant {
            Variant::Dark => self.lutgen.dark.as_str(),
            Variant::Light => self.lutgen.light.as_str(),
        };
        if name.is_empty() {
            None
        } else {
            Some(name)
        }
    }
}

impl Pair {
    fn name_for(&self, variant: Variant) -> &str {
        match variant {
            Variant::Dark => &self.dark,
            Variant::Light => &self.light,
        }
    }
}

fn pack_dir() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_WALLPAPER_PACK") {
        return PathBuf::from(p);
    }
    if let Some(home) = state::home_dir() {
        let p = home.join(".config/dendritic/wallpaper-pack");
        if p.is_dir() || p.is_symlink() {
            return p;
        }
    }
    PathBuf::from("/etc/dendritic/wallpaper-pack")
}

fn load_manifest() -> Result<Manifest, String> {
    let path = pack_dir().join("manifest.json");
    let raw =
        std::fs::read_to_string(&path).map_err(|e| format!("read {}: {e}", path.display()))?;
    serde_json::from_str(&raw).map_err(|e| format!("parse manifest: {e}"))
}

/// Civil (y, m, d) from days since Unix epoch (Howard Hinnant).
fn civil_from_days(z: i64) -> (i64, u32, u32) {
    let z = z + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 }.div_euclid(146_097);
    let doe = (z - era * 146_097) as u64;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    (y, m as u32, d as u32)
}

/// Day-of-year 1..=366 (UTC; matches prior `date +%j` for same calendar day in UTC).
fn day_of_year() -> usize {
    use std::time::{SystemTime, UNIX_EPOCH};
    let days = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64 / 86_400)
        .unwrap_or(0);
    let (y, m, d) = civil_from_days(days);
    let leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
    let cumul = [0u32, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let mut doy = cumul[(m as usize) - 1] + d;
    if leap && m > 2 {
        doy += 1;
    }
    doy as usize
}

fn day_index(count: usize) -> usize {
    if count == 0 {
        return 0;
    }
    (day_of_year().saturating_sub(1)) % count
}

fn wallpaper_scale() -> String {
    std::env::var("DENDRITIC_WALLPAPER_SCALE").unwrap_or_else(|_| "fill".into())
}

fn lutgen_cache_root() -> PathBuf {
    if let Ok(p) = std::env::var("DENDRITIC_LUTGEN_CACHE") {
        return PathBuf::from(p);
    }
    if let Ok(p) = std::env::var("DENDRITIC_GOWALL_CACHE") {
        return PathBuf::from(p);
    }
    if let Some(xdg) = std::env::var_os("XDG_CACHE_HOME") {
        return PathBuf::from(xdg).join("dendritic/lutgen");
    }
    state::home_dir()
        .map(|h| h.join(".cache/dendritic/lutgen"))
        .unwrap_or_else(|| PathBuf::from("/tmp/dendritic-lutgen"))
}

fn cached_png(pair: &str, theme: &str, variant: Variant) -> PathBuf {
    lutgen_cache_root()
        .join(pair)
        .join(theme)
        .join(format!("{}.png", variant.as_str()))
}

fn cached_blur(pair: &str, theme: &str, variant: Variant) -> PathBuf {
    lutgen_cache_root()
        .join(pair)
        .join(theme)
        .join(format!("{}-blur.png", variant.as_str()))
}

fn find_theme<'a>(manifest: &'a Manifest, name: &str) -> Result<&'a Theme, String> {
    manifest
        .themes
        .iter()
        .find(|t| t.name == name)
        .ok_or_else(|| format!("unknown theme '{name}'"))
}

fn find_pair<'a>(manifest: &'a Manifest, id: &str) -> Result<&'a Pair, String> {
    manifest
        .pairs
        .iter()
        .find(|p| p.id == id)
        .ok_or_else(|| format!("unknown wallpaper pair '{id}'"))
}

fn find_entry<'a>(manifest: &'a Manifest, name: &str) -> Result<&'a Entry, String> {
    manifest
        .wallpapers
        .iter()
        .find(|e| e.name == name)
        .ok_or_else(|| format!("unknown wallpaper '{name}'"))
}

fn daily_theme<'a>(manifest: &'a Manifest) -> Result<&'a Theme, String> {
    if manifest.themes.is_empty() {
        return Err("wallpaper pack has no theme families".into());
    }
    Ok(&manifest.themes[day_index(manifest.themes.len())])
}

fn daily_pair<'a>(manifest: &'a Manifest) -> Result<&'a Pair, String> {
    if manifest.pairs.is_empty() {
        return Err("wallpaper pack has no pairs".into());
    }
    Ok(&manifest.pairs[day_index(manifest.pairs.len())])
}

fn pair_index(manifest: &Manifest, pair: &Pair) -> usize {
    manifest
        .pairs
        .iter()
        .position(|p| p.id == pair.id)
        .unwrap_or(0)
}

fn current_or_daily_theme<'a>(manifest: &'a Manifest) -> Result<&'a Theme, String> {
    if let Some(name) = state::read_theme_name() {
        if let Ok(t) = find_theme(manifest, &name) {
            return Ok(t);
        }
    }
    daily_theme(manifest)
}

fn current_or_daily_pair<'a>(manifest: &'a Manifest) -> Result<&'a Pair, String> {
    if let Some(id) = state::read_pair_id() {
        if let Ok(p) = find_pair(manifest, &id) {
            return Ok(p);
        }
    }
    daily_pair(manifest)
}

fn next_pair<'a>(manifest: &'a Manifest, current: &Pair) -> Result<&'a Pair, String> {
    let n = manifest.pairs.len();
    if n == 0 {
        return Err("wallpaper pack has no pairs".into());
    }
    let idx = pair_index(manifest, current);
    Ok(&manifest.pairs[(idx + 1) % n])
}

struct Choice<'a> {
    theme: &'a Theme,
    pair: &'a Pair,
    mode: &'static str,
}

fn resolve_choice<'a>(manifest: &'a Manifest, target: &str) -> Result<Choice<'a>, String> {
    match target {
        "daily" | "" => Ok(Choice {
            theme: daily_theme(manifest)?,
            pair: daily_pair(manifest)?,
            mode: "daily",
        }),
        "current" => Ok(Choice {
            theme: current_or_daily_theme(manifest)?,
            pair: current_or_daily_pair(manifest)?,
            mode: "current",
        }),
        "next" => {
            let theme = current_or_daily_theme(manifest)?;
            let cur = current_or_daily_pair(manifest)?;
            Ok(Choice {
                theme,
                pair: next_pair(manifest, cur)?,
                mode: "next",
            })
        }
        name => {
            if let Ok(theme) = find_theme(manifest, name) {
                return Ok(Choice {
                    theme,
                    pair: current_or_daily_pair(manifest)?,
                    mode: "named-theme",
                });
            }
            if let Ok(pair) = find_pair(manifest, name) {
                return Ok(Choice {
                    theme: current_or_daily_theme(manifest)?,
                    pair,
                    mode: "named-pair",
                });
            }
            if let Ok(entry) = find_entry(manifest, name) {
                let pair = entry
                    .pair
                    .as_deref()
                    .and_then(|id| find_pair(manifest, id).ok())
                    .ok_or_else(|| format!("wallpaper '{name}' has no pair"))?;
                return Ok(Choice {
                    theme: current_or_daily_theme(manifest)?,
                    pair,
                    mode: "named",
                });
            }
            Err(format!(
                "unknown wallpaper/theme '{name}' (try list-wallpapers / list-themes)"
            ))
        }
    }
}

fn lutgen_bin() -> String {
    std::env::var("DENDRITIC_LUTGEN_BIN").unwrap_or_else(|_| "lutgen".into())
}

#[derive(Debug, Deserialize)]
struct GowallThemeJson {
    #[serde(default)]
    colors: Vec<String>,
}

fn load_hex_colors(theme_json: &str) -> Result<Vec<String>, String> {
    let raw = std::fs::read_to_string(theme_json).map_err(|e| format!("read {theme_json}: {e}"))?;
    let parsed: GowallThemeJson =
        serde_json::from_str(&raw).map_err(|e| format!("parse {theme_json}: {e}"))?;
    if parsed.colors.is_empty() {
        return Err(format!("{theme_json}: no colors"));
    }
    Ok(parsed.colors)
}

fn lutgen_apply(
    src: &str,
    dest: &Path,
    palette: Option<&str>,
    hexes: &[String],
) -> Result<(), String> {
    if dest.is_file() {
        return Ok(());
    }
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir {}: {e}", parent.display()))?;
    }
    let tmp = dest.with_file_name(format!(
        ".{}.converting.png",
        dest.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("lutgen")
    ));
    let _ = std::fs::remove_file(&tmp);
    let tmp_str = tmp.to_str().ok_or("lutgen dest not utf-8")?;
    let bin = lutgen_bin();
    let mut cmd = Command::new(&bin);
    // Default algorithm = Gaussian-blurred Hald CLUT (level 10). Do not pass
    // `-N` (nearest-neighbor): that posterizes. `-c` caches the generated LUT.
    cmd.args(["apply", "-c", "-o", tmp_str]);
    if let Some(name) = palette {
        cmd.args(["-p", name]);
    }
    cmd.arg(src);
    if palette.is_none() {
        if hexes.is_empty() {
            return Err("lutgen needs a palette name or hex colors".into());
        }
        cmd.arg("--");
        cmd.args(hexes);
    }
    let st = cmd.status().map_err(|e| format!("{bin}: {e}"))?;
    if !st.success() {
        let _ = std::fs::remove_file(&tmp);
        return Err(format!("{bin} apply failed"));
    }
    if tmp.is_file() {
        std::fs::rename(&tmp, dest).map_err(|e| format!("rename lutgen out: {e}"))?;
        return Ok(());
    }
    Err(format!("lutgen produced no image at {}", dest.display()))
}

fn recolor(src: &str, theme: &Theme, variant: Variant, dest: &Path) -> Result<(), String> {
    let palette = theme.lutgen_palette(variant);
    let hexes = if palette.is_none() {
        load_hex_colors(theme.gowall(variant))?
    } else {
        Vec::new()
    };
    lutgen_apply(src, dest, palette, &hexes)
}

fn magick_blur(src: &Path, dest: &Path) -> Result<(), String> {
    if dest.is_file() {
        return Ok(());
    }
    if let Some(parent) = dest.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    let st = Command::new("magick")
        .args([
            src.to_str().ok_or("blur src not utf-8")?,
            "-auto-orient",
            "-resize",
            "1920x1080^",
            "-gravity",
            "center",
            "-extent",
            "1920x1080",
            "-scale",
            "5%",
            "-gaussian-blur",
            "0x1.4",
            "-resize",
            "1920x1080!",
            "-quality",
            "92",
            dest.to_str().ok_or("blur dest not utf-8")?,
        ])
        .status()
        .map_err(|e| format!("magick: {e}"))?;
    if !st.success() {
        return Err("magick blur failed".into());
    }
    Ok(())
}

struct Prepared {
    name: String,
    image: String,
    blur: String,
}

fn prepare(
    manifest: &Manifest,
    pair: &Pair,
    theme: &Theme,
    variant: Variant,
) -> Result<Prepared, String> {
    let entry = find_entry(manifest, pair.name_for(variant))?;
    if !Path::new(&entry.image).is_file() {
        return Err(format!("missing image {}", entry.image));
    }
    let dest = cached_png(&pair.id, &theme.name, variant);
    match recolor(&entry.image, theme, variant, &dest) {
        Ok(()) => {}
        Err(e) => {
            eprintln!("dendritic-appearance: lutgen warn: {e}; using original");
            let blur = entry_blur(entry).to_string();
            return Ok(Prepared {
                name: entry.name.clone(),
                image: entry.image.clone(),
                blur,
            });
        }
    }
    let blur_dest = cached_blur(&pair.id, &theme.name, variant);
    let blur = match magick_blur(&dest, &blur_dest) {
        Ok(()) => blur_dest.to_string_lossy().into_owned(),
        Err(_) => entry_blur(entry).to_string(),
    };
    Ok(Prepared {
        name: entry.name.clone(),
        image: dest.to_string_lossy().into_owned(),
        blur,
    })
}

fn install_colors(theme: &Theme, variant: Variant) -> Result<(), String> {
    let colors_src = theme.colors(variant);
    if !Path::new(colors_src).is_file() {
        return Err(format!("missing colors file {colors_src}"));
    }
    let colors_dst = colors_toml_path();
    let _ = std::fs::remove_file(&colors_dst);
    std::fs::copy(colors_src, &colors_dst).map_err(|e| format!("copy colors: {e}"))?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&colors_dst, std::fs::Permissions::from_mode(0o644));
    }
    Ok(())
}

pub fn apply(variant: Variant, target: &str) -> Result<(), String> {
    let manifest = load_manifest()?;
    if manifest.wallpapers.is_empty() {
        return Err("empty wallpaper pack".into());
    }

    let choice = resolve_choice(&manifest, target)?;
    if target == "daily" || target.is_empty() {
        for v in [Variant::Light, Variant::Dark] {
            if let Err(e) = prepare(&manifest, choice.pair, choice.theme, v) {
                eprintln!("dendritic-appearance: preconvert {v}: {e}");
            }
        }
    }

    let colors_dst = colors_toml_path();
    let prev_palette = crate::palette::load_palette(&colors_dst).ok();
    install_colors(choice.theme, variant)?;

    let prepared = prepare(&manifest, choice.pair, choice.theme, variant)?;
    set_os_wallpaper(&prepared.image)?;
    publish_auth_paths(&prepared.image, &prepared.blur)?;

    let (lock_name, lock_image) = {
        #[cfg(target_os = "macos")]
        {
            let lock_pair = next_pair(&manifest, choice.pair)?;
            let lock = prepare(&manifest, lock_pair, choice.theme, variant)?;
            apply_lock_image(&lock.image)?;
            (lock.name, lock.image)
        }
        #[cfg(not(target_os = "macos"))]
        {
            (prepared.name.clone(), prepared.image.clone())
        }
    };

    let _ = ide::patch_from_colors_remap(&colors_dst, prev_palette.as_ref());
    let _ = crate::ghostty::apply_from_colors(&colors_dst);
    let _ = crate::qt::apply_from_colors(&colors_dst);
    let _ = crate::vesktop::apply_from_colors(&colors_dst);
    let _ = crate::spotify::apply_from_colors(&colors_dst);
    state::write_wallpaper_state(
        &prepared.name,
        &prepared.image,
        variant,
        choice.mode,
        pair_index(&manifest, choice.pair),
        Some(&lock_name),
        Some(&lock_image),
        Some(&choice.theme.name),
        Some(&choice.pair.id),
    );

    eprintln!(
        "dendritic-appearance: wallpaper {} + {} ({variant}, {}); auth={}",
        choice.pair.id, choice.theme.name, choice.mode, prepared.name
    );
    Ok(())
}

fn entry_blur(entry: &Entry) -> &str {
    entry
        .blur
        .as_deref()
        .filter(|p| Path::new(p).is_file())
        .unwrap_or(entry.image.as_str())
}

fn publish_auth_paths(image: &str, blur: &str) -> Result<(), String> {
    let dir = PathBuf::from("/var/lib/dendritic/auth");
    if dir.is_dir() {
        let tsv = format!("{image}\t{blur}\n");
        let path = dir.join("current.tsv");
        if let Err(e) = std::fs::write(&path, &tsv) {
            eprintln!("dendritic-appearance: warn: write {}: {e}", path.display());
        } else {
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let _ = std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o644));
            }
        }
    }
    if let Some(home) = state::home_dir() {
        let udir = home.join(".local/state/dendritic/auth");
        let _ = std::fs::create_dir_all(&udir);
        let _ = std::fs::write(udir.join("current.tsv"), format!("{image}\t{blur}\n"));
    }
    Ok(())
}

fn set_os_wallpaper(image: &str) -> Result<(), String> {
    let scale = wallpaper_scale();
    #[cfg(target_os = "macos")]
    {
        match crate::wallpaperkit::apply_all_spaces(image, &scale, false) {
            Ok(()) => return Ok(()),
            Err(e) => {
                eprintln!(
                    "dendritic-appearance: WallpaperKit: {e}; falling back to macos-wallpaperd"
                );
            }
        }
        let wallpaperd = std::env::var("DENDRITIC_MACOS_WALLPAPERD_BIN")
            .unwrap_or_else(|_| "macos-wallpaperd".into());
        let st = Command::new(&wallpaperd)
            .args(["import", image, "--scale", &scale])
            .status()
            .map_err(|e| format!("{wallpaperd}: {e}"))?;
        if !st.success() {
            return Err(format!("{wallpaperd} import failed"));
        }
        return Ok(());
    }
    #[cfg(target_os = "linux")]
    {
        let _ = Command::new("pkill").args(["-x", "swaybg"]).status();
        let _ = Command::new("pkill").args(["swaybg"]).status();
        std::thread::sleep(std::time::Duration::from_millis(250));
        let child = Command::new("swaybg")
            .args(["-i", image, "-m", &scale])
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn()
            .map_err(|e| format!("swaybg: {e}"))?;
        std::mem::forget(child);
        return Ok(());
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        let _ = image;
        Ok(())
    }
}

fn apply_lock_image(image: &str) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    {
        std::thread::sleep(std::time::Duration::from_millis(400));
        set_macos_lock_wallpaper(image)?;
        return Ok(());
    }
    #[cfg(not(target_os = "macos"))]
    {
        let _ = image;
        Ok(())
    }
}

/// macOS Sonoma+: set Idle (lock / screen-saver still) image in Wallpaper Index.plist.
#[cfg(target_os = "macos")]
fn set_macos_lock_wallpaper(image: &str) -> Result<(), String> {
    use plist::{Dictionary, Value};
    use std::time::SystemTime;

    let home = state::home_dir().ok_or_else(|| "no home directory".to_string())?;
    let index_path = home.join("Library/Application Support/com.apple.wallpaper/Store/Index.plist");
    if !index_path.is_file() {
        return Err(format!(
            "missing {} (open System Settings → Wallpaper once)",
            index_path.display()
        ));
    }

    let mut root = Value::from_file(&index_path).map_err(|e| format!("read Index.plist: {e}"))?;

    let file_url = path_as_file_url(image)?;
    let mut cfg = Dictionary::new();
    cfg.insert("type".into(), Value::String("imageFile".into()));
    let mut url = Dictionary::new();
    url.insert("relative".into(), Value::String(file_url));
    cfg.insert("url".into(), Value::Dictionary(url));

    let mut cfg_buf = Vec::new();
    Value::Dictionary(cfg)
        .to_writer_binary(&mut cfg_buf)
        .map_err(|e| format!("encode Idle Configuration: {e}"))?;
    let cfg_data = Value::Data(cfg_buf);

    let sample_eov = find_desktop_eov(&root);
    let now = Value::Date(SystemTime::now().into());
    let patched = patch_idle_nodes(&mut root, &cfg_data, sample_eov.as_ref(), &now);
    if patched == 0 {
        return Err("no Idle nodes found in Index.plist".into());
    }

    let tmp = index_path.with_extension("plist.tmp");
    root.to_file_binary(&tmp)
        .map_err(|e| format!("write {}: {e}", tmp.display()))?;
    let _ = Value::from_file(&tmp).map_err(|e| format!("validate tmp Index.plist: {e}"))?;
    std::fs::rename(&tmp, &index_path).map_err(|e| format!("replace Index.plist: {e}"))?;

    let _ = Command::new("killall").arg("WallpaperAgent").status();
    eprintln!("dendritic-appearance: macOS lock wallpaper ({patched} Idle nodes)");
    Ok(())
}

#[cfg(target_os = "macos")]
fn path_as_file_url(path: &str) -> Result<String, String> {
    let p = Path::new(path)
        .canonicalize()
        .map_err(|e| format!("canonicalize {path}: {e}"))?;
    let mut url = String::from("file://");
    for comp in p.components() {
        use std::path::Component;
        match comp {
            Component::RootDir => {}
            Component::Normal(s) => {
                url.push('/');
                url.push_str(&urlencoding_path_component(&s.to_string_lossy()));
            }
            _ => {}
        }
    }
    if !url.starts_with("file:///") {
        url = format!("file://{}", p.display());
    }
    Ok(url)
}

#[cfg(target_os = "macos")]
fn urlencoding_path_component(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

#[cfg(target_os = "macos")]
fn find_desktop_eov(value: &plist::Value) -> Option<plist::Value> {
    match value {
        plist::Value::Dictionary(dict) => {
            if let Some(desktop) = dict.get("Desktop") {
                if let Some(plist::Value::Dictionary(content)) =
                    desktop.as_dictionary().and_then(|d| d.get("Content"))
                {
                    if let Some(eov) = content.get("EncodedOptionValues") {
                        return Some(eov.clone());
                    }
                }
            }
            for v in dict.values() {
                if let Some(found) = find_desktop_eov(v) {
                    return Some(found);
                }
            }
            None
        }
        plist::Value::Array(arr) => {
            for v in arr {
                if let Some(found) = find_desktop_eov(v) {
                    return Some(found);
                }
            }
            None
        }
        _ => None,
    }
}

#[cfg(target_os = "macos")]
fn patch_idle_nodes(
    value: &mut plist::Value,
    cfg_data: &plist::Value,
    sample_eov: Option<&plist::Value>,
    now: &plist::Value,
) -> usize {
    let mut count = 0;
    match value {
        plist::Value::Dictionary(dict) => {
            if let Some(idle) = dict.get_mut("Idle") {
                if let Some(idle_dict) = idle.as_dictionary_mut() {
                    if let Some(content) = idle_dict.get_mut("Content") {
                        if let Some(content_dict) = content.as_dictionary_mut() {
                            if let Some(choices) = content_dict.get_mut("Choices") {
                                if let Some(arr) = choices.as_array_mut() {
                                    if let Some(choice) = arr.get_mut(0) {
                                        if let Some(choice_dict) = choice.as_dictionary_mut() {
                                            choice_dict.insert(
                                                "Provider".into(),
                                                plist::Value::String(
                                                    "com.apple.wallpaper.choice.image".into(),
                                                ),
                                            );
                                            choice_dict.insert(
                                                "Files".into(),
                                                plist::Value::Array(vec![]),
                                            );
                                            choice_dict
                                                .insert("Configuration".into(), cfg_data.clone());
                                            if let Some(eov) = sample_eov {
                                                content_dict.insert(
                                                    "EncodedOptionValues".into(),
                                                    eov.clone(),
                                                );
                                            }
                                            idle_dict.insert("LastSet".into(), now.clone());
                                            idle_dict.insert("LastUse".into(), now.clone());
                                            count += 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for (k, v) in dict.iter_mut() {
                if k == "Idle" {
                    continue;
                }
                count += patch_idle_nodes(v, cfg_data, sample_eov, now);
            }
        }
        plist::Value::Array(arr) => {
            for v in arr.iter_mut() {
                count += patch_idle_nodes(v, cfg_data, sample_eov, now);
            }
        }
        _ => {}
    }
    count
}

pub fn list() -> Result<(), String> {
    let manifest = load_manifest()?;
    if !manifest.pairs.is_empty() {
        for p in &manifest.pairs {
            println!("pair\t{}\t{}\t{}", p.id, p.light, p.dark);
        }
    }
    for e in &manifest.wallpapers {
        println!("{}\t{}", e.name, e.image);
    }
    Ok(())
}

pub fn list_themes() -> Result<(), String> {
    let manifest = load_manifest()?;
    if manifest.themes.is_empty() {
        return Err("wallpaper pack has no theme families (rebuild?)".into());
    }
    for t in &manifest.themes {
        println!("{}\t{}\t{}", t.name, t.colors.dark, t.colors.light);
    }
    Ok(())
}

/// Desktop-current wallpaper for Linux gtkgreet/gtklock (1:1 with swaybg).
/// Prints `image\tblur`.
pub fn resolve_auth() -> Result<(), String> {
    for path in [
        PathBuf::from("/var/lib/dendritic/auth/current.tsv"),
        state::home_dir()
            .map(|h| h.join(".local/state/dendritic/auth/current.tsv"))
            .unwrap_or_default(),
    ] {
        if path.is_file() {
            if let Ok(raw) = std::fs::read_to_string(&path) {
                let line = raw.lines().next().unwrap_or("").trim();
                if !line.is_empty() {
                    let mut parts = line.split('\t');
                    if let (Some(image), Some(blur)) = (parts.next(), parts.next()) {
                        if Path::new(image).is_file() {
                            println!("{image}\t{blur}");
                            eprintln!("dendritic-appearance: auth wallpaper (published)");
                            return Ok(());
                        }
                    }
                }
            }
        }
    }

    let manifest = load_manifest()?;
    let variant = state::read_wallpaper_variant().unwrap_or(Variant::Dark);
    let pair = current_or_daily_pair(&manifest)?;
    let theme = current_or_daily_theme(&manifest)?;
    let prepared = prepare(&manifest, pair, theme, variant)?;
    println!("{}\t{}", prepared.image, prepared.blur);
    eprintln!(
        "dendritic-appearance: auth wallpaper {} (= desktop)",
        prepared.name
    );
    Ok(())
}

/// Pack entry for the lock screen.
/// - Linux: same as desktop (`resolve_auth`) for gtklock 1:1.
/// - macOS: next pair, same polarity / theme.
pub fn resolve_lock() -> Result<(), String> {
    #[cfg(target_os = "linux")]
    {
        return resolve_auth();
    }
    #[cfg(not(target_os = "linux"))]
    {
        let manifest = load_manifest()?;
        let variant = state::read_wallpaper_variant().unwrap_or(Variant::Dark);
        let pair = current_or_daily_pair(&manifest)?;
        let theme = current_or_daily_theme(&manifest)?;
        let lock_pair = next_pair(&manifest, pair)?;
        let prepared = prepare(&manifest, lock_pair, theme, variant)?;
        println!("{}\t{}", prepared.image, prepared.blur);
        eprintln!(
            "dendritic-appearance: lock wallpaper {} (desktop={})",
            prepared.name, pair.id
        );
        Ok(())
    }
}

/// Re-apply lock wallpaper only (desktop unchanged). Useful after System Settings drift.
pub fn apply_lock_only() -> Result<(), String> {
    let manifest = load_manifest()?;
    let variant = state::read_wallpaper_variant().unwrap_or(Variant::Dark);
    let pair = current_or_daily_pair(&manifest)?;
    let theme = current_or_daily_theme(&manifest)?;
    let lock_pair = next_pair(&manifest, pair)?;
    let prepared = prepare(&manifest, lock_pair, theme, variant)?;
    apply_lock_image(&prepared.image)?;

    if let Ok(raw) = std::fs::read_to_string(state::wallpaper_state_path()) {
        if let Ok(mut v) = serde_json::from_str::<serde_json::Value>(&raw) {
            v["lock_name"] = serde_json::json!(prepared.name);
            v["lock_image"] = serde_json::json!(prepared.image);
            let _ = std::fs::write(
                state::wallpaper_state_path(),
                serde_json::to_string_pretty(&v).unwrap_or_default(),
            );
        }
    }

    eprintln!("dendritic-appearance: lock-only {}", prepared.name);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn day_index_wraps() {
        assert_eq!(day_index(0), 0);
        assert_eq!(day_index(1), 0);
        let i = day_index(10);
        assert!(i < 10);
    }
}
