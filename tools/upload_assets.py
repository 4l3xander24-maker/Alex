"""Sube a Roblox todas las imágenes del juego (sprites, texturas, cielo) y
escribe sus ids en src/shared/Assets.luau. Así el juego usa el pixel art sin
copiar ids a mano.

Necesitas una API key de Roblox (Open Cloud) con permiso de escritura de
assets, y tu número de usuario. Ver README → "Subir las imágenes".

Uso:
  python3 tools/upload_assets.py --api-key TU_CLAVE --user-id TU_ID
  python3 tools/upload_assets.py --api-key TU_CLAVE --group-id ID_DEL_GRUPO   (si el juego es de un grupo)

Las que ya subiste se recuerdan en assets/uploaded.json y no se vuelven a
subir (usa --force para subir todo de nuevo).
Solo usa la librería estándar de Python.
"""
import argparse
import json
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FOLDERS = ["sprites", "textures", "sky"]
CACHE = ROOT / "assets" / "uploaded.json"
OUTPUT = ROOT / "src" / "shared" / "Assets.luau"
API = "https://apis.roblox.com/assets/v1"


def request(method, url, api_key, body=None, content_type=None):
    headers = {"x-api-key": api_key}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.loads(response.read().decode())


def upload(path, api_key, creator):
    boundary = uuid.uuid4().hex
    meta = {
        "assetType": "Decal",
        "displayName": f"CampanaMaldita_{path.stem}"[:50],
        "description": "Imagen del juego Campana Maldita",
        "creationContext": {"creator": creator},
    }
    body = b"".join([
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n".encode(),
        json.dumps(meta).encode(),
        f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{path.name}\"\r\nContent-Type: image/png\r\n\r\n".encode(),
        path.read_bytes(),
        f"\r\n--{boundary}--\r\n".encode(),
    ])
    operation = request("POST", f"{API}/assets", api_key, body, f"multipart/form-data; boundary={boundary}")
    operation_id = operation.get("operationId") or operation["path"].split("/")[-1]
    # La subida se procesa en segundo plano: esperamos a que termine
    for _ in range(30):
        result = request("GET", f"{API}/operations/{operation_id}", api_key)
        if result.get("done"):
            return str(result["response"]["assetId"])
        time.sleep(2)
    raise RuntimeError(f"Roblox tardó demasiado en procesar {path.name}")


def lua_string(value):
    return '"' + value + '"' if value else '""'


def write_assets(ids):
    def get(folder, name):
        value = ids.get(f"{folder}/{name}")
        return f"rbxassetid://{value}" if value else ""

    sprites = sorted({p.stem.replace("_2", "") for p in (ROOT / "assets" / "sprites").glob("*.png") if not p.stem.startswith("NPC_")})
    npcs = sorted(p.stem[4:] for p in (ROOT / "assets" / "sprites").glob("NPC_*.png"))
    textures = sorted(p.stem for p in (ROOT / "assets" / "textures").glob("*.png"))
    lines = [
        "-- Ids de las imágenes subidas a Roblox. Este archivo lo escribe",
        "-- tools/upload_assets.py; también puedes pegar ids a mano.",
        "-- Vacío = no subida todavía (el juego usa los modelos 3D y materiales normales).",
        "return {",
        "\t-- Dos cuadros de caminar por enemigo",
        "\tSprites = {",
    ]
    for name in sprites:
        lines.append(f"\t\t{name} = {{ {lua_string(get('sprites', name))}, {lua_string(get('sprites', name + '_2'))} }},")
    lines += ["\t},", "\tNPC = {"]
    for name in npcs:
        lines.append(f"\t\t{name} = {lua_string(get('sprites', 'NPC_' + name))},")
    lines += ["\t},", "\t-- Texturas pixeladas (MaterialVariant)", "\tTextures = {"]
    for name in textures:
        lines.append(f"\t\t{name} = {lua_string(get('textures', name))},")
    lines += ["\t},", "\tSky = {", f"\t\tMoon = {lua_string(get('sky', 'Moon'))},", f"\t\tMoonRed = {lua_string(get('sky', 'MoonRed'))},", f"\t\tSun = {lua_string(get('sky', 'Sun'))},", "\t},", "}", ""]
    OUTPUT.write_text("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--api-key", required=True)
    owner = parser.add_mutually_exclusive_group(required=True)
    owner.add_argument("--user-id")
    owner.add_argument("--group-id")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    creator = {"userId": args.user_id} if args.user_id else {"groupId": args.group_id}

    ids = json.loads(CACHE.read_text()) if CACHE.exists() and not args.force else {}
    files = [p for folder in FOLDERS for p in sorted((ROOT / "assets" / folder).glob("*.png"))]
    for path in files:
        key = f"{path.parent.name}/{path.stem}"
        if key in ids:
            continue
        try:
            ids[key] = upload(path, args.api_key, creator)
            print(f"✔ {key} → {ids[key]}")
        except urllib.error.HTTPError as error:
            print(f"✘ {key}: {error.code} {error.read().decode()[:200]}")
        except Exception as error:  # seguimos con las demás
            print(f"✘ {key}: {error}")
        CACHE.write_text(json.dumps(ids, indent=2))
    write_assets(ids)
    print(f"Listo: {len(ids)}/{len(files)} imágenes subidas. Ids escritos en {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
