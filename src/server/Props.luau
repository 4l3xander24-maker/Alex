-- Piezas reutilizables para construir el mapa: partes, faroles, cajas,
-- barriles y letreros.
local Props = {}

Props.Colors = {
	Stone = Color3.fromRGB(110, 116, 118),
	Wood = Color3.fromRGB(120, 80, 48),
	DarkWood = Color3.fromRGB(74, 50, 32),
	Lantern = Color3.fromRGB(255, 170, 80),
}

function Props.makePart(props: { [string]: any }, className: string?): BasePart
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

function Props.lantern(parent: Instance, position: Vector3)
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
