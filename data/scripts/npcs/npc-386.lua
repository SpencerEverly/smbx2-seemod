local npcManager = require("npcManager")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")
local whistle = require("npcs/ai/whistle")

local ripvanfish = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local STATE_SLEEP = 0;
local STATE_CHASE = 1;

local fishSettings = {
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 2,
	framespeed = 6, 
	framestyle = 1,
	score = 0,
	nogravity = 1,
	jumphurt = 1,
	nowaterphysics = 1,
	spinjumpsafe = 1,
	-- Custom
	radius = 128,
	speedcap = 2,
	accel = 0.02,
	fallspeed = 0.125,
	sleepframespeed = 50
}

npcManager.setNpcSettings(fishSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_FROMBELOW]=189,
[HARM_TYPE_NPC]=189,
[HARM_TYPE_HELD]=189,
[HARM_TYPE_TAIL]=189,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

function ripvanfish.onInitAPI()
	npcManager.registerEvent(npcID, ripvanfish, "onTickEndNPC")
end

--***************************************************************************************************
--                                                                                                  *
--              BEHAVIOR                                                                            *
--                                                                                                  *
--***************************************************************************************************

function ripvanfish.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	-- reset + don't run the code if it's offscreen/grabbed/reserved
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		v.ai1 = 0; --State. 0 = sleeping, 1 = chasing
		v.ai2 = v.animationTimer; --Animation timer
		v.ai3 = 360; --Go back to sleep
		v.ai4 = 40; --Effect timer
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = 2 * config.frames
		})
		return
	end
	
	local data = v.data._basegame
	
	if (data.forceFrame == nil) then
		data.forceFrame = 0;
		data.lockDirection = v.direction;
		data.detectCollider = colliders.Circle(v.x + 0.5 * v.width,v.y + 0.5 * v.height, config.radius)
	end

	-- DO THOSE ANIMATIONS YO!!!!!!!!!!!!!!!
	if v.ai2 > 0 then
		v.ai2 = v.ai2 - 1;
	end

	if v.ai2 == 0 then
		if v.ai1 == 1 then
			v.ai2 = config.framespeed;
		else
			v.ai2 = config.sleepframespeed
		end
		data.forceFrame = (data.forceFrame + 1) % config.frames
	end
	
	data.detectCollider.x = v.x + 0.5 * v.width;
	data.detectCollider.y = v.y + 0.5 * v.height;
	local p = npcutils.getNearestPlayer(v)

	-- Sleepy....
	if v.ai1 == STATE_SLEEP then
		-- detect player in range
		if colliders.collide(data.detectCollider, p) or whistle.getActive() then
			v.ai1 = STATE_CHASE;
			v.ai2 = 8;
			data.forceFrame = 0;
		end
		
		if v.speedX ~= 0 then
			if v.speedX > 0 then
				v.speedX = v.speedX - config.accel;
			elseif v.speedX < 0 then
				v.speedX = v.speedX + config.accel;
			end
		end
		
		if (v.speedX < 0.25 and v.speedX > -0.25) then
			v.direction = data.lockDirection;
		end
		
		if v.speedY > config.fallspeed then
			v.speedY = v.speedY - config.accel;
		elseif v.speedY < config.fallspeed then
			v.speedY = v.speedY + config.accel;
		end
		
		if not v.collidesBlockBottom and math.abs(v.speedY) < 0.2 then
			v.speedY = config.fallspeed;
		end
			
		-- zzzzzzzz........
		v.ai4 = v.ai4 + 1;
		
		if v.ai4 % 60 == 0 then
			local z = Effect.spawn(190, v.x + (v.width/3), v.y + (v.height/3))
			z.direction = v.direction;
		end
	elseif v.ai1 == STATE_CHASE then
		data.lockDirection = v.direction;
		local px = p.x + 0.5 * p.width
		local vx = v.x + 0.5 * v.width
		if px > vx then
			v.speedX = math.min(config.speedcap, v.speedX + config.accel);
		else
			v.speedX = math.max(-config.speedcap, v.speedX - config.accel);
		end
	
		if v.underwater then
			local vy = v.y + 0.5 * v.height
			local py = p.y + 0.5 * p.height
			if vy < py then
				v.speedY = math.min(config.speedcap, v.speedY + config.accel);
			else
				v.speedY = math.max(-config.speedcap, v.speedY - config.accel);
			end
		else
			v.speedY = 2;
		end
		
		v.ai3 = v.ai3 - 1;
		if v.ai3 <= 0 and not colliders.collide(data.detectCollider, p) then
			v.ai3 = 360;
			v.ai1 = 0;
			v.ai2 = 50;
			data.forceFrame = 0;
			data.lockDirection = v.direction;
		end
	end
	local shiftFramesBy = 0
	if v.ai1 == 1 then
		shiftFramesBy = config.frames
	end
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.forceFrame + shiftFramesBy,
		frames = config.frames * 2,
		direction = data.lockDirection
	});
	v.animationTimer = 0
end

return ripvanfish;