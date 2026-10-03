local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local CombatService = require(script.Parent.CombatService)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)
local MatchService = require(script.Parent.MatchService)
local PlayerService = require(script.Parent.PlayerService)
local TrapService = require(script.Parent.TrapService)

local waves = Config.Waves
local random = Random.new()

local WaveService = {}

local currentWave = 0
local startRequested = false
local startPrompt: ProximityPrompt? = nil

-- Aviso "Empezar partida" en la campana: solo se ve durante la preparación
function WaveService.setStartPrompt(prompt: ProximityPrompt)
	startPrompt = prompt
	prompt.Enabled = false
	prompt.Triggered:Connect(function(player)
		if GameState.get("State") == "Lobby" and not startRequested then
			startRequested = true
			for _, other in Players:GetPlayers() do
				Remotes.Notify:FireClient(other, `🔔 {player.DisplayName} tocó la campana: ¡la partida empieza!`)
			end
		end
	end)
end

function WaveService.getEnemyCount(wave: number): number
	return math.floor(waves.FirstWaveCount * waves.CountGrowth ^ (wave - 1))
end

function WaveService.getSpawnRate(wave: number): number
	return math.min(waves.MaxSpawnRate, waves.FirstSpawnRate + waves.SpawnRateGrowth * (wave - 1))
end

function WaveService.getHealthMultiplier(wave: number): number
	return 1 + waves.HealthGrowth * (wave - 1)
end

-- Jefes de la oleada: uno más cada BossEvery oleadas, rotando la lista
function WaveService.getBosses(wave: number): { string }
	local bosses = {}
	if wave % waves.BossEvery == 0 then
		local count = wave // waves.BossEvery
		for index = 1, count do
			local offset = (count - 1 + index - 1) % #waves.Bosses
			table.insert(bosses, waves.Bosses[offset + 1])
		end
	end
	return bosses
end

local function announceBoss(typeName: string)
	local info = Config.Enemies[typeName]
	for _, player in Players:GetPlayers() do
		Remotes.Notify:FireClient(player, `{info.Icon or "💀"} ¡Llega el {info.DisplayName}!`)
	end
end

function WaveService.getCurrentWave(): number
	return currentWave
end

-- Elige un tipo de zombi según la oleada. Los tipos especiales se vuelven
-- más comunes mientras más oleadas pasan desde que aparecieron.
function WaveService.pickType(wave: number): string
	local total = 0
	local weights = {}
	for _, entry in waves.Mix do
		if wave >= entry.FromWave then
			local weight = entry.Weight * (1 + 0.1 * (wave - entry.FromWave))
			table.insert(weights, { Type = entry.Type, Weight = weight })
			total += weight
		end
	end
	local roll = random:NextNumber(0, total)
	for _, entry in weights do
		roll -= entry.Weight
		if roll <= 0 then
			return entry.Type
		end
	end
	return weights[#weights].Type
end

-- Preparación: el único momento para comprar. Termina al tocar la campana
-- o cuando se acaba el tiempo. Devuelve false si todos se fueron.
local function runLobby(): boolean
	GameState.set("State", "Lobby")
	GameState.set("Wave", 0)
	TrapService.reset()
	CombatService.resetAll()
	startRequested = false
	if startPrompt then
		startPrompt.Enabled = true
	end

	local remaining = Config.Match.LobbyTime
	local countingDown = false
	while remaining > 0 do
		if #Players:GetPlayers() == 0 then
			return false
		end
		if startRequested and not countingDown then
			countingDown = true
			remaining = math.min(remaining, Config.Match.StartCountdown)
		end
		GameState.set("Countdown", remaining)
		task.wait(1)
		remaining -= 1
	end

	if startPrompt then
		startPrompt.Enabled = false
	end
	GameState.set("Countdown", 0)
	return true
end

local function runIntermission(seconds: number)
	GameState.set("State", "Intermission")
	for remaining = seconds, 1, -1 do
		GameState.set("Countdown", remaining)
		task.wait(1)
	end
	GameState.set("Countdown", 0)
end

-- Devuelve true si la campana sobrevivió la oleada
local function runWave(wave: number): boolean
	currentWave = wave
	GameState.set("Wave", wave)
	GameState.set("State", "Wave")
	PlayerService.onWaveStart()

	local healthMultiplier = WaveService.getHealthMultiplier(wave)
	-- Los jefes salen de a uno, separados unos segundos
	local bosses = WaveService.getBosses(wave)
	local nextBossIn = 0

	local toSpawn = WaveService.getEnemyCount(wave)
	local spawnRate = WaveService.getSpawnRate(wave)
	local budget = 0

	while toSpawn > 0 or #bosses > 0 or EnemyService.getAliveCount() > 0 do
		if GameState.isBellDestroyed() or #Players:GetPlayers() == 0 then
			return false
		end

		local dt = task.wait()
		nextBossIn -= dt
		if #bosses > 0 and nextBossIn <= 0 then
			local boss = table.remove(bosses, 1) :: string
			EnemyService.spawn(boss, healthMultiplier)
			announceBoss(boss)
			nextBossIn = waves.BossSpacing
		end
		budget = math.min(budget + dt * spawnRate, spawnRate)
		while budget >= 1 and toSpawn > 0 and EnemyService.getAliveCount() < waves.MaxAlive do
			EnemyService.spawn(WaveService.pickType(wave), healthMultiplier)
			toSpawn -= 1
			budget -= 1
		end

		GameState.set("EnemiesLeft", toSpawn + #bosses + EnemyService.getAliveCount())
	end
	MatchService.onWaveCleared()
	return true
end

function WaveService.start()
	task.spawn(function()
		while true do
			GameState.set("State", "Waiting")
			while #Players:GetPlayers() == 0 do
				task.wait(1)
			end

			if not runLobby() then
				continue
			end

			GameState.resetBell()
			-- Todos empiezan la partida con la munición inicial
			CombatService.resetAll()
			local wave = 0
			repeat
				wave += 1
				runIntermission(if wave == 1 then waves.FirstIntermission else waves.Intermission)
			until not runWave(wave)

			GameState.set("State", "GameOver")
			EnemyService.clear()
			GameState.set("EnemiesLeft", 0)
			MatchService.endMatch(wave)
			task.wait(waves.GameOverDelay)
			currentWave = 0
			GameState.set("Wave", 0)
		end
	end)
end

return WaveService
