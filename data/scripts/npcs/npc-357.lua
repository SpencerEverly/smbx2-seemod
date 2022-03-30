local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local goldenBowserStatue = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local goldenBowserStatueSettings = {
	id = npcID, 
	gfxwidth = 48, 
	gfxheight = 60, 
	width = 32, 
	height = 32, 
	jumphurt = 1,
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	noiceball=1,
	gfxoffsety=2,
	score = 0,
	noyoshi = true,
	spinjumpsafe = true,
	-- Custom
	jumpinterval = 30,
	isheavy = 2
}

local configFile = npcManager.setNpcSettings(goldenBowserStatueSettings);

npcManager.registerHarmTypes(
	npcID, 	
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_PROJECTILE_USED
	}, 
	{
		[HARM_TYPE_PROJECTILE_USED] = 166,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

-- function registering
function goldenBowserStatue.onInitAPI()
	npcManager.registerEvent(npcID, goldenBowserStatue, "onTickEndNPC")
end

-- general direction table
local directionOffset = {}

directionOffset[-1] = 0;
directionOffset[0] = 0;
directionOffset[1] = 2;

--*********************************************
--                                            *
--                    AI                      * 
--                                            *
--*********************************************

function goldenBowserStatue.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if data.timer == nil then
		data.timer = 0
	end
	
	-- reset if offscreen
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
		data.timer = 0; -- generic timer
		return
	end
	
	-- reset jump
	if v.collidesBlockBottom then
		data.timer = data.timer + 1;
		v.speedX = 0;
	end
	
	if data.timer >= configFile.jumpInterval then
		v.y = v.y - 4;
		v.speedY = -6.5;
		
		local target = player
		local closestDist = math.huge

		for  _,v2 in ipairs(Player.get())  do
			local dist = math.sqrt((v.x - v2.x) * (v.x - v2.x) + (v.y - v2.y) * (v.y - v2.y))
			if  dist < closestDist  then
				target = v2
				closestDist = dist
			end
		end
		if (target.x < v.x) then
			v.direction = -1
		else
			v.direction = 1
		end
		
		v.speedX = 1.85 * v.direction;
		
		data.timer = -20;
	end
	
	-- animation
	local i = 0
	if not v.collidesBlockBottom then i = 1 end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = i;
		frames = configFile.frames
	});
	
	--[[if (v.collidesBlockBottom) then
		v.animationFrame = directionOffset[v.direction];
	else
		v.animationFrame = 1 + directionOffset[v.direction];
	end]]--
end

return goldenBowserStatue;