--by Nat The Porcupine--
local npcManager = require("npcManager");
local filth = require("npcs/ai/filthcoating");
local filthc = {};

local npcID = NPC_ID

npcManager.setNpcSettings{
	id = filth.id,
	width = 16,
	height = 16,
	gfxwidth = 22,
	gfxheight = 22,
	jumphurt = true,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	noyoshi = true,
}

filth.register(npcID, "p_leaf.ini", "leaf")

return filthc;