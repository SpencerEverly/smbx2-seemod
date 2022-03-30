local npcManager = require("npcManager")
local parabeetle = require("npcs/ai/parabeetle")

local beetleNPC = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 26,
	width = 32,
	height = 26,

	frames = 2,
	framestyle = 1,
	grabtop = 0,
	speed = 1,
	jumphurt = 1,
	nogravity = 1,
	playerblocktop = -1, --player AND npc can stand on top
	noblockcollision = -1,
	nofireball = 1,
	noiceball = -1,
	noyoshi = 1,
	spinjumpsafe = false,
	--lua only
	ridespeedstart = 2,
	ridespeeddelta = 0.08,
	ridespeedend = -1.6,
	returnspeeddelta = 0.2,
	
	returnspeed = 0,
    returndelay = 0,
    ridespeed = 0
})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_LAVA}, 
	{[HARM_TYPE_NPC]=169,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}}
);

function beetleNPC.onInitAPI()
	parabeetle.register(npcID)
end

return beetleNPC