local megaSpike =  {}

local npcManager = require("npcManager")
local skewers = require("npcs/ai/skewer")

local npcID = NPC_ID

--Initalise configs
npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 128, 
	gfxheight = 32, 
	width = 128, 
	height = 32, 
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
	staticdirection = true,
	hitboxoffset=18,
	hitsblocks=true,
	horizontal = false,
	waitdelay = 120,
	extendeddelay = 120,
	extendspeed = 16,
	retractspeed = 4,
})

skewers.register(npcID)

return megaSpike