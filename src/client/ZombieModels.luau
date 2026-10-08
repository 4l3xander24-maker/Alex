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

-- Cara de dibujo animado sobre una cabeza con este pivote e inclinación.
-- front: z de la cara delantera de la cabeza. size: escala de ojos y boca.
local function face(list: { PartSpec }, pivot: Vector3, tilt: number, centerY: number, front: number, size: number)
	local function add(name, partSize, hang, color, extra)
		table.insert(list, part(name, partSize * size, pivot, hang, tilt, color, "Head", extra))
	end
	add("LeftEye", v(0.55, 0.6, 0.1), v(-0.36 * size, centerY + 0.18 * size, front - 0.03), "White")
	add("RightEye", v(0.42, 0.45, 0.1), v(0.38 * size, centerY + 0.12 * size, front - 0.03), "White")
	add("LeftPupil", v(0.2, 0.22, 0.06), v(-0.3 * size, centerY + 0.14 * size, front - 0.09), "Pupil")
	add("RightPupil", v(0.16, 0.18, 0.06), v(0.33 * size, centerY + 0.1 * size, front - 0.09), "Pupil")
	add("Mouth", v(0.75, 0.42, 0.08), v(0.05 * size, centerY - 0.4 * size, front - 0.03), "Mouth")
	add("ToothLeft", v(0.16, 0.15, 0.06), v(-0.12 * size, centerY - 0.27 * size, front - 0.08), "White")
	add("ToothRight", v(0.16, 0.15, 0.06), v(0.2 * size, centerY - 0.27 * size, front - 0.08), "White")
end

