local npcManager = require("npcManager")
local cobratAI = require("npcs/ai/cobrats")

local cobrats = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 64, 
	gfxwidth = 32, 
	width = 32, 
	height = 64,
	frames = 3,
	framestyle = 2,
	framespeed = 8,
	jumphurt = 0, 
	nofireball = 1,
	noiceball = 0,
	noblockcollision=1,
	noyoshi = 0,
	grabtop = 1,
	playerblocktop = 1,
	npcblocktop = 1,
	iswalker = false,
	speed = 1,
	hideoffset = -4,
	spawnid = 133,
	transformid = 372,
	transformonjump = true
})

local harmTypes = {
	[HARM_TYPE_SWORD] = 10, 
	[HARM_TYPE_PROJECTILE_USED] = 260, 
	[HARM_TYPE_SPINJUMP] = 10, 
	[HARM_TYPE_TAIL] = 260, 
	[HARM_TYPE_JUMP] = 260, 
	[HARM_TYPE_FROMBELOW] = 260, 
	[HARM_TYPE_HELD] = 260, 
	[HARM_TYPE_NPC] = 260, 
	[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)

cobratAI.registerHiding(npcID)

return cobrats