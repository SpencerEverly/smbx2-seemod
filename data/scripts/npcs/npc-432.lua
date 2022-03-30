local thwomps = {}

local npcManager = require("npcManager")
local thwompAI = require("npcs/ai/thwomps")

local npcID = NPC_ID

local settings = {
	id = npcID, width = 128, height = 172, gfxwidth = 128, gfxheight = 172, earthquake = 6, smash = 1, staticdirection = true, harmTypes = {
		[HARM_TYPE_HELD] = 205,
		[HARM_TYPE_PROJECTILE_USED] = 205,
		[HARM_TYPE_NPC] = 205, --Nitro blocks trigger this...
		--[HARM_TYPE_FROMBELOW] = 10, --Enable when smashBlocks uses v:hit(true) I guess
		[HARM_TYPE_LAVA] = 10 --Can't guarantee it's lava that's BELOW the thwomp anymore so poof of dust
	}
}

thwompAI.registerThwomp(settings)

return thwomps