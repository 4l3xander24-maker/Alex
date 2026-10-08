local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Progression = require(ReplicatedStorage:WaitForChild("Shared").Progression)

local EnemyRenderer = require(script.EnemyRenderer)
local Guide = require(script.Guide)
local Hud = require(script.Hud)
local LevelUpFx = require(script.LevelUpFx)
local VillageController = require(script.VillageController)
local PetRenderer = require(script.PetRenderer)
local MatchSummary = require(script.MatchSummary)
local MovementController = require(script.MovementController)
local Notify = require(script.Notify)
local PowerController = require(script.PowerController)
local Profile = require(script.Profile)
local Sfx = require(script.Sfx)
local ShopUI = require(script.ShopUI)
local Viewmodel = require(script.Viewmodel)
local WeaponController = require(script.WeaponController)
local WorldFx = require(script.WorldFx)

-- Sin mochila: las teclas 1-6 cambian de arma
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- El perfil primero, para no perder la primera actualización del servidor
Profile.init()
Notify.init()
EnemyRenderer.init()
Sfx.init()
WorldFx.init()
Viewmodel.init("Pistol", 1.3, Progression.weaponTier(0))
MovementController.init()
WeaponController.init(EnemyRenderer.folder, function()
	Hud.flashHitMarker()
	Sfx.play("HitMarker")
	Guide.onEnemyHit()
end)
PowerController.init()
ShopUI.init()
MatchSummary.init()
LevelUpFx.init()
VillageController.init()
PetRenderer.init()
Hud.init({
	setTrigger = WeaponController.setTrigger,
	setAiming = WeaponController.setAiming,
	reload = WeaponController.reload,
	cycleWeapon = WeaponController.cycle,
	usePower = PowerController.use,
	setSprint = MovementController.setSprint,
	dash = MovementController.dash,
	getAmmo = WeaponController.getAmmoState,
	getMeleeEnergy = WeaponController.getMeleeEnergy,
	ammoGranted = WeaponController.AmmoGranted,
	getEquipped = WeaponController.getEquipped,
	isAiming = WeaponController.isAiming,
	isScoped = Viewmodel.isScoped,
	getCooldown = PowerController.getCooldown,
	getDashCooldown = MovementController.getDashCooldown,
})

-- Al final: espera el mapa y el perfil sin frenar lo demás
task.spawn(Guide.init)
