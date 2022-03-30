local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local dinoRhino = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

function dinoRhino.onInitAPI()
	npcManager.registerEvent(npcID, dinoRhino, "onTickEndNPC")
	registerEvent(dinoRhino, "onNPCKill", "onNPCKill", false)
end

-- DINO RHINO SETTINGS --
local dinoRhinoSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 66, 
	gfxoffsety = 2,
	width = 56, 
	height = 62, 
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	noyoshi=1,
	nofireball=1,
	noiceball=1,
	score = 4,
	blocknpc = 0,
	-- Custom
	turninterval = 40,
	dinotorchid = 382,
	isheavy = 1,
	health = 2
}

local configFile = npcManager.setNpcSettings(dinoRhinoSettings);

npcManager.registerHarmTypes(npcID, 	
{
	HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_SWORD,
	HARM_TYPE_LAVA
}, 
{[HARM_TYPE_JUMP]=10,
[HARM_TYPE_FROMBELOW]=188,
[HARM_TYPE_PROJECTILE_USED]=188,
[HARM_TYPE_NPC]=188,
[HARM_TYPE_HELD]=188,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

--*********************************************
--                                            *
--              DINO RHINOS                   *
--                                            *
--*********************************************

local function jumpOverBlocks(v, speed)
	local data = v.data._basegame
	-- locking midair direction
	if not v.collidesBlockBottom then
		if data.lockDirection ~= nil then
			v.direction = data.lockDirection;
		end
		
		data.frame = 1;
		v.ai2 = 0;
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
	if data.frame < 2 and v.ai1 < 240 then
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

-- DINO RHINOS
function dinoRhino.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	-- AI
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL) then
		data.exists = false
		return
	end
	
	-- Initializing
	if not data.exists then
		local data = v.data._basegame
		data.frame = 0;
		data.exists = true;
		data.lockDirection = v.direction;
		
		v.ai1 = 0 -- generic timer
		v.ai2 = 0 -- animation timer
	
		if v.direction == 0 then
			if v.x > Player.getNearest(v.x, v.y).x then
				v.direction = -1;
			else
				v.direction = 1;
			end
		end
	end
	
	-- follow player
	v.ai1 = v.ai1 + 1;
	
	if v.ai1 == configFile.turninterval then
		if v.x > Player.getNearest(v.x, v.y).x then
			v.direction = -1;
		else
			v.direction = 1;
		end
		v.ai1 = 0;
	end
	
	jumpOverBlocks(v, .85)
		
	v.speedX = .85 * v.direction;
	
	-- update frames
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames,
		direction = data.lockDirection or v.direction
	});
end

function dinoRhino.onNPCKill(eventObj, v, killReason)
	if v.id ~= npcID then return end;
	
	-- dino torch flame wiping
	local data = v.data._basegame;
	
	if killReason == 1 then
		local spawnDino = NPC.spawn(configFile.dinotorchid, v.x + (v.width/2), v.y + v.height - NPC.config[configFile.dinotorchid].height * 0.5,v:mem(0x146,FIELD_WORD), false, true)
		spawnDino.data._basegame = spawnDino.data._basegame or {}
		
		-- initialize npc here so it doesn't get overridden
		spawnDino.data._basegame.exists = true;
		spawnDino.data._basegame.frame = 0;
		spawnDino.data._basegame.lockDirection = v.direction;

		spawnDino.deathEventName = v.deathEventName
		spawnDino.noMoreObjInLayer = v.noMoreObjInLayer
		v.deathEventName = ""
		
		spawnDino.ai1 = 265; --generic timer
		spawnDino.ai2 = -1; --anim timer
		spawnDino.ai3 = 1; -- next fire breath
		
		-- pass on dino rhino's settings
		spawnDino.friendly = v.friendly
		spawnDino.dontMove = v.dontMove
		spawnDino.layerName = v.layerName
		spawnDino.direction = v.direction
		spawnDino.data._basegame.frame = 3;
		spawnDino.data._basegame.lockDirection = spawnDino.direction;
					
		spawnDino.speedX = 0;
	end
end

return dinoRhino;