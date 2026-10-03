-- Dibuja los zombis localmente. La posición sale de EnemyMath con el tiempo
-- del servidor, y se mueven todos de una vez con BulkMoveTo.
--
-- Estilo "3D": muñeco de bloques con materiales, ojos que brillan y
-- animación de caminar (y de golpear cuando llegan). Estilo "Pixel": sprite
-- que siempre mira a la cámara (si el enemigo tiene Sprite).
--
-- Optimización: los zombis detrás de la cámara no se mueven en pantalla, los
-- lejanos no se animan y los muy lejanos se actualizan cada 3 cuadros.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Remotes = require(Shared.Remotes)

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TINT = Color3.new(1, 0.35, 0.35)
local FLASH_TIME = 0.08
local SWAY_SPEED = 4
local SPRITE_SWAY = 0.06
local BOB_HEIGHT = 0.12
local graphics = Config.Graphics

-- Piezas del zombi 3D para uno de 5 studs de alto (se escala por tipo).
-- Pivot: punto de giro (cadera u hombro). Hang: dónde queda el centro de la
-- pieza respecto al pivote. Role: qué animación usa.
type PartSpec = {
	Name: string,
	Size: Vector3,
	Pivot: Vector3,
	Hang: Vector3,
	Tilt: number,
	Color: string,
	Material: Enum.Material,
	Role: string?,
}

local BODY_PARTS: { PartSpec } = {
	{ Name = "LeftLeg", Size = Vector3.new(0.8, 2, 0.9), Pivot = Vector3.new(-0.45, -0.5, 0), Hang = Vector3.new(0, -1, 0), Tilt = 0, Color = "Pants", Material = Enum.Material.Fabric, Role = "LegL" },
	{ Name = "RightLeg", Size = Vector3.new(0.8, 2, 0.9), Pivot = Vector3.new(0.45, -0.5, 0), Hang = Vector3.new(0, -1, 0), Tilt = 0, Color = "Pants", Material = Enum.Material.Fabric, Role = "LegR" },
	{ Name = "Torso", Size = Vector3.new(2, 2, 1), Pivot = Vector3.new(0, -0.5, 0), Hang = Vector3.new(0, 1, 0), Tilt = 0.18, Color = "Shirt", Material = Enum.Material.Fabric },
	{ Name = "Head", Size = Vector3.new(1.15, 1.15, 1.15), Pivot = Vector3.new(0, 1.5, -0.25), Hang = Vector3.new(0, 0.55, 0), Tilt = 0.3, Color = "Skin", Material = Enum.Material.SmoothPlastic },
	{ Name = "LeftArm", Size = Vector3.new(0.5, 0.5, 1.9), Pivot = Vector3.new(-1.25, 1.15, -0.2), Hang = Vector3.new(0, 0, -0.9), Tilt = 0, Color = "Skin", Material = Enum.Material.SmoothPlastic, Role = "ArmL" },
	{ Name = "RightArm", Size = Vector3.new(0.5, 0.5, 1.9), Pivot = Vector3.new(1.25, 1.15, -0.2), Hang = Vector3.new(0, 0, -0.9), Tilt = 0, Color = "Skin", Material = Enum.Material.SmoothPlastic, Role = "ArmR" },
	{ Name = "LeftEye", Size = Vector3.new(0.24, 0.16, 0.06), Pivot = Vector3.new(-0.25, 2.1, -0.92), Hang = Vector3.zero, Tilt = 0.3, Color = "Eyes", Material = Enum.Material.Neon },
	{ Name = "RightEye", Size = Vector3.new(0.24, 0.16, 0.06), Pivot = Vector3.new(0.25, 2.1, -0.92), Hang = Vector3.zero, Tilt = 0.3, Color = "Eyes", Material = Enum.Material.Neon },
}

type Piece = {
	Part: BasePart,
	Spec: PartSpec?,
	Color: Color3,
}

type Visual = {
	Pieces: { Piece },
	Decal: Decal?,
	Path: EnemyMath.Path,
	Speed: number,
	Scale: number,
	Facing: Vector3, -- última dirección en que caminó (por si queda quieto)
	FlashUntil: number,
	Phase: number,
	Slot: number, -- para repartir las actualizaciones de los lejanos entre cuadros
}

local EnemyRenderer = {}

