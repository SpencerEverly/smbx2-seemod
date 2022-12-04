local npcManager = require("npcManager")

local springs = {}

-- Spring type.
springs.TYPE = {
}

--Index is type of tick function
springs.ids = {}

--- custom NPC config flags:
-- force (force applied on bounce)

local whitelists = {
}

local blacklists = {
}

function springs.liftOthers(v)
	for k,w in ipairs(NPC.getIntersecting(v.x, v.y - 4, v.x + v.width, v.y)) do
		if w ~= v and NPC.HITTABLE[w.id] then
			w.speedY = v.speedY
			springs.liftOthers(w)
		end
	end
end

function springs.verticalSpringValidityCheck(v, w)
	local cfg = NPC.config[w.id]
	return (
        w ~= v
        and (not blacklists[springs.TYPE.UP][w.id])
		and w.speedY > 0
        and ((cfg.nogravity == false and cfg.noblockcollision == false and w.noblockcollision == false)
            or (whitelists[springs.TYPE.UP][w.id]))
		and w.collidesBlockBottom == false
		and (not w.isHidden)
		and w:mem(0x64, FIELD_WORD) == 0
		and w:mem(0x12C, FIELD_WORD) == 0
        and w:mem(0x138, FIELD_WORD) == 0
	)
end

function springs.horizontalSpringValidityCheck(v, w)
	local cfg = NPC.config[w.id]
	return (
		w ~= v
        and (not blacklists[springs.TYPE.SIDE][w.id])
		and (not w.isHidden)
		and w:mem(0x64, FIELD_WORD) == 0
		and w:mem(0x12E, FIELD_WORD) < 30
        and ((cfg.noblockcollision == false and w.noblockcollision == false)
            or (whitelists[springs.TYPE.SIDE][w.id]))
		and w.speedX ~= 0
	)
end

function springs.bounceAI_up(v, data)
    local x = v.x
    local y = v.y
    local collisions = {}
    for k,w in ipairs(NPC.getIntersecting(x + 4, y - v.height - 2 * data.state, x + v.width - 4, y + 8)) do
        if springs.verticalSpringValidityCheck(v, w) then
            table.insert(collisions, w)
        end
    end
    local secondaryCollisions = Player.getIntersecting(x + 4, y - v.height - 2 * data.state, x + v.width - 4, y + 8)
    for _, w in ipairs(secondaryCollisions) do
        if (not w:isGroundTouching() and w:mem(0x13E, FIELD_WORD) == 0 and w.speedY > 0) then
            table.insert(collisions, w)
        end
    end
    for _,w in ipairs(collisions) do
        data.restoreTimer = 0
        if data.previousX[w] then
            if data.previousX[w] ~= math.huge then
                local ms = math.sign(data.previousX[w])
                if ms ~= 0 then
                    w.direction = ms
                else
                    w.direction = 1
                end
            end
        end
        if data.state < 2 then
            if w.__type == "NPC" then
                data.bouncingNPCEntitity = w.id
                w.speedY = -Defines.npc_grav + 0.01
            else
                w.speedY = -Defines.player_grav + 0.01
            end
            if not data.previousX[w] then
                data.previousX[w] = w.speedX
                if w.__type == "NPC" then
                    if w.dontMove or w.speedX == 0 then
                        data.previousX[w] = math.huge
                    end
                    w.dontMove = true
                end
            end
            w.speedX = 0
            data.timer = data.timer + 1
            data.state = 1.5
        elseif data.state == 2 and data.timer >= 4 and data.previousX[w] then
            if data.previousX[w] ~= math.huge then
                w.speedX = data.previousX[w]
                w.dontMove = false
            end
            w.y = v.y - w.height - 10
            w.speedY = - math.abs(NPC.config[v.id].force * 0.75)
            if w.__type == "Player" then
                data.timeTillBouncingIsFalse = 2
                if w.jumpKeyPressing or w.altJumpKeyPressing then
                    w.speedY = - math.abs(NPC.config[v.id].force)
                end
                w:mem(0x00, FIELD_BOOL, w.character == CHARACTER_TOAD and (w.powerup == 5 or w.powerup == 6)) -- Toad Doublejump
                w:mem(0x0E, FIELD_BOOL, false) -- Fairy already used?
                w:mem(0x18, FIELD_BOOL, w.character == CHARACTER_PEACH) -- Peach hover
                if data.timeTillBouncingIsFalse == 2 then
                    data.isBouncingPlayer = true
                elseif data.timeTillBouncingIsFalse <= 0 then
                    data.isBouncingPlayer = false
                end
            end
            SFX.play(24)
            data.previousX[w] = nil
            data.timer = 0
        end
        if (data.state == 1.5 and data.timer >= 4) or data.state ~= 1.5 then
            data.state = math.floor(data.state + 1)
        end
    end
    return collisions
end

