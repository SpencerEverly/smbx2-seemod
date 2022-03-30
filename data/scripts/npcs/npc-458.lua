local npcManager = require("npcManager")
local springLib = require("npcs/ai/springs")

local springs = {}

local npcID = NPC_ID

local sideSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 16,
	height = 30,
	frames = 1,
	framestyle = 0,
	nohurt=-1,
	playerblock=false,
	jumphurt = true,
	nogravity = false,
	nofireball= true,
	npcblock = false,
	playerblocktop = true,
	ignorethrownnpcs = true,
	npcblocktop = true,
	grabside = false,
	grabtop = false,
	noiceball= true,
	noyoshi= true,
	harmlessgrab = true,
	harmlessthrown=true,
	force = 4
}

npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA}, 
{[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

npcManager.setNpcSettings(sideSettings)
springLib.register(npcID, springLib.TYPE.SIDE)

return springs