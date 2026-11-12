# Insignias de Roblox

Las insignias salen en el perfil del jugador y son publicidad gratis para el juego.
El servidor las da solo (`src/server/Insignias.luau`) cuando se cumple el hito; el
cliente no puede pedirlas. Funcionan igual que los productos de Robux: con `Id = 0`
están apagadas, y al pegar el id en `Config.Badges` (`src/shared/Config.luau`) se encienden.
Hay que volver a publicar la Partida (las insignias se dan solo desde la Partida).

## Lista (nombre y descripción para copiar en Creator Hub)
| Clave en Config | Nombre | Descripción | Cuándo se da |
|---|---|---|---|
| FirstMatch | Primera guardia | Termina tu primera partida defendiendo la campana. | Al terminar una partida (no al salirte a la mitad) |
| FirstVictory | Campana a salvo | Supera la oleada meta de una dificultad por primera vez. | Al superar la oleada meta, en cualquier dificultad |
| Wave10 | Resistencia | Llega a la oleada 10 en una sola partida. | Al superar 10 oleadas en la misma partida |
| FirstBoss | Cazajefes | Derrota a tu primer jefe. | Al matar un jefe |
| Kills1000 | Mil zombis | Elimina 1000 zombis en total. | Cuando bajas acumuladas + las de la partida llegan a 1000 |
| ClearHard | Duro de roer | Supera la dificultad Difícil. | Al superar la meta de Difícil |
| ClearExpert | Experto en zombis | Supera la dificultad Experto. | Al superar la meta de Experto |
| HallOfFame | Salón de la fama | Sé el primer jugador del mundo en superar una dificultad y entra al Salón de la fama. | Al entrar al Salón de la fama |
| Streak7 | Una semana fiel | Juega 7 días seguidos y llega a la racha de 7 días. | Al llegar al día 7 de racha |

## Cómo crearlas
1. Entra a create.roblox.com y abre **Creations**.
2. Elige la experiencia (Campana Maldita).
3. En el menú de la experiencia abre **Associated Items** y luego **Badges**.
4. Pulsa **Create a Badge**, sube un icono (cuadrado), pon el nombre y la descripción de la tabla de arriba y activa **Badge enabled**. Crear insignias puede tener costo en Robux (Roblox lo muestra al crearlas).
5. Copia el id de la insignia (aparece en su página y en la URL).
6. Pega el id en `Config.Badges`, en el campo `Id` de la clave que corresponde (reemplaza el `0`).
7. Vuelve a publicar la Partida.

## Notas
- Una insignia con `Id = 0` no hace nada: se puede ir encendiendo de a una.
- Cada insignia se pide una sola vez por jugador y sesión del servidor; Roblox ignora las repetidas.
- Un id equivocado no rompe nada: la llamada va dentro de `pcall` y solo deja un aviso en la consola del servidor.
