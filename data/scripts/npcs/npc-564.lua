local npcManager = require("npcManager")
local tantrunt = {}

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local npcID = NPC_ID;

function tantrunt.onInitAPI()
	npcManager.registerEvent(npcID, tantrunt, "onTickNPC", "onTickPig")
	npcManager.registerEvent(npcID, tantrunt, "onDrawNPC", "onDrawPig")
	registerEvent(tantrunt, "onNPCHarm", "onNPCHarm", false)
end

-- PIG SETTINGS --
local PigData = {}

PigData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 64, 
	gfxoffsety = 2,
	width = 42, 
	height = 50, 
	frames = 8,
	framespeed = 1, 
	framestyle = 1,
	score = 0,
	blocknpc = 0,
	noyoshi = true
	--lua only
	--death stuff
})

npcManager.registerHarmTypes(npcID,
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=275,
[HARM_TYPE_FROMBELOW]=275,
[HARM_TYPE_NPC]=275,
[HARM_TYPE_HELD]=275,
[HARM_TYPE_PROJECTILE_USED]=275,
[HARM_TYPE_TAIL]=275,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

local directionOffsetPig = {[-3]=0, [-2]=4, [-1]=0, [0]=0, [1]=8, [2]=12, [3]=8}

local moveState = {chase=0,charge=1,knockback=2};


--*********************************************
--                                            *
--              Pigs                       *
--                                            *
--*********************************************

function tantrunt.onTickPig(v)
	if Defines.levelFreeze then return end

	local basegame = v.data._basegame

	if  (v:mem(0x12A, FIELD_WORD) <= 0)  then
		basegame.exists = false
		return
	end

	if not basegame.exists then
		v.ai1 = 0
		basegame.forcedFrame = 0;
		basegame.exists = 0;
		basegame.lastX = v.x
		basegame.xAccel = 0;
		basegame.chargeDelay = 0;
		basegame.lockDirection = v.direction;
		if basegame.lockDirection == 0 then
			basegame.lockDirection = -1
		end
		basegame.destroyCollider = Colliders.Box(v.x-6,v.y+8,1,v.height-16);
	end

	local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	
	-- follow player
	if  (v.ai1 == moveState.chase)  then
		if  v.x + 0.5 * v.width > p.x + 0.5 * p.width then
			basegame.xAccel = basegame.xAccel-0.025;
			if  math.abs(basegame.xAccel) < 0.75  or  basegame.xAccel < 0  then
				basegame.lockDirection = -1;
			end
		else
			basegame.xAccel = basegame.xAccel+0.025;
			if  math.abs(basegame.xAccel) < 0.75  or  basegame.xAccel > 0  then
				basegame.lockDirection = 1;
			end
		end
		basegame.xAccel = math.max (math.min (basegame.xAccel, 1), -1);
		if  (v.collidesBlockLeft  or  v.collidesBlockRight) and v:mem(0x120, FIELD_BOOL)  then
			basegame.xAccel = -basegame.xAccel;
			v:mem(0x120, FIELD_BOOL, false)
		end
	end

	-- Knockback
	if  (v.ai1 == moveState.knockback)  then
		if  v.collidesBlockBottom  then
			v.ai1 = moveState.chase
		end
	end

	
	-- charge forward
	if  (v.ai1 == moveState.charge)  then
		v.ai3 = (v.ai3+1)%15
		if  (v.ai3 == 0)  then
			SFX.play(Misc.resolveSoundFile("pig-grunt"))
		end
		
		-- start charging after a delay
		v.ai4 = math.max(0, v.ai4-1)
		if  v.ai4 <= 0  then
			basegame.xAccel = basegame.xAccel+basegame.lockDirection*0.05;
		end
		basegame.xAccel = math.max (math.min (basegame.xAccel, 2), -2);
		

		-- Harm/kill weak enemies
		basegame.destroyCollider.x = v.x+v.speedX + 0.5 * v.width + 0.5 * v.width * v.direction;
		basegame.destroyCollider.y = v.y+8;
		
		--[[ THIS PART NEEDS TO BE UNCOMMENTED AND FINISHED
		local _, _, list = Colliders.collideNPC(basegame.destroyCollider,{})
		for _,v in ipairs(list) do
			if v.speedX ~= 0 then
				v:harm(HARM_TYPE_PROJECTILE_USED)
			end
		end
		--]]

		-- Break through blocks
		local brokeBlock = false
		local _, _, list = Colliders.collideBlock(basegame.destroyCollider,Block.MEGA_SMASH)
		for _,b in ipairs(list) do
			if not b.isHidden and b:mem(0x5A, FIELD_BOOL) == false then
				if v.speedX ~= 0 then
					if b.id == 667 then
						b:hit()
						brokeBlock = true
					else
						b:remove(true)
						brokeBlock = true
					end
				end
			end
		end

		if basegame.xAccel == 2 * basegame.lockDirection and
		(v.x > basegame.lastX + 4 and basegame.lockDirection == -1
		or v.x < basegame.lastX - 4 and basegame.lockDirection == 1) then
			basegame.xAccel = -basegame.lockDirection
			v.x = v.x - basegame.xAccel*2
			v.speedX = -2*basegame.xAccel
			
			v.y = v.y-1
			v.speedY = -4
			v.ai1 = moveState.knockback
		else

			-- Wall collision
			if  v:mem(0x120, FIELD_BOOL) and 
			    ((v.collidesBlockLeft   and  basegame.lockDirection == -1) or 
				(v.collidesBlockRight  and  basegame.lockDirection == 1))
			and  not brokeBlock  then
				basegame.xAccel = -basegame.lockDirection
				v.x = v.x - basegame.xAccel*2
				v.speedX = -2*basegame.xAccel
				
				v.y = v.y-1
				v.speedY = -4
				
				v.ai1 = moveState.knockback
				--Defines.earthquake = 10
				Misc.doPOW()
			end
		end
		basegame.lastX = v.x
	end

	if  (v.ai1 ~= moveState.knockback)  then
		v.speedX = basegame.xAccel * 4;
	end


	-- animation
	if  (v.ai1 ~= moveState.knockback)  then
		v.ai2 = (v.ai2+1)%(4 - math.floor (3 * (1-math.min (1, math.abs (basegame.xAccel)))))
		if  v.ai2 == 0  then
			basegame.forcedFrame = (basegame.forcedFrame+1)%4
		end
	else
		basegame.forcedFrame = 0
	end
end


function tantrunt.onDrawPig(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	local basegame = v.data._basegame
	if not basegame.exists then return end

	v.animationFrame = basegame.forcedFrame + directionOffsetPig[basegame.lockDirection*(v.ai1+1)];

end


function tantrunt.onNPCHarm(eventObj,npc,killReason, culprit)
	if npcID ~= npc.id or npc.isGenerator then return end
	
	local basegame = npc.data._basegame;

	if(basegame == nil) then
		return;
	end

	if  (killReason ~= HARM_TYPE_LAVA  and  killReason ~= HARM_TYPE_PROJECTILE_USED  and  killReason ~= HARM_TYPE_OFFSCREEN)  then
		eventObj.cancelled = true
		
		-- Destroy the held object
		if  (killReason == HARM_TYPE_NPC)  then
			--culprit:harm(HARM_TYPE_PROJECTILE_USED)
			-- add something here that forces the player to throw the object if it wasn't destroyed
		end
		
		if  npc.ai1 ~= moveState.charge
		and  (killReason ~= HARM_TYPE_FROMBELOW  or  (killReason == HARM_TYPE_FROMBELOW  and  culprit:mem(0x58, FIELD_WORD) == -1))
		then
			SFX.play(9)
			npc.ai1 = moveState.charge;
			npc.ai3 = -30
			npc.ai4 = 30
			basegame.xAccel = 0
			SFX.play(Misc.resolveSoundFile("pig-squeal.ogg"))
			if killReason == HARM_TYPE_SPINJUMP and type(culprit) == "Player" then
				Colliders.bounceResponse(culprit)
			end
		end
	end
end

return tantrunt;