from PIL import Image, ImageDraw
import math
import os

SIZE = 192
CENTER = SIZE // 2

def new_image():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

def make_red():
    img = new_image()
    draw = ImageDraw.Draw(img)
    # Outer dark outline
    draw.ellipse([28, 28, 164, 164], fill="#601818")
    # Main body with radial-gradient feel (layered)
    draw.ellipse([32, 32, 160, 160], fill="#802020")
    draw.ellipse([36, 36, 156, 156], fill="#A02820")
    draw.ellipse([40, 40, 152, 152], fill="#C03830")
    draw.ellipse([48, 48, 144, 144], fill="#D04038")
    # Soft top-left glossy highlight
    draw.ellipse([52, 48, 88, 72], fill=(255, 255, 255, 160))
    draw.ellipse([56, 52, 80, 64], fill=(255, 255, 255, 200))
    # Bottom-right depth shade
    draw.ellipse([104, 104, 144, 136], fill="#902018")
    return img

def make_blue():
    img = new_image()
    draw = ImageDraw.Draw(img)
    # Circle body with outline (same structure as red)
    draw.ellipse([28, 28, 164, 164], fill="#102858")
    draw.ellipse([32, 32, 160, 160], fill="#183878")
    draw.ellipse([36, 36, 156, 156], fill="#2050A0")
    draw.ellipse([40, 40, 152, 152], fill="#2868C8")
    draw.ellipse([48, 48, 144, 144], fill="#3070D8")
    # Top-left glossy highlight (same as red, no horizontal bars)
    draw.ellipse([52, 48, 88, 72], fill=(255, 255, 255, 160))
    draw.ellipse([56, 52, 80, 64], fill=(255, 255, 255, 200))
    # Bottom-right darker shade for depth
    draw.ellipse([104, 104, 144, 136], fill="#2050A0")
    return img

def make_green():
    img = new_image()
    draw = ImageDraw.Draw(img)
    r = 28
    # Shadow
    draw.rounded_rectangle([40, 40, 168, 168], radius=r, fill=(0, 0, 0, 90))
    # Outline + body
    draw.rounded_rectangle([32, 32, 160, 160], radius=r, fill="#104010")
    draw.rounded_rectangle([36, 36, 156, 156], radius=r, fill="#186018")
    draw.rounded_rectangle([40, 40, 152, 152], radius=r, fill="#248824")
    draw.rounded_rectangle([44, 44, 148, 148], radius=r, fill="#30A830")
    # Top-left highlight
    draw.rounded_rectangle([48, 48, 96, 80], radius=12, fill=(255, 255, 255, 160))
    draw.rounded_rectangle([52, 52, 88, 72], radius=8, fill=(255, 255, 255, 200))
    # Bottom-right shade
    draw.rounded_rectangle([104, 112, 144, 144], radius=10, fill="#208020")
    return img

def make_yellow():
    img = new_image()
    draw = ImageDraw.Draw(img)
    r = 28
    # Shadow
    draw.rounded_rectangle([40, 40, 168, 168], radius=r, fill=(0, 0, 0, 90))
    # Outline + body
    draw.rounded_rectangle([32, 32, 160, 160], radius=r, fill="#705808")
    draw.rounded_rectangle([36, 36, 156, 156], radius=r, fill="#A08010")
    draw.rounded_rectangle([40, 40, 152, 152], radius=r, fill="#D0A818")
    draw.rounded_rectangle([44, 44, 148, 148], radius=r, fill="#E8C820")
    # Top-left highlight
    draw.rounded_rectangle([48, 48, 96, 80], radius=12, fill=(255, 255, 255, 190))
    draw.rounded_rectangle([52, 52, 88, 72], radius=8, fill=(255, 255, 255, 230))
    # Bottom-right shade
    draw.rounded_rectangle([104, 112, 144, 144], radius=10, fill="#C0A010")
    # Center sparkle
    draw.ellipse([CENTER - 8, CENTER - 8, CENTER + 8, CENTER + 8], fill=(255, 255, 255, 240))
    return img

def hexagon_points(cx, cy, r):
    return [(cx + r * math.cos(math.pi/3*i - math.pi/2),
             cy + r * math.sin(math.pi/3*i - math.pi/2)) for i in range(6)]

