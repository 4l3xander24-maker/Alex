local Players = game:GetService("Players")

local PlayerService = {}

local function onPlayerAdded(player: Player)
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Monedas"
	coins.Parent = stats

	local kills = Instance.new("IntValue")
	kills.Name = "Bajas"
	kills.Parent = stats

	stats.Parent = player
end

function PlayerService.reward(player: Player, coins: number)
	local stats = player.Parent and player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	stats.Monedas.Value += coins
	stats.Bajas.Value += 1
end

function PlayerService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerService
