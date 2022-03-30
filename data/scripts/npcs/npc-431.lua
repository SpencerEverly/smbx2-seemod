local npcManager = require("npcManager")

local chargedSpiny = {}

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32, 
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = 1,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	nohurt = 0,
	jumphurt = 1,
	spinjumpsafe = 0,
	iswalker = 1,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white
})

local harmTypes = {
	[HARM_TYPE_NPC]      = 203,
	[HARM_TYPE_PROJECTILE_USED] = 203,
	[HARM_TYPE_HELD]     = 203,
	[HARM_TYPE_TAIL]     = 203,
	[HARM_TYPE_SWORD]    = 63,
	[HARM_TYPE_FROMBELOW]= 203,
	[HARM_TYPE_LAVA]     = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)

return chargedSpiny