-- Dibuja los goblins localmente. La posición sale de EnemyMath con el tiempo
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
local BOB_HEIGHT = 0.4
local BOB_SPEED = 10

type Visual = {
	Part: BasePart,
	Path: EnemyMath.Path,
	Color: Color3,
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

local function createPart(typeName: string, info): BasePart
	local part = Instance.new("Part")
	part.Name = typeName
	part.Size = info.Size
	part.Color = info.Color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
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
		Part = createPart(typeName, info),
		Path = EnemyMath.newPath(start, target, speed, spawnTime),
		Color = info.Color,
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

	local part = visual.Part
	if not animate then
		part:Destroy()
		return
	end
	part.Color = FLASH_COLOR
	local tween = TweenService:Create(part, TweenInfo.new(0.15), { Size = part.Size * 1.6, Transparency = 1 })
	tween.Completed:Once(function()
		part:Destroy()
	end)
	tween:Play()
end

local function flashEnemy(id: number)
	local visual = visuals[id]
	if visual then
		visual.Part.Color = FLASH_COLOR
		visual.FlashUntil = os.clock() + FLASH_TIME
	end
end

local function render()
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	table.clear(parts)
	table.clear(cframes)

	for _, visual in visuals do
		local bob = Vector3.new(0, math.abs(math.sin(clock * BOB_SPEED + visual.Phase)) * BOB_HEIGHT, 0)
		local position = EnemyMath.getPosition(visual.Path, now) + bob
		table.insert(parts, visual.Part)
		table.insert(cframes, CFrame.lookAt(position, position + visual.Path.Direction))

		if visual.FlashUntil > 0 and clock >= visual.FlashUntil then
			visual.FlashUntil = 0
			visual.Part.Color = visual.Color
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
