//! User-space notifications (no osascript, no root).

use anyhow::{Context, Result};
use notify_rust::Notification;

pub fn show(title: &str, body: &str) -> Result<()> {
    Notification::new()
        .summary(title)
        .body(body)
        .appname("dendritic")
        .show()
        .context("show notification")?;
    Ok(())
}
