-- Piezas reutilizables para construir el mapa: partes, faroles, antorchas,
-- velas, estandartes, cajas, barriles y letreros.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Props = {}

-- Las luces con esta etiqueta parpadean como fuego (lo hace WorldFx en cada cliente)
Props.FLICKER_TAG = "Flicker"
local medieval = (Config.Themes[Config.Theme] or {}).Medieval == true
-- Pixel art 3D: todo es de cubos con colores planos
Props.voxel = Config.ArtStyle == "Voxel"
local KEEP_MATERIAL = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.ForceField] = true,
}
local candleRandom = Random.new(11)

Props.Colors = {
	Stone = Color3.fromRGB(110, 116, 118),
	Wood = Color3.fromRGB(120, 80, 48),
	DarkWood = Color3.fromRGB(74, 50, 32),
	Lantern = Color3.fromRGB(255, 170, 80),
	Flame = Color3.fromRGB(255, 176, 70),
	Wax = Color3.fromRGB(236, 226, 196),
	Iron = Color3.fromRGB(52, 52, 58),
}

function Props.makePart(props: { [string]: any }, className: string?): BasePart
	if Props.voxel then
		-- Bolas y cilindros se vuelven bloques, y los materiales con textura, color plano
		if props.Shape == Enum.PartType.Ball or props.Shape == Enum.PartType.Cylinder then
			props.Shape = Enum.PartType.Block
		end
		if not (props.Material and KEEP_MATERIAL[props.Material]) then
			props.Material = Enum.Material.SmoothPlastic
		end
	end
	local part = Instance.new(className or "Part") :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

-- Decoración que no debe estorbar a los disparos ni a los jugadores
function Props.makeProp(props: { [string]: any }, className: string?): BasePart
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return Props.makePart(props, className)
end

function Props.vary(color: Color3, amount: number, random: Random): Color3
	local factor = 1 + random:NextNumber(-amount, amount)
	return Color3.new(math.min(color.R * factor, 1), math.min(color.G * factor, 1), math.min(color.B * factor, 1))
end

function Props.light(parent: Instance, color: Color3, range: number, brightness: number, shadows: boolean?): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = shadows == true
	light.Parent = parent
	return light
end

function Props.flickerLight(parent: Instance, color: Color3, range: number, brightness: number, shadows: boolean?): PointLight
	local light = Props.light(parent, color, range, brightness, shadows)
	light:SetAttribute("BaseBrightness", brightness)
	CollectionService:AddTag(light, Props.FLICKER_TAG)
	return light
end

-- Antorcha medieval: palo, canasta de hierro y fuego
function Props.torch(parent: Instance, position: Vector3, height: number?, shadows: boolean?)
	local top = height or 6
	Props.makePart({ Name = "TorchPole", Size = Vector3.new(0.45, top, 0.45), Position = position + Vector3.new(0, top / 2, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = parent })
	Props.makeProp({ Name = "TorchCage", Size = Vector3.new(0.9, 0.7, 0.9), Position = position + Vector3.new(0, top + 0.3, 0), Material = Enum.Material.Metal, Color = Props.Colors.Iron, Parent = parent })
	local flame = Props.makeProp({
		Name = "TorchFlame",
		Size = Vector3.new(0.6, 0.9, 0.6),
		Position = position + Vector3.new(0, top + 1, 0),
		Material = Enum.Material.Neon,
		Color = Props.Colors.Flame,
		Parent = parent,
	})
	if Props.voxel then
		-- Llama de cubitos: naranja abajo, amarilla arriba
		Props.makeProp({ Name = "TorchFlameTop", Size = Vector3.new(0.35, 0.45, 0.35), Position = position + Vector3.new(0, top + 1.65, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 110), Parent = parent })
	else
		local fire = Instance.new("Fire")
		fire.Size = 2.5
		fire.Heat = 6
		fire.Color = Color3.fromRGB(255, 150, 60)
		fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
		fire.Parent = flame
	end
	Props.flickerLight(flame, Props.Colors.Flame, 22, 1.7, shadows)
end

-- Grupo de velas en el suelo (o sobre algo). Una sola luz por grupo.
function Props.candles(parent: Instance, position: Vector3, count: number?, withLight: boolean?)
	local total = count or candleRandom:NextInteger(3, 5)
	local flames = {}
	for index = 1, total do
		local angle = index / total * math.pi * 2 + candleRandom:NextNumber(-0.4, 0.4)
		local radius = if index == 1 then 0 else candleRandom:NextNumber(0.4, 0.8)
		local height = candleRandom:NextNumber(0.5, 1.4)
		local base = position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		Props.makeProp({
			Name = "Candle",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 0.32, 0.32),
			CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Material = Enum.Material.SmoothPlastic,
			Color = Props.Colors.Wax,
			CastShadow = false,
			Parent = parent,
		})
		table.insert(flames, Props.makeProp({
			Name = "CandleFlame",
			Size = Vector3.new(0.14, 0.3, 0.14),
			Position = base + Vector3.new(0, height + 0.18, 0),
			Material = Enum.Material.Neon,
			Color = Props.Colors.Flame,
			CastShadow = false,
			Parent = parent,
		}))
	end
	if withLight ~= false then
		Props.flickerLight(flames[1], Props.Colors.Flame, 11, 1.3)
	end
