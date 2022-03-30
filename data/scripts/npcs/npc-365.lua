-- spike.lua
-- Written by Saturnyoshi

----- Spike (NPC 365)
-- ai2 - State (0 - just spawned, 1 - walking, 2 - throwing)
---- STATE 0
-- ai1 - Timer between turns
-- ai3 - Timer between shots
---- STATE 1
-- ai1 - Throwing timer
-- ai3 - Throwing animation
-- ai4 - Displayed ball Y offset

---- Spike's Ball (NPC 334)

local npcManager = require("npcManager")

local spike = {}
local npcID = NPC_ID

local spikeSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 28,
	height = 28,
	gfxoffsety=2,
	frames = 2,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=0,
	noiceball=0,
	noyoshi=0,
	speed = 1,
	needsvision = true,
	spawnid = 366
}

npcManager.registerHarmTypes(
	npcID, 
	{
		HARM_TYPE_SWORD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_TAIL,
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA
	}, {
		[HARM_TYPE_SWORD]=10,
		[HARM_TYPE_PROJECTILE_USED]=181,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_TAIL]=181,
		[HARM_TYPE_JUMP]={id=181,speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]=181,
		[HARM_TYPE_HELD]=181,
		[HARM_TYPE_NPC]=181,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings(spikeSettings)

local spikeFrameIndex  = {0 ,1 ,0 ,2 }

function spike.onInitAPI()
	npcManager.registerEvent(npcID, spike, "onTickEndNPC", "onTickEndSpike")
	npcManager.registerEvent(npcID, spike, "onDrawNPC")
end

function spike.onTickEndSpike(v)
	if Defines.levelFreeze then return end
	
	
	if v:mem(0x12A, FIELD_WORD) <= 0
	or v:mem(0x138, FIELD_WORD) > 0
	or v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL) then return end
	
	
	----------------------------------------- STATE 0: Just spawned
	if v.ai2 == 0 then
		v.ai1=65
		v.ai3=97
		v.ai2=1
		if v.direction == 0 then
			if math.random() <= 0.5 then
				v.direction = 1
			else
				v.direction = -1
			end
		end
		if v.speedX == 0 then
			v.speedX = v.direction * NPC.config[v.id].speed
		end
		----------------------------------------- STATE 1: Follow
	elseif v.ai2 == 1 then
		-- Turn timer ran out
		if v.ai1 == 0 then

			local myplayer=Player.getNearest(v.x,v.y)
			
			-- Turn
			local lastdirection=v.direction
			if math.abs(v.x-myplayer.x) < 512 and math.abs(v.y-myplayer.y) < 256 then
				if v.x < myplayer.x then
					v.direction = 1
				else
					v.direction = -1
				end
			end
			
			-- Reset timer
			if v.direction == lastdirection then
				v.ai1=4
			else
				if math.random() <= 0.75 then
					v.ai1=16
				else
					v.ai1=130
				end
			end
		else
			-- Decrease timer
			v.ai1=v.ai1 - 1
		end
		
		-- Fire timer ran out
		if v.ai3 == 0 then
			local myplayer=Player.getNearest(v.x,v.y)
			local cfg = NPC.config[v.id]
			-- Check if able to fire
			if (cfg.needsvision and math.min(math.max(myplayer.x-v.x,-1),1) == v.direction and math.abs(v.x-myplayer.x) < 512 and math.abs(v.y-myplayer.y) < 69) or (not cfg.needsvision) then
				v.ai2=2
				v.ai1=60
				v.ai3=0
				v.ai4=0
				SFX.play(23)
				
			else
				if math.random() < 0.75 then
					v.ai3=120
				else
					v.ai3=80
				end
			end
		else
			-- Decrease timer
			v.ai3=v.ai3- 1
		end
		if math.abs(v.speedX) > NPC.config[v.id].speed then
			if v.speedX > 0 then
				v.speedX = v.speedX - 0.2
			else
				v.speedX = v.speedX + 0.2
			end
		else
			v.speedX = v.direction * NPC.config[v.id].speed
		end
		
		----------------------------------------- STATE 2: Throwing
	elseif v.ai2 == 2 then
		v.speedX=0
		v.ai3=v.ai3 + 1
		if v.ai3 > 16 then
			if v.ai3 >= 40 then
				if v.ai3 == 40 then
					v.ai4=v.ai4-1
				end
				
				if v.ai4 > v.height/2.5 then 
					-- Lower the ball (until it's directly above the spike).
					
					v.ai4 = v.ai4 - (16 - v.ai4) / 8
				end
			else
				-- Raise the ball.
				
				v.ai4 = v.ai4 + (16 - v.ai4) / 8
			end
		end
		if v.ai1 == 0 then
			v.ai2=1
			v.ai1=60 
			v.ai3=65
			-- Shoot
			local newSpikeBall=NPC.spawn(NPC.config[v.id].spawnid, v.x+2, v.y-30, 0)
			newSpikeBall.direction=v.direction
			newSpikeBall.friendly=v.friendly
			newSpikeBall.layerName = "Spawned NPCs"
			SFX.play(25)
		else
			v.ai1=v.ai1 - 1
		end
	end
end

function spike.onDrawNPC(v)
	----- SPIKE THROW ANIMATION
	if v.ai2 == 2 then
		-- Logic for drawing the ball as it's being pulled out of the Spike's mouth.
		
		local drawyoffset=0 -- Offset upward relative to the spike the ball will be drawn.
		local drawxoffset=0 -- Offset rightward relative to the spike the ball will be drawn.
		
		-- Spike's current animation frame during the throwing process (goes in the order 0, 1, 0, 2, changes every 10
		-- ticks since v.ai3 is just the number of frames the spike is in the throwing state).
		
		local frame=spikeFrameIndex[math.min(math.floor(v.ai3/10)+1,4)]
		
		-- v.ai4 is a timer measuring the current y-offset of the ball - where the actual offset is measured by
		-- taking this value and multiplying by 2.5, so the offset changes by 2.5 pixels per tick.
		
		drawyoffset = v.ai4*2.5
		
		-- From 53 to 57 ticks after the spike enters the throwing state, we move the ball opposite the direction it's
		-- facing by four pixels each tick.
		
		if v.ai3 > 53 then
			drawxoffset=16-math.abs(v.ai3-57)*4
		end
		local frameoffset=0
		if v.direction == 1 then
			frameoffset = 3
			drawxoffset = -drawxoffset
		end
		
		-- And we compute the animation frame by advancing through the normal walking sprites in each direction,
		-- selecting the proper throwing sprite (based on the value of frame, computed above) and perform an
		-- additional offset to account for direction, if necessary.
		
		local cfg = NPC.config[v.id]
		v.animationFrame=cfg.frames*2+frameoffset+frame
		
		-- Then just draw it.
		
		local p = -46
		local cfg2 = NPC.config[cfg.spawnid]
		
		if cfg2.foreground then
			p = -16
		end
		
		Graphics.drawImageToSceneWP(Graphics.sprites.npc[cfg.spawnid].img, v.x+drawxoffset+cfg2.gfxoffsetx, v.y-drawyoffset+cfg2.gfxoffsety, 0, 0, cfg2.gfxwidth, cfg2.gfxheight, p)
	end 
end


return spike