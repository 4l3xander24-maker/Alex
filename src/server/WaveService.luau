local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local LobbyReturn = require(script.Parent.LobbyReturn)
local MatchService = require(script.Parent.MatchService)
local PlayerService = require(script.Parent.PlayerService)
local TrapService = require(script.Parent.TrapService)

local waves = Config.Waves
local random = Random.new()

local WaveService = {}

local currentWave = 0
local difficultyId = 1
local startRequested = false
local startPrompt: ProximityPrompt? = nil

-- Aviso "Reconstruir la campana": solo se ve durante la preparación. Al
-- reconstruirla se arma con animación y empieza la partida.
function WaveService.setStartPrompt(prompt: ProximityPrompt)
	startPrompt = prompt
	prompt.Enabled = false
	-- Al reconstruir la campana se elige la dificultad (solo ven la que tienen
	-- abierta y la siguiente con candado)
	prompt.Triggered:Connect(function(player)
		if GameState.get("State") == "Lobby" and not startRequested then
			local data = DataService.get(player)
			Remotes.DifficultyMenu:FireClient(player, if data then data.Difficulty else 1)
		end
	end)
end

function WaveService.getDifficulty()
	return Config.Difficulties[difficultyId]
end

-- La dificultad se decide en equipo: cada jugador vota y gana la mayoría. Empieza
-- en cuanto una opción pasa de la mitad (o votan todos); si no, a los
-- DifficultyVoteTime segundos gana la más votada (en empate, la más fácil).
local DIFFICULTY_VOTE_TIME = 15
local difficultyVotes: { [Player]: number } = {}
local difficultyTimer = 0

local function tally(): ({ [number]: number }, number)
	local counts: { [number]: number } = {}
	local voted = 0
	for player, id in difficultyVotes do
		if player.Parent then
			counts[id] = (counts[id] or 0) + 1
			voted += 1
		end
	end
	return counts, voted
end

local function finishDifficultyVote()
	if startRequested or GameState.get("State") ~= "Lobby" then
		return
	end
	local counts, voted = tally()
	local best, bestCount = 0, 0
	for id = 1, #Config.Difficulties do
		if (counts[id] or 0) > bestCount then
			best, bestCount = id, counts[id]
		end
	end
	if best == 0 then
		return
	end
	local info = Config.Difficulties[best]
	difficultyId = best
	GameState.set("Difficulty", best)
	startRequested = true
	difficultyTimer += 1
	table.clear(difficultyVotes)
	if startPrompt then
		startPrompt.Enabled = false
	end
	BellTower.rebuild()
	local suffix = if #Players:GetPlayers() > 1 then ` (ganó con {bestCount} de {voted} votos)` else ""
	for _, other in Players:GetPlayers() do
		Remotes.Notify:FireClient(other, `🔔 {info.Icon} {info.Name}{suffix}: ¡la campana se reconstruye y la partida empieza!`)
	end
end

Remotes.SelectDifficulty.OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "number" or GameState.get("State") ~= "Lobby" or startRequested then
		return
	end
	local info = Config.Difficulties[id]
	local data = DataService.get(player)
	if not info or not data or id > (data.Difficulty or 1) then
		return -- esa dificultad todavía tiene candado
	end
	local firstVote = next(difficultyVotes) == nil
	difficultyVotes[player] = id
	local counts, voted = tally()
	local total = #Players:GetPlayers()
	if voted >= total or (counts[id] or 0) * 2 > total then
		finishDifficultyVote()
		return
	end
	for _, other in Players:GetPlayers() do
		Remotes.Notify:FireClient(other, `🗳️ {player.DisplayName} votó {info.Icon} {info.Name} ({voted}/{total}). Gana la mayoría`)
		-- A los demás se les abre el menú para que voten
		if firstVote and other ~= player and not difficultyVotes[other] then
			local otherData = DataService.get(other)
			Remotes.DifficultyMenu:FireClient(other, if otherData then otherData.Difficulty else 1)
		end
	end
	if firstVote then
		difficultyTimer += 1
		local token = difficultyTimer
		task.delay(DIFFICULTY_VOTE_TIME, function()
			if token == difficultyTimer then
				finishDifficultyVote()
			end
		end)
	end
end)

-- Objetivo secundario de la oleada (Config.Objectives): matar N de un tipo
local objective: { Type: string, Goal: number, Count: number, Done: boolean }? = nil

local function publishObjective()
	local text = ""
	if objective then
		local info = Config.Enemies[objective.Type]
		text = if objective.Done then `✅ {info.DisplayName}: ¡cumplido!` else `🎯 {info.DisplayName}: {objective.Count}/{objective.Goal}`
	end
	GameState.set("Objective", text)
