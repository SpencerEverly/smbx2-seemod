local npcManager = require("npcManager")

local fallingPlatform = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local fallingSettings = {
	id = npcID, 
	gfxwidth = 128, 
	gfxheight = 32, 
	width = 128, 
	height = 32, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 0,
	blocknpctop = -1, 
	playerblocktop = -1, 
	nohurt = 1, 
	nogravity = 1, 
	noiceball = 1, 
	noblockcollision = 1, 
	ignorethrownnpcs = true,
	noyoshi = 1,
	notcointransformable = true,
	-- Custom
	falldelay = 25,
	delayspeed = .5,
	fallaccel = 1
}

local configFile = npcManager.setNpcSettings(fallingSettings);

local directionOffset = {}
directionOffset[-1] = 0;
directionOffset[0] = 0;
directionOffset[1] = 0 + (configFile.framestyle * configFile.frames);

-- register functions
function fallingPlatform.onInitAPI()
	npcManager.registerEvent(npcID, fallingPlatform, "onTickNPC")
end

--*********************************************
--                                            *
--                   AI                       *
--                                            *
--*********************************************

function fallingPlatform.onTickNPC(v)
	if Defines.levelFreeze then return end

	-- reset AI if offscreen/held/reserved
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = 0
		return
	end

	-- check for collision with player
	if (v.ai1 == 0) then
		for _,p in ipairs(Player.get()) do
			if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
				v.ai1 = 2;
				break;
			end
		end
	end
	
	-- time to fall to my doom
	if v.ai1 >= 2 then
		v.ai1 = v.ai1 + 1;
		
		if v.ai1 <= configFile.falldelay then
			v.speedY = configFile.delayspeed;
		else
			v.speedY = v.speedY + configFile.fallaccel * Defines.npc_grav;
		end
	end
end

return fallingPlatform;