"""Genera las texturas pixeladas del mundo en assets/textures/.

Cada textura es de 32x32 píxeles (se agranda x16 sin suavizado para que en
Roblox se vea nítida) y es casi gris: el color lo pone cada pieza o el
terreno, así la textura solo agrega el dibujo pixelado (briznas, piedras,
tablas, ladrillos...). Se repiten sin cortes en los bordes.

El juego las usa como MaterialVariant: reemplazan a los materiales de Roblox
(Grass, Ground, Cobblestone, Slate, WoodPlanks...) en todo el mapa y el terreno.

Uso: python3 tools/make_textures.py
"""
import random
from pathlib import Path

from PIL import Image

SIZE = 32
SCALE = 16
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "textures"


class Canvas:
    def __init__(self, base):
        self.pixels = [[base] * SIZE for _ in range(SIZE)]

    def set(self, x, y, value):
        self.pixels[y % SIZE][x % SIZE] = max(0, min(255, int(value)))

    def get(self, x, y):
        return self.pixels[y % SIZE][x % SIZE]

    def rect(self, x, y, w, h, value):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, value)

    def image(self, tint=(1.0, 1.0, 1.0)):
        image = Image.new("RGB", (SIZE, SIZE))
        for y in range(SIZE):
            for x in range(SIZE):
                v = self.pixels[y][x]
                image.putpixel((x, y), tuple(min(255, int(v * t)) for t in tint))
        return image.resize((SIZE * SCALE, SIZE * SCALE), Image.NEAREST)


def noise(canvas, rng, amount):
    for y in range(SIZE):
        for x in range(SIZE):
            canvas.set(x, y, canvas.get(x, y) + rng.randint(-amount, amount))


def grass(rng):
    """Pasto: tonos parejos con briznas claras y oscuras de 1x2 o 1x3."""
    c = Canvas(206)
    noise(c, rng, 8)
    for _ in range(90):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        tone = rng.choice((240, 250, 170, 160))
        for k in range(rng.randint(2, 3)):
            c.set(x, y - k, tone)
    for _ in range(14):
        c.set(rng.randrange(SIZE), rng.randrange(SIZE), 255)
    return c


def dirt(rng):
    """Tierra: grumos y piedritas."""
    c = Canvas(196)
    noise(c, rng, 14)
    for _ in range(22):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        c.rect(x, y, rng.randint(1, 2), 1, 236)
        c.set(x, y + 1, 150)
    for _ in range(30):
        c.set(rng.randrange(SIZE), rng.randrange(SIZE), 160)
    return c


def mud(rng):
    c = Canvas(176)
    noise(c, rng, 10)
    for _ in range(10):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        c.rect(x, y, rng.randint(2, 5), 1, 214)
    return c


def cobblestone(rng):
    """Adoquines: piedras redondeadas con juntas oscuras."""
    c = Canvas(110)
    for row in range(4):
        offset = (row % 2) * 4
        for col in range(4):
            x, y = col * 8 + offset, row * 8
            tone = rng.randint(196, 236)
            c.rect(x + 1, y + 1, 6, 6, tone)
            c.rect(x + 2, y + 1, 4, 1, tone + 18)
            c.rect(x + 1, y + 6, 6, 1, tone - 34)
            c.set(x + 1, y + 1, 110)
            c.set(x + 6, y + 6, 110)
    noise(c, rng, 5)
    return c


def stone_bricks(rng):
    """Ladrillos de castillo: bloques grandes con borde claro arriba y sombra abajo."""
    c = Canvas(96)
    for row in range(4):
        offset = (row % 2) * 8
        for col in range(2):
            x, y = col * 16 + offset, row * 8
            tone = rng.randint(186, 226)
            c.rect(x + 1, y + 1, 15, 7, tone)
            c.rect(x + 1, y + 1, 15, 1, tone + 22)
            c.rect(x + 1, y + 7, 15, 1, tone - 40)
            for _ in range(5):
                c.set(x + rng.randint(2, 14), y + rng.randint(2, 6), tone - rng.randint(18, 34))
    return c


def planks(rng):
    """Tablas horizontales con vetas y clavos."""
    c = Canvas(200)
    for row in range(4):
        y = row * 8
        tone = rng.randint(188, 226)
        c.rect(0, y, SIZE, 8, tone)
        c.rect(0, y, SIZE, 1, 120)
        for _ in range(4):
            gx = rng.randrange(SIZE)
            c.rect(gx, y + rng.randint(2, 6), rng.randint(3, 7), 1, tone - 26)
        joint = rng.randrange(SIZE)
        c.rect(joint, y, 1, 8, 130)
        c.set(joint + 2, y + 2, 150)
        c.set(joint + 2, y + 5, 150)
    return c


def bark(rng):
    """Corteza o troncos: vetas verticales."""
    c = Canvas(190)
    for x in range(SIZE):
        tone = 190 + rng.randint(-18, 18)
        for y in range(SIZE):
            c.set(x, y, tone + rng.randint(-6, 6))
    for _ in range(8):
        x = rng.randrange(SIZE)
        y = rng.randrange(SIZE)
        c.rect(x, y, 1, rng.randint(4, 10), 130)
    return c


def leaves(rng):
    """Hojas de pino: agujas en diagonal claras y oscuras."""
    c = Canvas(176)
    for _ in range(140):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        tone = rng.choice((226, 236, 140, 130, 200))
        c.set(x, y, tone)
        c.set(x + 1, y + 1, tone)
    return c


def roof(rng):
    """Tejas de madera en hileras escalonadas."""
    c = Canvas(160)
    for row in range(8):
        y = row * 4
        offset = (row % 2) * 3
        for col in range(6):
            x = col * 6 + offset
            tone = rng.randint(180, 220)
            c.rect(x, y, 5, 3, tone)
            c.rect(x, y + 3, 6, 1, 110)
    return c


def plaster(rng):
    c = Canvas(228)
    noise(c, rng, 6)
    for _ in range(6):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        c.rect(x, y, rng.randint(2, 4), rng.randint(1, 2), 196)
    return c


def rock(rng):
    """Roca: manchas grandes de luz y sombra."""
    c = Canvas(184)
    for _ in range(18):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        tone = rng.choice((150, 214, 230, 160))
        c.rect(x, y, rng.randint(3, 7), rng.randint(2, 4), tone)
    noise(c, rng, 6)
    return c


def sand(rng):
    c = Canvas(220)
    noise(c, rng, 10)
    return c


def fabric(rng):
    """Tela: trama fina."""
    c = Canvas(220)
    for y in range(SIZE):
        for x in range(SIZE):
            c.set(x, y, 220 + (12 if (x + y) % 2 else -8) + rng.randint(-4, 4))
    return c


TEXTURES = {
    "Grass": grass,
    "Dirt": dirt,
    "Mud": mud,
    "Cobblestone": cobblestone,
    "StoneBricks": stone_bricks,
    "Planks": planks,
    "Bark": bark,
    "Leaves": leaves,
    "Roof": roof,
    "Plaster": plaster,
    "Rock": rock,
    "Sand": sand,
    "Fabric": fabric,
}

if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for index, (name, build) in enumerate(TEXTURES.items()):
        build(random.Random(100 + index)).image().save(OUT_DIR / f"{name}.png")
    print(f"{len(TEXTURES)} texturas en {OUT_DIR}")
