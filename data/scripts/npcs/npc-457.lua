local npcManager = require("npcManager")
local springLib = require("npcs/ai/springs")

local springs = {}

local npcID = NPC_ID

local regularSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 32,
	gfxwidth = 32,
	width = 30,
	height = 16,
	frames = 1,
	framestyle = 0,
	nohurt=true,
	playerblock=false,
	jumphurt = true,
	nogravity = false,
	nofireball= true,
	npcblock = false,
	playerblocktop = false,
	ignorethrownnpcs = true,
	npcblocktop = false,
	grabside = true,
	noblockcollision=false,
	grabtop = false,
	noiceball= true,
	noyoshi= false,
	harmlessgrab = true,
	harmlessthrown=true,
	force = 15
}

npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA}, {[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}})

npcManager.setNpcSettings(regularSettings)
springLib.register(npcID, springLib.TYPE.UP)

return springs