local folder = Instance.new("Folder")
folder.Name = "ClientEnemies"
folder.Parent = workspace
EnemyRenderer.folder = folder

local visuals: { [number]: Visual } = {}
-- Ids que ya murieron, para ignorarlos si llegan tarde en el snapshot
local deadIds: { [number]: boolean } = {}

local parts: { BasePart } = {}
local cframes: { CFrame } = {}
local frame = 0

local function newPart(name: string, size: Vector3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function createSprite(typeName: string, info): ({ Piece }, Decal)
	local part = newPart(typeName, Vector3.new(info.Size.X, info.Size.Y, 0.05), Enum.Material.SmoothPlastic)
	part.Transparency = 1
	local decal = Instance.new("Decal")
	decal.Texture = info.Sprite
	decal.Face = Enum.NormalId.Front
	decal.Parent = part
	part.Parent = folder
	return { { Part = part, Spec = nil, Color = FLASH_COLOR } }, decal
end

local function createBody(info, scale: number): { Piece }
	local pieces = {}
	for _, spec in BODY_PARTS do
		local color = info[spec.Color]
		local part = newPart(spec.Name, spec.Size * scale, spec.Material)
		part.Color = color
		part.Parent = folder
		table.insert(pieces, { Part = part, Spec = spec, Color = color })
	end
	return pieces
end

local function setFlash(visual: Visual, flashing: boolean)
	if visual.Decal then
		visual.Decal.Color3 = if flashing then FLASH_TINT else FLASH_COLOR
		return
	end
	for _, piece in visual.Pieces do
		if piece.Spec and piece.Spec.Material ~= Enum.Material.Neon then
			piece.Part.Color = if flashing then FLASH_COLOR else piece.Color
		end
	end
end

local function addEnemy(id: number, typeName: string, start: Vector3, target: Vector3, speed: number, spawnTime: number)
	if visuals[id] or deadIds[id] then
		return
	end
	local info = Config.Enemies[typeName]
	if not info then
		return
	end

	local scale = info.Size.Y / 5
	local pieces, decal
	if Config.ZombieStyle == "Pixel" and info.Sprite ~= "" then
		pieces, decal = createSprite(typeName, info)
	else
		pieces = createBody(info, scale)
	end
	visuals[id] = {
		Pieces = pieces,
		Decal = decal,
		Path = EnemyMath.newPath(start, target, speed, spawnTime),
		Speed = speed,
		Scale = scale,
		Facing = Vector3.new(0, 0, 1),
		FlashUntil = 0,
		Phase = id * 0.37,
		Slot = id % 3,
	}
end

local function removeEnemy(id: number, animate: boolean)
	deadIds[id] = true
	local visual = visuals[id]
	if not visual then
		return
	end
	visuals[id] = nil

	for _, piece in visual.Pieces do
		local part = piece.Part
		if not animate then
			part:Destroy()
			continue
		end
		-- Se desarma: cada pieza cae y se desvanece
		local goal: { [string]: any } = { Size = part.Size * 0.6, CFrame = part.CFrame * CFrame.new(0, -1.2, 0) * CFrame.Angles(math.random() - 0.5, 0, math.random() - 0.5) }
		if visual.Decal then
			visual.Decal.Color3 = FLASH_TINT
			TweenService:Create(visual.Decal, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		else
			goal.Transparency = 1
		end
		local tween = TweenService:Create(part, TweenInfo.new(0.3), goal)
		tween.Completed:Once(function()
			part:Destroy()
		end)
		tween:Play()
	end
end

local function flashEnemy(id: number)
	local visual = visuals[id]
	if visual then
		setFlash(visual, true)
		visual.FlashUntil = os.clock() + FLASH_TIME
	end
end

-- Pose de cada pieza del zombi 3D: piernas y brazos se balancean al caminar;
-- al llegar a su objetivo golpean con los brazos.
local function bodyOffset(spec: PartSpec, scale: number, walk: number, attack: number, animate: boolean): CFrame
	local angle = 0
	if animate then
		if spec.Role == "LegL" then
			angle = walk * 0.6
		elseif spec.Role == "LegR" then
			angle = -walk * 0.6
		elseif spec.Role == "ArmL" then
			angle = walk * 0.15 + attack
		elseif spec.Role == "ArmR" then
			angle = -walk * 0.15 + attack * 0.8
		end
	end
	return CFrame.new(spec.Pivot * scale) * CFrame.Angles(angle - spec.Tilt, 0, 0) * CFrame.new(spec.Hang * scale)
end

local function render()
	frame += 1
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	local camera = workspace.CurrentCamera.CFrame
	local cameraPosition = camera.Position
	local look = camera.LookVector
	table.clear(parts)
	table.clear(cframes)

	for _, visual in visuals do
		local position = EnemyMath.getPosition(visual.Path, now)
		local toEnemy = position - cameraPosition
		local distance = toEnemy.Magnitude

		-- Detrás de la cámara no hace falta moverlo: se ubica en cuanto vuelva a verse
		local behind = distance > graphics.CullBehindDistance and toEnemy:Dot(look) < 0
		local skipFar = distance > graphics.FarDistance and frame % 3 ~= visual.Slot
		if behind or skipFar then
			continue
		end

		if visual.Path.Direction.Magnitude > 0.01 then
			visual.Facing = visual.Path.Direction
		end
		local arrived = EnemyMath.hasArrived(visual.Path, now)
		local wave = math.sin(clock * SWAY_SPEED + visual.Phase)

		if visual.Decal then
			-- El sprite gira para mirar siempre a la cámara (solo en horizontal)
			local bobbed = position + Vector3.new(0, math.abs(wave) * BOB_HEIGHT * 2, 0)
			local facing = Vector3.new(cameraPosition.X, bobbed.Y, cameraPosition.Z)
			if (facing - bobbed).Magnitude < 0.01 then
				facing = bobbed - visual.Facing
			end
			table.insert(parts, visual.Pieces[1].Part)
			table.insert(cframes, CFrame.lookAt(bobbed, facing) * CFrame.Angles(0, 0, wave * SPRITE_SWAY))
		else
			local animate = distance < graphics.AnimateDistance
			local scale = visual.Scale
			local walk = if arrived then 0 else math.sin(clock * visual.Speed * 0.9 + visual.Phase)
			local attack = if arrived then -0.5 - math.abs(math.sin(clock * 6 + visual.Phase)) * 0.9 else 0
			local bob = if arrived then 0 else math.abs(walk) * BOB_HEIGHT * scale
			local root = CFrame.lookAt(position + Vector3.new(0, bob, 0), position + Vector3.new(0, bob, 0) + visual.Facing)
				* CFrame.Angles(0, 0, wave * 0.08)
			for _, piece in visual.Pieces do
				table.insert(parts, piece.Part)
				table.insert(cframes, root * bodyOffset(piece.Spec :: PartSpec, scale, walk, attack, animate))
			end
		end

		if visual.FlashUntil > 0 and clock >= visual.FlashUntil then
			visual.FlashUntil = 0
			setFlash(visual, false)
		end
	end

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function EnemyRenderer.init()
	-- El servidor junta los eventos de cada cuadro en un solo mensaje
	Remotes.EnemySpawned.OnClientEvent:Connect(function(spawns)
		for _, entry in spawns do
			addEnemy(table.unpack(entry))
		end
	end)
	Remotes.EnemyHit.OnClientEvent:Connect(function(ids)
		for _, id in ids do
			flashEnemy(id)
		end
	end)
	Remotes.EnemyDied.OnClientEvent:Connect(function(ids)
		for _, id in ids do
			removeEnemy(id, true)
		end
	end)
	-- Cambios de camino: persiguen a un jugador, vuelven a la campana o los empujan
	Remotes.EnemyPathsUpdated.OnClientEvent:Connect(function(updates)
		for _, update in updates do
			local visual = visuals[update[1]]
			if visual then
				visual.Path = EnemyMath.newPath(update[2], update[3], visual.Speed, update[4])
			end
		end
	end)
	Remotes.EnemiesCleared.OnClientEvent:Connect(function()
		for id in visuals do
			removeEnemy(id, false)
		end
		table.clear(deadIds)
	end)

	task.spawn(function()
		local ok, snapshot = pcall(function()
			return Remotes.GetSnapshot:InvokeServer()
		end)
		if ok and type(snapshot) == "table" then
			for _, entry in snapshot do
				addEnemy(table.unpack(entry))
			end
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return EnemyRenderer
