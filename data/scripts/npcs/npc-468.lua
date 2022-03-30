local clearpipe_npc = {}

local npcManager = require("npcmanager")
local cnpc = require("npcs/ai/clearpipeNPC")

local npcID = NPC_ID
npcManager.setNpcSettings{
	id = npcID,
	
	nogravity = true,
	frames = 1,
	framestyle = 0,
	noblockcollision = true,
	speed = 1,
	jumphurt = true,
	nohurt = true,
	noiceball = true,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nowaterphysics = true,
	cannontime = 32
}

cnpc.register(npcID) -- I have the last word

return clearpipe_npc