#!/usr/bin/env python3
"""App Store screenshot compositor for Heal.

Reproduces the shipped design: vertical purple->near-black gradient, a bold white
headline (1-2 lines) at the top, and the raw simulator screenshot below, inset and
rounded. Geometry was measured off the shipped `designed/01-streak.png` so new
locales match the existing sets exactly.

Lives in the repo on purpose: the previous compositor lived in /tmp and was wiped,
which is why the Aug 31 checkup had to rebuild it from scratch.

Usage:  python3 compose.py <raw.png> <out.png> "Line one" ["Line two"]
"""
import sys
from PIL import Image, ImageDraw, ImageFont

W, H          = 1320, 2868
TOP_RGB       = (88, 60, 150)
BOT_RGB       = (21, 14, 34)
DEVICE_X      = 161          # left edge of the device screenshot
DEVICE_W      = 998
DEVICE_TOP    = 532
CORNER        = 58
LINE1_TOP     = 222          # cap-top of first headline line
LINE_STEP     = 136
FONT_SIZE     = 104
FONT_CANDIDATES = [
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/HelveticaNeue.ttc",
]

def load_font(size):
    for p in FONT_CANDIDATES:
        try:
            f = ImageFont.truetype(p, size)
            try: f.set_variation_by_name("Bold")     # variable SF fonts
            except Exception: pass
            return f
        except Exception:
            continue
    return ImageFont.load_default()

def gradient():
    g = Image.new("RGB", (1, H))
    px = g.load()
    for y in range(H):
        t = y / (H - 1)
        px[0, y] = tuple(round(TOP_RGB[i] + (BOT_RGB[i] - TOP_RGB[i]) * t) for i in range(3))
    return g.resize((W, H))

def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0]-1, img.size[1]-1], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out

def fit_line(draw, text, font_size, max_w):
    """Shrink until the line fits the safe width."""
    size = font_size
    while size > 40:
        f = load_font(size)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 4
    return load_font(size)

def compose(raw_path, out_path, lines):
    canvas = gradient()
    shot = Image.open(raw_path).convert("RGB")
    scale = DEVICE_W / shot.width
    shot = shot.resize((DEVICE_W, round(shot.height * scale)), Image.LANCZOS)
    # crop to the space available below the headline
    avail = H - DEVICE_TOP
    if shot.height > avail:
        shot = shot.crop((0, 0, DEVICE_W, avail))
    canvas.paste(rounded(shot, CORNER), (DEVICE_X, DEVICE_TOP), rounded(shot, CORNER))

    d = ImageDraw.Draw(canvas)
    safe_w = W - 2 * 120
    for i, line in enumerate(lines[:2]):
        f = fit_line(d, line, FONT_SIZE, safe_w)
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, LINE1_TOP + i * LINE_STEP), line, font=f, fill=(255, 255, 255))
    canvas.save(out_path)
    return out_path

if __name__ == "__main__":
    raw, out = sys.argv[1], sys.argv[2]
    compose(raw, out, sys.argv[3:5])
    print("wrote", out)