-- Zombi normal (también el Rey): piernas, camisa rota, cabezón y brazos al frente
local function zombie(info): { PartSpec }
	local list: { PartSpec } = {}
	local hunch = info.Hunch or 0
	local hip = v(0, -0.6, 0)
	-- Al encorvarse, todo lo de arriba gira hacia adelante desde la cadera
	local bend = CFrame.new(hip) * CFrame.Angles(-hunch, 0, 0)
	local function upper(point: Vector3): Vector3
		return bend:PointToWorldSpace(point - hip)
	end

	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "LegL" else "LegR"
		local legPivot = v(side * 0.45, -0.6, 0)
		table.insert(list, part(name .. "Leg", v(0.75, 1.9, 0.8), legPivot, v(0, -0.95, 0), 0, "Pants", "Leg", { Material = FABRIC, Role = role }))
		table.insert(list, part(name .. "Foot", v(0.8, 0.3, 1.1), legPivot, v(0, -1.75, -0.2), 0, "Skin", "Leg", { Role = role }))
	end

	local torsoTilt = 0.2 + hunch
	table.insert(list, part("Torso", v(1.9, 1.9, 1), hip, v(0, 0.95, 0), torsoTilt, "Shirt", "Torso", { Material = FABRIC }))
	-- Camisa rota: se ve la panza verde
	table.insert(list, part("Belly", v(0.8, 0.55, 0.06), hip, v(0.35, 0.45, -0.52), torsoTilt, "Skin", "Torso"))
	table.insert(list, part("Tear", v(0.35, 0.3, 0.06), hip, v(-0.55, 1.3, -0.52), torsoTilt, "Skin", "Torso"))

	local headPivot = upper(v(0, 1.3, -0.3))
	local headTilt = 0.3 + hunch * 0.5
	table.insert(list, part("Head", v(1.5, 1.4, 1.3), headPivot, v(0, 0.7, 0), headTilt, "Skin", "Head"))
	face(list, headPivot, headTilt, 0.7, -0.65, 1)

	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "ArmL" else "ArmR"
		local shoulder = upper(v(side * 1.15, 1.05, -0.15))
		table.insert(list, part(name .. "Arm", v(0.45, 0.45, 1.8), shoulder, v(0, 0, -0.9), 0, "Skin", "Arm", { Role = role }))
		table.insert(list, part(name .. "Sleeve", v(0.58, 0.58, 0.55), shoulder, v(0, 0, -0.2), 0, "Shirt", "Arm", { Material = FABRIC, Role = role }))
		table.insert(list, part(name .. "Hand", v(0.55, 0.5, 0.4), shoulder, v(0, -0.05, -1.85), 0, "Skin", "Arm", { Role = role }))
		if info.Armor then
			table.insert(list, part(name .. "Pauldron", v(0.75, 0.4, 0.75), shoulder, v(0, 0.3, -0.15), 0, "Iron", "Arm", { Material = METAL, Role = role }))
		end
	end

	if info.Armor then
		table.insert(list, part("ChestPlate", v(2.02, 1.25, 1.1), hip, v(0, 1.2, 0), torsoTilt, "Iron", "Torso", { Material = METAL }))
	end
	if info.Cape then
		local capePivot = upper(v(0, 1.25, 0.5))
		table.insert(list, part("Cape", v(2.1, 2.6, 0.15), capePivot, v(0, -1.25, 0.12), -0.12, "Cape", "Torso", { Material = FABRIC, Role = "Cape" }))
	end

	-- Sombreros
	local hat = info.Hat
	local function hatPart(name, size, y, color, extra)
		table.insert(list, part(name, size, headPivot, v(0, y, 0), headTilt + 0.12, color, "Head", extra))
	end
	if hat == "Cone" then
		-- Cono de tránsito naranja con franja blanca, un poco chueco
		hatPart("ConeBase", v(1.5, 0.2, 1.5), 1.48, "Orange")
		hatPart("ConeMid", v(1.05, 0.45, 1.05), 1.8, "Orange")
		hatPart("ConeStripe", v(0.86, 0.26, 0.86), 2.15, "White")
		hatPart("ConeTop", v(0.62, 0.45, 0.62), 2.5, "Orange")
		hatPart("ConeTip", v(0.3, 0.3, 0.3), 2.85, "Orange")
	elseif hat == "Helmet" then
		-- Yelmo de caballero con protector de nariz y penacho
		hatPart("Helmet", v(1.66, 0.8, 1.46), 1.22, "Iron", { Material = METAL })
		table.insert(list, part("NoseGuard", v(0.2, 0.55, 0.1), headPivot, v(0, 0.72, -0.72), headTilt, "Iron", "Head", { Material = METAL }))
		hatPart("Plume", v(0.22, 0.6, 1.1), 1.9, "Plume", { Material = FABRIC })
	elseif hat == "Crown" then
		hatPart("CrownBand", v(1.6, 0.35, 1.42), 1.55, "Gold", { Material = METAL })
		for _, corner in { v(-0.6, 0, -0.52), v(0.6, 0, -0.52), v(-0.6, 0, 0.52), v(0.6, 0, 0.52), v(0, 0, -0.62) } do
			table.insert(list, part("CrownSpike", v(0.26, 0.5, 0.26), headPivot, corner + v(0, 1.95, 0), headTilt + 0.12, "Gold", "Head", { Material = METAL }))
		end
		table.insert(list, part("Jewel", v(0.26, 0.26, 0.06), headPivot, v(0, 1.55, -0.74), headTilt + 0.12, "Ruby", "Head", { Material = Enum.Material.Neon }))
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

