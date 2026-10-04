# Campana Maldita 🔔🧟

Juego de Roblox en primera persona, en **pixel art 3D** al estilo de Guns 'n Goblins y en la Edad Media, con ciclo de día y noche: defiende la
campana de tu campamento, al borde de un acantilado sobre el mar, de hordas de muertos vivientes que salen del bosque y cruzan el único puente de piedra sobre un barranco. Empiezas solo con un cuchillo y una pistola; prepárate antes de cada partida
comprando armas, mejoras, poderes y trampas a los NPC del campamento.

![Vista previa](docs/preview.png)

_Vista previa: recreación con las medidas, colores y sprites del juego, no es captura de Roblox._

🎬 Video de la horda al anochecer: [`docs/capturas/pixel/horda-de-noche.mp4`](docs/capturas/pixel/horda-de-noche.mp4)
(recreación, no captura de Roblox).

Más vistas previas en [`docs/capturas/puente/`](docs/capturas/puente/) (el puente de piedra, la campana destruida,
el círculo de runas y el cuchillo), [`docs/capturas/pixel/`](docs/capturas/pixel/) (bosque, portón,
¡subiste de nivel!, Veterano, campamento y jefes), [`docs/capturas/texturado/`](docs/capturas/texturado/) (bloques con texturas),
[`docs/capturas/voxel/`](docs/capturas/voxel/) (pixel art 3D de colores planos),
[`docs/capturas/medieval/`](docs/capturas/medieval/) (noche medieval realista),
[`docs/capturas/otono/`](docs/capturas/otono/) (otoño) y [`docs/capturas/`](docs/capturas/) (versiones anteriores). El diseño completo está en [`docs/DISENO.md`](docs/DISENO.md).

## Qué tiene ya
- **Un solo camino a la campana: el puente de piedra**. Un barranco con un río cruza todo el mapa y el único
  paso es un puente de losas con musgo, muros bajos con postes de madera, un pilar hasta el río y columnas con
  antorchas. Los zombis no pueden saltar el barranco (tampoco te persiguen por el aire); si te caes, te lleva el río.
- **Rejas de metal en los dos extremos del puente** (entrada y salida): solo aparecen si se las compras al Intendente.
- **La campana empieza destruida**: postes caídos y cruzados sobre el montículo, la campana tirada de costado y los
  estandartes en el suelo. Para empezar la partida alguien la **reconstruye** (mantener E): cada pieza vuela a su
  lugar. Si los zombis la destruyen, se derrumba otra vez. Armada es como en Guns 'n Goblins: dos postes altos con
  una cruz arriba, brazos de hierro con estandartes verdes y la campana de cobre, delante de un castillo en ruinas.
- **Círculo negro de runas** frente a la campana: ahí aparecen los jugadores.
- **Cuchillo como en Guns 'n Goblins**: guante grande de cuero con tachas, mango abajo a la izquierda y la hoja hacia
  la derecha. Abajo a la derecha se ve su silueta y un **círculo blanco** que se vacía con cada tajo (5 seguidos) y
  se recarga solo cuando dejas de atacar.
- **Pixel art 3D al estilo Guns 'n Goblins**: texturas pixeladas de 32×32 (pasto, tierra, adoquines, ladrillo,
  tablas, corteza, hojas, techo, roca…) que reemplazan los materiales de Roblox en todo el mapa y el terreno, zombis
  y NPC como **sprites pixelados con 2 cuadros de caminar**, y letra pixelada en la interfaz.
  _Para verlo así tienes que subir las imágenes una vez (ver "Subir las imágenes"); mientras tanto los zombis se
  ven como muñecos de bloques y el mapa con los materiales normales._
- **Los zombis salen del bosque**: además de la cripta del cementerio, llegan por 3 senderos que nacen entre los
  árboles (norte, oeste y este), saliendo desparramados del bosque. Todos se juntan antes del puente.
  Alrededor del mapa hay una pared de bosque de pinos.
- **Enemigos de muchos tamaños**: zombi, corredor, cono, caballero, bruto y los jefes enormes (gordo, rey y dragón).
- **Números de daño pixelados** que saltan sobre los zombis (blancos al pegar, amarillos al matar).
- **¡SUBISTE DE NIVEL!**: cartel grande de letras pixeladas azules que rebota con destellos al subir de nivel.
- **Pantalla del Veterano estilo Guns 'n Goblins**: dos columnas, MEJORAS con barritas y botón "+" y TALENTOS
  con APRENDIDO / APRENDER / NIVEL X; abajo dice qué hace lo que señalas.
