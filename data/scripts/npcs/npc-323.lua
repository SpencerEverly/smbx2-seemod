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
	gfxoffsety=2,
	frames = 5,
	framespeed=8,
	framestyle = 1,
	jumphurt = 1,
	nogravity = -1,
	noblockcollision = -1,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	stretchframes = 3,
	cliffturn=-1,
}

stretch.register(npcID, stretch.TYPE.FLOOR)

return stretcher