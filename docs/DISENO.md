# Diseño del juego

## La idea en una frase
Defiendes una **campana** en lo alto de un campanario mientras **hordas de muertos vivientes** llegan del bosque
en oleadas cada vez más grandes. Disparas, subes de nivel, eliges mejoras y desbloqueas poderes. Si la campana cae,
pierdes la partida, pero conservas tus **monedas** para hacerte más fuerte en la siguiente.

## Estilo visual (de las referencias)
- Mundo 3D de **bloques**: pinos escalonados, montañas, piedra y madera.
- Enemigos como **sprites pixelados 2D** que siempre miran a la cámara (`assets/sprites/`).
- Noche con **luna enorme**, niebla de color y faroles cálidos.
- Paletas por mapa: verde (bosque), morado (pantano), ámbar (atardecer). Se cambian con `Config.Theme`.
- Arma "low-poly" en primera persona con manos, retroceso y destello.
- Campamento con fogata como zona entre partidas (Fase 3).

## Ciclo de juego
1. **Partida**: oleadas infinitas. Cada 5 oleadas aparece una Abominación (jefe).
2. **Cada zombi** da XP a todo el equipo y monedas a quien lo mata.
3. **Subir de nivel** muestra 3 cartas de mejora al azar. Eliges una (clic o teclas 1/2/3).
4. **Se pierde** cuando la vida de la campana llega a 0. Las mejoras de la partida se reinician.
5. **Entre partidas** gastas monedas en talentos permanentes y armas nuevas (Fase 3).

## Sistemas

| Sistema | Qué es | Dónde vive | Estado |
|---|---|---|---|
| Campana | Vida compartida; los zombis la golpean al llegar | `GameState`, `EnemyService` | ✅ |
| Oleadas | Más zombis, más rápido y con más vida | `WaveService`, `Config.Waves` | ✅ |
| Enemigos | Caminante, Corredor, Bruto, Abominación (jefe) | `Config.Enemies` | ✅ |
| Munición | Cargador, recarga con R o automática al vaciarse | `CombatService`, `WeaponController` | ✅ |
| XP y niveles | XP compartida; cada nivel pide 25% más | `ProgressionService` | ✅ |
| Mejoras (skills) | Daño, cadencia, cargador, recarga, perforación, disparo múltiple, crítico | `shared/Upgrades.luau` | ✅ |
| Poderes | Granada (Q), Rayo en cadena (E), Campanazo (F); mejoran por nivel | `PowerService`, `PowerController` | ✅ |
| Monedas | Se ganan por baja | `PlayerService` | ✅ (sin guardar todavía) |
| Talentos | Árbol permanente comprado con monedas | — | Fase 3 |
| Armas | Escopeta, rifle, ametralladora; mejoras de nivel con monedas | — | Fase 3 |
| Guardado | Monedas, talentos y armas en DataStore | — | Fase 3 |
| Campamento | Zona con fogata, tienda y NPCs entre partidas | — | Fase 3 |

## Mejoras disponibles al subir de nivel
| Mejora | Efecto | Máx. |
|---|---|---|
| 💥 Balas pesadas | +25% de daño | 10 |
| ⚡ Gatillo rápido | +15% de cadencia | 8 |
| 📦 Cargador ampliado | +40% de munición | 8 |
| 🔄 Manos ágiles | Recarga 20% más rápida | 6 |
| 🗡️ Balas perforantes | Atraviesa +1 zombi | 5 |
| 🔱 Disparo múltiple | +1 bala por disparo | 4 |
| 🎯 Ojo de halcón | +10% de crítico (x2) | 5 |
| 💣 Granada | Desbloquea [Q]; luego +50% daño y +15% radio | 5 |
| 🌩️ Rayo en cadena | Desbloquea [E]; luego +2 saltos y +30% daño | 5 |
| 🔔 Campanazo | Desbloquea [F]; empuja a todos los zombis cercanos | 4 |

## Talentos permanentes (Fase 3, propuesta)
- **Ofensiva**: daño base, crítico base, empezar con un poder desbloqueado.
- **Defensa**: vida de la campana, regeneración entre oleadas, campanazo más fuerte.
- **Economía**: monedas extra por baja, XP extra, una carta más al subir de nivel.

## Por qué aguanta cientos de zombis
- Los zombis no son personajes de Roblox (Humanoid): son datos en el servidor.
- Caminan en línea recta, así que servidor y clientes calculan la posición con el reloj del servidor.
  Solo se envía "nació", "recibió daño", "murió" y "fue empujado".
- El cliente mueve todos los sprites de golpe con `workspace:BulkMoveTo`.
- Los impactos se calculan con esferas contra rayos, que es muy barato.

## Plan
- **Fase 2 (hecha)**: campana, estilo nuevo, sprites, 4 enemigos, jefe, munición, XP, mejoras, poderes, arma en pantalla.
- **Fase 3**: guardado, campamento con fogata, talentos, tienda de armas, sonidos.
- **Fase 4**: más mapas (paletas morado/ámbar), más jefes, pases de juego y lanzamiento.
