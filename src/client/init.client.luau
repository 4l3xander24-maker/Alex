local StarterGui = game:GetService("StarterGui")

local EnemyRenderer = require(script.EnemyRenderer)
local Hud = require(script.Hud)
local PowerController = require(script.PowerController)
local UpgradeMenu = require(script.UpgradeMenu)
local Viewmodel = require(script.Viewmodel)
local WeaponController = require(script.WeaponController)

-- Sin mochila: las teclas 1, 2 y 3 son para elegir mejoras
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

EnemyRenderer.init()
Viewmodel.init()
WeaponController.init(EnemyRenderer.folder, Hud.flashHitMarker)
PowerController.init()
UpgradeMenu.init()
Hud.init({
	setTrigger = WeaponController.setTrigger,
	reload = WeaponController.reload,
	usePower = PowerController.use,
	getAmmo = WeaponController.getAmmoState,
	getPowerLevel = PowerController.getLevel,
	getCooldown = PowerController.getCooldown,
})
