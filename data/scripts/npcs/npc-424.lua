local megaSpike =  {}

local npcManager = require("npcManager")
local skewers = require("npcs/ai/skewer")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 128, 
	width = 32, 
	height = 128, 
	nogravity = 1, 
	frames = 1,
	playerblock = true, 
	playerblocktop = true, 
	npcblock = true,
	npcblocktop = true,
	speed = 0,
	jumphurt = 0,
	nohurt = 1,
	score = 0,
	noiceball=-1,
	noyoshi=1,
	noblockcollision=1,
	notcointransformable = true,
	hitboxoffset=18,
	hitsblocks=true,
	horizontal = true,
	waitDelay = 120,
	extendedDelay = 120,
	extendSpeed = 16,
	retractSpeed = 4,
})

skewers.register(npcID)

return megaSpike