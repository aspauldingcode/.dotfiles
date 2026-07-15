//! dendritic-appearance — activation-only light/dark + wallpaper sync.
//!
//! No osascript. macOS appearance set via SkyLight private API; detect via
//! `defaults`. Linux via gsettings / our state file. Palette + wallpaper come
//! from the declarative wallpaper pack (flavours dark/light per image).

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "macos")]
mod palette;
mod state;

use std::env;
use std::path::PathBuf;
use std::process::{Command, ExitCode};

use state::{Variant, WaybarStatus};

fn main() -> ExitCode {
    let mut args = env::args().skip(1);
    let cmd = args.next().unwrap_or_else(|| "status".into());
    let result = match cmd.as_str() {
        "detect" => cmd_detect(),
        "set" => {
            let v = args.next().unwrap_or_default();
            cmd_set(&v)
        }
        "toggle" => cmd_toggle(),
        "apply" => {
            let mut variant = None;
            let mut wallpaper = "current".to_string();
            while let Some(a) = args.next() {
                match a.as_str() {
                    "--variant" => variant = args.next(),
                    "--wallpaper" => {
                        wallpaper = args.next().unwrap_or_else(|| "current".into());
                    }
                    other if !other.starts_with('-') && variant.is_none() => {
                        variant = Some(a);
                    }
                    _ => {}
                }
            }
            cmd_apply(variant.as_deref(), &wallpaper)
        }
        "tint" => cmd_tint(),
        "status" => {
            let waybar = args.any(|a| a == "--waybar");
            cmd_status(waybar)
        }
        "help" | "-h" | "--help" => {
            print_help();
            Ok(())
        }
        other => {
            eprintln!("unknown command: {other}");
            print_help();
            Err(1)
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(code) => ExitCode::from(code as u8),
    }
}

fn print_help() {
    eprintln!(
        "\
dendritic-appearance — activation-only theme sync (no rebuild, no osascript)

  detect                 Print light|dark (host appearance)
  set <light|dark>       Set host appearance + apply palette/wallpaper
  toggle                 Flip host appearance + apply
  apply [--variant V] [--wallpaper daily|current|NAME]
                         Apply palette+wallpaper for variant (default: detect)
  tint                   Apply macOS accent/highlight from ~/colors.toml
  status [--waybar]      JSON status (waybar module format with --waybar)
"
    );
}

fn cmd_detect() -> Result<(), i32> {
    let v = detect_variant()?;
    println!("{}", v.as_str());
    Ok(())
}

fn cmd_set(raw: &str) -> Result<(), i32> {
    let v = Variant::parse(raw).ok_or_else(|| {
        eprintln!("set: expected light|dark, got {raw}");
        2
    })?;
    set_and_apply(v, "current")
}

fn cmd_toggle() -> Result<(), i32> {
    let cur = detect_variant()?;
    let next = cur.opposite();
    set_and_apply(next, "current")
}

fn cmd_apply(variant: Option<&str>, wallpaper: &str) -> Result<(), i32> {
    let v = match variant {
        Some(s) => Variant::parse(s).ok_or_else(|| {
            eprintln!("apply: bad --variant {s}");
            2
        })?,
        None => detect_variant()?,
    };
    apply_theme_layer(v, wallpaper)
}

fn cmd_tint() -> Result<(), i32> {
    #[cfg(target_os = "macos")]
    {
        macos::apply_tint_from_colors_toml(&colors_toml_path())?;
        println!("dendritic-appearance: macOS tint applied from colors.toml");
        Ok(())
    }
    #[cfg(not(target_os = "macos"))]
    {
        println!("dendritic-appearance: tint is macOS-only (noop)");
        Ok(())
    }
}

fn cmd_status(waybar: bool) -> Result<(), i32> {
    let host = detect_variant().unwrap_or(Variant::Dark);
    let applied = state::read_applied_variant().unwrap_or(host);
    let wallpaper = state::read_wallpaper_name().unwrap_or_else(|| "unknown".into());
    if waybar {
        let status = WaybarStatus {
            text: if applied == Variant::Dark {
                "󰖔".into()
            } else {
                "󰖙".into()
            },
            tooltip: format!(
                "appearance: {}\nwallpaper: {}\nclick: toggle light/dark",
                applied.as_str(),
                wallpaper
            ),
            class: applied.as_str().into(),
        };
        println!("{}", serde_json::to_string(&status).unwrap());
    } else {
        let obj = serde_json::json!({
            "host": host.as_str(),
            "applied": applied.as_str(),
            "wallpaper": wallpaper,
        });
        println!("{}", serde_json::to_string_pretty(&obj).unwrap());
    }
    Ok(())
}

fn detect_variant() -> Result<Variant, i32> {
    #[cfg(target_os = "macos")]
    {
        macos::detect()
    }
    #[cfg(target_os = "linux")]
    {
        linux::detect()
    }
    #[cfg(not(any(target_os = "macos", target_os = "linux")))]
    {
        state::read_applied_variant().ok_or(1)
    }
}

fn set_and_apply(v: Variant, wallpaper: &str) -> Result<(), i32> {
    #[cfg(target_os = "macos")]
    {
        macos::set(v)?;
    }
    #[cfg(target_os = "linux")]
    {
        linux::set(v)?;
    }
    // Persist before wallpaper so dendritic-wallpaper resolve_variant sees it.
    state::write_appearance_variant(v)?;
    apply_theme_layer(v, wallpaper)?;
    try_fast_activate(v);
    Ok(())
}

fn apply_theme_layer(v: Variant, wallpaper: &str) -> Result<(), i32> {
    let wallpaper_bin =
        env::var("DENDRITIC_WALLPAPER_BIN").unwrap_or_else(|_| "dendritic-wallpaper".into());
    let target = if wallpaper == "current" {
        match state::read_wallpaper_name() {
            Some(name) if !name.is_empty() && name != "unknown" => name,
            _ => "daily".into(),
        }
    } else {
        wallpaper.to_string()
    };

    let status = Command::new(&wallpaper_bin)
        .env("DENDRITIC_THEME_VARIANT", v.as_str())
        .args(["apply", &target])
        .status()
        .map_err(|e| {
            eprintln!("dendritic-appearance: failed to run {wallpaper_bin}: {e}");
            1
        })?;
    if !status.success() {
        eprintln!("dendritic-appearance: {wallpaper_bin} apply failed");
        return Err(status.code().unwrap_or(1));
    }

    #[cfg(target_os = "macos")]
    {
        let _ = macos::apply_tint_from_colors_toml(&colors_toml_path());
    }

    state::write_applied_variant(v)?;
    println!(
        "dendritic-appearance: applied {} (wallpaper={})",
        v.as_str(),
        target
    );
    Ok(())
}

fn try_fast_activate(v: Variant) {
    let helper = PathBuf::from("/etc/dendritic-appearance-activate-prebuilt.sh");
    if helper.is_file() {
        let _ = Command::new("/bin/sh")
            .arg(&helper)
            .arg(v.as_str())
            .status();
        return;
    }
    #[cfg(target_os = "linux")]
    {
        linux::try_specialisation_activate(v);
    }
}

fn colors_toml_path() -> PathBuf {
    env::var_os("DENDRITIC_COLORS_FILE")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            dirs_home()
                .map(|h| h.join("colors.toml"))
                .unwrap_or_else(|| PathBuf::from("colors.toml"))
        })
}

fn dirs_home() -> Option<PathBuf> {
    env::var_os("HOME").map(PathBuf::from)
}
