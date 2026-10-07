-- El cielo de cada cliente:
--   * Ciclo de día y noche: mueve la hora y los colores de la luz según el
--     reloj del servidor (todos ven la misma hora sin gastar red).
--   * En pixel art 3D: nubes de bloques que cruzan el cielo, esporas de
--     cubitos blancos que flotan con el viento (de día y de noche) y luciérnagas
--     de cubitos alrededor del jugador cuando es de noche.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local DayCycle = require(Shared.DayCycle)
local ResolvedAssets = require(Shared.ResolvedAssets)

local PALETTE_INTERVAL = 0.25
local CLOUD_COUNT = 18
local CLOUD_SPEED = 5
local CLOUD_RANGE = 900
local FIREFLY_COUNT = 40
local FIREFLY_RADIUS = 60
local CLOUD_DAY = Color3.fromRGB(250, 250, 255)
local CLOUD_NIGHT = Color3.fromRGB(56, 62, 92)
local FIREFLY_COLOR = Color3.fromRGB(220, 255, 140)
local MOTE_COUNT = 55
local MOTE_RADIUS = 55
local MOTE_COLORS = { Color3.fromRGB(240, 240, 228), Color3.fromRGB(226, 214, 186), Color3.fromRGB(255, 255, 255) }

type Cloud = { Parts: { BasePart }, Offsets: { Vector3 }, Position: Vector3 }
type Firefly = { Part: BasePart, Home: Vector3, Phase: number }

local SkyFx = {}

local voxel = Config.Style.Blocky
local theme = Config.Themes[Config.Theme] or {}
local nightFactor = if theme.Night then 1 else 0
local lastPalette = -math.huge
-- Cielo rojo que crece con las oleadas (DayCycle.getRedness), suavizado
local redness = 0
local redMoon = false
local random = Random.new()
local folder: Folder
local clouds: { Cloud } = {}
local fireflies: { Firefly } = {}
local motes: { Firefly } = {}
local moteVisible = false
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

local function buildMotes()
	for index = 1, MOTE_COUNT do
		local size = random:NextNumber(0.25, 0.6)
		local part = newBlock(Vector3.one * size, MOTE_COLORS[random:NextInteger(1, #MOTE_COLORS)], Enum.Material.SmoothPlastic)
		part.Transparency = 1
		table.insert(motes, { Part = part, Home = Vector3.new(0, -500, 0), Phase = index * 2.1 })
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

-- Esporas: flotan a favor del viento subiendo y bajando; las que se alejan
-- vuelven a aparecer cerca del jugador
local function updateMotes(dt: number, clock: number)
	local visible = not reduced
	if visible ~= moteVisible then
		moteVisible = visible
		for _, mote in motes do
			mote.Part.Transparency = if visible then 0.1 else 1
		end
	end
	if not visible then
		return
	end
	local camera = workspace.CurrentCamera.CFrame.Position
	local wind = workspace.GlobalWind * 0.12
	for _, mote in motes do
		local offset = mote.Home - camera
		if Vector3.new(offset.X, 0, offset.Z).Magnitude > MOTE_RADIUS + 10 or mote.Home.Y > 16 then
			local angle = random:NextNumber(0, math.pi * 2)
			local radius = random:NextNumber(6, MOTE_RADIUS)
			mote.Home = Vector3.new(camera.X + math.cos(angle) * radius, random:NextNumber(0.5, 9), camera.Z + math.sin(angle) * radius)
		end
		mote.Home += (wind + Vector3.new(0, 0.15, 0)) * dt
		local phase = clock * 0.7 + mote.Phase
		table.insert(parts, mote.Part)
		table.insert(cframes, CFrame.new(mote.Home + Vector3.new(math.sin(phase) * 0.8, math.sin(phase * 1.3) * 0.5, math.cos(phase * 0.8) * 0.8)) * CFrame.Angles(phase, phase * 0.7, 0))
	end
end

-- Con el cielo muy rojo la luna se vuelve de sangre (si se subió MoonRed)
local function updateMoon()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	local wantRed = redness >= Config.DayCycle.BloodMoon.RedMoonAt
	if not sky or wantRed == redMoon then
		return
	end
	local texture = ResolvedAssets.get(if wantRed then "Sky.MoonRed" else "Sky.Moon")
	if texture ~= "" then
		sky.MoonTextureId = texture
		redMoon = wantRed
	end
end

function SkyFx.step(dt: number)
	local now = workspace:GetServerTimeNow()
	local gameState = ReplicatedStorage:FindFirstChild("GameState")
	local wave = gameState and gameState:GetAttribute("Wave") or 0
	redness += (DayCycle.getRedness(wave) - redness) * math.min(1, dt * 0.4)
	if DayCycle.isEnabled() then
		local clock = DayCycle.getClock(now)
		nightFactor = DayCycle.getNightFactor(clock)
		-- La hora se mueve en cada cuadro; los colores, varias veces por segundo
		if os.clock() - lastPalette >= PALETTE_INTERVAL then
			lastPalette = os.clock()
			DayCycle.applyLighting(clock, redness)
			updateMoon()
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
	updateMotes(dt, os.clock())
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
	buildMotes()
end

return SkyFx
