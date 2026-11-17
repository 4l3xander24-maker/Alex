-- Pase de temporada (Config.SeasonPass). Todo lo decide el servidor:
--   * XP de temporada: oleadas superadas (vivo y con al menos una baja en esa
--     oleada, así quedarse quieto no sirve), bajas, jefes, misiones diarias y el
--     extra de las misiones. Sin bonos de renacer, VIP, amigos ni potenciadores,
--     y con tope por partida (Xp.MatchCap) para las oleadas, bajas y jefes.
--   * Premium: producto de Robux Monetization.Products.SeasonPass, lo entrega
--     PurchaseService (recibo anotado y guardado antes de confirmar). Si llega
--     una compra y ya era Premium (o la temporada terminó), no se pierde: da
--     DuplicateBoostHours horas de Monedas x2 y XP x2.
--   * Premios: los cobra el jugador desde la pantalla del pase (remote
--     SeasonClaim). El servidor revisa escalón, fila, Premium y que no esté
--     cobrado; uno a la vez por jugador y se guarda al momento.
--   * La XP se publica en el atributo SeasonXp para que el botón se actualice
--     en plena partida (el perfil completo llega al subir de escalón).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local CampBuilder = require(script.Parent.CampBuilder)
local DataService = require(script.Parent.DataService)

local pass = Config.SeasonPass

type MatchState = {
	Xp: number, -- XP de partida ya entregada (cuenta para el tope)
	Exact: number, -- con decimales (las bajas dan 0.1)
	WaveKills: number, -- bajas en la oleada en curso
	Gained: number, -- toda la XP de temporada ganada desde la última partida (para el resumen)
}

local SeasonService = {}

local matches: { [Player]: MatchState } = setmetatable({}, { __mode = "k" }) :: any

local function matchOf(player: Player): MatchState
	local entry = matches[player]
	if not entry then
		entry = { Xp = 0, Exact = 0, WaveKills = 0, Gained = 0 }
		matches[player] = entry
	end
	return entry
end

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function publish(player: Player, season)
	player:SetAttribute("SeasonXp", season.Xp)
end

-- Suma XP de temporada. fromMatch: oleadas, bajas y jefes (con decimales y
-- tope por partida); si no, misiones (enteras, sin tope)
local function addXp(player: Player, amount: number, fromMatch: boolean): number
	local data = DataService.get(player)
	if not data or amount <= 0 or not Progression.seasonOpen(os.time()) then
		return 0
	end
	local entry = matchOf(player)
	local whole
	if fromMatch then
		entry.Exact += amount
		whole = math.min(math.floor(entry.Exact), pass.Xp.MatchCap) - entry.Xp
		if whole <= 0 then
			return 0
		end
		entry.Xp += whole
	else
		whole = math.floor(amount)
	end
	local season = Progression.season(data)
	local before = Progression.seasonTier(season.Xp)
	season.Xp += whole
	entry.Gained += whole
	publish(player, season)
	local after = Progression.seasonTier(season.Xp)
	if after > before then
		DataService.changed(player, "Profile")
		Remotes.Notify:FireClient(player, `{pass.Icon} ¡Escalón {after} del pase de temporada! Toca "Pase" para cobrar`)
	end
	return whole
end

-- Suma tiempo a un potenciador ("Coins" o "Xp") con los mismos relojes que los
-- de Robux: si ya corre, desde donde termina
local function addBoost(player: Player, data, kind: string, seconds: number)
	data.Boosts[kind] = math.max(data.Boosts[kind] or 0, os.time()) + seconds
	player:SetAttribute(`Boost{kind}Until`, data.Boosts[kind])
end

-- Cada baja (desde el manejador de bajas de init)
function SeasonService.onKill(player: Player, isBoss: boolean)
	local entry = matchOf(player)
	entry.WaveKills += 1
	addXp(player, pass.Xp.Kill + (if isBoss then pass.Xp.Boss else 0), true)
end

-- Oleada superada: solo cuenta a quien sigue vivo y mató algo en ella
function SeasonService.onWaveCleared(players: { Player })
	for _, player in players do
		local entry = matchOf(player)
		if entry.WaveKills > 0 and isAlive(player) then
			addXp(player, pass.Xp.Wave, true)
		end
		entry.WaveKills = 0
	end
end

-- Misión diaria cumplida (all = el extra por cumplir las del día)
function SeasonService.onMission(player: Player, all: boolean)
	addXp(player, if all then pass.Xp.AllMissions else pass.Xp.Mission, false)
end

