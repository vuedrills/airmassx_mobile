
from PIL import Image
import os

def center_image(input_path, output_path):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Get bounding box of non-transparent pixels
        bbox = img.getbbox()
        if not bbox:
            print("Image is completely transparent!")
            return

        content_width = bbox[2] - bbox[0]
        content_height = bbox[3] - bbox[1]
        
        print(f"Original size: {width}x{height}")
        print(f"Content bbox: {bbox}")
        print(f"Content size: {content_width}x{content_height}")

        # Create a new square image (use max dimension)
        new_size = max(width, height)
        # Or maybe keep 1024x1024 if standard icon size
        new_size = max(new_size, 1024)
        
        new_img = Image.new("RGBA", (new_size, new_size), (0, 0, 0, 0))
        
        # Calculate center position
        paste_x = (new_size - content_width) // 2
        paste_y = (new_size - content_height) // 2
        
        # Crop content
        content = img.crop(bbox)
        
        # Paste centered
        new_img.paste(content, (paste_x, paste_y))
        
        # Save
        new_img.save(output_path)
        print(f"Saved centered image to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    center_image("assets/images/logo.png", "assets/images/logo_centered.png")
