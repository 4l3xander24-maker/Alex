-- Lobby: donde entra todo el mundo. Una plaza de piedra al atardecer con la
-- campana maldita en el centro y las salas (círculos de runas) alrededor. Te
-- paras en una para unirte; cuando entra el primero corre la cuenta (más corta
-- si se llena) y el grupo se va a una partida privada en el lugar Match
-- (servidor reservado solo para ellos). Alrededor: bosque de otoño con viento,
-- montañas, ranking global, un guía que explica el juego y la tienda.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Props)
local ModelLibrary = require(script.ModelLibrary)
local Leaderboard = require(script.Leaderboard)

local makePart, makeProp = Props.makePart, Props.makeProp
local rooms = Config.Rooms
local STONE = Color3.fromRGB(120, 124, 122)
local GRASS = Color3.fromRGB(104, 112, 48)
local GOLD = Color3.fromRGB(255, 215, 100)
local BRONZE = Color3.fromRGB(150, 104, 52)
local CURSE = Color3.fromRGB(255, 60, 40)
local FREE = Color3.fromRGB(80, 200, 120)
local FULL = Color3.fromRGB(230, 70, 60)
local FOLIAGE = { Color3.fromRGB(214, 120, 40), Color3.fromRGB(190, 70, 36), Color3.fromRGB(226, 170, 60), Color3.fromRGB(160, 110, 44) }
local PAD_RADIUS = 7
local PLAZA_RADIUS = 50
local BELL = Vector3.new(0, 0, -6) -- la campana gigante, centro de la plaza
local ROOM_RING = 32 -- distancia de las salas a la campana
local SPAWN = Vector3.new(0, 0, 36)
local BOARD_REFRESH = 90 -- segundos entre lecturas del ranking
local random = Random.new(5)

type Room = {
	Index: number,
	Center: Vector3,
	Members: { Player },
	EndsAt: number?,
	Launching: boolean,
	Label: TextLabel,
	Glow: { BasePart },
	Light: PointLight,
	Sparkles: ParticleEmitter,
}

local roomList: { Room } = {}
local roomOf: { [Player]: Room } = {}

-- Aviso para cada cliente (lo muestra LobbyClient)
local status = Instance.new("RemoteEvent")
status.Name = "LobbyStatus"
status.Parent = ReplicatedStorage

local function setupLighting()
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end
	-- Atardecer anaranjado con bruma: el sol bajo detrás del castillo
	Lighting.ClockTime = 17.9
	Lighting.GeographicLatitude = 25
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(70, 58, 72)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 96, 104)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local sky = Instance.new("Sky")
	sky.SunAngularSize = 14
	sky.Parent = Lighting
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.36
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(214, 152, 120)
	atmosphere.Decay = Color3.fromRGB(110, 70, 96)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1.8
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 26
	bloom.Threshold = 1.5
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.08
	grade.Contrast = 0.08
	grade.TintColor = Color3.fromRGB(255, 238, 226)
	grade.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.07
	rays.Spread = 0.6
	rays.Parent = Lighting
end

local function buildTerrain()
	local terrain = workspace.Terrain
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Grass, GRASS)
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(128, 122, 116))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(102, 80, 58))
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(760, 12, 760), Enum.Material.Grass)
	-- Lomas alrededor: tapan el borde del mundo
	for index = 0, 29 do
		local angle = index / 30 * math.pi * 2 + random:NextNumber(-0.08, 0.08)
		local radius = random:NextNumber(170, 210)
		terrain:FillBall(Vector3.new(math.cos(angle) * radius, -12, math.sin(angle) * radius), random:NextNumber(36, 62), Enum.Material.Grass)
	end
	-- La plaza es de piedra (así el pasto no la tapa) y un camino de tierra la rodea
	terrain:FillCylinder(CFrame.new(0, -2, 0), 3.6, PLAZA_RADIUS + 5, Enum.Material.Ground)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 3.6, PLAZA_RADIUS, Enum.Material.Cobblestone)
	-- Camino de entrada desde donde se aparece
	terrain:FillBlock(CFrame.new(0, -2, PLAZA_RADIUS + 18), Vector3.new(10, 3.6, 40), Enum.Material.Ground)
	pcall(function()
		(terrain :: any).Decoration = true
	end)
end

