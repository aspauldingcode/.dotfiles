# This script recolors an image using a Base16 color palette with accurate matching for base08 to base0f, and accurate shades matching for base00 to base07.
# it is inefficient currently. the goal is to make it more efficient, and more accurate. currently, it does not properly handle the shades of the base colors.

from PIL import Image
import numpy as np
import sys
import os
import colorsys
from tqdm import tqdm

# Global constants for sRGB to XYZ and LAB conversion
M_SRGB = np.array([[0.4124564, 0.3575761, 0.1804375],
                   [0.2126729, 0.7151522, 0.0721750],
                   [0.0193339, 0.1191920, 0.9503041]], dtype=np.float32)
WHITE_POINT = np.array([0.95047, 1.00000, 1.08883], dtype=np.float32)
EPSILON = 0.008856
KAPPA = 903.3

def parse_palette(palette_str):
    """Parse a comma‐separated string of colors and return only valid hex color strings."""
    tokens = palette_str.split(',')
    valid_colors = [token.strip() for token in tokens if token.strip().startswith('#') and len(token.strip()) == 7]
    if not valid_colors:
        print("Error: No valid hex colors found in the palette!")
        sys.exit(1)
    return valid_colors

def parse_shades_palette(palette):
    """Return the first 8 colors (base00 to base07) as shades."""
    return palette[:8]

def parse_colors_palette(palette):
    """Return the last 8 colors (base08 to base0F) as accent colors."""
    return palette[8:]

if len(sys.argv) < 5:
    print("Usage: python recolor_base16_inputs_efficient.py <input_image_path> <output_image_path> <mode> <palette>")
    print("Example palette: 'dark,#32302f,#3c3836,#504945,#665c54,#bdae93,#d5c4a1,#ebdbb2,#fbf1c7,#fb4934,#fe8019,#fabd2f,#b8bb26,#8ec07c,#83a598,#d3869b,#d65d0e'")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]
mode = sys.argv[3].lower()
palette_str = sys.argv[4]

# Extract only valid hex colors (ignoring any theme names or invalid entries)
BASE16_PALETTE = parse_palette(palette_str)

def hex_to_rgb(hex_color):
    """Convert a hex color string to an RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hsv(rgb):
    """Convert an RGB tuple (0-255) to an HSV tuple (all in [0,1])."""
    return colorsys.rgb_to_hsv(*(c / 255.0 for c in rgb))

def hsv_to_rgb(hsv):
    """Convert an HSV tuple (with values in [0,1]) to an RGB tuple (0-255)."""
    return tuple(round(c * 255) for c in colorsys.hsv_to_rgb(*hsv))

def normalize_range_255(val1, val2):
    """Normalize range for 255 values."""
    mn, mx = min(val1, val2), max(val1, val2)
    if mn == mx:
        mn, mx = max(0, mn - 20), min(255, mx + 20)
    return mn, mx

def normalize_range_unit(val1, val2):
    """Normalize range for unit values."""
    mn, mx = min(val1, val2), max(val1, val2)
    if abs(mx - mn) < 1e-6:
        mn, mx = max(0.0, val1 - 0.1), min(1.0, val1 + 0.1)
    return mn, mx

def generate_shade_gradient(hex_color, num_steps=16):
    """Generate a linear grayscale gradient with num_steps levels for a given shade color."""
    base_color = hex_to_rgb(hex_color)
    intensity = base_color[0]  # For a gray tone, R == G == B
    dark_val, bright_val = normalize_range_255(intensity, intensity)
    intensities = np.round(np.linspace(dark_val, bright_val, num_steps)).astype(int)
    return [(i, i, i) for i in intensities]

def generate_color_gradient(hex_color, num_steps=16):
    """Generate a linear brightness gradient for a given color."""
    base_color = hex_to_rgb(hex_color)
    h, s, v = rgb_to_hsv(base_color)
    v_dark, v_bright = normalize_range_unit(max(0.0, v - 0.4), min(1.0, v + 0.2))
    steps = np.linspace(0, 1, num_steps)
    new_vs = v_dark + steps * (v_bright - v_dark)
    return [hsv_to_rgb((h, s, new_v)) for new_v in new_vs]

def rgb_to_lab(rgb):
    """Convert RGB values to CIELAB color space."""
    rgb = rgb.astype(np.float32) / 255.0
    mask = rgb > 0.04045
    rgb_linear = np.where(mask, ((rgb + 0.055) / 1.055) ** 2.4, rgb / 12.92)
    xyz = np.dot(rgb_linear, M_SRGB.T)
    xyz /= WHITE_POINT
    f_xyz = np.where(xyz > EPSILON, np.cbrt(xyz), (KAPPA * xyz + 16) / 116)
    L = 116 * f_xyz[..., 1] - 16
    a = 500 * (f_xyz[..., 0] - f_xyz[..., 1])
    b = 200 * (f_xyz[..., 1] - f_xyz[..., 2])
    return np.stack([L, a, b], axis=-1)

def recolor_image(input_path, output_path):
    """Recolor an image using an expanded palette."""
    image = Image.open(input_path).convert("RGB")
    pixels = np.array(image)
    height, width = pixels.shape[:2]
    
    if mode == 'light':
        pixels = 255 - pixels

    shades_palette = parse_shades_palette(BASE16_PALETTE)
    colors_palette = parse_colors_palette(BASE16_PALETTE)

    candidate_colors = np.array(
        [clr for shade in shades_palette for clr in generate_shade_gradient(shade, num_steps=16)] +
        [clr for color in colors_palette for clr in generate_color_gradient(color, num_steps=16)]
    )
    
    candidate_lab = rgb_to_lab(candidate_colors)
    candidate_lab_sq = np.einsum('ij,ij->i', candidate_lab, candidate_lab)
    
    pixels_flat = pixels.reshape(-1, 3)
    num_pixels = pixels_flat.shape[0]
    recolored_pixels_flat = np.empty_like(pixels_flat)
    
    batch_size = 10000  # Adjust batch size as needed.
    for i in tqdm(range(0, num_pixels, batch_size), desc="Processing Pixels"):
        batch = pixels_flat[i:i+batch_size]
        batch_lab = rgb_to_lab(batch)
        batch_lab_sq = np.einsum('ij,ij->i', batch_lab, batch_lab)
        dot_prod = np.dot(batch_lab, candidate_lab.T)
        distances = batch_lab_sq[:, None] + candidate_lab_sq[None, :] - 2 * dot_prod
        indices = np.argmin(distances, axis=1)
        recolored_pixels_flat[i:i+batch_size] = candidate_colors[indices]
    
    recolored_pixels = recolored_pixels_flat.reshape(height, width, 3)
    if os.path.exists(output_path):
        os.remove(output_path)
    Image.fromarray(recolored_pixels.astype("uint8"), "RGB").save(output_path)

if __name__ == "__main__":
    recolor_image(input_path, output_path)
    print("Image recolored using input palette successfully.")