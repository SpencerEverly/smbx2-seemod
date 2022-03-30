--by Nat The Porcupine--
local npcManager = require("npcManager");
local fireSnakeAI = require("npcs/ai/firesnake");
local fireSnakeAPI = {};

local npcID = NPC_ID

local config = {
	id = npcID,
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32,
	height = 32,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	jumphurt=1,
	nofireball=-1,
	noiceball=0,
	noyoshi=-1,
	nogravity=1,
	nowaterphysics=true,
	spinjumpsafe=true,
	lightradius=64,
	lightcolor=Color.orange,
	lightbrightness=1,
	tailid = 308,
	ishot = true,
	durability = -1
}
npcManager.registerHarmTypes(npcID, {HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_FROMBELOW]=236,
[HARM_TYPE_NPC]=236,
[HARM_TYPE_HELD]=236,
[HARM_TYPE_TAIL]=236,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

fireSnakeAI.registerHead(config)

return fireSnakeAPI;