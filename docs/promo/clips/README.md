# Biblioteca de clips (sin audio, 30 fps, 1–4 MB cada uno)

Cada clip tiene `-alto` (720×1280, para TikTok/Reels/Shorts) y `-ancho` (1280×614, para YouTube/página del juego).
Los videos pesados están fuera de Git (`docs/promo/clips/*.mp4`); se regeneran con `tools/footage` + `tools/recclip.sh` + `tools/mkclip.sh`.

| Clip | Dura | Qué muestra |
|---|---|---|
| lobby-salas | 12 s | Recorrido por los carteles de las salas (SOLO, 2…5 PERSONAS) con sus círculos verdes |
| lobby-plaza | 10 s | Giro alrededor de la campana gigante y el arco de salas, de noche |
| tienda-armeria | 7 s | Tienda de la Armería con scroll (mejor en `-ancho`: en vertical se recorta el panel) |
| arma-fusil | 6 s | Fusil, zombis a lo lejos, números de daño |
| arma-minigun | 5 s | Minigun |
| arma-ballesta | 6 s | Ballesta |
| arma-lanzallamas | 7 s | Lanzallamas con fuego |
| horda | 6 s | Zombis grandes de cerca |

Pendientes (no se pudieron grabar): menú de dificultad, trampas, compañero.
