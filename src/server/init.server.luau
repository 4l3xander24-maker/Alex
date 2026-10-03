local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CombatService = require(script.CombatService)
local EnemyService = require(script.EnemyService)
local GameState = require(script.GameState)
local MapBuilder = require(script.MapBuilder)
local PlayerService = require(script.PlayerService)
local PowerService = require(script.PowerService)
local ProgressionService = require(script.ProgressionService)
local WaveService = require(script.WaveService)

MapBuilder.build()
GameState.init()
PlayerService.init()
ProgressionService.init()
CombatService.init()
PowerService.init()

EnemyService.setKillHandler(function(player, enemy)
	PlayerService.reward(player, enemy.Coins)
	ProgressionService.addXpAll(enemy.Xp)
end)
Remotes.GetSnapshot.OnServerInvoke = EnemyService.getSnapshot

RunService.Heartbeat:Connect(function(dt)
	local damagePerSecond = EnemyService.getBellDamagePerSecond(workspace:GetServerTimeNow())
	if damagePerSecond > 0 then
		GameState.damageBell(damagePerSecond * dt)
	end
end)

WaveService.start()
