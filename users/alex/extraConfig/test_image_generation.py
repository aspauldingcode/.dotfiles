# create a test image 1440 by 900 pixels
# we have 16 colors to work with. 8 are colors. 8 are shades of gray, from black to white

from PIL import Image
import colorsys

def hex_to_rgb(hex_color):
    """Convert a hex color string to an (R, G, B) tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hsv(rgb):
    """Convert RGB tuple to HSV tuple."""
    return colorsys.rgb_to_hsv(rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0)

def hsv_to_rgb(hsv):
    """Convert HSV tuple to RGB tuple."""
    rgb = colorsys.hsv_to_rgb(hsv[0], hsv[1], hsv[2])
    return tuple(int(x * 255) for x in rgb)

def normalize_range_255(val1, val2):
    """
    Given two intensity values in 0-255 range, return a (min, max) tuple.
    If both are the same, artificially extend the range to ensure visible 16-step variation.
    """
    mn = min(val1, val2)
    mx = max(val1, val2)
    if mn == mx:
        mn = max(0, mn - 20)
        mx = min(255, mx + 20)
    return mn, mx

def normalize_range_unit(val1, val2):
    """
    Given two values in [0, 1], return a (min, max) tuple.
    If the difference is negligible, adjust the range slightly.
    """
    mn = min(val1, val2)
    mx = max(val1, val2)
    if abs(mx - mn) < 1e-6:
        mn = max(0.0, val1 - 0.1)
        mx = min(1.0, val1 + 0.1)
    return mn, mx

# Define the base16 color palette as provided
base16_colors = [
    "#181818",  # base00
    "#282828",  # base01
    "#383838",  # base02
    "#585858",  # base03
    "#b8b8b8",  # base04
    "#d8d8d8",  # base05
    "#e8e8e8",  # base06
    "#f8f8f8",  # base07
    "#ff0000",  # base08
    "#ffa500",  # base09
    "#ffff00",  # base0A
    "#008000",  # base0B
    "#00ffff",  # base0C
    "#0000ff",  # base0D
    "#ff00ff",  # base0E
    "#a52a2a",  # base0F
]

# Create a new image of 1440x900 pixels
width, height = 1440, 900
img = Image.new("RGB", (width, height))

# Determine bar parameters
num_bars = len(base16_colors)
bar_width = width // num_bars

# Use 16 equidistant vertical steps.
num_steps = 16
step_height = height / num_steps
boundaries = [int(round(height - s * step_height)) for s in range(num_steps + 1)]
# boundaries[0] is the bottom (≈900) and boundaries[-1] is the top (0)

# For each bar, compute a normalized gradient and fill equidistant horizontal bands.
for i in range(num_bars):
    x0 = i * bar_width
    x1 = x0 + bar_width
    step_colors = []

    if i < 8:
        # Group 1 (base00 - base07): Grayscale bars with a gradient computed from each base color individually.
        base_color = hex_to_rgb(base16_colors[i])
        # Use the base color's intensity for both endpoints, letting normalize_range_255 add a visible range.
        dark_val, bright_val = normalize_range_255(base_color[0], base_color[0])
        for step in range(num_steps):
            t = step / (num_steps - 1)
            intensity = round(dark_val + t * (bright_val - dark_val))
            step_colors.append((intensity, intensity, intensity))
    else:
        # Group 2 (base08 - base0F): Color bars with a linear brightness gradient in HSV space.
        current_color = hex_to_rgb(base16_colors[i])
        h, sat, val = rgb_to_hsv(current_color)
        # Compute the brightness bounds and normalize them.
        v_dark = max(0.0, val - 0.4)
        v_bright = min(1.0, val + 0.2)
        v_dark, v_bright = normalize_range_unit(v_dark, v_bright)
        for step in range(num_steps):
            t = step / (num_steps - 1)
            new_v = v_dark + t * (v_bright - v_dark)
            step_colors.append(hsv_to_rgb((h, sat, new_v)))

    # Fill the bar with equidistant horizontal blocks based on the computed step_colors.
    for step in range(num_steps):
        y_start = boundaries[step + 1]
        y_end = boundaries[step]
        for y in range(y_start, y_end):
            for x in range(x0, x1):
                img.putpixel((x, y), step_colors[step])

img.save("test_image_generation_output.png")
img.show()
