-- Piezas de los modelos 3D de los zombis y jefes, para uno de 5 studs de alto
-- (EnemyRenderer los escala según el tamaño de cada tipo).
--
-- Estilo de dibujo animado: piel verde, ojos blancos enormes (uno más grande
-- que el otro), boca abierta con dientes, camisa blanca rota y jean azul.
--
-- Cada pieza gira alrededor de su Pivot (cadera, hombro, cuello...). Hang es
-- dónde queda el centro de la pieza respecto al pivote, Tilt cuánto se inclina
-- hacia adelante y Role qué animación usa. Axis: eje de giro de la animación
-- ("X" por defecto, "Z" para alas, "Y" para la cola). Group: parte del cuerpo
-- (la cabeza sale volando al morir).
local ZombieModels = {}

export type PartSpec = {
	Name: string,
	Size: Vector3,
	Pivot: Vector3,
	Hang: Vector3,
	Tilt: number,
	Color: string,
	Material: Enum.Material,
	Role: string?,
	Axis: string?,
	Group: string,
	Transparent: boolean?,
	Mesh: BasePart?, -- pieza de malla a copiar (zombi de la tienda) en vez de un bloque
	Turn: CFrame?, -- giro propio de la pieza (las mallas vienen mirando al revés)
	Shape: Enum.PartType?, -- bola o cilindro (por defecto, bloque)
}

-- Colores que no dependen del tipo de zombi
ZombieModels.Palette = {
	White = Color3.fromRGB(246, 246, 240),
	Black = Color3.fromRGB(18, 18, 22),
	Mouth = Color3.fromRGB(140, 18, 30),
	Orange = Color3.fromRGB(242, 112, 24),
	Iron = Color3.fromRGB(138, 142, 150),
	Gold = Color3.fromRGB(240, 190, 50),
	Ruby = Color3.fromRGB(220, 30, 50),
	Cape = Color3.fromRGB(150, 22, 34),
	Plume = Color3.fromRGB(190, 30, 40),
	Blood = Color3.fromRGB(110, 20, 24),
	Socket = Color3.fromRGB(28, 22, 22),
	Claw = Color3.fromRGB(70, 66, 60),
	Hair = Color3.fromRGB(30, 28, 30),
	Tentacle = Color3.fromRGB(46, 86, 46),
}

local PLASTIC = Enum.Material.SmoothPlastic
local FABRIC = Enum.Material.Fabric
local METAL = Enum.Material.Metal

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local function part(name: string, size: Vector3, pivot: Vector3, hang: Vector3, tilt: number, color: string, group: string, extra: { [string]: any }?): PartSpec
	local spec: PartSpec = {
		Name = name,
		Size = size,
		Pivot = pivot,
		Hang = hang,
		Tilt = tilt,
		Color = color,
		Material = PLASTIC,
		Group = group,
	}
	if extra then
		for key, value in extra do
			(spec :: any)[key] = value
		end
	end
	return spec
end

-- Cara de zombi de Roblox: cuencas oscuras con ojos que brillan, cejas
-- fruncidas, boca abierta con dientes chuecos y una costura en la mejilla.
-- front: z de la cara delantera de la cabeza. size: escala de la cara.
local function face(list: { PartSpec }, pivot: Vector3, tilt: number, centerY: number, front: number, size: number)
	local function add(name, partSize, hang, color, extra)
		table.insert(list, part(name, partSize * size, pivot, hang, tilt, color, "Head", extra))
	end
	local neon = { Material = Enum.Material.Neon }
	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local x = side * 0.27 * size
		add(name .. "Socket", v(0.38, 0.3, 0.05), v(x, centerY + 0.14 * size, front - 0.02), "Socket")
		add(name .. "Eye", v(0.2, 0.16, 0.06), v(x, centerY + 0.13 * size, front - 0.05), "Eyes", neon)
		-- Ceja fruncida: más baja del lado de adentro
		add(name .. "Brow", v(0.24, 0.08, 0.07), v(side * 0.34 * size, centerY + 0.34 * size, front - 0.04), "Socket")
		add(name .. "BrowIn", v(0.16, 0.08, 0.07), v(side * 0.14 * size, centerY + 0.29 * size, front - 0.04), "Socket")
	end
	add("Mouth", v(0.62, 0.26, 0.05), v(0.02 * size, centerY - 0.27 * size, front - 0.02), "Mouth")
	for index, x in { -0.2, -0.06, 0.08, 0.22 } do
		local tall = if index % 2 == 0 then 0.1 else 0.07
		add("Tooth" .. index, v(0.09, tall, 0.06), v(x * size, centerY - (0.16 + tall / 2) * size, front - 0.05), "White")
	end
	add("LowerTooth", v(0.09, 0.07, 0.06), v(0.12 * size, centerY - 0.36 * size, front - 0.05), "White")
	-- Costura en la mejilla
	add("Stitch", v(0.04, 0.24, 0.06), v(0.4 * size, centerY - 0.12 * size, front - 0.04), "Socket")
	for _, y in { -0.04, -0.12, -0.2 } do
		add("StitchCross", v(0.14, 0.03, 0.06), v(0.4 * size, centerY + y * size, front - 0.05), "Socket")
	end
