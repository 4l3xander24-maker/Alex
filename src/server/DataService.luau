-- Guarda el perfil de cada jugador (monedas, nivel, armas, poderes, talentos)
-- con DataStore. En Studio sin "Enable Studio Access to API Services" el
-- juego funciona igual, pero no guarda nada.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)

local STORE_NAME = "CampanaMaldita_v1"
local AUTOSAVE_INTERVAL = 90
local LOAD_RETRIES = 3

type Entry = {
	Data: Progression.Profile,
	CanSave: boolean,
}

local DataService = {}

local entries: { [Player]: Entry } = {}
local listeners: { (Player, string) -> () } = {}
local store: DataStore? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	end
end

-- Completa campos que falten en perfiles guardados con versiones anteriores
local function reconcile(target: { [any]: any }, template: { [any]: any })
	for key, value in template do
		if target[key] == nil then
			target[key] = if type(value) == "table" then table.clone(value) else value
		elseif type(value) == "table" and type(target[key]) == "table" then
			reconcile(target[key], value)
		end
	end
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function updateLeaderstats(player: Player, data: Progression.Profile)
	player:SetAttribute("Coins", data.Coins)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Monedas.Value = data.Coins
		stats.Nivel.Value = data.Level
		stats["Récord"].Value = data.BestWave
	end
end

local function save(player: Player)
	local entry = entries[player]
	if not entry or not entry.CanSave or not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), entry.Data, { player.UserId })
	end)
	if not ok then
		warn(`No se pudo guardar a {player.Name}: {err}`)
	end
end

local function load(player: Player)
	local data, loaded = nil, false
	if store then
		for attempt = 1, LOAD_RETRIES do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data, loaded = result, true
				break
			end
			warn(`No se pudo cargar a {player.Name} (intento {attempt}): {result}`)
			task.wait(1)
		end
	end
	if not loaded then
		warn("El progreso no se guardará en esta sesión. En Studio activa Game Settings → Security → Enable Studio Access to API Services.")
	end

	local profile = if type(data) == "table" then data else Progression.defaultProfile()
	reconcile(profile, Progression.defaultProfile())
	-- Si no pudimos leer lo guardado, no lo pisamos con un perfil vacío
	entries[player] = { Data = profile, CanSave = loaded }
end

function DataService.get(player: Player): Progression.Profile?
	local entry = entries[player]
	return entry and entry.Data
end

-- Avisa al cliente y a los demás servicios que el perfil cambió.
-- reason: "Load", "Shop", "Equip", "Level", "Record" o "Profile"
function DataService.changed(player: Player, reason: string)
	local data = DataService.get(player)
	if not data then
		return
	end
	updateLeaderstats(player, data)
	Remotes.ProfileUpdated:FireClient(player, data, reason)
	for _, listener in listeners do
		listener(player, reason)
	end
end

function DataService.onChanged(listener: (Player, string) -> ())
	table.insert(listeners, listener)
end

-- Las monedas cambian muy seguido: solo actualizamos el atributo, no todo el perfil
function DataService.addCoins(player: Player, amount: number)
	local data = DataService.get(player)
	if data then
		data.Coins += amount
		updateLeaderstats(player, data)
	end
end

function DataService.spendCoins(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	return true
end

function DataService.addXp(player: Player, amount: number): number
	local data = DataService.get(player)
	if not data then
		return 0
	end
	local levels = Progression.addXp(data, amount)
	DataService.changed(player, "Level")
	return levels
end

-- Se llama desde init al salir el jugador, después de darle la XP de la partida
function DataService.release(player: Player)
	save(player)
	entries[player] = nil
end

function DataService.isReady(player: Player): boolean
	return entries[player] ~= nil
end

function DataService.init(onLoaded: (Player) -> ())
	local function onPlayerAdded(player: Player)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local coins = Instance.new("IntValue")
		coins.Name = "Monedas"
		coins.Parent = stats
		local level = Instance.new("IntValue")
		level.Name = "Nivel"
		level.Parent = stats
		local best = Instance.new("IntValue")
		best.Name = "Récord"
		best.Parent = stats
		stats.Parent = player

		load(player)
		if player.Parent then
			DataService.changed(player, "Load")
			onLoaded(player)
		else
			entries[player] = nil
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in entries do
				task.spawn(save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in entries do
			pending += 1
			task.spawn(function()
				save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
