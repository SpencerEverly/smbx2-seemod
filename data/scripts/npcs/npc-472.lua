local rng = require("rng")
local npcManager = require("npcManager")

local waddledoo = {}

local npcID = NPC_ID

npcManager.setNpcSettings{
	id = npcID,
	width = 32,
	height = 32,
	framestyle = 1,
	frames = 2,
	framespeed = 8,
	speed = 1,
	-- ultra-configurable beam stuff!
	beamlength = 4,
	beamanglestart = 30,
	beamangleend = 150,
	walktime = 240,
	chargetime = 60,
	beamtime = 80,
	sparkspawndelay = 0.3,
	sparkkilldelay = 0.1,
	sparkid = 473
}

npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_PROJECTILE_USED}, 
	{
		[HARM_TYPE_FROMBELOW] = 258,
		[HARM_TYPE_NPC] = 258,
		[HARM_TYPE_HELD] = 258,
		[HARM_TYPE_JUMP] = {id=258, speedX=0, speedY=0},
		[HARM_TYPE_TAIL] = 258,
		[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_PROJECTILE_USED] = 258
	}
)

--Waddle Doo States
local STATE_WALK = 0
local STATE_CHARGE = 1
local STATE_BEAM = 2

local sfx_beamstart = Misc.resolveSoundFile("doo-beam-start")
local sfx_beamloop = Misc.resolveSoundFile("doo-beam")

local loopingSounds = {}

function waddledoo.onInitAPI()
	registerEvent(waddledoo, "onNPCHarm")
	npcManager.registerEvent(npcID, waddledoo, "onTickNPC", "onTickDoo")
	npcManager.registerEvent(npcID, waddledoo, "onDrawNPC", "onDrawDoo")
	npcManager.registerEvent(npcID, waddledoo, "onDrawEndNPC", "onDrawEndDoo")
end

function waddledoo.onNPCHarm(eventObj, killedNPC, killReason)
	if killedNPC.id == npcID then
		local data = killedNPC.data._basegame
		if data and data.sparkList then
			for _,v in ipairs(data.sparkList) do
				v:kill()
			end
		end
	end
end

-- Doo Functions & Events

local function initDoo(v)
	local data = v.data._basegame
	data.state = STATE_WALK
	data.stateTimer = 0
	data.sparkCooldown = 0
	data.sparkList = {}
	data.hasBeenHeld = false
	data.sparkOffset = 0
end

local function getBeamPos(v, step, angle)
	local bv = vector(0, step*-32 + NPC.config[v.id].height/2):rotate(angle)
	return {x = (bv.x+16)*v.direction + (v.x + v.width/2) + v.speedX, y = bv.y + (v.y + v.height/2) + v.speedY}
end

local function changeState(v, newState)
	local data = v.data._basegame
	data.stateTimer = 0
	data.state = newState
	data.sparkCooldown = 0
	data.sparkOffset = 0
	if newState ~= STATE_BEAM then
		for i=#data.sparkList, 1, -1 do
			if data.sparkList[i].isValid then
				data.sparkList[i]:kill()
			end
		end
		data.sparkList = {}
		if data.sound and data.sound.isValid and data.sound:isPlaying() then data.sound:Stop() end
		data.sound = nil
	end
end