end

-- Zombi de Roblox (cuerpo R6) para uno de 5 studs de alto: piernas y brazos de
-- 1x2x1, torso de 2x2x1 y cabeza cuadrada. Brazos estirados hacia adelante,
-- camisa rota con manchas de sangre y, según el tipo: pelo, garras, cuerpo de
-- bruto (Buff), tentáculos (Tentacles), sombrero, armadura o capa.
local function zombie(info): { PartSpec }
	local list: { PartSpec } = {}
	local hunch = info.Hunch or 0
	local buff = info.Buff == true
	local hip = v(0, -0.5, 0)
	-- Al encorvarse, todo lo de arriba gira hacia adelante desde la cadera
	local bend = CFrame.new(hip) * CFrame.Angles(-hunch, 0, 0)
	local function upper(point: Vector3): Vector3
		return bend:PointToWorldSpace(point - hip)
	end
	local torsoTilt = 0.12 + hunch
	local torsoSize = if buff then v(2.7, 2.1, 1.4) else v(2, 2, 1)
	local armSize = if buff then v(1.35, 2.3, 1.35) else v(1, 2, 1)

	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "LegL" else "LegR"
		local legPivot = v(side * 0.5, -0.5, 0)
		table.insert(list, part(name .. "Leg", v(0.98, 2, 1), legPivot, v(0, -1, 0), 0, "Pants", "Leg", { Material = FABRIC, Role = role }))
		-- Pantalón roto: se ve la pierna verde abajo
		table.insert(list, part(name .. "Shin", v(0.7, 0.45, 0.06), legPivot, v(side * 0.08, -1.6, -0.52), 0, "Skin", "Leg", { Role = role }))
		table.insert(list, part(name .. "Shoe", v(1, 0.3, 1.15), legPivot, v(0, -1.86, -0.08), 0, "Socket", "Leg", { Role = role }))
	end

	-- Torso con la camisa rota: panza verde, desgarros y sangre
	local front = -torsoSize.Z / 2 - 0.03
	table.insert(list, part("Torso", torsoSize, hip, v(0, torsoSize.Y / 2, 0), torsoTilt, "Shirt", "Torso", { Material = FABRIC }))
	table.insert(list, part("Belly", v(0.75, 0.6, 0.06), hip, v(0.3, 0.55, front), torsoTilt, "Skin", "Torso"))
	table.insert(list, part("Tear", v(0.4, 0.35, 0.06), hip, v(-0.55, 1.45, front), torsoTilt, "Skin", "Torso"))
	table.insert(list, part("Tear2", v(0.3, 0.5, 0.06), hip, v(-0.45, 0.35, front), torsoTilt, "Skin", "Torso"))
	table.insert(list, part("Blood", v(0.5, 0.3, 0.07), hip, v(0.45, 1.2, front - 0.01), torsoTilt, "Blood", "Torso"))
	table.insert(list, part("Blood2", v(0.25, 0.45, 0.07), hip, v(-0.15, 0.9, front - 0.01), torsoTilt, "Blood", "Torso"))
	table.insert(list, part("Collar", v(torsoSize.X * 0.45, 0.2, torsoSize.Z + 0.06), hip, v(0, torsoSize.Y - 0.08, 0), torsoTilt, "Socket", "Torso", { Material = FABRIC }))

	-- Cabeza cuadrada (más chica en el bruto)
	local headSize = if buff then 1.05 else 1.2
	local neck = upper(v(0, torsoSize.Y - 0.5, 0))
	local headPivot = neck
	local headTilt = 0.18 + hunch * 0.5
	table.insert(list, part("Head", v(headSize * 1.05, headSize, headSize), headPivot, v(0, headSize / 2, 0), headTilt, "Skin", "Head"))
	face(list, headPivot, headTilt, headSize / 2, -headSize / 2 - 0.01, headSize / 1.2)
	if info.Hair then
		table.insert(list, part("Hair", v(headSize * 1.12, 0.32, headSize * 1.08), headPivot, v(0, headSize + 0.1, 0.03), headTilt, "Hair", "Head"))
		for index, x in { -0.42, -0.1, 0.25, 0.48 } do
			table.insert(list, part("HairTuft" .. index, v(0.32, 0.38, 0.3), headPivot, v(x * headSize, headSize - 0.02, -headSize / 2 + 0.1), headTilt + 0.3, "Hair", "Head"))
		end
		table.insert(list, part("HairBack", v(headSize * 1.1, 0.7, 0.25), headPivot, v(0, headSize * 0.72, headSize / 2 + 0.06), headTilt, "Hair", "Head"))
	end

	-- Brazos hacia adelante, con manga rota y garras
	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "ArmL" else "ArmR"
		local shoulder = upper(v(side * (torsoSize.X / 2 + armSize.X / 2), torsoSize.Y - 0.5, 0))
		local tilt = -1.35
		table.insert(list, part(name .. "Arm", armSize, shoulder, v(0, -armSize.Y / 2 + 0.5, 0), tilt, "Skin", "Arm", { Role = role }))
		table.insert(list, part(name .. "Sleeve", v(armSize.X + 0.04, armSize.Y * 0.35, armSize.Z + 0.04), shoulder, v(0, 0.15, 0), tilt, if buff then "Skin" else "Shirt", "Arm", { Material = FABRIC, Role = role }))
		if info.Claws or buff then
			for index, x in { -0.3, 0, 0.3 } do
				table.insert(list, part(name .. "Claw" .. index, v(0.12, 0.42, 0.14), shoulder, v(x * armSize.X, -armSize.Y + 0.35, -0.38 * armSize.Z), tilt, "Claw", "Arm", { Material = METAL, Role = role }))
			end
		end
		if info.Armor then
			table.insert(list, part(name .. "Pauldron", v(armSize.X + 0.3, 0.45, armSize.Z + 0.3), shoulder, v(0, 0.55, 0), 0, "Iron", "Arm", { Material = METAL, Role = role }))
		end
	end

	if info.Armor then
		table.insert(list, part("ChestPlate", v(torsoSize.X + 0.06, torsoSize.Y * 0.65, torsoSize.Z + 0.1), hip, v(0, torsoSize.Y * 0.62, 0), torsoTilt, "Iron", "Torso", { Material = METAL }))
	end
	if info.Cape then
		local capePivot = upper(v(0, torsoSize.Y - 0.2, torsoSize.Z / 2 + 0.05))
		table.insert(list, part("Cape", v(torsoSize.X + 0.2, 3, 0.15), capePivot, v(0, -1.45, 0.1), -0.12, "Cape", "Torso", { Material = FABRIC, Role = "Cape" }))
	end
	-- Mutante: tentáculos de enredadera que salen de la espalda y se mecen
	if info.Tentacles then
		for index, root in { v(-0.55, 1.7, 0.55), v(0.55, 1.7, 0.55), v(-0.3, 1.1, 0.55), v(0.35, 1.2, 0.55) } do
			local pivot = upper(root)
			local out = if root.X < 0 then -1 else 1
			local reach = if index <= 2 then 1 else 0.75
			for segment = 1, 4 do
				local t = segment / 4
				local radius = (0.36 - t * 0.2) * reach
				local hang = v(out * (0.35 + t * 1.1) * reach, (0.6 + t * 2.4 - t * t * 0.9) * reach, (0.2 + t * 0.9) * reach)
				table.insert(list, part("Tentacle" .. index .. "_" .. segment, v(radius * 2, radius * 2, radius * 2), pivot, hang, 0, "Tentacle", "Torso", { Role = "Cape", Shape = Enum.PartType.Ball }))
			end
		end
	end

	-- Sombreros
	local hat = info.Hat
	local top = headSize
	local function hatPart(name, size, y, color, extra)
		table.insert(list, part(name, size, headPivot, v(0, y, 0), headTilt + 0.12, color, "Head", extra))
	end
	if hat == "Cone" then
		-- Cono de tránsito naranja con franja blanca, un poco chueco
		hatPart("ConeBase", v(1.4, 0.2, 1.4), top + 0.08, "Orange")
		hatPart("ConeMid", v(1, 0.45, 1), top + 0.38, "Orange")
		hatPart("ConeStripe", v(0.82, 0.26, 0.82), top + 0.72, "White")
		hatPart("ConeTop", v(0.6, 0.45, 0.6), top + 1.06, "Orange")
		hatPart("ConeTip", v(0.3, 0.3, 0.3), top + 1.4, "Orange")
	elseif hat == "Helmet" then
		-- Yelmo de caballero con protector de nariz y penacho
		hatPart("Helmet", v(headSize * 1.18, 0.75, headSize * 1.15), top - 0.12, "Iron", { Material = METAL })
		table.insert(list, part("NoseGuard", v(0.18, 0.5, 0.1), headPivot, v(0, top * 0.62, -headSize / 2 - 0.06), headTilt, "Iron", "Head", { Material = METAL }))
		hatPart("Plume", v(0.22, 0.6, 1.1), top + 0.55, "Plume", { Material = FABRIC })
	elseif hat == "Crown" then
		hatPart("CrownBand", v(headSize * 1.12, 0.35, headSize * 1.12), top + 0.1, "Gold", { Material = METAL })
		for _, corner in { v(-0.5, 0, -0.5), v(0.5, 0, -0.5), v(-0.5, 0, 0.5), v(0.5, 0, 0.5), v(0, 0, -0.6) } do
			table.insert(list, part("CrownSpike", v(0.24, 0.5, 0.24), headPivot, corner * headSize + v(0, top + 0.5, 0), headTilt + 0.12, "Gold", "Head", { Material = METAL }))
		end
		table.insert(list, part("Jewel", v(0.24, 0.24, 0.06), headPivot, v(0, top + 0.1, -headSize * 0.57), headTilt + 0.12, "Ruby", "Head", { Material = Enum.Material.Neon }))
	end
	return list
