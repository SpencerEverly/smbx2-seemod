local npcManager = require("npcManager")
local sinewave = require("npcs/ai/sinewave")

local gasBubble = {}

npcID = NPC_ID;

local bubbleData = {}

npcManager.setNpcSettings({
	id = npcID, 
	gfxoffsety = 8,
	gfxwidth = 112, 
	gfxheight = 120, 
	width = 86, 
	height = 100, 
	frames = 2,
	framespeed = 8, 
	framestyle = 0,
	score = 0,
	nofireball = 1,
	noiceball = -1,
	nogravity = 1,
	noblockcollision = 1,
	jumphurt = 1,
	noyoshi = 1,
	speed = 1.3,
	ignorethrownnpcs = true,
	harmlessgrab = true,
	spinjumpsafe = true,
	--lua only
	frequency = 40,
	amplitude = 2,
    wavestart = -1,
    chase = true
})

function gasBubble.onInitAPI()
	sinewave.register(npcID)
end

return gasBubble;