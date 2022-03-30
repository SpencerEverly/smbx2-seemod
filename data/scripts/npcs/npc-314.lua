local npcManager = require("npcManager")
local rng = require("rng")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local splittingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local splittingChuckSettings = {
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 56, 
	gfxheight = 54, 
	width = 32, 
	height = 48, 
	gfxoffsety = 2,
	frames = 2,
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
	splits = 2,
	splitnpc = 311,
	postsplitnpc = 311
}

local configFile = npcManager.setNpcSettings(splittingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local splittingSfxFile = Misc.resolveSoundFile("magikoopa-magic")

local STATE_GROUNDED = 0;
local STATE_SPLITTING = 1;

-- final setup
local function hurtFunction (v)
	v.speedX = 0;
	v.speedY = 0;
	v.ai2 = 0;
	v.ai3 = STATE_GROUNDED;
end

local function hurtEndFunction (v)
	v.ai2 = 90;
end

function splittingChuck.onInitAPI()
	npcManager.registerEvent(npcID, splittingChuck, "onTickEndNPC")
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              SPLITTING CHUCK               *
--                                            *
--*********************************************

local function newChuck(v, speedX)
	local newChuck = NPC.spawn(configFile.splitnpc, v.x + 0.5 * v.width, v.y - 4, npcutils.getNearestPlayer(v).section, false, true)
	newChuck.data._basegame = {}
	
	newChuck.friendly = v.friendly
	newChuck.layerName = v.layerName
	newChuck.noMoreObjInLayer = v.noMoreObjInLayer
	newChuck.speedX = speedX * NPC.config[npcID].speed;
	newChuck.speedY = -5.5
	newChuck.dontMove = v.dontMove
	newChuck.ai1 = configFile.health
	
	newChuck.data._basegame.cameFromSplittingChuck = 1
	newChuck.data._basegame.frame = 2
	return newChuck, newChuck.data._basegame
end

function splittingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; --Health
		v.ai2 = 90; --Generic Timer
		v.ai3 = STATE_GROUNDED; --State. 0 = ground; 1 = about to split
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = configFile.frames
		})
		return
	end
	
	if data.exists == nil then
		v.ai1 = configFile.health;
		data.frame = 0;
		data.exists = 0;
		data.shakeX = v.x;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- bouncing in place
	if v.ai3 == STATE_GROUNDED and not data.hurt then
		-- fix timer
		if v.ai2 < -1 then
			v.ai2 = 90;
		end
		
		v.ai2 = v.ai2 - 1;
		
		-- small hop
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
				
		-- track when to start splitting
		if (p.x > v.x - configFile.range and v.direction == -1) or (p.x < v.x + configFile.range and v.direction == 1) then
			v.ai2 = 1;
			v.ai3 = STATE_SPLITTING;
			data.shakeX = v.x;
			data.frame = 1;
		end
	-- time to split
	elseif v.ai3 == STATE_SPLITTING and not data.hurt then
		v.ai2 = v.ai2 + 1;
				
		-- enjl was here
		-- Thanks enjl! :)
		if v.ai2 > 2 and v.ai2 < 15 then
			if v.ai2 % 2 == 0 then
				v.x = data.shakeX;
			else
				v.x = v.x + rng.randomInt(-6,6)
			end
		end
				
		if v.ai2 == 60 then
			SFX.play(splittingSfxFile)
			
			-- Ah dang not again
			for i=0, configFile.splits - 1 do
				newChuck(v,(i/(configFile.splits-1)) * 4 - 2)
			end
			
			-- transform into normal chuck
			v.id = configFile.postsplitnpc;
			v.ai3 = 1; -- you think i'm gonna port over charging chuck's defines just for these two lines? HAH
			v.ai4 = 0;
			
			v.ai2 = 45;
			v.ai5 = -1;
			v.speedX = 0;
			data.frame = 7;
		end
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

return splittingChuck;