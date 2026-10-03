-- El servidor crea los remotes; los clientes los esperan.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	-- servidor -> clientes
	"EnemySpawned",
	"EnemyHit",
	"EnemyDied",
	"EnemiesCleared",
	"EnemyPathsUpdated",
	"PowerFx",
	"LevelUpOffer",
	-- cliente -> servidor
	"Shoot",
	"Reload",
	"UsePower",
	"ChooseUpgrade",
}
local FUNCTIONS = { "GetSnapshot" }

local Remotes = {}

if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
	for _, name in FUNCTIONS do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
	folder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in EVENTS do
		Remotes[name] = folder:WaitForChild(name)
	end
	for _, name in FUNCTIONS do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
