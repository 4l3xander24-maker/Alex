-- El arma y las manos que se ven en primera persona. Son piezas locales
-- pegadas a la cámara, con retroceso, balanceo al caminar, animación de
-- recarga, tajo del machete y posición de apuntar. Cada arma tiene su propio
-- modelo de bloques, y cambia de color con cada mejora (Config.WeaponTiers).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local GUNMETAL = Color3.fromRGB(48, 48, 54)
local STEEL = Color3.fromRGB(125, 128, 138)
local DARK = Color3.fromRGB(28, 28, 32)
local WOOD = Color3.fromRGB(150, 95, 50)
local OLIVE = Color3.fromRGB(90, 100, 60)
local SKIN = Color3.fromRGB(150, 105, 80)
local SLEEVE = Color3.fromRGB(60, 70, 60)
local FLASH = Color3.fromRGB(255, 210, 90)
local LENS = Color3.fromRGB(120, 200, 255)

local SWING_TIME = 0.28

local HIP_OFFSET = CFrame.new(1.05, -1.05, -2.1)
local AIM_OFFSET = CFrame.new(0, -0.55, -1.7)
local BASE_FOV = 80

type PieceSpec = { Size: Vector3, Offset: CFrame, Color: Color3, Neon: boolean? }
type ModelSpec = { Pieces: { PieceSpec }, Muzzle: CFrame, LeftHand: Vector3 }

local function p(size: Vector3, offset: CFrame, color: Color3, neon: boolean?): PieceSpec
	return { Size = size, Offset = offset, Color = color, Neon = neon }
end

