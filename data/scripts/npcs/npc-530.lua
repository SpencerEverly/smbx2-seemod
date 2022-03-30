local npcManager = require("npcManager")

local porcupo = {}

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	width = 32, 
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = true,
	nofireball = true,
	noiceball = false,
	noyoshi = false,
	nohurt = false,
	jumphurt = true,
	spinjumpsafe = true,
	iswalker = true
})

local harmTypes = {
	[HARM_TYPE_PROJECTILE_USED] = 227,
	[HARM_TYPE_NPC]      = 227,
	[HARM_TYPE_HELD]     = 227,
	[HARM_TYPE_TAIL]     = 227,
	[HARM_TYPE_SWORD]    = 10,
	[HARM_TYPE_FROMBELOW]= 227,
	[HARM_TYPE_LAVA]     = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)

return porcupo