local function harmEnemies(v, sparp)
	if v:mem(0x12E, FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK then
		sparp.friendly = true
		
		for _,n in ipairs(Colliders.getColliding{a=sparp, b=NPC.HITTABLE, btype=Colliders.NPC}) do
			if (not n.friendly) and (not n.isHidden) and (n.id ~= sparp.id) and (n.idx ~= v.idx) and (Colliders.collide(sparp, n)) then
				n:harm(HARM_TYPE_NPC)
			end
		end
	else
		sparp.friendly = false
	end
end

function waddledoo.onTickDoo(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	
	if data.state == nil then
		initDoo(v)
	end

	local cfg = NPC.config[v.id]
	
	-- when he despawns or isn't gonna hurt you
	if v:mem(0x12A, FIELD_WORD) <= 0 or v.friendly or v.isHidden then
		changeState(v, STATE_WALK)
		
	--when he's coming out of a block
	elseif v:mem(0x138, FIELD_WORD) == 1 or v:mem(0x138, FIELD_WORD) == 3 then
		if not data.OOBDirPicked then
			v.direction = rng.randomInt(0,1)*2-1
			data.OOBDirPicked = true
		end
		
	--when he's not in the reserve box
	elseif v:mem(0x138, FIELD_WORD) == 0 then
		if v:mem(0x12E, FIELD_WORD) == 30 then
			data.hasBeenHeld = true
		elseif data.hasBeenHeld then
			v:harm()
			return
		end
		
		if data.state == STATE_WALK then
			if (data.stateTimer >= cfg.walktime and v.collidesBlockBottom) or (v:mem(0x12E,FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK) then
				changeState(v, STATE_CHARGE)
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and v.speedX ~= cfg.speed then
				if v.speedX == 0 then
					v.speedX = v.direction * cfg.speed
				elseif math.abs(v.speedX) > cfg.speed then
					v.speedX = v.speedX * 0.9
					if math.abs(v.speedX) < cfg.speed then
						v.speedX = v.direction * cfg.speed
					end
				else
					v.speedX = v.speedX * 1.25
					if math.abs(v.speedX) > cfg.speed then
						v.speedX = v.direction * cfg.speed
					end
				end
			end
			
		elseif data.state == STATE_CHARGE then
			v.animationTimer = v.animationTimer + 1
		
			if v:mem(0x132, FIELD_WORD) == 0 then
				v.x = v.x - v.speedX -- make him not walk
			end

			local ct = cfg.chargetime
			
			if data.stateTimer >= ct * math.clamp(1-cfg.sparkspawndelay, 0, 1) then
				if data.sound == nil then
					data.sound = SFX.play(sfx_beamstart)
					table.insert(loopingSounds, {source=v, effect=data.sound})
				end
				local isFriendly = v:mem(0x12E, FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK

				if data.sparkCooldown > 0 then
					data.sparkCooldown = data.sparkCooldown - 1
				else
					--spawn in the sparks
					while data.sparkCooldown <= 0 and #data.sparkList < cfg.beamlength do
						local i = #data.sparkList + 1
						local bp = getBeamPos(v, i, cfg.beamanglestart)
						local shiny = NPC.spawn(cfg.sparkid, bp.x, bp.y, v:mem(0x146, FIELD_WORD), false, true)
						shiny.data._basegame.parent = v
						shiny.layerName = "Spawned NPCs"
						if isFriendly then
							shiny.friendly = true
						end
						data.sparkList[i] = shiny;
						data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkspawndelay, 0, 1) / (cfg.beamlength+1)
					end
				end

				for i, sparp in ipairs(data.sparkList) do
					i = i + data.sparkOffset
					if sparp.isValid then
						local bp = getBeamPos(v, i, cfg.beamanglestart)
						sparp.x = bp.x - sparp.width/2 + rng.randomInt(-2,2) -- this'll be so much beter with centerx and centery
						sparp.y = bp.y - sparp.height/2 + rng.randomInt(-2,2)
						
						-- when he's your bestest friend
						harmEnemies(v, sparp)
					end
				end
			end
		
			if data.stateTimer >= cfg.chargetime then
				changeState(v, STATE_BEAM)
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			
		elseif data.state == STATE_BEAM then	
			v.animationTimer = v.animationTimer + 1
			
			if v:mem(0x132, FIELD_WORD) == 0 then
				v.speedX = 0
			end
			
			if data.stateTimer >= cfg.beamtime then
				if v:mem(0x12E,FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK then
					changeState(v, STATE_CHARGE)
				else
					changeState(v, STATE_WALK)
				end
			else
				
				for i, sparp in ipairs(data.sparkList) do
					i = i + data.sparkOffset
					if sparp.isValid then
						local bp = getBeamPos(v, i, cfg.beamanglestart + (data.stateTimer/cfg.beamtime)*(cfg.beamangleend-cfg.beamanglestart) - 2*(i*((1+data.stateTimer)/(cfg.beamtime*0.8))))
						sparp.x = bp.x - sparp.width/2 + rng.randomInt(-2,2) -- this'll be so much beter with centerx and centery
						sparp.y = bp.y - sparp.height/2 + rng.randomInt(-2,2)
						
						-- when he's your bestest friend
						harmEnemies(v, sparp)
					end
				end
				local ct = cfg.beamtime
			
				if data.stateTimer >= ct * math.clamp(1-cfg.sparkkilldelay, 0, 1) then
					if data.sparkCooldown <= 0 then
						while data.sparkCooldown <= 0 and #data.sparkList > 0 do
							--cleanup the sparks
							if data.sparkList[1].isValid then
								data.sparkList[1]:kill()
							end
							table.remove(data.sparkList, 1)
							data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkkilldelay, 0, 1) / (cfg.beamlength+1)
							data.sparkOffset = data.sparkOffset + 1
						end
					else
						data.sparkCooldown = data.sparkCooldown - 1
					end
				end
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end

			if data.sound and data.state ~= STATE_WALK and data.sound.isValid and not data.sound:isPlaying() then
				data.sound = SFX.play(sfx_beamloop)
			end
		end
		
		data.stateTimer = data.stateTimer + 1
	end
end

function waddledoo.onDrawDoo(v)
	local data = v.data._basegame
	
	if data.state == nil then
		initDoo(v)
	end

	if Misc.isPaused() and data.sound and data.sound.isValid and data.sound:isPlaying() then
		data.sound:Stop()
	end
	
	v.animationFrame = v.animationFrame + (data.state * NPC.config[v.id].frames * 2^NPC.config[v.id].framestyle)
end

function waddledoo.onDrawEndDoo(v)
	v.animationFrame = v.animationFrame % (NPC.config[v.id].frames * 2^NPC.config[v.id].framestyle)
end

return waddledoo