"""Genera los sprites pixelados de los enemigos en assets/sprites/.

Cada sprite se dibuja con rectángulos sobre una cuadrícula pequeña; luego se
le agrega sombreado y contorno automáticos, y se escala sin suavizado para
que en Roblox se vea nítido.

Uso: python3 tools/make_sprites.py
"""
from pathlib import Path

from PIL import Image

SCALE = 10
OUTLINE = (16, 20, 18)
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"


class Sprite:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.pixels = [[None] * width for _ in range(height)]
        self.glow = set()  # colores que no se sombrean (ojos)

    def rect(self, x, y, w, h, color):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if 0 <= xx < self.width and 0 <= yy < self.height:
                    self.pixels[yy][xx] = color

    def px(self, x, y, color):
        self.rect(x, y, 1, 1, color)

    def clear(self, x, y):
        self.pixels[y][x] = None

    def _filled(self, x, y):
        return 0 <= x < self.width and 0 <= y < self.height and self.pixels[y][x] is not None

    def render(self):
        shaded = [row[:] for row in self.pixels]
        for y in range(self.height):
            for x in range(self.width):
                color = self.pixels[y][x]
                if color is None or color in self.glow:
                    continue
                if not self._filled(x + 1, y):
                    shaded[y][x] = tuple(int(c * 0.72) for c in color)
                elif not self._filled(x, y - 1):
                    shaded[y][x] = tuple(min(255, int(c * 1.18)) for c in color)

        width, height = self.width + 2, self.height + 2
        image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        for y in range(self.height):
            for x in range(self.width):
                if shaded[y][x] is not None:
                    image.putpixel((x + 1, y + 1), shaded[y][x] + (255,))
        for y in range(height):
            for x in range(width):
                if image.getpixel((x, y))[3] == 0:
                    neighbors = ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
                    if any(
                        0 <= nx < width and 0 <= ny < height and image.getpixel((nx, ny))[3] == 255
                        and image.getpixel((nx, ny))[:3] != OUTLINE
                        for nx, ny in neighbors
                    ):
                        image.putpixel((x, y), OUTLINE + (255,))
        return image.resize((width * SCALE, height * SCALE), Image.NEAREST)


def walker():
    skin, shirt, pants = (128, 168, 112), (72, 92, 138), (82, 66, 54)
    blood, eye, mouth = (150, 32, 32), (255, 90, 60), (40, 18, 18)
    s = Sprite(18, 26)
    s.glow.add(eye)
    s.rect(5, 0, 8, 8, skin)
    s.rect(5, 0, 3, 1, (52, 70, 48))
    s.rect(5, 1, 1, 2, (52, 70, 48))
    s.rect(6, 3, 2, 1, eye)
    s.rect(10, 3, 2, 1, eye)
    s.rect(6, 4, 2, 1, (96, 128, 84))
    s.rect(10, 4, 2, 1, (96, 128, 84))
    s.px(9, 5, (96, 128, 84))
    s.rect(7, 6, 4, 1, mouth)
    s.px(7, 6, (225, 220, 190))
    s.px(9, 6, (225, 220, 190))
    s.rect(8, 7, 2, 1, mouth)
    s.px(12, 1, blood)
    s.px(12, 2, blood)
    s.rect(8, 8, 2, 1, skin)
    s.rect(4, 9, 10, 8, shirt)
    for x, y in ((6, 11), (7, 12), (7, 13), (11, 10)):
        s.px(x, y, blood)
    s.rect(9, 14, 2, 2, skin)
    for x in (5, 8, 12):
        s.clear(x, 16)
    s.rect(1, 9, 3, 4, shirt)
    s.rect(0, 13, 3, 3, skin)
    s.px(0, 16, skin)
    s.px(2, 16, skin)
    s.rect(14, 9, 3, 3, shirt)
    s.rect(15, 12, 3, 3, skin)
    s.px(15, 15, skin)
    s.px(17, 15, skin)
    s.rect(5, 17, 3, 7, pants)
    s.rect(10, 17, 3, 7, pants)
    s.px(6, 19, blood)
    s.px(11, 21, skin)
    s.rect(4, 24, 4, 2, (40, 34, 30))
    s.rect(10, 24, 4, 2, (40, 34, 30))
    return s


