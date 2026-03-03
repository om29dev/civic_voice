import os
from PIL import Image, ImageDraw, ImageFont

def create_icon():
    size = (512, 512)
    img = Image.new('RGBA', size, (17, 34, 64, 255)) # Deep blue background AppColors.bgDeep = 0xFF112240
    draw = ImageDraw.Draw(img)
    
    # Draw mic icon representation (rounded rectangle and stand)
    # Mic head
    draw.rounded_rectangle([216, 120, 296, 260], radius=40, outline=(0, 245, 255, 255), width=16)
    # Mic stand curve
    draw.arc([176, 180, 336, 320], start=0, end=180, fill=(0, 245, 255, 255), width=16)
    # Mic stand base
    draw.line([256, 320, 256, 360], fill=(0, 245, 255, 255), width=16)
    draw.line([200, 360, 312, 360], fill=(0, 245, 255, 255), width=16)
    
    # Add text
    try:
        font = ImageFont.truetype("arialbd.ttf", 80)
    except IOError:
        font = ImageFont.load_default()
        
    text = "CVI"
    draw.text((180, 400), text, font=font, fill=(0, 245, 255, 255))
    
    os.makedirs('assets/icon', exist_ok=True)
    img.save('assets/icon/app_icon.png')
    print("Icon generated successfully.")

if __name__ == '__main__':
    try:
        create_icon()
    except Exception as e:
        print(f"Error: {e}")
