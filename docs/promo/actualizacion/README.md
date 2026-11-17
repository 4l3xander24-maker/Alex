# Videos de la actualización (jefe final y bestiario)

Tres videos verticales de 15 s (1080×1920, 30 fps) para TikTok, Reels y Shorts.
Se hacen con `trailer/src/Update.tsx` (audio: `trailer/audio_update.py`).
Montan capturas reales del juego (vistas en primera persona con ballesta,
escopeta y lanzallamas, la campana y los zombis recortados del bestiario) con
disparos, cubitos, combos, subtítulos palabra por palabra y sonido sincronizado.
No son una partida grabada. El Campanero Maldito todavía no tiene captura: está
hecho en 3D con bloques siguiendo su modelo (`trailer/tools/boss3d.html`, se
abre con three.js 0.170 y Playwright).

Volver a generarlos (desde `trailer/`):
```
python3 audio_update.py
npx remotion render src/index.ts ShortFinalBoss ../docs/promo/actualizacion/ShortFinalBoss.mp4
```

> Publica estos videos **después** de volver a publicar el juego en Roblox:
> el jefe final, el bestiario y el código BIENVENIDO solo existen en la versión nueva.

| Día (19:00 Lima) | Archivo | Descripción para pegar |
|---|---|---|
| Mié 18 nov | `ShortFinalBoss.mp4` | `Llegas a la última oleada y la campana suena… 🔔💀 El CAMPANERO MALDITO te espera. ¿Lo derrotas? Gratis en Roblox: busca "Campana Maldita" 👇 #roblox #robloxgame #zombies #jefefinal #juegosroblox #campanamaldita #fyp` |
| Jue 19 nov | `ShortBestiary.mp4` | `¿Cuántos zombis conoces? 📖 Colecciona a todos y gana medallas 🥉🥈🥇 El último solo aparece en la oleada final… Gratis en Roblox: "Campana Maldita" 👇 #roblox #robloxgame #zombies #coleccion #juegosroblox #campanamaldita #fyp` |
| Vie 20 nov | `ShortUpdate.mp4` | `¡Nueva actualización! 🔔 Jefe final, bestiario, racha diaria y skins de invierno ❄️ Código: BIENVENIDO = 200 monedas 🪙 Gratis en Roblox: "Campana Maldita" 👇 #roblox #robloxgame #codigos #robloxcodes #zombies #campanamaldita #fyp` |

Comentario fijado en todos: `Juégalo aquí 👉 https://www.roblox.com/games/107080967531379/Campana-Maldita`

Consejos:
- Uno por día a las 19:00, como el calendario de `docs/promo/tiktok-calendario.md`.
- El del código suele moverse más: pide en el comentario "¿Qué código quieren para la próxima?".
- Cuando grabes al Campanero de verdad en Studio, un clip de 5 s matándolo vale más que estos tres juntos.
