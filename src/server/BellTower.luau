-- La campana sobre su montículo, al estilo de Guns 'n Goblins: dos postes altos
-- con una cruz arriba, un travesaño con puntas de hierro, estandartes verdes y
-- la campana de cobre colgando.
--
-- Al empezar la preparación está DESTRUIDA: los postes caídos y cruzados sobre
-- el montículo, la campana tirada de costado y los estandartes en el suelo.
-- Al reconstruirla cada pieza vuela a su lugar; si los zombis la destruyen,
-- se derrumba otra vez. Cada pieza guarda dónde va armada y dónde cae.
local TweenService = game:GetService("TweenService")

local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local POST = Color3.fromRGB(96, 62, 38)
local DARK_WOOD = Props.Colors.DarkWood
local IRON = Props.Colors.Iron
local COPPER = Color3.fromRGB(176, 98, 62)
local BANNER = Color3.fromRGB(36, 116, 62)
local EMBLEM = Color3.fromRGB(200, 220, 120)
local GRASS = Color3.fromRGB(70, 112, 58)
local STONE = Color3.fromRGB(120, 124, 122)

local BRONZE = Color3.fromRGB(150, 104, 52)
local GOLD = Color3.fromRGB(214, 170, 80)
-- Los cilindros de Roblox van a lo largo de X: esto los para
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

local MOUND_HEIGHT = 2.4
local MOUND_HALF = 8

-- Un grupo de partes que se mueve junto (un poste, la campana, un estandarte)
type Piece = {
	Parts: { BasePart },
	Offsets: { CFrame }, -- de cada parte respecto al centro del grupo
	Built: CFrame,
	Ruined: CFrame,
	Order: number, -- en qué orden se arma (los postes primero)
}

local BellTower = {}

local pieces: { Piece } = {}
local built = false
local animationToken = 0

local function newPiece(order: number, built: CFrame, ruined: CFrame): Piece
	local piece = { Parts = {}, Offsets = {}, Built = built, Ruined = ruined, Order = order }
	table.insert(pieces, piece)
	return piece
end

-- Agrega una parte a la pieza; `offset` es relativo al centro del grupo armado
local function add(piece: Piece, props: { [string]: any }, offset: CFrame, prop: boolean?): BasePart
	props.CFrame = piece.Ruined * offset
	local part = if prop then makeProp(props) else makePart(props)
	table.insert(piece.Parts, part)
	table.insert(piece.Offsets, offset)
	return part
end