-- Piezas relativas al centro del arma (el cañón apunta hacia -Z).
-- Las piezas GUNMETAL y STEEL toman los colores del nivel de mejora.
local MODELS: { [string]: ModelSpec } = {
	Machete = {
		Muzzle = CFrame.new(0, 0.1, -2),
		-- La mano izquierda queda fuera de la vista
		LeftHand = Vector3.new(-1.6, -1.6, 0.6),
		Pieces = {
			p(Vector3.new(0.26, 0.3, 0.85), CFrame.new(0, -0.25, 0.45), WOOD),
			p(Vector3.new(0.55, 0.12, 0.18), CFrame.new(0, -0.05, 0.02), GUNMETAL),
			p(Vector3.new(0.07, 0.42, 1.7), CFrame.new(0, 0.05, -0.85), STEEL),
			p(Vector3.new(0.07, 0.3, 0.55), CFrame.new(0, 0.16, -1.85) * CFrame.Angles(0.35, 0, 0), STEEL),
			p(Vector3.new(0.08, 0.08, 1.5), CFrame.new(0, -0.17, -0.8), GUNMETAL),
		},
	},
	Pistol = {
		Muzzle = CFrame.new(0, 0.1, -1.3),
		LeftHand = Vector3.new(-0.12, -0.32, 0.05),
		Pieces = {
			p(Vector3.new(0.34, 0.36, 1.5), CFrame.new(0, 0, 0), GUNMETAL),
			p(Vector3.new(0.36, 0.14, 1.45), CFrame.new(0, 0.24, -0.02), STEEL),
			p(Vector3.new(0.37, 0.15, 0.06), CFrame.new(0, 0.24, 0.4), DARK),
			p(Vector3.new(0.37, 0.15, 0.06), CFrame.new(0, 0.24, 0.52), DARK),
			p(Vector3.new(0.18, 0.18, 0.5), CFrame.new(0, 0.1, -0.95), GUNMETAL),
			p(Vector3.new(0.07, 0.12, 0.07), CFrame.new(0, 0.37, -0.62), DARK),
			p(Vector3.new(0.24, 0.12, 0.07), CFrame.new(0, 0.37, 0.62), DARK),
			p(Vector3.new(0.3, 0.7, 0.36), CFrame.new(0, -0.42, 0.42) * CFrame.Angles(-0.25, 0, 0), WOOD),
			p(Vector3.new(0.06, 0.22, 0.35), CFrame.new(0, -0.26, 0.05), DARK),
		},
	},
	Shotgun = {
		Muzzle = CFrame.new(0, 0.1, -2.55),
		LeftHand = Vector3.new(-0.05, -0.34, -1.0),
		Pieces = {
			p(Vector3.new(0.34, 0.4, 1.0), CFrame.new(0, 0, 0.3), GUNMETAL),
			p(Vector3.new(0.2, 0.2, 2.4), CFrame.new(0, 0.1, -1.3), DARK),
			p(Vector3.new(0.16, 0.16, 1.9), CFrame.new(0, -0.12, -1.05), GUNMETAL),
			p(Vector3.new(0.32, 0.3, 0.8), CFrame.new(0, -0.12, -1.0), WOOD),
			p(Vector3.new(0.3, 0.5, 1.3), CFrame.new(0, -0.22, 1.3) * CFrame.Angles(-0.18, 0, 0), WOOD),
			p(Vector3.new(0.06, 0.08, 0.06), CFrame.new(0, 0.24, -2.45), STEEL),
			p(Vector3.new(0.3, 0.6, 0.34), CFrame.new(0, -0.45, 0.6) * CFrame.Angles(-0.3, 0, 0), WOOD),
		},
	},
	Rifle = {
		Muzzle = CFrame.new(0, 0.05, -2.3),
		LeftHand = Vector3.new(-0.05, -0.32, -1.05),
		Pieces = {
			p(Vector3.new(0.32, 0.42, 1.7), CFrame.new(0, 0, 0.1), GUNMETAL),
			p(Vector3.new(0.36, 0.34, 0.9), CFrame.new(0, 0.02, -1.1), DARK),
			p(Vector3.new(0.12, 0.12, 0.7), CFrame.new(0, 0.05, -1.9), DARK),
			p(Vector3.new(0.24, 0.8, 0.36), CFrame.new(0, -0.55, -0.35) * CFrame.Angles(0.25, 0, 0), DARK),
			p(Vector3.new(0.3, 0.5, 1.1), CFrame.new(0, -0.1, 1.4), GUNMETAL),
			p(Vector3.new(0.14, 0.18, 0.5), CFrame.new(0, 0.32, -0.1), DARK),
			p(Vector3.new(0.2, 0.06, 1.2), CFrame.new(0, 0.24, -0.4), STEEL),
			p(Vector3.new(0.28, 0.65, 0.34), CFrame.new(0, -0.45, 0.55) * CFrame.Angles(-0.3, 0, 0), DARK),
		},
	},
	Sniper = {
		Muzzle = CFrame.new(0, 0.08, -2.75),
		LeftHand = Vector3.new(-0.05, -0.3, -0.8),
		Pieces = {
			p(Vector3.new(0.3, 0.36, 1.8), CFrame.new(0, 0, 0.2), WOOD),
			p(Vector3.new(0.12, 0.12, 2.0), CFrame.new(0, 0.08, -1.7), DARK),
			p(Vector3.new(0.26, 0.26, 1.3), CFrame.new(0, 0.42, -0.1), DARK),
			p(Vector3.new(0.2, 0.2, 0.05), CFrame.new(0, 0.42, -0.76), LENS, true),
			p(Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.25, -0.5), DARK),
			p(Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.25, 0.3), DARK),
			p(Vector3.new(0.3, 0.08, 0.08), CFrame.new(0.22, 0.1, 0.5), STEEL),
			p(Vector3.new(0.3, 0.55, 1.2), CFrame.new(0, -0.15, 1.5), WOOD),
			p(Vector3.new(0.28, 0.6, 0.34), CFrame.new(0, -0.42, 0.6) * CFrame.Angles(-0.3, 0, 0), WOOD),
		},
	},
	Minigun = {
		Muzzle = CFrame.new(0, -0.03, -2.4),
		LeftHand = Vector3.new(0, 0.62, 0.1),
		Pieces = {
			p(Vector3.new(0.6, 0.6, 1.3), CFrame.new(0, -0.05, 0.2), GUNMETAL),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(-0.14, 0.05, -1.4), DARK),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(0.14, 0.05, -1.4), DARK),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(0, -0.17, -1.4), DARK),
			p(Vector3.new(0.5, 0.5, 0.15), CFrame.new(0, -0.03, -2.2), STEEL),
			p(Vector3.new(0.5, 0.5, 0.15), CFrame.new(0, -0.03, -0.9), STEEL),
			p(Vector3.new(0.12, 0.3, 0.7), CFrame.new(0, 0.4, 0.1), DARK),
			p(Vector3.new(0.5, 0.55, 0.6), CFrame.new(-0.55, -0.25, 0.3), OLIVE),
			p(Vector3.new(0.3, 0.6, 0.34), CFrame.new(0, -0.55, 0.6) * CFrame.Angles(-0.3, 0, 0), DARK),
		},
	},
}

