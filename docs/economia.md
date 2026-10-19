# Economía de Campana Maldita — análisis y ajustes

Todo son **estimaciones en papel** (modelo en `tools/balance.py` y las cuentas de abajo). Hay que confirmarlas con jugadores reales.

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

## Cuánto cuesta todo
- Armas: 6.700 · Mejoras de armas: 31.400 · Cartuchera: 5.400 · Campana: 5.900 · Poderes: 1.700 → **núcleo ≈ 51.000**
- Compañeros 6.900 y skins/cosméticos: otros 40.000+ (largo plazo).

Si todas las partidas se completaran, el núcleo saldría en ~29 partidas (~19 con Botín/Codicia, ~10 con el pase x2). **No se completan todas:** se pierde mucho, sobre todo en Experto o más, así que en la práctica son 60–80 partidas (≈12–16 horas), y el pase x2 las acorta a la mitad.

## Qué cambió en esta ronda
1. **Menos monedas por zombi:** x0,45 de lo original (`Economy.KillCoinScale`).
2. **Mejoras de armas más caras arriba:** factores de costo 0,35 / 0,5 / 0,75 / 1,2 / 1,8 (antes 0,35 / 0,5 / 0,7 / 1,0 / 1,3). Los niveles 4 y 5 cuestan bastante más.
3. **Cartuchera y refuerzo de campana:** niveles altos más caros.
4. **Maestría (candados):** subir al nivel alto exige haber superado una dificultad.
   - Armas: niveles 1–3 libres; el nivel 4 pide superar **Normal** y el 5, **Difícil**.
   - Cartuchera y campana: niveles 5–6 piden superar **Normal**; 7–8, **Difícil**.
   - (Ajustado: antes pedían una dificultad más; ahora el primer candado llega más tarde y con una meta alcanzable.)
   - Así no basta con juntar monedas: hay que mejorar el juego para pasar el siguiente reto. Es el motivo para volver a intentar.
5. **Premio por completar** la dificultad cada vez (120 / 250 / 450 / 800 / 1.400), además del premio de la primera vez.
6. **Consuelo al perder:** 10 monedas por oleada superada (por el multiplicador de la dificultad). Perder nunca deja en cero.

## Cosas que NO toqué (y por qué)
- **Puntos de estadística:** salen del nivel de cuenta, que crece exponencialmente (~9 partidas al nivel 20, cientos al 50). Ya frena solo.
- **Precios de Robux y skins:** los fija Creator Hub.
- **Pase x2 de monedas:** acelera a todos, pero no abre nada que no se pueda ganar jugando, y los candados de maestría siguen valiendo.

## Qué mirar en las primeras pruebas
- ¿Cuántas partidas tarda alguien en comprar su 2.ª arma? Meta: 2–4.
- ¿Se siente injusto el candado del nivel 3 (superar Normal)? Si cuesta más de 5 intentos, hay que bajar el reto de Normal, no quitar el candado.
- ¿Qué porcentaje completa Normal? Meta: 50–70% en los primeros 5 intentos.
- ¿Sigue jugando quien perdió 3 veces seguidas? Si no, subir el consuelo.
