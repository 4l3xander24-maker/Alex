-- El cliente solo dice "disparé desde aquí hacia allá"; el servidor decide si
-- le dio a algo y lleva la cuenta de la munición de cada arma. Así no se
-- puede hacer trampa mandando "maté al zombi 5" o disparando sin recargar.
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
	Ammo: { [string]: number },
	ReloadEnd: number?,
	ReloadWeapon: string?,
	LastShot: number,
}

local CombatService = {}

local states: { [Player]: State } = {}

local function getState(player: Player): State
	local state = states[player]
	if not state then
		state = { Ammo = {}, ReloadEnd = nil, ReloadWeapon = nil, LastShot = 0 }
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

-- Cargadores llenos (al reaparecer o al comprar mejoras)
function CombatService.refill(player: Player)
	local state = getState(player)
	table.clear(state.Ammo)
	state.ReloadEnd = nil
	state.ReloadWeapon = nil
end

local function getAmmo(state: State, weaponId: string, magazine: number): number
	local ammo = state.Ammo[weaponId]
	if ammo == nil then
		ammo = magazine
		state.Ammo[weaponId] = ammo
	end
	return ammo
end

local function finishReloadIfDone(state: State, now: number, weaponId: string, magazine: number)
	if state.ReloadEnd and state.ReloadWeapon == weaponId and now >= state.ReloadEnd - anticheat.ReloadTolerance then
		state.Ammo[weaponId] = magazine
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
	finishReloadIfDone(state, now, weaponId, stats.Magazine)
	if state.ReloadEnd then
		if state.ReloadWeapon == weaponId then
			return
		end
		-- Cambió de arma a mitad de la recarga: se cancela
		state.ReloadEnd = nil
		state.ReloadWeapon = nil
	end
	local ammo = getAmmo(state, weaponId, stats.Magazine)
	if ammo <= 0 then
		return
	end

	local aim, time = CombatService.validateAim(player, origin, direction, shotTime)
	if not aim then
		return
	end

	state.Ammo[weaponId] = ammo - 1
	state.LastShot = now
	local explosive = Progression.hasTalent(data, "Explosive")

	for _ = 1, stats.Pellets do
		local pelletDirection = applySpread(aim, stats.Spread)
		for _, enemyId in EnemyService.raycast(origin, pelletDirection, stats.Range, time, stats.Pierce + 1) do
			local damage = stats.Damage
			if random:NextNumber() < stats.CritChance then
				damage *= Config.CritMultiplier
			end
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
	local state = getState(player)
	local now = os.clock()
	finishReloadIfDone(state, now, weaponId, stats.Magazine)
	if state.ReloadEnd and state.ReloadWeapon == weaponId then
		return
	end
	if getAmmo(state, weaponId, stats.Magazine) >= stats.Magazine then
		return
	end
	state.ReloadEnd = now + stats.ReloadTime
	state.ReloadWeapon = weaponId
end

function CombatService.init()
	Remotes.Shoot.OnServerEvent:Connect(onShoot)
	Remotes.Reload.OnServerEvent:Connect(onReload)

	local function watchCharacter(player: Player)
		player.CharacterAdded:Connect(function()
			CombatService.refill(player)
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	DataService.onChanged(function(player, reason)
		if reason == "Shop" then
			CombatService.refill(player)
		elseif reason == "Equip" then
			local state = getState(player)
			state.ReloadEnd = nil
			state.ReloadWeapon = nil
		end
	end)
end

return CombatService