-- Mano y antebrazo derechos (siempre en el mango)
local RIGHT_ARM = {
	p(Vector3.new(0.42, 0.36, 0.5), CFrame.new(0.02, -0.5, 0.48) * CFrame.Angles(-0.25, 0, 0), SKIN),
	p(Vector3.new(0.4, 0.4, 1.8), CFrame.new(0.12, -0.8, 1.45) * CFrame.Angles(0.35, 0, 0), SKIN),
	p(Vector3.new(0.46, 0.46, 0.8), CFrame.new(0.14, -1.05, 2.15) * CFrame.Angles(0.35, 0, 0), SLEEVE),
}

local function leftArm(hand: Vector3): { PieceSpec }
	local base = CFrame.new(hand)
	return {
		p(Vector3.new(0.42, 0.32, 0.5), base, SKIN),
		p(Vector3.new(0.38, 0.38, 1.7), base * CFrame.new(-0.58, -0.38, 0.7) * CFrame.Angles(0.3, -0.55, 0), SKIN),
		p(Vector3.new(0.44, 0.44, 0.8), base * CFrame.new(-1.03, -0.63, 1.4) * CFrame.Angles(0.3, -0.55, 0), SLEEVE),
	}
end

local Viewmodel = {}

local folder = Instance.new("Folder")
folder.Name = "Viewmodel"

local parts: { BasePart } = {}
local offsets: { CFrame } = {}
local cframes: { CFrame } = {}
local flashPart: Part
local flashLight: PointLight
local muzzleOffset = MODELS.Pistol.Muzzle

local currentWeapon = ""
local currentLevel = -1
local isMelee = false
local swingStart = -1
local recoil = 0
local reloadAlpha = 0
local aimAlpha = 0
local reloading = false
local aiming = false
local zoom = 1
local hideWhenAiming = false
local flashUntil = 0
local walkTime = 0
local muzzlePosition = Vector3.zero

local function newPart(spec: PieceSpec): Part
	local part = Instance.new("Part")
	part.Size = spec.Size
	part.Color = spec.Color
	part.Material = if spec.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
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

