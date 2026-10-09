local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)
local Remotes = require(Shared.Remotes)
local BellTower = require(script.Parent.BellTower)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
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

-- Aviso "Reconstruir la campana": solo se ve durante la preparación. Al
-- reconstruirla se arma con animación y empieza la partida.
function WaveService.setStartPrompt(prompt: ProximityPrompt)
	startPrompt = prompt
	prompt.Enabled = false
	prompt.Triggered:Connect(function(player)
		if GameState.get("State") == "Lobby" and not startRequested then
			startRequested = true
			prompt.Enabled = false
			BellTower.rebuild()
			for _, other in Players:GetPlayers() do
				Remotes.Notify:FireClient(other, `🔔 {player.DisplayName} reconstruyó la campana: ¡la partida empieza!`)
			end
		end
	end)
end

function WaveService.getEnemyCount(wave: number): number
	return math.floor(waves.FirstWaveCount * waves.CountGrowth ^ (wave - 1))
end

-- Vida de la campana: la base más el refuerzo más alto entre los jugadores
function WaveService.getBellMaxHealth(): number
	local armor = Config.Bell.Armor
	local level = 0
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data then
			level = math.max(level, math.min(data.BellArmor or 0, armor.MaxLevel))
		end
	end
	return Config.Bell.MaxHealth + level * armor.HealthPerLevel
end

-- Zombis por segundo. De noche llegan más (Config.DayCycle.NightSpawnMultiplier).
function WaveService.getSpawnRate(wave: number, night: boolean?): number
	local rate = math.min(waves.MaxSpawnRate, waves.FirstSpawnRate + waves.SpawnRateGrowth * (wave - 1))
	if night then
		rate = math.min(waves.MaxSpawnRate, rate * Config.DayCycle.NightSpawnMultiplier)
	end
	return rate
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

-- Los tipos de zombi de cada oleada (Config.Waves.Lineups; después, una
-- mezcla al azar que se elige una vez por oleada)
local lineups: { [number]: { string } } = {}

function WaveService.getLineup(wave: number): { string }
	if lineups[wave] then
		return lineups[wave]
	end
	local lineup = waves.Lineups[wave]
	if not lineup then
		local pool = table.clone(waves.Random)
		lineup = {}
		for _ = 1, random:NextInteger(2, 3) do
			table.insert(lineup, table.remove(pool, random:NextInteger(1, #pool)))
		end
	end
	lineups[wave] = lineup
	return lineup
end

-- Elige un tipo de zombi de la mezcla de esa oleada
function WaveService.pickType(wave: number): string
	local lineup = WaveService.getLineup(wave)
	return lineup[random:NextInteger(1, #lineup)]
end

-- Preparación: el único momento para comprar. La campana está destruida y la
-- partida no empieza hasta que alguien la reconstruye (no hay tiempo límite).
-- Devuelve false si todos se fueron.
local function runLobby(): boolean
	GameState.set("State", "Lobby")
	GameState.set("Wave", 0)
	TrapService.reset()
	CombatService.resetAll()
	startRequested = false
	if startPrompt then
		startPrompt.Enabled = true
	end

	while not startRequested do
		if #Players:GetPlayers() == 0 then
			return false
		end
		task.wait(0.25)
	end
	if startPrompt then
		startPrompt.Enabled = false
	end
	return true
end

-- Descanso antes de cada oleada (sin conteo en pantalla). Devuelve false si
-- cayeron todos los jugadores.
local function runIntermission(seconds: number): boolean
	GameState.set("State", "Intermission")
	CombatService.restockAll()
	local finish = os.clock() + seconds
	while os.clock() < finish do
		if PlayerService.allDown() then
			GameState.set("EndReason", "Dead")
			return false
		end
		task.wait(0.25)
	end
	return true
end

-- Devuelve true si la campana sobrevivió la oleada
local function runWave(wave: number): boolean
	currentWave = wave
	GameState.set("Wave", wave)
	GameState.set("State", "Wave")
	PlayerService.onWaveStart()
	-- Avisa qué zombis vienen en esta oleada
	local names = {}
	for _, typeName in WaveService.getLineup(wave) do
		table.insert(names, Config.Enemies[typeName].DisplayName)
	end
	Remotes.Notify:FireAllClients(`🧟 Oleada {wave}: {table.concat(names, " + ")}`)

	local healthMultiplier = WaveService.getHealthMultiplier(wave)
	-- Los jefes salen de a uno, separados unos segundos
	local bosses = WaveService.getBosses(wave)
	local nextBossIn = 0

	local toSpawn = WaveService.getEnemyCount(wave)
	local spawnRate = WaveService.getSpawnRate(wave)
	local budget = 0

	while toSpawn > 0 or #bosses > 0 or EnemyService.getAliveCount() > 0 do
		if GameState.isBellDestroyed() or #Players:GetPlayers() == 0 then
			GameState.set("EndReason", "Bell")
			return false
		end
		if PlayerService.allDown() then
			GameState.set("EndReason", "Dead")
			return false
		end

		local dt = task.wait()
		spawnRate = WaveService.getSpawnRate(wave, DayCycle.isNight(workspace:GetServerTimeNow()))
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

			GameState.resetBell(WaveService.getBellMaxHealth())
			-- Todos empiezan la partida con la munición inicial
			CombatService.resetAll()
			table.clear(lineups)
			GameState.set("EndReason", "")
			PlayerService.setInMatch(true)
			local wave = 0
			repeat
				wave += 1
			until not runIntermission(if wave == 1 then waves.FirstIntermission else waves.Intermission) or not runWave(wave)
			PlayerService.setInMatch(false)

			GameState.set("State", "GameOver")
			-- La campana se derrumba; en la próxima preparación hay que reconstruirla
			BellTower.collapse()
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
