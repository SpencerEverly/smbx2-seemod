local npcManager = require("npcManager")
local rng = require("rng")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local bouncingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local bouncingChuckSettings = {
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 56, 
	gfxheight = 54, 
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
	range = 192,
	jumpheight = 8
}

local configFile = npcManager.setNpcSettings(bouncingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

local STATE_GROUNDED = 0;
local STATE_JUMP = 1;

-- Final setup
local function hurtFunction (v)
	v.speedX = 0;
	v.speedY = 0;
	v.ai2 = 0;
	v.ai3 = STATE_GROUNDED;
end

local function hurtEndFunction (v)
end

function bouncingChuck.onInitAPI()
	npcManager.registerEvent(npcID, bouncingChuck, "onTickEndNPC")
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              BOUNCING CHUCK                *
--                                            *
--*********************************************

function bouncingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; --Health
		v.ai2 = 90; --Generic Timer
		v.ai3 = 0; --State. 0 = ground; 1 = jump
		
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
		data.shakeX = v.x;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- slow bouncing in place
	if v.ai3 == STATE_GROUNDED and not data.hurt then
		-- fix timer
		if v.ai2 < -1 then
			v.ai2 = 90;
		end
				
		v.ai2 = v.ai2 - 1;
				
		if v.ai2 == 0 then
			v.speedY = -3;
			v.ai2 = 60;
		end
				
		-- face player
		if p.x < v.x then
			v.direction = -1;
		else
			v.direction = 1;
		end
				
		-- track bouncing
		if (p.x > v.x - configFile.range and v.direction == -1) or (p.x < v.x + configFile.range and v.direction == 1) then
			v.ai2 = 1;
			v.ai3 = STATE_JUMP;
			data.frame = 1;
			data.shakeX = v.x;
		end
	-- bouncing around for real
	elseif v.ai3 == STATE_JUMP and not data.hurt then
		v.ai2 = v.ai2 + 1;
				
		-- shaking animation
		if v.ai2 > 2 and v.ai2 < 15 then
			if v.ai2 % 2 == 0 then
				v.x = data.shakeX;
			else
				v.x = v.x + rng.randomInt(-6,6)
			end
		end
		
		-- actual bounce
		if v.ai2 == 60 then
			data.frame = 2;
			SFX.play(24)
			v.speedX = 3.5 * v.direction * NPC.config[npcID].speed;
			v.speedY = -math.abs(configFile.jumpheight);
		end
		
		-- AI for when it hits ground
		if v.ai2 > 62 and v.collidesBlockBottom and data.frame == 2 then
			data.frame = 0;
			v.ai2 = 6660;
			v.speedX = 0
			-- face player
			if p.x < v.x then
				v.direction = -1;
			else
				v.direction = 1;
			end
		end
		if v.ai2 >= 6670 then
			v.ai2 = 90;
			v.ai3 = STATE_GROUNDED;
		end
	end
	
	-- Animation updating
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames,
		direction = v.direction
	});
	v.animationTimer = 0
end

return bouncingChuck;