-- Cambia el modelo del arma. zoomFactor viene de Config.Weapons y tier de
-- Config.WeaponTiers según el nivel de mejora.
function Viewmodel.setWeapon(weaponId: string, zoomFactor: number, level: number, tier)
	if weaponId == currentWeapon and level == currentLevel then
		return
	end
	currentWeapon = weaponId
	currentLevel = level
	isMelee = weaponId == "Machete"
	zoom = zoomFactor
	-- Con mira telescópica se ve por el visor en vez del arma
	hideWhenAiming = zoomFactor >= 3

	for _, part in parts do
		if part ~= flashPart then
			part:Destroy()
		end
	end
	table.clear(parts)
	table.clear(offsets)
	table.clear(cframes)

	local model = MODELS[weaponId] or MODELS.Pistol
	muzzleOffset = model.Muzzle
	local specs = table.clone(model.Pieces)
	table.move(RIGHT_ARM, 1, #RIGHT_ARM, #specs + 1, specs)
	local left = leftArm(model.LeftHand)
	table.move(left, 1, #left, #specs + 1, specs)
	for _, spec in specs do
		local part = newPart(spec)
		-- Color del nivel de mejora: cuerpo (Main) y detalles (Accent)
		if spec.Color == GUNMETAL then
			part.Color = tier.Main
		elseif spec.Color == STEEL then
			part.Color = tier.Accent
			if tier.Glow then
				part.Material = Enum.Material.Neon
			end
		end
		table.insert(parts, part)
		table.insert(offsets, spec.Offset)
	end
	table.insert(parts, flashPart)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	aimAlpha += ((if aiming then 1 else 0) - aimAlpha) * math.min(1, dt * 14)
	camera.FieldOfView = BASE_FOV / (1 + (zoom - 1) * aimAlpha)

	local visible = isAlive() and not (hideWhenAiming and aimAlpha > 0.9)
	folder.Parent = if visible then camera else nil
	if not visible then
		return
	end

	recoil *= math.exp(-dt * 14)
	reloadAlpha += ((if reloading then 1 else 0) - reloadAlpha) * math.min(1, dt * 10)

	local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
	local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
	if moving then
		walkTime += dt * (humanoid :: Humanoid).WalkSpeed / 16
	end
	local sway = 1 - aimAlpha * 0.8
	local bobX = if moving then math.sin(walkTime * 8) * 0.05 * sway else 0
	local bobY = if moving then math.abs(math.cos(walkTime * 8)) * 0.05 * sway else 0

	local base = HIP_OFFSET:Lerp(AIM_OFFSET, aimAlpha)
	-- Tajo del machete: de arriba a la derecha hacia abajo a la izquierda
	local swing = CFrame.identity
	local swingAlpha = (os.clock() - swingStart) / SWING_TIME
	if swingAlpha >= 0 and swingAlpha <= 1 then
		local arc = math.sin(swingAlpha * math.pi)
		local sweep = swingAlpha * 2 - 1
		swing = CFrame.new(-0.7 * arc, 0.25 * arc - 0.3 * sweep, -0.4 * arc) * CFrame.Angles(-0.9 * arc, 0.8 * arc, -0.5 * sweep)
	end
	local root = camera.CFrame
		* base
		* swing
		* CFrame.new(bobX, bobY - 0.5 * reloadAlpha, recoil * 0.22)
		* CFrame.Angles(recoil * 0.15 * sway - 0.7 * reloadAlpha, 0, 0.5 * reloadAlpha)

	for index, offset in offsets do
		cframes[index] = root * offset
	end
	local muzzle = root * muzzleOffset
	muzzlePosition = muzzle.Position
	cframes[#offsets + 1] = muzzle
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)

	local flashing = os.clock() < flashUntil and not isMelee
	flashPart.Transparency = if flashing then 0 else 1
	flashLight.Enabled = flashing
end

function Viewmodel.swing()
	swingStart = os.clock()
end

function Viewmodel.kick(strength: number?)
	recoil = math.min(recoil + (strength or 1), 1.8)
	flashUntil = os.clock() + 0.04
end

function Viewmodel.setReloading(value: boolean)
	reloading = value
end

function Viewmodel.setAiming(value: boolean)
	aiming = value
end

function Viewmodel.isScoped(): boolean
	return hideWhenAiming and aimAlpha > 0.9
end

function Viewmodel.getMuzzlePosition(): Vector3
	if folder.Parent then
		return muzzlePosition
	end
	-- Sin arma visible (mirando por el visor) la bala sale de la cámara
	return (workspace.CurrentCamera.CFrame * CFrame.new(0, -0.3, -1)).Position
end

function Viewmodel.init(weaponId: string, zoomFactor: number, tier)
	flashPart = newPart(p(Vector3.new(0.22, 0.22, 0.22), CFrame.identity, FLASH, true))
	flashPart.Transparency = 1
	flashLight = Instance.new("PointLight")
	flashLight.Color = FLASH
	flashLight.Range = 14
	flashLight.Brightness = 3
	flashLight.Enabled = false
	flashLight.Parent = flashPart

	Viewmodel.setWeapon(weaponId, zoomFactor, 0, tier)
	-- Después de que la cámara se mueve, para que el arma no tiemble
	RunService:BindToRenderStep("Viewmodel", Enum.RenderPriority.Camera.Value + 1, update)
end

return Viewmodel
