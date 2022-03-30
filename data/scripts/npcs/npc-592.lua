local donutblock = {}

local npcManager = require("npcmanager")
local dblock = require("npcs/ai/donutblock")

local npcID = NPC_ID
npcManager.setNpcSettings({
	id = npcID,
	width = 32,
	height = 32,
	gfxwidth = 32,
	gfxheight = 32,
	frames = 1,
	playerblock = false,
	playerblocktop = true,
	ignorethrownnpcs = true,
	nogravity = true,
	nohurt = false,
	noblockcollision = true,
	npcblock = false,
	npcblocktop = true,
	noiceball = true,
	noyoshi = true,
	notcointransformable = true,

	time = 30,
	maxspeed = 4.5,
	cooldown = 5
})

dblock.register(npcID)

return donutblock