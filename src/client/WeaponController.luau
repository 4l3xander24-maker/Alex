local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local TRACER_COLOR = Color3.fromRGB(255, 220, 90)
local TRACER_TIME = 0.05
local MUZZLE_OFFSET = CFrame.new(0.7, -0.5, -1.2)

local weapon = Config.Weapon
local player = Players.LocalPlayer

local WeaponController = {}

local triggerHeld = false
local lastShot = 0
local enemyFolder: Instance
local onEnemyHit: () -> ()

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
	tracer.Size = Vector3.new(0.08, 0.08, length)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = workspace.CurrentCamera
	Debris:AddItem(tracer, TRACER_TIME)
end

local function fire()
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local origin = cameraCFrame.Position
	local direction = cameraCFrame.LookVector

	Remotes.Shoot:FireServer(origin, direction, workspace:GetServerTimeNow())

	-- Lo visual es local; el daño lo decide el servidor
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local result = workspace:Raycast(origin, direction * weapon.Range, params)
	local hitPoint = if result then result.Position else origin + direction * weapon.Range

	drawTracer((cameraCFrame * MUZZLE_OFFSET).Position, hitPoint)
	if result and result.Instance:IsDescendantOf(enemyFolder) then
		onEnemyHit()
	end
end

local function canShoot(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function WeaponController.setTrigger(held: boolean)
	triggerHeld = held
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
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			triggerHeld = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			triggerHeld = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if triggerHeld and now - lastShot >= 1 / weapon.FireRate and canShoot() then
			lastShot = now
			fire()
		end
	end)
end

return WeaponController
