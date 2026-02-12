
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
        size = max(width, height)
        # Add some padding (20% padding total = 10% each side)
        padding_pct = 0.2
        new_size = int(size / (1 - padding_pct))
        
        # Or if we want a fixed output size, say 1024x1024
        final_size = 1024
        
        # Calculate scale to fit content within (1 - padding) of final_size
        target_content_size = final_size * (1 - padding_pct)
        scale = target_content_size / max(content_width, content_height)
        
        new_content_width = int(content_width * scale)
        new_content_height = int(content_height * scale)
        
        content = img.crop(bbox)
        content = content.resize((new_content_width, new_content_height), Image.Resampling.LANCZOS)
        
        new_img = Image.new("RGBA", (final_size, final_size), (0, 0, 0, 0))
        
        paste_x = (final_size - new_content_width) // 2
        paste_y = (final_size - new_content_height) // 2
        
        new_img.paste(content, (paste_x, paste_y))
        
        # Save
        new_img.save(output_path)
        print(f"Saved larger centered image to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    center_image("assets/images/logo.png", "assets/images/logo_centered.png")
