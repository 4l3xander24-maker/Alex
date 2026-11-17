-- Pase de temporada (Config.SeasonPass). Todo lo decide el servidor:
--   * XP de temporada: oleadas superadas (vivo y con al menos una baja en esa
--     oleada, así quedarse quieto no sirve), bajas, jefes, misiones diarias y el
--     extra de las misiones. Sin bonos de renacer, VIP, amigos ni potenciadores,
--     y con tope por partida (Xp.MatchCap) para las oleadas, bajas y jefes.
--   * La XP se publica en el atributo SeasonXp para que el botón se actualice
--     en plena partida (el perfil completo llega al subir de escalón).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
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

function SeasonService.onPlayerReady(player: Player)
	local data = DataService.get(player)
	if data then
		publish(player, Progression.season(data))
	end
end

return SeasonService
