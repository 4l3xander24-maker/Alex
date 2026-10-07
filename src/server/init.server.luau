local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local AssetService = require(script.AssetService)
local CombatService = require(script.CombatService)
local DataService = require(script.DataService)
local EnemyService = require(script.EnemyService)
local GameState = require(script.GameState)
local MapBuilder = require(script.MapBuilder)
local MatchService = require(script.MatchService)
local PetService = require(script.PetService)
local PlayerService = require(script.PlayerService)
local PowerService = require(script.PowerService)
local ShopService = require(script.ShopService)
local TrapService = require(script.TrapService)
local VillageService = require(script.VillageService)
local WaveService = require(script.WaveService)

local random = Random.new()

local map = MapBuilder.build()
-- Imágenes subidas (sprites y texturas pixeladas), en segundo plano
AssetService.init()
GameState.init()
TrapService.init()
PlayerService.init()
CombatService.init()
PowerService.init()
ShopService.init()
VillageService.init(map)
PetService.init()
DataService.init(function(player)
	PlayerService.onPlayerReady(player)
	PetService.onPlayerReady(player)
end)

local repairPrompt = map:FindFirstChild("RepairPrompt", true)
if repairPrompt then
	PlayerService.bindRepairPrompt(repairPrompt)
end
local startPrompt = map:FindFirstChild("StartPrompt", true)
if startPrompt then
	WaveService.setStartPrompt(startPrompt)
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
	CombatService.grantKillAmmo(player)
end)
Remotes.GetSnapshot.OnServerInvoke = EnemyService.getSnapshot

-- Al salir: primero la XP de la partida, después se guarda el perfil
Players.PlayerRemoving:Connect(function(player)
	MatchService.award(player, WaveService.getCurrentWave())
	DataService.release(player)
end)

RunService.Heartbeat:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local damagePerSecond = EnemyService.getBellDamagePerSecond(now)
	if damagePerSecond > 0 then
		GameState.damageBell(damagePerSecond * dt)
	end
	for gateId, gateDamage in EnemyService.getBarrierDamage(now) do
		TrapService.damageGate(gateId, gateDamage * dt)
	end
	-- Un solo mensaje por tipo de evento de zombis en cada cuadro
	EnemyService.flushEvents()
end)

task.spawn(function()
	local interval = Config.Hunt.ThinkInterval
	while true do
		task.wait(interval)
		local now = workspace:GetServerTimeNow()
		EnemyService.think(now, interval)
		TrapService.think(now, WaveService.getCurrentWave())
	end
end)

WaveService.start()
