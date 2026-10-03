# Diseño del juego

## La idea en una frase
Defiendes una **campana** junto a tu **campamento**, al borde de un acantilado sobre el mar, mientras hordas de
muertos vivientes llegan en oleadas por dos caminos, en una noche de la Edad Media. Empiezas con un machete y una pistola. Antes de cada partida
compras armas, mejoras, poderes y trampas a los NPC, y al terminar ganas **XP de cuenta** para subir de nivel,
mejorar tus estadísticas y aprender talentos.

## Estilo visual
- **Pixel art 3D** (`Config.ArtStyle = "Voxel"`): todo de cubos con colores planos (SmoothPlastic). Las bolas y
  cilindros del mapa se vuelven bloques. Suelo de baldosas de 8 studs en varios tonos con flores y matas de
  cubitos; caminos escalonados de tierra y de piedra (en damero); acantilado de columnas de roca; mar azul con
  espuma. Fuego de cubitos que bailan, nubes de bloques, luciérnagas de cubitos, explosiones cúbicas, sombras
  nítidas sin desenfoque y letra pixelada (Arcade) en oleada, munición y monedas.
- **Ciclo de día y noche** (`Config.DayCycle`, 10 minutos por día): cada cliente calcula la hora con el reloj del
  servidor y mezcla tres paletas (día, atardecer y noche): brillo, luz ambiente, atmósfera, tinte, estrellas,
  color de las nubes. De día las velas y antorchas alumbran un 25%; de noche, todo. De noche llegan 30% más
  zombis por segundo (`NightSpawnMultiplier`). Amanecer 4:30-7:00, atardecer 17:00-19:30.
- Mundo 3D de **bloques** sobre **Terrain** de Roblox con pasto 3D (`Terrain.Decoration`).
- Iluminación **Future** (sombras suaves y luces reales), `Atmosphere` con bruma, rayos de sol y
  desenfoque de fondo.
- Por defecto, **noche medieval** (`Config.Theme = "Medieval"`): luna enorme, estrellas, bruma azul, velas y
  antorchas que parpadean, casas con entramado de madera, cripta, ruinas de castillo, estandartes y árboles secos.
- Otros temas: **otoño de día** (`"Otono"`, inspirado en la imagen "Super Upsampler" de Roblox) y noches de
  color: verde (bosque), morado (pantano), ámbar (atardecer).
- Zombis de **dibujo animado** en 3D de bloques (`Config.ZombieStyle = "3D"`), como las imágenes de referencia:
  piel verde, ojos blancos enormes (uno más grande), boca abierta con dientes, camisa blanca rota y jean azul.
  Caminan, balancean los brazos y golpean. Alternativa: sprites pixelados 2D con el mismo estilo (`"Pixel"`).
- **Muerte pixelada**: destello blanco, la cabeza sale volando, el cuerpo se desarma y cada pedazo revienta en
  cubitos (verdes, del color de la ropa y rojos) que rebotan y se achican. Queda una mancha verde que se borra.
- 5 armas de bloques en primera persona con manos, retroceso, destello y mira telescópica.

## El mapa
- **Campanario** (en el centro, al frente): lo que hay que defender. Tiene rampa y baranda; desde arriba los zombis
  no te alcanzan, pero tampoco proteges a la campana de cerca.
- **Campamento** (detrás): fogata con bancos, 4 tiendas de campaña, empalizada de troncos y faroles.
- **Acantilado y mar** (detrás del campamento): cerca de madera, mirador con catalejo. Caer al mar = morir.
- **NPC del campamento** (se habla con ellos con **E**):
  | NPC | Puesto | Qué vende |
  |---|---|---|
  | Bruno, el Armero | Armería | Armas nuevas, mejoras de arma (5 niveles, cambian el color), equipar |
  | Morgana, la Bruja | Caldero | Poderes y sus mejoras |
  | Don Ramiro, el Veterano | Campo de entrenamiento | Puntos de mejora y talentos |
  | Gustavo, el Intendente | Intendencia | Cartuchera (más balas) y trampas: minas y rejas |
- **Caminos** (al frente): dos caminos angostos (8 studs) hasta la campana, con antorchas y velas a los lados.
  - **Camino del cementerio** (tierra, `Main`): empieza en una cripta rodeada de tumbas y reja de hierro.
    Lo usan 3 de cada 4 zombis.
  - **Camino de las ruinas** (piedra, `Side`): empieza en el arco de un castillo en ruinas con una torre partida.
  - Cada zombi va un poco desviado del centro (hasta 2.5 studs) para que la horda no parezca una fila.
- **Aldea**: casas con ventanas encendidas, pozo y carreta a los lados del campo.

## Ciclo de juego
0. **Preparación** (hasta 2 minutos): el único momento para comprar en el campamento. Termina cuando alguien
   toca la campana (mantener E) o se acaba el tiempo. Durante la partida las tiendas están cerradas.
1. **Entre oleadas** hay 12 segundos de respiro (sin tiendas).
2. **Oleada**: los zombis van a la campana. Si te acercas a menos de 22 studs te persiguen y te atacan;
   si te alejas más de 45, vuelven a su camino. Cada 5 oleadas salen jefes (ver abajo).
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

