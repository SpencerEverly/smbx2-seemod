local npcManager = require("npcManager")

local bowserStatueFireball = {}
local npcID = NPC_ID;

-- fireball

local bowserStatueFireballSettings = {
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 16, 
	width = 32, 
	height = 4, 
	frames = 4,
	framespeed = 3, 
	framestyle = 1,
	jumphurt = 1,
	nogravity = 1,
	noblockcollision = 1,
	harmlessgrab = true,
	ignorethrownnpcs = true,
	linkshieldable = true,
	score = 0,
	noyoshi = true,
	spinjumpsafe = true,
	-- Darkness effect stuff
	lightoffsetx = 8,
	lightradius = 64,
	lightbrightness = 1,
	lightcolor = Color.orange,
	ishot = true,
	durability = 2
}

local configFile = npcManager.setNpcSettings(bowserStatueFireballSettings);

return bowserStatueFireball;