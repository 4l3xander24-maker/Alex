-- El cliente solo dice "disparé desde aquí hacia allá"; el servidor decide si
-- le dio a algo y lleva la cuenta de la munición. Así no se puede hacer
-- trampa mandando "maté al zombi 5" o disparando sin recargar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local ProgressionService = require(script.Parent.ProgressionService)

local weapon = Config.Weapon
local anticheat = Config.Anticheat
local random = Random.new()

local CombatService = {}

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
	if not head or (head.Position - origin).Magnitude > anticheat.MaxOriginDistance then
		return nil, 0
	end

	local serverNow = workspace:GetServerTimeNow()
	return direction.Unit, math.clamp(shotTime, serverNow - anticheat.MaxRewind, serverNow)
end

local function finishReloadIfDone(run: ProgressionService.Run, now: number)
	if run.ReloadEnd and now >= run.ReloadEnd - anticheat.ReloadTolerance then
		run.Ammo = run.Stats.Magazine
		run.ReloadEnd = nil
	end
end

local function applySpread(direction: Vector3, spread: number): Vector3
	if spread <= 0 then
		return direction
	end
	local rotation = CFrame.Angles(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), 0)
	return (CFrame.lookAt(Vector3.zero, direction) * rotation).LookVector
end

local function onShoot(player: Player, origin: any, direction: any, shotTime: any)
	local run = ProgressionService.getRun(player)
	if not run then
		return
	end
	local stats = run.Stats

	local now = os.clock()
	if run.LastShot and now - run.LastShot < (1 / stats.FireRate) * anticheat.FireRateTolerance then
		return
	end
	finishReloadIfDone(run, now)
	if run.ReloadEnd or run.Ammo <= 0 then
		return
	end

	local aim, time = CombatService.validateAim(player, origin, direction, shotTime)
	if not aim then
		return
	end

	run.Ammo -= 1
	run.LastShot = now

	for _ = 1, stats.Pellets do
		local pelletDirection = applySpread(aim, stats.Spread)
		for _, enemyId in EnemyService.raycast(origin, pelletDirection, weapon.Range, time, stats.Pierce + 1) do
			local damage = stats.Damage
			if random:NextNumber() < stats.CritChance then
				damage *= weapon.CritMultiplier
			end
			EnemyService.damage(enemyId, damage, player)
		end
	end
end

local function onReload(player: Player)
	local run = ProgressionService.getRun(player)
	if not run then
		return
	end
	local now = os.clock()
	finishReloadIfDone(run, now)
	if run.ReloadEnd or run.Ammo >= run.Stats.Magazine then
		return
	end
	run.ReloadEnd = now + run.Stats.ReloadTime
end

function CombatService.init()
	Remotes.Shoot.OnServerEvent:Connect(onShoot)
	Remotes.Reload.OnServerEvent:Connect(onReload)
end

return CombatService
