local npcManager = require("npcManager");
local circle = require("npcs/ai/boocircles");

local boocircle = {};
local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, {}, {});

npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 0, 
	gfxheight = 0, 
	width = 32, 
	height = 32,
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
	nohurt = true,
	jumphurt = true,
	spinjumpsafe = false,
	defaultspeed = 180/275,
	staticdirection = true,
	notcointransformable = true
});
circle.registerRing(npcID, 469) -- More IDs can be entered, separated by comma.
return boocircle;