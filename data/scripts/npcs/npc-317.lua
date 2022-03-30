local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")
local whistle = require("npcs/ai/whistle");

local whistlingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

-- Basic setup
local whistlingChuckSettings = {
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 56, 
	gfxheight = 56, 
	width = 32, 
	height = 48, 
	gfxoffsety = 2,
	frames = 6,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 317,
	luahandlesspeed=true,
	-- Custom
	range = 96,
	hitcooldown = 30,
	whistlecooldown = nil
}

local configFile = npcManager.setNpcSettings(whistlingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local STATE_CALM = 0;
local STATE_WHISTLING = 1;

local whistleSfx = Misc.resolveSoundFile("chuck-whistle")

-- Final setup
local function hurtFunction (v)
	v.data._basegame.frame = 1;
end

local function hurtEndFunction (v)
	v.ai2 = STATE_WHISTLING;
	v.ai3 = 0;
	v.ai4 = 0;
end

function whistlingChuck.onInitAPI()
	npcManager.registerEvent(npcID, whistlingChuck, "onTickEndNPC")
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              WHISTLING CHUCK               *
--                                            *
--*********************************************

function whistlingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		v.ai2 = STATE_CALM; -- State
		v.ai3 = 0; -- Generic Timer
		v.ai4 = 0; -- Anim Timer
		
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

	local settings = v.data._settings
	
	if settings.proximity == nil then
		settings.proximity = true;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- Stop if it hits a block
	if v.collidesBlockBottom and v.speedX ~= 0 then
		v.speedX = 0;
	end
	
	-- Update animations
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
	
	-- Trigger by proximity
	if settings.proximity then
		if math.abs(p.x - v.x) < configFile.range and v.ai2 == STATE_CALM then
			v.ai2 = STATE_WHISTLING;
			v.ai3 = configFile.hitcooldown;
			v.ai4 = 0;
		end
	end
	
	-- Actual AI
	if data.hurt then return end;
	
	-- He's just standing there... MENACINGLY!!
	if (v.ai2 == STATE_CALM) then
		-- face player
		if v.x > p.x then
			v.direction = -1;
		else
			v.direction = 1;
		end
		
		data.frame = 0;
	elseif (v.ai2 == STATE_WHISTLING) then
		v.ai3 = v.ai3 + 1;
		
		-- cooldown after hit
		if (v.ai3 > configFile.hitcooldown) then
			-- call awakening scripts
			whistle.setActive(configFile.whistlecooldown);
			
			-- whistle animation
			v.ai4 = v.ai4 + 1;
			
			-- im so sorry for this code but it has to be done.
			if (v.ai4 == 1) then
				data.frame = 5;
			elseif (v.ai4 == 16) then
				SFX.play(whistleSfx)
				data.frame = 2;
			elseif (v.ai4 == 28) then
				data.frame = 1;
			elseif (v.ai4 == 36) then
				data.frame = 5;
			elseif (v.ai4 == 48) then
				data.frame = 3;
			elseif (v.ai4 == 64) then
				data.frame = 4;
			elseif (v.ai4 == 68) then
				data.frame = 5;
				v.ai4 = 0;
			end
		end
	end
end

return whistlingChuck;