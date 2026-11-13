# Economía de Campana Maldita — análisis y ajustes

Todo son **estimaciones en papel** (modelo en `tools/balance.py` y las cuentas de abajo). Hay que confirmarlas con jugadores reales.

> **Valores actuales (noviembre):** las ganancias se bajaron a propósito para que queden niveladas con el costo de
> las mejoras. En `Config.Economy` hoy rige: monedas por zombi **x0,25** (`KillCoinScale`), premio por completar
> **80 / 170 / 320 / 560 / 980** (`ClearBonus`) y consuelo de **5 monedas por oleada** (`ParticipationPerWave`).
> Las tablas y cuentas de abajo son de la ronda anterior (x0,45, premio 120 y consuelo 10): con los valores de hoy
> una partida Normal completa paga aproximadamente la mitad de lo que dice la tabla (estimado, sin medir en juego).
> Los jugadores nuevos empiezan con 150 monedas y la racha diaria suma hasta 625 por semana.

## Qué queremos que se sienta
1. **Primera sesión (30 min):** comprar la primera arma nueva y 2–3 mejoras. Sensación de "avanzo rápido".
2. **Primeros días:** cada partida acerca algo concreto; perder también da algo.
3. **Semanas:** lo mejor exige **superar dificultades**, no solo juntar monedas. Ese es el reto que invita a seguir intentando.
4. **Largo plazo:** skins, compañeros y títulos como metas de colección.

## Cuánto se gana por partida (sin multiplicadores)
| Dificultad | La completas | Caes a mitad | Caes en la oleada 3 |
|---|---|---|---|
| Normal | ~830 | ~200 | ~100 |
| Difícil | ~1.560 | ~310 | ~120 |
| Experto | ~2.200 | ~480 | ~135 |
| Pesadilla | ~3.680 | ~770 | ~170 |
| Infierno | ~6.370 | ~1.360 | ~250 |

Multiplicadores: Botín (hasta +50%) y Codicia (+25%) ≈ x1,5; el pase de monedas x2 multiplica por encima.
Amigos de Roblox en la partida: +10% de monedas de bajas y de XP por amigo, tope +30% (`Config.Friends`); se multiplica con lo anterior y solo pasa jugando en grupo.

## Cuánto cuesta todo
- Armas: 6.700 · Mejoras de armas: 31.400 · Mochila: 1.910 · Campana: 5.900 · Poderes: 1.700 → **núcleo ≈ 51.000**
- Compañeros 6.900 y skins/cosméticos: otros 40.000+ (largo plazo).

Si todas las partidas se completaran, el núcleo saldría en ~29 partidas (~19 con Botín/Codicia, ~10 con el pase x2). **No se completan todas:** se pierde mucho, sobre todo en Experto o más, así que en la práctica son 60–80 partidas (≈12–16 horas), y el pase x2 las acorta a la mitad.

## Qué cambió en esta ronda
1. **Menos monedas por zombi:** x0,45 de lo original (`Economy.KillCoinScale`).
2. **Mejoras de armas más caras arriba:** factores de costo 0,35 / 0,5 / 0,75 / 1,2 / 1,8 (antes 0,35 / 0,5 / 0,7 / 1,0 / 1,3). Los niveles 4 y 5 cuestan bastante más.
3. **Mochila de suministros** (antes cartuchera): ahora cura al empezar cada oleada (10–30%) y da escudo corto cada 2 oleadas desde el nivel 3; 5 niveles, 80–850 monedas. Refuerzo de campana: niveles altos más caros.
4. **Maestría (candados):** subir al nivel alto exige haber superado una dificultad.
   - Armas: niveles 1–3 libres; el nivel 4 pide superar **Normal** y el 5, **Difícil**.
   - Mochila: nivel 4 pide superar **Normal** y el 5 **Difícil**. Campana: niveles 5–6 piden **Normal**; 7–8, **Difícil**.
   - (Ajustado: antes pedían una dificultad más; ahora el primer candado llega más tarde y con una meta alcanzable.)
   - Así no basta con juntar monedas: hay que mejorar el juego para pasar el siguiente reto. Es el motivo para volver a intentar.
5. **Premio por completar** la dificultad cada vez (120 / 250 / 450 / 800 / 1.400), además del premio de la primera vez.
6. **Consuelo al perder:** 10 monedas por oleada superada (por el multiplicador de la dificultad). Perder nunca deja en cero.

## Misiones diarias y racha
- **Día de juego:** cambia a las 9:00 UTC (`DailyRules.ResetHourUtc`), de madrugada en Latinoamérica, no a medianoche UTC.
- **Misiones:** cada día salen 3 de un grupo de 10 (`Config.DailyMissions`), las mismas para todos; pagan 150–500 monedas cada una. Cumplir las 3 da +150 (`DailyRules.AllBonus`) una vez al día.
- **Racha de entrada:** 40 / 50 / 60 / 75 / 90 / 110 / 200 monedas (días 1 a 7, luego se repite). Una semana completa son **625 monedas**: menos que ganar Normal una vez (~830) y ~1% del núcleo (~51.000), así que es un motivo para volver, no un atajo. El día 7 casi triplica el 1 para que valga la pena no faltar. Faltar un día reinicia la racha.

## Premios extra pequeños
- **Códigos de regalo** (`src/server/GiftCodes.luau`): una vez por cuenta y código; los de inicio dan 200 y 100 monedas (menos que una partida de Normal).
- **Participación semanal:** 100 monedas (`Config.Weekly.Participation`) a quien sumó puntos en la semana y no entró al podio (1500 / 1000 / 600), una vez por semana.

## Colección del bestiario
Maestría por enemigo (`Config.Collection`, una sola vez por cuenta): comunes 5 / 15 / 40 monedas (bronce / plata / oro, a 10 / 100 / 500 bajas) y jefes 15 / 40 / 100 (a 1 / 5 / 20 bajas). Completar un nivel con todos los enemigos paga 100 / 300 / 800 y el oro da el título «Maestro del Bestiario».
Con 10 comunes y 5 jefes: 600 + 775 + 1.200 = **2.575 monedas** en total (~5% del núcleo). Cada enemigo nuevo suma 60 (común) o 155 (jefe). El oro de los comunes pide cientos de bajas y el del Segador, que solo sale en su semana, es de largo plazo.

## Cosas que NO toqué (y por qué)
- **Puntos de estadística:** salen del nivel de cuenta, que crece exponencialmente (~9 partidas al nivel 20, cientos al 50). Ya frena solo.
- **Precios de Robux y skins:** los fija Creator Hub.
- **Pase x2 de monedas:** acelera a todos, pero no abre nada que no se pueda ganar jugando, y los candados de maestría siguen valiendo.

## Qué mirar en las primeras pruebas
- ¿Cuántas partidas tarda alguien en comprar su 2.ª arma? Meta: 2–4.
- ¿Se siente injusto el candado del nivel 3 (superar Normal)? Si cuesta más de 5 intentos, hay que bajar el reto de Normal, no quitar el candado.
- ¿Qué porcentaje completa Normal? Meta: 50–70% en los primeros 5 intentos.
- ¿Sigue jugando quien perdió 3 veces seguidas? Si no, subir el consuelo.
