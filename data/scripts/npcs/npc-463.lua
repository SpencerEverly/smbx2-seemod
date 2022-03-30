local npcManager = require("npcManager")
local clouddrop = require("npcs/ai/clouddrop")
local cDrop = {}

local npcID = NPC_ID

local hSettings = {
	id = npcID,
	gfxwidth = 48,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 7,
	framespeed=8,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 1,
	noblockcollision=1,
	horizontal = true,
	range = 128
}

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD,}, 
{[HARM_TYPE_JUMP]=131,
[HARM_TYPE_NPC]=131,
[HARM_TYPE_PROJECTILE_USED]=131,
[HARM_TYPE_HELD]=131,
[HARM_TYPE_TAIL]=131,});

npcManager.setNpcSettings(hSettings)
clouddrop.register(npcID)
return cDrop