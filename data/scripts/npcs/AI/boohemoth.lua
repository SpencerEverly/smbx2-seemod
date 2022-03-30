local boohemoth = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local particles = require("particles")
local rng = require("rng")
local pcl = require("npcs/ai/percamlimiter")

-- TODO:
-- Fix collision vertically
-- Test multiplayer camera edge cases (merging, diverging)
-- Implement multiplayer collision (only player camera's own boohemoth can hurt player)
-- Draw semitransparent for cameras that dont belong to you to indicate harmlessness
-- Test edge cases like coming out of block or generator
-- Figure out why the opacity doesnt work for frame 1 when gif recorder is on

local megashroom = require("npcs/ai/megashroom")

boohemoth.id = 444

local STATE = {INIT=1, APPEAR=2, DESPAWN = 3,APPROACH=4, HIDE=5, PEEK=6, SHUFFLE=7}
local poofParticles = Misc.resolveFile("particles/p_smoke_large.ini")

local states = {
	KILL = 0,
	R = 1,
	D = 2, 
	L = 3,
	U = 4
}

function boohemoth.setProperties(id)
	boohemoth.id = id
end

function boohemoth.register(id)
	npcManager.registerEvent(id,boohemoth,"onTickNPC")
	registerEvent(boohemoth,"onPostNPCKill")
	npcManager.registerEvent(id,boohemoth,"onCameraUpdateNPC")
	npcManager.registerEvent(id,boohemoth,"onCameraDrawNPC")
end

function boohemoth.onPostNPCKill(v, reason)
	if v.id == boohemoth.id then
		local npc = pcl.getNPC(v.data._basegame.cam.idx, boohemoth.id)
		if npc == v then
			pcl.getUnregisterNPC(v.data._basegame.cam.idx, boohemoth.id)
		end
	end
end

function boohemoth.spawn(cam, settings)
	local oldNPC = pcl.getNPC(cam.idx, boohemoth.id)
	if oldNPC and oldNPC.data._basegame.movementState ~= settings.state then
		local npc = pcl.getUnregisterNPC(cam.idx, boohemoth.id)
		if npc ~= nil and npc.isValid then
			npc.data._basegame.state = STATE.DESPAWN -- Little cute routine when he die
		end
	end
	if settings.state ~= states.KILL and pcl.isCamFree() then
		local section = Player.getNearest(cam.x + 0.5 * cam.width, cam.y + 0.5 * cam.height).section
		local x,y
		if settings.state == states.R then
			x = cam.x
			y = cam.y + 0.5 * cam.height
		elseif settings.state == states.L then
			x = cam.x + cam.width
			y = cam.y + 0.5 * cam.height
		elseif settings.state == states.U then
			x = cam.x + 0.5 * cam.width
			y = cam.y + cam.height
		elseif settings.state == states.D then
			x = cam.x + 0.5 * cam.width
			y = cam.y
		end
		local n = NPC.spawn(boohemoth.id, x, y, section, false, true)
		n.data._settings = settings
		n.data._basegame.state = STATE.INIT
		n.data._basegame.cam = cam
		n.data._basegame.movementState = settings.state
		pcl.registerNPC(cam.idx, n)
		npcutils.hideNPC(n)
	end
end

local function playerCollision(p, npc, data, settings)
	-- Player facing npc
	local playerLooking = (p.direction ~= npc.direction) or p:mem(0x50, FIELD_BOOL)
	local x1, x2 = p.x + 0.5 * p.width, npc.x + 0.5 * npc.width
	if data.movementState % 2 == 0 and data.movementState > 0 then
		playerLooking = (p.direction == 1 and x1 <= x2) or (p.direction == -1 and x1 > x2)
	end

	if  data.state >= STATE.APPROACH  and  not playerLooking  then
		data.state = STATE.APPROACH
		data.timer = 0
	end
	
	-- Player collision
	local playerOverlap = Colliders.collide (p, data.hitbox)
	if  not(npc.friendly  or  not data.solid)  and  playerOverlap then
		
		local normal = vector(0,0)
		if data.movementState == states.R then
			normal.x = 1
		elseif data.movementState == states.L then
			normal.x = -1
		elseif data.movementState == states.U then
			normal.y = -1
		else
			normal.y = 1
		end
		if normal.x == 0 and normal.y == 0 then
			normal.x = 1
			normal = normal:lookat(mid_npc.x,mid_npc.y)
			--normal = normal:rotate(180)
		end
		
		-- Move the player there and "bounce" them
		if normal.x ~= 0 then
			p.speedX = normal.x * settings.bounceStrength
		end
		if normal.y ~= 0 then
			p.speedY = normal.y * settings.bounceStrength
		end
		if p:isGroundTouching() and p.speedY > 0 then
			p.speedY = 0
		end
		
		-- Additional check for crush
		if player.deathTimer == 0 then
			if  (normal.x < 0  and  p:mem(0x148,FIELD_WORD) > 0)  or  (normal.x > 0  and  p:mem(0x14C,FIELD_WORD) > 0)  then
				if p.isMega then
					megashroom.StopMega(p,true)
				else
					p:harm()
				end
			else
				p:harm()
			end
		end
	end
	return playerLooking
end

function boohemoth.onTickNPC(npc)
	if Defines.levelFreeze then return end -- Maybe he should transcend this..?
	
		--Init
	local data = npc.data._basegame

	if data.state == nil then
		npc:transform(NPC.config[npc.id].spawnerID)
		return
	end
	
	if data.movementState < 3 then
		npc.direction = 1
	else
		npc.direction = -1
	end

	local x,y,speedX,speedY,width,height = "x", "y", "speedX", "speedY", "width", "height"
	if data.movementState % 2 == 0 then
		x,y,speedX,speedY,width,height = y,x,speedY,speedX,height,width
	end

	if  data.hitbox == nil  then --could be any data entry really, npcEventManager initializes _basegame as {}
		data.state  = STATE.INIT
		data.timer  = 0
		--data.effect = particles.Emitter(npc.x,npc.y,poofParticles)
		data.solid  = false --??
		data.hitbox = Colliders.Circle(0, 0, 0.43 * npc.width) 
		data.opacity = 0
		data.speed = 0
		data.squashTimer = 0
	end

	npc:mem(0x12A,FIELD_WORD, 180) --darned despawning
	
	-- STATE-INDEPENDENT BEHAVIOR
	--Update hitbox's position
	data.hitbox.x = npc.x + 0.5 * npc.width
	data.hitbox.y = npc.y + 0.5 * npc.height

	if not (camera.isSplit or camera2.isSplit) then
		data.cam = camera
	end
	--npc.y = npc:mem(0xB0, FIELD_DFLOAT)

	local settings = NPC.config[npc.id]

	local playerLooking = false

	local sectionIndex = npc:mem(0x146, FIELD_WORD)
	
	if camera.isSplit or camera2.isSplit then
		local p = Player.get(data.cam.idx)
		if p.section == sectionIndex then
			if playerCollision(p, npc, data, settings) then
				playerLooking = true
			end
		end
	else
		for k,p in ipairs(Player.get()) do
			if p.section == sectionIndex then
				if playerCollision(p, npc, data, settings) then
					playerLooking = true
				end
			end
		end
	end

	-- Update the timer
	data.timer = math.max(0, data.timer - 1)


	-- STATE-SPECIFIC BEHAVIOR
	if      (data.state == STATE.INIT)  then
		-- Stay invisible until the player is not colliding
		if  not playerOverlap  then
			data.state = STATE.APPEAR
			data.timer = lunatime.toTicks(1)
		end

	elseif  (data.state == STATE.APPEAR)  then
		-- Begin movement
		data.opacity = math.min(data.opacity + 0.025, 1)
		if  data.opacity == 1  then
			data.solid = true
			data.state = STATE.APPROACH
		end

	elseif  (data.state == STATE.APPROACH)  then
		-- Move forward
		data.speed = npc.direction * math.min(settings.speed, math.abs(data.speed) + 0.04 * settings.speed)
		data.opacity = math.min(data.opacity + 0.025, 1)

		if  playerLooking  then
			data.state = STATE.HIDE
			data.timer = lunatime.toTicks(settings.shyTime)
		else
			data.squashTimer = data.squashTimer + 1
		end

	elseif  (data.state == STATE.HIDE)  then
		
		data.opacity = math.max(data.opacity - 0.01, 0.7)
		data.speed = data.speed * 0.96

		-- Peek if the time runs out
		if  data.timer == 0  then
			data.state = STATE.PEEK
			data.timer = lunatime.toTicks(settings.peekTime)
		end

	elseif  (data.state == STATE.PEEK)  then
		data.opacity = math.min(data.opacity + 0.01, 0.9)
		data.speed = data.speed * 0.96
		-- Start shuffling forward if the time runs out
		if  data.timer == 0  then
			data.state = STATE.SHUFFLE
		end

	elseif  (data.state == STATE.DESPAWN)  then
		data.opacity = data.opacity - 0.02
		data.speed = 0
		if data.opacity <= 0 then
			npc:kill(9)
		end
	elseif  (data.state == STATE.SHUFFLE)  then
		data.speed = npc.direction * math.min(settings.shufflespeedmultiplier * settings.speed, math.abs(data.speed) + 0.04 * settings.shufflespeedmultiplier * settings.speed)
		data.squashTimer = data.squashTimer + 0.5
	end
	--local section = Section(npc:mem(0x146,FIELD_WORD))
	--local bounds = section.boundary
	--local midX = npc.x
	--if npc.direction == DIR_RIGHT then
	--	midX = midX + npc.width
	--end
	--bounds.left  = 0.1 * (midX - data.cam.width/2) + 0.9 * bounds.left
	--bounds.right = 0.1 * (midX + data.cam.width/2) + 0.9 * bounds.right
	--section.boundary = bounds

	npc[speedX] = data.speed

	--Debug
	if settings.debug ~= 0 then
		data.hitbox:Draw()
	end
end

local function playerCameraLimit(p, data)
	p.x = math.clamp(p.x, data.cam.x, data.cam.x + data.cam.width - p.width)
	if p.deathTimer == 0 and p.y > data.cam.y + data.cam.height + 64 then
		p:kill()
	end
	p.y = math.clamp(p.y, data.cam.y - 64, data.cam.y + data.cam.height + 64)
end

function boohemoth.onCameraUpdateNPC(npc, camIdx)
	local data = npc.data._basegame
	if data.cam == nil then
		return
	end
	if camIdx ~= data.cam.idx then return end
	if data.hitbox == nil then return end
	
	-- Modifying the camera. This whole shtick doesn't work reliably in multiplayer yet, unfortunately. TODO: Fix split cams & camera merging/splitting
	if data.movementState == states.R then
		data.cam.x = npc.x + 0.5 * npc.width
		data.cam.y = npc.y + 0.5 * npc.height - 0.5 * data.cam.height
	elseif data.movementState == states.L then
		data.cam.x = npc.x + 0.5 * npc.width - data.cam.width
		data.cam.y = npc.y + 0.5 * npc.height - 0.5 * data.cam.height
	elseif data.movementState == states.U then
		data.cam.x = npc.x + 0.5 * npc.width - 0.5 * data.cam.width
		data.cam.y = npc.y + 0.5 * npc.height - data.cam.height
	elseif data.movementState == states.D then
		data.cam.x = npc.x + 0.5 * npc.width - 0.5 * data.cam.width
		data.cam.y = npc.y + 0.5 * npc.height
	end
	local sectionIndex = npc:mem(0x146, FIELD_WORD)
	local sec = Section(sectionIndex)
	data.cam.x = math.clamp(data.cam.x, sec.boundary.left, sec.boundary.right - data.cam.width)
	data.cam.y = math.clamp(data.cam.y, sec.boundary.top, sec.boundary.bottom - data.cam.height)

	if camera.isSplit or camera2.isSplit then
		local p = Player.get(data.cam.idx)
		if p.section == sectionIndex then
			playerCameraLimit(p, data)
		end
	else
		for k,p in ipairs(Player.get()) do
			if p.section == sectionIndex then
				playerCameraLimit(p, data)
			end
		end
	end
end

function boohemoth.onCameraDrawNPC(npc, camIdx)
	local data = npc.data._basegame
	npcutils.hideNPC(npc)
	if data.hitbox == nil or data.opacity <= 0 then 
		return
	end
	local opacity = 1
	if camIdx ~= data.cam.idx then
		opacity = 0.2
	end

	local frame = 0
	
	if  data.state ==  STATE.SHUFFLE  or  data.state == STATE.HIDE or data.state == STATE.DESPAWN then
		frame = 1
	elseif  data.state == STATE.PEEK  then
		frame = 2
	end

	local cfg = NPC.config[npc.id]
	
	if npc.direction > 0 then
		frame = frame + cfg.frames
	end

	local p = -45

	if cfg.foreground then
		p = -15
	end

	local w = 0.5*cfg.gfxwidth * (1 + math.sin(data.squashTimer * 0.02) * 0.025)
	local h = 0.5*cfg.gfxheight * (1 + math.cos(data.squashTimer * 0.02) * 0.025)

	local vt = {
		vector(-w, -h),
		vector(w, -h),
		vector(w, h),
		vector(-w, h),
	}

	local angle = math.sin(data.squashTimer * 0.025) * 2.5
	if data.movementState % 2 == 0 then
		angle = angle + 90
	end

	for k,n in ipairs(vt) do
		vt[k] = n:rotate(angle)
	end

	local totalFrames = cfg.frames
	if cfg.framestyle == 1 then
		totalFrames = cfg.frames * 2
	end

	local f = frame / totalFrames
	local f2 = (frame+1) / totalFrames

	local tx = {
		0, f,
		1, f,
		1, f2,
		0, f2
	}

	local x = npc.x + 0.5 * npc.width + cfg.gfxoffsetx
	local y = npc.y + 0.5 * npc.height + cfg.gfxoffsety + 12 * math.sin(data.squashTimer * 0.02)
	Graphics.glDraw{
		texture = Graphics.sprites.npc[npc.id].img,
		vertexCoords = {
			x + vt[1].x, y + vt[1].y,
			x + vt[2].x, y + vt[2].y,
			x + vt[3].x, y + vt[3].y,
			x + vt[4].x, y + vt[4].y,
		},
		textureCoords = tx,
		primitive = Graphics.GL_TRIANGLE_FAN,
		priority = p,
		color = Color.white .. data.opacity * opacity,
		sceneCoords = true
	}
end

return boohemoth
