from PIL import Image
import numpy as np
import sys

def parse_palette(palette_str):
    """Parse a comma-separated string of hex colors into a list."""
    return palette_str.split(',')

if len(sys.argv) < 5:
    print("Usage: python recolor_base16_inputs_efficient.py <input_image_path> <output_image_path> <mode> <palette>")
    print("Example palette: 'dark,#32302f,#3c3836,#504945,#665c54,#bdae93,#d5c4a1,#ebdbb2,#fbf1c7,#fb4934,#fe8019,#fabd2f,#b8bb26,#8ec07c,#83a598,#d3869b,#d65d0e'")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]
mode = sys.argv[3].lower()
palette_str = sys.argv[4]

# Define a Base16 color palette using hexadecimal values from CLI
BASE16_PALETTE = parse_palette(palette_str)

def hex_to_rgb(hex_color):
    """Convert a hex color to an RGB numpy array."""
    hex_color = hex_color.lstrip('#')
    return np.array([int(hex_color[i:i+2], 16) for i in (0, 2, 4)])

def rgb_to_hsv(rgb):
    """Convert RGB to HSV."""
    rgb = rgb / 255.0
    maxc = rgb.max(axis=1)
    minc = rgb.min(axis=1)
    v = maxc
    delta = maxc - minc
    s = np.zeros_like(maxc)
    mask = maxc != 0
    s[mask] = delta[mask] / maxc[mask]
    
    h = np.zeros_like(maxc)
    mask_delta = delta != 0
    idx = (rgb.argmax(axis=1) == 0) & mask_delta
    h[idx] = ((rgb[idx, 1] - rgb[idx, 2]) / delta[idx]) % 6
    idx = (rgb.argmax(axis=1) == 1) & mask_delta
    h[idx] = ((rgb[idx, 2] - rgb[idx, 0]) / delta[idx]) + 2
    idx = (rgb.argmax(axis=1) == 2) & mask_delta
    h[idx] = ((rgb[idx, 0] - rgb[idx, 1]) / delta[idx]) + 4
    h /= 6
    h = np.mod(h, 1.0)
    hsv = np.stack([h, s, v], axis=1)
    return hsv

def hsv_to_rgb(hsv):
    """Convert HSV to RGB."""
    h, s, v = hsv[:, 0], hsv[:, 1], hsv[:, 2]
    i = np.floor(h * 6).astype(int)
    f = (h * 6) - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    
    i = i % 6
    conditions = [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5]
    r = np.select(conditions, [v, q, p, p, t, v])
    g = np.select(conditions, [t, v, v, q, p, p])
    b = np.select(conditions, [p, p, t, v, v, q])
    
    rgb = np.stack([r, g, b], axis=1)
    rgb = np.clip(rgb * 255, 0, 255).astype(np.uint8)
    return rgb

def generate_shades(palette_rgb, base_indices, num_shades=10, brightness_factor=0.9):
    """
    Generate shades for darker base colors by reducing their brightness.

    Parameters:
    - palette_rgb: numpy array of shape (num_colors, 3)
    - base_indices: list or array of indices representing base00 to base07
    - num_shades: number of shading steps
    - brightness_factor: factor by which to reduce brightness at each step

    Returns:
    - extended_palette: numpy array with original base colors, their shades, and accent colors
    """
    hsv = rgb_to_hsv(palette_rgb[base_indices])
    brightness = hsv[:, 2]
    dark_colors = hsv[:, 2] < 0.3  # Threshold for darkness
    shades = []
    
    for idx, is_dark in enumerate(dark_colors):
        if is_dark:
            for step in range(1, num_shades + 1):
                factor = brightness_factor ** step
                new_v = hsv[idx, 2] * factor
                new_v = np.clip(new_v, 0, 1)
                shaded_color = np.array([hsv[idx, 0], hsv[idx, 1], new_v])
                rgb_shaded = hsv_to_rgb(shaded_color.reshape(1, -1))[0]
                shades.append(rgb_shaded)
    
    if shades:
        shades = np.array(shades)
        # Combine base shades with original palette
        extended_palette = np.vstack([palette_rgb, shades])
    else:
        extended_palette = palette_rgb
    return extended_palette

def recolor_image(input_path, output_path):
    """Recolor an image using the Base16 color palette with accurate matching for base08 to base0f."""
    image = Image.open(input_path).convert('RGB')
    pixels = np.array(image)
    height, width = pixels.shape[:2]

    # Convert palette to RGB array
    palette_rgb = np.array([hex_to_rgb(color) for color in BASE16_PALETTE])
    num_base = 8  # base00 to base07
    num_accent = 8  # base08 to base0f

    base_palette = palette_rgb[:num_base]
    accent_palette = palette_rgb[num_base:num_base + num_accent]

    # Generate shades only for base palette
    palette_with_shades = generate_shades(palette_rgb, base_indices=np.arange(num_base))
    
    # Reconstruct the full palette: shades + accent colors
    num_shades = palette_with_shades.shape[0] - num_base
    full_palette = np.vstack([palette_with_shades, accent_palette])

    # Flatten the image array to shape (num_pixels, 3)
    pixels_flat = pixels.reshape(-1, 3)
    num_pixels = pixels_flat.shape[0]

    # Compute distances between each pixel and accent palette colors first
    distances_accent = np.linalg.norm(pixels_flat[:, np.newaxis, :] - accent_palette[np.newaxis, :, :], axis=2)
    closest_accent = np.argmin(distances_accent, axis=1)
    min_dist_accent = np.min(distances_accent, axis=1)

    # Define a threshold to accept accent color mapping
    threshold = 30  # Adjust based on desired strictness

    # Initialize indices with accent mappings where distance is below threshold
    indices = np.where(min_dist_accent < threshold, closest_accent + palette_with_shades.shape[0], -1)

    # For remaining pixels, map to the rest of the palette (base + shades)
    mask = indices == -1
    remaining_pixels = pixels_flat[mask]
    if remaining_pixels.size > 0:
        distances_base = np.linalg.norm(remaining_pixels[:, np.newaxis, :] - palette_with_shades[np.newaxis, :, :], axis=2)
        closest_base = np.argmin(distances_base, axis=1)
        indices[mask] = closest_base

    # Map pixels to palette colors
    recolored_pixels_flat = full_palette[indices]

    # Invert colors if mode is light
    if mode == 'light':
        recolored_pixels_flat = 255 - recolored_pixels_flat

    # Ensure every color in the palette is used at least once
    used_colors = np.unique(indices)
    missing_colors = np.setdiff1d(np.arange(full_palette.shape[0]), used_colors)
    for i, color_idx in enumerate(missing_colors):
        if i < num_pixels:
            # Assign the missing color to a random pixel
            recolored_pixels_flat[i] = full_palette[color_idx]

    # Reshape back to the original image shape
    recolored_pixels = recolored_pixels_flat.reshape(height, width, 3)

    recolored_image = Image.fromarray(recolored_pixels.astype('uint8'), 'RGB')
    recolored_image.save(output_path)

if __name__ == "__main__":
    recolor_image(input_path, output_path)
    print("Image recolored using Base16 palette successfully.")