-- Cierra la partida del jugador: devuelve la XP de temporada ganada (para el resumen)
function SeasonService.finishMatch(player: Player): number
	local entry = matches[player]
	matches[player] = nil
	return if entry then entry.Gained else 0
end

-- Compra del Premium (la llama PurchaseService dentro de ProcessReceipt). Si
-- falla lanza error y el recibo queda sin confirmar para que Roblox reintente.
function SeasonService.grantPremium(player: Player)
	local data = DataService.get(player)
	if not data then
		error("Perfil sin cargar")
	end
	local season = Progression.season(data)
	if season.Premium or not Progression.seasonOpen(os.time()) then
		-- El botón no se ofrece en estos casos; si igual llega una compra (dos
		-- ventanas, reintento tardío), se compensa con potenciadores
		local seconds = pass.DuplicateBoostHours * 3600
		addBoost(player, data, "Coins", seconds)
		addBoost(player, data, "Xp", seconds)
		local reason = if season.Premium then "Ya tenías el Premium" else "La temporada ya terminó"
		Remotes.Notify:FireClient(player, `{pass.Icon} {reason}: te damos {pass.DuplicateBoostHours} h de Monedas x2 y XP x2`)
		return
	end
	season.Premium = true
	local ready = Progression.seasonClaimable(data)
	Remotes.Notify:FireClient(player, `{pass.Icon} ¡Pase Premium de {pass.Name} activado!{if ready > 0 then ` Tienes {ready} premios para cobrar` else ""}`)
end

-- Entrega un premio del pase (cosméticos: se ganan para siempre y se ponen)
local function giveReward(player: Player, data, reward)
	if reward.Coins then
		DataService.addCoins(player, reward.Coins)
	end
	if reward.Boost == "Coins" or reward.Boost == "Xp" then
		addBoost(player, data, reward.Boost, pass.BoostMinutes * 60)
	end
	if reward.ObjectSkin then
		local skin = Progression.objectSkinInfo(reward.ObjectSkin)
		if skin then
			data.ObjectSkins[skin.Id] = true
			data.ObjectSkinOn[skin.Kind] = skin.Id
			if skin.Kind == "Campfire" then
				CampBuilder.setFireSkin(skin) -- la fogata es del campamento: se ve al instante
			end
		end
	end
	if reward.WeaponSkin and Progression.weaponSkinInfo(reward.WeaponSkin) then
		data.WeaponSkins[reward.WeaponSkin] = true
		data.WeaponSkin = reward.WeaponSkin
	end
	if reward.Title then
		data.Titles[`Season:{pass.Id}`] = true
		-- Se pone, salvo que lleve un título del Salón de la fama (es único en el mundo)
		local keep = false
		for _, title in Config.Conquest.FirstTitle do
			if data.Title == title then
				keep = true
			end
		end
		if not keep then
			data.Title = reward.Title
		end
	end
end

local claiming: { [Player]: boolean } = {}

local function claim(player: Player, track: string, tier: number): (boolean, string)
	local data = DataService.get(player)
	if not data then
		return false, "Tu perfil aún está cargando"
	end
	local ok, reason = Progression.canClaimSeason(data, track, tier)
	if not ok then
		return false, reason
	end
	local season = Progression.season(data)
	local reward = pass.Rewards[tier][track]
	season.Claimed[Progression.seasonKey(track, tier)] = true
	giveReward(player, data, reward)
	DataService.changed(player, "Profile")
	-- Guardado al momento: un premio cobrado no se repite aunque se caiga el servidor
	DataService.saveNow(player)
	local icon, text = Progression.seasonRewardText(reward)
	return true, `{icon} ¡{text}!`
end

function SeasonService.init()
	Remotes.SeasonClaim.OnServerInvoke = function(player: Player, track: any, tier: any)
		if typeof(track) ~= "string" or typeof(tier) ~= "number" or tier ~= math.floor(tier) then
			return false, "Premio inválido"
		end
		-- Uno a la vez por jugador (el guardado espera a Roblox)
		if claiming[player] then
			return false, "Espera un momento"
		end
		claiming[player] = true
		local ok, done, message = pcall(claim, player, track, tier)
		claiming[player] = nil
		if not ok then
			warn(`Pase de {player.Name}: {done}`)
			return false, "No se pudo cobrar. Inténtalo de nuevo"
		end
		return done, message
	end
end

function SeasonService.onPlayerReady(player: Player)
	local data = DataService.get(player)
	if data then
		publish(player, Progression.season(data))
	end
end

return SeasonService