def runner():
    skin, shirt, pants = (160, 172, 150), (150, 50, 46), (60, 66, 80)
    blood, eye, mouth = (110, 20, 20), (255, 230, 90), (40, 18, 18)
    s = Sprite(16, 24)
    s.glow.add(eye)
    s.rect(5, 2, 7, 7, skin)
    s.rect(5, 2, 7, 1, (60, 40, 30))
    s.px(5, 3, (60, 40, 30))
    s.px(11, 3, (60, 40, 30))
    s.rect(6, 5, 2, 1, eye)
    s.rect(9, 5, 2, 1, eye)
    s.rect(7, 7, 4, 1, mouth)
    s.px(8, 7, (225, 220, 190))
    s.px(10, 7, (225, 220, 190))
    s.rect(4, 9, 8, 7, shirt)
    for x, y in ((6, 10), (9, 12), (10, 12)):
        s.px(x, y, blood)
    s.clear(4, 15)
    s.clear(11, 14)
    s.rect(2, 9, 2, 3, shirt)
    s.rect(1, 12, 2, 4, skin)
    s.rect(12, 9, 2, 2, shirt)
    s.rect(13, 11, 2, 3, skin)
    s.rect(4, 16, 3, 4, pants)
    s.rect(3, 20, 3, 2, pants)
    s.rect(9, 16, 3, 3, pants)
    s.rect(10, 19, 3, 3, pants)
    s.rect(2, 22, 4, 2, (40, 34, 30))
    s.rect(10, 22, 4, 2, (40, 34, 30))
    return s


def brute(skin, top, pants, eye, spikes=None):
    mouth, blood = (40, 18, 18), (130, 28, 28)
    s = Sprite(26, 28)
    s.glow.add(eye)
    s.rect(10, 0, 7, 6, skin)
    s.rect(11, 2, 2, 1, eye)
    s.rect(14, 2, 2, 1, eye)
    s.rect(11, 4, 5, 1, mouth)
    s.px(12, 4, (225, 220, 190))
    s.px(14, 4, (225, 220, 190))
    s.px(16, 1, (60, 40, 40))
    s.rect(6, 6, 15, 3, skin)
    s.rect(4, 9, 19, 11, top)
    belly = tuple(int(c * 0.9) for c in skin)
    s.rect(8, 15, 11, 5, belly)
    s.px(13, 17, tuple(int(c * 0.6) for c in skin))
    for x, y in ((6, 10), (7, 11), (19, 12), (18, 13)):
        s.px(x, y, blood)
    s.rect(0, 7, 5, 9, skin)
    s.rect(0, 16, 5, 4, tuple(int(c * 0.85) for c in skin))
    s.rect(22, 7, 4, 9, skin)
    s.rect(21, 16, 5, 4, tuple(int(c * 0.85) for c in skin))
    s.rect(6, 20, 6, 6, pants)
    s.rect(15, 20, 6, 6, pants)
    s.rect(5, 26, 7, 2, (36, 30, 28))
    s.rect(15, 26, 7, 2, (36, 30, 28))
    if spikes:
        for x, y in ((6, 5), (7, 4), (19, 4), (20, 5), (2, 6), (23, 6)):
            s.px(x, y, spikes)
    return s


SPRITES = {
    "Walker": walker(),
    "Runner": runner(),
    "Brute": brute((150, 160, 90), (190, 180, 150), (70, 60, 80), (255, 90, 60)),
    "Giant": brute((130, 100, 140), (110, 30, 40), (40, 40, 50), (120, 255, 120), spikes=(220, 215, 190)),
}

if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, sprite in SPRITES.items():
        image = sprite.render()
        image.save(OUT_DIR / f"{name}.png")
        print(f"{name}: {image.width}x{image.height} (proporción ancho/alto = {image.width / image.height:.3f})")