-- Dragón zombi: cuerpo podrido con costillas al aire, alas rotas que aletean,
-- cuello largo, mandíbula que se abre para escupir fuego y cola
local function dragon(_info): { PartSpec }
	local list: { PartSpec } = {}
	local slate = Enum.Material.Slate
	table.insert(list, part("Body", v(2, 1.6, 4.2), v(0, 0, 0), v(0, 0, 0), 0, "Skin", "Torso", { Material = slate }))
	for index, z in { -1.2, 0, 1.2 } do
		table.insert(list, part("Spine" .. index, v(0.3, 0.5, 0.6), v(0, 0, 0), v(0, 1, z), 0, "Shirt", "Torso"))
		table.insert(list, part("Rib" .. index, v(2.18, 0.22, 0.3), v(0, 0, 0), v(0, -0.1, z * 0.7), 0, "Shirt", "Torso"))
	end

	-- Cuello, cabeza y mandíbula
	table.insert(list, part("Neck", v(0.9, 0.9, 2.4), v(0, 0.5, -2), v(0, 0.3, -1.1), -0.45, "Skin", "Head", { Material = slate, Role = "Neck" }))
	local headPivot = v(0, 1.5, -3.6)
	table.insert(list, part("Head", v(1.3, 1, 1.9), headPivot, v(0, 0, -0.8), 0, "Skin", "Head", { Material = slate, Role = "Neck" }))
	table.insert(list, part("Teeth", v(1, 0.2, 0.1), headPivot, v(0, -0.55, -1.7), 0, "White", "Head", { Role = "Neck" }))
	for _, side in { -1, 1 } do
		table.insert(list, part("Horn", v(0.25, 0.25, 1.1), headPivot + v(side * 0.45, 0.35, 0.2), v(0, 0.2, 0.5), -0.6, "Shirt", "Head", { Role = "Neck" }))
		table.insert(list, part("Eye", v(0.08, 0.25, 0.32), headPivot, v(side * 0.66, 0.22, -1.1), 0, "Eyes", "Head", { Material = Enum.Material.Neon, Role = "Neck" }))
	end
	table.insert(list, part("Jaw", v(1.1, 0.35, 1.6), v(0, 1.12, -3.5), v(0, -0.1, -0.75), 0, "Skin", "Head", { Material = slate, Role = "Jaw" }))
	-- Punto invisible de donde sale el fuego (mira adelante y abajo)
	table.insert(list, part("Breath", v(0.2, 0.2, 0.2), headPivot, v(0, -0.3, -1.9), 0.75, "Skin", "Head", { Role = "Neck", Transparent = true }))

	-- Alas: hueso, membrana rota y dedos
	for _, side in { -1, 1 } do
		local name = if side < 0 then "Left" else "Right"
		local role = if side < 0 then "WingL" else "WingR"
		local root = v(side * 0.9, 0.6, -0.8)
		table.insert(list, part(name .. "WingBone", v(5.5, 0.35, 0.35), root, v(side * 2.75, 0, 0), 0, "Shirt", "Wing", { Role = role, Axis = "Z" }))
		table.insert(list, part(name .. "Wing", v(5.5, 0.12, 2.8), root, v(side * 2.75, 0, 1.4), 0, "Pants", "Wing", { Material = FABRIC, Role = role, Axis = "Z" }))
		table.insert(list, part(name .. "WingFinger", v(0.25, 0.14, 2.6), root, v(side * 5.25, 0.05, 1.25), 0, "Shirt", "Wing", { Role = role, Axis = "Z" }))
		table.insert(list, part(name .. "WingFinger2", v(0.22, 0.14, 2.2), root, v(side * 3.2, 0.05, 1.1), 0, "Shirt", "Wing", { Role = role, Axis = "Z" }))
	end

	-- Cola que se mece y patas colgando
	local tailPivot = v(0, 0.1, 2.1)
	table.insert(list, part("Tail", v(0.8, 0.7, 2.6), tailPivot, v(0, 0, 1.3), 0.1, "Skin", "Tail", { Material = slate, Role = "Tail", Axis = "Y" }))
	table.insert(list, part("Tail2", v(0.5, 0.45, 2.2), tailPivot, v(0, -0.25, 3.6), 0.1, "Skin", "Tail", { Material = slate, Role = "Tail", Axis = "Y" }))
	table.insert(list, part("TailSpike", v(0.6, 0.6, 0.6), tailPivot, v(0, -0.4, 4.8), 0.1, "Shirt", "Tail", { Role = "Tail", Axis = "Y" }))
	for _, corner in { v(-0.8, -0.7, -1.3), v(0.8, -0.7, -1.3), v(-0.8, -0.7, 1.3), v(0.8, -0.7, 1.3) } do
		table.insert(list, part("Leg", v(0.5, 1.2, 0.5), corner, v(0, -0.6, 0), -0.3, "Skin", "Leg", { Material = slate }))
		table.insert(list, part("Claw", v(0.6, 0.25, 0.7), corner, v(0, -1.25, -0.1), -0.3, "Shirt", "Leg"))
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
	if Config.ZombieStyle ~= "3D" or not Config.UseStoreModels or Config.Style.Blocky then
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
	Fat = fat,
	Dragon = dragon,
}

local cache: { [string]: { PartSpec } } = {}

-- Cadera (pivote del torso) para un zombi de 5 studs: el torso, la cabeza y
-- los brazos giran juntos alrededor de este punto
local HIPS = {
	Zombie = Vector3.new(0, -0.6, 0),
	Fat = Vector3.new(0, -1, 0),
	Dragon = Vector3.zero,
}

function ZombieModels.getHip(info): Vector3
	if info.Model == "Zombie" then
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
