//! dendritic-appearance — pure-Rust appearance state machine (macOS + NixOS).
//!
//! Never leaves light/dark desynced. No osascript. No Python for sync paths.

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "macos")]
mod macos;

mod activate;
mod ide;
mod machine;
mod observe;
mod palette;
mod reconcile;
mod state;
mod supervise;
mod wallpaper;

use std::process::ExitCode;

use machine::MachineStatus;
use state::{Variant, WaybarStatus};

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(code) => ExitCode::from(code as u8),
    }
}

fn run() -> Result<(), i32> {
    let mut args = std::env::args().skip(1);
    let cmd = args.next().unwrap_or_else(|| "status".into());
    match cmd.as_str() {
        "detect" => {
            println!("{}", observe_host().as_str());
            Ok(())
        }
        "reconcile" | "sync" => {
            let st = reconcile::reconcile().map_err(|e| {
                eprintln!("{e}");
                1
            })?;
            print_status(&st, false);
            Ok(())
        }
        "supervise" | "daemon" => {
            let secs = args.next().and_then(|s| s.parse().ok()).unwrap_or(2);
            supervise::supervise(secs).map_err(|e| {
                eprintln!("{e}");
                1
            })
        }
        "set" => {
            let v = Variant::parse(&args.next().unwrap_or_default()).ok_or(2)?;
            let st = reconcile::force(v, "current").map_err(|e| {
                eprintln!("{e}");
                1
            })?;
            print_status(&st, false);
            Ok(())
        }
        "toggle" => {
            let st = reconcile::force(observe_host().opposite(), "current").map_err(|e| {
                eprintln!("{e}");
                1
            })?;
            print_status(&st, false);
            Ok(())
        }
        "apply" => {
            let mut variant = None;
            let mut wallpaper_target = "current".to_string();
            while let Some(a) = args.next() {
                match a.as_str() {
                    "--variant" => variant = args.next(),
                    "--wallpaper" => {
                        wallpaper_target = args.next().unwrap_or_else(|| "current".into());
                    }
                    other if !other.starts_with('-') && variant.is_none() => {
                        variant = Some(a);
                    }
                    _ => {}
                }
            }
            let v = match variant.as_deref() {
                Some(s) => Variant::parse(s).ok_or(2)?,
                None => observe_host(),
            };
            reconcile::force(v, &wallpaper_target).map_err(|e| {
                eprintln!("{e}");
                1
            })?;
            Ok(())
        }
        "wallpaper" => {
            let target = args.next().unwrap_or_else(|| "daily".into());
            let v = observe_host();
            wallpaper::apply(v, &target).map_err(|e| {
                eprintln!("{e}");
                1
            })?;
            let _ = reconcile::reconcile();
            Ok(())
        }
        "tint" => {
            #[cfg(target_os = "macos")]
            {
                macos::apply_tint_from_colors_toml(&observe::colors_toml_path()).map_err(|_| 1)?;
                println!("dendritic-appearance: tint ok");
            }
            #[cfg(not(target_os = "macos"))]
            {
                println!("tint: macOS only");
            }
            Ok(())
        }
        "status" => {
            let waybar = args.any(|a| a == "--waybar");
            let obs = observe::observe();
            let st = MachineStatus {
                phase: obs.phase(),
                observation: obs,
            };
            print_status(&st, waybar);
            Ok(())
        }
        "list-wallpapers" => wallpaper::list().map_err(|e| {
            eprintln!("{e}");
            1
        }),
        "help" | "-h" | "--help" => {
            print_help();
            Ok(())
        }
        other => {
            eprintln!("unknown: {other}");
            print_help();
            Err(1)
        }
    }
}

fn observe_host() -> Variant {
    observe::observe().host
}

fn print_status(st: &MachineStatus, waybar: bool) {
    if waybar {
        let v = match &st.phase {
            machine::Phase::Synced { variant } => *variant,
            machine::Phase::Desynced { host, .. } => *host,
            machine::Phase::Applying { target, .. } => *target,
            machine::Phase::Failed { target, .. } => *target,
        };
        let synced = matches!(st.phase, machine::Phase::Synced { .. });
        let status = WaybarStatus {
            text: if v == Variant::Dark {
                if synced {
                    "󰖔".into()
                } else {
                    "󰖔!".into()
                }
            } else if synced {
                "󰖙".into()
            } else {
                "󰖙!".into()
            },
            tooltip: format!(
                "phase: {:?}\nhost: {}\nwallpaper: {}\nclick: toggle",
                st.phase,
                st.observation.host,
                st.observation
                    .wallpaper_name
                    .clone()
                    .unwrap_or_else(|| "?".into())
            ),
            class: if synced {
                v.as_str().into()
            } else {
                "desync".into()
            },
        };
        println!("{}", serde_json::to_string(&status).unwrap());
    } else {
        println!("{}", serde_json::to_string_pretty(st).unwrap());
    }
}

fn print_help() {
    eprintln!(
        "\
dendritic-appearance — pure Rust light/dark state machine (no desync)

  detect                 Print host appearance
  reconcile | sync       Observe → apply until host==layers
  supervise [SECS]       Daemon: poll+reconcile forever (default 2s)
  set <light|dark>       Force host + global apply
  toggle                 Flip host + global apply
  apply [--variant V] [--wallpaper current|daily|next|NAME]
  wallpaper <daily|next|NAME|current>
  tint                   macOS accent/highlight from colors.toml
  status [--waybar]
  list-wallpapers
"
    );
}
