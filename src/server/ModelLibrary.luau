-- Modelos 3D de la Creator Store (árboles y casas) guardados en src/models y
-- puestos por Rojo en ServerStorage.Models. Se copian al mapa escalados y
-- apoyados en el suelo. Se usan solo en los estilos no pixelados; si un modelo
-- falta, quien llama construye la versión de bloques.
-- Para agregar o cambiar modelos: ver tools/extract_models.luau y el README.
local ServerStorage = game:GetService("ServerStorage")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ModelLibrary = {}

local folder = ServerStorage:FindFirstChild("Models")
local enabled = Config.UseStoreModels and not Config.Style.Blocky

-- Lo que no hace falta en un adorno quieto (las uniones sobran si todo está anclado)
local REMOVE = { "LuaSourceContainer", "JointInstance", "WeldConstraint", "Camera", "Seat", "VehicleSeat" }

-- Medidas de cada modelo una sola vez (caja y punto de apoyo en el suelo)
local templates: { [string]: { Model: Model, Size: Vector3 } } = {}

local function prepare(name: string): { Model: Model, Size: Vector3 }?
	if templates[name] then
		return templates[name]
	end
	local source = folder and folder:FindFirstChild(name)
	if not source or not source:IsA("Model") then
		return nil
	end
	local model = source:Clone()
	for _, descendant in model:GetDescendants() do
		for _, className in REMOVE do
			if descendant:IsA(className) then
				descendant:Destroy()
				break
			end
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanTouch = false
		end
	end
	-- El pivote queda en el centro de la base: así se apoya justo en el suelo
	local boxCFrame, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(boxCFrame.Position - Vector3.new(0, size.Y / 2, 0))
	templates[name] = { Model = model, Size = size }
	return templates[name]
end

-- true si se pueden usar modelos de la tienda y existe `name`
function ModelLibrary.has(name: string): boolean
	return enabled and prepare(name) ~= nil
end

-- Copia `name` con la base en `cframe`. size: { Height = n } o { Footprint = n }
-- (el lado más largo del piso). solid = false: no choca ni frena las balas.
function ModelLibrary.place(name: string, cframe: CFrame, size: { Height: number?, Footprint: number? }, solid: boolean, parent: Instance): Model?
	if not enabled then
		return nil
	end
	local template = prepare(name)
	if not template then
		return nil
	end
	local model = template.Model:Clone()
	local scale = if size.Height
		then size.Height / template.Size.Y
		else (size.Footprint or 1) / math.max(template.Size.X, template.Size.Z)
	model:ScaleTo(scale)
	model:PivotTo(cframe)
	if not solid then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanQuery = false
			end
		end
	end
	model.Parent = parent
	return model
end

return ModelLibrary
