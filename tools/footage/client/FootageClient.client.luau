-- SOLO PARA GRABAR TRÁILERS (footage.project.json). No se publica.
-- Takes (workspace attribute "Take"): "fps" apunta y dispara solo, "orbit" gira
-- la cámara alrededor de la campana, "off" devuelve el control.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local client = player:WaitForChild("PlayerScripts"):WaitForChild("Client")
local WeaponController = require(client:WaitForChild("WeaponController"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local enemies = workspace:WaitForChild("ClientEnemies")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end)

local camera = workspace.CurrentCamera
local bell = Config.Arena.Bell
local take = "off"
local takeStart = os.clock()
local lastCycle = 0

local function nearestEnemy(): BasePart?
	local best, bestDistance = nil, 140
	for _, part in enemies:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local distance = (part.Position - camera.CFrame.Position).Magnitude
			if distance < bestDistance and distance > 6 then
				best, bestDistance = part, distance
			end
		end
	end
	return best
end

RunService:BindToRenderStep("FootageDirector", Enum.RenderPriority.Camera.Value + 10, function()
	local age = os.clock() - takeStart
	if take == "orbit" then
		camera.CameraType = Enum.CameraType.Scriptable
		local angle = age * 0.18
		local radius = 38 - math.min(age, 20) * 0.5
		local position = bell + Vector3.new(math.sin(angle) * radius, 13 + math.sin(age * 0.3) * 2, math.cos(angle) * radius)
		camera.CFrame = CFrame.lookAt(position, bell + Vector3.new(0, 7, 0))
	elseif take == "fps" then
		-- La cámara es nuestra: así el disparo sale exactamente hacia donde se ve
		camera.CameraType = Enum.CameraType.Scriptable
		local character = player.Character
		if character then
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
				end
			end
		end
		local head = character and character:FindFirstChild("Head") :: BasePart?
		local origin = if head then head.Position + Vector3.new(0, 0.3, 0) else camera.CFrame.Position
		local target = nearestEnemy()
		if target then
			local aim = CFrame.lookAt(origin, target.Position + Vector3.new(0, 1.4, 0))
			camera.CFrame = (CFrame.new(origin) * (camera.CFrame - camera.CFrame.Position)):Lerp(aim, 0.3)
			WeaponController.setTrigger(true)
		else
			camera.CFrame = CFrame.new(origin) * (camera.CFrame - camera.CFrame.Position)
			WeaponController.setTrigger(false)
		end
		local ammo = WeaponController.getAmmoState()
		if ammo == 0 then
			WeaponController.reload()
		end
		if os.clock() - lastCycle > 6.5 then
			lastCycle = os.clock()
			WeaponController.cycle()
			local _, _, _, _, melee = WeaponController.getAmmoState()
			if melee then
				WeaponController.cycle()
			end
		end
	end
end)

local function onTake()
	take = workspace:GetAttribute("Take") or "off"
	takeStart = os.clock()
	if take ~= "orbit" and take ~= "fps" then
		camera.CameraType = Enum.CameraType.Custom
	end
	if take ~= "fps" then
		WeaponController.setTrigger(false)
	end
	if take == "start" then
		Remotes.SelectDifficulty:FireServer(workspace:GetAttribute("Diff") or 3, {})
		take = "off"
	end
end
workspace:GetAttributeChangedSignal("Take"):Connect(onTake)
