local bombs = {}

local _hud = require("HUDOverride2")

local container = {
	bindX = _hud.BIND.MID
}

local bombIcon = {
	x = 0,
	y = 52,
	splitOffset = 0,
	defaultImage = Graphics.sprites.hardcoded["33-2"]
}
bombIcon.icons = {}

function bombs.setCoinIcon(characterID, icon)
	bombIcon.icons[characterID] = icon
end

bombs.setCoinIcon(5, Graphics.sprites.hardcoded["33-6"])


function bombIcon:drawHUD(thisPlayer, thisCam, priority, isSplit)
	bombIcon.image = bombIcon.icons[_hud.activePlayers[camIndex]] or bombIcon.defaultImage
	Graphics.HUD.draw(bombIcon, thisPlayer, thisCam, priority, isSplit)
end

local value = {
	x = 45,
	y = 1,
	splitOffset = 0,
	bindX = _hud.BIND.LEFT,
	fontType = 1
}

function value:drawHUD(thisPlayer, thisCam, priority, isSplit)
	value.text = mem(0x00B2C5A8, FIELD_WORD)
	Graphics.HUD.draw(value, thisPlayer, thisCam, priority, isSplit)
end

function bombs.onInitAPI()
	Graphics.HUD:register("bombs", container)
	container:register("icon", bombIcon)
	local cross = container:register("cross", "_cross.json")
	cross.x = 24
	cross.y = 1
	cross.splitOffset = 0
	container:register("value", value)
end

return bombs