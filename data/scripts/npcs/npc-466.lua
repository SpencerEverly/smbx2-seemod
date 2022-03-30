local npcManager = require("npcManager")
local splitter = require("npcs/ai/splitter")
local bigGoomba = {}

local npcID = NPC_ID

local bigGoombaSettings = {
	id = npcID, 
	gfxheight = 64, 
	gfxwidth = 64, 
	width = 64, 
	height = 64,
	gfxoffsety=2,
	frames = 2, 
	framestyle = 0,
	framespeed = 16,
	jumphurt = 0, 
	nogravity = 0, 
	noblockcollision = 0,
	nofireball = 0,
	noiceball = 1,
	noyoshi = 1, 
	speed = 0.6,
	iswalker = true,
	health=5,
	splits=2,
	splitid=89,
	isheavy = 2
}

local harmTypes = {
	[HARM_TYPE_SWORD]=216, 
	[HARM_TYPE_PROJECTILE_USED]=10, 
	[HARM_TYPE_SPINJUMP]=10, 
	[HARM_TYPE_TAIL]=216, 
	[HARM_TYPE_JUMP]=10, 
	[HARM_TYPE_FROMBELOW]=10, 
	[HARM_TYPE_HELD]=10, 
	[HARM_TYPE_NPC]=10, 
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)

npcManager.setNpcSettings(bigGoombaSettings)

splitter.register(npcID, splitter.SFX_die_giant)

return bigGoomba