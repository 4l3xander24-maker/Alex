# Genera la hoja de iconos blancos (512x512, celdas de 128) del HUD de celular.
# Uso: python3 assets/make_icons.py assets/hud_icons.png   (necesita Pillow)
import math, sys
from PIL import Image, ImageDraw
S = 4            # supersampling
C = 128 * S      # celda
W = (255, 255, 255, 255)
G = (205, 210, 218, 255)
D = (0, 0, 0, 0)

def cell():
    return Image.new("RGBA", (C, C), D)

def line(d, pts, w, fill=W):
    d.line([(x * S, y * S) for x, y in pts], fill=fill, width=int(w * S), joint="curve")
    for x, y in (pts[0], pts[-1]):
        r = w * S / 2
        d.ellipse([x * S - r, y * S - r, x * S + r, y * S + r], fill=fill)

def bullet():
    im = cell(); d = ImageDraw.Draw(im)
    # Bala vertical (punta arriba) y luego se gira: punta arriba-izquierda
    cx = 64
    # punta ojival
    tip = [(cx, 10)]
    for t in range(0, 21):
        a = t / 20 * math.pi / 2
        tip.append((cx + 13 * math.sin(a) * 0 + 14 * (1 - math.cos(a)) * 0 + 14 * math.sin(a) * 1.0, 10 + 34 * (1 - math.cos(a)) ** 0.5 * 0 + 34 * a / (math.pi / 2)))
    pts = [(cx - 14 * math.sin(t / 20 * math.pi / 2), 10 + 34 * (t / 20)) for t in range(0, 21)]
    pts2 = [(cx + 14 * math.sin(t / 20 * math.pi / 2), 10 + 34 * (t / 20)) for t in range(20, -1, -1)]
    d.polygon([(x * S, y * S) for x, y in pts + [(cx - 14, 44), (cx - 14, 74), (cx - 20, 82), (cx - 20, 108), (cx + 20, 108), (cx + 20, 82), (cx + 14, 74), (cx + 14, 44)] + pts2], fill=W)
    # ranuras (cuello y base)
    for y, h in ((46, 3.2), (82, 3.2), (104, 3.2)):
        d.rectangle([(cx - 22) * S, y * S, (cx + 22) * S, (y + h) * S], fill=D)
    d.rectangle([(cx - 14) * S, 46 * S, (cx + 14) * S, 49 * S], fill=D)
    im = im.rotate(45, resample=Image.BICUBIC, center=(C // 2, C // 2))
    return im

def jump():
    im = cell(); d = ImageDraw.Draw(im)
    # tres barras inclinadas y un pie curvo
    line(d, [(44, 92), (74, 22)], 11)
    line(d, [(62, 96), (92, 30)], 11)
    line(d, [(80, 98), (106, 40)], 11)
    line(d, [(16, 102), (36, 96), (52, 100)], 9)
    return im

def reload_icon():
    im = cell(); d = ImageDraw.Draw(im)
    r = 38
    box = [(64 - r) * S, (64 - r) * S, (64 + r) * S, (64 + r) * S]
    d.arc(box, start=-70, end=240, fill=W, width=10 * S)
    # punta de flecha al final del arco (arriba a la derecha)
    a = math.radians(-70)
    x, y = 64 + r * math.cos(a), 64 + r * math.sin(a)
    tang = a + math.pi / 2
    pts = [(x + 20 * math.cos(tang - 0.0) , y + 20 * math.sin(tang)), (x + 15 * math.cos(a), y + 15 * math.sin(a)), (x - 15 * math.cos(a), y - 15 * math.sin(a))]
    d.polygon([(px * S, py * S) for px, py in [(x - 2, y - 24), (x + 24, y + 2), (x - 12, y + 14)]], fill=W)
    return im

def swap():
    im = cell(); d = ImageDraw.Draw(im)
    line(d, [(18, 44), (100, 44)], 9)
    d.polygon([(x * S, y * S) for x, y in [(112, 44), (90, 26), (90, 62)]], fill=W)
    line(d, [(110, 86), (28, 86)], 9)
    d.polygon([(x * S, y * S) for x, y in [(16, 86), (38, 68), (38, 104)]], fill=W)
    return im

def scope():
    im = cell(); d = ImageDraw.Draw(im)
    r = 34
    d.ellipse([(64 - r) * S, (64 - r) * S, (64 + r) * S, (64 + r) * S], outline=W, width=7 * S)
    for a in range(4):
        x, y = math.cos(a * math.pi / 2), math.sin(a * math.pi / 2)
        line(d, [(64 + x * 20, 64 + y * 20), (64 + x * 58, 64 + y * 58)], 7)
    d.ellipse([60 * S, 60 * S, 68 * S, 68 * S], fill=W)
    return im

def sprint():
    im = cell(); d = ImageDraw.Draw(im)
    for dx in (0, 34):
        line(d, [(30 + dx, 28), (62 + dx, 64), (30 + dx, 100)], 12)
    return im

def dash():
    im = cell(); d = ImageDraw.Draw(im)
    line(d, [(14, 38), (70, 38)], 9)
    line(d, [(30, 64), (100, 64)], 9)
    line(d, [(14, 90), (70, 90)], 9)
    d.polygon([(x * S, y * S) for x, y in [(118, 64), (96, 42), (96, 86)]], fill=W)
    return im

def crouch():
    im = cell(); d = ImageDraw.Draw(im)
    d.ellipse([58 * S, 22 * S, 82 * S, 46 * S], fill=W)
    line(d, [(70, 48), (66, 80)], 16)
    line(d, [(66, 80), (88, 90), (86, 108)], 11)
    line(d, [(66, 80), (50, 104), (70, 108)], 11)
    line(d, [(72, 56), (44, 62), (18, 54)], 8)
    return im

ICONS = [bullet, jump, reload_icon, swap, scope, sprint, dash, crouch]
sheet = Image.new("RGBA", (512 * S, 256 * S), D)
for i, fn in enumerate(ICONS):
    sheet.paste(fn(), ((i % 4) * C, (i // 4) * C))
sheet = sheet.resize((512, 256), Image.LANCZOS)
sheet.save(sys.argv[1])
