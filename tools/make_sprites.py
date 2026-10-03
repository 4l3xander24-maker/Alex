"""Genera los sprites pixelados de los enemigos, jefes y NPC en assets/sprites/.

Cada enemigo tiene dos cuadros de caminar (Nombre.png y Nombre_2.png): en el
segundo levanta un pie y los brazos se mueven. El juego los alterna al caminar.

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

    def copy(self):
        other = Sprite(self.width, self.height)
        other.pixels = [row[:] for row in self.pixels]
        other.glow = set(self.glow)
        return other

    def walk_frame(self, leg_row, arm_rows=None):
        """Segundo cuadro de caminar: el pie izquierdo sube un píxel y el
        brazo derecho baja uno."""
        other = self.copy()
        half = self.width // 2
        for y in range(leg_row, self.height):
            for x in range(half):
                other.pixels[y - 1][x] = self.pixels[y][x] if y - 1 >= leg_row - 1 else other.pixels[y - 1][x]
        for x in range(half):
            other.pixels[self.height - 1][x] = None
        if arm_rows:
            top, bottom = arm_rows
            for y in range(bottom, top - 1, -1):
                for x in range(half, self.width):
                    if y + 1 < self.height:
                        other.pixels[y + 1][x] = self.pixels[y][x]
            for x in range(half, self.width):
                if self.pixels[top][x] is not None and other.pixels[top][x] == self.pixels[top][x]:
                    pass
        return other

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


def fatso():
    """Jefe Zombi Gordo: una mole verde con camiseta manchada y cabeza chiquita."""
    skin, shirt, pants = (150, 186, 80), (210, 200, 170), (80, 60, 90)
    dark = tuple(int(c * 0.75) for c in skin)
    s = Sprite(36, 40)
    s.rect(13, 0, 10, 8, skin)
    cartoon_face(s, 14, 2, skin)
    s.rect(6, 8, 24, 4, skin)
    s.rect(3, 12, 30, 16, shirt)
    s.rect(9, 18, 18, 10, skin)
    s.rect(17, 22, 2, 2, dark)
    for x, y in ((6, 13), (7, 14), (27, 15), (26, 16), (12, 14)):
        s.px(x, y, BLOOD)
    # Puntadas en la panza
    for x in range(11, 25, 3):
        s.px(x, 26, (60, 40, 40))
    s.rect(0, 10, 4, 14, skin)
    s.rect(32, 10, 4, 14, skin)
    s.rect(0, 24, 4, 3, dark)
    s.rect(32, 24, 4, 3, dark)
    s.rect(6, 28, 24, 2, (60, 40, 30))
    s.rect(7, 30, 9, 7, pants)
    s.rect(20, 30, 9, 7, pants)
    s.rect(6, 37, 10, 3, skin)
    s.rect(20, 37, 10, 3, skin)
    return s


def king():
    """Jefe Rey Zombi: corona, túnica morada con borde de oro y capa roja."""
    skin, robe, gold, cape = (110, 160, 96), (96, 40, 120), (240, 190, 50), (150, 22, 34)
    ruby = (220, 30, 50)
    s = Sprite(28, 46)
    s.glow.update({gold, ruby})
    # Capa detrás (se ve a los lados)
    s.rect(2, 13, 24, 30, cape)
    # Corona
    for x in (8, 12, 16, 19):
        s.rect(x, 0, 2, 3, gold)
    s.rect(7, 3, 14, 3, gold)
    s.px(13, 4, ruby)
    s.rect(7, 6, 14, 10, skin)
    cartoon_face(s, 9, 8, skin)
    # Cuello de armiño
    s.rect(5, 16, 18, 3, WHITE)
    for x in (7, 11, 15, 19):
        s.px(x, 17, PUPIL)
    s.rect(6, 19, 16, 18, robe)
    s.rect(13, 19, 2, 18, gold)
    s.rect(6, 30, 16, 1, gold)
    s.rect(2, 19, 4, 11, robe)
    s.rect(22, 19, 4, 11, robe)
    s.rect(2, 30, 4, 3, skin)
    s.rect(22, 30, 4, 3, skin)
    # Cetro
    s.rect(26, 14, 1, 20, gold)
    s.rect(25, 12, 3, 3, ruby)
    s.rect(8, 37, 5, 6, (44, 36, 54))
    s.rect(15, 37, 5, 6, (44, 36, 54))
    s.rect(7, 43, 6, 3, skin)
    s.rect(15, 43, 6, 3, skin)
    return s


def dragon():
    """Jefe Dragón Zombi de frente: alas abiertas con huesos y membrana rota."""
    skin, bone, wing, eye = (92, 120, 84), (220, 212, 186), (58, 62, 56), (120, 255, 120)
    s = Sprite(60, 40)
    s.glow.add(eye)
    # Alas: hueso arriba y membrana con agujeros
    for side in (-1, 1):
        for i in range(24):
            x = 30 + side * (5 + i)
            top = 6 + i // 3
            s.rect(x, top, 1, 2, bone)
            s.rect(x, top + 2, 1, 14 - i // 2, wing)
        for i in (8, 16, 22):
            x = 30 + side * (5 + i)
            s.rect(x, 8 + i // 3, 1, 16 - i // 2, bone)
        for hx, hy in ((14, 18), (19, 15)):
            s.px(30 + side * hx, hy, None) if False else s.clear(30 + side * hx, hy)
    # Cuerpo, costillas y cuello
    s.rect(23, 14, 14, 16, skin)
    for y in (17, 20, 23):
        s.rect(24, y, 12, 1, bone)
    s.rect(26, 6, 8, 9, skin)
    # Cabeza con cuernos y ojos verdes
    s.rect(24, 0, 12, 8, skin)
    s.rect(22, 0, 2, 3, bone)
    s.rect(36, 0, 2, 3, bone)
    s.rect(26, 3, 2, 2, eye)
    s.rect(32, 3, 2, 2, eye)
    s.rect(27, 6, 6, 2, MOUTH)
    s.px(28, 6, WHITE)
    s.px(31, 6, WHITE)
    # Patas y cola
    s.rect(23, 30, 4, 6, skin)
    s.rect(33, 30, 4, 6, skin)
    s.rect(22, 36, 6, 2, bone)
    s.rect(32, 36, 6, 2, bone)
    s.rect(29, 30, 2, 8, skin)
    s.rect(28, 38, 4, 2, bone)
    return s


def npc(skin, shirt, pants, hat=None, beard=None, extra=None):
    """NPC del campamento (sin ojos de zombi: ojos chicos y boca cerrada)."""
    s = Sprite(18, 26)
    s.rect(4, 2, 10, 8, skin)
    s.rect(6, 5, 2, 2, PUPIL)
    s.rect(10, 5, 2, 2, PUPIL)
    s.rect(7, 8, 4, 1, tuple(int(c * 0.6) for c in skin))
    if beard:
        s.rect(5, 7, 8, 4, beard)
        s.rect(7, 8, 4, 1, tuple(int(c * 0.7) for c in beard))
    if hat:
        hat(s)
    s.rect(4, 11, 10, 8, shirt)
    s.rect(1, 11, 3, 6, shirt)
    s.rect(14, 11, 3, 6, shirt)
    s.rect(1, 17, 3, 2, skin)
    s.rect(14, 17, 3, 2, skin)
    s.rect(4, 19, 4, 5, pants)
    s.rect(10, 19, 4, 5, pants)
    s.rect(3, 24, 5, 2, (50, 36, 28))
    s.rect(10, 24, 5, 2, (50, 36, 28))
    if extra:
        extra(s)
    return s


def armero():
    def hat(s):
        s.rect(3, 0, 12, 3, (150, 50, 46))

    def apron(s):
        s.rect(5, 12, 8, 10, (90, 64, 40))
        s.rect(15, 8, 2, 9, (120, 90, 60))
        s.rect(14, 7, 4, 2, (130, 134, 142))

    return npc((200, 150, 110), (90, 70, 50), (50, 50, 60), hat, (110, 70, 40), apron)


def bruja():
    def hat(s):
        black = (30, 22, 40)
        s.rect(2, 2, 14, 2, black)
        s.rect(5, 0, 8, 2, black)
        s.rect(7, -1 + 1, 4, 1, black)

    def potion(s):
        s.rect(15, 15, 3, 4, (110, 255, 120))
        s.glow.add((110, 255, 120))
        s.rect(4, 19, 10, 5, (60, 34, 90))

    return npc((150, 190, 140), (70, 40, 100), (50, 30, 70), hat, None, potion)


def veterano():
    def hat(s):
        s.rect(3, 0, 12, 4, (150, 155, 165))
        s.rect(8, 4, 2, 3, (150, 155, 165))

    def cloak(s):
        s.rect(5, 11, 8, 5, (150, 155, 165))
        s.rect(0, 11, 1, 10, (150, 40, 40))
        s.rect(17, 11, 1, 10, (150, 40, 40))

    return npc((210, 165, 130), (110, 115, 125), (60, 50, 40), hat, (235, 235, 235), cloak)


def intendente():
    def hat(s):
        s.rect(3, 0, 12, 3, (60, 70, 40))
        s.rect(2, 2, 15, 1, (60, 70, 40))

    def satchel(s):
        s.rect(6, 8, 6, 1, (40, 30, 20))
        s.rect(12, 14, 4, 4, (110, 80, 40))
        for y in range(11, 15):
            s.px(4 + (y - 11) * 2, y, (110, 80, 40))

    return npc((170, 120, 85), (85, 95, 55), (60, 65, 45), hat, None, satchel)


# Fila donde empiezan las piernas de cada enemigo (para el segundo cuadro)
ENEMIES = {
    "Walker": (walker(), 17),
    "Runner": (runner(), 17),
    "Cone": (cone(), 25),
    "Knight": (knight(), 17),
    "Brute": (brute((130, 176, 70), (214, 206, 180), (86, 66, 52), WHITE), 20),
    "Fatso": (fatso(), 30),
    "King": (king(), 37),
    "Dragon": (dragon(), 30),
}

SPRITES = {}
for _name, (_sprite, _leg_row) in ENEMIES.items():
    SPRITES[_name] = _sprite
    SPRITES[_name + "_2"] = _sprite.walk_frame(_leg_row)
SPRITES.update({
    "NPC_Armero": armero(),
    "NPC_Bruja": bruja(),
    "NPC_Veterano": veterano(),
    "NPC_Intendente": intendente(),
})

if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, sprite in SPRITES.items():
        image = sprite.render()
        image.save(OUT_DIR / f"{name}.png")
        print(f"{name}: {image.width}x{image.height} (proporción ancho/alto = {image.width / image.height:.3f})")
