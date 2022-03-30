local npcManager = require("npcManager")
local parabeetle = require("npcs/ai/parabeetle")

local beetleNPC = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 64,
	gfxheight = 46,
	width = 50,
	height = 34,
	gfxoffsety=6,
	frames = 2,
	framestyle = 1,
	grabtop = 0,
	speed = 0.8,
	jumphurt = 1,
	nogravity = 1,
	playerblocktop = -1, --player AND npc can stand on top
	noblockcollision = -1,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	spinjumpsafe = false,
	--lua only
	ridespeed = 0.65,
	returnspeed = -0.35,
	returnspeeddelta = 0.015,
	returndelay = 30,

	ridespeedstart = 0,
	ridespeeddelta = 0,
	ridespeedend = 0,
})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_LAVA}, 
	{[HARM_TYPE_NPC]=168,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}}
)

function beetleNPC.onInitAPI()
	parabeetle.register(npcID)
end

return beetleNPC