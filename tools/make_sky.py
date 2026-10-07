"""Genera la luna, la luna de sangre y el sol pixelados para el cielo en assets/sky/.

Súbelos a Roblox (Asset Manager → Bulk Import) y pega sus ids en
Config.SkyTextures (Moon y Sun). Si no los subes, se usan los de Roblox.

Uso: python3 tools/make_sky.py
"""
import math
import random
from pathlib import Path

from PIL import Image

SIZE = 32  # píxeles de la luna/sol antes de escalar
SCALE = 16
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sky"


def disc(color, shade, craters):
    rng = random.Random(4)
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    center = (SIZE - 1) / 2
    radius = SIZE / 2 - 1
    for y in range(SIZE):
        for x in range(SIZE):
            distance = math.hypot(x - center, y - center)
            if distance > radius:
                continue
            # Borde más oscuro abajo a la derecha, como luz desde arriba a la izquierda
            tone = color if (x - center) + (y - center) < radius * 0.9 else shade
            image.putpixel((x, y), tone + (255,))
    for _ in range(craters):
        cx, cy, r = rng.randint(6, SIZE - 7), rng.randint(6, SIZE - 7), rng.randint(1, 3)
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if math.hypot(x - cx, y - cy) <= r and image.getpixel((x, y))[3]:
                    image.putpixel((x, y), shade + (255,))
    return image.resize((SIZE * SCALE, SIZE * SCALE), Image.NEAREST)


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    disc((236, 232, 255), (176, 176, 210), 7).save(OUT_DIR / "Moon.png")
    disc((255, 226, 120), (255, 170, 60), 0).save(OUT_DIR / "Sun.png")
    # Luna de sangre: aparece en las oleadas altas, cuando el cielo se pone rojo
    disc((236, 96, 80), (170, 46, 52), 7).save(OUT_DIR / "MoonRed.png")
    print("assets/sky/Moon.png, MoonRed.png y Sun.png listos")
