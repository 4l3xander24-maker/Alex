local StarterGui = game:GetService("StarterGui")

local EnemyRenderer = require(script.EnemyRenderer)
local Hud = require(script.Hud)
local MatchSummary = require(script.MatchSummary)
local MovementController = require(script.MovementController)
local Notify = require(script.Notify)
local PowerController = require(script.PowerController)
local Profile = require(script.Profile)
local ShopUI = require(script.ShopUI)
local Viewmodel = require(script.Viewmodel)
local WeaponController = require(script.WeaponController)

-- Sin mochila: las teclas 1-5 cambian de arma
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- El perfil primero, para no perder la primera actualización del servidor
Profile.init()
Notify.init()
EnemyRenderer.init()
Viewmodel.init("Pistol", 1.3)
MovementController.init()
WeaponController.init(EnemyRenderer.folder, Hud.flashHitMarker)
PowerController.init()
ShopUI.init()
MatchSummary.init()
Hud.init({
	setTrigger = WeaponController.setTrigger,
	setAiming = WeaponController.setAiming,
	reload = WeaponController.reload,
	cycleWeapon = WeaponController.cycle,
	usePower = PowerController.use,
	setSprint = MovementController.setSprint,
	dash = MovementController.dash,
	getAmmo = WeaponController.getAmmoState,
	getEquipped = WeaponController.getEquipped,
	isAiming = WeaponController.isAiming,
	isScoped = Viewmodel.isScoped,
	getCooldown = PowerController.getCooldown,
	getDashCooldown = MovementController.getDashCooldown,
})
