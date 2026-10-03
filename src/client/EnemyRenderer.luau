-- Dibuja los zombis localmente. La posición sale de EnemyMath con el tiempo
-- del servidor, y se mueven todos de una vez con BulkMoveTo.
-- Si el enemigo tiene Sprite, se dibuja como imagen pixelada que siempre mira
-- a la cámara; si no, como un muñeco de bloques.
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
local BLOCK_SWAY = 0.12
local SPRITE_SWAY = 0.06
local BOB_HEIGHT = 0.15

-- Piezas del muñeco de bloques para un zombi de 5 studs (se escala por tipo).
-- Color es el nombre del campo de color en Config.Enemies.
local BODY_PARTS = {
	{ Name = "Legs", Size = Vector3.new(1.8, 2, 1), Offset = Vector3.new(0, -1.5, 0), Color = "Pants" },
	{ Name = "Torso", Size = Vector3.new(2, 2, 1), Offset = Vector3.new(0, 0.5, 0), Color = "Shirt" },
	{ Name = "Head", Size = Vector3.new(1.1, 1.1, 1.1), Offset = Vector3.new(0, 2.05, 0), Color = "Skin" },
	{ Name = "LeftArm", Size = Vector3.new(0.5, 0.5, 1.8), Offset = Vector3.new(-0.75, 1.1, -1.1), Color = "Skin" },
	{ Name = "RightArm", Size = Vector3.new(0.5, 0.5, 1.8), Offset = Vector3.new(0.75, 1.1, -1.1), Color = "Skin" },
}

type Piece = {
	Part: BasePart,
	Offset: CFrame,
	Color: Color3,
}

type Visual = {
	Pieces: { Piece },
	Decal: Decal?,
	Path: EnemyMath.Path,
	FlashUntil: number,
	Phase: number,
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

local function newPart(name: string, size: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function createSprite(typeName: string, info): ({ Piece }, Decal)
	local part = newPart(typeName, Vector3.new(info.Size.X, info.Size.Y, 0.05))
	part.Transparency = 1
	local decal = Instance.new("Decal")
	decal.Texture = info.Sprite
	decal.Face = Enum.NormalId.Front
	decal.Parent = part
	part.Parent = folder
	return { { Part = part, Offset = CFrame.identity, Color = FLASH_COLOR } }, decal
end

local function createBlocks(info): { Piece }
	local scale = info.Size.Y / 5
	local pieces = {}
	for _, spec in BODY_PARTS do
		local color = info[spec.Color]
		local part = newPart(spec.Name, spec.Size * scale)
		part.Color = color
		part.Parent = folder
		table.insert(pieces, { Part = part, Offset = CFrame.new(spec.Offset * scale), Color = color })
	end
	return pieces
end

local function setFlash(visual: Visual, flashing: boolean)
	if visual.Decal then
		visual.Decal.Color3 = if flashing then FLASH_TINT else FLASH_COLOR
		return
	end
	for _, piece in visual.Pieces do
		piece.Part.Color = if flashing then FLASH_COLOR else piece.Color
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

	local pieces, decal
	if info.Sprite ~= "" then
		pieces, decal = createSprite(typeName, info)
	else
		pieces = createBlocks(info)
	end
	visuals[id] = {
		Pieces = pieces,
		Decal = decal,
		Path = EnemyMath.newPath(start, target, speed, spawnTime),
		FlashUntil = 0,
		Phase = id * 0.37,
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
		local goal: { [string]: any } = { Size = part.Size * 1.4 }
		if visual.Decal then
			visual.Decal.Color3 = FLASH_TINT
			TweenService:Create(visual.Decal, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		else
			part.Color = FLASH_COLOR
			goal.Transparency = 1
		end
		local tween = TweenService:Create(part, TweenInfo.new(0.2), goal)
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

local function render()
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	table.clear(parts)
	table.clear(cframes)

	for _, visual in visuals do
		local wave = math.sin(clock * SWAY_SPEED + visual.Phase)
		local position = EnemyMath.getPosition(visual.Path, now) + Vector3.new(0, math.abs(wave) * BOB_HEIGHT, 0)

		local root
		if visual.Decal then
			-- El sprite gira para mirar siempre a la cámara (solo en horizontal)
			local facing = Vector3.new(cameraPosition.X, position.Y, cameraPosition.Z)
			if (facing - position).Magnitude < 0.01 then
				facing = position - visual.Path.Direction
			end
			root = CFrame.lookAt(position, facing) * CFrame.Angles(0, 0, wave * SPRITE_SWAY)
		else
			root = CFrame.lookAt(position, position + visual.Path.Direction) * CFrame.Angles(0, 0, wave * BLOCK_SWAY)
		end

		for _, piece in visual.Pieces do
			table.insert(parts, piece.Part)
			table.insert(cframes, root * piece.Offset)
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
	Remotes.EnemySpawned.OnClientEvent:Connect(addEnemy)
	Remotes.EnemyHit.OnClientEvent:Connect(flashEnemy)
	Remotes.EnemyDied.OnClientEvent:Connect(function(id)
		removeEnemy(id, true)
	end)
	Remotes.EnemyPathsUpdated.OnClientEvent:Connect(function(updates)
		for _, update in updates do
			local visual = visuals[update[1]]
			if visual then
				visual.Path.SpawnTime = update[2]
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
