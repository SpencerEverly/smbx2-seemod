local npcManager = require("npcManager")
local beetleAI = require("npcs/ai/busterbeetle")

local beetle =  {}

local npcID = NPC_ID

local busterSettings = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	cliffturn=true,
	target1=45,
	range = 2,
	collideryoffset = -2,
	useai1 = false,
	throwspeedx = 7,
	throwspeedy = -5,
})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]={id=241, speedX=0, speedY=0},
[HARM_TYPE_FROMBELOW]=241,
[HARM_TYPE_NPC]=241,
[HARM_TYPE_HELD]=241,
[HARM_TYPE_TAIL]=241,
[HARM_TYPE_PROJECTILE_USED]=241,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

beetleAI.register(npcID)

return beetle