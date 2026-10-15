-- Partida que viene del Lobby (servidor reservado): al terminar, todos
-- vuelven al Lobby. Si se entró directo a este lugar (o en Studio), la
-- partida se repite aquí mismo como siempre.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local MatchRegistry = require(ReplicatedStorage.Shared.MatchRegistry)

local LobbyReturn = {}

-- Jugadores que se van al Lobby a propósito (no cuentan como desconexión)
local leaving: { [Player]: boolean } = {}

function LobbyReturn.isLeaving(player: Player): boolean
	return leaving[player] == true
end

-- Mientras la partida siga viva marca "sigo aquí" para que los que se
-- desconectaron puedan volver (ver MatchRegistry)
function LobbyReturn.startHeartbeat()
	if not LobbyReturn.isRoomMatch() then
		return
	end
	local privateId = game.PrivateServerId
	MatchRegistry.heartbeat(privateId)
	task.spawn(function()
		while true do
			task.wait(MatchRegistry.HeartbeatEvery)
			MatchRegistry.heartbeat(privateId)
		end
	end)
	game:BindToClose(function()
		MatchRegistry.finish(privateId)
	end)
end

-- true si este servidor lo reservó el Lobby para una sala
function LobbyReturn.isRoomMatch(): boolean
	return not RunService:IsStudio() and Config.Places.Lobby ~= 0 and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- Manda a estos jugadores al Lobby (reintenta si Roblox falla)
function LobbyReturn.sendPlayers(players: { Player })
	if #players == 0 then
		return
	end
	-- Van al Lobby a propósito: ya no tienen partida a la que reconectarse
	for _, player in players do
		leaving[player] = true
		MatchRegistry.clear(player.UserId)
	end
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(Config.Places.Lobby, players)
		end)
		if ok then
			return
		end
		warn(`No se pudo volver al Lobby (intento {attempt}): {err}`)
		task.wait(2)
	end
end

-- Manda a todos al Lobby
function LobbyReturn.sendEveryone()
	LobbyReturn.sendPlayers(Players:GetPlayers())
end

return LobbyReturn
