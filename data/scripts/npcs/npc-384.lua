local npcManager = require("npcManager")
local torches = require("npcs/ai/torches")

local torchHorz = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local torchHorzSettings = {
	id = npcID, 
	gfxwidth = 88, 
	gfxheight = 32, 
	width = 72, 
	height = 28, 
	frames = 8,
	framespeed = 8, 
	framestyle = 1,
	nogravity = 1,
	gfxoffsety = 2,
	ignorethrownnpcs = true,
	noyoshi=1,
	noblockcollision = 1,
	score = 0,
	jumphurt = 1,
	-- Light library stuff
	lightradius = 64,
	lightbrightness = 2,
	lightcolor = Color.orange,
	ishot = true,
	durability = -1
}

npcManager.setNpcSettings(torchHorzSettings);

function torchHorz.onInitAPI()
    torches.register(npcID)
end

return torchHorz;