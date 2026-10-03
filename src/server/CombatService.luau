-- El cliente solo dice "disparé desde aquí hacia allá"; el servidor decide si
-- le dio a algo y lleva la cuenta de la munición de cada arma (cargador y
-- reserva). Así no se puede hacer trampa mandando "maté al zombi 5" o
-- disparando sin balas. El machete no usa munición.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)

local anticheat = Config.Anticheat
local talents = Config.TalentValues
local random = Random.new()

type State = {
	Ammo: { [string]: number }, -- balas en el cargador
	Reserve: { [string]: number }, -- balas de reserva
	ReloadEnd: number?,
	ReloadWeapon: string?,
	LastShot: number,
	LastGun: string, -- última arma de fuego usada (recibe las balas si matas con el machete)
}

local CombatService = {}

local states: { [Player]: State } = {}

local function getState(player: Player): State
	local state = states[player]
	if not state then
		state = { Ammo = {}, Reserve = {}, ReloadEnd = nil, ReloadWeapon = nil, LastShot = 0, LastGun = "Pistol" }
		states[player] = state
	end
	return state
end

local function isValidNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- Valida un disparo o poder. Devuelve la dirección normalizada y el momento
-- (con compensación de lag) en que el jugador apuntó, o nil si es inválido.
function CombatService.validateAim(player: Player, origin: any, direction: any, shotTime: any): (Vector3?, number)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or typeof(shotTime) ~= "number" then
		return nil, 0
	end
	if not isValidNumber(shotTime) or not isValidNumber(direction.Magnitude) or direction.Magnitude < 0.5 then
		return nil, 0
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or ((head :: BasePart).Position - origin).Magnitude > anticheat.MaxOriginDistance then
		return nil, 0
	end

	local serverNow = workspace:GetServerTimeNow()
	return direction.Unit, math.clamp(shotTime, serverNow - anticheat.MaxRewind, serverNow)
end

