-- Reto semanal (Config.Weekly + Shared.Weekly): el modificador de las oleadas
-- cambia cada semana, cada partida sube puntos al ranking de la semana y los 3
-- primeros de la semana pasada cobran su premio al entrar. Quien jugó esa
-- semana y no quedó entre los 3 cobra un premio de participación.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Weekly = require(ReplicatedStorage.Shared.Weekly)
local DataService = require(script.Parent.DataService)
local Leaderboard = require(script.Parent.Leaderboard)

local WeeklyService = {}

-- Sube el puntaje de un jugador (solo se guarda si supera el que ya tenía esa semana)
function WeeklyService.submitPlayer(player: Player, wave: number, difficultyId: number)
	local _, week = Weekly.current()
	Leaderboard.weeklySubmit(week, player.UserId, Weekly.score(wave, difficultyId))
end

-- Al terminar una partida: sube el puntaje de cada jugador de la partida
function WeeklyService.submit(wave: number, difficultyId: number)
	for _, player in Players:GetPlayers() do
		WeeklyService.submitPlayer(player, wave, difficultyId)
	end
end

-- Al cargar el perfil: si quedó entre los 3 primeros de la semana pasada, cobra
-- su premio; si solo jugó, cobra el de participación (una sola vez por semana)
function WeeklyService.onPlayerReady(player: Player)
	local _, week = Weekly.current()
	local previous = week - 1
	local data = DataService.get(player)
	if not data or data.WeeklyClaimed >= previous then
		return
	end
	task.spawn(function()
		local rows = Leaderboard.weeklyTop(previous, #Config.Weekly.Prizes)
		if not rows then
			return -- sin conexión: se intenta la próxima vez
		end
		local place = nil
		for index, row in rows do
			if row.UserId == player.UserId then
				place = index
				break
			end
		end
		-- Fuera del podio: ¿jugó esa semana? Si no se puede consultar, se intenta otra vez
		local score = 0
		if not place then
			local own = Leaderboard.weeklyScore(previous, player.UserId)
			if not own then
				return
			end
			score = own
		end
		local current = DataService.get(player)
		if not current or current.WeeklyClaimed >= previous then
			return
		end
		current.WeeklyClaimed = previous
		if place then
			local prize = Config.Weekly.Prizes[place] or 0
			DataService.addCoins(player, prize)
			Remotes.Notify:FireClient(player, `🏅 Quedaste #{place} en el reto de la semana pasada: +{prize} monedas`)
		elseif score > 0 then
			local prize = Config.Weekly.Participation
			DataService.addCoins(player, prize)
			Remotes.Notify:FireClient(player, `🎖️ Participaste en el reto de la semana pasada: +{prize} monedas`)
		end
		DataService.changed(player, "Profile")
	end)
end

return WeeklyService
