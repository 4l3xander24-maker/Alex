local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)

local waves = Config.Waves

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

local function runIntermission()
	GameState.set("State", "Intermission")
	for seconds = waves.Intermission, 1, -1 do
		GameState.set("Countdown", seconds)
		task.wait(1)
	end
	GameState.set("Countdown", 0)
end

-- Devuelve true si el castillo sobrevivió la oleada
local function runWave(wave: number): boolean
	GameState.set("Wave", wave)
	GameState.set("State", "Wave")

	local toSpawn = WaveService.getEnemyCount(wave)
	local spawnRate = WaveService.getSpawnRate(wave)
	local healthMultiplier = WaveService.getHealthMultiplier(wave)
	local budget = 0

	while toSpawn > 0 or EnemyService.getAliveCount() > 0 do
		if GameState.isCastleDestroyed() or #Players:GetPlayers() == 0 then
			return false
		end

		local dt = task.wait()
		budget = math.min(budget + dt * spawnRate, spawnRate)
		while budget >= 1 and toSpawn > 0 and EnemyService.getAliveCount() < waves.MaxAlive do
			EnemyService.spawn("Goblin", healthMultiplier)
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

			GameState.resetCastle()
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
