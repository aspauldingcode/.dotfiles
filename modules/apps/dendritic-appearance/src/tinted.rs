//! Shared TintedBrowse-style palette tokens (`--tb-baseXX`).
//! Auxiliary CSS only — the LUT rewriter does the actual tinting.

use std::collections::HashMap;

const SLOTS: [&str; 16] = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07", "base08",
    "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F",
];

fn req<'a>(map: &'a HashMap<String, String>, key: &str) -> Result<&'a str, String> {
    map.get(key)
        .map(String::as_str)
        .ok_or_else(|| format!("palette missing {key}"))
}

/// `:root, :host { --tb-base00: … }` — same auxiliary sheet as TintedBrowse.
pub fn palette_css(p: &HashMap<String, String>) -> Result<String, String> {
    let mut out = String::from(
        "/**\n * TintedBrowse palette tokens. LUT rewriter tints authored CSS;\n * this block does not remap Discord/Spotify chrome variables.\n */\n\n:root, :host {\n",
    );
    for slot in SLOTS {
        let v = req(p, slot)?;
        out.push_str(&format!("    --tb-{slot}: {v};\n"));
    }
    out.push_str("}\n");
    Ok(out)
}

pub fn palette_json(p: &HashMap<String, String>) -> Result<String, String> {
    let mut obj = serde_json::Map::new();
    for slot in SLOTS {
        obj.insert(slot.to_string(), serde_json::Value::String(req(p, slot)?.into()));
    }
    serde_json::to_string_pretty(&serde_json::Value::Object(obj))
        .map_err(|e| format!("palette json: {e}"))
}
