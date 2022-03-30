local npcManager = require("npcmanager");
local scuttleAI = require("npcs/ai/scuttlebug");

local scuttlebug = {};

local npcID = NPC_ID

npcManager.registerHarmTypes(
	npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_JUMP] = 224,
		[HARM_TYPE_FROMBELOW] = 224,
		[HARM_TYPE_NPC] = 224,
		[HARM_TYPE_PROJECTILE_USED] = 224,
		[HARM_TYPE_HELD] = 224,
		[HARM_TYPE_TAIL] = 224,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings{
	id = npcID,
	gfxwidth = 86,
	gfxheight = 72,
	width = 64,
	height = 64,
	frames = 1,
	framestyle = 0,
	nogravity = true,
	noblockcollision = true,
	nonpccollision = true,
	
	dropspeed = 6, -- how fast it drops down with its string
	hangspeed = 1.5, -- max. speed while vertically oscillating 
	hangheight = 100, -- change in height while vertically oscillating
	stringpriority = -67, -- priority when the string is manually drawn
	hangtime = -1, -- -1=forever, 0=after dropped (no oscillating), other=number of ticks of oscillating before transforming into walking scuttlebug
	stringretractspeed = 8, -- how fast an abandonned string retracts
	spawnid = 510,
	stringcolor = Color.white..0.9
};
scuttleAI.register(npcID)

return scuttlebug