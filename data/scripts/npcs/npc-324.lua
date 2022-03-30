local npcManager = require("npcManager")
local stretch = require("npcs/ai/stretch")

local stretcher = {}

local npcID = NPC_ID

stretcher.config = npcManager.setNpcSettings{
	id = npcID,
	gfxheight = 32,
	gfxwidth = 36,
	width = 30,
	height = 32,
	frames = 5,
	gfxoffsety=-2,
	framespeed=8,
	framestyle = 1,
	jumphurt = 1,
	noblockcollision = -1,
	nofireball=-1,
	nogravity=-1,
	noiceball=-1,
	noyoshi=-1, 
	stretchframes = 3,
	cliffturn=-1
}

stretch.register(npcID, stretch.TYPE.CEILING)

return stretcher