## Munición
- Cada arma de fuego tiene **cargador** y **reserva**. Recargar pasa balas de la reserva al cargador.
- Empiezas cada partida con la reserva inicial de cada arma.
- **Cada zombi eliminado te da balas** para el arma que tienes en la mano (o la última que usaste si lo
  mataste con el machete), hasta el máximo de reserva.
- La **cartuchera** del Intendente (8 niveles) sube un 25% por nivel el máximo y las balas iniciales.

## Trampas (Intendente, duran una partida)
| Trampa | Precio | Efecto |
|---|---|---|
| 🪤 Mina (hasta 8) | 40 | Explota cuando pasa un zombi (12 de daño en 10 studs, crece con la oleada) |
| 🚧 Reja del cementerio / de las ruinas | 150 c/u | Cierra ese camino a 36 studs de la campana: los zombis se paran a romperla (800 de vida); no persiguen a quien está detrás. El dragón pasa volando |

## Zombis
| Zombi | Desde la oleada | Cómo es |
|---|---|---|
| Zombi | 1 | El clásico: camisa blanca rota y jean azul |
| Corredor | 2 | Flaco, sin camisa y encorvado; rápido pero débil |
| Zombi con cono | 2 | Un cono de tránsito en la cabeza; aguanta más del doble |
| Bruto | 3 | Gordo y grande; pega fuerte |
| Caballero zombi | 4 | Yelmo, peto y ojos rojos; resistente |

## Jefes (6 veces más grandes)
Cada 5 oleadas: la 5 trae al **Gordo**, la 10 al **Rey** y al **Dragón**, la 15 a los tres... (uno más cada vez,
separados 6 segundos). Arriba de la pantalla aparece su barra de vida.

| Jefe | Vida | Qué hace |
|---|---|---|
| 🤢 Zombi Gordo | 150 | Lento; al morir revienta y suelta 8 zombis |
| 👑 Rey Zombi | 220 | Corona, capa y golpes fuertes |
| 🐉 Dragón Zombi | 300 | Vuela recto a la campana a 30 de altura (ignora caminos, rejas y minas) y le escupe fuego verde |

La vida de todos crece 12% por oleada. Las balas golpean a los jefes en todo el cuerpo (de los pies a la cabeza).

## Armas (Armero)
Cada mejora cambia el color del arma: Normal → Bronce → Plata → Oro → Esmeralda (brilla) → Legendaria (brilla).

| Arma | Precio | Estilo |
|---|---|---|
| 🔪 Machete | gratis | Cuerpo a cuerpo, sin munición, hasta 3 zombis por tajo |
| 🔫 Pistola | gratis | Equilibrada |
| 💥 Escopeta | 300 | 7 perdigones, corto alcance |
| 🪖 Rifle de asalto | 700 | Rápido, cargador de 30 |
| 🎯 Francotirador | 1000 | Daño enorme, atraviesa 4 zombis, mira telescópica |
| ⚙️ Ametralladora | 2000 | 15 disparos/s, cargador de 120 |

Cada arma se mejora 5 veces (+20% daño, +15% cargador, recarga más rápida). Cambio de arma con 1-6.

## Poderes (Bruja)
| Poder | Tecla | Precio | Efecto |
|---|---|---|---|
| 💣 Granada | G | 200 | Explosión en área |
| 🌩️ Rayo en cadena | Q | 400 | Salta entre varios zombis |
| 🔔 Campanazo | F | 500 | Empuja a todos los zombis cercanos a la campana |

## Por qué aguanta cientos de zombis
- Los zombis no son personajes de Roblox (Humanoid): son datos en el servidor.
- Caminan por una línea quebrada (los puntos de su camino); servidor y clientes calculan la posición con el
  reloj del servidor.
  Solo se envía "nació", "recibió daño", "murió" y "cambió de camino" (persigue, vuelve o lo empujaron).
- Máximo 40 zombis persiguiendo a la vez, y se recalcula su camino 4 veces por segundo.
- El cliente mueve todos los zombis de golpe con `workspace:BulkMoveTo`.
- Los avisos de nacer, daño y muerte se juntan en un solo mensaje por fotograma.
- El cliente no dibuja los zombis que están detrás de la cámara y no anima los lejanos.
- **StreamingEnabled**: cada jugador recibe solo lo cercano; las montañas son `Persistent`.
- Efectos según la calidad gráfica: en calidad baja o celular se apagan el desenfoque, los rayos y las hojas.

## Plan
- **Fase 2 (hecha)**: campana, estilo pixelado, enemigos, jefe, poderes.
- **Fase 3 (hecha)**: movimiento libre, campamento con NPC, armas, tiendas, nivel de cuenta, mejoras, talentos, guardado.
- **Fase 3.5 (hecha)**: machete, munición de reserva y balas por baja, Intendente (cartuchera y trampas),
  colores por mejora, acantilado y mar, preparación antes de la partida.
- **Fase 3.6 (hecha)**: gráficos de otoño, zombis 3D animados y optimización.
- **Fase 3.8 (hecha)**: pixel art 3D y ciclo de día y noche.
- **Fase 3.7 (hecha)**: noche medieval con velas, dos caminos, zombis de dibujo animado, jefes gigantes
  (Gordo, Rey y Dragón) y muerte pixelada.
- **Fase 4**: sonidos y música, más mapas (paletas morado/ámbar), más jefes, misiones diarias, pases de juego y lanzamiento.
