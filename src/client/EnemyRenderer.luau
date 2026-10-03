-- Dibuja los zombis localmente. La posición sale de EnemyMath con el tiempo
-- del servidor, y se mueven todos de una vez con BulkMoveTo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Remotes = require(Shared.Remotes)

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TIME = 0.08
local SWAY_ANGLE = 0.12
local SWAY_SPEED = 4
local BOB_HEIGHT = 0.15

-- Piezas del zombi relativas al centro de su caja (mirando hacia -Z).
-- Color es el nombre del campo de color en Config.Enemies.
local BODY_PARTS = {
	{ Name = "Legs", Size = Vector3.new(1.8, 2, 1), Offset = CFrame.new(0, -1.5, 0), Color = "Pants" },
	{ Name = "Torso", Size = Vector3.new(2, 2, 1), Offset = CFrame.new(0, 0.5, 0), Color = "Shirt" },
	{ Name = "Head", Size = Vector3.new(1.1, 1.1, 1.1), Offset = CFrame.new(0, 2.05, 0), Color = "Skin" },
	-- Brazos estirados al frente, pose clásica de zombi
	{ Name = "LeftArm", Size = Vector3.new(0.5, 0.5, 1.8), Offset = CFrame.new(-0.75, 1.1, -1.1), Color = "Skin" },
	{ Name = "RightArm", Size = Vector3.new(0.5, 0.5, 1.8), Offset = CFrame.new(0.75, 1.1, -1.1), Color = "Skin" },
}

type Piece = {
	Part: BasePart,
	Offset: CFrame,
	Color: Color3,
}

type Visual = {
	Pieces: { Piece },
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

local function createPieces(info): { Piece }
	local pieces = {}
	for _, spec in BODY_PARTS do
		local color = info[spec.Color]
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = spec.Size
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = folder
		table.insert(pieces, { Part = part, Offset = spec.Offset, Color = color })
	end
	return pieces
end

local function setColor(visual: Visual, color: Color3?)
	for _, piece in visual.Pieces do
		piece.Part.Color = color or piece.Color
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
	visuals[id] = {
		Pieces = createPieces(info),
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
		if animate then
			part.Color = FLASH_COLOR
			local tween = TweenService:Create(part, TweenInfo.new(0.2), { Size = part.Size * 1.4, Transparency = 1 })
			tween.Completed:Once(function()
				part:Destroy()
			end)
			tween:Play()
		else
			part:Destroy()
		end
	end
end

local function flashEnemy(id: number)
	local visual = visuals[id]
	if visual then
		setColor(visual, FLASH_COLOR)
		visual.FlashUntil = os.clock() + FLASH_TIME
	end
end

local function render()
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	table.clear(parts)
	table.clear(cframes)

	for _, visual in visuals do
		local wave = math.sin(clock * SWAY_SPEED + visual.Phase)
		local position = EnemyMath.getPosition(visual.Path, now) + Vector3.new(0, math.abs(wave) * BOB_HEIGHT, 0)
		-- Se tambalean de lado a lado al caminar
		local root = CFrame.lookAt(position, position + visual.Path.Direction) * CFrame.Angles(0, 0, wave * SWAY_ANGLE)
		for _, piece in visual.Pieces do
			table.insert(parts, piece.Part)
			table.insert(cframes, root * piece.Offset)
		end

		if visual.FlashUntil > 0 and clock >= visual.FlashUntil then
			visual.FlashUntil = 0
			setColor(visual, nil)
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