function springs.bounceAI_side(v, data)
    local x = v.x
    local y = v.y
    local collisions = {}
    for k,w in ipairs(NPC.getIntersecting(x - 12 + 2 * data.state, y + 4, x + v.width + 12 - 2 * data.state, y + v.height - 4)) do
        if springs.horizontalSpringValidityCheck(v, w) then
            table.insert(collisions, w)
        end
    end
    local secondaryCollisions = Player.getIntersecting(x - 8, y + 4, x + v.width + 8, y + v.height - 4)
    for _, w in ipairs(secondaryCollisions) do
        if (w.deathTimer == 0) then
            table.insert(collisions, w)
        end
    end
    for _,w in ipairs(collisions) do
        local dirCalc = w.x + 0.5 * w.width > x + 0.5 * v.width
        
        local dir = -1
        
        if dirCalc then
            dir = 1
        end
        
        data.restoreTimer = 0
        if data.state == 2 then
            SFX.play(24)
            w.direction = dir
            w.speedX = 7 * dir
            if w.__type == "NPC" then
                data.bouncingNPCEntitity = w.id
                if NPC.config[w.id].nogravity == 0 or NPC.config[w.id].nogravity == false then
                    w.speedY = - math.abs(NPC.config[v.id].force)
                end
                if not NPC.SHELL_MAP[w.id] then
                    w.speedX = math.abs(NPC.config[v.id].force) * dir
                end
                --w:mem(0x136, FIELD_BOOL, true)
            end
        end
        data.state = data.state + 1
    end
    return collisions
end

local bounceAIFunctions = {
}

function springs.addType(name, func)
    springs.TYPE[name] = #whitelists + 1
    whitelists[springs.TYPE[name]] = {}
    blacklists[springs.TYPE[name]] = {}
    bounceAIFunctions[springs.TYPE[name]] = func
end

--defaults
springs.addType("UP", springs.bounceAI_up)
springs.addType("SIDE", springs.bounceAI_side)

function springs.whitelist(id, type)
    if type then
        whitelists[type][id] = true
    else
        for k,v in ipairs(whitelists) do
            v[id] = true
        end
    end
end

function springs.blacklist(id, type)
    if type then
        blacklists[type][id] = true
    else
        for k,v in ipairs(blacklists) do
            v[id] = true
        end
    end
end

function springs.register(id, type)
    if type == nil or type <= 0 or type > #whitelists then
        error("Must provide spring type when registering springs.")
        return
    end

    springs.ids[id] = type

	npcManager.registerEvent(id, springs, "onTickEndNPC")
end

function springs.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = 0
		data.restoreTimer = 0
		data.previousGrabPlayer = 0
		data.dropCooldown = 0
		data.timer = 0
        data.bouncingNPCEntitity = 0
        data.timeTillBouncingIsFalse = 0
        data.isBouncingPlayer = false
		data.previousX = {}
		return
	end
	
	if data.state == nil then
		data.state = 0
		data.restoreTimer = 0
		data.previousGrabPlayer = 0
		data.dropCooldown = 0
		data.timer = 0
        data.bouncingNPCEntitity = 0
        data.timeTillBouncingIsFalse = 0
        data.isBouncingPlayer = false
		data.previousX = {}
	end
    
    
    -- SMW-style throwing
	if data.previousGrabPlayer > 0 and v:mem(0x136, FIELD_WORD) == -1 then
		local p = Player(data.previousGrabPlayer)
		if p:mem(0x108, FIELD_WORD) == 0 then
			if p.upKeyPressing then
				v.speedX = p.speedX * 0.5
				v.speedY = - 12
			else
				if p:mem(0x12E, FIELD_WORD) ~= 0 or p.speedX == 0 or (not p.rightKeyPressing and not p.leftKeyPressing) then
					v.speedX = 0.5 * p.FacingDirection
					v.speedY = -0.5
				else
					v.speedY = 0
					v.speedX = 6 * p.FacingDirection + 0.5 * p.speedX
				end
			end
			data.dropCooldown = 16
		end
	end
	
	if v:mem(0x12C, FIELD_WORD) == 1 then
		v.collidesBlockBottom = false
	end
	
	if v.collidesBlockBottom then
		v.speedX = v.speedX * 0.5
    end
	
	data.previousGrabPlayer = v:mem(0x12C, FIELD_WORD)
	data.dropCooldown = data.dropCooldown - 1
    
    --
    
    -- Execute AI
    if data.previousGrabPlayer == 0 and data.dropCooldown <= 0 and data.state < 3 then
        local collisions = bounceAIFunctions[springs.ids[v.id]](v, data)
		if #collisions == 0 and data.state > 0 then
			data.restoreTimer = data.restoreTimer + 1
			if data.restoreTimer >= 8 then
				data.state = 0
			end
		end
	else
		data.restoreTimer = data.restoreTimer + 1
		if data.restoreTimer >= 4 then
			data.state = 0
		end
	end
	if data.state >= 1 then
		v.animationFrame = math.floor(data.state)%3
	end
    
    if data.timeTillBouncingIsFalse > 0 then
        data.timeTillBouncingIsFalse = data.timeTillBouncingIsFalse - 1
    end
    
	v.animationTimer = 0
end

return springs