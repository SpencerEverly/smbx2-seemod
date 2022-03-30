local npcManager = require("npcManager")

local colliders = require("colliders")
local rng = require("rng")
local vectr = require("vectr")

local footballs = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local footballSettings = {
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 1,
	framestyle = 1,
	score = 3,
	luahandlesspeed=true,
	-- Custom
	lowheight = 4.5,
	mediumheight = 6,
	highheight = 9.5
}

local configFile = npcManager.setNpcSettings(footballSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]={id=175, speedX=0, speedY=0},
[HARM_TYPE_FROMBELOW]=175,
[HARM_TYPE_NPC]=175,
[HARM_TYPE_HELD]=175,
[HARM_TYPE_TAIL]=175,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- register functions
function footballs.onInitAPI()
	npcManager.registerEvent(npcID, footballs, "onTickEndNPC")
end

--*********************************************
--                                            *
--              FOOTBALL                      *
--                                            *
--*********************************************

local function blockFilter(a)
	return not (a.isHidden or a:mem(0x5A, FIELD_WORD) ~= 0 or Block.LAVA_MAP[a.id]);
end

local function findAndRemove(list, obj)
	for k,v in pairs(list) do
		if v == obj then
			table.remove(list, k)
			break
		end
	end
end

function footballs.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	-- reset + don't run the code if it's offscreen/grabbed/reserved
	if (v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0) then	
		v.ai1 = 1; -- next bounce speed
		v.ai2 = 0; -- AI value used for punting chucks holding the football
		v.ai3 = 0; -- AI value used as a timer to prevent swapping directions too fast
		return
	end	
	
	-- data initialize
	local data = v.data._basegame
	
	if (data.flip == nil) then
		data.flip = 0;
		data.forceFrame = 0;
		data.collider = colliders.Box(v.x, v.y, v.width, v.height + 2)
	end
	
	if (data.spdvec == nil) then
		data.spdvec = vector.v2(v.speedX, v.speedY);
	end
	
	-- decrement timer
	if (v.ai3 > 0) then
		v.ai3 = v.ai3 - 1;
	end
	
	-- collision code. run for your life
	data.collider.x = v.x;
	data.collider.y = v.y;
	
	local hitAblock,_,blockList = colliders.collideBlock(data.collider,colliders.BLOCK_SOLID..colliders.BLOCK_SEMISOLID..colliders.BLOCK_HURT..colliders.BLOCK_PLAYER, blockFilter)
	if not hitAblock then
		local tmpNPCList = NPC.getIntersecting(data.collider.x, data.collider.y, data.collider.x + data.collider.width, data.collider.y + data.collider.height)
		for k,n in ipairs(tmpNPCList) do
			if n ~= v then
				local configFile = NPC.config[n.id]
				if configFile.npcblocktop or configFile.playerblocktop then
					if (not n.isHidden) and n:mem(0x12A, FIELD_WORD) > 0 and n:mem(0x12C, FIELD_WORD) == 0 and n:mem(0x138, FIELD_WORD) == 0 and n:mem(0x64, FIELD_BOOL) == false then
						table.insert(blockList, n)
						hitAblock = true
					end
				end
			end
		end
	end

	if hitAblock and v.ai2 == 0 then
		local inNormal = nil;
		local success = nil;
		local pt = vectr.v2(v.x+(0.5*v.width),v.y+(0.5*v.height));
		local dir = vectr.down2*(v.height*0.5+32);
		repeat
			local p,_,n,o = colliders.raycast(pt,dir,blockList)
			if not p then
				break
			end
			if (n.x ~= 0 or n.y ~= 0) then 
				inNormal = n; 
				success = p
			else
				findAndRemove(blockList, o);
			end
		until (inNormal ~= nil or #blockList == 0);
				
		if (not success) and #blockList > 0 then
			local success1,pt1,n1,_ = colliders.raycast(pt-vectr.v2(v.width*0.5,0),dir,blockList)
				
			local success2,pt2,n2,_ = colliders.raycast(pt+vectr.v2(v.width*0.5,0),dir,blockList)
				
			success = success1 or success2;
					
			if (success1 and not success2) then
				inNormal = n1;
			elseif (success2 and not success1) then
				inNormal = n2;
			elseif (success1 and success2) then
				if (pt2.y < pt1.y) then
					inNormal = n2;
				else
					inNormal = n1;
				end
			end
		end
				
		if success and (inNormal.x ~= 0 or inNormal.y ~= 0) then
			if (v.ai3 == 0) then
				-- swap animation direction
				if data.flip == 1 then
					data.flip = 0;
				else
					data.flip = 1;
				end
				v.ai3 = 5;
			end
					
			local inDirection = vectr.v2(v.speedX,v.speedY)			
					
			-- Hacky workaround for vanilla physics overriding things
			if (v.speedX == 0 and v.speedY == 0) then
				inDirection = data.spdvec;
			end
				
			-- randomly choose football jump height
			v.ai1 = rng.randomInt(1,3);
					
			local choice;
			if (v.ai1 == 1) then
				choice = -math.abs(configFile.lowheight);
			elseif (v.ai1 == 2) then
				choice = -math.abs(configFile.mediumheight);
			else
				choice = -math.abs(configFile.highheight);
			end
					
			-- apply vector
			local Result = inDirection - 2 * inDirection:project(inNormal)
					
			local spdvec = vectr.v2(math.clamp(Result.x, -3.5*NPC.config[npcID].speed, 3.5*NPC.config[npcID].speed), choice)
			v.speedX,v.speedY = spdvec.x,spdvec.y;
		end
	end
	
	-- ai2 garbage
	if v.ai2 == 1 then
		v.speedY = v.speedY - Defines.npc_grav;
	end

	if v.animationTimer == 0 then
		data.forceFrame = (data.forceFrame + 1) % configFile.frames
	end
	
	data.spdvec.x = v.speedX;
	data.spdvec.y = v.speedY;
	
	v.animationFrame = (data.flip * configFile.frames) + data.forceFrame;
end

return footballs;