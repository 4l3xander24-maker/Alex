-- Disparo, munición, recarga, cambio de arma y apuntar. El cliente predice
-- todo con las mismas reglas que el servidor para que se sienta instantáneo;
-- el servidor valida y decide el daño.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local MovementController = require(script.Parent.MovementController)
local Profile = require(script.Parent.Profile)
local Viewmodel = require(script.Parent.Viewmodel)

local TRACER_COLOR = Color3.fromRGB(255, 220, 90)
local TRACER_TIME = 0.05
local SWITCH_DELAY = 0.3
local NUMBER_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }

local player = Players.LocalPlayer
local random = Random.new()

local WeaponController = {}

local equipped = "Pistol"
local ammo: { [string]: number } = {}
local triggerHeld = false
local aimHeld = false
local lastShot = 0
local reloading = false
local reloadWeapon = ""
local reloadStart = 0
local reloadEnd = 0
local enemyFolder: Instance
local onEnemyHit: () -> ()

local function isAiming(): boolean
	return aimHeld and Profile.hasTalent("Aim") and not MovementController.isSprinting()
end

local function stats(weaponId: string?)
	return Progression.getWeaponStats(Profile.get(), weaponId or equipped, isAiming())
end

local function getAmmo(weaponId: string): number
	if ammo[weaponId] == nil then
		ammo[weaponId] = stats(weaponId).Magazine
	end
	return ammo[weaponId]
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function cancelReload()
	reloading = false
	Viewmodel.setReloading(false)
end

local function showWeapon()
	Viewmodel.setWeapon(equipped, Config.Weapons[equipped].Zoom)
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

local function fire(weaponStats)
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local origin = cameraCFrame.Position
	local direction = cameraCFrame.LookVector
	Remotes.Shoot:FireServer(origin, direction, workspace:GetServerTimeNow(), isAiming())
	Viewmodel.kick(if weaponStats.Pellets > 1 or weaponStats.Damage > 5 then 1.6 else 1)

	-- Lo visual es local; el daño lo decide el servidor
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hitEnemy = false
	for _ = 1, weaponStats.Pellets do
		local pelletDirection = applySpread(direction, weaponStats.Spread)
		local result = workspace:Raycast(origin, pelletDirection * weaponStats.Range, params)
		local hitPoint = if result then result.Position else origin + pelletDirection * weaponStats.Range
		drawTracer(Viewmodel.getMuzzlePosition(), hitPoint)
		if result and result.Instance:IsDescendantOf(enemyFolder) then
			hitEnemy = true
		end
	end
	if hitEnemy then
		onEnemyHit()
	end
end

function WeaponController.equip(weaponId: string)
	if weaponId == equipped or not Profile.get().Weapons[weaponId] then
		return
	end
	cancelReload()
	equipped = weaponId
	-- Pequeña pausa al cambiar de arma (y respeta la cadencia del arma nueva)
	lastShot = math.max(lastShot, os.clock() + SWITCH_DELAY - 1 / stats().FireRate)
	showWeapon()
	Remotes.EquipWeapon:FireServer(weaponId)
end

function WeaponController.cycle()
	local owned = {}
	for _, id in Config.WeaponOrder do
		if Profile.get().Weapons[id] then
			table.insert(owned, id)
		end
	end
	local index = table.find(owned, equipped) or 0
	WeaponController.equip(owned[index % #owned + 1])
end

function WeaponController.reload()
	if reloading or not isAlive() or getAmmo(equipped) >= stats().Magazine then
		return
	end
	reloading = true
	reloadWeapon = equipped
	reloadStart = os.clock()
	reloadEnd = reloadStart + stats().ReloadTime
	Remotes.Reload:FireServer()
	Viewmodel.setReloading(true)
end

function WeaponController.setTrigger(held: boolean)
	triggerHeld = held
end

function WeaponController.setAiming(held: boolean)
	aimHeld = held
end

function WeaponController.isAiming(): boolean
	return isAiming()
end

function WeaponController.getEquipped(): string
	return equipped
end

-- Para el HUD: balas, tamaño del cargador y progreso de recarga (0-1 o nil)
function WeaponController.getAmmoState(): (number, number, number?)
	local progress = if reloading then math.clamp((os.clock() - reloadStart) / (reloadEnd - reloadStart), 0, 1) else nil
	return getAmmo(equipped), stats().Magazine, progress
end

local function update()
	local now = os.clock()
	if reloading and now >= reloadEnd then
		reloading = false
		ammo[reloadWeapon] = stats(reloadWeapon).Magazine
		Viewmodel.setReloading(false)
	end
	Viewmodel.setAiming(isAiming())

	if not triggerHeld or reloading or not isAlive() or MovementController.isSprinting() then
		return
	end
	local weaponStats = stats()
	if now - lastShot < 1 / weaponStats.FireRate then
		return
	end
	if getAmmo(equipped) > 0 then
		lastShot = now
		ammo[equipped] -= 1
		fire(weaponStats)
	end
	if ammo[equipped] <= 0 then
		WeaponController.reload()
	end
end

local function isTriggerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2
end

local function isAimInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2
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
		elseif isAimInput(input) then
			aimHeld = true
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
			WeaponController.reload()
		elseif input.KeyCode == Enum.KeyCode.ButtonY then
			WeaponController.cycle()
		else
			local slot = table.find(NUMBER_KEYS, input.KeyCode)
			if slot and Config.WeaponOrder[slot] then
				WeaponController.equip(Config.WeaponOrder[slot])
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isTriggerInput(input) then
			triggerHeld = false
		elseif isAimInput(input) then
			aimHeld = false
		end
	end)

	-- Al reaparecer: cargadores llenos
	player.CharacterAdded:Connect(function()
		table.clear(ammo)
		cancelReload()
		aimHeld = false
	end)

	Profile.Changed:Connect(function(reason)
		if reason == "Shop" then
			-- Igual que el servidor: comprar o mejorar llena los cargadores
			table.clear(ammo)
			cancelReload()
		end
		local serverEquipped = Profile.get().Equipped
		if reason ~= "Equip" and serverEquipped ~= equipped then
			equipped = serverEquipped
			cancelReload()
			showWeapon()
		end
	end)

	RunService.RenderStepped:Connect(update)
end

return WeaponController