- **Portón de piedra** (torres, almenas, rastrillo de hierro, escalera, bandera y farol) como reja.
- **Campamento** con cobertizos de madera (techo de tablas, faroles colgantes, cajas, barriles y troncos para sentarse)
  y fogata de cubitos; esporas que flotan con el viento.
- **Bloques con texturas reales**: todo es de cubos, pero con los materiales de Roblox (madera, piedra, ladrillo,
  hojas, tela, metal). El suelo es el terreno de Roblox con **pasto 3D que se mueve con el viento**, con ráfagas
  que lo hacen ondular. Los árboles, arbustos y estandartes también se mecen. El fuego es de cubitos que bailan,
  hay nubes de bloques y luciérnagas de cubitos, y los números grandes del HUD usan letra pixelada.
  (También está el estilo `"Voxel"`, de colores planos y baldosas.)
- **Zombis que se mueven como zombis**: cada uno camina distinto (largo del paso, ritmo, cabeza ladeada),
  algunos cojean y se hunden al pisar, el torso se balancea, la cabeza mira a los lados, los brazos suben y bajan,
  giran suave en las curvas, **salen de la tierra** arañando al aparecer, se echan hacia atrás cuando reciben
  un balazo y embisten al atacar. Los jefes dan pasos más lentos y pesados.
- **Ciclo de día y noche** (10 minutos por día): amanecer, mediodía, atardecer y noche con la luna enorme.
  Las velas y antorchas alumbran más de noche, y **de noche llegan más zombis** (30% más por segundo).
  Todos los jugadores ven la misma hora. Arriba a la derecha está el reloj.
- **Mapa medieval**: la campana en su montículo al frente, campamento detrás (fogata, tiendas, empalizada) al borde de un
  **acantilado sobre el mar** (con mirador; si te caes, te lleva el mar). Alrededor: aldea con casas de
  entramado de madera, pozo, carreta, estandartes, **velas** y **antorchas** que parpadean, árboles secos y una luna enorme.
- Si un zombi te persigue y lo pierdes, vuelve a su camino.
- **Preparación antes de cada partida**: el único momento para comprar. La partida empieza cuando alguien
  **reconstruye la campana** (mantener E) o cuando se acaba el tiempo (entonces se arma sola). Durante las
  oleadas las tiendas están cerradas.
- **Empiezas con cuchillo y pistola**. El cuchillo no gasta balas (gasta energía); las armas de fuego tienen cargador y
  **reserva limitada**, y **cada zombi que eliminas te da balas** para el arma que tienes en la mano.
- **4 NPC** en el campamento (habla con **E**):
  - **Bruno, el Armero**: 6 armas (cuchillo, pistola, escopeta, rifle, francotirador, ametralladora) y sus
    mejoras. **Cada mejora cambia el color del arma**: Bronce → Plata → Oro → Esmeralda → Legendaria.
  - **Morgana, la Bruja**: poderes (granada, rayo en cadena, campanazo) y sus mejoras.
  - **Don Ramiro, el Veterano**: gasta tus puntos de mejora y aprende talentos.
  - **Gustavo, el Intendente**: **cartuchera** (más balas máximas y más balas al empezar) y **trampas**:
    hasta 8 **minas** sobre el camino y 2 **rejas** (entrada y salida del puente) que los detienen hasta que las rompen.
- **Zombis que te persiguen** si te acercas, y vuelven a atacar la campana si te alejas. Tienes vida y reapareces.
- **5 tipos de zombi** de dibujo animado (piel verde, ojos enormes, boca abierta, camisa rota y jean): Zombi,
  Corredor, Zombi con cono, Caballero zombi y Bruto.
- **Jefes 6 veces más grandes** cada 5 oleadas, con su barra de vida arriba:
  - 🤢 **Zombi Gordo**: lento y resistente; al morir revienta y suelta 8 zombis.
  - 👑 **Rey Zombi**: corona, capa y mucha vida.
  - 🐉 **Dragón Zombi**: vuela directo a la campana por encima de rejas y minas y le escupe fuego verde.
- **Muerte pixelada**: el zombi se pone blanco, la cabeza sale volando, el cuerpo se desarma y revienta en
  cubitos que rebotan y se achican, y queda una mancha en el suelo.
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
- **Estilo**: `Config.ArtStyle` = `"Pixel"` (pixel art 3D con texturas pixeladas, por defecto), `"Texturado"`
  (bloques con los materiales de Roblox y pasto con viento),
  `"Voxel"` (pixel art 3D de colores planos y baldosas) o `"Realista"` (formas redondas, desenfoque y fuego
  de partículas).
- **Viento**: `Config.Wind` (dirección, fuerza y ráfagas).
- **Día y noche**: `Config.DayCycle` (duración del día, hora de inicio, cuántos zombis más de noche;
  `Enabled = false` para dejarlo siempre de noche).
