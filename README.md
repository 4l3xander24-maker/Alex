# Castle Blasters 🏰🔫🧟

Juego de Roblox: defiende tu castillo de hordas de zombis que crecen en cada oleada.
Inspirado en el género "horde survivor FPS".

## Fase 1: prototipo (lo que ya funciona)

- El mapa se genera solo, de noche y con niebla: muro del castillo con almenas, antorchas, torres, puerta y un cementerio de donde salen los zombis.
- Cámara en primera persona con mira.
- Pistola con disparo automático mientras mantienes el clic. En celular hay un botón 🔫.
- Zombis (piernas, torso, cabeza y brazos al frente) que se tambalean hacia el castillo y le hacen daño al llegar al muro.
- Oleadas infinitas: cada una trae más zombis, más rápido y con más vida.
- El castillo tiene vida. Si llega a 0 → Game Over y se reinicia solo.
- Oro y bajas en la tabla de jugadores.
- Multijugador cooperativo desde el inicio.

## Cómo probarlo en tu Mac

1. **Instala Rokit** (gestor de herramientas) y Rojo:
   ```bash
   curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   cd ruta/a/este/repo
   rokit install
   ```
2. **Instala el plugin de Rojo en Roblox Studio**:
   ```bash
   rojo plugin install
   ```
3. **Arranca el servidor de Rojo**:
   ```bash
   rojo serve
   ```
4. En Roblox Studio abre un **Baseplate** nuevo → pestaña **Plugins** → **Rojo** → **Connect**.
5. Dale a **Play** (F5). Para probar el co-op: pestaña **Test** → **Clients and Servers** → 2 jugadores → **Start**.

Cada vez que cambies código en el repo, Rojo lo actualiza en Studio en vivo.

## Estructura

```
src/
  shared/              → ReplicatedStorage.Shared (servidor y cliente)
    Config.luau        ← TODOS los números del juego (balance)
    EnemyMath.luau     ← movimiento determinista de los zombis
    Remotes.luau       ← comunicación servidor ↔ cliente
  server/              → ServerScriptService.Server
    init.server.luau   ← arranque
    MapBuilder.luau    ← construye el mapa
    GameState.luau     ← vida del castillo, oleada, estado
    EnemyService.luau  ← zombis (datos, daño, detección de impactos)
    WaveService.luau   ← ciclo de oleadas
    CombatService.luau ← valida disparos (anti-trampas)
    PlayerService.luau ← oro, bajas, cámara
  client/              → StarterPlayerScripts.Client
    init.client.luau   ← arranque
    EnemyRenderer.luau ← dibuja los zombis
    WeaponController.luau ← disparo e input
    Hud.luau           ← interfaz
```

## Cómo funciona por dentro (para aguantar cientos de zombis)

- Los zombis **no son personajes de Roblox** (Humanoid). Son solo datos en el servidor.
- Caminan en línea recta, así que servidor y clientes calculan la misma posición con el reloj del servidor.
  Solo se envía "nació", "recibió daño" y "murió". No se mandan posiciones cada frame.
- El cliente los mueve todos de golpe con `workspace:BulkMoveTo`.
- El servidor decide los impactos con matemática de esfera contra rayo. El cliente solo envía de dónde y hacia dónde disparó.
  Hay límite de cadencia, validación de la posición y compensación de lag.

## Balance rápido

Todo está en `src/shared/Config.luau`. Ejemplos:
- ¿El juego es muy fácil? Sube `Waves.CountGrowth` o `Enemies.Zombie.Speed`.
- ¿El castillo cae muy rápido? Sube `Castle.MaxHealth`.
- ¿La pistola se siente lenta? Sube `Weapon.FireRate`.

## Próximas fases

- **Fase 2 – Diversión:** subir de nivel con XP y elegir 1 de 3 mejoras, 5 armas, 4 tipos de enemigo, jefe cada 5 oleadas, modelos de zombi mejorados.
- **Fase 3 – Juego completo:** lobby, mejoras permanentes con gemas, guardado de datos.
- **Fase 4 – Lanzamiento:** tienda, pases de juego, pulido y publicación.
