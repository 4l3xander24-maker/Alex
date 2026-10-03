local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)
local ProgressionService = require(script.Parent.ProgressionService)

local waves = Config.Waves
local random = Random.new()

local WaveService = {}

function WaveService.getEnemyCount(wave: number): number
	return math.floor(waves.FirstWaveCount * waves.CountGrowth ^ (wave - 1))
end

function WaveService.getSpawnRate(wave: number): number
	return math.min(waves.MaxSpawnRate, waves.FirstSpawnRate + waves.SpawnRateGrowth * (wave - 1))
end

function WaveService.getHealthMultiplier(wave: number): number
	return 1 + waves.HealthGrowth * (wave - 1)
end

-- Elige un tipo de zombi según la oleada. Los tipos especiales se vuelven
-- más comunes mientras más oleadas pasan desde que aparecieron.
function WaveService.pickType(wave: number): string
	local total = 0
	local weights = {}
	for _, entry in waves.Mix do
		if wave >= entry.FromWave then
			local weight = entry.Weight * (1 + 0.1 * (wave - entry.FromWave))
			table.insert(weights, { entry.Type, weight })
			total += weight
		end
	end
	local roll = random:NextNumber(0, total)
	for _, pair in weights do
		roll -= pair[2]
		if roll <= 0 then
			return pair[1]
		end
	end
	return weights[#weights][1]
end

local function runIntermission()
	GameState.set("State", "Intermission")
	for seconds = waves.Intermission, 1, -1 do
		GameState.set("Countdown", seconds)
		task.wait(1)
	end
	GameState.set("Countdown", 0)
end

-- Devuelve true si la campana sobrevivió la oleada
local function runWave(wave: number): boolean
	GameState.set("Wave", wave)
	GameState.set("State", "Wave")

	local healthMultiplier = WaveService.getHealthMultiplier(wave)
	if wave % waves.BossEvery == 0 then
		for _ = 1, wave // waves.BossEvery do
			EnemyService.spawn("Giant", healthMultiplier)
		end
	end

	local toSpawn = WaveService.getEnemyCount(wave)
	local spawnRate = WaveService.getSpawnRate(wave)
	local budget = 0

	while toSpawn > 0 or EnemyService.getAliveCount() > 0 do
		if GameState.isBellDestroyed() or #Players:GetPlayers() == 0 then
			return false
		end

		local dt = task.wait()
		budget = math.min(budget + dt * spawnRate, spawnRate)
		while budget >= 1 and toSpawn > 0 and EnemyService.getAliveCount() < waves.MaxAlive do
			EnemyService.spawn(WaveService.pickType(wave), healthMultiplier)
			toSpawn -= 1
			budget -= 1
		end

		GameState.set("EnemiesLeft", toSpawn + EnemyService.getAliveCount())
	end
	return true
end

function WaveService.start()
	task.spawn(function()
		while true do
			GameState.set("State", "Waiting")
			while #Players:GetPlayers() == 0 do
				task.wait(1)
			end

			GameState.resetBell()
			ProgressionService.resetAll()
			local wave = 0
			repeat
				wave += 1
				runIntermission()
			until not runWave(wave)

			GameState.set("State", "GameOver")
			EnemyService.clear()
			GameState.set("EnemiesLeft", 0)
			task.wait(waves.GameOverDelay)
			GameState.set("Wave", 0)
		end
	end)
end

return WaveService
