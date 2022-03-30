local npcManager = require("npcManager")

local panser = {}

panser.ids = {}

function panser.register(id)
    panser.ids[id] = true
	npcManager.registerEvent(id, panser, "onTickEndNPC")
end


function panser.onTickEndNPC(v)
    if Defines.levelFreeze then return end
	-- Do not update the panser's behavior if
	if  v:mem(0x12A,FIELD_WORD) <= 0 -- it is currently offscreen despawned
	or  v:mem(0x138, FIELD_WORD) > 0 -- it is contained within another NPC
    then
        v.data._basegame.initialized = nil
		return;
	end

	--Local variable for data
	local data = v.data._basegame

	-- Initialize the data if it doesn't exist yet
	if data.initialized == nil then
		data.openTimer=0
		data.animFlip=false
		data.turnTimer=0
		data.fireTimer=15
		data.timesFired=1
		data.speedX=0
		data.startedFriendly=v.friendly
		data.initialized=true
	end

	-- Shorthand state check flags
	local isHeld = (v:mem(0x12C, FIELD_WORD) > 0)
	local isThrown = v:mem(0x136, FIELD_BOOL) and not isHeld

	-- Control friendly flag
	--[[
	v.friendly = v.data.panser.startedFriendly
	if  v:mem(0x12C, FIELD_WORD) > 0  then
		v.friendly = true
	end
	--]]

	-- Determine the target
	local target = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
    local targetIsLeft = (target.x + 0.5 * target.width < v.x + 0.5 * v.width)
    
    local config = NPC.config[v.id]

	-- When the fire timer reaches 0, spit a fireball
	if  data.fireTimer == 0  then
		if  isThrown  then
			data.fireTimer = 5
		else
			local fireball = NPC.spawn(config.projectileid, v.x+v.width*0.5, v.y+4, target.section, false, true)
			SFX.play(16)
			fireball.friendly = v.friendly
			fireball.layerName = "Spawned NPCs"
			fireball.data._basegame = fireball.data._basegame or {}
			fireball.data._basegame.ally = isHeld

			fireball.speedY = config.shotspeedy * -1
			fireball.speedX = config.shotspeedx * 2
			if  targetIsLeft  then  fireball.speedX = fireball.speedX * -1;  end;
			fireball.speedX = fireball.speedX + v.speedX *0.5

			if  isHeld  then
				if  targetIsLeft  then
					fireball.x = fireball.x + 8
				else
					fireball.x = fireball.x - 8
				end
				fireball.y = fireball.y - 8
				fireball.speedX = fireball.speedX * -1
				fireball.speedX = fireball.speedX + target.speedX

				fireball:mem(0x12C, FIELD_WORD, -1)
				--fireball:mem(0x136, FIELD_BOOL, true)
			end
		end

		-- Determine the next delay based on how many were fired in a row
		data.timesFired = data.timesFired + 1

		data.openTimer = config.firetime+1
		if  data.timesFired == config.shots  then
			data.timesFired = 0
			data.fireTimer = config.reloadtime
		else
			data.fireTimer = config.firetime
		end
	end

	-- When the turn timer reaches 0, change movement speed variable
	if  data.turnTimer == 0  and  config.turntime ~= 0  then
		if  isThrown  then  
			data.turnTimer = 2
		else
            data.turnTimer = config.turntime
			data.speedX = config.speedx

			if  targetIsLeft  then
				data.speedX = data.speedX * -1
			end
			v.speedX = data.speedX
		end
	end

	-- Update the timers
	data.turnTimer = data.turnTimer - 1
	data.fireTimer = data.fireTimer - 1
	data.openTimer = data.openTimer - 1

	-- Update the animation
	if  v.animationTimer == 0  then
		data.animFlip = not data.animFlip
	end

	if  data.openTimer <= 0  then
		if  data.animFlip  then
			v.animationFrame = 0
		else
			v.animationFrame = 1
		end
	else
		v.animationFrame = 2
	end
end


return panser