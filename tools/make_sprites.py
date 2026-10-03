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


# Colores del estilo de dibujo animado (como las imágenes de referencia)
WHITE = (246, 246, 240)
PUPIL = (18, 18, 22)
MOUTH = (140, 18, 30)
BLOOD = (120, 22, 26)


def cartoon_face(s, x, y, skin):
    """Ojos blancos enormes (uno más grande), pupilas y boca abierta con dientes."""
    s.glow.update({WHITE, PUPIL})
    s.rect(x, y, 4, 4, WHITE)
    s.rect(x + 1, y + 1, 2, 2, PUPIL)
    s.rect(x + 6, y, 3, 3, WHITE)
    s.px(x + 7, y + 1, PUPIL)
    s.rect(x + 2, y + 4, 6, 2, MOUTH)
    s.px(x + 3, y + 4, WHITE)
    s.px(x + 6, y + 4, WHITE)
    s.px(x - 1, y - 1, tuple(int(c * 0.8) for c in skin))


def walker(skin=(104, 186, 64), shirt=WHITE, pants=(46, 92, 168), top=0):
    """Zombi clásico: cabezón verde, camisa blanca rota y jean azul."""
    s = Sprite(18, 26 + top)
    y = top
    s.rect(3, y, 12, 9, skin)
    cartoon_face(s, 4, y + 2, skin)
    s.rect(7, y + 9, 4, 1, skin)
    s.rect(4, y + 10, 10, 7, shirt)
    # Camisa rota y manchada
    s.rect(5, y + 14, 2, 2, skin)
    s.px(11, y + 12, skin)
    for px, py in ((8, 11), (9, 12), (12, 15)):
        s.px(px, py + y, BLOOD)
    # Brazos estirados hacia adelante
    s.rect(1, y + 10, 3, 2, shirt)
    s.rect(0, y + 12, 3, 4, skin)
    s.px(0, y + 16, skin)
    s.px(2, y + 16, skin)
    s.rect(14, y + 10, 3, 2, shirt)
    s.rect(15, y + 12, 3, 4, skin)
    s.px(15, y + 16, skin)
    s.px(17, y + 16, skin)
    s.rect(4, y + 17, 10, 1, (70, 44, 30))
    s.rect(4, y + 18, 4, 5, pants)
    s.rect(10, y + 18, 4, 5, pants)
    s.px(5, y + 20, skin)
    s.rect(3, y + 23, 5, 3, skin)
    s.rect(10, y + 23, 5, 3, skin)
    return s


def runner():
    """Corredor: flaco, sin camisa, encorvado y con jean oscuro."""
    skin, pants = (70, 160, 70), (70, 74, 120)
    s = Sprite(16, 24)
    s.rect(2, 2, 11, 8, skin)
    cartoon_face(s, 3, 4, skin)
    s.rect(4, 10, 8, 7, tuple(int(c * 0.88) for c in skin))
    for px, py in ((5, 12), (7, 12), (9, 12)):
        s.px(px, py, tuple(int(c * 0.7) for c in skin))
    s.px(10, 14, BLOOD)
    s.rect(1, 10, 3, 2, skin)
    s.rect(0, 12, 2, 4, skin)
    s.rect(12, 10, 3, 2, skin)
    s.rect(14, 12, 2, 4, skin)
    s.rect(4, 17, 3, 4, pants)
    s.rect(3, 21, 3, 1, pants)
    s.rect(9, 17, 3, 3, pants)
    s.rect(10, 20, 3, 2, pants)
    s.rect(2, 22, 4, 2, skin)
    s.rect(10, 22, 4, 2, skin)
    return s


def cone():
    """Zombi con un cono de tránsito naranja con franja blanca."""
    s = walker(skin=(120, 196, 72), pants=(40, 100, 180), top=8)
    orange = (242, 112, 24)
    s.rect(8, 0, 2, 2, orange)
    s.rect(7, 2, 4, 2, orange)
    s.rect(6, 4, 6, 1, WHITE)
    s.rect(6, 5, 6, 2, orange)
    s.rect(3, 7, 12, 1, orange)
    s.glow.add(WHITE)
    return s


def knight():
    """Caballero zombi: yelmo de hierro, ojos rojos que brillan y túnica."""
    skin, tunic, iron, eye = (96, 150, 70), (120, 36, 40), (138, 142, 150), (255, 70, 50)
    s = Sprite(18, 26)
    s.glow.add(eye)
    s.rect(3, 0, 12, 9, skin)
    s.rect(3, 0, 12, 4, iron)
    s.rect(8, 4, 2, 3, iron)
    s.rect(5, 4, 2, 1, eye)
    s.rect(11, 4, 2, 1, eye)
    s.rect(6, 7, 6, 1, MOUTH)
    s.rect(4, 10, 10, 7, tunic)
    s.rect(5, 10, 8, 4, iron)
    s.rect(1, 10, 3, 2, iron)
    s.rect(0, 12, 3, 4, skin)
    s.rect(14, 10, 3, 2, iron)
    s.rect(15, 12, 3, 4, skin)
    s.rect(4, 17, 10, 1, (60, 40, 25))
    s.rect(4, 18, 4, 5, (60, 56, 64))
    s.rect(10, 18, 4, 5, (60, 56, 64))
    s.rect(3, 23, 5, 3, iron)
    s.rect(10, 23, 5, 3, iron)
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


# Los jefes (Gordo, Rey y Dragón) siempre usan el modelo 3D
SPRITES = {
    "Walker": walker(),
    "Runner": runner(),
    "Cone": cone(),
    "Knight": knight(),
    "Brute": brute((130, 176, 70), (214, 206, 180), (86, 66, 52), WHITE),
}

if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, sprite in SPRITES.items():
        image = sprite.render()
        image.save(OUT_DIR / f"{name}.png")
        print(f"{name}: {image.width}x{image.height} (proporción ancho/alto = {image.width / image.height:.3f})")
