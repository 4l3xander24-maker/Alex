-- Sonidos y música del juego. Son audios públicos de la Creator Store de las
-- librerías con licencia de Roblox (ProSoundEffects y APM), así que funcionan
-- en cualquier experiencia sin subir nada.
-- Cada sonido: Id, Volume y opcionalmente Pitch (o PitchRange para variar),
-- Ids (varios, se elige uno al azar) y Distance (alcance en studs si suena en
-- el mundo).
return {
	-- Armas (al disparar, en primera persona)
	Weapons = {
		Machete = { Id = 9119751604, Volume = 0.5, PitchRange = { 1.05, 1.25 } },
		Pistol = { Id = 9117402631, Volume = 0.45, PitchRange = { 0.95, 1.05 } },
		Shotgun = { Id = 9112913564, Volume = 0.6, PitchRange = { 0.95, 1.05 } },
		Rifle = { Id = 9118173988, Volume = 0.45, PitchRange = { 0.97, 1.05 } },
		Sniper = { Id = 9113198012, Volume = 0.65, Pitch = 0.8 },
		Minigun = { Id = 9116344855, Volume = 0.3, PitchRange = { 1.0, 1.1 } },
	},
	Reload = { Id = 9113104176, Volume = 0.5 },
	HitMarker = { Id = 9113632114, Volume = 0.35, PitchRange = { 1.1, 1.3 } },
	PlayerHurt = { Id = 9118167124, Volume = 0.6, PitchRange = { 0.9, 1.1 } },

	-- Zombis (suenan en el mundo, más bajo cuanto más lejos)
	ZombieGroan = { Ids = { 9113980480, 9113980319, 9113985604 }, Volume = 0.55, PitchRange = { 0.55, 0.75 }, Distance = 90 },
	ZombieDeath = { Ids = { 9113607285, 9113607683 }, Volume = 0.6, PitchRange = { 0.8, 1.0 }, Distance = 80 },
	BossRoar = { Id = 9113980507, Volume = 1, Pitch = 0.5, Distance = 400 },

	-- Poderes y trampas
	Explosion = { Id = 9114224354, Volume = 0.8, PitchRange = { 0.9, 1.05 }, Distance = 200 },
	SmallExplosion = { Id = 9114224354, Volume = 0.35, PitchRange = { 1.4, 1.6 }, Distance = 80 },
	Lightning = { Id = 9114277757, Volume = 0.6, PitchRange = { 0.9, 1.1 }, Distance = 150 },
	BellToll = { Id = 9114352428, Volume = 0.9, Distance = 500 },

	-- Campana y partida
	BellHit = { Id = 9113449851, Volume = 0.4, PitchRange = { 0.6, 0.8 }, Distance = 150 },
	Rebuild = { Id = 9114755635, Volume = 0.6 },
	LevelUp = { Id = 1836473422, Volume = 0.5 },
	Coins = { Id = 9113849651, Volume = 0.5 },

	-- Música según el momento de la partida (en bucle)
	Music = {
		Lobby = { Id = 1839906422, Volume = 0.25 },
		Wave = { Id = 9047425352, Volume = 0.3 },
		Boss = { Id = 1846862303, Volume = 0.35 },
		GameOver = { Id = 1836102253, Volume = 0.3 },
	},
	MusicFade = 2, -- segundos para pasar de una canción a otra
	-- Viento de fondo, siempre sonando bajito
	Ambience = { Id = 9114228832, Volume = 0.15 },
	-- Cada cuántos segundos gruñe algún zombi cercano durante las oleadas
	GroanInterval = { 2.5, 5 },
}
