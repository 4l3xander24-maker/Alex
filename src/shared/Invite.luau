-- Invitar amigos (Lobby y Partida). La invitación lleva "ref:<UserId>" del
-- que invita en LaunchData: así el servidor sabe a quién premiar cuando el
-- amigo termine su primera partida (ReferralService). El cliente solo abre la
-- ventana de Roblox; el premio lo decide y valida el servidor.
local SocialService = game:GetService("SocialService")

local Invite = {}

local PREFIX = "ref:"

-- Texto de LaunchData para una invitación de este jugador
function Invite.launchData(userId: number): string
	return `{PREFIX}{userId}`
end

-- UserId del que invitó, o nil si el texto no es una invitación válida
function Invite.parse(text: any): number?
	if typeof(text) ~= "string" or #text > 32 then
		return nil
	end
	local id = tonumber(string.match(text, "^ref:(%d+)$"))
	if id and id > 0 and id < 2 ^ 53 and id == math.floor(id) then
		return id
	end
	return nil
end

-- Abre la ventana de invitar de Roblox. false si no se puede (Studio, edad,
-- restricciones de la cuenta): quien llama muestra un aviso.
function Invite.prompt(player: Player): boolean
	local ok, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if not ok or not canInvite then
		return false
	end
	local opened = pcall(function()
		local options = Instance.new("ExperienceInviteOptions")
		options.PromptMessage = "¡Ayúdame a defender la campana maldita!"
		options.LaunchData = Invite.launchData(player.UserId)
		SocialService:PromptGameInvite(player, options)
	end)
	return opened
end

return Invite
