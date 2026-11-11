-- Códigos de regalo. Viven solo en el servidor (no en Shared) para que ningún
-- cliente pueda leer la lista. Para agregar uno, añade una fila a List:
--   Code = el texto (se compara sin importar mayúsculas)
--   Coins = monedas que da
--   Until = (opcional) vence en esa fecha, en segundos UTC (os.time); sin Until no vence
--   ObjectSkin = (opcional) id de una skin de Config.ObjectSkins que regala
-- Cada jugador canjea cada código una sola vez (queda en su perfil, Codes).
return {
	Cooldown = 2, -- segundos mínimos entre un intento y otro
	MaxFails = 5, -- intentos fallidos seguidos antes del bloqueo
	Lockout = 60, -- segundos de bloqueo después de fallar MaxFails veces
	List = {
		{ Code = "BIENVENIDO", Coins = 200 },
		{ Code = "CAMPANA", Coins = 100 },
	},
}
