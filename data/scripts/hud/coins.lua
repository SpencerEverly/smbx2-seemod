local coins = {}

local _hud = require("HUDOverride2")

local container = {}

local coinIcon = {
	x = 88,
	y = 26,
	splitOffset = 2,
	defaultImage = Graphics.sprites.hardcoded["33-2"]
}
coinIcon.icons = {}

function coins.setCoinIcon(characterID, icon)
	coinIcon.icons[characterID] = icon
end

coins.setCoinIcon(5, Graphics.sprites.hardcoded["33-6"])


function coinIcon:drawHUD(thisPlayer, thisCam, priority, isSplit)
	coinIcon.image = coinIcon.icons[_hud.activePlayers[camIndex]] or coinIcon.defaultImage
	Graphics.HUD.draw(coinIcon, thisPlayer, thisCam, priority, isSplit)
end

local value = {
	x = 168,
	y = 27,
	splitOffset = 2,
	bindX = _hud.BIND.RIGHT,
	fontType = 1
}

function value:drawHUD(thisPlayer, thisCam, priority, isSplit)
	value.text = mem(0x00B2C5A8, FIELD_WORD)
	Graphics.HUD.draw(value, thisPlayer, thisCam, priority, isSplit)
end

function coins.onInitAPI()
	Graphics.HUD:register("coins", container)
	container:register("icon", coinIcon)
	local cross = container:register("cross", "_cross.json")
	cross.x = 112
	cross.y = 27
	cross.splitOffset = 2
	container:register("value", value)
end

return coins