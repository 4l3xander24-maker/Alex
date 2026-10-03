-- Estado de cada jugador durante una partida: XP, nivel, mejoras elegidas,
-- munición y enfriamiento de poderes. Todo se reinicia al perder.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Upgrades = require(Shared.Upgrades)

local STAT_NAMES = { "Damage", "FireRate", "Magazine", "ReloadTime", "Pellets", "Spread", "Pierce", "CritChance" }

export type Run = {
	Level: number,
	Xp: number,
	Counts: { [string]: number },
	Stats: Upgrades.Stats,
	Pending: number, -- niveles ganados que aún no eligieron mejora
	Offer: { string }?,
	Ammo: number,
	ReloadEnd: number?,
	LastShot: number?,
	Cooldowns: { [string]: number },
}

local ProgressionService = {}

local runs: { [Player]: Run } = {}
local runCounter = 0
local random = Random.new()

function ProgressionService.xpNeeded(level: number): number
	local progression = Config.Progression
	return math.floor(progression.XpBase * progression.XpGrowth ^ (level - 1))
end

local function publishXp(player: Player, run: Run)
	player:SetAttribute("Level", run.Level)
	player:SetAttribute("Xp", run.Xp)
	player:SetAttribute("XpNeeded", ProgressionService.xpNeeded(run.Level))
end

-- El cliente lee estas estadísticas para predecir cadencia, munición, etc.
local function publishStats(player: Player, run: Run)
	for _, name in STAT_NAMES do
		player:SetAttribute("Stat_" .. name, run.Stats[name])
	end
	for name, level in run.Stats.Powers do
		player:SetAttribute("Power_" .. name, level)
	end
end

local function newRun(player: Player)
	local stats = Upgrades.computeStats({})
	local run: Run = {
		Level = 1,
		Xp = 0,
		Counts = {},
		Stats = stats,
		Pending = 0,
		Offer = nil,
		Ammo = stats.Magazine,
		ReloadEnd = nil,
		LastShot = nil,
		Cooldowns = {},
	}
	runs[player] = run
	publishXp(player, run)
	publishStats(player, run)
	runCounter += 1
	player:SetAttribute("RunId", runCounter)
	Remotes.LevelUpOffer:FireClient(player, nil)
end

local function makeOffer(player: Player, run: Run)
	local candidates = {}
	for _, upgrade in Upgrades.List do
		if (run.Counts[upgrade.Id] or 0) < upgrade.MaxStacks then
			table.insert(candidates, upgrade)
		end
	end
	if #candidates == 0 then
		run.Pending = 0
		return
	end

	for index = #candidates, 2, -1 do
		local swap = random:NextInteger(1, index)
		candidates[index], candidates[swap] = candidates[swap], candidates[index]
	end

	local offer, options = {}, {}
	for index = 1, math.min(Config.Progression.ChoicesPerLevel, #candidates) do
		local upgrade = candidates[index]
		local stacks = run.Counts[upgrade.Id] or 0
		offer[index] = upgrade.Id
		options[index] = {
			Id = upgrade.Id,
			Name = upgrade.Name,
			Icon = upgrade.Icon,
			Description = upgrade.Describe(stacks),
			Stacks = stacks,
			MaxStacks = upgrade.MaxStacks,
		}
	end
	run.Offer = offer
	Remotes.LevelUpOffer:FireClient(player, run.Level - run.Pending + 1, options)
end

local function onChooseUpgrade(player: Player, id: any)
	local run = runs[player]
	if not run or not run.Offer or typeof(id) ~= "string" or not table.find(run.Offer, id) then
		return
	end

	local oldMagazine = run.Stats.Magazine
	run.Counts[id] = (run.Counts[id] or 0) + 1
	run.Stats = Upgrades.computeStats(run.Counts)
	-- Un cargador más grande también da esas balas extra de inmediato
	run.Ammo += math.max(0, run.Stats.Magazine - oldMagazine)
	run.Offer = nil
	run.Pending -= 1
	publishStats(player, run)

	if run.Pending > 0 then
		makeOffer(player, run)
	end
end

function ProgressionService.getRun(player: Player): Run?
	return runs[player]
end

-- En cooperativo todos ganan la XP de cada zombi
function ProgressionService.addXpAll(amount: number)
	for player, run in runs do
		run.Xp += amount
		local leveledUp = false
		while run.Xp >= ProgressionService.xpNeeded(run.Level) do
			run.Xp -= ProgressionService.xpNeeded(run.Level)
			run.Level += 1
			run.Pending += 1
			leveledUp = true
		end
		publishXp(player, run)
		if leveledUp and not run.Offer then
			makeOffer(player, run)
		end
	end
end

function ProgressionService.resetAll()
	for _, player in Players:GetPlayers() do
		newRun(player)
	end
end

function ProgressionService.init()
	Players.PlayerAdded:Connect(newRun)
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		newRun(player)
	end
	Remotes.ChooseUpgrade.OnServerEvent:Connect(onChooseUpgrade)
end

return ProgressionService
