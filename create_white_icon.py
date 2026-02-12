
from PIL import Image, ImageDraw, ImageFont
import os

def create_white_bg_icon(input_path, output_path, tagline="Airmass Xpress"):
    try:
        # 1. Open original logo
        img = Image.open(input_path).convert("RGBA")
        
        # Get bounding box of content
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
            
        width, height = img.size
        
        # 2. Create detailed White Square Background (1024x1024)
        final_size = 1024
        new_img = Image.new("RGBA", (final_size, final_size), (255, 255, 255, 255))
        draw = ImageDraw.Draw(new_img)
        
        # 3. Resize Logo to fit comfortably (e.g. 50% height)
        target_logo_h = int(final_size * 0.5)
        aspect = width / height
        target_logo_w = int(target_logo_h * aspect)
        
        logo_resized = img.resize((target_logo_w, target_logo_h), Image.Resampling.LANCZOS)
        
        # 4. Paste Logo Centered horizontally, slightly up vertically
        paste_x = (final_size - target_logo_w) // 2
        paste_y = (final_size - target_logo_h) // 2 - 50 # slight offset up to make room for text
        
        new_img.paste(logo_resized, (paste_x, paste_y), logo_resized)
        
        # 5. Add Tagline (optional, as small text doesn't show well on icons, but per user request)
        # Using default font since we might not have a ttf handy, drawing generic path text 
        # Actually, let's skip text for the *Icon* if it's too small, but user asked for "statement below".
        # We'll try to load a default font or just draw it.
        
        try:
            # Try to load a font, or fallback to default
            font_size = 60
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
            except:
                font = ImageFont.load_default()
                
            # Text color: Navy (from theme: #1A2B4A -> (26, 43, 74))
            text_color = (26, 43, 74, 255)
            
            # Position text below logo
            text_bbox = draw.textbbox((0, 0), tagline, font=font)
            text_w = text_bbox[2] - text_bbox[0]
            text_h = text_bbox[3] - text_bbox[1]
            
            text_x = (final_size - text_w) // 2
            text_y = paste_y + target_logo_h + 40 # 40px padding below logo
            
            draw.text((text_x, text_y), tagline, font=font, fill=text_color)
            
        except Exception as e:
            print(f"Could not add text: {e}")

        # 6. Save
        new_img.save(output_path)
        print(f"Saved white bg icon to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_white_bg_icon("assets/images/logo.png", "assets/images/logo_white_bg.png")
