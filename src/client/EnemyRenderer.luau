-- Dibuja los zombis localmente. La posición sale de EnemyMath con el tiempo
-- del servidor, y se mueven todos de una vez con BulkMoveTo.
--
-- Estilo "3D": muñecos de bloques de dibujo animado (ZombieModels) con
-- animación de caminar, golpear y, en el dragón, aletear y escupir fuego.
-- Estilo "Pixel": sprite que siempre mira a la cámara (si tiene Sprite).
-- Al morir revientan en cubitos (DeathFx).
--
-- Optimización: los zombis detrás de la cámara no se mueven en pantalla y los
-- muy lejanos se actualizan cada 3 cuadros. Cada zombi tiene un nivel de
-- detalle (LOD) según la distancia y la calidad gráfica (Config.Graphics):
--   * completo: la animación entera. Las piezas que giran juntas (toda la cara
--     con la cabeza, la manga con el brazo) comparten una articulación, así el
--     giro se calcula una vez por articulación y no una vez por pieza.
--   * rígido (solo calidad baja): pasado el tope de animados, los demás cercanos
--     se mueven enteros con la pose quieta y un saltito al caminar. Una
--     multiplicación por pieza; si no se movió (ya llegó a la campana), nada.
--   * lejano: pose quieta, como siempre. En calidad baja además se esconden las
--     piezas chicas (cara, dientes, manchas): se mueven 11 de 36 piezas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Paths = require(Shared.Paths)
local Remotes = require(Shared.Remotes)
local ResolvedAssets = require(Shared.ResolvedAssets)
local DamageNumbers = require(script.Parent.DamageNumbers)
local DeathFx = require(script.Parent.DeathFx)
local ZombieAnimator = require(script.Parent.ZombieAnimator)
local ZombieModels = require(script.Parent.ZombieModels)
local Sfx = require(script.Parent.Sfx)
local ComboUi = require(script.Parent.ComboUi)
local XpDrops = require(script.Parent.XpDrops)

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TINT = Color3.new(1, 0.35, 0.35)
local FLASH_TIME = 0.08
local SWAY_SPEED = 4
local TURN_RATE = 5 -- qué tan rápido giran hacia donde caminan
-- Pose quieta para los zombis lejanos y rígidos (no se anima)
local REST_POSE = ZombieAnimator.newPose()
-- Niveles de detalle (ver arriba)
local LOD_FULL = 1
local LOD_RIGID = 2
local LOD_FAR = 3
local BUDGET_FRAMES = 10 -- cada cuántos cuadros se eligen los que se animan enteros
local BUDGET_STICKY = 0.85 -- el que ya se anima entero cuenta como más cerca: no salta de nivel por un paso
local DIRT = { Color3.fromRGB(92, 70, 48), Color3.fromRGB(70, 54, 38), Color3.fromRGB(60, 90, 50) }
local SPRITE_SWAY = 0.06
local BOB_HEIGHT = 0.12
local BREATH_DISTANCE = 320
local BLOOD = Color3.fromRGB(120, 22, 26)
local graphics = Config.Graphics
-- Pixel art 3D: colores planos, y el fuego del dragón son cubitos
local voxel = Config.Style.Blocky
local FIRE_CUBES_PER_SECOND = 40
local FIRE_COLORS = { Color3.fromRGB(150, 255, 120), Color3.fromRGB(200, 255, 110), Color3.fromRGB(255, 200, 70), Color3.fromRGB(255, 140, 40) }

type PartSpec = ZombieModels.PartSpec

-- Articulación: las piezas con el mismo papel, inclinación y pivote giran juntas
type Joint = {
	Role: string,
	Tilt: number,
	Pivot: CFrame,
	OnTorso: boolean,
}

type Piece = {
	Part: BasePart,
	Spec: PartSpec?,
	Color: Color3,
	Glows: boolean,
	Joint: number?, -- índice en Visual.Joints; nil = fija al torso o a la raíz
	Offset: CFrame, -- desde su articulación (o desde el torso o la raíz si es fija)
	Rest: CFrame, -- desde la raíz con la pose quieta (zombis rígidos y lejanos)
	Small: boolean, -- pieza chica: en calidad baja no se dibuja de lejos ni sale volando al morir
	OnTorso: boolean, -- se mueve con el torso (cabeza, brazos, ropa) o con la raíz (piernas)
}

type Visual = {
	Type: string,
	Pieces: { Piece },
	Joints: { Joint },
	JointFrames: { CFrame }, -- dónde quedó cada articulación en este cuadro
	Decal: Decal?,
	Breath: ParticleEmitter?,
	BreathLight: PointLight?,
	BreathPart: BasePart?, -- de dónde sale el fuego (estilo voxel)
	SpriteFrames: { string }?, -- dos cuadros de caminar (estilo Pixel)
	SpriteFrame: number,
	FireBudget: number,
	Path: EnemyMath.Path,
	Speed: number,
	Scale: number,
	Extent: number, -- medio tamaño, para no ocultar a los jefes grandes antes de tiempo
	Flying: boolean,
	Facing: Vector3, -- hacia dónde mira (gira suave hacia donde camina)
	Gait: ZombieAnimator.Gait,
	Pose: ZombieAnimator.Pose,
	Hip: Vector3,
	HitAt: number,
	SpawnAt: number,
	FlashUntil: number,
	Phase: number,
	Slot: number, -- para repartir las actualizaciones de los lejanos entre cuadros
	Boss: boolean,
	Lod: number,
	Hidden: boolean, -- piezas chicas escondidas (lejano en calidad baja)
	InBudget: boolean, -- entre los más cercanos que se animan enteros (calidad baja)
	Visible: boolean, -- false si quedó detrás de la cámara
	Distance: number,
	Score: number, -- para ordenar el tope de animados
	PlacedAt: Vector3?, -- dónde se dejaron las piezas rígidas (si no cambia, no se mueven)
	PlacedFacing: Vector3?,
	Mouth: CFrame?, -- boca del dragón (de donde sale el fuego)
}