-- Munición inicial de todas las armas de fuego (al empezar la partida o al
-- comprar algo en la preparación). Se le manda al cliente para que coincida.
function CombatService.resetAmmo(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local state = getState(player)
	table.clear(state.Ammo)
	table.clear(state.Reserve)
	state.ReloadEnd = nil
	state.ReloadWeapon = nil
	for weaponId in data.Weapons do
		local stats = Progression.getWeaponStats(data, weaponId, false)
		if not stats.Melee then
			state.Ammo[weaponId] = stats.Magazine
			state.Reserve[weaponId] = stats.StartReserve
		end
	end
	Remotes.AmmoSync:FireClient(player, state.Ammo, state.Reserve)
end

function CombatService.resetAll()
	for _, player in Players:GetPlayers() do
		CombatService.resetAmmo(player)
	end
end

-- Cada zombi eliminado da balas al arma que tienes en la mano (o a la última
-- arma de fuego que usaste si lo mataste con el machete)
function CombatService.grantKillAmmo(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local state = getState(player)
	local weaponId = data.Equipped
	if Config.Weapons[weaponId].Melee then
		weaponId = state.LastGun
	end
	if not data.Weapons[weaponId] then
		return
	end
	local stats = Progression.getWeaponStats(data, weaponId, false)
	local reserve = state.Reserve[weaponId] or 0
	local added = math.min(stats.AmmoPerKill, stats.MaxReserve - reserve)
	if added > 0 then
		state.Reserve[weaponId] = reserve + added
		Remotes.AmmoGranted:FireClient(player, weaponId, added)
	end
end

local function finishReloadIfDone(state: State, now: number, weaponId: string, magazine: number)
	if state.ReloadEnd and state.ReloadWeapon == weaponId and now >= state.ReloadEnd - anticheat.ReloadTolerance then
		local ammo = state.Ammo[weaponId] or 0
		local moved = math.min(magazine - ammo, state.Reserve[weaponId] or 0)
		state.Ammo[weaponId] = ammo + moved
		state.Reserve[weaponId] = (state.Reserve[weaponId] or 0) - moved
		state.ReloadEnd = nil
		state.ReloadWeapon = nil
	end
end

local function applySpread(direction: Vector3, spread: number): Vector3
	if spread <= 0 then
		return direction
	end
	local rotation = CFrame.Angles(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), 0)
	return (CFrame.lookAt(Vector3.zero, direction) * rotation).LookVector
end

local function rollDamage(damage: number, critChance: number): number
	return if random:NextNumber() < critChance then damage * Config.CritMultiplier else damage
end

-- Talento Balas explosivas: daña a los zombis alrededor del impacto
local function explode(player: Player, enemyId: number, damage: number, time: number)
	local position = EnemyService.getPosition(enemyId, time)
	if not position then
		return
	end
	Remotes.PowerFx:FireAllClients("Explosion", position, talents.ExplosiveRadius)
	for _, otherId in EnemyService.getInRadius(position, talents.ExplosiveRadius, time) do
		if otherId ~= enemyId then
			EnemyService.damage(otherId, damage * talents.ExplosiveDamage, player)
		end
	end
end

local function onShoot(player: Player, origin: any, direction: any, shotTime: any, aiming: any)
	local data = DataService.get(player)
	if not data then
		return
	end
	local weaponId = data.Equipped
	local stats = Progression.getWeaponStats(data, weaponId, aiming == true)
	local state = getState(player)

	local now = os.clock()
	if now - state.LastShot < (1 / stats.FireRate) * anticheat.FireRateTolerance then
		return
	end

	if stats.Melee then
		local aim, time = CombatService.validateAim(player, origin, direction, shotTime)
		if not aim then
			return
		end
		state.LastShot = now
		for _, enemyId in EnemyService.getInCone(origin, aim, stats.Range, stats.Arc, time, stats.MaxTargets) do
			EnemyService.damage(enemyId, rollDamage(stats.Damage, stats.CritChance), player)
		end
		return
	end

	finishReloadIfDone(state, now, weaponId, stats.Magazine)
	if state.ReloadEnd then
		if state.ReloadWeapon == weaponId then
			return
		end
		-- Cambió de arma a mitad de la recarga: se cancela
		state.ReloadEnd = nil
		state.ReloadWeapon = nil
	end
	local ammo = state.Ammo[weaponId] or 0
	if ammo <= 0 then
		return
	end

	local aim, time = CombatService.validateAim(player, origin, direction, shotTime)
	if not aim then
		return
	end

	state.Ammo[weaponId] = ammo - 1
	state.LastShot = now
	state.LastGun = weaponId
	local explosive = Progression.hasTalent(data, "Explosive")

	for _ = 1, stats.Pellets do
		local pelletDirection = applySpread(aim, stats.Spread)
		for _, enemyId in EnemyService.raycast(origin, pelletDirection, stats.Range, time, stats.Pierce + 1) do
			local damage = rollDamage(stats.Damage, stats.CritChance)
			if explosive and random:NextNumber() < talents.ExplosiveChance then
				explode(player, enemyId, damage, time)
			end
			EnemyService.damage(enemyId, damage, player)
		end
	end
end

local function onReload(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local weaponId = data.Equipped
	local stats = Progression.getWeaponStats(data, weaponId, false)
	if stats.Melee then
		return
	end
	local state = getState(player)
	local now = os.clock()
	finishReloadIfDone(state, now, weaponId, stats.Magazine)
	if state.ReloadEnd and state.ReloadWeapon == weaponId then
		return
	end
	if (state.Ammo[weaponId] or 0) >= stats.Magazine or (state.Reserve[weaponId] or 0) <= 0 then
		return
	end
	state.ReloadEnd = now + stats.ReloadTime
	state.ReloadWeapon = weaponId
end

function CombatService.init()
	Remotes.Shoot.OnServerEvent:Connect(onShoot)
	Remotes.Reload.OnServerEvent:Connect(onReload)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	DataService.onChanged(function(player, reason)
		if reason == "Load" or reason == "Shop" then
			-- Las compras solo se hacen en la preparación: empiezas con todo lleno
			CombatService.resetAmmo(player)
		elseif reason == "Equip" then
			local state = getState(player)
			state.ReloadEnd = nil
			state.ReloadWeapon = nil
		end
	end)
end

return CombatService
