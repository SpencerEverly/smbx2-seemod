local dolphins = {}

local npcManager = require("npcManager")
local waterleaper = require("npcs/ai/waterleaper")

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************
-- Vertical
local npcID = NPC_ID;

local verticalData = {}

verticalData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 64, 
	gfxoffsety = 0,
	width = 32, 
	height = 64, 
	frames = 2,
	framespeed = 5, 
	framestyle = 0,
	score = 0,
	jumphurt = 0,
	nowaterphysics = 1,
	nogravity = -1, 
	noblockcollision=-1,
	playerblocktop=-1,
	blocknpctop=-1,
	nohurt = 1,
	speed = 0,
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