-- Avisa a los jugadores que ya habían jugado qué cambió desde la última vez que
-- entraron (Config.WhatsNew). Cada versión se avisa una sola vez por jugador.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local WhatsNewService = {}

function WhatsNewService.onPlayerReady(player: Player)
	local data = DataService.get(player)
	if not data or data.SeenVersion == Config.Version.Id then
		return
	end
	local returning = data.Tutorial -- los nuevos ven el tutorial, no la lista de cambios
	data.SeenVersion = Config.Version.Id
	DataService.changed(player, "Profile")
	if not returning then
		return
	end
	task.delay(8, function()
		if not player.Parent then
			return
		end
		Remotes.Notify:FireClient(player, `🆕 Novedades {Config.Version.Id}: {Config.Version.Title}`)
		for index, line in Config.Version.Lines do
			task.delay(index * 3, function()
				if player.Parent then
					Remotes.Notify:FireClient(player, line)
				end
			end)
		end
	end)
end

return WhatsNewService
