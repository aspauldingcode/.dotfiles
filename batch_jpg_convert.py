import os
from PIL import Image
from tqdm import tqdm
import argparse
import pillow_heif
from moviepy.editor import VideoFileClip
import mimetypes
import shutil
import subprocess

# Register HEIF opener with PIL
pillow_heif.register_heif_opener()

def is_video(file_path):
    mime_type, _ = mimetypes.guess_type(file_path)
         if mime_type and mime_type.startswith('video'):
        return True
    # Check common video extensions as fallback
    video_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm'}
    return os.path.splitext(file_path)[1].lower() in video_extensions

def is_image(file_path):
    try:
        Image.open(file_path)
        return True
    except:
        return False

    try 

def convert_video_to_mp4(input_path, output_path):
    try:
        # If input is already MP4, just copy the file
        if input_path.lower().endswith('.mp4'):
            shutil.copy2(input_path, output_path)
            return True
            
        # For MOV files, use FFmpeg directly
        if input_path.lower().endswith('.mov'):
            try:
                command = [
                    'ffmpeg',
                    '-i', input_path,
                    '-c:v', 'libx264',     # Video codec
                    '-preset', 'medium',    # Encoding speed preset
                    '-c:a', 'aac',         # Audio codec
                    '-strict', 'experimental',
                    '-y',                   # Overwrite output file if exists
                    output_path
                ]
                
                # Run FFmpeg with output redirected to null
                with open(os.devnull, 'wb') as devnull:
                    subprocess.check_call(command, stdout=devnull, stderr=subprocess.STDOUT)
                
                # Verify the output file exists and has size
                if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
                    raise Exception("Output file is empty or not created")
                    
                return True
                
            except subprocess.CalledProcessError as e:
                raise Exception(f"FFmpeg failed with error code {e.returncode}")
                
        # For other video formats, use moviepy
        video = VideoFileClip(input_path)
        try:
            # Get video properties with fallbacks
            fps = video.fps if video.fps else 30.0
            
            # Check if video has valid audio
            has_audio = False
            try:
                has_audio = video.audio is not None and hasattr(video.audio, 'fps') and video.audio.fps is not None
            except:
                pass
            
            video.write_videofile(
                output_path,
                codec='libx264',
                audio_codec='aac' if has_audio else None,
                fps=fps,
                preset='medium',
                audio=has_audio,
                verbose=False,
                logger=None
            )
            
            # Verify the output file exists and has size
            if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
                raise Exception("Output file is empty or not created")
                
            return True
            
        finally:
            video.close()
                
    except Exception as e:
        print(f"Failed to convert video {os.path.basename(input_path)}: {str(e)}")
        # Clean up failed conversion
        if os.path.exists(output_path):
            try:
                os.remove(output_path)
            except:
                pass
        return False

def batch_convert(input_folder, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # List all files in the input folder
    files = [f for f in os.listdir(input_folder) if os.path.isfile(os.path.join(input_folder, f))]
    
    # Process each file
    for file in tqdm(files, desc="Converting files", unit="file"):
        file_path = os.path.join(input_folder, file)
        file_name = os.path.splitext(file)[0]
        
        # Skip hidden files
        if file.startswith('.'):
            continue
            
        # Check if it's a video
        if is_video(file_path):
            output_path = os.path.join(output_folder, file_name + '.mp4')
            if not os.path.exists(output_path):  # Skip if already converted
                convert_video_to_mp4(file_path, output_path)
            continue
            
        # Check if it's an image
        if is_image(file_path):
            try:
                with Image.open(file_path) as img:
                    # Convert image to RGB (if not already in that mode)
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    # Save the image as JPG
                    output_path = os.path.join(output_folder, file_name + '.jpg')
                    if not os.path.exists(output_path):  # Skip if already converted
                        img.save(output_path, 'JPEG', quality=95)
            except Exception as e:
                print(f"Failed to convert image {file}: {str(e)}")
        else:
            print(f"Skipping {file}: not a supported image or video file")

def main():
    parser = argparse.ArgumentParser(description='Convert media files: images to JPG and videos to MP4')
    parser.add_argument('input_folder', help='Path to the input folder containing media files')
    parser.add_argument('output_folder', help='Path to the output folder for converted files')
    
    args = parser.parse_args()
    batch_convert(args.input_folder, args.output_folder)

if __name__ == '__main__':
    main()

