//! IDE one-shots previously implemented in Python.

use std::path::PathBuf;

use anyhow::{bail, Context, Result};
use rusqlite::Connection;

const KEYS: &[&str] = &[
    "cursor/attributeCommitsToAgent",
    "cursor/attributePRsToAgent",
];

fn cursor_db_candidates() -> Vec<PathBuf> {
    let home = dirs_home();
    vec![
        home.join("Library/Application Support/Cursor/User/globalStorage/state.vscdb"),
        home.join(".config/Cursor/User/globalStorage/state.vscdb"),
        home.join(".config/Cursor/User/globalStorage/state.vscdb"),
    ]
}

fn dirs_home() -> PathBuf {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

/// Disable Cursor Agent commit/PR attribution trailers.
pub fn cursor_disable_attribution() -> Result<()> {
    let mut touched = 0usize;
    for db in cursor_db_candidates() {
        if !db.is_file() {
            continue;
        }
        let conn = Connection::open(&db)
            .with_context(|| format!("open {}", db.display()))?;
        for key in KEYS {
            conn.execute(
                "INSERT INTO ItemTable (key, value) VALUES (?1, ?2)
                 ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                rusqlite::params![key, "false"],
            )
            .with_context(|| format!("upsert {key} in {}", db.display()))?;
        }
        eprintln!(
            "cursor-disable-attribution: set {:?} = 'false' in {}",
            KEYS,
            db.display()
        );
        touched += 1;
    }
    if touched == 0 {
        bail!("no Cursor state.vscdb found under known paths");
    }
    Ok(())
}
