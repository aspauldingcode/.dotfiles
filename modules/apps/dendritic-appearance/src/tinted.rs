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

fn variant_from_base00(hex: &str) -> &'static str {
    let h = hex.trim().trim_start_matches('#');
    if h.len() != 6 {
        return "dark";
    }
    let r = u32::from(u8::from_str_radix(&h[0..2], 16).unwrap_or(0));
    let g = u32::from(u8::from_str_radix(&h[2..4], 16).unwrap_or(0));
    let b = u32::from(u8::from_str_radix(&h[4..6], 16).unwrap_or(0));
    let y = 2126 * r + 7152 * g + 722 * b;
    if y > 5_000 * 255 {
        "light"
    } else {
        "dark"
    }
}

/// `:root, :host { --tb-base00: … }` — same auxiliary sheet as TintedBrowse.
pub fn palette_css(p: &HashMap<String, String>) -> Result<String, String> {
    let variant = variant_from_base00(req(p, "base00")?);
    let mut out = String::from(
        "/**\n * TintedBrowse palette tokens. LUT rewriter tints authored CSS;\n * this block does not remap Discord/Spotify chrome variables.\n */\n\n:root, :host {\n",
    );
    out.push_str(&format!("    color-scheme: {variant};\n"));
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

/// Spotify CEF serves `https://xpui.app.spotify.com/` and maps
/// `extensions/*.js` from the local xpui folder (same as Spicetify).
/// A `.json` next to `index.html` 404s; this file does not.
pub fn palette_js(p: &HashMap<String, String>) -> Result<String, String> {
    let json = palette_json(p)?;
    Ok(format!(
        "/*dendritic-palette*/globalThis.__DENDRITIC_PALETTE__ = {json};\n/*dendritic-palette-end*/\n"
    ))
}