end

-- Zombi gordo (Bruto y el jefe Gordo): panza enorme fuera de la camisa
local function fat(_info): { PartSpec }
	local list: { PartSpec } = {}
	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "LegL" else "LegR"
		local legPivot = v(side * 0.75, -1, 0)
		table.insert(list, part(name .. "Leg", v(1, 1.5, 1), legPivot, v(0, -0.72, 0), 0, "Pants", "Leg", { Material = FABRIC, Role = role }))
		table.insert(list, part(name .. "Foot", v(1.05, 0.3, 1.3), legPivot, v(0, -1.35, -0.2), 0, "Skin", "Leg", { Role = role }))
	end
	local hip = v(0, -1, 0)
	table.insert(list, part("Torso", v(3, 2.4, 2.2), hip, v(0, 1.2, 0), 0.1, "Shirt", "Torso", { Material = FABRIC }))
	table.insert(list, part("Belly", v(2.6, 1.5, 0.55), hip, v(0, 0.8, -1.25), 0.1, "Skin", "Torso"))
	table.insert(list, part("BellyButton", v(0.25, 0.25, 0.06), hip, v(0, 0.75, -1.55), 0.1, "Mouth", "Torso"))
	table.insert(list, part("Tear", v(0.6, 0.4, 0.06), hip, v(-0.9, 1.9, -1.12), 0.1, "Skin", "Torso"))

	local headPivot = v(0, 1.35, -0.5)
	table.insert(list, part("Head", v(1.5, 1.3, 1.3), headPivot, v(0, 0.6, 0), 0.2, "Skin", "Head"))
	table.insert(list, part("Chin", v(1.3, 0.35, 1.1), headPivot, v(0, -0.1, -0.05), 0.2, "Skin", "Head"))
	face(list, headPivot, 0.2, 0.62, -0.65, 0.9)

	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "ArmL" else "ArmR"
		local shoulder = v(side * 1.85, 1, -0.2)
		table.insert(list, part(name .. "Arm", v(0.8, 0.8, 1.9), shoulder, v(0, -0.1, -0.85), 0, "Skin", "Arm", { Role = role }))
		table.insert(list, part(name .. "Sleeve", v(0.95, 0.95, 0.6), shoulder, v(0, 0, -0.2), 0, "Shirt", "Arm", { Material = FABRIC, Role = role }))
		table.insert(list, part(name .. "Hand", v(0.9, 0.85, 0.5), shoulder, v(0, -0.1, -1.9), 0, "Skin", "Arm", { Role = role }))
	end
	return list
