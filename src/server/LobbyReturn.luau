-- Partida que viene del Lobby (servidor reservado): al terminar, todos
-- vuelven al Lobby. Si se entró directo a este lugar (o en Studio), la
-- partida se repite aquí mismo como siempre.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)

local LobbyReturn = {}

-- true si este servidor lo reservó el Lobby para una sala
function LobbyReturn.isRoomMatch(): boolean
	return not RunService:IsStudio() and Config.Places.Lobby ~= 0 and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- Manda a todos al Lobby (reintenta si Roblox falla)
function LobbyReturn.sendEveryone()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
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

return LobbyReturn
