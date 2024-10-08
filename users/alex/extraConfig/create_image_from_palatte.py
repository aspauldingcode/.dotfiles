import argparse
from PIL import Image
from diffusers import StableDiffusionPipeline
import torch

def hex_to_color_names(hex_colors):
    # Placeholder function to convert hex to color names
    # In practice, you might use a library or a predefined mapping
    return ["dark blue", "purple", "light blue", "gray", "white", "orange", "yellow", "green", "sky blue", "lavender", "pink"]

def generate_image_from_palette(color_names):
    # Use a valid model ID
    model_id = "stabilityai/stable-diffusion-2-1"
    pipe = StableDiffusionPipeline.from_pretrained(model_id)

    # Use MPS if available, otherwise fallback to CPU
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    pipe = pipe.to(device)

    prompt = f"Generate a wallpaper using the following colors: {', '.join(color_names)}"
    image = pipe(prompt).images[0]
    return image

def main():
    parser = argparse.ArgumentParser(description='Generate an AI image from a color palette.')
    parser.add_argument('colors', metavar='C', type=str, nargs='+',
                        help='a list of base16 color codes separated by commas')
    
    args = parser.parse_args()
    # Convert hex colors to descriptive color names
    color_names = hex_to_color_names(args.colors[0].split(','))
    
    # Generate and show the image
    image = generate_image_from_palette(color_names)
    image.show()

if __name__ == "__main__":
    main()
