local graf = {}

local grafAI = require("npcs/ai/graf")
local npcManager = require("npcManager")
local npcID = NPC_ID

local settings = {
	id = npcID
}

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=221,
[HARM_TYPE_NPC]=221,
[HARM_TYPE_PROJECTILE_USED]=221,
[HARM_TYPE_HELD]=221,
[HARM_TYPE_TAIL]=221,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

grafAI.register(settings)

return graf