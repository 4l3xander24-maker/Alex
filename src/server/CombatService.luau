-- El cliente solo dice "disparé desde aquí hacia allá"; el servidor decide si
-- le dio a algo. Así no se puede hacer trampa mandando "maté al goblin 5".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)

local weapon = Config.Weapon
local anticheat = Config.Anticheat
local minShotInterval = (1 / weapon.FireRate) * anticheat.FireRateTolerance

local CombatService = {}

local lastShot: { [Player]: number } = {}

local function isValidNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function onShoot(player: Player, origin: any, direction: any, shotTime: any)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or typeof(shotTime) ~= "number" then
		return
	end
	if not isValidNumber(shotTime) or not isValidNumber(direction.Magnitude) or direction.Magnitude < 0.5 then
		return
	end

	local now = os.clock()
	local last = lastShot[player]
	if last and now - last < minShotInterval then
		return
	end
	lastShot[player] = now

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or (head.Position - origin).Magnitude > anticheat.MaxOriginDistance then
		return
	end

	-- Compensación de lag: usamos el momento en que el jugador disparó, con límite
	local serverNow = workspace:GetServerTimeNow()
	local time = math.clamp(shotTime, serverNow - anticheat.MaxRewind, serverNow)

	local hitId = EnemyService.raycast(origin, direction.Unit, weapon.Range, time)
	if hitId then
		EnemyService.damage(hitId, weapon.Damage, player)
	end
end

function CombatService.init()
	Remotes.Shoot.OnServerEvent:Connect(onShoot)
	Players.PlayerRemoving:Connect(function(player)
		lastShot[player] = nil
	end)
end

return CombatService
