local npcManager = require("npcManager")

local bowserStatue = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local bowserStatueSettings = {
	id = npcID, 
	gfxwidth = 48, 
	gfxheight = 48, 
	gfxoffsetx = -8,
	width = 32, 
	height = 32, 
	frames = 1,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	gfxoffsety=2,
	blocknpctop = -1,
	playerblocktop = -1,
	playerblock = -1,
	blocknpc = -1,
	nohurt = 1,
	harmlessgrab = true,
	noyoshi = true,
	-- Custom
	fireinterval = 140,
	firenpc = 356,
	firespeed = 1.5,
	isheavy = 2
}

local configFile = npcManager.setNpcSettings(bowserStatueSettings);

function bowserStatue.onInitAPI()
	npcManager.registerEvent(npcID, bowserStatue, "onTickNPC")
end

--*********************************************
--                                            *
--              	   AI                     *
--                                            *
--*********************************************

function bowserStatue.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		data.timer = 60; -- generic timer
		return
	end
	
	if data.timer == nil then
		data.timer = 60;
		data.volley = 0;
	end
	
	-- stop running if it's not firing any shots
	if v.ai2 == 0 then return end
	
	data.timer = data.timer + 1
	
	if v.collidesBlockBottom then v.speedX = 0 end
	
	if data.timer >= configFile.fireinterval then
		SFX.play(42)
		
		local myFire = NPC.spawn(configFile.firenpc, v.x + (configFile.width * 0.5) + (configFile.width * 0.75) * v.direction, 
		v.y + 14 - (NPC.config[configFile.firenpc].height * 0.5),player.section, false, true);
		myFire.speedX = configFile.firespeed * v.direction;
		myFire.friendly = v.friendly
		myFire.layerName = "Spawned NPCs"
		data.volley = data.volley + 1
		if data.volley >= v.ai2 then
			data.timer = 0;
			data.volley = 0;
		else
			data.timer = configFile.fireinterval - 16
		end
	end
end

return bowserStatue;