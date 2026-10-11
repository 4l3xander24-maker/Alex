-- Lleva la cuenta de cada jugador durante la partida (oleadas, bajas,
-- monedas) y al terminar le da la XP de cuenta con un resumen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local Leaderboard = require(script.Parent.Leaderboard)

type MatchStats = {
	Kills: number,
	BossKills: number,
	Coins: number,
	Waves: number,
}

local MatchService = {}

local stats: { [Player]: MatchStats } = {}

local function ensure(player: Player): MatchStats
	local entry = stats[player]
	if not entry then
		entry = { Kills = 0, BossKills = 0, Coins = 0, Waves = 0 }
		stats[player] = entry
	end
	return entry
end

function MatchService.getXp(entry: MatchStats): number
	local progression = Config.Progression
	return entry.Waves * progression.XpPerWave + entry.Kills * progression.XpPerKill + entry.BossKills * progression.XpPerBossKill
end

-- El HUD muestra cuánta XP llevas ganada en esta partida
local function publish(player: Player, entry: MatchStats)
	player:SetAttribute("MatchXp", MatchService.getXp(entry))
	player:SetAttribute("MatchKills", entry.Kills)
end

function MatchService.onKill(player: Player, isBoss: boolean, coins: number)
	local entry = ensure(player)
	entry.Kills += 1
	entry.Coins += coins
	if isBoss then
		entry.BossKills += 1
	end
	publish(player, entry)
end

function MatchService.onWaveCleared()
	for _, player in Players:GetPlayers() do
		local entry = ensure(player)
		entry.Waves += 1
		publish(player, entry)
	end
end

-- Da la XP de la partida. Si el jugador sigue conectado, le manda el resumen.
function MatchService.award(player: Player, wave: number)
	local entry = stats[player]
	stats[player] = nil
	if not entry then
		return
	end
	local xp = MatchService.getXp(entry)
	local levels = if xp > 0 then DataService.addXp(player, xp) else 0
	local data = DataService.get(player)
	local previousBest = if data then data.BestWave else 0
	local newRecord = data ~= nil and entry.Waves > previousBest
	if data and newRecord then
		data.BestWave = entry.Waves
		DataService.changed(player, "Record")
	end
	-- Ranking global que se ve en el lobby
	if data then
		data.TotalKills += entry.Kills
		Leaderboard.submit(player.UserId, "BestWave", data.BestWave)
		Leaderboard.submit(player.UserId, "Kills", data.TotalKills)
	end
	if player.Parent and data then
		player:SetAttribute("MatchXp", 0)
		player:SetAttribute("MatchKills", 0)
		Remotes.MatchSummary:FireClient(player, {
			Wave = wave,
			Waves = entry.Waves,
			Kills = entry.Kills,
			BossKills = entry.BossKills,
			Coins = entry.Coins,
			Xp = xp,
			Levels = levels,
			Level = data.Level,
			StatPoints = data.StatPoints,
			TalentPoints = data.TalentPoints,
			BestWave = data.BestWave,
			PreviousBest = previousBest,
			NewRecord = newRecord,
		})
	end
end

function MatchService.endMatch(wave: number)
	-- Todos reciben el resumen (y la votación), aunque no hayan matado nada
	for _, player in Players:GetPlayers() do
		ensure(player)
	end
	for player in stats do
		MatchService.award(player, wave)
	end
end

return MatchService
