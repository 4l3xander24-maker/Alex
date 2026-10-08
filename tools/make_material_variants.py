"""Genera src/materials/*.model.json: un MaterialVariant por textura pixelada.

Roblox no deja crear MaterialVariant desde un script mientras se juega, así que
Rojo los crea en Studio. Los ids son de IMAGEN (no del Decal subido) y están en
assets/texture_images.json. Para sacarlos de un Decal, en la barra de comandos
de Studio: print(game:GetService("InsertService"):LoadAsset(ID_DEL_DECAL):FindFirstChildWhichIsA("Decal", true).Texture)
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Qué material de Roblox reemplaza cada textura y cada cuántos studs se repite
# (igual que TEXTURE_MATERIALS en src/server/AssetService.luau)
MATERIALS = {
    "Grass": ("Grass", 8),
    "Dirt": ("Ground", 6),
    "Mud": ("Mud", 8),
    "Cobblestone": ("Cobblestone", 8),
    "StoneBricks": ("Slate", 8),
    "Planks": ("WoodPlanks", 6),
    "Bark": ("Wood", 4),
    "Leaves": ("LeafyGrass", 6),
    "Roof": ("ClayRoofTiles", 6),
    "Plaster": ("Plaster", 8),
    "Rock": ("Rock", 12),
    "Sand": ("Sand", 8),
    "Fabric": ("Fabric", 3),
}


def main():
    images = json.loads((ROOT / "assets" / "texture_images.json").read_text())
    out = ROOT / "src" / "materials"
    out.mkdir(exist_ok=True)
    for old in out.glob("*.model.json"):
        old.unlink()
    for name, (material, studs) in MATERIALS.items():
        image = images.get(name, "")
        if not image:
            continue
        model = {
            "ClassName": "MaterialVariant",
            "Properties": {
                "BaseMaterial": material,
                "ColorMap": f"rbxassetid://{image}",
                "StudsPerTile": studs,
                "MaterialPattern": "Regular",
            },
        }
        (out / f"Pixel{name}.model.json").write_text(json.dumps(model, indent=2) + "\n")
        print(f"Pixel{name}: {material} <- {image}")


if __name__ == "__main__":
    main()
