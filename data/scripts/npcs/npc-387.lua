local npcManager = require("npcManager")

local mathPlatform = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local mathSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 32, 
	width = 64,
	height = 32, 
	frames = 10, 
	framestyle = 0, 
	framespeed = 8, 
	score = 0, 
	blocknpctop = -1, 
	playerblocktop = -1, 
	ignorethrownnpcs = true,
	nohurt = 1, 
	nogravity = 1, 
	noblockcollision = 1, 
	noyoshi = 1, 
	noiceball = 1, 
	notcointransformable = true,
	-- Custom
	default = 4, 
	second = 60,
	fallaccel = 1;
}

local configFile = npcManager.setNpcSettings(mathSettings);

-- register functions
function mathPlatform.onInitAPI()
	npcManager.registerEvent(npcID, mathPlatform, "onTickEndNPC")
end

--*********************************************
--                                            *
--                   AI                       * 
--                                            *
--*********************************************

function mathPlatform.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	local settings = v.data._settings

	-- reset everything when offscreen or grabbed or in reserve box
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		settings.timer = data.timerbase	or settings.timer
		v.animationFrame = settings.timer or 0;
		return
	end
	
	-- initialize timer
	if data.timerbase == nil then
		if settings.timer == nil then
			settings.timer = configFile.default
		end
		data.timerbase = settings.timer
	end

	-- check for player standing on the NPC
	if (v.ai3 == 0) then
		for _,p in ipairs(Player.get()) do
			if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
				v.ai3 = 2;
				v.speedX = 2.4 * v.direction;
				break;
			end
		end
	end
	
	-- time to fall to my doom
	if v.ai3 >= 2 then
		if Layer.isPaused() then
			v.speedX = 0
			v.speedY = 0
		else
			v.speedX = 2.4 * v.direction
			v.ai3 = v.ai3 + 1;
			
			if v.ai3 >= configFile.second then
				if settings.timer > 0 then
					settings.timer = settings.timer - 1;
				end
				v.ai3 = 2;
			end
			
			if settings.timer <= 0 then
				v.ai5 = v.ai5 + configFile.fallaccel * Defines.npc_grav;
			end
			v.speedY = v.ai5
		end
	end
	
	-- update animations
	v.animationFrame = settings.timer;
end

return mathPlatform;