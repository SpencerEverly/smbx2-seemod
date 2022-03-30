local npcManager = require("npcManager")
local ptooieAI = require("npcs/ai/ptooies")

local ptooie = {}

-- IDs
local npcID = NPC_ID

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
			[HARM_TYPE_PROJECTILE_USED]=234,
			[HARM_TYPE_TAIL]=234,
			[HARM_TYPE_FROMBELOW]=234,
			[HARM_TYPE_HELD]=234,
			[HARM_TYPE_NPC]=234,
			[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
		}
	);

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 52,
	gfxwidth = 32,
	width = 28,
	height = 52,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=0,
	noiceball=0,
	noyoshi=0,
	ptooiespeed=1.2,
	spinjumpsafe = true,
	walktimer = 5,
	ballid = 376,
	blowheight1 = 48,
	blowheight2 = 192
})

ptooieAI.register(npcID)

return ptooie