local npcManager = require("npcManager")
local panserAI = require("npcs/ai/pansers")

local panser = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight=32,
	gfxwidth=32,
	width=28,
	height=28,
	frames=3,
	framestyle=0,
	jumphurt=true,
	spinjumpsafe=true,
	noblockcollision=false,
	nofireball=true,
	speedx=0,
	shotspeedx=0,
	shotspeedy=9,
	turntime=2,
	reloadtime=65,
	firetime=15,
    shots=2,
    projectileid = 348
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_FROMBELOW]=177,
		[HARM_TYPE_NPC]=177,
		[HARM_TYPE_HELD]=177,
		[HARM_TYPE_TAIL]=177,
		[HARM_TYPE_PROJECTILE_USED]=177,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

panserAI.register(npcID)
return panser