-- Ids de imagen ya listos que publica el servidor (AssetService), para el
-- cliente: sprites de los zombis y de los NPC. "" si no se subieron.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResolvedAssets = {}

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild("ResolvedAssets")
end

function ResolvedAssets.get(key: string): string
	local assets = folder()
	local value = assets and assets:GetAttribute(key)
	return if type(value) == "string" then value else ""
end

-- Dos cuadros de caminar de un enemigo (o nil si no hay sprite)
function ResolvedAssets.getSprite(typeName: string): { string }?
	local first = ResolvedAssets.get(`Sprite.{typeName}.1`)
	if first == "" then
		return nil
	end
	local second = ResolvedAssets.get(`Sprite.{typeName}.2`)
	return { first, if second ~= "" then second else first }
end

-- Avisa cuando el servidor termina de publicar
function ResolvedAssets.onReady(callback: () -> ())
	task.spawn(function()
		local assets = ReplicatedStorage:WaitForChild("ResolvedAssets", 30)
		if not assets then
			return
		end
		if not assets:GetAttribute("Ready") then
			assets:GetAttributeChangedSignal("Ready"):Wait()
		end
		callback()
	end)
end

return ResolvedAssets