-- Montículo redondo de pasto con un muro de piedras alrededor, flores y
-- escalones a los costados
local function buildMound(map: Instance): BasePart
	local random = Random.new(7)
	local mound = makePart({
		Name = "BellMound",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(MOUND_HEIGHT, MOUND_HALF * 2, MOUND_HALF * 2),
		CFrame = CFrame.new(0, MOUND_HEIGHT / 2, 0) * UPRIGHT,
		Material = Enum.Material.Cobblestone,
		Color = STONE,
		Parent = map,
	})
	makePart({ Name = "MoundGrass", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, MOUND_HALF * 2 - 0.8, MOUND_HALF * 2 - 0.8), CFrame = CFrame.new(0, MOUND_HEIGHT + 0.2, 0) * UPRIGHT, Material = Enum.Material.Grass, Color = GRASS, Parent = map })
	-- Piedras grandes del muro, una al lado de la otra (hueco adelante para la rampa)
	local stones = 26
	for index = 0, stones - 1 do
		local angle = index / stones * math.pi * 2
		local direction = Vector3.new(math.sin(angle), 0, math.cos(angle))
		if direction.Z > 0.93 then
			continue
		end
		local height = MOUND_HEIGHT + random:NextNumber(0.2, 0.9)
		makePart({
			Name = "MoundStone",
			Size = Vector3.new(random:NextNumber(1.9, 2.4), height, random:NextNumber(1.1, 1.6)),
			CFrame = CFrame.lookAt(direction * (MOUND_HALF + 0.2) + Vector3.new(0, height / 2, 0), Vector3.new(0, height / 2, 0)) * CFrame.Angles(random:NextNumber(-0.06, 0.06), 0, random:NextNumber(-0.08, 0.08)),
			Material = Enum.Material.Slate,
			Color = Props.vary(STONE, 0.12, random),
			Parent = map,
		})
	end
	-- Florcitas sobre el pasto, cerca del borde (en el centro van los postes)
	local petals = { Color3.fromRGB(240, 220, 90), Color3.fromRGB(240, 240, 235), Color3.fromRGB(200, 120, 200), Color3.fromRGB(230, 110, 70) }
	for _ = 1, 24 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(MOUND_HALF - 3.2, MOUND_HALF - 1.2)
		makeProp({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.one * random:NextNumber(0.3, 0.5), Position = Vector3.new(math.sin(angle) * radius, MOUND_HEIGHT + 0.5, math.cos(angle) * radius), Material = Enum.Material.SmoothPlastic, Color = petals[random:NextInteger(1, #petals)], Parent = map })
	end
	-- Rampa de pasto hacia el círculo de runas (lado +Z)
	makePart({
		Name = "MoundRamp",
		Size = Vector3.new(7, MOUND_HEIGHT + 0.4, 7),
		CFrame = CFrame.new(0, (MOUND_HEIGHT + 0.4) / 2, MOUND_HALF + 3.5) * CFrame.Angles(0, math.pi, 0),
		Material = Enum.Material.Grass,
		Color = GRASS,
		Parent = map,
	}, "WedgePart")
	-- Escalones de piedra a los dos costados
	for _, side in { -1, 1 } do
		for step = 1, 3 do
			local height = MOUND_HEIGHT * step / 3
			makePart({ Name = "MoundStep", Size = Vector3.new(1.4, height, 6), Position = Vector3.new(side * (MOUND_HALF + 4.2 - step * 1.4), height / 2, 0), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.06, Random.new(step)), Parent = map })
		end
	end
	return mound
end

local function buildStructure(map: Instance)
	local top = MOUND_HEIGHT + 0.4
	local postHeight = 20
	local postX = 4.5

	-- Postes: armados, derechos; destruidos, caídos y cruzados sobre el montículo
	for index, side in { -1, 1 } do
		local fallen = CFrame.new(side * 1.5, top + 1.2 + index * 0.9, side * 1.2) * CFrame.Angles(0, side * 0.55, math.pi / 2 - side * 0.22)
		local piece = newPiece(1, CFrame.new(side * postX, top + postHeight / 2, 0), fallen)
		-- Poste redondo con aros de hierro y remate tallado
		add(piece, { Name = "BellPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(postHeight, 1.5, 1.5), Material = Enum.Material.Wood, Color = POST }, UPRIGHT)
		add(piece, { Name = "PostFoot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.1, 2.1), Material = Enum.Material.Wood, Color = DARK_WOOD }, CFrame.new(0, -postHeight / 2 + 0.5, 0) * UPRIGHT, true)
		for _, bandY in { -postHeight / 2 + 2, -2, postHeight / 2 - 4.2 } do
			add(piece, { Name = "IronBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 1.65, 1.65), Material = Enum.Material.Metal, Color = IRON }, CFrame.new(0, bandY, 0) * UPRIGHT, true)
		end
		add(piece, { Name = "PostCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.9, 1.9), Material = Enum.Material.Wood, Color = DARK_WOOD }, CFrame.new(0, postHeight / 2 + 0.3, 0) * UPRIGHT, true)
		add(piece, { Name = "PostKnob", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.3, Material = Enum.Material.Wood, Color = DARK_WOOD }, CFrame.new(0, postHeight / 2 + 1.1, 0), true)
	end

	-- Viga de arriba con la cruz de madera encima
	local beamY = top + postHeight - 0.8
	local beam = newPiece(2, CFrame.new(0, beamY, 0), CFrame.new(-3, top + 0.6, -5.5) * CFrame.Angles(0, 0.35, 0.08))
	add(beam, { Name = "TopBeam", Size = Vector3.new(postX * 2 + 2.4, 1, 1.2), Material = Enum.Material.Wood, Color = POST }, CFrame.identity)
	for _, side in { -1, 1 } do
		local cross = newPiece(3, CFrame.new(0, beamY + 1.6, 0) * CFrame.Angles(0, 0, side * 0.62), CFrame.new(side * 5, top + 0.4, -2) * CFrame.Angles(0, side * 1.2, 0.05))
		add(cross, { Name = "CrossBrace", Size = Vector3.new(8.4, 0.7, 0.8), Material = Enum.Material.Wood, Color = DARK_WOOD }, CFrame.identity)
	end

	-- Brazos de hierro con punta a los lados de los postes, de donde cuelgan los estandartes
	local barY = top + postHeight - 3.2
	for _, side in { -1, 1 } do
		local bar = newPiece(2, CFrame.new(side * (postX + 1.7), barY, 0), CFrame.new(side * 6, top + 0.25, -5) * CFrame.Angles(0, side * 0.7, 0))
		add(bar, { Name = "BannerBar", Size = Vector3.new(3.4, 0.45, 0.45), Material = Enum.Material.Metal, Color = IRON }, CFrame.identity)
		add(bar, { Name = "Finial", Size = Vector3.new(0.6, 0.6, 0.6), Material = Enum.Material.Metal, Color = IRON }, CFrame.new(side * 1.9, 0, 0) * CFrame.Angles(0, 0, math.rad(45)), true)
	end

	-- Estandartes verdes con emblema, por fuera de cada poste
	for _, side in { -1, 1 } do
		local hang = CFrame.new(side * (postX + 1.6), barY - 3.4, 0)
		local fallen = CFrame.new(side * 4, top + 0.12, 4.5) * CFrame.Angles(-math.pi / 2, side * 0.4, 0)
		local banner = newPiece(4, hang, fallen)
		add(banner, { Name = "BannerCloth", Size = Vector3.new(2.6, 6.4, 0.15), Material = Enum.Material.Fabric, Color = BANNER }, CFrame.identity, true)
		add(banner, { Name = "BannerTrim", Size = Vector3.new(2.7, 0.35, 0.18), Material = Enum.Material.Fabric, Color = DARK_WOOD }, CFrame.new(0, 3.1, 0), true)
		add(banner, { Name = "BannerEmblem", Size = Vector3.new(1.2, 1.4, 0.2), Material = Enum.Material.Fabric, Color = EMBLEM }, CFrame.new(0, 0.8, 0), true)
		-- Puntas abajo
		for _, x in { -0.9, 0.9 } do
			add(banner, { Name = "BannerTail", Size = Vector3.new(0.8, 0.8, 0.15), Material = Enum.Material.Fabric, Color = BANNER }, CFrame.new(x, -3.4, 0) * CFrame.Angles(0, 0, math.rad(45)), true)
		end
	end

	-- La campana de cobre (Model "Bell": PowerController hace brillar su centro)
	local bellModel = Instance.new("Model")
	bellModel.Name = "Bell"
	local bellTop = beamY - 0.5
	local bell = newPiece(5, CFrame.new(0, bellTop, 0), CFrame.new(1.8, top + 1.8, -1.5) * CFrame.Angles(math.rad(100), 0.6, 0))
	add(bell, { Name = "Rope", Size = Vector3.new(0.25, 1.2, 0.25), Material = Enum.Material.Fabric, Color = Color3.fromRGB(150, 120, 80) }, CFrame.new(0, -0.1, 0), true)
	add(bell, { Name = "Yoke", Size = Vector3.new(2.8, 0.7, 1.1), Material = Enum.Material.Wood, Color = DARK_WOOD }, CFrame.new(0, -0.9, 0))
	for _, x in { -0.9, 0.9 } do
		add(bell, { Name = "YokeStrap", Size = Vector3.new(0.25, 0.8, 1.2), Material = Enum.Material.Metal, Color = IRON }, CFrame.new(x, -0.9, 0), true)
	end
	-- Campana de bronce acampanada: cúpula, cuerpo que se abre y borde dorado
	add(bell, { Name = "BellCrown", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.9, 0.9), Material = Enum.Material.Metal, Color = BRONZE }, CFrame.new(0, -1.45, 0) * UPRIGHT)
	add(bell, { Name = "BellDome", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.3, Material = Enum.Material.Metal, Color = BRONZE }, CFrame.new(0, -2.3, 0))
	local y = -2.3
	for _, layer in { { 2.35, 0.8 }, { 2.6, 0.8 }, { 2.95, 0.7 }, { 3.4, 0.55 }, { 3.9, 0.35 } } do
		y -= layer[2] / 2
		add(bell, { Name = "BellBody", Shape = Enum.PartType.Cylinder, Size = Vector3.new(layer[2], layer[1], layer[1]), Material = Enum.Material.Metal, Color = BRONZE }, CFrame.new(0, y, 0) * UPRIGHT)
		y -= layer[2] / 2
	end
	add(bell, { Name = "BellRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.22, 4.05, 4.05), Material = Enum.Material.Metal, Color = GOLD }, CFrame.new(0, y + 0.1, 0) * UPRIGHT, true)
	add(bell, { Name = "BellBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 2.66, 2.66), Material = Enum.Material.Metal, Color = GOLD }, CFrame.new(0, -3.1, 0) * UPRIGHT, true)
	add(bell, { Name = "Clapper", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.85, Material = Enum.Material.Metal, Color = COPPER:Lerp(Color3.new(0, 0, 0), 0.5) }, CFrame.new(0, y - 0.25, 0), true)
	for _, part in bell.Parts do
		part.Parent = bellModel
	end
	bellModel.Parent = map

	local structure = Instance.new("Model")
	structure.Name = "BellTower"
	for _, piece in pieces do
		for _, part in piece.Parts do
			if not part.Parent then
				part.Parent = structure
			end
		end
	end
	structure.Parent = map
end

-- Mueve todas las piezas a armado (true) o destruido (false), con animación
local function moveTo(toBuilt: boolean, animate: boolean)
	built = toBuilt
	animationToken += 1
	local token = animationToken
	for _, piece in pieces do
		local target = if toBuilt then piece.Built else piece.Ruined
		-- Al armarse: postes primero, campana al final. Al caerse: al revés.
		local delay = if toBuilt then (piece.Order - 1) * 0.22 else (5 - piece.Order) * 0.12
		local info = if toBuilt
			then TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			else TweenInfo.new(0.9, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		for index, part in piece.Parts do
			local goal = target * piece.Offsets[index]
			if not animate then
				part.CFrame = goal
			else
				task.delay(delay, function()
					if token == animationToken then
						TweenService:Create(part, info, { CFrame = goal }):Play()
					end
				end)
			end
		end
	end
end

function BellTower.isBuilt(): boolean
	return built
end

-- Se arma con animación (al reconstruirla para empezar la partida)
function BellTower.rebuild()
	if not built then
		moveTo(true, true)
	end
end

-- Se derrumba (cuando los zombis la destruyen)
function BellTower.collapse()
	if built then
		moveTo(false, true)
	end
end

-- Construye el montículo y la campana destruida. Devuelve el montículo (los
-- avisos de reconstruir y reparar van ahí).
function BellTower.build(map: Instance): BasePart
	local mound = buildMound(map)
	buildStructure(map)
	moveTo(false, false)
	return mound
end

return BellTower
