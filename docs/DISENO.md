# Diseño del juego

## La idea en una frase
Defiendes una **campana** junto a tu **campamento** mientras hordas de muertos vivientes llegan del bosque en
oleadas. Te mueves libremente por el mapa, compras armas y poderes a los NPC del campamento, y al terminar cada
partida ganas **XP de cuenta** para subir de nivel, mejorar tus estadísticas y aprender talentos.

## Estilo visual
- Mundo 3D de **bloques** sobre **Terrain** de Roblox con pasto (con decoración 3D si está activada).
- Enemigos como **sprites pixelados 2D** que siempre miran a la cámara (`assets/sprites/`).
- Noche con **luna enorme**, niebla de color, fogata, faroles y luciérnagas.
- Paletas por mapa: verde (bosque), morado (pantano), ámbar (atardecer) con `Config.Theme`.
- 5 armas de bloques en primera persona con manos, retroceso, destello y mira telescópica.

## El mapa
- **Campanario** (en el centro, al frente): lo que hay que defender. Tiene rampa y baranda; desde arriba los zombis
  no te alcanzan, pero tampoco proteges a la campana de cerca.
- **Campamento** (detrás): fogata con bancos, 4 tiendas de campaña, empalizada de troncos y faroles.
- **NPC del campamento** (se habla con ellos con **E**):
  | NPC | Puesto | Qué vende |
  |---|---|---|
  | Bruno, el Armero | Armería | Armas nuevas, mejoras de arma (5 niveles), equipar |
  | Morgana, la Bruja | Caldero | Poderes y sus mejoras |
  | Don Ramiro, el Veterano | Campo de entrenamiento | Puntos de mejora y talentos |
- **Campo de batalla** (al frente): cementerio donde nacen los zombis, rocas y bosque alrededor.

## Ciclo de juego
1. **Antes de cada oleada** (25 s la primera, 15 s las demás) compras en el campamento.
2. **Oleada**: los zombis van a la campana. Si te acercas a menos de 22 studs te persiguen y te atacan;
   si te alejas más de 45, vuelven a la campana. Cada 5 oleadas sale una Abominación (jefe).
3. **Cada baja** da monedas a quien la hizo (se guardan siempre).
4. **Si mueres** reapareces en el campamento a los 5 segundos.
5. **Si la campana cae** termina la partida: ves un resumen y recibes la **XP de cuenta**:
   25 por oleada superada + 2 por baja + 40 por jefe.

## Progresión permanente (se guarda con DataStore)
- **Monedas**: para el Armero y la Bruja.
- **Nivel de cuenta**: cada nivel pide 15% más XP (100, 114, 132, 152…).
- **1 punto de mejora por nivel** para el Veterano:

  | Mejora | Por punto | Máx. |
  |---|---|---|
  | 💥 Daño | +5% | 20 |
  | ❤️ Vida | +10 de vida máxima | 20 |
  | 👟 Velocidad | +3% al caminar | 10 |
  | 🔄 Recarga | 5% más rápida | 10 |
  | ⚡ Cadencia | +3% | 10 |
  | 📦 Munición | +8% por cargador | 10 |
  | 🎯 Crítico | +2% | 10 |
  | 🪙 Botín | +5% monedas | 10 |
  | ✨ Poder | +5% daño de poderes y menos espera | 10 |

- **1 talento cada 5 niveles** (se aprende una vez cada uno):

  | Talento | Qué hace |
  |---|---|
  | 🔭 Puntería | Clic derecho para apuntar: zoom, -70% dispersión, +15% crítico |
  | 🏃 Correr | Shift: 60% más rápido (sin disparar) |
  | 💚 Regeneración | 8 de vida/s tras 4 s sin recibir daño |
  | 🩸 Vampiro | Cada baja cura 3 |
  | 🦘 Doble salto | Otro salto en el aire |
  | 💨 Esquivar | C: impulso hacia adelante (cada 3 s) |
  | 🛡️ Último aliento | Una vez por oleada, sobrevives a un golpe mortal |
  | 🧨 Balas explosivas | 10% de que una bala explote en área |
  | 💰 Codicia | +25% monedas |
  | 🔧 Reparador | Mantén E junto a la campana para repararla |

## Armas (Armero)
| Arma | Precio | Estilo |
|---|---|---|
| 🔫 Pistola | gratis | Equilibrada |
| 💥 Escopeta | 300 | 7 perdigones, corto alcance |
| 🪖 Rifle de asalto | 700 | Rápido, cargador de 30 |
| 🎯 Francotirador | 1000 | Daño enorme, atraviesa 4 zombis, mira telescópica |
| ⚙️ Ametralladora | 2000 | 15 disparos/s, cargador de 120 |

Cada arma se mejora 5 veces (+20% daño, +15% cargador, recarga más rápida). Cambio de arma con 1-5.

## Poderes (Bruja)
| Poder | Tecla | Precio | Efecto |
|---|---|---|---|
| 💣 Granada | G | 200 | Explosión en área |
| 🌩️ Rayo en cadena | Q | 400 | Salta entre varios zombis |
| 🔔 Campanazo | F | 500 | Empuja a todos los zombis cercanos a la campana |

## Por qué aguanta cientos de zombis
- Los zombis no son personajes de Roblox (Humanoid): son datos en el servidor.
- Caminan en línea recta hacia un objetivo; servidor y clientes calculan la posición con el reloj del servidor.
  Solo se envía "nació", "recibió daño", "murió" y "cambió de camino" (persigue, vuelve o lo empujaron).
- Máximo 40 zombis persiguiendo a la vez, y se recalcula su camino 4 veces por segundo.
- El cliente mueve todos los sprites de golpe con `workspace:BulkMoveTo`.

## Plan
- **Fase 2 (hecha)**: campana, estilo pixelado, enemigos, jefe, poderes.
- **Fase 3 (hecha)**: movimiento libre, campamento con NPC, armas, tiendas, nivel de cuenta, mejoras, talentos, guardado.
- **Fase 4**: sonidos y música, más mapas (paletas morado/ámbar), más jefes, misiones diarias, pases de juego y lanzamiento.
