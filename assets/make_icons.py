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
    # cuatro barras finas y pegadas, inclinadas, con un gancho en cada punta
    for i in range(4):
        x = 40 + i * 11
        line(d, [(x, 26 + i * 4), (x + 30, 88 + i * 4)], 6)
    line(d, [(36, 90), (22, 98), (26, 108), (44, 108), (62, 102)], 6)
    line(d, [(60, 22), (82, 20), (98, 28), (100, 44)], 6)
    return im

def reload_icon():
    im = cell(); d = ImageDraw.Draw(im)
    r = 42
    box = [(64 - r) * S, (64 - r) * S, (64 + r) * S, (64 + r) * S]
    end = 250
    d.arc(box, start=-60, end=end, fill=W, width=7 * S)
    a = math.radians(end)
    px, py = 64 + r * math.cos(a), 64 + r * math.sin(a)
    tx, ty = -math.sin(a), math.cos(a)
    rx, ry = math.cos(a), math.sin(a)
    d.polygon([(qx * S, qy * S) for qx, qy in [(px + 20 * tx, py + 20 * ty), (px + 13 * rx, py + 13 * ry), (px - 13 * rx, py - 13 * ry)]], fill=W)
    d.rounded_rectangle([54 * S, 52 * S, 74 * S, 86 * S], radius=4 * S, fill=W)
    d.pieslice([54 * S, 38 * S, 74 * S, 66 * S], 180, 360, fill=W)
    d.rectangle([54 * S, 78 * S, 74 * S, 81 * S], fill=D)
    return im

def swap():
    im = cell(); d = ImageDraw.Draw(im)
    r = 40
    box = [(64 - r) * S, (64 - r) * S, (64 + r) * S, (64 + r) * S]
    d.arc(box, start=200, end=335, fill=W, width=7 * S)
    d.arc(box, start=20, end=155, fill=W, width=7 * S)
    for ang, sign in ((335, 1), (155, 1)):
        a = math.radians(ang)
        x, y = 64 + r * math.cos(a), 64 + r * math.sin(a)
        t = a + math.pi / 2
        tip = (x + 16 * math.cos(t), y + 16 * math.sin(t))
        b1 = (x + 14 * math.cos(a), y + 14 * math.sin(a))
        b2 = (x - 14 * math.cos(a), y - 14 * math.sin(a))
        d.polygon([(px * S, py * S) for px, py in [tip, b1, b2]], fill=W)
    return im

def scope():
    im = cell(); d = ImageDraw.Draw(im)
    r = 26
    d.ellipse([(64 - r) * S, (64 - r) * S, (64 + r) * S, (64 + r) * S], outline=W, width=5 * S)
    for a in range(4):
        x, y = math.cos(a * math.pi / 2), math.sin(a * math.pi / 2)
        line(d, [(64 + x * 14, 64 + y * 14), (64 + x * 60, 64 + y * 60)], 5)
    d.ellipse([59 * S, 59 * S, 69 * S, 69 * S], fill=W)
    return im

def soldier(running):
    im = cell(); d = ImageDraw.Draw(im)
    d.ellipse([66 * S, 18 * S, 90 * S, 42 * S], fill=W)           # cabeza (con casco)
    d.rectangle([64 * S, 28 * S, 92 * S, 34 * S], fill=W)
    line(d, [(78, 46), (74, 76)], 17)                                # torso
    if running:
        line(d, [(74, 76), (96, 84), (112, 98)], 10)                 # pierna adelante
        line(d, [(74, 76), (54, 96), (36, 108)], 10)                 # pierna atrás
    else:
        line(d, [(74, 76), (92, 90), (90, 108)], 10)                 # rodilla
        line(d, [(74, 76), (54, 104), (74, 110)], 10)
    line(d, [(80, 54), (54, 60), (22, 46)], 7)                       # brazo con fusil
    line(d, [(14, 42), (40, 54)], 5)
    return im

def sprint():
    return soldier(True)

def crouch():
    return soldier(False)

def dash():
    im = cell(); d = ImageDraw.Draw(im)
    line(d, [(14, 38), (70, 38)], 7)
    line(d, [(30, 64), (100, 64)], 7)
    line(d, [(14, 90), (70, 90)], 7)
    d.polygon([(x * S, y * S) for x, y in [(118, 64), (96, 42), (96, 86)]], fill=W)
    return im

ICONS = [bullet, jump, reload_icon, swap, scope, sprint, dash, crouch]
sheet = Image.new("RGBA", (512 * S, 256 * S), D)
for i, fn in enumerate(ICONS):
    sheet.paste(fn(), ((i % 4) * C, (i // 4) * C))
sheet = sheet.resize((512, 256), Image.LANCZOS)
sheet.save(sys.argv[1])
