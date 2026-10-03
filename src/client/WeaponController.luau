-- Disparo, munición y recarga del lado del cliente. El cliente predice todo
-- con las mismas reglas que el servidor para que se sienta instantáneo; el
-- servidor valida y decide el daño.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Upgrades = require(Shared.Upgrades)
local Viewmodel = require(script.Parent.Viewmodel)

local TRACER_COLOR = Color3.fromRGB(255, 220, 90)
local TRACER_TIME = 0.05

local player = Players.LocalPlayer
local baseStats = Upgrades.baseStats()
local random = Random.new()

local WeaponController = {}

local triggerHeld = false
local lastShot = 0
local ammo = baseStats.Magazine
local knownMagazine = baseStats.Magazine
local reloading = false
local reloadStart = 0
local reloadEnd = 0
local enemyFolder: Instance
local onEnemyHit: () -> ()

local function stat(name: string): number
	return player:GetAttribute("Stat_" .. name) or baseStats[name]
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function drawTracer(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.CastShadow = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = TRACER_COLOR
	tracer.Size = Vector3.new(0.06, 0.06, length)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = workspace.CurrentCamera
	Debris:AddItem(tracer, TRACER_TIME)
end

local function applySpread(direction: Vector3, spread: number): Vector3
	if spread <= 0 then
		return direction
	end
	local rotation = CFrame.Angles(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), 0)
	return (CFrame.lookAt(Vector3.zero, direction) * rotation).LookVector
end

local function fire()
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local origin = cameraCFrame.Position
	local direction = cameraCFrame.LookVector
	Remotes.Shoot:FireServer(origin, direction, workspace:GetServerTimeNow())
	Viewmodel.kick()

	-- Lo visual es local; el daño lo decide el servidor
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hitEnemy = false
	for _ = 1, stat("Pellets") do
		local pelletDirection = applySpread(direction, stat("Spread"))
		local result = workspace:Raycast(origin, pelletDirection * Config.Weapon.Range, params)
		local hitPoint = if result then result.Position else origin + pelletDirection * Config.Weapon.Range
		drawTracer(Viewmodel.getMuzzlePosition(), hitPoint)
		if result and result.Instance:IsDescendantOf(enemyFolder) then
			hitEnemy = true
		end
	end
	if hitEnemy then
		onEnemyHit()
	end
end

function WeaponController.reload()
	if reloading or ammo >= stat("Magazine") or not isAlive() then
		return
	end
	reloading = true
	reloadStart = os.clock()
	reloadEnd = reloadStart + stat("ReloadTime")
	Remotes.Reload:FireServer()
	Viewmodel.setReloading(true)
end

function WeaponController.setTrigger(held: boolean)
	triggerHeld = held
end

-- Para el HUD: balas, tamaño del cargador y progreso de recarga (0-1 o nil)
function WeaponController.getAmmoState(): (number, number, number?)
	local progress = if reloading then math.clamp((os.clock() - reloadStart) / (reloadEnd - reloadStart), 0, 1) else nil
	return ammo, stat("Magazine"), progress
end

local function resetAmmo()
	ammo = stat("Magazine")
	knownMagazine = ammo
	reloading = false
	Viewmodel.setReloading(false)
end

local function update()
	local now = os.clock()
	if reloading and now >= reloadEnd then
		reloading = false
		ammo = stat("Magazine")
		Viewmodel.setReloading(false)
	end

	if triggerHeld and not reloading and isAlive() and now - lastShot >= 1 / stat("FireRate") then
		if ammo > 0 then
			lastShot = now
			ammo -= 1
			fire()
		end
		if ammo <= 0 then
			WeaponController.reload()
		end
	end
end

local function isTriggerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2
end

function WeaponController.init(folder: Instance, hitCallback: () -> ())
	enemyFolder = folder
	onEnemyHit = hitCallback

	if UserInputService.MouseEnabled then
		UserInputService.MouseIconEnabled = false
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if isTriggerInput(input) then
			triggerHeld = true
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
			WeaponController.reload()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isTriggerInput(input) then
			triggerHeld = false
		end
	end)

	-- Partida nueva: cargador lleno
	player:GetAttributeChangedSignal("RunId"):Connect(resetAmmo)
	-- Igual que en el servidor: un cargador más grande da las balas extra al instante
	player:GetAttributeChangedSignal("Stat_Magazine"):Connect(function()
		local magazine = stat("Magazine")
		if magazine > knownMagazine then
			ammo += magazine - knownMagazine
		end
		knownMagazine = magazine
	end)
	resetAmmo()

	RunService.RenderStepped:Connect(update)
end

return WeaponController
