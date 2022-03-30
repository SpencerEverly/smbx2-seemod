local npcManager = require("npcManager")
local spawnerAI = require("npcs/ai/tedspawner")
local npcID = NPC_ID
local torpedoTeds = {}

local gripSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 1,
	noblockcollision = 1,
	nofireball=1,
	noiceball=1,
	frames=2,
	ignorethrownnpcs = true,
	noyoshi=1,
	nohurt=1,
	spinjumpsafe = false,
	delay=65,
	force=1,
	harmlessgrab=true,
	traveldistance=64,
    spawnspeed=0.5,
	spawnid = 305,
	heldframe=0,
	spawnerpriority=-70,
	anchory=1 -- -1 is top
}
npcManager.setNpcSettings(gripSettings)
spawnerAI.register(npcID)
	
return torpedoTeds