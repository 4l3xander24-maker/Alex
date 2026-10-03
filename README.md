# Campana Maldita 🔔🧟

Juego de Roblox en primera persona: defiende la campana de tu campamento, al borde de un acantilado sobre el mar,
de hordas de muertos vivientes. Empiezas solo con un machete y una pistola; prepárate antes de cada partida
comprando armas, mejoras, poderes y trampas a los NPC del campamento.

![Vista previa](docs/preview.png)

_Vista previa: recreación con las medidas, colores y sprites del juego, no es captura de Roblox._

Más vistas previas en [`docs/capturas/otono/`](docs/capturas/otono/) (ambiente de otoño) y [`docs/capturas/`](docs/capturas/) (noche). El diseño completo está en [`docs/DISENO.md`](docs/DISENO.md).

## Qué tiene ya
- **Mapa abierto**: campanario al frente, campamento detrás (fogata, tiendas, empalizada) al borde de un
  **acantilado sobre el mar** (con mirador; si te caes, te lleva el mar) y bosque alrededor.
- **Preparación antes de cada partida**: el único momento para comprar. La partida empieza cuando alguien
  **toca la campana** (mantener E) o cuando se acaba el tiempo. Durante las oleadas las tiendas están cerradas.
- **Empiezas con machete y pistola**. El machete no gasta balas; las armas de fuego tienen cargador y
  **reserva limitada**, y **cada zombi que eliminas te da balas** para el arma que tienes en la mano.
- **4 NPC** en el campamento (habla con **E**):
  - **Bruno, el Armero**: 6 armas (machete, pistola, escopeta, rifle, francotirador, ametralladora) y sus
    mejoras. **Cada mejora cambia el color del arma**: Bronce → Plata → Oro → Esmeralda → Legendaria.
  - **Morgana, la Bruja**: poderes (granada, rayo en cadena, campanazo) y sus mejoras.
  - **Don Ramiro, el Veterano**: gasta tus puntos de mejora y aprende talentos.
  - **Gustavo, el Intendente**: **cartuchera** (más balas máximas y más balas al empezar) y **trampas**:
    hasta 8 **minas** en el camino de los zombis y 2 **rejas** que los detienen hasta que las rompen.
- **Zombis que te persiguen** si te acercas, y vuelven a atacar la campana si te alejas. Tienes vida y reapareces.
- **4 tipos de zombi** en 3D (caminan, balancean los brazos y golpean) y una Abominación (jefe) cada 5 oleadas.
- **Ambiente de otoño** realista: iluminación Future con sombras suaves, árboles naranjas y rojos, molino,
  camino de piedra, hojas que caen, bruma y rayos de sol. También hay ambientes de noche.
- **Nivel de cuenta**: al terminar la partida ganas XP. Cada nivel da 1 punto de mejora (daño, vida, velocidad,
  recarga, cadencia, munición, crítico, botín, poder) y cada 5 niveles un **talento** (apuntar, correr,
  regeneración, vampiro, doble salto, esquivar, último aliento, balas explosivas, codicia, reparador).
- **Todo se guarda** (monedas, nivel, armas, poderes, talentos) con DataStore.
- Cooperativo, y funciona en celular.

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
4. **Para que se guarde el progreso en Studio**: Home → Game Settings → Security →
   **Enable Studio Access to API Services** (el juego tiene que estar publicado).

Los gráficos ya vienen configurados en `default.project.json`: iluminación **Future**, pasto 3D
(`Terrain.Decoration`) y **StreamingEnabled**. No tienes que tocar nada en Studio.

## Gráficos y rendimiento
- **Ambiente**: `Config.Theme` = `"Otono"` (día de otoño, por defecto), `"Verde"`, `"Morado"` o `"Ambar"` (noches).
- **Zombis**: `Config.ZombieStyle` = `"3D"` (por defecto) o `"Pixel"` (sprites 2D, aún más ligero).
- **Optimización**:
  - **StreamingEnabled**: cada jugador carga solo lo que tiene cerca; las montañas del fondo siempre se ven.
  - Los avisos de zombis (nacer, recibir daño, morir) se juntan en **un mensaje por fotograma**
    en vez de uno por zombi.
  - Los zombis que están detrás de ti no se dibujan, y los lejanos no se animan (`Config.Graphics`).
  - El molino y las partículas corren solo en cada cliente.
  - En **calidad gráfica baja o celular** se apagan el desenfoque, los rayos de sol y las hojas.

## Subir los sprites de los zombis (solo estilo `"Pixel"`)

Con `ZombieStyle = "3D"` no hace falta. En estilo `"Pixel"`, mientras no subas los sprites,
los zombis se ven como muñecos de bloques.

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
| Cambiar de arma | 1 - 6 (1 = machete) | Botón 🔁 |
| Hablar con NPC / empezar partida / reparar campana | E | Tocar el aviso |
| Poderes | G granada · Q rayo · F campanazo | Botones abajo a la izquierda |
| Apuntar (talento Puntería) | Clic derecho | Botón 🔭 |
| Correr (talento Correr) | Shift | Botón 🏃 |
| Esquivar (talento Esquivar) | C | Botón 💨 |

## Estructura

```
src/
  shared/                   → ReplicatedStorage.Shared (servidor y cliente)
    Config.luau             ← TODOS los números del juego (enemigos, armas, poderes, mejoras, talentos)
    Progression.luau        ← perfil, nivel de cuenta y cálculo de estadísticas
    EnemyMath.luau          ← movimiento de los zombis
    Remotes.luau            ← comunicación servidor ↔ cliente
  server/                   → ServerScriptService.Server
    MapBuilder.luau         ← terreno, campanario, bosque de otoño, molino, montañas, luz y bruma
    CampBuilder.luau        ← fogata, tiendas, empalizada, mirador, puestos y NPC
    Props.luau              ← piezas del mapa (faroles, cajas, letreros…)
    DataService.luau        ← guardado del perfil (DataStore)
    ShopService.luau        ← compras de los 4 NPC (solo en la preparación)
    MatchService.luau       ← estadísticas de la partida y XP final
    EnemyService.luau       ← zombis (persecución, daño, empuje)
    WaveService.luau        ← oleadas y jefes
    CombatService.luau      ← valida disparos y munición (anti-trampas)
    PowerService.luau       ← granada, rayo y campanazo
    PlayerService.luau      ← vida, velocidad, talentos del servidor y caída al mar
    TrapService.luau        ← minas y rejas
    GameState.luau          ← vida de la campana y estado
  client/                   → StarterPlayerScripts.Client
    Profile.luau            ← copia local del perfil
    ShopUI.luau             ← ventanas de los NPC
    MatchSummary.luau       ← pantalla de fin de partida
    Hud.luau / Notify.luau  ← interfaz y avisos
    WeaponController.luau   ← disparo, munición, cambio de arma, apuntar
    MovementController.luau ← correr, doble salto, esquivar
    PowerController.luau    ← poderes y sus efectos
    Viewmodel.luau          ← armas y manos en primera persona
    EnemyRenderer.luau      ← dibuja y anima los zombis (3D o pixel, con recorte por distancia)
    WorldFx.luau            ← molino y efectos según la calidad gráfica
  character/Health.server.luau ← quita la regeneración automática de Roblox
assets/sprites/             ← PNG de los zombis
tools/make_sprites.py       ← generador de los sprites
```

## Balance rápido
Todo está en `src/shared/Config.luau`:
- ¿Muy fácil? Sube `Waves.CountGrowth` o la `Speed` de los enemigos.
- ¿Los zombis pegan muy fuerte? Baja `PlayerDamage` de cada enemigo.
- ¿Subes de nivel muy lento? Baja `Progression.XpBase` o sube `XpPerKill`.
- ¿Las armas son muy caras? Cambia `Price` en `Config.Weapons`.
- ¿Te quedas sin balas muy rápido? Sube `AmmoPerKill` o `StartReserve` del arma.
- ¿La preparación es muy larga? Cambia `Match.LobbyTime`.
- ¿Otro ambiente? Cambia `Theme` a `"Verde"`, `"Morado"` o `"Ambar"` (noches).
