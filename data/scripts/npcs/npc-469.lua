local npcManager = require("npcManager");

local boocircle = {}
local npcID = NPC_ID
npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	score = 0,
	playerblock = false,
	npcblock = false,
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	grabside = false,
	isshoe = false,
	isyoshi = false,
	iscoin = false,
	nohurt = false,
	jumphurt = true,
	spinjumpsafe = false,
	bootypes = 3}
);
return boocircle;