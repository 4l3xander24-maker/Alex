# Campana Maldita 🔔🧟

Juego de Roblox en primera persona: defiende la campana de hordas de muertos vivientes.
Sube de nivel, elige mejoras, desbloquea poderes y aguanta todas las oleadas que puedas.

![Vista previa](docs/preview.png)

_Vista previa: recreación con las medidas, colores y sprites del juego, no es captura de Roblox._

Más vistas previas en [`docs/capturas/`](docs/capturas/). El diseño completo está en [`docs/DISENO.md`](docs/DISENO.md).

## Qué tiene ya
- Campanario en un claro del bosque, de noche, con luna enorme, niebla verde y faroles.
- Zombis pixelados en 4 tipos: Caminante, Corredor, Bruto y Abominación (jefe cada 5 oleadas).
- Arma con manos en primera persona, retroceso, destello y munición (recarga con **R**).
- XP y niveles: al subir eliges 1 de 3 mejoras con clic o con las teclas **1 / 2 / 3**.
- Poderes: **Q** Granada, **E** Rayo en cadena, **F** Campanazo.
- Monedas por cada baja.
- Cooperativo, y funciona en celular (botones de disparo, recarga y poderes).

## Cómo probarlo en tu Mac

1. **Instala Rokit y Rojo** (solo la primera vez):
   ```bash
   curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   cd ruta/a/este/repo
   rokit install
   rojo plugin install
   ```
2. **Arranca Rojo**: `rojo serve`
3. En Roblox Studio abre un **Baseplate** nuevo → **Plugins** → **Rojo** → **Connect** → **Play**.
4. Recomendado: en el panel Explorer selecciona **Lighting** y pon `Technology = Future`
   para que los faroles den sombras.

## Subir los sprites de los zombis

Mientras no subas los sprites, los zombis se ven como muñecos de bloques.

1. En Studio: **View → Asset Manager → Bulk Import** y elige los 4 PNG de `assets/sprites/`.
2. Clic derecho en cada imagen → **Copy Asset ID**.
3. Pégalo en `src/shared/Config.luau`, en el campo `Sprite` del enemigo, por ejemplo:
   ```lua
   Sprite = "rbxassetid://1234567890",
   ```

Para cambiar o crear sprites, edita `tools/make_sprites.py` y ejecuta `python3 tools/make_sprites.py`
(necesita `pip install pillow`).

## Controles
| Acción | PC | Celular |
|---|---|---|
| Disparar | Clic izquierdo (mantener) | Botón 🔫 |
| Recargar | R | Botón 🔄 |
| Poderes | Q / E / F | Botones abajo a la izquierda |
| Elegir mejora | Clic o 1 / 2 / 3 | Tocar la carta |

## Estructura

```
src/
  shared/                  → ReplicatedStorage.Shared (servidor y cliente)
    Config.luau            ← TODOS los números del juego (balance, enemigos, poderes, tema)
    Upgrades.luau          ← mejoras al subir de nivel y fuerza de los poderes
    EnemyMath.luau         ← movimiento determinista de los zombis
    Remotes.luau           ← comunicación servidor ↔ cliente
  server/                  → ServerScriptService.Server
    MapBuilder.luau        ← campanario, bosque, montañas, luna y niebla
    GameState.luau         ← vida de la campana, oleada, estado
    EnemyService.luau      ← zombis (daño, impactos, empuje)
    WaveService.luau       ← oleadas, mezcla de enemigos y jefes
    ProgressionService.luau← XP, niveles, cartas de mejora, munición
    CombatService.luau     ← valida disparos y recargas (anti-trampas)
    PowerService.luau      ← granada, rayo y campanazo
    PlayerService.luau     ← monedas, bajas, cámara
  client/                  → StarterPlayerScripts.Client
    EnemyRenderer.luau     ← dibuja los zombis (sprites o bloques)
    Viewmodel.luau         ← arma y manos en primera persona
    WeaponController.luau  ← disparo, munición, recarga
    PowerController.luau   ← teclas de poderes y sus efectos
    UpgradeMenu.luau       ← cartas de "¡subiste de nivel!"
    Hud.luau               ← interfaz
assets/sprites/            ← PNG de los zombis
tools/make_sprites.py      ← generador de los sprites
```

## Balance rápido
Todo está en `src/shared/Config.luau`:
- ¿Muy fácil? Sube `Waves.CountGrowth` o la `Speed` de los enemigos.
- ¿La campana cae muy rápido? Sube `Bell.MaxHealth`.
- ¿Subes de nivel muy lento? Baja `Progression.XpBase`.
- ¿Otro ambiente? Cambia `Theme` a `"Morado"` o `"Ambar"`.
