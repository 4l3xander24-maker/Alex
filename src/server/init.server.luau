local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local CombatService = require(script.CombatService)
local DataService = require(script.DataService)
local EnemyService = require(script.EnemyService)
local GameState = require(script.GameState)
local MapBuilder = require(script.MapBuilder)
local MatchService = require(script.MatchService)
local PlayerService = require(script.PlayerService)
local PowerService = require(script.PowerService)
local ShopService = require(script.ShopService)
local WaveService = require(script.WaveService)

local random = Random.new()

local map = MapBuilder.build()
GameState.init()
PlayerService.init()
CombatService.init()
PowerService.init()
ShopService.init()
DataService.init(PlayerService.onPlayerReady)

local repairPrompt = map:FindFirstChild("RepairPrompt", true)
if repairPrompt then
	PlayerService.bindRepairPrompt(repairPrompt)
end

EnemyService.setPlayerDamageHandler(PlayerService.damagePlayer)
EnemyService.setKillHandler(function(player, enemy)
	local data = player.Parent and DataService.get(player)
	if not data then
		return
	end
	-- Las monedas con decimales se redondean al azar para que el bonus cuente
	local exact = enemy.Coins * Progression.getPlayerStats(data).CoinMultiplier
	local coins = math.floor(exact) + (if random:NextNumber() < exact % 1 then 1 else 0)
	DataService.addCoins(player, coins)
	MatchService.onKill(player, enemy.IsBoss, coins)
	PlayerService.onKill(player)
end)
Remotes.GetSnapshot.OnServerInvoke = EnemyService.getSnapshot

-- Al salir: primero la XP de la partida, después se guarda el perfil
Players.PlayerRemoving:Connect(function(player)
	MatchService.award(player, WaveService.getCurrentWave())
	DataService.release(player)
end)

RunService.Heartbeat:Connect(function(dt)
	local damagePerSecond = EnemyService.getBellDamagePerSecond(workspace:GetServerTimeNow())
	if damagePerSecond > 0 then
		GameState.damageBell(damagePerSecond * dt)
	end
end)

task.spawn(function()
	local interval = Config.Hunt.ThinkInterval
	while true do
		task.wait(interval)
		EnemyService.think(workspace:GetServerTimeNow(), interval)
	end
end)

WaveService.start()