local EnemyRenderer = {}

-- Zombi que cruza un rayo: id, distancia desde el origen y punto del impacto
export type RayHit = { Id: number, Distance: number, Position: Vector3 }

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
local random = Random.new()
-- Calidad baja (la marca WorldFx): menos detalle en los zombis
local player = Players.LocalPlayer
local lowQuality = player:GetAttribute("LowQuality") == true
local budgetDirty = true
local candidates: { Visual } = {}

local function newPart(name: string, size: Vector3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function createSprite(typeName: string, info, frames: { string }): ({ Piece }, Decal)
	local size = info.SpriteSize or info.Size
	local part = newPart(typeName, Vector3.new(size.X, size.Y, 0.05), Enum.Material.SmoothPlastic)
	part.Transparency = 1
	local decal = Instance.new("Decal")
	decal.Texture = frames[1]
	decal.Face = Enum.NormalId.Front
	decal.Parent = part
	part.Parent = folder
	return { { Part = part, Spec = nil, Color = info.Skin, Glows = false, Offset = CFrame.identity, Rest = CFrame.identity, Small = false, OnTorso = false } }, decal
end

-- Fuego del dragón: llamas verdes y naranjas que salen de la boca
local function addBreath(part: BasePart, scale: number): (ParticleEmitter?, PointLight)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 255, 110)
	light.Range = math.min(12 * scale, 60)
	light.Brightness = 3
	light.Enabled = false
	light.Parent = part
	if voxel then
		return nil, light
	end
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.EmissionDirection = Enum.NormalId.Front
	fire.Rate = 70
	fire.Lifetime = NumberRange.new(0.5, 0.8)
	fire.Speed = NumberRange.new(9 * scale, 13 * scale)
	fire.SpreadAngle = Vector2.new(10, 10)
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * scale), NumberSequenceKeypoint.new(1, 2.2 * scale) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Color = ColorSequence.new(Color3.fromRGB(150, 255, 120), Color3.fromRGB(255, 140, 40))
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = part
	return fire, light
end

local function createBody(typeName: string, info, scale: number, id: number): ({ Piece }, { Joint }, ParticleEmitter?, PointLight?, BasePart?)
	local pieces = {}
	local joints: { Joint } = {}
	local jointIndex: { [string]: number } = {}
	local breath, breathLight, breathPart = nil, nil, nil
	-- Un tono distinto por zombi (no a los jefes, que tienen su look). Todas las
	-- piezas del mismo color de un zombi salen con la misma semilla, así coinciden.
	local varied = not info.IsBoss
	-- En celulares flojos se omiten los adornos pequeños (vendas, heridas, costillas)
	local lowDetail = lowQuality
	for _, spec in ZombieModels.get(typeName, info) do
		if lowDetail and spec.Detail then
			continue
		end
		local color, glows = ZombieModels.resolveColor(info, spec.Color)
		if varied and not glows then
			local seed = id * 7
			for index = 1, #spec.Color do
				seed += string.byte(spec.Color, index) * index
			end
			color = ZombieModels.vary(spec.Color, color, Random.new(seed))
		end
		local material = if glows then Enum.Material.Neon else spec.Material
		if Config.Style.Flat and material ~= Enum.Material.Neon then
			material = Enum.Material.SmoothPlastic
		end
		local part: BasePart
		if spec.Mesh then
			-- Malla de la tienda: conserva su textura y color
			part = spec.Mesh:Clone()
			part.Size = spec.Size * scale
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			color = part.Color
		else
			local block = newPart(spec.Name, spec.Size * scale, material)
			-- En los estilos de cubos todo queda en bloques
			if spec.Shape and not Config.Style.Blocky then
				block.Shape = spec.Shape
			end
			block.Color = color
			part = block
		end
		if spec.Transparent then
			part.Transparency = 1
			breath, breathLight = addBreath(part, scale)
			breathPart = part
		end
		part.Parent = folder
		local pivot, hang = spec.Pivot * scale, spec.Hang * scale
		local dragon = info.Model == "Dragon"
		-- La cabeza (con su cara y sombrero) se mueve entera: mira a los lados
		local role = spec.Role or (if not dragon and spec.Group == "Head" then "Head" else nil)
		local onTorso = not dragon and spec.Group ~= "Leg"
		local size = part.Size
		local piece: Piece = {
			Part = part,
			Spec = spec,
			Color = color,
			Glows = material == Enum.Material.Neon,
			Joint = nil,
			Offset = CFrame.identity,
			Rest = CFrame.identity,
			Small = not spec.Transparent and math.max(size.X, size.Y, size.Z) < graphics.SmallPartSize,
			OnTorso = onTorso,
		}
		if role then
			-- Las piezas que giran igual alrededor del mismo pivote comparten articulación
			local key = `{role}|{spec.Tilt}|{pivot}|{onTorso}`
			local index = jointIndex[key]
			if not index then
				table.insert(joints, { Role = role, Tilt = spec.Tilt, Pivot = CFrame.new(pivot), OnTorso = onTorso })
				index = #joints
				jointIndex[key] = index
			end
			piece.Joint = index
			piece.Offset = CFrame.new(hang) * (spec.Turn or CFrame.identity)
			piece.Rest = CFrame.new(pivot) * ZombieAnimator.rotation(role, spec.Tilt, REST_POSE) * piece.Offset
		else
			-- Pose fija ya escalada (con la pose quieta el torso coincide con la raíz)
			piece.Offset = CFrame.new(pivot) * CFrame.Angles(-spec.Tilt, 0, 0) * CFrame.new(hang) * (spec.Turn or CFrame.identity)
			piece.Rest = piece.Offset
		end
		table.insert(pieces, piece)
	end
	return pieces, joints, breath, breathLight, breathPart
