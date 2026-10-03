-- El cielo de cada cliente:
--   * Ciclo de día y noche: mueve la hora y los colores de la luz según el
--     reloj del servidor (todos ven la misma hora sin gastar red).
--   * En pixel art 3D: nubes de bloques que cruzan el cielo y luciérnagas de
--     cubitos alrededor del jugador cuando es de noche.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)

local PALETTE_INTERVAL = 0.25
local CLOUD_COUNT = 18
local CLOUD_SPEED = 5
local CLOUD_RANGE = 900
local FIREFLY_COUNT = 40
local FIREFLY_RADIUS = 60
local CLOUD_DAY = Color3.fromRGB(250, 250, 255)
local CLOUD_NIGHT = Color3.fromRGB(56, 62, 92)
local FIREFLY_COLOR = Color3.fromRGB(220, 255, 140)

type Cloud = { Parts: { BasePart }, Offsets: { Vector3 }, Position: Vector3 }
type Firefly = { Part: BasePart, Home: Vector3, Phase: number }

local SkyFx = {}

local voxel = Config.ArtStyle == "Voxel"
local theme = Config.Themes[Config.Theme] or {}
local nightFactor = if theme.Night then 1 else 0
local lastPalette = -math.huge
local random = Random.new()
local folder: Folder
local clouds: { Cloud } = {}
local fireflies: { Firefly } = {}
local cloudShade = -1
local fireflyVisible = false
local reduced = false
local parts: { BasePart } = {}
local cframes: { CFrame } = {}

-- 0 = pleno día, 1 = noche
function SkyFx.getNightFactor(): number
	return nightFactor
end

-- Cuánto alumbran velas, antorchas y ventanas: poco de día, todo de noche
function SkyFx.getFireLevel(): number
	return 0.25 + 0.75 * nightFactor
end

-- En calidad baja no hay luciérnagas
function SkyFx.setReduced(value: boolean)
	reduced = value
end

local function newBlock(size: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function buildClouds()
	for _ = 1, CLOUD_COUNT do
		local cloud: Cloud = {
			Parts = {},
			Offsets = {},
			Position = Vector3.new(random:NextNumber(-CLOUD_RANGE, CLOUD_RANGE), random:NextNumber(250, 330), random:NextNumber(-CLOUD_RANGE, 200)),
		}
		local width, depth = random:NextNumber(60, 120), random:NextNumber(40, 70)
		table.insert(cloud.Parts, newBlock(Vector3.new(width, 14, depth), CLOUD_DAY, Enum.Material.SmoothPlastic))
		table.insert(cloud.Offsets, Vector3.zero)
		-- Bultos encima y a los lados para que no sea una caja
		for _ = 1, random:NextInteger(2, 4) do
			local size = Vector3.new(width * random:NextNumber(0.3, 0.55), random:NextNumber(8, 14), depth * random:NextNumber(0.4, 0.7))
			table.insert(cloud.Parts, newBlock(size, CLOUD_DAY, Enum.Material.SmoothPlastic))
			table.insert(cloud.Offsets, Vector3.new(random:NextNumber(-width / 3, width / 3), random:NextNumber(4, 10), random:NextNumber(-depth / 4, depth / 4)))
		end
		table.insert(clouds, cloud)
	end
end

local function buildFireflies()
	for index = 1, FIREFLY_COUNT do
		local part = newBlock(Vector3.one * 0.3, FIREFLY_COLOR, Enum.Material.Neon)
		part.Transparency = 1
		table.insert(fireflies, { Part = part, Home = Vector3.new(0, -500, 0), Phase = index * 1.3 })
	end
end

local function randomHome(center: Vector3): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(12, FIREFLY_RADIUS)
	return Vector3.new(center.X + math.cos(angle) * radius, random:NextNumber(1, 6), center.Z + math.sin(angle) * radius)
end

local function updateClouds(dt: number)
	-- El color cambia con la hora: blancas de día, azul oscuro de noche
	local shade = math.floor(nightFactor * 20 + 0.5) / 20
	local recolor = shade ~= cloudShade
	cloudShade = shade
	local color = CLOUD_DAY:Lerp(CLOUD_NIGHT, shade)
	for _, cloud in clouds do
		local x = cloud.Position.X + CLOUD_SPEED * dt
		if x > CLOUD_RANGE then
			x = -CLOUD_RANGE
		end
		cloud.Position = Vector3.new(x, cloud.Position.Y, cloud.Position.Z)
		for index, part in cloud.Parts do
			if recolor then
				part.Color = color
			end
			table.insert(parts, part)
			table.insert(cframes, CFrame.new(cloud.Position + cloud.Offsets[index]))
		end
	end
end

local function updateFireflies(clock: number)
	local visible = not reduced and nightFactor > 0.5
	if visible ~= fireflyVisible then
		fireflyVisible = visible
		for _, firefly in fireflies do
			firefly.Part.Transparency = if visible then 0 else 1
		end
	end
	if not visible then
		return
	end
	local camera = workspace.CurrentCamera.CFrame.Position
	for _, firefly in fireflies do
		local offset = firefly.Home - camera
		if Vector3.new(offset.X, 0, offset.Z).Magnitude > FIREFLY_RADIUS + 10 then
			firefly.Home = randomHome(camera)
		end
		local phase = clock * 0.8 + firefly.Phase
		local drift = Vector3.new(math.sin(phase) * 1.5, math.sin(phase * 1.7) * 0.6, math.cos(phase * 0.9) * 1.5)
		table.insert(parts, firefly.Part)
		table.insert(cframes, CFrame.new(firefly.Home + drift))
	end
end

function SkyFx.step(dt: number)
	local now = workspace:GetServerTimeNow()
	if DayCycle.isEnabled() then
		local clock = DayCycle.getClock(now)
		nightFactor = DayCycle.getNightFactor(clock)
		-- La hora se mueve en cada cuadro; los colores, varias veces por segundo
		if os.clock() - lastPalette >= PALETTE_INTERVAL then
			lastPalette = os.clock()
			DayCycle.applyLighting(clock)
		else
			Lighting.ClockTime = clock
		end
	end
	if not voxel then
		return
	end
	table.clear(parts)
	table.clear(cframes)
	updateClouds(dt)
	updateFireflies(os.clock())
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function SkyFx.init()
	if not voxel then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "VoxelSky"
	folder.Parent = workspace
	buildClouds()
	buildFireflies()
end

return SkyFx