end

-- Dragón zombi: cuerpo podrido con costillas al aire, púas en el lomo, alas
-- rotas que aletean, cuello largo, mandíbula que se abre para escupir fuego y
-- cola que se mece. Formas redondas: bolas y cilindros.
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local ALONG_Z = CFrame.Angles(0, math.pi / 2, 0) -- cilindro a lo largo de Z
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- cilindro parado

local function dragon(_info): { PartSpec }
	local list: { PartSpec } = {}
	local slate = Enum.Material.Slate
	local function add(name, size, pivot, hang, tilt, color, group, extra)
		local spec = part(name, size, pivot, hang, tilt, color, group, extra)
		table.insert(list, spec)
		return spec
	end

	-- Cuerpo: tronco redondo, pecho y panza
	add("Body", v(4.4, 2, 2), v(0, 0, 0), v(0, 0, 0), 0, "Skin", "Torso", { Material = slate, Shape = CYLINDER, Turn = ALONG_Z })
	add("Chest", v(2.3, 2.3, 2.3), v(0, 0, 0), v(0, 0.1, -1.6), 0, "Skin", "Torso", { Material = slate, Shape = BALL })
	add("Hips", v(2, 2, 2), v(0, 0, 0), v(0, 0, 1.7), 0, "Skin", "Torso", { Material = slate, Shape = BALL })
	-- Costillas al aire (aros de hueso) y púas en el lomo
	for index, z in { -1.1, -0.4, 0.3, 1 } do
		add("Rib" .. index, v(0.2, 2.15, 2.15), v(0, 0, 0), v(0, -0.05, z), 0, "Shirt", "Torso", { Shape = CYLINDER, Turn = ALONG_Z })
	end
	for index, z in { -1.8, -1, -0.2, 0.6, 1.4, 2.1 } do
		local height = if index <= 3 then 0.75 else 0.55
		add("Spike" .. index, v(0.16, height, height), v(0, 0, 0), v(0, 1.05, z), 0.785, "Shirt", "Torso")
	end

	-- Cuello en tres partes, cabeza con hocico, cejas y cuernos curvos
	for index, segment in { { -2.3, 0.95 }, { -2.9, 0.82 }, { -3.4, 0.72 } } do
		add("Neck" .. index, v(1.1, segment[2], segment[2]), v(0, 0.5, -2), v(0, 0.35 * index, segment[1] + 2), -0.45, "Skin", "Head", { Material = slate, Role = "Neck", Shape = CYLINDER, Turn = ALONG_Z })
	end
	local headPivot = v(0, 1.5, -3.6)
	add("Head", v(1.4, 1.1, 1.5), headPivot, v(0, 0.05, -0.55), 0, "Skin", "Head", { Material = slate, Role = "Neck" })
	add("Snout", v(1.4, 0.75, 0.75), headPivot, v(0, -0.08, -1.45), 0, "Skin", "Head", { Material = slate, Role = "Neck", Shape = CYLINDER, Turn = ALONG_Z })
	add("Skull", v(1.25, 1.25, 1.25), headPivot, v(0, 0.25, -0.2), 0, "Skin", "Head", { Material = slate, Role = "Neck", Shape = BALL })
	for index = -2, 2 do
		add("Tooth" .. index, v(0.12, 0.28, 0.12), headPivot, v(index * 0.2, -0.5, -1.7 + math.abs(index) * 0.08), 0, "White", "Head", { Role = "Neck" })
	end
	for _, side in { -1, 1 } do
		add("Brow", v(0.5, 0.16, 0.35), headPivot, v(side * 0.42, 0.62, -1.05), 0.3, "Shirt", "Head", { Role = "Neck" })
		add("Eye", v(0.08, 0.26, 0.34), headPivot, v(side * 0.71, 0.3, -1), 0, "Eyes", "Head", { Material = Enum.Material.Neon, Role = "Neck" })
		add("Nostril", v(0.16, 0.16, 0.16), headPivot, v(side * 0.28, 0.1, -1.82), 0, "Black", "Head", { Role = "Neck", Shape = BALL })
		-- Cuerno en dos tramos que se curva hacia atrás
		add("Horn", v(0.32, 0.32, 1), headPivot + v(side * 0.45, 0.55, 0.1), v(0, 0.15, 0.45), -0.7, "Shirt", "Head", { Role = "Neck" })
		add("HornTip", v(0.2, 0.2, 0.8), headPivot + v(side * 0.45, 0.55, 0.1), v(0, 0.55, 1.05), -0.25, "Shirt", "Head", { Role = "Neck" })
	end
	add("Jaw", v(1.1, 0.35, 1.7), v(0, 1.12, -3.5), v(0, -0.1, -0.8), 0, "Skin", "Head", { Material = slate, Role = "Jaw" })
	for index = -1, 1 do
		add("LowerTooth" .. index, v(0.12, 0.22, 0.12), v(0, 1.12, -3.5), v(index * 0.3, 0.12, -1.5), 0, "White", "Head", { Role = "Jaw" })
	end
	-- Punto invisible de donde sale el fuego (mira adelante y abajo)
	add("Breath", v(0.2, 0.2, 0.2), headPivot, v(0, -0.3, -1.9), 0.75, "Skin", "Head", { Role = "Neck", Transparent = true })

	-- Alas: hueso del brazo, tres dedos y membrana rota en tres paños con huecos
	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "WingL" else "WingR"
		local root = v(side * 0.9, 0.6, -0.8)
		local wing = { Role = role, Axis = "Z" }
		add(name .. "WingShoulder", v(0.9, 0.9, 0.9), root, v(0, 0, 0), 0, "Skin", "Wing", { Material = slate, Role = role, Axis = "Z", Shape = BALL })
		add(name .. "WingBone", v(5.6, 0.38, 0.38), root, v(side * 2.8, 0, 0), 0, "Shirt", "Wing", { Role = role, Axis = "Z", Shape = CYLINDER })
		add(name .. "WingJoint", v(0.55, 0.55, 0.55), root, v(side * 5.6, 0, 0), 0, "Shirt", "Wing", { Role = role, Axis = "Z", Shape = BALL })
		for index, finger in { { 1.9, 2.4 }, { 3.7, 2.8 }, { 5.4, 3.1 } } do
			add(name .. "WingFinger" .. index, v(0.2, 0.2, finger[2]), root, v(side * finger[1], 0.04, finger[2] / 2), 0, "Shirt", "Wing", wing)
		end
		-- Paños de piel entre los dedos (el de afuera roto, más corto)
		for index, panel in { { 0.95, 1.9, 2.2 }, { 2.8, 1.8, 2.5 }, { 4.55, 1.7, 1.6 } } do
			add(name .. "Wing" .. index, v(panel[2], 0.1, panel[3]), root, v(side * panel[1], 0, panel[3] / 2 + 0.1), 0, "Pants", "Wing", { Material = FABRIC, Role = role, Axis = "Z" })
		end
	end

	-- Cola en cuatro tramos que se afinan, con púas y punta de pala
	local tailPivot = v(0, 0.1, 2.1)
	local tail = { Material = slate, Role = "Tail", Axis = "Y", Shape = CYLINDER, Turn = ALONG_Z }
	for index, segment in { { 1.3, 1.5, 0.95 }, { 2.7, 1.4, 0.75 }, { 4, 1.3, 0.58 }, { 5.2, 1.2, 0.42 } } do
		add("Tail" .. index, v(segment[2] + 0.2, segment[3], segment[3]), tailPivot, v(0, -0.12 * index, segment[1]), 0.1, "Skin", "Tail", tail)
		add("TailSpike" .. index, v(0.12, segment[3] * 0.7, segment[3] * 0.7), tailPivot, v(0, -0.12 * index + segment[3] / 2 + 0.1, segment[1]), 0.885, "Shirt", "Tail", { Role = "Tail", Axis = "Y" })
	end
	add("TailBlade", v(0.12, 0.9, 0.9), tailPivot, v(0, -0.5, 6.1), 0.785, "Shirt", "Tail", { Role = "Tail", Axis = "Y" })

	-- Patas con muslo, canilla y tres garras
	for _, corner in { v(-0.85, -0.6, -1.3), v(0.85, -0.6, -1.3), v(-0.75, -0.6, 1.5), v(0.75, -0.6, 1.5) } do
		add("Thigh", v(0.8, 0.8, 0.8), corner, v(0, 0, 0), -0.3, "Skin", "Leg", { Material = slate, Shape = BALL })
		add("Leg", v(1.2, 0.48, 0.48), corner, v(0, -0.6, 0), -0.3, "Skin", "Leg", { Material = slate, Shape = CYLINDER, Turn = UPRIGHT })
		for index = -1, 1 do
			add("Claw", v(0.14, 0.18, 0.45), corner, v(index * 0.2, -1.22, -0.25), -0.3, "Shirt", "Leg")
		end
	end
	return list
