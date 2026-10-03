-- El arma y las manos que se ven en primera persona. Son piezas locales
-- pegadas a la cámara, con retroceso, balanceo al caminar y animación de recarga.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local GUNMETAL = Color3.fromRGB(48, 48, 54)
local STEEL = Color3.fromRGB(125, 128, 138)
local DARK = Color3.fromRGB(28, 28, 32)
local GRIP = Color3.fromRGB(150, 95, 50)
local SKIN = Color3.fromRGB(150, 105, 80)
local SLEEVE = Color3.fromRGB(60, 70, 60)
local FLASH = Color3.fromRGB(255, 210, 90)

local BASE_OFFSET = CFrame.new(1.05, -1.05, -2.1)
local MUZZLE_OFFSET = CFrame.new(0, 0.1, -1.3)
local FIELD_OF_VIEW = 80

-- Piezas relativas al centro del arma (el cañón apunta hacia -Z)
local PIECES = {
	{ Size = Vector3.new(0.34, 0.36, 1.5), Offset = CFrame.new(0, 0, 0), Color = GUNMETAL },
	{ Size = Vector3.new(0.36, 0.14, 1.45), Offset = CFrame.new(0, 0.24, -0.02), Color = STEEL },
	{ Size = Vector3.new(0.37, 0.15, 0.06), Offset = CFrame.new(0, 0.24, 0.4), Color = DARK },
	{ Size = Vector3.new(0.37, 0.15, 0.06), Offset = CFrame.new(0, 0.24, 0.52), Color = DARK },
	{ Size = Vector3.new(0.37, 0.15, 0.06), Offset = CFrame.new(0, 0.24, 0.64), Color = DARK },
	{ Size = Vector3.new(0.18, 0.18, 0.5), Offset = CFrame.new(0, 0.1, -0.95), Color = GUNMETAL },
	{ Size = Vector3.new(0.07, 0.12, 0.07), Offset = CFrame.new(0, 0.37, -0.62), Color = DARK },
	{ Size = Vector3.new(0.24, 0.12, 0.07), Offset = CFrame.new(0, 0.37, 0.62), Color = DARK },
	{ Size = Vector3.new(0.3, 0.7, 0.36), Offset = CFrame.new(0, -0.42, 0.42) * CFrame.Angles(-0.25, 0, 0), Color = GRIP },
	{ Size = Vector3.new(0.06, 0.22, 0.35), Offset = CFrame.new(0, -0.26, 0.05), Color = DARK },
	-- Mano y antebrazo derechos
	{ Size = Vector3.new(0.42, 0.36, 0.5), Offset = CFrame.new(0.02, -0.5, 0.48) * CFrame.Angles(-0.25, 0, 0), Color = SKIN },
	{ Size = Vector3.new(0.4, 0.4, 1.8), Offset = CFrame.new(0.12, -0.8, 1.45) * CFrame.Angles(0.35, 0, 0), Color = SKIN },
	{ Size = Vector3.new(0.46, 0.46, 0.8), Offset = CFrame.new(0.14, -1.05, 2.15) * CFrame.Angles(0.35, 0, 0), Color = SLEEVE },
	-- Mano y antebrazo izquierdos sosteniendo el arma desde abajo
	{ Size = Vector3.new(0.42, 0.32, 0.5), Offset = CFrame.new(-0.12, -0.32, 0.05), Color = SKIN },
	{ Size = Vector3.new(0.38, 0.38, 1.7), Offset = CFrame.new(-0.7, -0.7, 0.75) * CFrame.Angles(0.3, -0.55, 0), Color = SKIN },
	{ Size = Vector3.new(0.44, 0.44, 0.8), Offset = CFrame.new(-1.15, -0.95, 1.45) * CFrame.Angles(0.3, -0.55, 0), Color = SLEEVE },
}

local Viewmodel = {}

local folder = Instance.new("Folder")
folder.Name = "Viewmodel"

local parts: { BasePart } = {}
local offsets: { CFrame } = {}
local cframes: { CFrame } = {}
local flashPart: Part
local flashLight: PointLight

local recoil = 0
local reloadAlpha = 0
local reloading = false
local flashUntil = 0
local walkTime = 0
local muzzlePosition = Vector3.zero

local function newPart(size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	folder.Parent = if isAlive() then camera else nil
	if not folder.Parent then
		return
	end

	recoil *= math.exp(-dt * 14)
	reloadAlpha += ((if reloading then 1 else 0) - reloadAlpha) * math.min(1, dt * 10)

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1
	if moving then
		walkTime += dt
	end
	local bobX = if moving then math.sin(walkTime * 8) * 0.04 else 0
	local bobY = if moving then math.abs(math.cos(walkTime * 8)) * 0.04 else 0

	local root = camera.CFrame
		* BASE_OFFSET
		* CFrame.new(bobX, bobY - 0.5 * reloadAlpha, recoil * 0.22)
		* CFrame.Angles(recoil * 0.15 - 0.7 * reloadAlpha, 0, 0.5 * reloadAlpha)

	for index, offset in offsets do
		cframes[index] = root * offset
	end
	local muzzle = root * MUZZLE_OFFSET
	muzzlePosition = muzzle.Position
	cframes[#offsets + 1] = muzzle
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)

	local flashing = os.clock() < flashUntil
	flashPart.Transparency = if flashing then 0 else 1
	flashLight.Enabled = flashing
end

function Viewmodel.kick()
	recoil = math.min(recoil + 1, 1.6)
	flashUntil = os.clock() + 0.04
end

function Viewmodel.setReloading(value: boolean)
	reloading = value
end

function Viewmodel.getMuzzlePosition(): Vector3
	return muzzlePosition
end

function Viewmodel.init()
	for _, spec in PIECES do
		table.insert(parts, newPart(spec.Size, spec.Color))
		table.insert(offsets, spec.Offset)
	end

	flashPart = newPart(Vector3.new(0.22, 0.22, 0.22), FLASH)
	flashPart.Material = Enum.Material.Neon
	flashPart.Transparency = 1
	flashLight = Instance.new("PointLight")
	flashLight.Color = FLASH
	flashLight.Range = 14
	flashLight.Brightness = 3
	flashLight.Enabled = false
	flashLight.Parent = flashPart
	table.insert(parts, flashPart)

	workspace.CurrentCamera.FieldOfView = FIELD_OF_VIEW
	-- Después de que la cámara se mueve, para que el arma no tiemble
	RunService:BindToRenderStep("Viewmodel", Enum.RenderPriority.Camera.Value + 1, update)
end

return Viewmodel
