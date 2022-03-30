local npcManager = require("npcManager")

local ptooie = {}

local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC
	}, {
		[HARM_TYPE_PROJECTILE_USED]=235,
		[HARM_TYPE_TAIL]=235,
		[HARM_TYPE_NPC]=235,
		[HARM_TYPE_HELD]=235
	}
);

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 28,
	gfxwidth = 28,
	width = 28,
	height = 28,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 1,
	ignorethrownnpcs = true,
	nofireball=1,
	noiceball=-1,
	noyoshi=0,
	maxspeed = 4,
	spinjumpsafe = true
})

return ptooie