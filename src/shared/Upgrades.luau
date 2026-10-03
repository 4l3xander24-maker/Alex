-- Mejoras que se eligen al subir de nivel durante una partida.
-- Las estadísticas del jugador se recalculan desde cero aplicando cada mejora
-- tantas veces como la haya elegido, así nunca se desincronizan.
local Config = require(script.Parent.Config)

export type Stats = {
	Damage: number,
	FireRate: number,
	Magazine: number,
	ReloadTime: number,
	Pellets: number,
	Spread: number,
	Pierce: number,
	CritChance: number,
	Powers: { [string]: number }, -- nivel de cada poder (0 = bloqueado)
}

export type Upgrade = {
	Id: string,
	Name: string,
	Icon: string,
	MaxStacks: number,
	Describe: (stacks: number) -> string,
	Apply: (stats: Stats) -> (),
}

local function powerUpgrade(power: string, name: string, unlockText: string, levelText: string, maxStacks: number): Upgrade
	return {
		Id = power,
		Name = name,
		Icon = Config.Powers[power].Icon,
		MaxStacks = maxStacks,
		Describe = function(stacks)
			local key = Config.Powers[power].Key.Name
			return if stacks == 0 then `Desbloquea [{key}]: {unlockText}` else levelText
		end,
		Apply = function(stats)
			stats.Powers[power] += 1
		end,
	}
end

local Upgrades = {}

Upgrades.List = {
	{
		Id = "Damage",
		Name = "Balas pesadas",
		Icon = "💥",
		MaxStacks = 10,
		Describe = function()
			return "+25% de daño"
		end,
		Apply = function(stats)
			stats.Damage *= 1.25
		end,
	},
	{
		Id = "FireRate",
		Name = "Gatillo rápido",
		Icon = "⚡",
		MaxStacks = 8,
		Describe = function()
			return "+15% de cadencia de disparo"
		end,
		Apply = function(stats)
			stats.FireRate *= 1.15
		end,
	},
	{
		Id = "Magazine",
		Name = "Cargador ampliado",
		Icon = "📦",
		MaxStacks = 8,
		Describe = function()
			return "+40% de munición por cargador"
		end,
		Apply = function(stats)
			stats.Magazine = math.ceil(stats.Magazine * 1.4)
		end,
	},
	{
		Id = "Reload",
		Name = "Manos ágiles",
		Icon = "🔄",
		MaxStacks = 6,
		Describe = function()
			return "Recargas 20% más rápido"
		end,
		Apply = function(stats)
			stats.ReloadTime *= 0.8
		end,
	},
	{
		Id = "Pierce",
		Name = "Balas perforantes",
		Icon = "🗡️",
		MaxStacks = 5,
		Describe = function()
			return "Cada bala atraviesa +1 zombi"
		end,
		Apply = function(stats)
			stats.Pierce += 1
		end,
	},
	{
		Id = "Multishot",
		Name = "Disparo múltiple",
		Icon = "🔱",
		MaxStacks = 4,
		Describe = function()
			return "+1 bala por disparo"
		end,
		Apply = function(stats)
			stats.Pellets += 1
			stats.Spread = math.max(stats.Spread, 0.04)
		end,
	},
	{
		Id = "Crit",
		Name = "Ojo de halcón",
		Icon = "🎯",
		MaxStacks = 5,
		Describe = function()
			return `+10% de crítico (x{Config.Weapon.CritMultiplier} de daño)`
		end,
		Apply = function(stats)
			stats.CritChance += 0.1
		end,
	},
	powerUpgrade("Grenade", "Granada", "lanza una granada explosiva", "Granada: +50% daño y +15% radio", 5),
	powerUpgrade("Chain", "Rayo en cadena", "un rayo salta entre 5 zombis", "Rayo: +2 saltos y +30% daño", 5),
	powerUpgrade("Bell", "Campanazo", "la campana empuja a los zombis", "Campanazo: -20% de espera y más empuje", 4),
} :: { Upgrade }

local byId: { [string]: Upgrade } = {}
for _, upgrade in Upgrades.List do
	byId[upgrade.Id] = upgrade
end

function Upgrades.get(id: string): Upgrade?
	return byId[id]
end

function Upgrades.baseStats(): Stats
	local weapon = Config.Weapon
	local powers = {}
	for name in Config.Powers do
		powers[name] = 0
	end
	return {
		Damage = weapon.Damage,
		FireRate = weapon.FireRate,
		Magazine = weapon.Magazine,
		ReloadTime = weapon.ReloadTime,
		Pellets = weapon.Pellets,
		Spread = weapon.Spread,
		Pierce = weapon.Pierce,
		CritChance = weapon.CritChance,
		Powers = powers,
	}
end

function Upgrades.computeStats(counts: { [string]: number }): Stats
	local stats = Upgrades.baseStats()
	for _, upgrade in Upgrades.List do
		for _ = 1, counts[upgrade.Id] or 0 do
			upgrade.Apply(stats)
		end
	end
	return stats
end

-- Valores de un poder según su nivel (nivel 1 = recién desbloqueado)
function Upgrades.getPowerStats(name: string, level: number)
	local stats = table.clone(Config.Powers[name])
	local bonus = math.max(level - 1, 0)
	if name == "Grenade" then
		stats.Damage *= 1.5 ^ bonus
		stats.Radius *= 1.15 ^ bonus
	elseif name == "Chain" then
		stats.Targets += 2 * bonus
		stats.Damage *= 1.3 ^ bonus
	elseif name == "Bell" then
		stats.Cooldown *= 0.8 ^ bonus
		stats.KnockbackSeconds += bonus
	end
	return stats
end

return Upgrades
