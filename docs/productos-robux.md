# Productos de Robux para crear en Roblox

Crear en create.roblox.com → tu experiencia → Monetización. El precio lo decides tú
(los de abajo son sugerencias). Con el id de cada uno se rellena `Config.Monetization`
en `src/shared/Config.luau` (campo `Id = 0` → el número).

## Pases (se compran una sola vez) — `Config.Monetization.Passes`
| Clave | Nombre | Qué da | Precio sugerido |
|---|---|---|---|
| StarterPack | Pack Inicial | 1000 monedas, pistola de Plata, skin Pionero | 199 R$ |
| DoubleCoins | Monedas x2 | el doble de monedas por zombi, para siempre | 399 R$ |
| Vip | VIP | +25% XP y la skin Dorada | 299 R$ |

## Skins de traje con pase propio — `Config.Monetization.Skins[*].PassId`
Crimson, Royal, Emerald, Shadow, BoneKing, Inferno: un pase por skin.
Sugerido: 99 R$ las comunes (Crimson, Royal), 149 R$ Emerald y Shadow, 249–349 R$ BoneKing e Inferno.

## Productos (se compran muchas veces) — `Config.Monetization.Products`
| Clave | Nombre | Qué da | Precio sugerido |
|---|---|---|---|
| Revive | Revivir | vuelves con la vida llena | 25 R$ |
| Continue | Continuar partida | cuando caen todos o la campana: sigue el equipo | 49 R$ |
| CoinsSmall | Bolsa de monedas | +500 monedas | 49 R$ |
| CoinsBig | Cofre de monedas | +2000 monedas | 149 R$ |
| PetGolem | Gólem de piedra | compañero que aplasta en área | 299 R$ |
| PetPhoenix | Fénix | compañero que lanza fuego | 399 R$ |
| SkinBlood | Skin Sangrienta | skin de arma roja brillante | 99 R$ |
| SkinGalaxy | Skin Galaxia | skin de arma morada brillante | 129 R$ |
| SkinGold | Skin Oro Macizo | skin de arma dorada brillante | 199 R$ |

## Notas
- Los precios en Robux se leen de Roblox: la tienda del juego los muestra sola.
- Hasta que un id sea distinto de 0, ese producto sale como "Pronto" y no se puede comprar.
- Con los ids puestos hay que volver a publicar la Partida y el Lobby.

## Estado
- Los 9 productos (Revivir, Continuar, 2 bolsas, Gólem, Fénix, 3 skins de arma) ya están creados y sus ids puestos en Config (precios: 25, 49, 49, 149, 299, 399, 99, 129, 199 R$; Precios administrados desactivados).
- Los 9 pases también están creados y conectados: Pack Inicial 199, Monedas x2 399, VIP 299, Capa Carmesí 99, Capa Real 99, Caballero Esmeralda 149, Cazador de Sombras 149, Rey de los Huesos 249, Infernal 349 R$.

## Skins de objetos (Premium)
Mina galáctica 79, Mina de oro 129, Reja de fuego 99, Reja de cristal 149, Campana dorada 149 y Campana infernal 199 R$: creadas y conectadas.
Compañero solar 129, Compañero del vacío 149, Rastro de tormenta 79 y Rastro de oro 99 R$: creadas y conectadas.
