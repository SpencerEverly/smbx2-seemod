local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local diggingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local diggingChuckSettings = {
	id = npcID, 
	gfxwidth = 68, 
	gfxheight = 50, 
	width = 32, 
	height = 48, 
	gfxoffsety=2,
	frames = 5,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed = true,
	-- Custom
	startwait = 110,
	digwait = 55,
	liftwait = 45,
	donewait = 60,
	rockemergeid = 173,
	rockxspeed = 1,
	rockyspeed = 5,
	defaultvolley = 3,
	projectileid = 320
}

local configFile = npcManager.setNpcSettings(diggingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

local rockOffset = {}
rockOffset[-1] = -16;
rockOffset[1] = 38;

-- Final setup
local function hurtFunction (v)
	v.ai2 = -20;
	v.ai3 = 0;
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
	v.ai2 = -40;
end

function diggingChuck.onInitAPI()
	npcManager.registerEvent(npcID, diggingChuck, "onTickEndNPC")
	registerEvent(diggingChuck, "onNPCKill")
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--********************************************
--                                           *
--              digging CHUCK                *
--                                           *
--********************************************

function diggingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		v.ai2 = -40; -- Generic Timer
		v.ai3 = 0; -- rock counter
		
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
	-- failsafe
	if (settings.volley == nil) then
		settings.volley = configFile.defaultvolley;
	end
	
	-- Animation update
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
	
	-- stop speed if it hits the ground
	if v.collidesBlockBottom and v.speedX ~= 0 then
		v.speedX = 0;
	end
	
	-- Actual AI
	if data.hurt then return end;
	
	-- increment timer
	v.ai2 = v.ai2 + 1;
	
	-- look at player and judge their sins
	if v.ai2 == math.max(10, configFile.startwait - 70) then
		data.frame = 1;
	end
	
	if v.ai2 == configFile.startwait then
		data.frame = 0;
	end
	
	-- begin to dig up rock
	if v.ai2 == configFile.startwait + configFile.digwait then
		data.frame = 2;
		local xOffset = v.width - NPC.config[320].width + v.width * v.direction
		data.rockSpawner = Effect.spawn(configFile.rockemergeid, v.x + xOffset,v.y + v.height - Effect.config[configFile.rockemergeid][1].height)
	end
	
	-- snap rock spawner to position
	if (data.rockSpawner ~= nil) then
		local xOffset = v.width - NPC.config[320].width + v.width * v.direction
		data.rockSpawner.x = v.x + xOffset;
		data.rockSpawner.y = v.y + v.height - Effect.config[configFile.rockemergeid][1].height;
	end
	
	if v.ai2 == configFile.startwait + configFile.digwait + configFile.liftwait then
		data.frame = 3;
	end
	
	-- dig up rock
	if v.ai2 == configFile.startwait + configFile.digwait + configFile.liftwait + 2 and data.rockSpawner then
		data.frame = 4;
				
		local r = NPC.spawn(configFile.projectileid, data.rockSpawner.x, data.rockSpawner.y, v:mem(0x146,FIELD_WORD))
		r.y = v.y + v.height - 48
		r.speedX = configFile.rockxspeed * v.direction * NPC.config[320].speed;
		r.speedY = -math.abs(configFile.rockyspeed);
		r.friendly = v.friendly
		r.layerName = "Spawned NPCs"
		data.rockSpawner:kill()
	end
	
	-- wait after digging up
	if v.ai2 == configFile.startwait + configFile.digwait + configFile.liftwait + configFile.donewait then
		data.frame = 0;
		v.ai3 = v.ai3 + 1;
		
		-- if it's done w/ volley reset, otherwise go back
		if v.ai3 >= settings.volley then
			v.ai2 = -40;
			v.ai3 = 0;
		else
			v.ai2 = configFile.startwait;
		end
	end
end

function diggingChuck.onNPCKill(eventObj,v,killReason) 
	if v.id == npcID then
		local data = v.data._basegame
		if data.rockSpawner then
			data.rockSpawner:kill()
		end
	end
end

return diggingChuck;