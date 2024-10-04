from PIL import Image
import numpy as np
import sys

def parse_palette(palette_str):
    """Parse a comma-separated string of hex colors into a list."""
    return palette_str.split(',')

def hex_to_rgb(hex_color):
    """Convert a hex color to an RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def normalize_colors(colors):
    """Normalize a list of hex colors to [0, 1] RGB values."""
    return np.array([hex_to_rgb(color) for color in colors]) / 255.0

def rgb_to_hsv_vectorized(rgb):
    """Vectorized conversion from RGB to HSV."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    v = maxc

    s = np.zeros_like(maxc)
    mask = maxc != 0
    s[mask] = (maxc - minc)[mask] / maxc[mask]

    h = np.zeros_like(maxc)
    diff = maxc - minc
    mask_diff = diff != 0

    rc = np.zeros_like(r)
    gc = np.zeros_like(g)
    bc = np.zeros_like(b)

    rc[mask_diff] = (maxc - r)[mask_diff] / diff[mask_diff]
    gc[mask_diff] = (maxc - g)[mask_diff] / diff[mask_diff]
    bc[mask_diff] = (maxc - b)[mask_diff] / diff[mask_diff]

    h_candidates = np.zeros((r.shape[0], r.shape[1], 3)) if rgb.ndim > 2 else np.zeros((rgb.shape[0], 3))

    h_candidates[..., 0] = (bc - gc)  # r == maxc
    h_candidates[..., 1] = 2.0 + (rc - bc)  # g == maxc
    h_candidates[..., 2] = 4.0 + (gc - rc)  # b == maxc

    if rgb.ndim > 2:
        idx = np.argmax(np.stack([r, g, b], axis=-1), axis=-1)
        h[mask_diff] = h_candidates[..., 0][mask_diff] * (idx == 0)[mask_diff] + \
                       h_candidates[..., 1][mask_diff] * (idx == 1)[mask_diff] + \
                       h_candidates[..., 2][mask_diff] * (idx == 2)[mask_diff]
    else:
        idx = np.argmax(rgb, axis=-1)
        h[mask_diff] = h_candidates[np.arange(len(h)), idx][mask_diff]

    h = (h / 6.0) % 1.0
    return np.stack([h, s, v], axis=-1)

def hsv_to_rgb_vectorized(hsv):
    """Vectorized conversion from HSV to RGB."""
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    h = h * 6.0
    i = np.floor(h).astype(int)
    f = h - i
    i = i % 6

    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))

    conditions = [i == k for k in range(6)]
    r = np.select(conditions, [v, q, p, p, t, v])
    g = np.select(conditions, [t, v, v, q, p, p])
    b = np.select(conditions, [p, p, t, v, v, q])

    return np.stack([r, g, b], axis=-1)

if len(sys.argv) < 4:
    print("Usage: python recolor_base16_hue_filter_efficient.py <input_image_path> <output_image_path> <palette>")
    print("Example palette: '#32302f,#3c3836,#504945,#665c54,#bdae93,#d5c4a1,#ebdbb2,#fbf1c7,#fb4934,#fe8019,#fabd2f,#b8bb26,#8ec07c,#83a598,#d3869b,#d65d0e'")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]
palette_str = sys.argv[3]

# Define a Base16 color palette using hexadecimal values from CLI
BASE16_PALETTE = parse_palette(palette_str)
BASE16_PALETTE_NORMALIZED = normalize_colors(BASE16_PALETTE)

def apply_hue_adjustment(input_path, output_path, palette_normalized):
    """Apply a hue adjustment to an image using the normalized Base16 color palette."""
    image = Image.open(input_path).convert('RGB')
    pixels = np.array(image) / 255.0  # Normalize to [0, 1]

    # Convert palette to hues
    palette_hsv = rgb_to_hsv_vectorized(palette_normalized[np.newaxis, :])
    palette_hues = palette_hsv[0, :, 0]  # Extract hues
    palette_v_min, palette_v_max = np.min(palette_hsv[..., 2]), np.max(palette_hsv[..., 2])

    # Convert image to HSV
    hsv_pixels = rgb_to_hsv_vectorized(pixels)
    image_hues = hsv_pixels[..., 0]
    # Compute hue differences, considering wrap-around
    diffs = np.abs(image_hues[..., np.newaxis] - palette_hues)
    diffs = np.minimum(diffs, 1.0 - diffs)
    indices = np.argmin(diffs, axis=-1)
    new_hues = palette_hues[indices]

    # Limit hue adjustment to a small range
    hue_adjustment_limit = 0.05
    hue_diffs = new_hues - image_hues
    hue_diffs = np.where(hue_diffs > 0.5, hue_diffs - 1.0, hue_diffs)
    hue_diffs = np.where(hue_diffs < -0.5, hue_diffs + 1.0, hue_diffs)
    hue_diffs = np.clip(hue_diffs, -hue_adjustment_limit, hue_adjustment_limit)
    new_hues = image_hues + hue_diffs
    new_hues = new_hues % 1.0

    # Update hues
    hsv_pixels[..., 0] = new_hues

    # Quantize brightness and saturation to 8 levels to limit shading steps
    hsv_pixels[..., 1] = np.floor(hsv_pixels[..., 1] * 8) / 7.0
    hsv_pixels[..., 2] = np.floor(hsv_pixels[..., 2] * 8) / 7.0
    hsv_pixels[..., 1] = np.clip(hsv_pixels[..., 1], 0, 1)
    hsv_pixels[..., 2] = np.clip(hsv_pixels[..., 2], 0, 1)

    # Normalize brightness to match the palette's brightness range
    image_v_min, image_v_max = np.min(hsv_pixels[..., 2]), np.max(hsv_pixels[..., 2])
    hsv_pixels[..., 2] = (hsv_pixels[..., 2] - image_v_min) / (image_v_max - image_v_min) * (palette_v_max - palette_v_min) + palette_v_min

    # Convert back to RGB
    rgb_pixels = hsv_to_rgb_vectorized(hsv_pixels)
    rgb_pixels = (rgb_pixels * 255).astype(np.uint8)

    adjusted_image = Image.fromarray(rgb_pixels, 'RGB')
    adjusted_image.save(output_path)

if __name__ == "__main__":
    input_path = sys.argv[1]
    output_path = sys.argv[2]

    apply_hue_adjustment(input_path, output_path, BASE16_PALETTE_NORMALIZED)
    print("Hue adjustment applied using Base16 palette successfully.")
