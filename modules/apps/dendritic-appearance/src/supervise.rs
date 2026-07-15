//! Long-running supervisor: poll host appearance and reconcile forever.

use std::time::Duration;

use crate::reconcile;

pub fn supervise(interval_secs: u64) -> Result<(), String> {
    eprintln!(
        "dendritic-appearance: supervisor start (interval={interval_secs}s)"
    );
    // Immediate reconcile on boot / launchd RunAtLoad.
    if let Err(e) = reconcile::reconcile() {
        eprintln!("dendritic-appearance: initial reconcile: {e}");
    }
    loop {
        std::thread::sleep(Duration::from_secs(interval_secs.max(1)));
        match reconcile::reconcile() {
            Ok(_) => {}
            Err(e) => eprintln!("dendritic-appearance: reconcile: {e}"),
        }
    }
}
