local npcManager = require("npcManager")

local bouyantPlatform = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local bouyantSettings = {
	id = npcID, 
	gfxwidth = 96, 
	gfxheight = 64, 
	width = 96, 
	height = 64, 
	frames = 1,
	framespeed = 8, 
	framestyle = 0,
	gfxoffsety = 0,
	score = 0,
	blocknpctop = -1,
	playerblocktop = -1,
	ignorethrownnpcs = true,
	nohurt = 1,
	noblockcollision = 1,
	nowaterphysics = 1,
	nogravity = 1,
	noiceball = 1,
	noyoshi = 1,
	notcointransformable = true,
	-- Custom
	wateraccel = -0.20;
	fallaccel = 0.1;
	speedcap = 1.25;
};

local configFile = npcManager.setNpcSettings(bouyantSettings);

-- register functions
function bouyantPlatform.onInitAPI()
	npcManager.registerEvent(npcID, bouyantPlatform, "onTickNPC")
end

--*********************************************
--                                            *
--                    AI                      *
--                                            *
--*********************************************

function bouyantPlatform.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	-- don't run the code if it's offscreen/grabbed/reserved
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		return
	end
	
	-- check for liquids
	local liquid = Liquid.getIntersecting(v.x, v.y - 8, v.x + v.width, v.y + 24)
	
	-- float up if it's in the liquid
	for _,l in ipairs(liquid) do
		if not l.isHidden then
			-- check for players standing on it, if there is one sink
			for _,p in ipairs(Player.get()) do
				if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
					v.speedY = -configFile.wateraccel * 2.25;
					return
				end
			end
			
			v.speedY = v.speedY + configFile.wateraccel * Defines.npc_grav;
			
			-- caps to its speed so its physics dont get all wacky
			if v.speedY < -configFile.speedcap then
				v.speedY = -configFile.speedcap;
			end
			
			if v.speedY > configFile.speedcap then
				v.speedY = configFile.speedcap;
			end
			
			break
		end
	end
	
	if #liquid == 0 then
		if (v.speedY < -configFile.wateraccel * 7) then
			v.speedY = -configFile.wateraccel * 7;
		else
			v.speedY = v.speedY + (configFile.fallaccel * Defines.npc_grav);
		end
	end
end

return bouyantPlatform;