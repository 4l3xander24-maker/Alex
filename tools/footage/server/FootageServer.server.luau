-- SOLO PARA GRABAR TRÁILERS (footage.project.json). No se publica.
-- Prepara al jugador con todo el equipo y lo mantiene vivo; los "Take" los
-- cambia el director desde la barra de comandos: workspace:SetAttribute("Take", "fps")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local DataService = require(Server:WaitForChild("DataService"))
local CombatService = require(Server:WaitForChild("CombatService"))
local PlayerService = require(Server:WaitForChild("PlayerService"))
local BellTower = require(Server:WaitForChild("BellTower"))
local GameState = require(Server:WaitForChild("GameState"))
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat
	task.wait(0.5)
until DataService.isReady(player)

local data = DataService.get(player)
for _, id in Config.WeaponOrder do
	data.Weapons[id] = 4
end
data.Equipped = "Rifle"
data.Tutorial = true
data.Difficulty = 5
data.Level = 30
data.Coins = 9000
data.BellArmor = 3
DataService.changed(player, "Shop")

task.spawn(function()
	while true do
		task.wait(0.25)
		PlayerService.heal(player, 1000)
	end
end)

task.spawn(function()
	while true do
		task.wait(3)
		CombatService.refillAmmo(player)
	end
end)

-- La campana aguanta mientras se graba (salvo en el Take "collapse")
task.spawn(function()
	while true do
		task.wait(0.4)
		if workspace:GetAttribute("Take") ~= "collapse" and workspace:GetAttribute("Hold") ~= false then
			GameState.repairBell(60)
		end
	end
end)

workspace:GetAttributeChangedSignal("Take"):Connect(function()
	if workspace:GetAttribute("Take") == "collapse" then
		Remotes.GameOverCinematic:FireAllClients("Bell", Config.Arena.Bell, Config.Rooms.CinematicTime)
		task.wait(2.6)
		BellTower.collapse()
	end
end)

-- Colocar al jugador junto a la campana, donde llega la horda
workspace:GetAttributeChangedSignal("Spot"):Connect(function()
	local character = player.Character
	if workspace:GetAttribute("Spot") == "bell" and character then
		local bell = Config.Arena.Bell
		character:PivotTo(CFrame.lookAt(bell + Vector3.new(0, 5, 15), bell + Vector3.new(0, 5, 0)))
	end
end)