- **Ambiente**: `Config.Theme` = `"Medieval"` (aldea medieval con día y noche, por defecto), `"Otono"`
  (atardecer de otoño), `"Verde"`, `"Morado"` o `"Ambar"` (noches fijas).
- **Zombis**: `Config.ZombieStyle` = `"Pixel"` (sprites 2D si subiste las imágenes, por defecto) o `"3D"`
  (muñecos de bloques).
- **Mapa**: el barranco y el puente están en `Config.Arena.Ravine` y `Config.Arena.Bridge`; el círculo de runas en
  `Config.Arena.SpawnCircle`.
- **Caminos**: los puntos de cada camino están en `Config.Paths` (y cuántos zombis van por cada uno en `Weight`).
  Los senderos del bosque no tienen `Entrance`: los zombis salen desparramados `PathStyle.SpawnSpread` studs.
- **Optimización**:
  - **StreamingEnabled**: cada jugador carga solo lo que tiene cerca; las montañas del fondo siempre se ven.
  - Los avisos de zombis (nacer, recibir daño, morir) se juntan en **un mensaje por fotograma**
    en vez de uno por zombi.
  - Los zombis que están detrás de ti no se dibujan, y los lejanos no se animan (`Config.Graphics`).
  - La muerte en cubitos tiene un tope de 260 cubitos a la vez, y los zombis muy lejanos mueren sin efecto.
  - El molino, las partículas y el parpadeo de velas y antorchas corren solo en cada cliente.
  - En **calidad gráfica baja o celular** se apagan el desenfoque, los rayos de sol, las partículas y el parpadeo.

## Subir las imágenes (para el pixel art)

Roblox solo muestra imágenes subidas a tu cuenta, así que las texturas pixeladas, los sprites de los zombis y NPC,
la luna y el sol hay que subirlos **una vez**. Hay un programa que lo hace todo solo:

1. **Genera las imágenes** (opcional, ya vienen en `assets/`; necesita `pip install pillow`):
   ```bash
   python3 tools/make_textures.py
   python3 tools/make_sprites.py
   python3 tools/make_sky.py
   ```
