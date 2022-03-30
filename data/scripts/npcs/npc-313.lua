local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local pitchingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local pitchingChuckSettings = {
	id = npcID, 
	gfxwidth = 48, 
	gfxheight = 56, 
	width = 32, 
	height = 48, 
	gfxoffsety=2,
	frames = 7,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed = true,
	-- Custom
	jumprange = 80,
	jumpheight = 6.5,
	throwtime = 30,
	throwcooldown = 15,
	volleycooldown = 90,
	defaultvolley = 6,
	projectileid = 319
}

local configFile = npcManager.setNpcSettings(pitchingChuckSettings);

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

local thrownOffset = {}
thrownOffset[-1] = -8;
thrownOffset[1] = (configFile.width) + 8;

-- Final setup
local function hurtFunction (v)
	v.data._basegame.hangInAir = 0;
	v.speedY = 0;
	v.ai2 = -20;
	v.ai5 = 0;
	v.ai3 = v.ai4;
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
	v.ai2 = -60;
end

function pitchingChuck.onInitAPI()
	npcManager.registerEvent(npcID, pitchingChuck, "onTickEndNPC");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              pitching CHUCK                *
--                                            *
--*********************************************

function pitchingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 --[[or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)]] or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		v.ai2 = -20; -- Generic Timer
		v.ai3 = settings.volley or configFile.defaultvolley -- current ammo
		v.ai4 = v.ai3; -- Starting ammo
		v.ai5 = 0; -- is jumping?
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = configFile.frames
		})
		return
	end
	
	if (data.exists == nil) then
		v.ai1 = configFile.health;
		data.exists = 0;
		data.frame = 0;
		data.hangInAir = 0;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- failsafe
	if (settings.volley == nil) then
		v.ai2 = -20; --Generic Timer
		v.ai3 = configFile.defaultvolley
		v.ai4 = v.ai3;
		settings.volley = v.ai4;
	end
	
	-- timer start
	v.ai2 = v.ai2 + 1;

	-- hanging in midair handler
	if data.hangInAir == 1 and not data.hurt then
		v.speedY = v.speedY - Defines.npc_grav;
	end
	
	-- regular pitching
	if v.ai5 == STATE_GROUNDED and not data.hurt then
		if v.ai2 == configFile.throwtime then
			data.frame = 1;
		end
		if v.ai2 == configFile.throwtime + 8 then
			data.frame = 2;
			
			local myBaseball = NPC.spawn(configFile.projectileid, v.x+thrownOffset[v.direction], v.y+12, p.section)
			myBaseball.direction = v.direction
			myBaseball.layerName = "Spawned NPCs"
			myBaseball.speedX = NPC.config[myBaseball.id].speed * myBaseball.direction * 2.25
			myBaseball.friendly = v.friendly
			if v:mem(0x12C, FIELD_WORD) > 0 then
				myBaseball.data._basegame = myBaseball.data._basegame or {}
				myBaseball.data._basegame.thrownPlayer = 1
			end
			
			-- decrement how many baseballs are left
			v.ai3 = v.ai3 - 1;
		end
		
		-- reset
		if v.ai2 == configFile.throwtime + configFile.throwcooldown then
			-- if there's still balls left, reset
			if v.ai3 > 0 then
				v.ai2 = 0;
				data.frame = 0;
			-- otherwise time to pause
			else
				data.frame = 3;
			end
		end
		
		-- reset throw timer
		if v.ai2 == configFile.throwtime + configFile.volleycooldown or (v.ai2 == configFile.throwtime + configFile.throwcooldown + 5 and v:mem(0x12C, FIELD_WORD) > 0) then
			v.ai2 = -20;
			v.ai3 = settings.volley;
		end
		
		-- detect if player is gonna jump
		if p.y < v.y - configFile.jumprange and v.ai2 >= -20 then
			v.y = v.y - 4;
			v.speedY = -math.abs(configFile.jumpheight);
			
			v.ai5 = STATE_JUMPING;
			data.frame = 4;
			
			v.ai2 = 0;
			v.ai3 = settings.volley;
		end
	-- jumping AI
	elseif v.ai5 == STATE_JUMPING then
		-- jumping animation change
		if v.ai2 == 9 then	
			data.frame = 5;
		end
		
		-- hang in air
		if v.ai2 == 15 then
			v.speedY = -0.25;
			data.hangInAir = 1;
		end
		
		-- throw baseball time
		if v.ai2 == 22 then
			data.frame = 4;
		end
		
		if v.ai2 == 27 then
			data.frame = 6;
			local myBaseball = NPC.spawn(configFile.projectileid, v.x + thrownOffset[v.direction], v.y + 12, p.section)
			myBaseball.direction = v.direction
			myBaseball.layerName = "Spawned NPCs"
			myBaseball.speedX = NPC.config[myBaseball.id].speed * myBaseball.direction * 2.25
			myBaseball.friendly = v.friendly
			if v:mem(0x12C, FIELD_WORD) > 0 then
				myBaseball.data._basegame = myBaseball.data._basegame or {}
				myBaseball.data._basegame.thrownPlayer = p;
			end
		end
		
		-- reset
		if v.ai2 == 33 then
			data.hangInAir = 0;
		end
			
		-- check if on ground
		if v.collidesBlockBottom then
			if data.frame == 5 then
				data.frame = 1;
			elseif data.frame == 4 then
				data.frame = 1;
			elseif data.frame == 6 then
				data.frame = 2;
			end

			data.hangInAir = 0;
			
			-- if the throw has been completed, reset properly
			if v.ai2 > 70 then
				v.ai2 = 10;
				v.ai5 = STATE_GROUNDED;
				data.frame = 0;
			end
		end
	end
	
	-- resetting
	if v.collidesBlockBottom and v.speedY >= 0 then
		if v.speedX ~= 0 then
			v.speedX = 0;
		end
				
		if data.frame > 3 then
			data.frame = 0;
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

function pitchingChuck.onDrawNPC(v)
	if not Defines.levelFreeze then
		local data = v.data._basegame
		if not data.frame then return end
		v.animationFrame = data.frame + directionOffset[v.direction];
	end
end

return pitchingChuck;