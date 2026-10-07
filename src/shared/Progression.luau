-- Reglas de progresión que comparten servidor y cliente: perfil del jugador,
-- nivel de cuenta, estadísticas, talentos, armas y poderes. Las estadísticas
-- se calculan siempre desde el perfil, así cliente y servidor coinciden.
local Config = require(script.Parent.Config)

export type Profile = {
	Coins: number,
	Level: number,
	Xp: number,
	StatPoints: number,
	TalentPoints: number,
	Stats: { [string]: number }, -- puntos invertidos en cada estadística
	Talents: { [string]: boolean },
	Weapons: { [string]: number }, -- armas compradas y su nivel de mejora
	Equipped: string,
	Powers: { [string]: number }, -- poderes comprados y su nivel (1 = recién comprado)
	AmmoStorage: number, -- nivel de la cartuchera del Intendente
	VillageBridge: boolean, -- ya reparó el puente a la aldea
	Pets: { [string]: boolean }, -- mascotas compradas a la Bruja
	Pet: string, -- mascota que lo acompaña ("" = ninguna)
}

local Progression = {}

local statById = {}
for _, stat in Config.Stats do
	statById[stat.Id] = stat
end

local talentById = {}
for _, talent in Config.Talents do
	talentById[talent.Id] = talent
end

function Progression.defaultProfile(): Profile
	return {
		Coins = 0,
		Level = 1,
		Xp = 0,
		StatPoints = 0,
		TalentPoints = 0,
		Stats = {},
		Talents = {},
		Weapons = { Machete = 0, Pistol = 0 },
		Equipped = "Pistol",
		Powers = {},
		AmmoStorage = 0,
		VillageBridge = false,
		Pets = {},
		Pet = "",
	}
end

function Progression.getStatInfo(id: string)
	return statById[id]
end

function Progression.getTalentInfo(id: string)
	return talentById[id]
end

-- Valor total que dan los puntos invertidos (por ejemplo 0.15 = +15%)
function Progression.statValue(profile: Profile, id: string): number
	return (profile.Stats[id] or 0) * statById[id].PerPoint
end

function Progression.describeStat(id: string, points: number): string
	local info = statById[id]
	local value = points * info.PerPoint
	return string.format(info.Text, if info.Percent then math.floor(value * 100 + 0.5) else value)
end

function Progression.hasTalent(profile: Profile, id: string): boolean
	return profile.Talents[id] == true
end

function Progression.xpNeeded(level: number): number
	local progression = Config.Progression
	return math.floor(progression.XpBase * progression.XpGrowth ^ (level - 1))
end

-- Suma XP de cuenta y devuelve cuántos niveles se ganaron.
-- Cada nivel da 1 punto de estadística; cada 5 niveles, 1 de talento.
function Progression.addXp(profile: Profile, amount: number): number
	profile.Xp += amount
	local gained = 0
	while profile.Xp >= Progression.xpNeeded(profile.Level) do
		profile.Xp -= Progression.xpNeeded(profile.Level)
		profile.Level += 1
		profile.StatPoints += 1
		if profile.Level % Config.Progression.TalentEvery == 0 then
			profile.TalentPoints += 1
		end
		gained += 1
	end
	return gained
end

function Progression.getPlayerStats(profile: Profile)
	local greed = if Progression.hasTalent(profile, "Greed") then 1 + Config.TalentValues.GreedBonus else 1
	local power = Progression.statValue(profile, "Power")
	return {
		MaxHealth = Config.Player.MaxHealth + Progression.statValue(profile, "Health"),
		WalkSpeed = Config.Player.WalkSpeed * (1 + Progression.statValue(profile, "Speed")),
		CoinMultiplier = (1 + Progression.statValue(profile, "Loot")) * greed,
		PowerDamage = 1 + power,
		PowerCooldown = 1 - power * 0.6,
	}
end

-- Cuántas veces más balas puedes cargar gracias a la cartuchera
function Progression.ammoStorageMultiplier(profile: Profile): number
	return 1 + (profile.AmmoStorage or 0) * Config.AmmoStorage.PerLevel
end

-- Costo de subir la cartuchera al siguiente nivel (nil si ya está al máximo)
function Progression.ammoStorageCost(level: number): number?
	return Config.AmmoStorage.Prices[level + 1]
end

-- Color del arma según su nivel de mejora
function Progression.weaponTier(level: number)
	local tiers = Config.WeaponTiers
	return tiers[math.clamp(level + 1, 1, #tiers)]
end

function Progression.getWeaponStats(profile: Profile, weaponId: string, aiming: boolean?)
	local base = Config.Weapons[weaponId]
	local level = profile.Weapons[weaponId] or 0
	local upgrade = Config.WeaponUpgrade
	local damage = base.Damage * (1 + upgrade.DamagePerLevel * level) * (1 + Progression.statValue(profile, "Damage"))
	local critChance = Config.BaseCritChance + Progression.statValue(profile, "Crit")

	if base.Melee then
		return {
			Melee = true,
			Damage = damage,
			FireRate = base.FireRate * (1 + Progression.statValue(profile, "FireRate")),
			Range = base.Range,
			Arc = base.Arc,
			MaxTargets = base.MaxTargets,
			CritChance = critChance,
			Magazine = 0,
			MaxReserve = 0,
			StartReserve = 0,
			AmmoPerKill = 0,
			ReloadTime = 0,
			Pellets = 1,
			Pierce = 0,
			Spread = 0,
			Zoom = 1,
			Level = level,
		}
	end

	local aim = aiming == true and Progression.hasTalent(profile, "Aim")
	local talents = Config.TalentValues
	local storage = Progression.ammoStorageMultiplier(profile)
	return {
		Melee = false,
		Damage = damage,
		FireRate = base.FireRate * (1 + Progression.statValue(profile, "FireRate")),
		Magazine = math.ceil(base.Magazine * (1 + upgrade.MagazinePerLevel * level) * (1 + Progression.statValue(profile, "Ammo"))),
		MaxReserve = math.floor(base.MaxReserve * storage),
		StartReserve = math.floor(base.StartReserve * storage),
		AmmoPerKill = base.AmmoPerKill,
		ReloadTime = base.ReloadTime * math.max(0.3, 1 - upgrade.ReloadPerLevel * level - Progression.statValue(profile, "Reload")),
		Range = base.Range,
		Pellets = base.Pellets,
		Pierce = base.Pierce,
		Spread = base.Spread * (if aim then talents.AimSpread else 1),
		CritChance = critChance + (if aim then talents.AimCrit else 0),
		Zoom = base.Zoom,
		Level = level,
	}
end

-- Costo de subir un arma de `level` a `level + 1`
function Progression.weaponUpgradeCost(weaponId: string, level: number): number
	local price = math.max(Config.WeaponUpgrade.BaseCost, Config.Weapons[weaponId].Price)
	return math.floor(price * 0.5 * (level + 1))
end

-- Costo de subir un poder de `level` a `level + 1`
function Progression.powerUpgradeCost(name: string, level: number): number
	return math.floor(Config.Powers[name].Price * 0.6 * level)
end

-- Valores de un poder según su nivel y los puntos de "Poder" del jugador
function Progression.getPowerStats(profile: Profile, name: string)
	local level = profile.Powers[name] or 0
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

	local playerStats = Progression.getPlayerStats(profile)
	stats.Damage *= playerStats.PowerDamage
	stats.Cooldown *= playerStats.PowerCooldown
	stats.Level = level
	return stats
end

return Progression
