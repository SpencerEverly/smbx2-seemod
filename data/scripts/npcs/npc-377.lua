local npcManager = require("npcManager")
local ptooieAI = require("npcs/ai/ptooies")

local ptooie = {}

-- IDs
local npcID = NPC_ID

-- NPC properties

npcManager.registerHarmTypes(npcID,
		{
			HARM_TYPE_SWORD,
			HARM_TYPE_PROJECTILE_USED,
			HARM_TYPE_TAIL,
			HARM_TYPE_FROMBELOW,
			HARM_TYPE_HELD,
			HARM_TYPE_NPC,
			HARM_TYPE_LAVA
		}, {
			[HARM_TYPE_SWORD]=10,
			[HARM_TYPE_PROJECTILE_USED]=10,
			[HARM_TYPE_TAIL]=10,
			[HARM_TYPE_FROMBELOW]=10,
			[HARM_TYPE_HELD]=10,
			[HARM_TYPE_NPC]=10,
			[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
		}
	);

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 64,
	gfxwidth = 32,
	width = 32,
	height = 64,
	frames = 1,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	speed = 0,
	noblockcollision = 0,
	nofireball=0,
	noiceball=0,
	noyoshi=0, 
	ptooiespeed=0,
	spinjumpsafe = true,
	ballid = 376,
	blowheight1 = 48,
	blowheight2 = 192
})

ptooieAI.register(npcID)


return ptooie