end

local function rollObjective(wave: number)
	objective = nil
	local settings = Config.Objectives
	if wave < settings.FirstWave or wave % waves.BossEvery == 0 or random:NextNumber() >= settings.Chance then
		publishObjective()
		return
	end
	local lineup = WaveService.getLineup(wave)
	local typeName = lineup[random:NextInteger(1, #lineup)]
	local goal = math.floor(settings.KillsBase + settings.KillsPerWave * (wave - settings.FirstWave))
	objective = { Type = typeName, Goal = goal, Count = 0, Done = false }
	publishObjective()
	Remotes.Notify:FireAllClients(`🎯 Objetivo: elimina {goal} {Config.Enemies[typeName].DisplayName} (+{goal * settings.RewardPerKill} monedas)`)
end

-- Cada baja cuenta para el objetivo
function WaveService.onKill(typeName: string)
	local current = objective
	if not current or current.Done or current.Type ~= typeName then
		return
	end
	current.Count += 1
	if current.Count >= current.Goal then
		current.Done = true
		local reward = current.Goal * Config.Objectives.RewardPerKill
		for _, player in Players:GetPlayers() do
			if DataService.get(player) then
				DataService.addCoins(player, reward)
			end
		end
		Remotes.Notify:FireAllClients(`✅ ¡Objetivo cumplido! +{reward} monedas para todos`)
	end
	publishObjective()
end

-- Evento de la oleada en curso (Config.WaveEvents), o nil
local waveEvent: { Count: number, Health: number, Spawn: number, Coins: number }? = nil

function WaveService.getEventCoins(): number
	return if waveEvent then waveEvent.Coins else 1
end

local function rollWaveEvent(wave: number)
	waveEvent = nil
	GameState.set("WaveEvent", "")
	local events = Config.WaveEvents
	if wave < events.FirstWave or wave % waves.BossEvery == 0 or random:NextNumber() >= events.Chance then
		return
	end
	local names = {}
	for name in events.Types do
		table.insert(names, name)
	end
	table.sort(names)
	local name = names[random:NextInteger(1, #names)]
	local info = events.Types[name]
	waveEvent = info
	GameState.set("WaveEvent", `{info.Icon} {info.Name}`)
	Remotes.Notify:FireAllClients(`{info.Icon} ¡Evento: {info.Name}! {info.Description}`)
end

-- Jugadores extra en la partida (0 si juegas solo)
local function extraPlayers(): number
	return math.max(#Players:GetPlayers() - 1, 0)
end

function WaveService.getEnemyCount(wave: number): number
	local difficulty = WaveService.getDifficulty()
	local base = waves.FirstWaveCount * (difficulty.Growth or waves.CountGrowth) ^ (wave - 1)
	return math.max(1, math.floor(base * (1 + waves.PerExtraPlayer.Count * extraPlayers()) * difficulty.Count * (if waveEvent then waveEvent.Count else 1)))
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
	local rate = (waves.FirstSpawnRate + waves.SpawnRateGrowth * (wave - 1)) * (1 + waves.PerExtraPlayer.SpawnRate * extraPlayers()) * WaveService.getDifficulty().Spawn * (if waveEvent then waveEvent.Spawn else 1)
	rate = math.min(waves.MaxSpawnRate, rate)
	if night then
		rate = math.min(waves.MaxSpawnRate, rate * Config.DayCycle.NightSpawnMultiplier)
	end
	return rate
end

function WaveService.getHealthMultiplier(wave: number): number
	return (1 + waves.HealthGrowth * (wave - 1)) * (1 + waves.PerExtraPlayer.Health * extraPlayers()) * WaveService.getDifficulty().Health * (if waveEvent then waveEvent.Health else 1)
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
-- Cayeron todos: cuenta de ContinueWindow segundos para que cualquiera pague
-- Continuar (Robux) y vuelvan todos; o todos tocan Cancelar. true si la
-- partida sigue. Los zombis siguen atacando la campana mientras tanto.
local cancelled: { [Player]: boolean } = {}

Remotes.ContinueCancel.OnServerEvent:Connect(function(player)
	cancelled[player] = true
end)

-- reason: "Dead" (cayeron todos los jugadores) o "Bell" (cayó la campana)
local function offerContinue(reason: string): boolean
	local monetization = Config.Monetization
	-- Sin producto de Robux creado solo se ofrece en Studio (para probar)
	if monetization.Products.Continue.Id == 0 and not RunService:IsStudio() then
		return false
	end
	table.clear(cancelled)
	local endsAt = workspace:GetServerTimeNow() + monetization.ContinueWindow
	GameState.set("ContinueReason", reason)
	GameState.set("ContinueEnds", endsAt)
	local continued = false
	while workspace:GetServerTimeNow() < endsAt do
		if reason == "Bell" then
			if not GameState.isBellDestroyed() then
				continued = true
				break
			end
		elseif not PlayerService.allDown() then
			continued = true
			break
		end
		if #Players:GetPlayers() == 0 or (reason == "Dead" and GameState.isBellDestroyed()) then
			break
		end
		local everyoneCancelled = true
		for _, player in Players:GetPlayers() do
			if not cancelled[player] then
				everyoneCancelled = false
				break
			end
		end
		if everyoneCancelled then
			break
		end
		task.wait(0.2)
	end
	GameState.set("ContinueEnds", 0)
	return continued
end

-- Cayeron todos y nadie pagó para seguir: se termina por muerte
local function everyoneDown(): boolean
	return PlayerService.allDown() and not offerContinue("Dead")
end

-- Cayó la campana y nadie pagó para seguir
local function bellDown(): boolean
	return GameState.isBellDestroyed() and not offerContinue("Bell")
end

local function runIntermission(seconds: number): boolean
	GameState.set("State", "Intermission")
	CombatService.restockAll()
	if TrapService.healGates(Config.Traps.Gate.RepairPerWave) > 0 then
		Remotes.Notify:FireAllClients("🚧 Las rejas se reparan un poco")
	end
	local finish = os.clock() + seconds
	while os.clock() < finish do
		if everyoneDown() then
			GameState.set("EndReason", "Dead")
			return false
		end
		-- Los zombis que quedaron de la horda anterior siguen atacando
		if bellDown() then
			GameState.set("EndReason", "Bell")
			return false
		end
		GameState.set("EnemiesLeft", EnemyService.getAliveCount())
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
	rollWaveEvent(wave)
	rollObjective(wave)
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

	-- Mini-jefe: un Coloso reforzado en las oleadas que no tienen jefe
	if wave >= waves.MiniBossEvery and wave % waves.MiniBossEvery == 0 and wave % waves.BossEvery ~= 0 then
		EnemyService.spawn("Colossus", healthMultiplier * waves.MiniBossHealth)
		Remotes.Notify:FireAllClients("💪 ¡Mini-jefe! Un Coloso reforzado viene con la horda")
	end
	local toSpawn = WaveService.getEnemyCount(wave)
	local spawnRate = WaveService.getSpawnRate(wave)
	local budget = 0

	-- Termina cuando ya salieron todos y quedan pocos vivos (NextWaveAt): los
	-- que quedan siguen y llega la próxima horda. Con jefes, hay que matarlos a todos.
	local keep = if wave % waves.BossEvery == 0 then 0 else waves.NextWaveAt
	while toSpawn > 0 or #bosses > 0 or EnemyService.getAliveCount() > keep do
		if #Players:GetPlayers() == 0 or bellDown() then
			GameState.set("EndReason", "Bell")
			return false
		end
		if everyoneDown() then
			GameState.set("EndReason", "Dead")
			return false
		end

		local dt = task.wait()
		spawnRate = WaveService.getSpawnRate(wave, DayCycle.isNight(workspace:GetServerTimeNow()))
		nextBossIn -= dt
		if #bosses > 0 and nextBossIn <= 0 then
			local boss = table.remove(bosses, 1) :: string
			-- Los jefes suben más con cada jugador extra (BossHealth en vez de Health)
			local extra = extraPlayers()
			local scale = waves.PerExtraPlayer
			EnemyService.spawn(boss, healthMultiplier * (1 + scale.BossHealth * extra) / (1 + scale.Health * extra))
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
	-- Superó las oleadas de la dificultad: se abre la que sigue (para quien la tenía de tope)
	local info = WaveService.getDifficulty()
	if wave == info.Goal then
		Remotes.Notify:FireAllClients(`🏆 ¡Dificultad {info.Name} superada!`)
		local nextInfo = Config.Difficulties[difficultyId + 1]
		for _, player in Players:GetPlayers() do
			local data = DataService.get(player)
			if data and nextInfo and (data.Difficulty or 1) == difficultyId then
				data.Difficulty = difficultyId + 1
				DataService.changed(player, "Profile")
				DataService.saveNow(player)
				Remotes.Notify:FireClient(player, `🔓 ¡Desbloqueaste {nextInfo.Icon} {nextInfo.Name}!`)
			end
		end
	end
	return true
end

-- Al perder: el equipo vota Reintentar o Volver al lobby y gana la mayoría (vale
-- para todos). No hay cuenta regresiva: termina cuando una opción pasa de la
-- mitad o votan todos; cada uno puede cambiar su voto mientras tanto. (Por si
-- alguien se queda dormido, pasados VoteMaxWait segundos se cuenta como Reintentar.)
local votes: { [Player]: string } = {}
local voting = false

-- Decide la mayoría y vale para todo el equipo. Devuelve "Lobby" o "Retry"
-- (en empate o sin mayoría para el lobby, se reintenta)
function WaveService.runVote(): string
	table.clear(votes)
	voting = true
	GameState.set("VoteRetry", 0)
	GameState.set("VoteLobby", 0)
	GameState.set("Vote", true)
	local started = os.clock()
	while true do
		local retry, lobby, total = 0, 0, 0
		for _, player in Players:GetPlayers() do
			total += 1
			if votes[player] == "Retry" then
				retry += 1
			elseif votes[player] == "Lobby" then
				lobby += 1
			end
		end
		GameState.set("VoteRetry", retry)
		GameState.set("VoteLobby", lobby)
		-- Termina cuando una opción tiene más de la mitad, o votaron todos
		if total == 0 or retry * 2 > total or lobby * 2 > total or retry + lobby >= total or os.clock() - started > Config.Rooms.VoteMaxWait then
			break
		end
		task.wait(0.25)
	end
	voting = false
	GameState.set("Vote", false)
	local retry, lobby = 0, 0
	for _, player in Players:GetPlayers() do
		if votes[player] == "Lobby" then
			lobby += 1
		elseif votes[player] == "Retry" then
			retry += 1
		end
	end
	return if lobby > retry and lobby * 2 > #Players:GetPlayers() then "Lobby" else "Retry"
end

Remotes.Vote.OnServerEvent:Connect(function(player, choice)
	if voting and (choice == "Retry" or choice == "Lobby") then
		votes[player] = choice
	end
end)

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
			-- Skin de la campana: la del primer jugador que tenga una puesta
			local bellSkin = nil
			for _, player in Players:GetPlayers() do
				bellSkin = TrapService.skinOf(player, "Bell")
				if bellSkin then
					break
				end
			end
			BellTower.setSkin(bellSkin)
			BellTower.setArmorLevel((WaveService.getBellMaxHealth() - Config.Bell.MaxHealth) // Config.Bell.Armor.HealthPerLevel)
			-- Todos empiezan la partida con la munición inicial
			CombatService.resetAll()
			table.clear(lineups)
			GameState.set("EndReason", "")
			PlayerService.setInMatch(true)
			local wave = 0
			repeat
				wave += 1
				-- Si quedaron zombis de la horda anterior, la siguiente llega enseguida
				local pause = if wave == 1 then waves.FirstIntermission elseif EnemyService.getAliveCount() > 0 then waves.OverlapIntermission else waves.Intermission
			until not runIntermission(pause) or not runWave(wave)
			PlayerService.setInMatch(false)

			GameState.set("State", "GameOver")
			-- Cinemática: todos ven a la campana derrumbarse
			Remotes.GameOverCinematic:FireAllClients(GameState.get("EndReason"), Config.Arena.Bell, Config.Rooms.CinematicTime)
			task.wait(1.4)
			BellTower.collapse()
			task.wait(Config.Rooms.CinematicTime - 1.4)
			EnemyService.clear()
			GameState.set("EnemiesLeft", 0)
			MatchService.endMatch(wave)
			currentWave = 0
			GameState.set("Wave", 0)
			-- Votación: reintentar aquí mismo o volver al lobby (solo si vinieron de una sala)
			local decision = WaveService.runVote()
			if decision == "Lobby" then
				if LobbyReturn.isRoomMatch() then
					Remotes.Notify:FireAllClients("🏰 La mayoría eligió volver al lobby")
					LobbyReturn.sendPlayers(Players:GetPlayers())
					task.wait(4)
				else
					-- Fuera de una sala (Studio) no hay lobby al que volver
					Remotes.Notify:FireAllClients("🏰 Aquí no hay lobby: seguimos en la partida")
				end
			else
				Remotes.Notify:FireAllClients("🔄 La mayoría eligió reintentar")
			end
			local retryNames = #Players:GetPlayers()
			if retryNames > 0 then
				Remotes.Notify:FireAllClients("🔄 ¡Otra vez! Prepárense")
			end
		end
	end)
end

return WaveService
