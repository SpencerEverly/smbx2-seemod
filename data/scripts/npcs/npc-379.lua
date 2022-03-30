local npcManager = require("npcManager")
local shoegoombaAI = require("npcs/ai/shoegoomba")

local shoegoomba = {}

local npcID = NPC_ID

local settings = {
	id = npcID,
}

shoegoombaAI.register(settings)

npcManager.registerHarmTypes(npcID, 
	{
		HARM_TYPE_SWORD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_TAIL,
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_SWORD]=191,
		[HARM_TYPE_PROJECTILE_USED]=4,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_TAIL]=4,
		[HARM_TYPE_JUMP]=191,
		[HARM_TYPE_FROMBELOW]=4,
		[HARM_TYPE_HELD]=4,
		[HARM_TYPE_NPC]=4,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

return shoegoomba