use std::collections::HashMap;
use std::path::Path;

pub fn load_palette(path: &Path) -> Result<HashMap<String, String>, String> {
    let text =
        std::fs::read_to_string(path).map_err(|e| format!("read {}: {e}", path.display()))?;
    let mut map = HashMap::new();
    let mut in_palette = false;
    for line in text.lines() {
        let t = line.trim();
        if t.starts_with('[') {
            in_palette = t == "[palette]";
            continue;
        }
        if !in_palette || t.is_empty() || t.starts_with('#') {
            continue;
        }
        if let Some((k, v)) = t.split_once('=') {
            let key = k.trim().to_string();
            let mut val = v.trim().trim_matches('"').to_string();
            if !val.starts_with('#') && val.len() == 6 {
                val = format!("#{val}");
            }
            map.insert(key, val);
        }
    }
    Ok(map)
}

#[cfg(target_os = "macos")]
pub fn hex_to_tint_str(hex: &str) -> Result<String, String> {
    let h = hex.trim().trim_start_matches('#');
    if h.len() != 6 {
        return Err(format!("bad hex: {hex}"));
    }
    let r = u8::from_str_radix(&h[0..2], 16).map_err(|e| e.to_string())?;
    let g = u8::from_str_radix(&h[2..4], 16).map_err(|e| e.to_string())?;
    let b = u8::from_str_radix(&h[4..6], 16).map_err(|e| e.to_string())?;
    Ok(format!(
        "{} {} {} 1.00",
        byte_to_float(r),
        byte_to_float(g),
        byte_to_float(b)
    ))
}

#[cfg(target_os = "macos")]
fn byte_to_float(n: u8) -> String {
    let scaled = (u32::from(n) * 10000) / 255;
    let whole = scaled / 10000;
    let frac = scaled % 10000;
    format!("{whole}.{frac:04}")
}
