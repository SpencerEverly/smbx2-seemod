local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local clappingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local clappingChuckSettings = {
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 60, 
	gfxheight = 58, 
	width = 32, 
	height = 48, 
	gfxoffsety = 2,
	frames = 3,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed = true,
	-- Custom
	jumprange = 64,
	jumprangemax = 256,
	jumpheight = 7
}

local configFile = npcManager.setNpcSettings(clappingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local STATE_GROUNDED = 0;
local STATE_JUMPING = 1;

-- Final setup
local function hurtFunction (v)
end

local function hurtEndFunction (v)
	v.data._basegame = v.data._basegame or {}
	v.data._basegame.frame = 0
	v.ai2 = 30; --Countdown Timer
	v.ai3 = 0; --Jump Timer
	v.ai4 = 0; --State. 0 = ground; 1 = jump
end

function clappingChuck.onInitAPI()
	npcManager.registerEvent(npcID, clappingChuck, "onTickEndNPC")
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end


--*********************************************
--                                            *
--              CLAPPING CHUCK                *
--                                            *
--*********************************************

function clappingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; --Health
		v.ai2 = 30; --Countdown Timer
		v.ai3 = 0; --Jump Timer
		v.ai4 = 0; --State. 0 = ground; 1 = jump
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = configFile.frames
		})
		return
	end
	
	if data.exists == nil then
		v.ai1 = configFile.health;
		data.exists = 0;
		data.frame = 0;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- Stop if it hits a block
	if v.collidesBlockBottom and v.speedX ~= 0 then
		v.speedX = 0;
	end
	
	-- correct animation
	if data.frame == 2 and v.collidesBlockBottom then
		data.frame = 0;
		v.ai4 = 0;
	end
	
	-- face player
	if v.x > p.x then
		v.direction = -1;
	else
		v.direction = 1;
	end
	
	-- Update animations
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
	
	-- Actual AI
	if data.hurt then return end;
	
	-- bouncing in place
	if v.ai4 == STATE_GROUNDED then
		-- smol bounces
		if v.ai2 < 0 then
			v.ai2 = 30;
		end
				
		v.ai2 = v.ai2 - 1;
		if v.ai2 <= 0 and v.collidesBlockBottom then
			v.y = v.y - 4;
			v.speedY = -2;
			
			v.ai2 = 30;
			data.frame = 1;
			
		end
				
		if v.collidesBlockBottom and v.speedY == 0 then
			data.frame = 0;
		end
	-- clap AI
	elseif v.ai4 == STATE_JUMPING then
		v.ai3 = v.ai3 - 1;
		if v.ai3 == 0 then
			data.frame = 2;
			SFX.play(91)
		end
	end
	
	-- begin JUMNP
	if p.y < v.y - configFile.jumprange and p.y > v.y - configFile.jumprangemax and v.ai4 == STATE_GROUNDED and v.collidesBlockBottom then
		v.ai4 = STATE_JUMPING;
		v.ai2 = 5;
		v.ai3 = 20;
		
		v.y = v.y - 4;
		v.speedY = -math.abs(configFile.jumpheight);
		
		data.frame = 1;
		SFX.play(24)
	end
end

return clappingChuck;