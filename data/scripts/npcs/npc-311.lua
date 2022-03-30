local npcManager = require("npcManager")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local chargingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local chargingChuckSettings = {
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 56, 
	gfxheight = 54, 
	width = 32, 
	height = 48, 
	gfxoffsety = 2,
	frames = 8,
	framespeed = 8, 
	framestyle = 1,
	score = 4,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed=true,
	-- Custom
	startrange = 48,
	calmrange = 48,
	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 668, 526}
}

local configFile = npcManager.setNpcSettings(chargingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local stompSfx = Misc.resolveSoundFile("chuck-stomp")

local STATE_WANDER = 0;
local STATE_CHARGE = 1;

local STATE_MINOR_STILL = 0;
local STATE_MINOR_MOVING = 1;

local STATE_MINOR_LOOKING_ONE = 2;
local STATE_MINOR_LOOKING_OTHER = 3;

local STATE_MINOR_PAUSE = 2;
local STATE_MINOR_JUMPING = 3;

-- Final setup
local function hurtFunction (v)
	v.speedX = 0;
	v.ai2 = 0;
	v.ai3 = STATE_WANDER;
	v.ai4 = STATE_MINOR_STILL;
	v.ai5 = -1;
end

local function hurtEndFunction (v)
	local data = v.data._basegame
	
	v.ai2 = 60;
	data.frame = 7;
end

function chargingChuck.onInitAPI()
	chucks.register(npcID, hurtFunction, hurtEndFunction);
	npcManager.registerEvent(npcID, chargingChuck, "onTickEndNPC")
end

--*********************************************
--                                            *
--              CHARGING CHUCK                *
--                                            *
--*********************************************

function chargingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		v.ai1 = configFile.health;
		v.ai2 = 30; -- generic timer
		v.ai3 = 0; -- main state. 0 = wander, 1 = charge, 2 = stun
		v.ai4 = 0; -- minor state. it's like every number at some point
		-- 0 = wander, standing still; 1 = wander, moving; 2 = wander, looking;
		v.ai5 = -1; -- animation timer
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 7,
			frames = configFile.frames
		})
		
		if (v.collidesBlockBottom) then
			v.speedX = 0;
		end
		return
	end
	
	-- initializing
	if (data.exists == nil) then
		v.ai1 = configFile.health;
		data.exists = true;
		data.frame = 7;
		data.lockDirection = 0;
		data.destroyCollider = colliders.Box(v.x - 4, v.y + 8, v.width + 8, v.height - 8);
	end
	
	local p = npcutils.getNearestPlayer(v)
		
	-- manage regular timer
	if v.ai2 > 0 then
		v.ai2 = v.ai2 - 1;
	end
	
	-- Basic AI
	if v.ai3 == STATE_WANDER and not data.hurt then
		-- Control actual wandering around
		if v.ai4 == STATE_MINOR_STILL then
			-- start moving around if its timer is up
			if v.collidesBlockBottom then
				v.speedX = 0
			end
			if v.ai2 == 0 then
				if v.collidesBlockBottom then
					v.speedX = v.direction * 1.5 * NPC.config[npcID].speed;
				end
				v.ai4 = STATE_MINOR_MOVING;
				
				v.ai5 = 1;
				v.ai2 = 60;
			end
			
			-- no animation here
			data.frame = 3;
		elseif v.ai4 == STATE_MINOR_MOVING then
			-- Start to look both ways
			if (v.ai2 <= 0 and v.collidesBlockBottom) or (v.collidesBlockLeft or v.collidesBlockRight) then
				v.speedX = 0;
				v.direction = -v.direction;
				v.ai4 = STATE_MINOR_LOOKING_ONE;
				
				data.frame = 3;
				v.ai5 = 25;
				v.ai2 = 130;
				
				if (v.collidesBlockLeft or v.collidesBlockRight) then
					v.x = v.x - (4*v.direction);
				end
			end
			
			-- jog animation
			v.ai5 = v.ai5 - 1;
			if v.ai5 == 0 then
				v.ai5 = 4;
				if data.frame == 1 then
					data.frame = 0;
				else
					data.frame = 1;
				end
			end
		elseif v.ai4 == STATE_MINOR_LOOKING_ONE then
			v.ai5 = v.ai5 - 1;
			if v.ai5 == 0 then
				v.ai5 = 4;
				data.frame = data.frame + 1;
				if data.frame > 7 then
					v.ai4 = STATE_MINOR_LOOKING_OTHER;
					
					data.frame = 7;
					v.ai5 = 30;
				end
			end
		elseif v.ai4 == STATE_MINOR_LOOKING_OTHER then
			v.ai5 = v.ai5 - 1;
			if v.ai5 == 0 then
				v.ai5 = 4;
				data.frame = data.frame - 1;
				if data.frame < 3 then
					v.ai4 = STATE_MINOR_STILL;
					
					data.frame = 3;
					v.ai5 = -1;
					v.ai2 = 60;
				end
			end
		end
		
		-- ATTACK
		if p.y >= v.y - configFile.startrange and v.collidesBlockBottom and ((data.cameFromSplittingChuck == nil) or (data.cameFromSplittingChuck == 0)) then
			--SFX.play(12)
			v.ai3 = STATE_CHARGE;
			v.ai4 = STATE_MINOR_STILL;
			
			v.ai2 = 35;
			v.ai5 = -1;
			data.frame = 7;
			
			v.speedX = 0;
		end
	elseif v.ai3 == STATE_CHARGE and not data.hurt then
		-- Face p if not moving
		if v.speedX == 0 then
			if v.x > p.x then
				v.direction = -1;
			else
				v.direction = 1;
			end
		end
			
		-- first charge
		if v.ai2 == 0 and v.ai4 == STATE_MINOR_STILL then
			v.speedX = 3 * v.direction * NPC.config[npcID].speed;
			v.ai4 = STATE_MINOR_MOVING;
			v.ai5 = 1;
		-- actually charging at the p
		elseif v.ai4 == STATE_MINOR_MOVING then
			-- properly set charge speed
			if v.collidesBlockBottom and v.speedX == 0 then
				v.speedX = 3 * v.direction * NPC.config[npcID].speed;
			end
			
			-- check if p is outside range. if so, stop
			if ((v.x+(v.width/2) < p.x-configFile.calmrange and v.direction == -1) or (v.x+(v.width/2) > p.x+configFile.calmrange and v.direction == 1)) and v.collidesBlockBottom then
				v.speedX = 0;
				v.ai4 = STATE_MINOR_PAUSE;
				v.ai5 = -1;
				v.ai2 = 45;
				data.frame = 7;
			end
		-- pausing after p is far enough out of the way
		elseif v.ai4 == STATE_MINOR_PAUSE then
			if v.ai2 == 0 then
				v.ai3 = STATE_WANDER;
				v.ai4 = STATE_MINOR_STILL;
			end
			data.frame = 7;
		end
		
		-- Jumping over walls
		if (v.collidesBlockLeft or v.collidesBlockRight) and v.collidesBlockBottom and v.ai4 ~= STATE_MINOR_JUMPING then
			v.speedX = 3 * v.direction * NPC.config[npcID].speed;
			v.speedY = -8;
			v.ai4 = STATE_MINOR_JUMPING;
			
			data.lockDirection = v.direction;
		elseif v.ai4 == STATE_MINOR_JUMPING then
			v.direction = data.lockDirection;
			
			v.speedX = 3 * data.lockDirection * NPC.config[npcID].speed;
			
			data.frame = 2;
			if v.collidesBlockBottom then
				v.ai4 = STATE_MINOR_MOVING;
				data.lockDirection = 0;
				v.speedX = 0
			end
		end
			
		-- Handle destroying blocks
		data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 4, v.y + 8, v.width + 8, v.height - 8);
		data.destroyCollider.x = v.x - 2 + 0.5 * (v.width + 2) * v.direction;
		data.destroyCollider.y = v.y + 8;
		local list = colliders.getColliding{
			a = data.destroyCollider,
			b = configFile.destroyblocktable,
			btype = colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
		}
		for _,b in ipairs(list) do
			if v.speedX ~= 0 then
				if b.id == 667 then
					b:hit()
				else
					b:remove(true)
				end
			end
		end
		
		-- Animation for when he's moving
		if v.ai4 == STATE_MINOR_MOVING then
			v.ai5 = v.ai5 - 1;
			if v.ai5 == 0 or v.ai5 == 3 or v.ai5 == 6 then
				if v.ai5 == 0 then
					if v.collidesBlockBottom and v.dontMove == false then
						SFX.play(stompSfx)
					end
					v.ai5 = 9;
				end
				if v.collidesBlockBottom then
					if data.frame == 1 then
						data.frame = 0;
					else
						data.frame = 1;
					end
				else
					data.frame = 2;
				end
			end
		end
	end
		
	if (data.frame == 0 or data.frame == 1) and v.speedX == 0 then
		data.frame = 5;
	end
	
	-- Special case handling for if this is a chuck spawned from splitting chuck
	if (data.cameFromSplittingChuck ~= nil) then
		if data.cameFromSplittingChuck == 1 then
			data.frame = 2;
			if v.collidesBlockBottom then
				if p.x < v.x then
					v.direction = -1;
				else
					v.direction = 1;
				end
				data.cameFromSplittingChuck = 0;
				v.speedX = 3 * v.direction * NPC.config[npcID].speed;
				v.ai3 = STATE_CHARGE;
				v.ai4 = STATE_MINOR_MOVING;
				
				v.ai5 = 1;
				v.ai2 = 35;
			end
		end
	end
	
	-- Animation updating
	local forceDir;
	if v.ai3 == STATE_CHARGE and v.ai4 == STATE_MINOR_JUMPING then
		if p.x < v.x then
			forceDir = -1;
		else
			forceDir = 1;
		end
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames,
		direction = forceDir or v.direction
	});
	v.animationTimer = 0
end

return chargingChuck;