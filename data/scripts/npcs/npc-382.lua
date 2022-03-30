local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rng = require("rng")

local dinoTorch = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local dinoTorchSettings = {
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 30, 
	height = 30, 
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	gfxoffsety = 2,
	score = 2,
	blocknpc = 0,
	-- Custom
	horzflamenpc = 384,
	vertflamenpc = 385,
	roamtime = 240,
	turninterval = 30
}

local configFile = npcManager.setNpcSettings(dinoTorchSettings);

npcManager.registerHarmTypes(npcID, 	
{
	HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_TAIL,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_SWORD,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_LAVA
}, 
{[HARM_TYPE_JUMP]=187,
[HARM_TYPE_FROMBELOW]=186,
[HARM_TYPE_NPC]=186,
[HARM_TYPE_HELD]=186,
[HARM_TYPE_TAIL]=186,
[HARM_TYPE_PROJECTILE_USED]=186,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- register functions
function dinoTorch.onInitAPI()
	npcManager.registerEvent(npcID, dinoTorch, "onTickEndNPC")
	registerEvent(dinoTorch, "onNPCKill", "onNPCKill", false)
end

--*********************************************
--                                            *
--                     AI                     *
--                                            *
--*********************************************

local function offsetFlameSide(v, flame)
	flame.x = v.x + 0.5 * v.width + (0.5 * (v.width + flame.width) * v.data._basegame.lockDirection) - 0.5 * flame.width
	flame.y = v.y + 0.5 * v.height - 0.5 * flame.height
end

local function offsetFlameUp(v, flame)
	flame.x = v.x + 0.5 * v.width - 0.5 * flame.width
	flame.y = v.y - flame.height
end

local function jumpOverBlocks(v, speed)
	local data = v.data._basegame
	
	-- locking midair direction
	if not v.collidesBlockBottom then
		if data.lockDirection ~= nil then
			v.direction = data.lockDirection;
		end
		
		data.frame = 1;
		v.ai2 = 0;
		
		v.ai1 = math.min(configFile.roamtime + 10, v.ai1)
		data.frame = 0
		return
	end
	
	if v.ai2 == 0 then
		v.ai2 = 4;
		data.lockDirection = nil;
	end

	-- jumpin
	if (v.direction == -1 and v.collidesBlockLeft) or (v.direction == 1 and v.collidesBlockRight) then
		-- calibrate right now so it doesn't get stuck up against the wall
		local tempdir;
		if v.x > Player.getNearest(v.x, v.y).x then
			tempdir = -1;
		else
			tempdir = 1;
		end
		
		if v.direction == tempdir then
			v.speedY = -7;
			data.lockDirection = v.direction;
		end
	end

	-- anime
	if data.frame < 2 and v.ai1 < configFile.roamtime then
		v.ai2 = v.ai2 + 1;
		if v.ai2 == 10 then
			if data.frame == 1 then
				data.frame = 0;
			else
				data.frame = 1;
			end
			v.ai2 = 1;
		end
	end
end

function dinoTorch.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	-- now exit out in case of bad situations
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL) then
		data.exists = false
		return
	end
	
	-- Initialize
	if not data.exists then
		v.ai1 = 0; --generic timer
		v.ai2 = 0; --anim timer
		v.ai3 = 0; --next breath. 0 = sideways, 1 = down
	
		local data = v.data._basegame
		data.frame = 0;
		data.exists = true;
		data.lockDirection = v.direction;
		data.offsetFunction = nil
	
		if v.direction == 0 then
			if v.x > Player.getNearest(v.x, v.y).x then
				v.direction = -1;
			else
				v.direction = 1;
			end
		end
	end
	
	-- Start running timer
	v.ai1 = v.ai1 + 1;
	
	-- face player every so often
	if (v.ai1 % configFile.turninterval == 0 and v.ai1 <= configFile.roamtime) then
		if v.x > Player.getNearest(v.x, v.y).x then
			v.direction = -1;
		else
			v.direction = 1;
		end
		v.ai3 = rng.randomInt(0,1);
	end
	
	-- stop and get ready to blow fire
	if v.ai1 == configFile.roamtime then
		v.ai2 = -1;
		data.frame = 1;
	end
	
	if v.ai1 == configFile.roamtime + 25 then
		--v.ai3 = v.ai5;
		data.lockDirection = v.direction
		data.frame = v.ai3 + 2
	end
	
	if v.ai1 == configFile.roamtime + 55 then
		-- creating the flame
		SFX.play(42);
		
		if v.ai3 == 1 then
			data.myFlame = NPC.spawn(configFile.vertflamenpc, v.x + 0.5 * v.width, v.y - NPC.config[configFile.vertflamenpc].height * 0.5, v:mem(0x146, FIELD_WORD), false, true)
			data.offsetFunction = offsetFlameUp
		else
			data.myFlame = NPC.spawn(configFile.horzflamenpc, v.x + 0.5 * v.width + (0.5 * (v.width + NPC.config[configFile.horzflamenpc].width) * data.lockDirection), v.y + 0.5 * v.height, v:mem(0x146, FIELD_WORD), false, true)
			data.offsetFunction = offsetFlameSide
		end
		data.myFlame.direction = data.lockDirection
		data.myFlame.layerName = "Spawned NPCs"
		data.myFlame.data._basegame.parent = v
		data.myFlame.friendly = true
		data.myFlame.frame = 0
		data.myFlame.data._basegame = { friendly = v.friendly }
	end

	if data.myFlame and data.myFlame.isValid and data.offsetFunction then
		data.offsetFunction(v, data.myFlame)
		data.myFlame.direction = data.lockDirection
	end
	
	-- after flame goes out, stop opening your mouth
	if v.ai1 == configFile.roamtime + 225 then
		data.frame = 1;
	end
	
	-- resetting after flame end
	if v.ai1 == configFile.roamtime + 240 then
		v.ai1 = math.max(0, configFile.roamtime - 121);
		data.lockDirection = nil
	end
	
	-- update direction properly
	if data.lockDirection then
		v.direction = data.lockDirection
	end
	
	-- jump over blocks (wow)
	if v.ai1 < configFile.roamtime + 25 then
		jumpOverBlocks(v, 1.75)
	end
	
	-- set speed
	if v.ai1 < configFile.roamtime then
		v.speedX = 1.75 * v.direction;
	else
		v.speedX = 0
	end
	
	-- animation updates
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames * 2,
		direction = data.lockDirection
	});
end

function dinoTorch.onNPCKill(eventObj, v, killReason)
	if v.id ~= npcID then return end;
	-- dino torch flame wiping
	local data = v.data._basegame
	
	if (data.myFlame == nil) then
		return;
	end
	
	if data.myFlame.isValid == true then
		data.myFlame:kill(9)
	end
end

return dinoTorch;