end

local function setFlash(visual: Visual, flashing: boolean)
	if visual.Decal then
		visual.Decal.Color3 = if flashing then FLASH_TINT else FLASH_COLOR
		return
	end
	for _, piece in visual.Pieces do
		if not piece.Glows then
			piece.Part.Color = if flashing then FLASH_COLOR else piece.Color
		end
	end
end

local function addEnemy(id: number, typeName: string, points: { Vector3 }, speed: number, spawnTime: number)
	if visuals[id] or deadIds[id] then
		return
	end
	local info = Config.Enemies[typeName]
	if not info then
		return
	end

	local scale = info.Size.Y / 5
	local pieces, decal, breath, breathLight, breathPart
	local joints: { Joint } = {}
	-- Sprite pixelado si se subió (tools/upload_assets.py) o si se pegó uno en Config
	local frames = if Config.ZombieStyle == "Pixel" then ResolvedAssets.getSprite(typeName) else nil
	if not frames and Config.ZombieStyle == "Pixel" and info.Sprite ~= "" then
		frames = { info.Sprite, info.Sprite }
	end
	if frames then
		pieces, decal = createSprite(typeName, info, frames)
		if info.Flying then
			-- El dragón de sprite también ilumina con su fuego
			breathLight = Instance.new("PointLight")
			breathLight.Color = Color3.fromRGB(150, 255, 110)
			breathLight.Range = 40
			breathLight.Brightness = 3
			breathLight.Enabled = false
			breathLight.Parent = pieces[1].Part
		end
	else
		pieces, joints, breath, breathLight, breathPart = createBody(typeName, info, scale, id)
	end
	visuals[id] = {
		Type = typeName,
		Pieces = pieces,
		Joints = joints,
		JointFrames = table.create(#joints, CFrame.identity),
		Decal = decal,
		Breath = breath,
		BreathLight = breathLight,
		BreathPart = breathPart,
		SpriteFrames = frames,
		SpriteFrame = 1,
		FireBudget = 0,
		Path = EnemyMath.newRoute(points, speed, spawnTime),
		Speed = speed,
		Scale = scale,
		Extent = math.max(info.Size.X, info.Size.Y) / 2,
		Flying = info.Flying == true,
		Facing = Vector3.new(0, 0, 1),
		Gait = ZombieAnimator.newGait(id, info),
		Pose = ZombieAnimator.newPose(),
		Hip = ZombieModels.getHip(info) * scale,
		HitAt = -math.huge,
		SpawnAt = -math.huge,
		FlashUntil = 0,
		Phase = id * 0.37,
		Slot = id % 3,
		Boss = info.IsBoss == true,
		Lod = if decal then LOD_FULL else 0, -- 0: todavía no se ubicó
		Hidden = false,
		InBudget = false,
		Visible = false,
		Distance = math.huge,
		Score = 0,
		PlacedAt = nil,
		PlacedFacing = nil,
		Mouth = nil,
	}
	budgetDirty = true

	-- Recién nacido (no el que ya estaba al entrar al juego): sale de la tierra
	local visual = visuals[id]
	local now = workspace:GetServerTimeNow()
	local age = now - spawnTime
	Sfx.onEnemySpawned(typeName)
	if not visual.Flying and age < ZombieAnimator.EMERGE_TIME then
		visual.SpawnAt = os.clock() - math.max(age, 0)
		visual.Facing = Vector3.new(visual.Path.Points[#visual.Path.Points].X - points[1].X, 0, visual.Path.Points[#visual.Path.Points].Z - points[1].Z)
		visual.Facing = if visual.Facing.Magnitude > 0.01 then visual.Facing.Unit else Vector3.new(0, 0, 1)
		local position = EnemyMath.getPosition(visual.Path, now)
		if (position - workspace.CurrentCamera.CFrame.Position).Magnitude < graphics.DeathFxDistance then
			-- Tierra que salta al salir
			for _ = 1, math.min(6, DeathFx.budget()) do
				local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.6, 1.4), random:NextNumber(-1, 1)).Unit
				DeathFx.addCube(Vector3.new(position.X, Paths.walkHeight(position) + 0.3, position.Z), DIRT[random:NextInteger(1, #DIRT)], 0.4 * scale ^ 0.8, direction * 8 * scale ^ 0.5, 50, random:NextNumber(0.5, 0.8))
			end
		end
	end
end

local function destroyPieces(visual: Visual)
	for _, piece in visual.Pieces do
		piece.Part:Destroy()
	end
end

-- Reparte los cubitos entre las piezas según su tamaño (cabeza, torso, piernas)
local function cubeShares(flying: { Piece }, total: number): { [Piece]: number }
	local volumes = {}
	local sum = 0
	for _, piece in flying do
		local size = piece.Part.Size
		local volume = size.X * size.Y * size.Z
		volumes[piece] = volume
		sum += volume
	end
	local shares = {}
	for piece, volume in volumes do
		shares[piece] = math.floor(total * volume / sum + 0.35)
	end
	return shares
end

-- Muerte al estilo pixelado: destello blanco, la cabeza sale volando, el
-- cuerpo se desarma hacia atrás y cada pedazo revienta en cubitos.
local function explode(visual: Visual, position: Vector3, cameraPosition: Vector3)
	local info = Config.Enemies[visual.Type]
	local scale = visual.Scale
	local boost = scale ^ 0.6
	local gravity = 60 * boost
	local away = Vector3.new(position.X - cameraPosition.X, 0, position.Z - cameraPosition.Z)
	away = if away.Magnitude > 0.01 then away.Unit else -visual.Facing
	local cubeSize = 0.42 * scale ^ 0.8
	-- El jefe final revienta en más cubitos (DeathFx igual pone su tope)
	local wanted = if info.Final then 140 elseif info.IsBoss then 70 else 14
	local goo = info.Skin:Lerp(Color3.new(0, 0, 0), 0.35)

	-- En calidad baja las piezas chicas (cara, dientes, manchas) no salen
	-- volando: desaparecen con el destello y quedan los pedazos grandes
	local flying = {}
	for _, piece in visual.Pieces do
		local spec = piece.Spec
		if (spec and spec.Transparent) or (piece.Small and (lowQuality or visual.Hidden)) then
			piece.Part:Destroy()
		else
			table.insert(flying, piece)
		end
	end
	local shares = cubeShares(flying, math.min(wanted, DeathFx.budget()))

	for _, piece in flying do
		local spec = piece.Spec
		local group = if spec then spec.Group else "Torso"
		local velocity, spin, life
		if visual.Decal then
			-- El sprite cae de espaldas y revienta
			velocity = away * 3 + Vector3.new(0, 5, 0)
			spin = Vector3.new(-6, 0, 0)
			life = 0.4
		elseif visual.Flying then
			-- El dragón se desploma desde el cielo y revienta al tocar el suelo
			velocity = away * random:NextNumber(2, 6) * boost + Vector3.new(0, random:NextNumber(-2, 4) * boost, 0)
			spin = Vector3.new(random:NextNumber(-2, 2), random:NextNumber(-2, 2), random:NextNumber(-2, 2))
			life = 2.5
		elseif group == "Head" then
			velocity = away * 6 * boost + Vector3.new(random:NextNumber(-2, 2), 15, random:NextNumber(-2, 2)) * boost
			spin = Vector3.new(random:NextNumber(6, 10), random:NextNumber(-4, 4), random:NextNumber(-3, 3))
			life = 0.8
		elseif group == "Leg" then
			velocity = away * random:NextNumber(1, 3) * boost + Vector3.new(0, random:NextNumber(1, 3) * boost, 0)
			spin = Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
			life = random:NextNumber(0.45, 0.6)
		else
			velocity = away * random:NextNumber(3, 6) * boost + Vector3.new(random:NextNumber(-2, 2), random:NextNumber(4, 8), random:NextNumber(-2, 2)) * boost
			spin = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))
			life = random:NextNumber(0.5, 0.7)
		end
		DeathFx.addPiece(piece.Part, piece.Part.CFrame, {
			Velocity = velocity,
			Spin = spin,
			Gravity = gravity,
			Life = life,
			BurstColors = { piece.Color, piece.Color, goo, BLOOD },
			BurstCount = if visual.Decal then math.min(10, DeathFx.budget()) else shares[piece] or 0,
			BurstSize = cubeSize,
			BurstSpeed = 11 * boost,
			BurstOnGround = visual.Flying,
			Flash = visual.Decal == nil,
		})
	end
	if visual.Decal then
		visual.Decal.Color3 = FLASH_TINT
	end
	DeathFx.splat(position, math.max(1.6, info.Size.X * 0.45), goo, if info.IsBoss then 8 else 4)
end

local function removeEnemy(id: number, animate: boolean)
	deadIds[id] = true
	local visual = visuals[id]
	if not visual then
		return
	end
	visuals[id] = nil

	if not animate then
		Sfx.onEnemyRemoved(visual.Type, nil, false)
		destroyPieces(visual)
		return
	end
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	Sfx.onEnemyRemoved(visual.Type, position, true)
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	-- Muy lejos no vale la pena el efecto: desaparece (menos el jefe final, que lo ven todos)
	local info = Config.Enemies[visual.Type]
	if not info.Final and (position - cameraPosition).Magnitude > graphics.DeathFxDistance + visual.Extent then
		destroyPieces(visual)
		return
	end
	explode(visual, position, cameraPosition)
end

-- Número de daño sobre la cabeza del enemigo
local function showDamage(id: number, amount: number, killed: boolean)
	local visual = visuals[id]
	if not visual or type(amount) ~= "number" then
		return
	end
	local info = Config.Enemies[visual.Type]
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	local top = (info.SpriteSize or info.Size).Y / 2 + 0.8
	DamageNumbers.show(position + Vector3.new(0, top, 0), amount, killed)
end

-- Salpicadura de sangre en cubitos (la malla con textura no se pone blanca)
local function splatter(visual: Visual)
	local info = Config.Enemies[visual.Type]
	if not info or DeathFx.budget() < 4 then
		return
	end
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	if (position - cameraPosition).Magnitude > graphics.DeathFxDistance then
		return
	end
	local scale = info.Size.Y / 5
	local chest = position + Vector3.new(0, info.Size.Y * 0.15, 0)
	-- Salen hacia el lado de la cámara, que es de donde vino el tiro
	local toward = Vector3.new(cameraPosition.X - chest.X, 0, cameraPosition.Z - chest.Z).Unit
	for _ = 1, 4 do
		local direction = (toward + Vector3.new(random:NextNumber(-0.8, 0.8), random:NextNumber(0.3, 1.2), random:NextNumber(-0.8, 0.8))).Unit
		DeathFx.addCube(chest, BLOOD, 0.22 * scale ^ 0.7, direction * random:NextNumber(6, 11), 45, random:NextNumber(0.3, 0.55))
	end
end

local function flashEnemy(id: number)
	local visual = visuals[id]
	if visual then
		setFlash(visual, true)
		visual.FlashUntil = os.clock() + FLASH_TIME
		visual.HitAt = os.clock()
		if visual.Pieces[1] and visual.Pieces[1].Spec and visual.Pieces[1].Spec.Mesh then
			splatter(visual)
		end
	end
end

-- Punto del eje de la cápsula de un zombi más cercano al rayo, igual que en
-- EnemyService.raycast (dos pasadas bastan). Devuelve la distancia sobre el
-- rayo, ese punto del eje y el radio de la cápsula.
local function closestOnBody(origin: Vector3, direction: Vector3, center: Vector3, info): (number, Vector3, number)
	local radius = info.HitRadius
	local reach = math.max(0, info.Size.Y / 2 - radius)
	local extra = info.HitExtra or 0
	local along = (center - origin):Dot(direction)
	local axisPoint = center
	for _ = 1, 2 do
		local rayPoint = origin + direction * along
		axisPoint = Vector3.new(center.X, math.clamp(rayPoint.Y, center.Y - reach, center.Y + reach + extra), center.Z)
		along = (axisPoint - origin):Dot(direction)
	end
	return along, axisPoint, radius
end

-- Rayo contra los zombis que se dibujan (sus piezas tienen CanQuery = false
-- y el raycast del mundo no los ve). Cada uno es una cápsula vertical con la
-- misma forma que usa el servidor. Devuelve el más cercano o nil.
function EnemyRenderer.raycast(origin: Vector3, direction: Vector3, range: number): RayHit?
	local now = workspace:GetServerTimeNow()
	local best: RayHit? = nil
	for id, visual in visuals do
		local info = Config.Enemies[visual.Type]
		local along, axisPoint, radius = closestOnBody(origin, direction, EnemyMath.getPosition(visual.Path, now), info)
		if along > 0 and along < range then
			local gap = axisPoint - (origin + direction * along)
			local gapSquared = gap:Dot(gap)
			if gapSquared <= radius * radius then
				-- Donde el rayo entra en la cápsula (ahí termina la bala)
				local distance = math.max(0, along - math.sqrt(radius * radius - gapSquared))
				if not best or distance < best.Distance then
					best = { Id = id, Distance = distance, Position = origin + direction * distance }
				end
			end
		end
	end
	return best
end

-- Ayuda de puntería: el zombi cuyo cuerpo queda a menos de `maxAngle`
-- radianes del rayo (el más cercano al centro de la mira). Position es el
-- punto de su eje hacia donde conviene apuntar.
function EnemyRenderer.nearestToAim(origin: Vector3, direction: Vector3, range: number, maxAngle: number): RayHit?
	local now = workspace:GetServerTimeNow()
	local best: RayHit? = nil
	local bestAngle = maxAngle
	for id, visual in visuals do
		local info = Config.Enemies[visual.Type]
		local along, axisPoint, radius = closestOnBody(origin, direction, EnemyMath.getPosition(visual.Path, now), info)
		if along > 0 and along < range then
			local gap = math.max(0, (axisPoint - (origin + direction * along)).Magnitude - radius)
			local angle = math.atan2(gap, along)
			if angle <= bestAngle then
				bestAngle = angle
				best = { Id = id, Distance = along, Position = axisPoint }
			end
		end
	end
	return best
end

-- true si algún zombi queda dentro del tajo del cuchillo, con la misma regla
-- que EnemyService.getInCone en el servidor
function EnemyRenderer.anyInSwing(origin: Vector3, direction: Vector3, range: number, arcDegrees: number): boolean
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.01 then
		return false
	end
	flatDirection = flatDirection.Unit
	local minDot = math.cos(math.rad(arcDegrees / 2))
	local now = workspace:GetServerTimeNow()
	for _, visual in visuals do
		local info = Config.Enemies[visual.Type]
		local position = EnemyMath.getPosition(visual.Path, now)
		local offset = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)
		local distance = offset.Magnitude - info.HitRadius
		local heightGap = math.abs(position.Y - origin.Y) - info.Size.Y / 2
		if distance <= range and heightGap <= range then
			if offset.Magnitude < info.HitRadius + 1 or offset.Unit:Dot(flatDirection) >= minDot then
				return true
			end
		end
	end
	return false
end

local nextGrowl = 0

local function byScore(a: Visual, b: Visual): boolean
	return a.Score < b.Score
end

-- Calidad baja: elige los zombis cercanos que se animan enteros (los N más
-- cercanos a la cámara). El que ya estaba animado cuenta como un poco más
-- cerca, así en el borde no cambian de nivel a cada rato.
local function assignBudget()
	table.clear(candidates)
	local limit = graphics.LowAnimateDistance
	for _, visual in visuals do
		local wasIn = visual.InBudget
		visual.InBudget = false
		if not visual.Decal and not visual.Boss and visual.Visible and visual.Distance < limit + visual.Extent then
			visual.Score = visual.Distance * (if wasIn then BUDGET_STICKY else 1)
			table.insert(candidates, visual)
		end
	end
	if #candidates > graphics.LowFullBudget then
		table.sort(candidates, byScore)
	end
	for index = 1, math.min(graphics.LowFullBudget, #candidates) do
		candidates[index].InBudget = true
	end
	table.clear(candidates)
end

-- Nivel de detalle de un zombi de piezas según la distancia y la calidad
local function chooseLod(visual: Visual, distance: number, spawnAge: number): number
	if not lowQuality or visual.Boss then
		-- Calidad alta (y los jefes siempre): como antes, se anima de cerca y al salir de la tierra
		if spawnAge < ZombieAnimator.EMERGE_TIME or distance < graphics.AnimateDistance + visual.Extent then
			return LOD_FULL
		end
		return LOD_FAR
	end
	-- Con histéresis: el lejano vuelve a acercarse unos studs más adentro del borde
	local limit = graphics.LowAnimateDistance + visual.Extent
	if visual.Lod == LOD_FAR then
		limit -= graphics.LodMargin
	end
	if distance > limit then
		return LOD_FAR
	end
	return if visual.InBudget then LOD_FULL else LOD_RIGID
end

-- Esconde o muestra las piezas chicas (lejanos en calidad baja). Se llama en
-- el mismo cuadro en que se ubican las piezas, así nunca se ven fuera de lugar.
local function setHidden(visual: Visual, hidden: boolean)
	visual.Hidden = hidden
	for _, piece in visual.Pieces do
		if piece.Small then
			piece.Part.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function render(dt: number)
	frame += 1
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	local camera = workspace.CurrentCamera.CFrame
	local cameraPosition = camera.Position
	local look = camera.LookVector
	local farDistance = if lowQuality then graphics.LowFarDistance else graphics.FarDistance
	table.clear(parts)
	table.clear(cframes)
	if lowQuality and (budgetDirty or frame % BUDGET_FRAMES == 0) then
		budgetDirty = false
		assignBudget()
	end

	for _, visual in visuals do
		-- El destello del golpe se apaga aunque no se mueva en este cuadro
		if visual.FlashUntil > 0 and clock >= visual.FlashUntil then
			visual.FlashUntil = 0
			setFlash(visual, false)
		end

		local traveled = EnemyMath.getTraveled(visual.Path, now)
		local position, direction = EnemyMath.locate(visual.Path, traveled)
		-- La ruta va a la altura del cuerpo: se le suma el suelo (bosque más
		-- bajo, rampa del puente, terreno), igual que el hitbox del servidor
		position += Vector3.new(0, Paths.walkHeight(position), 0)
		local toEnemy = position - cameraPosition
		local distance = toEnemy.Magnitude
		-- Gruñidos de los que están cerca: de vez en cuando uno suelta uno
		if distance < 50 and clock > nextGrowl and math.random() < 0.04 then
			nextGrowl = clock + 1.2
			Sfx.playAt("ZombieGrowl", position)
		end

		-- Detrás de la cámara no hace falta moverlo: se ubica en cuanto vuelva a verse
		local behind = distance > graphics.CullBehindDistance + visual.Extent and toEnemy:Dot(look) < -visual.Extent
		visual.Visible = not behind
		visual.Distance = distance
		if behind then
			continue
		end
		local hitAge = clock - visual.HitAt
		local spawnAge = clock - visual.SpawnAt
		local lod = if visual.Decal then LOD_FULL else chooseLod(visual, distance, spawnAge)
		-- En calidad baja los lejanos esconden las piezas chicas
		local hide = lowQuality and lod == LOD_FAR
		local changed = lod ~= visual.Lod or hide ~= visual.Hidden
		-- Los muy lejanos se mueven cada 3 cuadros (salvo si cambian de nivel)
		if not changed and distance > farDistance + visual.Extent and frame % 3 ~= visual.Slot then
			continue
		end

		-- Gira suave hacia donde camina (no de golpe en cada curva del camino)
		local flatDirection = Vector3.new(direction.X, 0, direction.Z)
		if flatDirection.Magnitude > 0.01 then
			local target = flatDirection.Unit
			local turned = visual.Facing:Lerp(target, math.min(1, dt * TURN_RATE))
			if (turned - target).Magnitude < 1e-3 then
				-- Ya mira hacia allá: queda fijo (el rígido quieto no se vuelve a mover)
				visual.Facing = target
			elseif turned.Magnitude > 0.01 then
				visual.Facing = turned.Unit
			end
		end
		local arrived = traveled >= visual.Path.Distance
		local wave = math.sin(clock * SWAY_SPEED + visual.Phase)

		if visual.Decal then
			-- Sprite: mira siempre a la cámara (solo en horizontal), alterna sus dos
			-- cuadros al caminar, sale de la tierra y se echa atrás al recibir un golpe
			local pose = visual.Pose
			if visual.Flying then
				ZombieAnimator.flyer(pose, clock, visual.Phase, arrived, visual.Scale, hitAge)
			else
				ZombieAnimator.walker(pose, visual.Gait, clock, visual.Speed, visual.Scale, visual.Phase, arrived, hitAge, spawnAge)
			end
			local frames = visual.SpriteFrames
			if frames and distance < graphics.AnimateDistance + visual.Extent then
				local beat = if arrived then clock * 6 else clock * visual.Speed * 0.9 / math.sqrt(visual.Scale) * visual.Gait.Cadence
				local index = if math.sin(beat + visual.Phase) > 0 then 1 else 2
				if index ~= visual.SpriteFrame then
					visual.SpriteFrame = index;
					(visual.Decal :: Decal).Texture = frames[index]
				end
			end
			local bobbed = position + Vector3.new(0, math.max(pose.Lift, -visual.Extent * 2) + math.abs(wave) * BOB_HEIGHT, 0) - visual.Facing * pose.Back
			local facing = Vector3.new(cameraPosition.X, bobbed.Y, cameraPosition.Z)
			if (facing - bobbed).Magnitude < 0.01 then
				facing = bobbed - visual.Facing
			end
			local lean = if hitAge < 0.28 then (1 - hitAge / 0.28) * 0.35 else 0
			local root = CFrame.lookAt(bobbed, facing) * CFrame.Angles(lean, 0, wave * SPRITE_SWAY)
			table.insert(parts, visual.Pieces[1].Part)
			table.insert(cframes, root)

			-- Dragón de sprite: escupe cubitos de fuego hacia la campana
			local light = visual.BreathLight
			if light then
				local breathing = arrived and distance < BREATH_DISTANCE
				if light.Enabled ~= breathing then
					light.Enabled = breathing
				end
				if breathing then
					local mouth = CFrame.lookAt(position + Vector3.new(0, visual.Extent * 0.3, 0), Vector3.new(0, 4, 0))
					visual.FireBudget += dt * FIRE_CUBES_PER_SECOND
					while visual.FireBudget >= 1 do
						visual.FireBudget -= 1
						local spread = Vector3.new(random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15))
						local velocity = (mouth.LookVector + spread).Unit * 11 * visual.Scale * random:NextNumber(0.8, 1.2)
						DeathFx.addCube(mouth.Position, FIRE_COLORS[random:NextInteger(1, #FIRE_COLORS)], 0.5 * visual.Scale ^ 0.8 * random:NextNumber(0.7, 1.3), velocity, 0, random:NextNumber(0.45, 0.7), true)
					end
				end
			end
		else
			local scale = visual.Scale
			local pose = visual.Pose
			local lift, back
			if lod == LOD_FULL then
				if visual.Flying then
					ZombieAnimator.flyer(pose, clock, visual.Phase, arrived, scale, hitAge)
				else
					ZombieAnimator.walker(pose, visual.Gait, clock, visual.Speed, scale, visual.Phase, arrived, hitAge, spawnAge)
				end
				lift, back = pose.Lift, pose.Back
			else
				-- Rígido: pose quieta y el cuerpo entero sube y baja al caminar. El
				-- lejano queda quieto como antes (solo sale de la tierra en calidad baja).
				local walking = lod == LOD_RIGID and not arrived and not visual.Flying
				lift, back = ZombieAnimator.rigid(visual.Gait, clock, visual.Speed, scale, visual.Phase, walking, hitAge, spawnAge)
			end
			if changed then
				visual.Lod = lod
				if hide ~= visual.Hidden then
					setHidden(visual, hide)
				end
			end

			local lifted = position + Vector3.new(0, lift, 0) - visual.Facing * back
			-- Un rígido que no se movió (ya llegó y mira fijo) deja sus piezas donde están
			local still = lod ~= LOD_FULL and not changed and lifted == visual.PlacedAt and visual.Facing == visual.PlacedFacing
			if not still then
				local root = CFrame.lookAt(lifted, lifted + visual.Facing)
				visual.PlacedAt = if lod == LOD_FULL then nil else lifted
				visual.PlacedFacing = visual.Facing
				local breathPart = visual.BreathPart
				if lod == LOD_FULL then
					-- El torso gira sobre la cadera y lleva consigo la cabeza y los brazos
					local hip = visual.Hip
					local torso = root * CFrame.new(hip) * CFrame.Angles(-pose.TorsoPitch, pose.TorsoYaw, pose.TorsoRoll) * CFrame.new(-hip)
					-- Cada articulación gira una vez y sus piezas cuelgan de ella
					local jointFrames = visual.JointFrames
					for index, joint in visual.Joints do
						jointFrames[index] = (if joint.OnTorso then torso else root) * joint.Pivot * ZombieAnimator.rotation(joint.Role, joint.Tilt, pose)
					end
					for _, piece in visual.Pieces do
						local joint = piece.Joint
						local cframe = if joint then jointFrames[joint] * piece.Offset elseif piece.OnTorso then torso * piece.Offset else root * piece.Offset
						table.insert(parts, piece.Part)
						table.insert(cframes, cframe)
						if piece.Part == breathPart then
							visual.Mouth = cframe
						end
					end
				else
					-- Una multiplicación por pieza; las chicas escondidas no se mueven
					for _, piece in visual.Pieces do
						if hide and piece.Small then
							continue
						end
						local cframe = root * piece.Rest
						table.insert(parts, piece.Part)
						table.insert(cframes, cframe)
						if piece.Part == breathPart then
							visual.Mouth = cframe
						end
					end
				end
			end

			local breathLight = visual.BreathLight
			if breathLight then
				local breathing = arrived and distance < BREATH_DISTANCE
				if breathLight.Enabled ~= breathing then
					breathLight.Enabled = breathing
					if visual.Breath then
						visual.Breath.Enabled = breathing
					end
				end
				local mouth = visual.Mouth
				if breathing and voxel and mouth then
					-- Fuego de cubitos que salen de la boca hacia la campana
					visual.FireBudget += dt * FIRE_CUBES_PER_SECOND
					while visual.FireBudget >= 1 do
						visual.FireBudget -= 1
						local spread = Vector3.new(random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15))
						local velocity = (mouth.LookVector + spread).Unit * 11 * scale * random:NextNumber(0.8, 1.2)
						DeathFx.addCube(mouth.Position, FIRE_COLORS[random:NextInteger(1, #FIRE_COLORS)], 0.5 * scale ^ 0.8 * random:NextNumber(0.7, 1.3), velocity, 0, random:NextNumber(0.45, 0.7), true)
					end
				end
			end
		end
	end

	DeathFx.step(dt, parts, cframes)

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function EnemyRenderer.init()
	DeathFx.init(folder)
	DamageNumbers.init()
	player:GetAttributeChangedSignal("LowQuality"):Connect(function()
		lowQuality = player:GetAttribute("LowQuality") == true
		budgetDirty = true
	end)

	-- El servidor junta los eventos de cada cuadro en un solo mensaje
	Remotes.EnemySpawned.OnClientEvent:Connect(function(spawns)
		for _, entry in spawns do
			addEnemy(table.unpack(entry))
		end
	end)
	-- Golpes y muertes llegan como { id, daño }: el número salta sobre la cabeza
	Remotes.EnemyHit.OnClientEvent:Connect(function(hits)
		-- Varios golpes al mismo zombi en el mismo mensaje (los perdigones de la
		-- escopeta) se juntan en un solo número
		local totals: { [number]: number } = {}
		local order: { number } = {}
		for _, hit in hits do
			local id, amount = hit[1], hit[2]
			if not totals[id] then
				totals[id] = 0
				table.insert(order, id)
			end
			if type(amount) == "number" then
				totals[id] += amount
			end
		end
		for _, id in order do
			showDamage(id, totals[id], false)
			flashEnemy(id)
		end
	end)
	Remotes.EnemyDied.OnClientEvent:Connect(function(deaths)
		for _, death in deaths do
			local visual = visuals[death[1]]
			if visual then
				-- Rombo de experiencia que vuela hacia quien lo mató
				XpDrops.spawn(EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow()), death[3] or 0, visual.Type)
			end
			ComboUi.onKill(death[3] or 0)
			-- Efecto de skin del que lo eliminó (lo ve todo el equipo)
			local killer = Players:GetPlayerByUserId(death[3] or 0)
			local skinId = killer and killer:GetAttribute("DeathSkin")
			if visual and typeof(skinId) == "string" and skinId ~= "" then
				for _, skin in Config.ObjectSkins do
					if skin.Id == skinId then
						-- getPosition ya incluye la altura del suelo
						DeathFx.skinBurst(EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow()), skin)
						break
					end
				end
			end
			showDamage(death[1], death[2], true)
			removeEnemy(death[1], true)
		end
	end)
	-- Cambios de recorrido: persiguen a un jugador, vuelven al camino o los empujan
	Remotes.EnemyPathsUpdated.OnClientEvent:Connect(function(updates)
		for _, update in updates do
			local visual = visuals[update[1]]
			if visual then
				-- El 4.º dato es la velocidad (cambia en la cámara súper lenta)
				visual.Speed = update[4] or visual.Speed
				visual.Path = EnemyMath.newRoute(update[2], visual.Speed, update[3])
			end
		end
	end)
	Remotes.EnemiesCleared.OnClientEvent:Connect(function()
		for id in visuals do
			removeEnemy(id, false)
		end
		table.clear(deadIds)
		DeathFx.clear()
		Sfx.onEnemiesCleared()
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
