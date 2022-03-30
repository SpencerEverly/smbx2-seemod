local npcManager = require("npcManager")
local grrrolAI = require("npcs/ai/grrrol")

local grrrol = {}

    -----------------------------------------
   -----------------------------------------
  ------- Initialize NPC settings ---------
 -----------------------------------------
-----------------------------------------

local npcID = NPC_ID

local settings = {
	id = npcID,
	gfxheight = 80,
	gfxwidth = 80,
	gfxoffsetx = 0,
	gfxoffsety = 4,
	width = 64, 
	height = 64,
	eyeOffsetX = 8,
	eyeOffsetY = 11,
	isheavy = 2,
	grrrolstrength = 2
}

local harmtypes = {
	[HARM_TYPE_NPC]     = 256,
	[HARM_TYPE_LAVA]     = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmtypes), harmtypes)

grrrolAI.register(settings)

return grrrol