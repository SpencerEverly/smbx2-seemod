local npcManager = require("npcManager")

local seaMines = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local mineSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 64, 
	gfxoffsety = 8,
	width = 48, 
	height = 48, 
	frames = 2,
	framespeed = 16, 
	framestyle = 0,
	score = 0,
	speed = 1,
	jumphurt = 1,
	nowaterphysics = 1,
	noblockcollision = 1,
	noyoshi=true,
	spinjumpsafe = true,
	-- Custom
	fallaccel = 0.6,
	wateraccel = 1.1,
	sinkmultiplier = 1.06
}

local configFile = npcManager.setNpcSettings(mineSettings);

npcManager.registerHarmTypes(npcID, {HARM_TYPE_PROJECTILE_USED}, {[HARM_TYPE_PROJECTILE_USED]=238});

-- function setup
function seaMines.onInitAPI()
	npcManager.registerEvent(npcID, seaMines, "onTickEndNPC")
end

--***************************************************************************************************
--                                                                                                  *
--              BEHAVIOR                                                                            *
--                                                                                                  *
--***************************************************************************************************

function seaMines.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings

	-- don't run the code if it's offscreen/grabbed/reserved
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		settings.fast = settings.fast or false;
		return
	end
	
	if settings.fast == nil then
		settings.fast = false;
	end
	
	--[[if (data.speedMultiplier == nil) then
		data.speedMultiplier = 1;
	end]]--
	
	-- float upwards
	local sinkMult = 1
	if v.speedY > 0 then
		sinkMult = configFile.sinkmultiplier
	end
	if v.underwater then
		v.speedY = v.speedY - configFile.wateraccel * sinkMult * Defines.npc_grav;
	else
		v.speedY = v.speedY - configFile.fallaccel * Defines.npc_grav;
	end
	
	-- move around
	if (settings.fast) then
		v.speedX = 1.75 * v.direction;
	else
		v.speedX = v.direction;
	end
end

return seaMines;