end

-- Estandarte: mástil con travesaño y tela colgando
function Props.banner(parent: Instance, position: Vector3, facing: number, cloth: Color3)
	local frame = CFrame.new(position) * CFrame.Angles(0, facing, 0)
	Props.makePart({ Name = "BannerPole", Size = Vector3.new(0.5, 12, 0.5), CFrame = frame * CFrame.new(0, 6, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = parent })
	Props.makeProp({ Name = "BannerBar", Size = Vector3.new(4.2, 0.3, 0.3), CFrame = frame * CFrame.new(0, 11.4, -0.3), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = parent })
	Props.makeProp({ Name = "BannerCloth", Size = Vector3.new(3.6, 6, 0.12), CFrame = frame * CFrame.new(0, 8.3, -0.35), Material = Enum.Material.Fabric, Color = cloth, Parent = parent })
	Props.makeProp({ Name = "BannerStripe", Size = Vector3.new(3.62, 0.6, 0.14), CFrame = frame * CFrame.new(0, 7.2, -0.35), Material = Enum.Material.Fabric, Color = Color3.fromRGB(230, 190, 70), Parent = parent })
	Props.makeProp({ Name = "BannerTail", Size = Vector3.new(1.4, 1.4, 0.12), CFrame = frame * CFrame.new(0, 5.3, -0.35) * CFrame.Angles(0, 0, math.rad(45)), Material = Enum.Material.Fabric, Color = cloth, Parent = parent })
end

-- Farol con poste. En el mapa medieval se cambia por una antorcha.
function Props.lantern(parent: Instance, position: Vector3)
	if medieval then
		Props.torch(parent, position, 4.6, true)
		return
	end
	Props.makePart({ Name = "LanternPost", Size = Vector3.new(0.4, 4, 0.4), Position = position + Vector3.new(0, 2, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = parent })
	local lantern = Props.makeProp({
		Name = "Lantern",
		Size = Vector3.new(0.9, 1.1, 0.9),
		Position = position + Vector3.new(0, 4.5, 0),
		Material = Enum.Material.Neon,
		Color = Props.Colors.Lantern,
		Parent = parent,
	})
	Props.light(lantern, Props.Colors.Lantern, 22, 1.6, true)
end

function Props.crate(parent: Instance, cframe: CFrame, size: number)
	Props.makePart({ Name = "Crate", Size = Vector3.one * size, CFrame = cframe * CFrame.new(0, size / 2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 100, 60), Parent = parent })
end

function Props.barrel(parent: Instance, position: Vector3)
	Props.makePart({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 2.4, 2.4),
		CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(110, 70, 40),
		Parent = parent,
	})
end

-- Tablón con texto (por ejemplo "ARMERÍA") que mira hacia -Z del CFrame
function Props.sign(parent: Instance, cframe: CFrame, text: string, color: Color3)
	local board = Props.makePart({ Name = "Sign", Size = Vector3.new(8, 2, 0.4), CFrame = cframe, Material = Enum.Material.WoodPlanks, Color = Props.Colors.DarkWood, Parent = parent })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

return Props