end

-- Zombi de malla de la Creator Store (src/zombies → ReplicatedStorage.ZombieMeshes),
-- un cuerpo R15 normal. Se lleva a 5 studs de alto y mirando a -Z, y cada pieza
-- se cuelga del pivote de su parte del cuerpo (cadera, hombro, cuello) para que
-- ZombieAnimator la mueva como a los de bloques. Los brazos van estirados hacia
-- adelante. Los sombreros (cono, yelmo, corona) son los de bloques.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config)
local MESH_HEIGHT = 5
local HAT_PREFIXES = { "Cone", "Helmet", "NoseGuard", "Plume", "Crown", "Jewel" }
local meshHip: Vector3? = nil

local function meshSource(): Model?
	if not Config.ZombieMesh or Config.ZombieStyle ~= "3D" or not Config.UseStoreModels or Config.Style.Blocky then
		return nil
	end
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("ZombieMeshes")
	local model = folder and folder:FindFirstChild("Zombie")
	return if model and model:IsA("Model") then model else nil
end

local function meshZombie(info, source: Model): { PartSpec }
	local byName: { [string]: BasePart } = {}
	local low, high = math.huge, -math.huge
	local sum, count = Vector3.zero, 0
	for _, descendant in source:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			byName[descendant.Name] = descendant
			low = math.min(low, descendant.Position.Y - descendant.Size.Y / 2)
			high = math.max(high, descendant.Position.Y + descendant.Size.Y / 2)
			sum += descendant.Position
			count += 1
		end
	end
	local scale = MESH_HEIGHT / (high - low)
	local center = Vector3.new(sum.X / count, (low + high) / 2, sum.Z / count)
	local flip = CFrame.Angles(0, math.pi, 0)
	local function norm(point: Vector3): Vector3
		return flip:VectorToWorldSpace((point - center) * scale)
	end
	local function top(name: string): Vector3
		local part = byName[name]
		return norm(part.Position + Vector3.new(0, part.Size.Y / 2, 0))
	end
	local function bottom(name: string): Vector3
		local part = byName[name]
		return norm(part.Position - Vector3.new(0, part.Size.Y / 2, 0))
	end

	-- Parte del cuerpo de cada pieza: { rol, grupo, pivote, inclinación }
	local hip = bottom("LowerTorso")
	meshHip = hip
	local joints = {
		Leg = { "LegL", "Leg", top("LeftUpperLeg"), 0 },
		LegR = { "LegR", "Leg", top("RightUpperLeg"), 0 },
		Arm = { "ArmL", "Arm", top("LeftUpperArm"), -1.4 },
		ArmR = { "ArmR", "Arm", top("RightUpperArm"), -1.4 },
		Head = { "Head", "Head", bottom("Head"), 0 },
		Torso = { nil, "Torso", hip, 0 },
	}
	local function jointOf(name: string)
		local right = string.find(name, "Right") ~= nil
		if string.find(name, "Leg") or string.find(name, "Foot") then
			return if right then joints.LegR else joints.Leg
		elseif string.find(name, "Arm") or string.find(name, "Hand") then
			return if right then joints.ArmR else joints.Arm
		elseif name == "Head" then
			return joints.Head
		end
		return joints.Torso
	end

	local list: { PartSpec } = {}
	for name, mesh in byName do
		local joint = jointOf(name)
		local spec = part(name, mesh.Size * scale, joint[3], norm(mesh.Position) - joint[3], joint[4], "Skin", joint[2], { Role = joint[1] })
		-- Copia limpia: solo la malla con su textura (sin anclajes ni valores del rig)
		local clean = mesh:Clone()
		for _, child in clean:GetChildren() do
			if not (child:IsA("SurfaceAppearance") or child:IsA("Decal")) then
				child:Destroy()
			end
		end
		spec.Mesh = clean
		spec.Turn = flip
		table.insert(list, spec)
	end
	-- Sombreros de bloques, colgados del cuello de la malla
	for _, spec in zombie(info) do
		for _, prefix in HAT_PREFIXES do
			if string.sub(spec.Name, 1, #prefix) == prefix then
				local hat = table.clone(spec)
				hat.Pivot = joints.Head[3]
				hat.Tilt = spec.Tilt - 0.3
				hat.Role = "Head"
				table.insert(list, hat)
				break
			end
		end
	end
	return list
end

local builders = {
	Zombie = function(info)
		local source = meshSource()
		return if source then meshZombie(info, source) else zombie(info)
	end,
	-- El Bruto y el Gordo: el mismo zombi de malla, más grande (Size del tipo)
	Fat = function(info)
		local source = meshSource()
		return if source then meshZombie(info, source) else fat(info)
	end,
	Dragon = dragon,
}

local cache: { [string]: { PartSpec } } = {}

-- Cadera (pivote del torso) para un zombi de 5 studs: el torso, la cabeza y
-- los brazos giran juntos alrededor de este punto
local HIPS = {
	Zombie = Vector3.new(0, -0.5, 0),
	Fat = Vector3.new(0, -1, 0),
	Dragon = Vector3.zero,
}

function ZombieModels.getHip(info): Vector3
	if info.Model == "Zombie" or info.Model == "Fat" then
		local source = meshSource()
		if source and not meshHip then
			meshZombie(info, source) -- calcula la cadera de la malla
		end
		if source and meshHip then
			return meshHip
		end
	end
	return HIPS[info.Model] or HIPS.Zombie
end

-- Piezas del tipo de enemigo (se calculan una vez por tipo)
function ZombieModels.get(typeName: string, info): { PartSpec }
	local cached = cache[typeName]
	if not cached then
		cached = (builders[info.Model] or zombie)(info)
		cache[typeName] = cached
	end
	return cached
end

-- Color de una pieza: primero los del tipo (Skin, Shirt...), después la paleta.
-- Las pupilas son negras, salvo en los que tienen ojos que brillan.
function ZombieModels.resolveColor(info, key: string): (Color3, boolean)
	if key == "Pupil" then
		local eyes: Color3 = info.Eyes
		local glowing = eyes ~= nil and (eyes.R < 0.95 or eyes.G < 0.95 or eyes.B < 0.95)
		return if glowing then eyes else ZombieModels.Palette.Black, glowing
	end
	local color = info[key] or ZombieModels.Palette[key] or Color3.new(1, 0, 1)
	return color, false
end

return ZombieModels
