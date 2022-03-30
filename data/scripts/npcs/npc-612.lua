local spiny = {}
local npcManager = require("npcManager")

local npcID = NPC_ID
npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	framestyle = 1,
	frames = 2,
	framespeed = 8,
	jumphurt = true,
	iswalker = true,
	spinjumpsafe = true
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA},
	{[HARM_TYPE_FROMBELOW] = 247,
	[HARM_TYPE_NPC] = 247,
	[HARM_TYPE_HELD] = 247,
	[HARM_TYPE_TAIL] = 247,
	[HARM_TYPE_PROJECTILE_USED] = 247,
	[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
})

return spiny