local npcManager = require("npcManager")

local spike = {}

local npcID = NPC_ID

local spikeBallSettings = {
	id = npcID,
	gfxheight = 28,
	gfxwidth = 28,
	width = 28,
	height = 28,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 1,
	ignorethrownnpcs = true,
	noblockcollision = 1,
	nofireball=1,
	noiceball=-1,
	noyoshi=0,
	speed = 2,
	iswalker=true,
	spinjumpsafe = true
}

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_SWORD,
		HARM_TYPE_TAIL,
		HARM_TYPE_NPC
	}, {
		[HARM_TYPE_TAIL]=182,
		[HARM_TYPE_NPC]=182,
		[HARM_TYPE_SWORD]=182,
		[HARM_TYPE_PROJECTILE_USED]=182,
		[HARM_TYPE_HELD]=182
	}
);

local ballConfig = npcManager.setNpcSettings(spikeBallSettings)

return spike