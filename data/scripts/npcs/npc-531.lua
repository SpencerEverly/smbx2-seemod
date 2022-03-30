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
	gfxheight = 64,
	gfxwidth = 64,
	gfxoffsetx = 0,
	gfxoffsety = 4,
	width = 48, 
	height = 50,
	eyeOffsetX = 6,
	eyeOffsetY = 5,
	grrrolstrength = 0
}

local harmtypes = {
	[HARM_TYPE_NPC]     = 255,
	[HARM_TYPE_LAVA]     = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmtypes), harmtypes)

grrrolAI.register(settings)

return grrrol