local npcManager = require("npcManager")
local rng = require("rng")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local puntingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local puntingChuckSettings = {
	id = npcID, 
	gfxwidth = 48, 
	gfxheight = 50, 
	width = 32, 
	height = 48, 
	gfxoffsety=2,
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed=true,
	-- Custom
	starttimelower = 90,
	starttimeupper = 120,
	kickcooldown = 100,
	footballid = 321,
	footballspeedx = 5,
	footballspeedy = 0
}

local configFile = npcManager.setNpcSettings(puntingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Final setup
local function hurtFunction (v)
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
	v.ai2 = configFile.kickcooldown;
end

function puntingChuck.onInitAPI()
	npcManager.registerEvent(npcID, puntingChuck, "onTickEndNPC");
	registerEvent(puntingChuck, "onNPCKill");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              BOUNCING CHUCK                *
--                                            *
--*********************************************

function puntingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; --Health
		v.ai2 = rng.randomInt(configFile.starttimelower, configFile.starttimeupper); --Generic Timer
		
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
	end
		
	-- reset speed if it hits ground
	if v.collidesBlockBottom then
		v.speedX = 0
	end
	
	-- Animation update
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
	
	if data.hurt then return end;
	
	-- AI
	v.ai2 = v.ai2 - 1;
	
	-- spawn football
	if v.ai2 == 10 then
		data.myCurrentFootball = NPC.spawn(configFile.footballid, v.x + (24 * v.direction), v.y + v.height - 32, v:mem(0x146,FIELD_WORD))
		data.myCurrentFootball.friendly = v.friendly;
		data.myCurrentFootball.layerName = "Spawned NPCs"
		data.myCurrentFootball.ai2 = 1;
	end
	
	-- keep football to football player
	if (data.myCurrentFootball and data.myCurrentFootball.isValid) then
		data.myCurrentFootball.x = v.x + (24 * v.direction);
		data.myCurrentFootball.y = v.y + v.height - 32;

		--kick
		if v.ai2 == 0 then
			data.myCurrentFootball.ai2 = 0;
			data.myCurrentFootball.speedX = configFile.footballspeedx * v.direction * NPC.config[configFile.footballid].speed;
			data.myCurrentFootball.speedY = configFile.footballspeedy;
			
			-- kick effect
			Animation.spawn(75, data.myCurrentFootball.x, data.myCurrentFootball.y)
			SFX.play(9)
			
			-- reset vars
			data.myCurrentFootball = nil
			data.frame = 1;
		end
	end
			
	if v.ai2 == -20 then
		data.frame = 0;
		v.ai2 = configFile.kickcooldown;
	end
end

function puntingChuck.onNPCKill(eventObj,npc,killReason) 
	if npc.id == npcID then
		local data = npc.data._basegame
		
		if data.myCurrentFootball and data.myCurrentFootball.isValid then
			data.myCurrentFootball:kill(9)
		end
	end
end

return puntingChuck;