2. **Crea una API key**: entra a [create.roblox.com](https://create.roblox.com) → **Open Cloud → API Keys** →
   **Create API Key**. En *Access Permissions* agrega **Assets** con permiso de **lectura y escritura**
   (`asset:read` y `asset:write`), y en *Accepted IP Addresses* pon `0.0.0.0/0`. Copia la clave.
3. **Busca tu número de usuario**: es el número de la dirección de tu perfil
   (`roblox.com/users/`**`123456789`**`/profile`).
4. **Sube todo**:
   ```bash
   python3 tools/upload_assets.py --api-key TU_CLAVE --user-id TU_NUMERO
   ```
   Si el juego es de un grupo, usa `--group-id ID_DEL_GRUPO` en vez de `--user-id`.
   Escribe los ids en `src/shared/Assets.luau` y recuerda lo subido en `assets/uploaded.json`
   (si algo falla, vuelve a correrlo y solo sube lo que falta; `--force` sube todo de nuevo).
5. Reinicia `rojo serve` y dale **Play**.

**Importante**: el juego tiene que ser **del mismo usuario (o grupo)** que subió las imágenes; si no, Roblox no deja
leerlas y el juego sigue con el aspecto normal. Las imágenes nuevas pueden tardar unos minutos en pasar la
moderación de Roblox.

También puedes pegar ids a mano en `src/shared/Assets.luau` (o en `Config.SkyTextures` para la luna y el sol).
Para cambiar las imágenes, edita los `tools/make_*.py`, vuelve a generarlas y corre `upload_assets.py --force`.

## Controles
| Acción | PC | Celular |
|---|---|---|
| Disparar | Clic izquierdo (mantener) | Botón 🔫 |
| Recargar | R | Botón 🔄 |
| Cambiar de arma | 1 - 6 (1 = cuchillo) | Botón 🔁 |
| Hablar con NPC / reconstruir la campana / reparar campana | E | Tocar el aviso |
| Poderes | G granada · Q rayo · F campanazo | Botones abajo a la izquierda |
| Apuntar (talento Puntería) | Clic derecho | Botón 🔭 |
| Correr (talento Correr) | Shift | Botón 🏃 |
| Esquivar (talento Esquivar) | C | Botón 💨 |

## Estructura

```
src/
  shared/                   → ReplicatedStorage.Shared (servidor y cliente)
    Config.luau             ← TODOS los números del juego (enemigos, jefes, caminos, armas, poderes, mejoras, talentos)
    Paths.luau              ← geometría de los caminos de los zombis y del barranco
    DayCycle.luau           ← hora del día, paletas de luz y "es de noche"
    MeleeEnergy.luau        ← energía del cuchillo (el círculo blanco)
    Assets.luau             ← ids de las imágenes subidas (lo escribe tools/upload_assets.py)
    ResolvedAssets.luau     ← ids de imagen listos que publica el servidor, para el cliente
    Progression.luau        ← perfil, nivel de cuenta y cálculo de estadísticas
    EnemyMath.luau          ← movimiento de los zombis (línea quebrada por los caminos)
    Remotes.luau            ← comunicación servidor ↔ cliente
  server/                   → ServerScriptService.Server
    MapBuilder.luau         ← terreno, círculo de runas, bosque, molino, montañas, luz y bruma
    BellTower.luau          ← la campana: montículo, destruida/armada y su animación
    BridgeBuilder.luau      ← barranco con río y puente de piedra
    MedievalBuilder.luau    ← caminos, cementerio con cripta, castillo en ruinas, casas, pozo, velas y antorchas
    VoxelBuilder.luau       ← suelo de baldosas, acantilado y mar en pixel art 3D
    CampBuilder.luau        ← fogata, tiendas, empalizada, mirador, puestos y NPC
    AssetService.luau       ← aplica las imágenes subidas: texturas pixeladas (MaterialVariant), cielo y NPC
    Props.luau              ← piezas del mapa (faroles, antorchas, velas, estandartes, cajas, letreros…)
    DataService.luau        ← guardado del perfil (DataStore)
    ShopService.luau        ← compras de los 4 NPC (solo en la preparación)
    MatchService.luau       ← estadísticas de la partida y XP final
    EnemyService.luau       ← zombis (caminos, persecución, jefes, daño, empuje)
    WaveService.luau        ← oleadas y orden de los jefes
    CombatService.luau      ← valida disparos y munición (anti-trampas)
    PowerService.luau       ← granada, rayo y campanazo
    PlayerService.luau      ← vida, velocidad, talentos del servidor y caída al mar
    TrapService.luau        ← minas y rejas (portón de piedra con rastrillo)
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
    ZombieModels.luau       ← piezas de cada zombi, del Gordo, del Rey y del Dragón
    DeathFx.luau            ← muerte en cubitos
    DamageNumbers.luau      ← números de daño pixelados
    LevelUpFx.luau          ← cartel de ¡SUBISTE DE NIVEL!
    WorldFx.luau            ← molino, viento (ráfagas y cosas que se mecen), fuego y calidad gráfica
    SkyFx.luau              ← ciclo de día y noche, nubes, luciérnagas y esporas
    ZombieAnimator.luau     ← manera de caminar de cada zombi, cojera, salir de la tierra, golpes y embestidas
  character/Health.server.luau ← quita la regeneración automática de Roblox
assets/sprites/             ← PNG de los zombis, jefes y NPC (2 cuadros de caminar cada uno)
assets/textures/            ← texturas pixeladas de 32×32
tools/make_sprites.py       ← generador de los sprites
tools/make_textures.py      ← generador de las texturas
tools/make_sky.py           ← generador de la luna y el sol pixelados
tools/upload_assets.py      ← sube todas las imágenes a Roblox y escribe Assets.luau
```

## Balance rápido
Todo está en `src/shared/Config.luau`:
- ¿Muy fácil? Sube `Waves.CountGrowth` o la `Speed` de los enemigos.
- ¿Los zombis pegan muy fuerte? Baja `PlayerDamage` de cada enemigo.
- ¿Subes de nivel muy lento? Baja `Progression.XpBase` o sube `XpPerKill`.
- ¿Las armas son muy caras? Cambia `Price` en `Config.Weapons`.
- ¿Te quedas sin balas muy rápido? Sube `AmmoPerKill` o `StartReserve` del arma.
- ¿La preparación es muy larga? Cambia `Match.LobbyTime`.
- ¿Otro ambiente? Cambia `Theme` a `"Otono"`, `"Verde"`, `"Morado"` o `"Ambar"`.
- ¿Los jefes son muy duros? Baja su `MaxHealth` o sube `Waves.BossEvery`.
- ¿El cuchillo se cansa muy rápido? Baja `Energy.Cost` o sube `Energy.Regen` del `Machete` en `Config.Weapons`.
- ¿Más o menos zombis del bosque? Cambia el `Weight` de `ForestNorth`, `ForestWest` y `ForestEast`.
- ¿La noche es muy difícil? Baja `DayCycle.NightSpawnMultiplier` (1 = igual que de día).
- ¿Días más largos? Sube `DayCycle.Length` (en segundos).
