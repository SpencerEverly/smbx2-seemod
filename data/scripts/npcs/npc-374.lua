local npcManager = require("npcManager")

local flurry = {}

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local npcID = NPC_ID;

function flurry.onInitAPI()
	npcManager.registerEvent(npcID, flurry, "onTickNPC", "onTickFlurry")
end


-- FLURRY SETTINGS --
local FlurryData = {}

FlurryData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxheight = 32, 
	gfxwidth = 32, 
	width = 32, 
	height = 32,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	jumphurt = 0, 
	nogravity = 0, 
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	grabtop = 1,
	playerblocktop = 1,
	npcblocktop = 1,
	iswalker = false,
	speed = 1
})

local harmTypes = {
	[HARM_TYPE_SWORD] = 242, 
	[HARM_TYPE_PROJECTILE_USED] = 242, 
	[HARM_TYPE_SPINJUMP] = 10, 
	[HARM_TYPE_TAIL] = 242, 
	[HARM_TYPE_JUMP] = 10, 
	[HARM_TYPE_FROMBELOW] = 242, 
	[HARM_TYPE_HELD] = 242, 
	[HARM_TYPE_NPC] = 242, 
	[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}
npcManager.registerHarmTypes(npcID, table.unmap(harmTypes), harmTypes)


--*********************************************
--                                            *
--              Flurrys                       *
--                                            *
--*********************************************

function flurry.onTickFlurry(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
		data.exists = nil
		return
	end
	-- AI
	if not data.exists then
		data.exists = 0;
		data.xAccel = v.direction;
		data.lockDirection = v.direction;
	end
	if v:mem(0x120, FIELD_BOOL) then
		data.lockDirection = -data.lockDirection
		data.xAccel = -data.xAccel
		return
	end

	local p = Player.getNearest(v.x, v.y)
	local pMidX = p.x + 0.5 * p.width
	local fMidX = v.x + v.width*0.5

	v.ai1 = (v.ai1 + 1)%60

	local shouldSlip = 0.025
	if  v.collidesBlockBottom  then
		shouldSlip = 0.05
		local x1,y1 = v.x,v.y+v.height+1
		local x2,y2 = x1+v.width,y1+1
		
		for  k,v in ipairs(Block.getIntersecting(x1,y1,x2,y2))  do
			if  v.slippery  then
				shouldSlip = 0.025
				break;
			end
		end
	end
	-- follow player on ice
	if  shouldSlip > 0 then
		if  pMidX < fMidX  then
			data.xAccel = data.xAccel-shouldSlip;
			if  math.abs(data.xAccel) < 0.75  or  data.xAccel < 0  then
				data.lockDirection = -1;
			end
		else
			data.xAccel = data.xAccel+shouldSlip;
			if  math.abs(data.xAccel) < 0.75  or  data.xAccel > 0  then
				data.lockDirection = 1;
			end
		end

		data.xAccel = math.max (math.min (data.xAccel, 1), -1);
	
		v.speedX = data.xAccel * FlurryData.config.speed * 3;
	
	-- Follow player on ground with good traction
	else
		if  v.ai1 == 0  then
			if  pMidX < fMidX then
				data.lockDirection = -1;
				data.xAccel = -1;
				v.speedX = FlurryData.config.speed*-3;
			else
				data.lockDirection = 1;
				data.xAccel = 1;
				v.speedX = FlurryData.config.speed*3;
			end
		end
	end
end



return flurry;