def make_purple():
    img = new_image()
    draw = ImageDraw.Draw(img)
    pts = hexagon_points(CENTER, CENTER, 72)
    shadow_pts = [(x + 6, y + 6) for x, y in pts]
    draw.polygon(shadow_pts, fill=(0, 0, 0, 90))
    # Outer outline
    out_pts = hexagon_points(CENTER, CENTER, 68)
    draw.polygon(pts, fill="#501860")
    draw.polygon(out_pts, fill="#8020A0")
    # Facets for 3D effect
    f1 = [out_pts[0], out_pts[1], (CENTER, CENTER)]
    draw.polygon(f1, fill="#C050D0")
    f2 = [out_pts[0], out_pts[5], (CENTER, CENTER)]
    draw.polygon(f2, fill="#9030B0")
    f3 = [out_pts[1], out_pts[2], (CENTER, CENTER)]
    draw.polygon(f3, fill="#B040C0")
    # Bottom shades
    draw.polygon([out_pts[3], out_pts[4], (CENTER, CENTER)], fill="#701870")
    draw.polygon([out_pts[2], out_pts[3], (CENTER, CENTER)], fill="#802080")
    # Top highlight
    draw.ellipse([CENTER - 12, 40, CENTER + 12, 64], fill=(255, 255, 255, 150))
    return img

def make_orange():
    img = new_image()
    draw = ImageDraw.Draw(img)
    pts = hexagon_points(CENTER, CENTER, 72)
    shadow_pts = [(x + 6, y + 6) for x, y in pts]
    draw.polygon(shadow_pts, fill=(0, 0, 0, 90))
    out_pts = hexagon_points(CENTER, CENTER, 68)
    draw.polygon(pts, fill="#703808")
    draw.polygon(out_pts, fill="#B06010")
    # Facets
    draw.polygon([out_pts[0], out_pts[1], (CENTER, CENTER)], fill="#F0A030")
    draw.polygon([out_pts[0], out_pts[5], (CENTER, CENTER)], fill="#D08020")
    draw.polygon([out_pts[1], out_pts[2], (CENTER, CENTER)], fill="#C07018")
    # Bottom shades
    draw.polygon([out_pts[3], out_pts[4], (CENTER, CENTER)], fill="#904810")
    draw.polygon([out_pts[2], out_pts[3], (CENTER, CENTER)], fill="#A05810")
    # Top highlight
    draw.ellipse([CENTER - 12, 40, CENTER + 12, 64], fill=(255, 255, 255, 160))
    return img

def make_magic():
    img = new_image()
    draw = ImageDraw.Draw(img)
    # Outer glow ring
    draw.ellipse([28, 28, 164, 164], fill="#186060")
    draw.ellipse([32, 32, 160, 160], fill="#207070")
    draw.ellipse([36, 36, 156, 156], fill="#289090")
    draw.ellipse([40, 40, 152, 152], fill="#30B0B0")
    draw.ellipse([44, 44, 148, 148], fill="#38C0C0")
    # Inner rainbow rings (more bands for HD)
    rainbow = [
        "#FF5555", "#FF7733", "#FFAA00", "#FFDD33",
        "#55FF55", "#55AAFF", "#AA55FF", "#FF55FF"
    ]
    for i, col in enumerate(rainbow):
        off = 20 + i * 4
        draw.ellipse([CENTER - off, CENTER - off, CENTER + off, CENTER + off], outline=col, width=4)
    # Top-left highlight
    draw.ellipse([52, 48, 88, 72], fill=(255, 255, 255, 150))
    draw.ellipse([56, 52, 80, 64], fill=(255, 255, 255, 190))
    # Star cross sparkle
    draw.line([(CENTER, CENTER - 24), (CENTER, CENTER + 24)], fill=(255, 255, 255, 210), width=6)
    draw.line([(CENTER - 24, CENTER), (CENTER + 24, CENTER)], fill=(255, 255, 255, 210), width=6)
    draw.ellipse([CENTER - 8, CENTER - 8, CENTER + 8, CENTER + 8], fill=(255, 255, 255, 255))
    return img

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "jewels")
    os.makedirs(out_dir, exist_ok=True)
    makers = {
        "jewel_red.png": make_red,
        "jewel_blue.png": make_blue,
        "jewel_green.png": make_green,
        "jewel_yellow.png": make_yellow,
        "jewel_purple.png": make_purple,
        "jewel_orange.png": make_orange,
        "jewel_magic.png": make_magic,
    }
    for name, fn in makers.items():
        path = os.path.join(out_dir, name)
        img = fn()
        img.save(path)
        print(f"Saved {path}")
