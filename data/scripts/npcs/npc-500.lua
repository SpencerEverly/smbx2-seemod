local npcManager = require("npcManager")

local asteronSpike = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local asteronSpikeSettings = {
	id = npcID, 
	gfxwidth = 30, 
	gfxheight = 28, 
	width = 30, 
	height = 28, 
	frames = 5,
	framespeed = 8, 
	framestyle = 0,
	score = 0,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	nogravity = 1,
	jumphurt = 1,
	nowaterphysics = 1,
	spinjumpsafe = 0,
	nogravity = -1, 
	noiceball = -1,
	nofireball = -1,
	noyoshi = -1,
	noblockcollision = -1
}

local configFile = npcManager.setNpcSettings(asteronSpikeSettings)

-- ready set go
function asteronSpike.onInitAPI()
	npcManager.registerEvent(npcID, asteronSpike, "onTickEndNPC")
end

--***************************************************************************************************
--                                                                                                  *
--              BEHAVIOR                                                                            *
--                                                                                                  *
--***************************************************************************************************

function asteronSpike.onTickEndNPC(v)	
	v.animationFrame = v.ai1;
end

return asteronSpike;