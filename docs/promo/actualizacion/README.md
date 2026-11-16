# Videos de la actualización (jefe final y bestiario)

Tres videos verticales de 15 s (1080×1920, 30 fps) para TikTok, Reels y Shorts.
Se hacen con `trailer/src/Update.tsx` (audio: `trailer/audio_update.py`).
Usan capturas reales del juego (`docs/promo/06-bestiario.png`, `segador.png` y
las de la campana). El Campanero Maldito sale como **silueta**: todavía no hay
captura suya, así que el video lo presenta como un misterio.

Volver a generarlos (desde `trailer/`):
```
python3 audio_update.py
npx remotion render src/index.ts ShortFinalBoss ../docs/promo/actualizacion/ShortFinalBoss.mp4
```

> Publica estos videos **después** de volver a publicar el juego en Roblox:
> el jefe final, el bestiario y el código BIENVENIDO solo existen en la versión nueva.

| Orden | Archivo | Descripción para pegar |
|---|---|---|
| 1 | `ShortFinalBoss.mp4` | `Llegas a la última oleada y la campana suena… 🔔💀 El CAMPANERO MALDITO te espera. ¿Lo derrotas? Gratis en Roblox: busca "Campana Maldita" 👇 #roblox #robloxgame #zombies #jefefinal #juegosroblox #campanamaldita #fyp` |
| 2 | `ShortBestiary.mp4` | `¿Cuántos zombis conoces? 📖 Colecciona a todos y gana medallas 🥉🥈🥇 El último solo aparece en la oleada final… Gratis en Roblox: "Campana Maldita" 👇 #roblox #robloxgame #zombies #coleccion #juegosroblox #campanamaldita #fyp` |
| 3 | `ShortUpdate.mp4` | `¡Nueva actualización! 🔔 Jefe final, bestiario, racha diaria y skins de invierno ❄️ Código: BIENVENIDO = 200 monedas 🪙 Gratis en Roblox: "Campana Maldita" 👇 #roblox #robloxgame #codigos #robloxcodes #zombies #campanamaldita #fyp` |

Comentario fijado en todos: `Juégalo aquí 👉 https://www.roblox.com/games/107080967531379/Campana-Maldita`

Consejos:
- Uno por día a las 19:00, como el calendario de `docs/promo/tiktok-calendario.md`.
- El del código suele moverse más: pide en el comentario "¿Qué código quieren para la próxima?".
- Cuando grabes al Campanero de verdad en Studio, un clip de 5 s matándolo vale más que estos tres juntos.
