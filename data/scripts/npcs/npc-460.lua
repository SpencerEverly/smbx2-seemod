local dolphins = {}

local npcManager = require("npcManager")
local waterleaper = require("npcs/ai/waterleaper")

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

-- Horz Long
local npcID = NPC_ID;

local longHorizontalData = {}

longHorizontalData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 80, 
	gfxheight = 32, 
	gfxoffsety = 0,
	width = 80, 
	height = 32, 
	frames = 2,
	framespeed = 5, 
	framestyle = 1,
	score = 0,
	jumphurt = 0,
	nowaterphysics = -1,
	nogravity = -1, 
	noblockcollision=-1,
	playerblocktop=-1,
	blocknpctop=-1,
	nohurt = 1,
	speed = 2.75,
	--lua only
	gravitymultiplier = 0.33,
	type = waterleaper.TYPE.WATER,
	resttime = 0,
	jumpspeed = 6,
	effect = 113
	--death stuff
})

-- ready set go
function dolphins.onInitAPI()
	waterleaper.register(npcID)
end

return dolphins;