# Analíticas: dónde mirar y qué significa cada cosa

El juego le cuenta a Roblox qué hacen los jugadores (sin nombres ni nada personal). Todo se ve en
**Creator Hub → Creaciones → Campana Maldita → Analytics**. Los datos tardan unas horas en aparecer (a veces
hasta un día) y lo que pasa en Studio no cuenta: hay que mirar el juego publicado.

El código está en `src/server/Analytics.luau` (lo usan el Lobby y la Partida). Si Roblox falla, el juego sigue
igual: las analíticas nunca frenan una partida.

## 1. Embudo de bienvenida (Funnels → Onboarding)

Cuenta **la primera vez** de cada jugador nuevo, paso a paso. Sirve para ver **dónde se van los nuevos**: si
del paso 4 al 5 se pierde mucha gente, algo de la preparación confunde.

| Paso | Nombre | Qué pasó |
|---|---|---|
| 1 | Entró al Lobby | Abrió el juego y apareció en la plaza |
| 2 | Entró a una sala | Se paró en un círculo de runas |
| 3 | Viaja a la partida | Terminó la cuenta y el grupo salió hacia la partida |
| 4 | Llegó a la partida | Cargó su perfil en la partida (todavía sin ninguna partida terminada) |
| 5 | Reconstruyó la campana | Se eligió la dificultad y empezó la partida |
| 6 | Superó la oleada 1 | |
| 7 | Superó la oleada 3 | |
| 8 | Primera compra | Gastó monedas por primera vez (arma, trampa, mascota…) |
| 9 | Terminó su primera partida | Llegó al resumen final (ganando o perdiendo) |
| 10 | Primera victoria | Superó la oleada meta por primera vez |

Los pasos 4 a 8 solo cuentan mientras el jugador nunca terminó una partida. El paso 8 puede pasar antes del 5
(comprar en la preparación): es normal.

## 2. Embudo de cada partida: «Partida» (Funnels → Recurring)

Se repite en **cada partida** (cada una con su propio id). Sirve para ver **hasta dónde llegan los equipos**.

| Paso | Nombre | Qué pasó |
|---|---|---|
| 1 | Empezó | Se reconstruyó la campana |
| 2 | Llegó a la oleada 3 | |
| 3 | Llegó a la oleada 5 | |
| 4 | Venció una oleada de jefe | Superó la primera oleada con jefes (cada 5 oleadas) |
| 5 | Llegó a la oleada meta | La última de la dificultad (8 en Normal, 10 en Difícil…) |
| 6 | Victoria | Superó la oleada meta |
| 7 | Eligió seguir (sin fin) | El equipo votó seguir jugando después de ganar |

Si mucha gente llega a la 3 pero poca a la 5, el primer jefe o el mini-jefe pueden estar muy duros.

## 3. Economía (Economy)

La moneda se llama **Monedas**. Cada entrada es una **fuente** (Source) y cada gasto un **sumidero** (Sink), con el
saldo que quedó. Ahí se ve si entran demasiadas monedas o si nadie compra algo.

**De dónde salen** (columna de tipo de transacción entre paréntesis):
- `Zombi` (Gameplay): monedas por bajas. Se juntan y se mandan de a una vez por minuto, no una por zombi.
- `Oleadas` (Gameplay): el consuelo por oleadas superadas al terminar.
- `Objetivo`, `JefeFinal`, `Dificultad`, `Conquista`, `Logro`, `Bestiario` (Gameplay).
- `Mision`, `Racha`, `Semanal`, `Pase` (TimedReward): misiones diarias, racha de días, reto semanal y pase de temporada.
- `Codigo`, `Referido` (Onboarding): códigos de regalo e invitar amigos.
- `Robux`, `PackInicial`, `ReembolsoRobux` (IAP): packs de monedas con Robux, el Pack Inicial y la devolución cuando
  un Revivir/Continuar ya no hacía falta.
- `Reembolso` (Shop): se devolvió una compra de skin que no se pudo guardar.

**En qué se gastan** (el nombre es `Categoría_Id`; en la tabla sale como item):
- Tiendas (Shop): `Arma_…`, `MejoraArma_…`, `Poder_…`, `MejoraPoder_…`, `Mochila`, `RefuerzoCampana`, `Puente`,
  `Mascota_…`, `SkinArma_…`, `SkinObjeto_…`, `SkinPersonaje`.
- En el terreno (ContextualPurchase): `Trampa_Mina`, `Trampa_Reja`, `Trampa_MejoraMina`, `Trampa_MejoraReja`.

Los puntos de estadística y los talentos no cuestan monedas, por eso no salen.

## 4. Eventos propios (Custom Events)

Pocos y sin datos personales. Cada uno tiene un número (value) y hasta 3 campos con forma `Nombre - valor`.

| Evento | Número | Campos | Cuándo |
|---|---|---|---|
| `MatchEnded` | oleadas superadas | Dificultad, Jugadores, Ganó (Sí/No) | Al terminar cada partida, uno por jugador |
| `DifficultySelected` | id de la dificultad (1 a 5) | Dificultad | Al empezar cada partida, uno por jugador |
| `Rebirth` | veces que renació | | Al renacer con el Veterano |
| `SeasonPremium` | 1 | | Al comprar el Premium del pase |
| `SeasonTierClaimed` | escalón | Fila (Gratis/Premium) | Al cobrar un premio del pase |
| `CodeRedeemed` | monedas que dio | | Al canjear un código (nunca se manda el texto) |
| `RobuxProductBought` | 1 | Producto (nombre en `Config.Monetization.Products`) | Al entregar una compra con Robux |

## Qué mirar primero
- **Bienvenida, pasos 4 → 6:** ¿los nuevos entienden cómo empezar y aguantan la primera oleada?
- **Partida, pasos 1 → 5 en Normal:** ¿cuántos equipos llegan a la meta? (la meta es 50–70%, ver `docs/economia.md`).
- **Economía:** ¿qué sumideros casi no se usan? ¿El saldo medio crece sin parar? Eso significa que no hay en qué gastar.
- **`Referido`:** cuántas monedas salen por invitar amigos (cada amigo nuevo que termina su primera partida da 150 en total).
