//! Reconcile loop: never leave host/applied/colors/wallpaper desynced.

use crate::activate;
use crate::machine::{MachineStatus, Phase};
use crate::observe;
use crate::observe::colors_toml_path;
use crate::state::{self, Variant};
use crate::wallpaper;

#[cfg(target_os = "macos")]
use crate::macos;

const MAX_ATTEMPTS: u32 = 3;

/// Follow host appearance and apply globally until observation is synced.
pub fn reconcile() -> Result<MachineStatus, String> {
    let mut last_err = String::new();
    for attempt in 1..=MAX_ATTEMPTS {
        let obs = observe::observe();
        if obs.synced() {
            let status = MachineStatus {
                phase: Phase::Synced {
                    variant: obs.host,
                },
                observation: obs,
            };
            state::write_phase_snapshot(&status);
            eprintln!("dendritic-appearance: SYNCED ({})", status.observation.host);
            return Ok(status);
        }

        let target = obs.host;
        eprintln!(
            "dendritic-appearance: DESYNC attempt {attempt}/{MAX_ATTEMPTS} → {target}: {:?}",
            obs.reasons
        );
        let applying = MachineStatus {
            phase: Phase::Applying { target, attempt },
            observation: obs,
        };
        state::write_phase_snapshot(&applying);

        match apply_global(target, "current") {
            Ok(()) => {
                let again = observe::observe();
                if again.synced() {
                    let status = MachineStatus {
                        phase: Phase::Synced {
                            variant: again.host,
                        },
                        observation: again,
                    };
                    state::write_phase_snapshot(&status);
                    eprintln!("dendritic-appearance: SYNCED after apply ({target})");
                    return Ok(status);
                }
                last_err = format!("still desynced after apply: {:?}", again.reasons);
            }
            Err(e) => {
                last_err = e;
                eprintln!("dendritic-appearance: apply error: {last_err}");
            }
        }
    }

    let obs = observe::observe();
    let status = MachineStatus {
        phase: Phase::Failed {
            target: obs.host,
            error: last_err.clone(),
        },
        observation: obs,
    };
    state::write_phase_snapshot(&status);
    Err(last_err)
}

/// Force a variant (toggle/set): set host chrome, then reconcile.
pub fn force(variant: Variant, wallpaper_target: &str) -> Result<MachineStatus, String> {
    #[cfg(target_os = "macos")]
    {
        macos::set(variant).map_err(|c| format!("macos set failed ({c})"))?;
    }
    #[cfg(target_os = "linux")]
    {
        crate::linux::set(variant).map_err(|c| format!("linux set failed ({c})"))?;
    }
    apply_global(variant, wallpaper_target)?;
    // Re-observe; if host didn't flip yet, still ensure our layers match requested.
    let mut obs = observe::observe();
    if obs.host != variant {
        // Host lag: record requested and apply layers for requested variant.
        eprintln!(
            "dendritic-appearance: host still {:?}, locking layers to {variant}",
            obs.host
        );
        apply_global(variant, wallpaper_target)?;
        obs = observe::observe();
    }
    if obs.synced() && obs.host == variant {
        let status = MachineStatus {
            phase: Phase::Synced { variant },
            observation: obs,
        };
        state::write_phase_snapshot(&status);
        return Ok(status);
    }
    // Run full reconcile following whatever host reports now.
    reconcile()
}

fn apply_global(variant: Variant, wallpaper_target: &str) -> Result<(), String> {
    state::write_appearance_variant(variant)?;
    wallpaper::apply(variant, wallpaper_target)?;

    #[cfg(target_os = "macos")]
    {
        let _ = macos::apply_tint_from_colors_toml(&colors_toml_path());
    }

    // Hot theme layer — same on Darwin and NixOS (wallpaper palette → apps).
    let colors = colors_toml_path();
    let _ = crate::tmux::apply_from_colors(&colors);
    let _ = crate::ghostty::apply_from_colors(&colors);
    let _ = crate::qt::apply_from_colors(&colors);
    let _ = crate::ide::patch_from_colors(&colors);

    // Prebuilt / specialisation (best-effort; hot layer already applied)
    if let Err(e) = activate::activate(variant) {
        eprintln!("dendritic-appearance: activate warning: {e}");
    }

    state::write_applied_variant(variant)?;
    Ok(())
}