local function buildCastle(map: Instance)
	local castle = Instance.new("Model")
	castle.Name = "Castle"
	local wallZ = -66
	for x = -48, 48, 6 do
		if math.abs(x) > 6 then
			local height = random:NextNumber(12, 15)
			makePart({ Name = "Wall", Size = Vector3.new(6, height, 4), Position = Vector3.new(x, height / 2, wallZ), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.07, random), Parent = castle })
			makeProp({ Name = "Merlon", Size = Vector3.new(2.4, 2, 4), Position = Vector3.new(x, height + 1, wallZ), Material = Enum.Material.Slate, Color = STONE, Parent = castle })
		end
	end
	-- Portón en el medio con arco y rejas
	for _, side in { -1, 1 } do
		makePart({ Name = "GatePost", Size = Vector3.new(4, 20, 6), Position = Vector3.new(side * 8, 10, wallZ), Material = Enum.Material.Slate, Color = STONE, Parent = castle })
	end
	makePart({ Name = "GateTop", Size = Vector3.new(20, 5, 6), Position = Vector3.new(0, 20.5, wallZ), Material = Enum.Material.Slate, Color = STONE, Parent = castle })
	makePart({ Name = "Gate", Size = Vector3.new(12, 18, 1), Position = Vector3.new(0, 9, wallZ), Material = Enum.Material.WoodPlanks, Color = Props.Colors.DarkWood, Parent = castle })
	for x = -5, 5, 2 do
		makeProp({ Name = "GateBar", Size = Vector3.new(0.4, 18, 0.4), Position = Vector3.new(x, 9, wallZ + 0.8), Material = Enum.Material.Metal, Color = Props.Colors.Iron, Parent = castle })
	end
	for _, x in { -54, 54 } do
		makePart({ Name = "Tower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 12, 12), CFrame = CFrame.new(x, 13, wallZ) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = STONE, Parent = castle })
		for index = 0, 6 do
			local width = 13 - index * 1.8
			makePart({ Name = "TowerRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, width, width), CFrame = CFrame.new(x, 26.8 + index * 1.6, wallZ) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.ClayRoofTiles, Color = Color3.fromRGB(128, 54, 40), Parent = castle })
		end
		-- Ventana encendida
		local window = makeProp({ Name = "TowerWindow", Size = Vector3.new(2, 3, 0.3), Position = Vector3.new(x, 18, wallZ + 6), Material = Enum.Material.Neon, Color = Props.Colors.Lantern, Parent = castle })
		Props.light(window, Props.Colors.Lantern, 14, 1)
		Props.banner(castle, Vector3.new(x + (if x < 0 then 10 else -10), 0, wallZ + 2.4), 0, Color3.fromRGB(120, 30, 30))
	end
	-- Cartel con el nombre del juego sobre el portón
	local sign = makePart({ Name = "TitleSign", Size = Vector3.new(34, 7, 1), Position = Vector3.new(0, 27, wallZ + 2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 62, 38), Parent = castle })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.2
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextScaled = true
	title.TextColor3 = GOLD
	title.Text = "CAMPANA MALDITA"
	title.Parent = gui
	castle.Parent = map
end

-- La campana maldita: cuelga de un armazón de madera sobre un pedestal,
-- grietas rojas brillantes, brasas que suben y se mece despacio
local function buildBell(map: Instance)
	local model = Instance.new("Model")
	model.Name = "CursedBell"
	for index, step in { { 9, 0.8 }, { 7, 1.6 } } do
		makePart({ Name = "Pedestal" .. index, Shape = Enum.PartType.Cylinder, Size = Vector3.new(step[2], step[1] * 2, step[1] * 2), CFrame = CFrame.new(BELL + Vector3.new(0, step[2] / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = model })
	end
	local beamY = 20
	for _, side in { -1, 1 } do
		makePart({ Name = "BellPost", Size = Vector3.new(1.4, beamY, 1.4), Position = BELL + Vector3.new(side * 6, beamY / 2 + 1.6, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
		for _, z in { -1, 1 } do
			makeProp({ Name = "BellBrace", Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(BELL + Vector3.new(side * 6, 5.5, z * 2.6)) * CFrame.Angles(math.rad(z * 28), 0, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
		end
	end
	makePart({ Name = "BellBeam", Size = Vector3.new(15, 1.6, 1.8), Position = BELL + Vector3.new(0, beamY + 2.2, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
	makeProp({ Name = "BellRoof", Size = Vector3.new(16, 0.6, 5), Position = BELL + Vector3.new(0, beamY + 3.4, 0), Material = Enum.Material.WoodPlanks, Color = Props.Colors.Wood, Parent = model })

	-- Campana: corona, cuerpo que se ensancha y labio
	local pivot = BELL + Vector3.new(0, beamY + 1.4, 0)
	local pieces = {}
	local function piece(props: { [string]: any })
		props.Parent = model
		local part = makeProp(props)
		table.insert(pieces, part)
		return part
	end
	for _, x in { -0.6, 0.6 } do
		piece({ Name = "BellChain", Size = Vector3.new(0.25, 2, 0.25), Position = pivot + Vector3.new(x, -0.6, 0), Material = Enum.Material.Metal, Color = Props.Colors.Iron })
	end
	piece({ Name = "BellCrown", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 2.6, 2.6), CFrame = CFrame.new(pivot + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = BRONZE })
	local top, bottom = pivot.Y - 2.5, pivot.Y - 10.5
	local segments = 6
	for index = 0, segments - 1 do
		local alpha = index / (segments - 1)
		local height = (top - bottom) / segments
		local radius = 2.4 + 2.4 * alpha ^ 1.6
		piece({ Name = "BellBody", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height + 0.05, radius * 2, radius * 2), CFrame = CFrame.new(pivot.X, top - height * (index + 0.5), pivot.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Props.vary(BRONZE, 0.05, random) })
	end
	piece({ Name = "BellLip", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 10.6, 10.6), CFrame = CFrame.new(pivot.X, bottom, pivot.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 80, 40) })
	-- Grietas que brillan en rojo por los cuatro lados
	for index = 0, 3 do
		local angle = index * math.pi / 2 + 0.4
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		for step = 0, 2 do
			local y = bottom + 1.4 + step * 1.9
			local radius = 2.4 + 2.4 * (1 - (y - bottom) / (top - bottom)) ^ 1.6
			local at = Vector3.new(pivot.X, y, pivot.Z) + out * (radius + 0.02)
			piece({ Name = "Crack", Size = Vector3.new(0.18, 2.1, 0.12), CFrame = CFrame.lookAt(at, at + out) * CFrame.Angles(0, 0, math.rad((step % 2 * 2 - 1) * 24)), Material = Enum.Material.Neon, Color = CURSE, CastShadow = false })
		end
	end
	local clapper = piece({ Name = "Clapper", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, Position = Vector3.new(pivot.X, bottom - 0.4, pivot.Z), Material = Enum.Material.Metal, Color = Props.Colors.Iron })
	for _, part in pieces do
		Props.sway(part, pivot, 0.035)
	end
	-- Luz roja y brasas
	local glow = makeProp({ Name = "CurseGlow", Size = Vector3.one, Position = Vector3.new(pivot.X, bottom + 2, pivot.Z), Transparency = 1, CastShadow = false, Parent = model })
	Props.flickerLight(glow, CURSE, 26, 2.2)
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Rate = 8
	embers.Lifetime = NumberRange.new(2.5, 4)
	embers.Speed = NumberRange.new(1.5, 3)
	embers.SpreadAngle = Vector2.new(35, 35)
	embers.Acceleration = Vector3.new(0, 1.2, 0)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), CURSE)
	embers.LightEmission = 1
	embers.Parent = clapper
	-- Velas alrededor del pedestal
	for index = 0, 5 do
		local angle = index / 6 * math.pi * 2
		Props.candles(model, BELL + Vector3.new(math.cos(angle) * 8, 0.8, math.sin(angle) * 8), 3, index % 2 == 0)
	end
	model.Parent = map
end

-- Árbol de otoño de la tienda que se mece; de bloques si no hay modelo
local function buildTree(map: Instance, position: Vector3)
	local height = random:NextNumber(14, 22)
	local name = if random:NextNumber() < 0.7 then "TreeB" else "TreeA"
	local model = ModelLibrary.place(name, CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), { Height = height }, false, map)
	if model then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				Props.sway(part, position, 0.02)
			end
		end
	else
		makePart({ Name = "Trunk", Size = Vector3.new(1.4, height * 0.6, 1.4), Position = position + Vector3.new(0, height * 0.3, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = map })
		for _ = 1, 3 do
			local leaves = makeProp({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.one * height * random:NextNumber(0.35, 0.5), Position = position + Vector3.new(random:NextNumber(-2, 2), height * random:NextNumber(0.6, 0.8), random:NextNumber(-2, 2)), Material = Enum.Material.Grass, Color = FOLIAGE[random:NextInteger(1, #FOLIAGE)], Parent = map })
			Props.sway(leaves, position, 0.02)
		end
	end
	-- Algunos sueltan hojas que caen girando con el viento
	if random:NextNumber() < 0.4 then
		local box = makeProp({ Name = "LeafFall", Size = Vector3.new(height * 0.6, height * 0.25, height * 0.6), Position = position + Vector3.new(0, height * 0.65, 0), Transparency = 1, CastShadow = false, CanCollide = false, Parent = map })
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "LeafEmitter"
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emitter.Rate = random:NextNumber(0.6, 1.4)
		emitter.Lifetime = NumberRange.new(5, 8)
		emitter.Speed = NumberRange.new(0.2, 0.8)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Config.Wind.Direction.Unit * 0.9 + Vector3.new(0, -1.6, 0)
		emitter.Drag = 0.4
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-120, 120)
		emitter.Size = NumberSequence.new(0.32)
		emitter.LightInfluence = 1
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.Color = ColorSequence.new(FOLIAGE[random:NextInteger(1, #FOLIAGE)], FOLIAGE[random:NextInteger(1, #FOLIAGE)])
		emitter.Parent = box
	end
end

local function buildScenery(map: Instance)
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	-- Bosque alrededor de la plaza (deja libre el castillo y el camino de entrada)
	local placed = 0
	while placed < 80 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(PLAZA_RADIUS + 12, 150)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local nearCastle = position.Z < -50 and math.abs(position.X) < 75
		local onPath = position.Z > PLAZA_RADIUS and math.abs(position.X) < 10
		if not nearCastle and not onPath then
			buildTree(scenery, position)
			placed += 1
		end
	end
	-- Montañas lejanas (estiradas a lo ancho y alto que queremos, lejos de la plaza)
	for index = 0, 13 do
		local angle = index / 14 * math.pi * 2 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(420, 500)
		local height = random:NextNumber(140, 220)
		local width = random:NextNumber(200, 280)
		local base = Vector3.new(math.cos(angle) * radius, -height * 0.06, math.sin(angle) * radius)
		local name = if random:NextNumber() < 0.3 then "MountainC" elseif random:NextNumber() < 0.5 then "MountainA" else "MountainB"
		local mountain = ModelLibrary.placeStretched(name, CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), Vector3.new(width, height, width), scenery)
		if mountain then
			mountain.CastShadow = false
		end
	end
	-- Luciérnagas sobre la plaza
	local air = makeProp({ Name = "Fireflies", Size = Vector3.new(PLAZA_RADIUS * 2.4, 10, PLAZA_RADIUS * 2.4), Position = Vector3.new(0, 6, 0), Transparency = 1, CastShadow = false, CanCollide = false, Parent = scenery })
	local fireflies = Instance.new("ParticleEmitter")
	fireflies.Name = "LeafEmitter" -- se apaga en calidad baja como las hojas
	fireflies.Shape = Enum.ParticleEmitterShape.Box
	fireflies.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	fireflies.Rate = 6
	fireflies.Lifetime = NumberRange.new(4, 7)
	fireflies.Speed = NumberRange.new(0.3, 0.8)
	fireflies.SpreadAngle = Vector2.new(180, 180)
	fireflies.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.18), NumberSequenceKeypoint.new(0.8, 0.18), NumberSequenceKeypoint.new(1, 0) })
	fireflies.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
	fireflies.LightEmission = 1
	fireflies.Parent = air
	-- Antorchas en el borde de la plaza y faroles en el camino
	for index = 0, 13 do
		local angle = index / 14 * math.pi * 2
		local position = Vector3.new(math.cos(angle) * (PLAZA_RADIUS - 2), 0, math.sin(angle) * (PLAZA_RADIUS - 2))
		if not (position.Z > PLAZA_RADIUS - 8 and math.abs(position.X) < 8) then
			Props.torch(scenery, position)
		end
	end
	for _, z in { PLAZA_RADIUS + 6, PLAZA_RADIUS + 22 } do
		for _, side in { -1, 1 } do
			Props.hangingLantern(scenery, Vector3.new(side * 7, 0, z), Vector3.new(-side, 0, 0))
		end
	end
	scenery.Parent = map
end

-- Tablero de madera con texto. Devuelve las filas para llenarlas después.
local function buildBoard(map: Instance, position: Vector3, title: string, rows: number): { TextLabel }
	local frame = CFrame.lookAt(position, Vector3.new(SPAWN.X, position.Y, SPAWN.Z + 10))
	local model = Instance.new("Model")
	model.Name = "Leaderboard"
	for _, side in { -1, 1 } do
		makePart({ Name = "BoardPost", Size = Vector3.new(0.9, 16, 0.9), CFrame = frame * CFrame.new(side * 6.6, 8, 0.4), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
	end
	local board = makePart({ Name = "Board", Size = Vector3.new(12.6, 13, 0.6), CFrame = frame * CFrame.new(0, 8.6, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(86, 58, 36), Parent = model })
	makeProp({ Name = "BoardRoof", Size = Vector3.new(14.4, 0.5, 2.6), CFrame = frame * CFrame.new(0, 15.5, 0.2) * CFrame.Angles(math.rad(-12), 0, 0), Material = Enum.Material.WoodPlanks, Color = Props.Colors.DarkWood, Parent = model })
	Props.hangingLantern(model, (frame * CFrame.new(7.8, 0, -0.6)).Position, frame.RightVector)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.25
	gui.Parent = board
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 26)
	padding.PaddingRight = UDim.new(0, 26)
	padding.Parent = gui
	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, 0, 0, 62)
	heading.BackgroundTransparency = 1
	heading.Font = Enum.Font.Arcade
	heading.TextScaled = true
	heading.TextColor3 = GOLD
	heading.Text = title
	heading.LayoutOrder = 0
	heading.Parent = gui
	local labels = {}
	for index = 1, rows do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 38)
		row.BackgroundTransparency = if index % 2 == 0 then 1 else 0.85
		row.BackgroundColor3 = Color3.new(0, 0, 0)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if index == 1 then GOLD elseif index <= 3 then Color3.fromRGB(230, 230, 230) else Color3.fromRGB(200, 186, 170)
		row.Text = ""
		row.LayoutOrder = index
		row.Parent = gui
		table.insert(labels, row)
	end
	model.Parent = map
	return labels
end

local names: { [number]: string } = {}
local function nameOf(userId: number): string
	if not names[userId] then
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		names[userId] = if ok then name else `#{userId}`
	end
	return names[userId]
end

local function fillBoard(labels: { TextLabel }, stat: string, suffix: string)
	local rows = Leaderboard.top(stat, #labels)
	for index, label in labels do
		local row = rows and rows[index]
		if row then
			label.Text = `  {index}. {nameOf(row.UserId)}  ·  {row.Value} {suffix}`
		elseif index == 1 and not rows then
			label.Text = "  Ranking sin conexión (solo en Roblox)"
		elseif index == 1 then
			label.Text = "  ¡Sé el primero!"
		else
			label.Text = ""
		end
	end
end

-- Personaje de malla de la tienda parado en `cframe` (5.6 de alto)
local function placeNpc(map: Instance, name: string, cframe: CFrame): Model?
	local mesh = ModelLibrary.clone(name)
	if not mesh then
		return nil
	end
	local low, high = math.huge, -math.huge
	local torso: BasePart? = nil
	for _, descendant in mesh:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			if descendant.Transparency < 1 then
				low = math.min(low, descendant.Position.Y - descendant.Size.Y / 2)
				high = math.max(high, descendant.Position.Y + descendant.Size.Y / 2)
			end
			if descendant.Name == "UpperTorso" or descendant.Name == "Torso" then
				torso = descendant
			end
		end
	end
	if not torso or high <= low then
		mesh:Destroy()
		return nil
	end
	local look = torso.CFrame.LookVector
	local base = Vector3.new(torso.Position.X, low, torso.Position.Z)
	mesh.WorldPivot = CFrame.lookAt(base, base + Vector3.new(look.X, 0, look.Z).Unit)
	mesh:ScaleTo(5.6 / (high - low))
	mesh:PivotTo(cframe)
	-- La ropa clásica solo se dibuja con un Humanoid: uno quieto y sin nombre
	local clothing = mesh:FindFirstChildWhichIsA("Shirt", true) or mesh:FindFirstChildWhichIsA("Pants", true)
	if clothing and clothing.Parent and not clothing.Parent:FindFirstChildOfClass("Humanoid") then
		local humanoid = Instance.new("Humanoid")
		humanoid.RigType = Enum.HumanoidRigType.R15
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.EvaluateStateMachine = false
		humanoid.RequiresNeck = false
		humanoid.BreakJointsOnDeath = false
		humanoid.Parent = clothing.Parent
	end
	mesh.Parent = map
	return mesh
end

local function addPrompt(map: Instance, name: string, position: Vector3, action: string, object: string)
	local anchor = makeProp({ Name = name .. "Anchor", Size = Vector3.new(1, 1, 1), Position = position, Transparency = 1, CanCollide = false, Parent = map })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
end

local function floatingTag(parent: Instance, adornee: BasePart, title: string, subtitle: string, color: Color3)
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(220, 56)
	board.StudsOffset = Vector3.new(0, 4.2, 0)
	board.MaxDistance = 70
	board.Adornee = adornee
	board.Parent = parent
	local top = Instance.new("TextLabel")
	top.Size = UDim2.fromScale(1, 0.6)
	top.BackgroundTransparency = 1
	top.Font = Enum.Font.GothamBlack
	top.TextScaled = true
	top.TextColor3 = color
	top.TextStrokeTransparency = 0.3
	top.Text = title
	top.Parent = board
	local bottom = top:Clone()
	bottom.Position = UDim2.fromScale(0, 0.6)
	bottom.Size = UDim2.fromScale(1, 0.4)
	bottom.Font = Enum.Font.GothamBold
	bottom.TextColor3 = Color3.new(1, 1, 1)
	bottom.Text = subtitle
	bottom.Parent = board
end

-- Guía que explica el juego (el diálogo lo muestra el cliente)
local function buildGuide(map: Instance)
	local position = Vector3.new(-13, 0, 24)
	local frame = CFrame.lookAt(position, Vector3.new(SPAWN.X, 0, SPAWN.Z))
	local npc = placeNpc(map, "NpcMystic", frame)
	if not npc then
		makePart({ Name = "GuideBody", Size = Vector3.new(2, 5, 1), CFrame = frame * CFrame.new(0, 2.5, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(70, 50, 100), Parent = map })
	end
	Props.torch(map, position + frame.RightVector * 3)
	addPrompt(map, "GuidePrompt", position + Vector3.new(0, 3, 0), "Hablar", "Guía")
	floatingTag(map, map:FindFirstChild("GuidePromptAnchor") :: BasePart, "❗ Ermitaño Tobías", "¿Primera vez? Háblame", GOLD)
end

-- Puesto de la tienda de skins (abre con la monetización)
local function buildShop(map: Instance)
	local position = Vector3.new(14, 0, 24)
	local frame = CFrame.lookAt(position, Vector3.new(SPAWN.X, 0, SPAWN.Z))
	local model = Instance.new("Model")
	model.Name = "SkinShop"
	for _, x in { -4, 4 } do
		for _, z in { -2, 2 } do
			makePart({ Name = "StallPost", Size = Vector3.new(0.5, 8, 0.5), CFrame = frame * CFrame.new(x, 4, z), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
		end
	end
	makePart({ Name = "Counter", Size = Vector3.new(8.6, 3, 1.4), CFrame = frame * CFrame.new(0, 1.5, -2.2), Material = Enum.Material.WoodPlanks, Color = Props.Colors.Wood, Parent = model })
	-- Toldo a rayas moradas y doradas
	for index = 0, 6 do
		makeProp({ Name = "Canopy", Size = Vector3.new(1.3, 0.3, 5.6), CFrame = frame * CFrame.new(-3.9 + index * 1.3, 8.4, 0) * CFrame.Angles(math.rad(10), 0, 0), Material = Enum.Material.Fabric, Color = if index % 2 == 0 then Color3.fromRGB(110, 50, 150) else GOLD, Parent = model })
	end
	-- Maniquíes con capas de colores (las skins que vendrán)
	for index, color in { Color3.fromRGB(160, 40, 40), Color3.fromRGB(40, 90, 160), Color3.fromRGB(40, 130, 70) } do
		local at = frame * CFrame.new(-3 + (index - 1) * 3, 0, 0.6)
		makePart({ Name = "MannequinStand", Size = Vector3.new(0.3, 3.2, 0.3), CFrame = at * CFrame.new(0, 1.6, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
		makePart({ Name = "Cape", Size = Vector3.new(1.8, 2.4, 0.9), CFrame = at * CFrame.new(0, 4.2, 0), Material = Enum.Material.Fabric, Color = color, Parent = model })
		makePart({ Name = "MannequinHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, CFrame = at * CFrame.new(0, 6, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(220, 200, 170), Parent = model })
	end
	Props.sign(model, frame * CFrame.new(0, 9.4, -2.9), "SKINS", GOLD)
	Props.crate(model, frame * CFrame.new(5.6, 0, -1.4), 1.8)
	Props.barrel(model, (frame * CFrame.new(-5.6, 0, -1.2)).Position)
	model.Parent = map
	addPrompt(map, "ShopPrompt", (frame * CFrame.new(0, 3, -3)).Position, "Ver tienda", "Skins")
	floatingTag(map, map:FindFirstChild("ShopPromptAnchor") :: BasePart, "🛒 Tienda de skins", "¡Muy pronto!", Color3.fromRGB(200, 150, 255))
end

local function buildSpawn(map: Instance)
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.lookAt(SPAWN + Vector3.new(0, 0.5, 0), BELL + Vector3.new(0, 0.5, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map
end

local function buildRoom(map: Instance, index: number, center: Vector3): Room
	local model = Instance.new("Model")
	model.Name = "Room" .. index
	local outward = Vector3.new(center.X - BELL.X, 0, center.Z - BELL.Z).Unit
	local glow: { BasePart } = {}
	makePart({ Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, PAD_RADIUS * 2, PAD_RADIUS * 2), CFrame = CFrame.new(center + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = Color3.fromRGB(32, 32, 38), Parent = model })
	table.insert(glow, makeProp({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, PAD_RADIUS * 2 + 1, PAD_RADIUS * 2 + 1), CFrame = CFrame.new(center + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Neon, Color = FREE, Parent = model }))
	-- Runas: un círculo interior de marcas y piedras alrededor
	for step = 0, 11 do
		local angle = step / 12 * math.pi * 2
		local at = center + Vector3.new(math.cos(angle) * 4.6, 0.52, math.sin(angle) * 4.6)
		table.insert(glow, makeProp({ Name = "Rune", Size = Vector3.new(0.3, 0.08, 1.4), CFrame = CFrame.lookAt(at, center + Vector3.new(0, 1.02, 0)) * CFrame.Angles(0, math.rad(step % 2 * 50 - 25), 0), Material = Enum.Material.Neon, Color = FREE, CastShadow = false, Parent = model }))
	end
	for step = 0, 5 do
		local angle = step / 6 * math.pi * 2 + 0.3
		local at = center + Vector3.new(math.cos(angle) * (PAD_RADIUS + 1.6), 0, math.sin(angle) * (PAD_RADIUS + 1.6))
		local stone = makePart({ Name = "RuneStone", Size = Vector3.new(1.2, 2.4, 0.8), CFrame = CFrame.lookAt(at + Vector3.new(0, 1.2, 0), center + Vector3.new(0, 1.2, 0)), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.08, random), Parent = model })
		table.insert(glow, makeProp({ Name = "RuneMark", Size = Vector3.new(0.5, 1, 0.06), CFrame = stone.CFrame * CFrame.new(0, 0.2, -0.42), Material = Enum.Material.Neon, Color = FREE, CastShadow = false, Parent = model }))
	end
	local light = Props.light(glow[1], FREE, 16, 1.4)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Shape = Enum.ParticleEmitterShape.Disc
	sparkles.EmissionDirection = Enum.NormalId.Right -- el disco está acostado: Right apunta arriba
	sparkles.Rate = 0
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	sparkles.LightEmission = 1
	sparkles.Parent = glow[1]

	-- Arco de piedra detrás de la sala, mirando a la campana, con su cartel
	local archPosition = center + outward * (PAD_RADIUS + 1.5)
	local arch = CFrame.lookAt(archPosition, archPosition - outward)
	for _, side in { -1, 1 } do
		makePart({ Name = "ArchPost", Size = Vector3.new(1.8, 12, 1.8), CFrame = arch * CFrame.new(side * 6.5, 6, 0), Material = Enum.Material.Slate, Color = STONE, Parent = model })
		Props.torch(model, (arch * CFrame.new(side * 6.5, 0, -1.4)).Position, 4.5)
	end
	makePart({ Name = "ArchTop", Size = Vector3.new(15.6, 1.8, 1.8), CFrame = arch * CFrame.new(0, 12.9, 0), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	local sign = makePart({ Name = "RoomSign", Size = Vector3.new(11, 4.6, 0.4), CFrame = arch * CFrame.new(0, 9.4, -0.6), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(86, 58, 36), Parent = model })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.55)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextScaled = true
	title.TextColor3 = GOLD
	title.Text = `SALA {index}`
	title.Parent = gui
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.05, 0.55)
	label.Size = UDim2.fromScale(0.9, 0.4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	model.Parent = map
	return { Index = index, Center = center, Members = {}, EndsAt = nil, Launching = false, Label = label, Glow = glow, Light = light, Sparkles = sparkles }
end

local function refresh(room: Room)
	local count = #room.Members
	local text = `👥 {count}/{rooms.MaxPlayers}`
	if room.Launching then
		text ..= "  ·  ¡Saliendo!"
	elseif room.EndsAt then
		text ..= `  ·  ⏳ {math.max(0, math.ceil(room.EndsAt - os.clock()))} s`
	else
		text ..= "  ·  Párate aquí"
	end
	room.Label.Text = text
	local color = if count >= rooms.MaxPlayers then FULL elseif count > 0 then GOLD else FREE
	for _, part in room.Glow do
		part.Color = color
	end
	room.Light.Color = color
	room.Sparkles.Color = ColorSequence.new(color)
	room.Sparkles.Rate = if count > 0 then 14 else 0
	for _, player in room.Members do
		status:FireClient(player, room.Index, count, if room.EndsAt then math.max(0, math.ceil(room.EndsAt - os.clock())) else nil)
	end
end

local function leave(player: Player)
	local room = roomOf[player]
	if not room or room.Launching then
		return
	end
	roomOf[player] = nil
	local index = table.find(room.Members, player)
	if index then
		table.remove(room.Members, index)
	end
	if #room.Members == 0 then
		room.EndsAt = nil
	end
	status:FireClient(player, nil)
	refresh(room)
end

local function join(player: Player, room: Room)
	if roomOf[player] == room or room.Launching or #room.Members >= rooms.MaxPlayers then
		return
	end
	leave(player)
	roomOf[player] = room
	table.insert(room.Members, player)
	if not room.EndsAt then
		room.EndsAt = os.clock() + rooms.Countdown
	end
	if #room.Members >= rooms.MaxPlayers then
		room.EndsAt = math.min(room.EndsAt :: number, os.clock() + rooms.FullCountdown)
	end
	refresh(room)
end

-- Se van todos los de la sala a una partida privada
local function launch(room: Room)
	room.Launching = true
	refresh(room)
	local members = table.clone(room.Members)
	local ok, err = pcall(function()
		if RunService:IsStudio() then
			error("En Studio no se puede teletransportar: publica y prueba desde Roblox")
		end
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({ Room = room.Index, Players = #members })
		TeleportService:TeleportAsync(Config.Places.Match, members, options)
	end)
	if not ok then
		warn(`Sala {room.Index}: {err}`)
		for _, player in members do
			status:FireClient(player, room.Index, #members, nil, tostring(err))
		end
	end
	task.wait(if ok then 8 else 3)
	-- Quien no se fue (falló o se desconectó) vuelve a la plaza
	for _, player in members do
		roomOf[player] = nil
	end
	table.clear(room.Members)
	room.EndsAt = nil
	room.Launching = false
	refresh(room)
end

local map = Instance.new("Folder")
map.Name = "Map"
setupLighting()
buildTerrain()
buildCastle(map)
buildBell(map)
buildScenery(map)
buildSpawn(map)
buildGuide(map)
buildShop(map)
-- Las salas en semicírculo detrás de la campana, mirándola
local spread = math.rad(120)
for index = 1, rooms.Count do
	local alpha = if rooms.Count > 1 then (index - 1) / (rooms.Count - 1) else 0.5
	local angle = -math.pi / 2 - spread / 2 + spread * alpha
	local center = BELL + Vector3.new(math.cos(angle) * ROOM_RING, 0, math.sin(angle) * ROOM_RING)
	table.insert(roomList, buildRoom(map, index, center))
end
local waveBoard = buildBoard(map, Vector3.new(-38, 0, 6), "MEJOR OLEADA", 8)
local killBoard = buildBoard(map, Vector3.new(38, 0, 6), "MÁS ZOMBIS", 8)
map.Parent = workspace

task.spawn(function()
	while true do
		fillBoard(waveBoard, "BestWave", "oleadas")
		fillBoard(killBoard, "Kills", "zombis")
		task.wait(BOARD_REFRESH)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	leave(player)
end)

-- Cada cuarto de segundo: quién está parado en qué sala y las cuentas
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local inside: Room? = nil
			if root then
				for _, room in roomList do
					local offset = root.Position - room.Center
					if Vector3.new(offset.X, 0, offset.Z).Magnitude <= PAD_RADIUS and offset.Y < 8 then
						inside = room
						break
					end
				end
			end
			if inside then
				join(player, inside)
			elseif roomOf[player] then
				leave(player)
			end
		end
		for _, room in roomList do
			if room.EndsAt and not room.Launching then
				if os.clock() >= room.EndsAt and #room.Members > 0 then
					task.spawn(launch, room)
				else
					refresh(room)
				end
			end
		end
	end
end)

for _, room in roomList do
	refresh(room)
end
