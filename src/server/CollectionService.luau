-- Colección del bestiario (Config.Collection): cuenta las bajas de cada tipo de
-- enemigo en el perfil y paga, una sola vez y solo desde el servidor, el premio
-- de cada nivel de maestría y el de completar un nivel con todos los enemigos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local CollectionService = {}

-- Premio del nivel `tier` para todos los enemigos: solo si ya cobró ese nivel en cada uno
local function checkSet(player: Player, data: Progression.Profile, tier: number)
	local collection = Config.Collection
	local setKey = `Set:{tier}`
	if data.BestiaryClaimed[setKey] then
		return false
	end
	for _, typeName in Progression.collectionEnemies() do
		if not data.BestiaryClaimed[`{typeName}:{tier}`] then
			return false
		end
	end
	data.BestiaryClaimed[setKey] = true
	local info = collection.Tiers[tier]
	local reward = collection.SetRewards[tier]
	DataService.addCoins(player, reward)
	local extra = ""
	if tier == #collection.Tiers then
		data.Titles.Bestiary = true
		-- No pisa el título del Salón de la fama si ya lleva uno
		if data.Title == "" then
			data.Title = collection.SetTitle
			extra = ` · título «{collection.SetTitle}»`
		else
			extra = ` · título «{collection.SetTitle}» desbloqueado`
		end
	end
	Remotes.Notify:FireClient(player, `📖 ¡Bestiario completo en {info.Icon} {info.Name}! +{reward} monedas{extra}`)
	return true
end

-- Se llama en cada baja (el servidor decide quién mató y a qué tipo)
function CollectionService.onKill(player: Player, typeName: string)
	local data = DataService.get(player)
	local info = Config.Enemies[typeName]
	if not data or not info then
		return
	end
	local kills = (data.BestiaryKills[typeName] or 0) + 1
	data.BestiaryKills[typeName] = kills
	local dirty = kills == 1 -- recién descubierto: el bestiario deja de mostrar la silueta
	local goals, rewards = Progression.collectionGoals(typeName)
	local setDone = false
	for tier, goal in goals do
		local key = `{typeName}:{tier}`
		if kills >= goal and not data.BestiaryClaimed[key] then
			data.BestiaryClaimed[key] = true
			dirty = true
			DataService.addCoins(player, rewards[tier])
			local tierInfo = Config.Collection.Tiers[tier]
			Remotes.Notify:FireClient(player, `📖 {info.DisplayName}: maestría {tierInfo.Icon} {tierInfo.Name} · +{rewards[tier]} monedas`)
			if checkSet(player, data, tier) then
				setDone = true
			end
		end
	end
	if dirty then
		DataService.changed(player, "Profile")
	end
	if setDone then
		DataService.saveNow(player)
	end
end

return CollectionService
