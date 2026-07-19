//! Deterministic appearance state machine.
//!
//! Authority:
//!   - macOS: AppleInterfaceStyle (host chrome) is source of truth
//!   - Linux: committed dendritic state (toggle/set) is source of truth;
//!            gsettings must track it
//!
//! Invariant: after every successful reconcile, host == recorded == colors
//!            == wallpaper-variant. Desync is never left standing.

use crate::state::Variant;
use serde::Serialize;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Phase {
    Synced { variant: Variant },
    Desynced {
        host: Variant,
        recorded: Option<Variant>,
        reasons: Vec<String>,
    },
    Applying { target: Variant, attempt: u32 },
    Failed { target: Variant, error: String },
}

#[derive(Debug, Clone, Serialize)]
pub struct Observation {
    pub host: Variant,
    pub recorded: Option<Variant>,
    pub colors_variant: Option<Variant>,
    pub wallpaper_variant: Option<Variant>,
    pub wallpaper_name: Option<String>,
    pub reasons: Vec<String>,
}

impl Observation {
    pub fn synced(&self) -> bool {
        self.reasons.is_empty()
    }

    pub fn phase(&self) -> Phase {
        if self.synced() {
            Phase::Synced {
                variant: self.host,
            }
        } else {
            Phase::Desynced {
                host: self.host,
                recorded: self.recorded,
                reasons: self.reasons.clone(),
            }
        }
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct MachineStatus {
    pub phase: Phase,
    pub observation: Observation,
}
