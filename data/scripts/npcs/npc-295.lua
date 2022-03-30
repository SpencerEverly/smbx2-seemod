local thwomps = {}

local npcManager = require("npcManager")
local thwompAI = require("npcs/ai/thwomps")

local npcID = NPC_ID

local settings = {
	id = npcID, horizontal = true, harmTypes = {
		[HARM_TYPE_HELD] = 162,
		[HARM_TYPE_PROJECTILE_USED] = 162,
		[HARM_TYPE_NPC] = 162, --Nitro blocks trigger this...
		--[HARM_TYPE_FROMBELOW] = 10, --Enable when smashBlocks uses v:hit(true) I guess
		[HARM_TYPE_LAVA] = 10 --Can't guarantee it's lava that's BELOW the thwomp anymore so poof of dust
	}
}

thwompAI.registerThwomp(settings)

return thwomps
