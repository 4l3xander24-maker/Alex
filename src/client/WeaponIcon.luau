-- Ícono 3D de un arma: el modelo de malla visto de costado dentro de un
-- ViewportFrame, con la culata a la izquierda y el cañón a la derecha.
local WeaponIcon = {}

-- Todos los modelos tienen el largo en Z y el perfil (alto del arma) en Y del
-- mundo: se miran desde el costado (+X)
local VIEW_FROM = Vector3.new(1, 0, 0)
local VIEW_UP = Vector3.new(0, 1, 0)
-- Excepciones: la hoja del alfanje es plana en X-Z, se mira desde arriba
local VIEWS: { [string]: { From: Vector3, Up: Vector3 } } = {
	Machete = { From = Vector3.new(0, 1, 0), Up = Vector3.new(1, 0, 0) },
}
local FOV = 30
local MARGIN = 1.2 -- deja un poco de aire alrededor

function WeaponIcon.build(parent: GuiObject, source: Model, weaponId: string): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(170, 160, 150)
	viewport.LightColor = Color3.fromRGB(255, 244, 228)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	viewport.ZIndex = 2
	viewport.Parent = parent

	local model = source:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	model.Parent = viewport

	local center, size = model:GetBoundingBox()
	-- El largo del arma va a lo ancho del ícono (las casillas son más anchas que altas)
	local length = math.max(size.X, size.Y, size.Z)
	local aspect = 72 / 44
	local distance = (length / 2) / math.tan(math.rad(FOV / 2)) / aspect * MARGIN
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	local view = VIEWS[weaponId]
	local from = if view then view.From else VIEW_FROM
	camera.CFrame = CFrame.lookAt(center.Position + from * distance, center.Position, if view then view.Up else VIEW_UP)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end

return WeaponIcon
