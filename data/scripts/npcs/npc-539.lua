local npcManager = require("npcManager")
local flipAI = require("npcs/ai/fliprus")

local fliprus = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 80,
	gfxwidth = 80,
	gfxoffsety=28,
	width = 32,
	height = 32,
	frames = 10,
	framestyle = 1,
	framespeed = 8,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	spinjumpsafe=-1,
	idleFrames=4,
	attackFrames=2,
	flipFrames=4,
	spawnid = 540,
	throwspeedx = 3,
	throwspeedy = -5
})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=229,
[HARM_TYPE_FROMBELOW]=228,
[HARM_TYPE_NPC]=228,
[HARM_TYPE_HELD]=228,
[HARM_TYPE_PROJECTILE_USED]=228,
[HARM_TYPE_TAIL]=228,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

flipAI.register(npcID)
	
return fliprus