local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local springs = {}

-- Spring type.
springs.TYPE = {
}

--Index is type of tick function
springs.ids = {}

springs.isSpringingPlayer = {}
springs.isSpringingNPC = {}
for i = 1,NPC_MAX_ID do
    springs.isSpringingNPC[i] = false
end
for i = 1,200 do
    springs.isSpringingPlayer[i] = false
end

--- custom NPC config flags:
-- force (force applied on bounce)

local whitelists = {
}

local blacklists = {
}

local affectedEntityMap = {

}

local verticalBounceResponseMap = {}
local horizontalBounceResponseMap = {}

-- return false to cancel regular behaviour
function springs.registerVerticalBounceResponse(id, fun)
    verticalBounceResponseMap[id] = fun
end

-- return false to cancel regular behaviour
function springs.registerHorizontalBounceResponse(id, fun)
    horizontalBounceResponseMap[id] = fun
end

local function liftOthers(v)
	for k,w in NPC.iterateIntersecting(v.x, v.y - 4, v.x + v.width, v.y) do
		if w ~= v and NPC.HITTABLE[w.id] then
			w.speedY = v.speedY
			liftOthers(w)
		end
	end
end

local function upwardsSpringValidityCheck(v, w)
	local cfg = NPC.config[w.id]
	return (
        w ~= v
        and (not blacklists[springs.ids[v.id]][w.id])
		and (
            (w.y + w.height + w.speedY > v.y - (16 - 8 * v.data._basegame.state) + math.min(v.speedY, 0) and w.y + w.height < v.y + 8 and not (v.data._basegame.stalled and affectedEntityMap[w] == v))
            or
            (v.data._basegame.stalled and affectedEntityMap[w] == v and w.y + w.height + 2 > v.y))
        and (((cfg.nogravity == false or springs.ids[v.id] ~= springs.TYPE.UP) and cfg.noblockcollision == false and w.noblockcollision == false)
            or (whitelists[springs.ids[v.id]][w.id]))
		and (w.collidesBlockBottom == false or w.y + w.height < v.y)
		and (not w.isHidden)
		and w:mem(0x64, FIELD_WORD) == 0
		and w:mem(0x12C, FIELD_WORD) == 0
        and w:mem(0x138, FIELD_WORD) == 0
	)
end

local function downwardsSpringValidityCheck(v, w)
	local cfg = NPC.config[w.id]
	return (
        w ~= v
        and (not blacklists[springs.ids[v.id]][w.id])
		and w.speedY < v.speedY
        and ((cfg.nogravity == false and cfg.noblockcollision == false and w.noblockcollision == false)
            or (whitelists[springs.ids[v.id]][w.id]))
		and (not w.isHidden)
		and w:mem(0x64, FIELD_WORD) == 0
		and w:mem(0x12C, FIELD_WORD) == 0
        and w:mem(0x138, FIELD_WORD) == 0
	)
end

local function horizontalSpringValidityCheck(v, w)
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

local function forcePosition(v, w, data)

    if data.stalled then return end

    local fb = {}

    -- If we're hitting a ceiling, we should not phase through it.
    for k,b in Block.iterateIntersecting(v.x, v.y - w.height - v.speedY, v.x + v.width, v.y) do
        if (Block.SOLID_MAP[b.id] or Block.PLAYER[b.id]) and not b.isHidden and b:mem(0x5A, FIELD_BOOL) == false then
            table.insert(fb, b)
        end
    end

    if #fb > 0 then
        local a1, b1 = Colliders.linecast(vector(w.x, v.y), vector(w.x, v.y - w.height - v.speedY - 2), fb)
        local a2, b2 = Colliders.linecast(vector(w.x + w.width, v.y), vector(w.x + w.width, v.y - w.height - v.speedY - 2), fb)

        local blockY = -math.huge
        if b1 then
            blockY = b1.y
        end

        if b2 then
            blockY = math.max(blockY, b2.y)
        end

        if b1 or b2 then
            v.y = math.max(v.y, blockY + w.height + 2) + 2
            v.speedY = 0
        end
    end
    

    w.y = v.y - w.height - v.speedY
    if w.__type == "NPC" then
        w.speedY = -Defines.npc_grav + 0.5 + v.speedY
    else
        w.speedY = -Defines.player_grav + 0.5 + v.speedY
    end
end

local function passesRaycastChecks(w)
    local fb = {}

    -- If we're hitting a FLOOR, we should not phase through it.
    for k,b in Block.iterateIntersecting(w.x, w.y + w.height, w.x + w.width, w.y + w.speedY + w.height + 32) do
        if (Block.SOLID_MAP[b.id] or Block.SEMISOLID_MAP[b.id] or Block.PLAYER[b.id]) and not b.isHidden and b:mem(0x5A, FIELD_BOOL) == false and b.y >= w.y + w.height then
            table.insert(fb, b)
        end
    end

    for k,b in NPC.iterateIntersecting(w.x, w.y + w.height, w.x + w.width, w.y + w.speedY + w.height + 32) do
        if ((NPC.config[b.id].playerblocktop or NPC.config[b.id].npcblock or NPC.config[b.id].npcblocktop) and b:mem(0x12C, FIELD_WORD) == 0 and b.forcedState == 0 and b.isGenerator == false) and b.y >= w.y + w.height then
            table.insert(fb, b)
        end
    end

    if #fb > 0 then
        local a1 = Colliders.linecast(
            vector(w.x, w.y + w.height),
            vector(w.x, w.y + w.height + w.speedY + 2), fb)
        local a2 = Colliders.linecast(
            vector(w.x + w.width, w.y + w.height),
            vector(w.x + w.width, w.y + w.height + w.speedY + 2), fb)

        if a1 or a2 then
            return false
        end
    end

    return true
end

local function recursiveBounceUp(v, npcforce, rec)
    v.speedY = -(npcforce + 0.0001 * rec)
    if NPC.config[v.id].playerblocktop then
        for k,w in NPC.iterateIntersecting(v.x, v.y - 12, v.x + v.width, v.y) do
            if (w ~= v and w.y < v.y)
            and (w.collidesBlockBottom or w.speedY > 0)
            and (not w.isGenerator)
            and (not NPC.config[w.id].nogravity)
            and (not (w.noblockcollision or NPC.config[w.id].noblockcollision))
            and (w.forcedState == 0)
            and (w:mem(0x12C, FIELD_WORD) == 0)
            and (not w.isHidden)
            then
                recursiveBounceUp(w, npcforce, rec + 1)
            end
        end
    end
end

local function bounceAI_up(v, data)
    local x = v.x
    local y = v.y
    local collisions = {}
    for k,w in NPC.iterateIntersecting(x, y - v.height - 24 + math.min(v.speedY, 0), x + v.width, y + 4) do
        if w ~= v and upwardsSpringValidityCheck(v, w) then
            if passesRaycastChecks(w) then
                table.insert(collisions, w)
            end
        end
    end

    if v:mem(0x12E, FIELD_WORD) == 0 then
        local secondaryCollisions = Player.getIntersecting(x, y - v.height + math.min(v.speedY, 0), x + v.width, y + 4)
        for _, w in ipairs(secondaryCollisions) do
            if ((not w:isGroundTouching() or w.y + w.height < v.y)
            and w.forcedState == 0
            and w:mem(0x13E, FIELD_WORD) == 0
            and w.y + w.speedY + w.height > v.y - (16) + math.min(v.speedY, 0)) 
            and w:mem(0x11C, FIELD_WORD) == 0 then
                if passesRaycastChecks(w) then
                    table.insert(collisions, w)
                end
            end
        end
    end

    for k,e in pairs(data.lockPosition) do
        if (not table.icontains(collisions, k)) then
            affectedEntityMap[k] = nil
            data.lockPosition[k] = nil
        end
    end

    for _,w in ipairs(collisions) do
        data.restoreTimer = 0
        if data.state < 2 then
            if affectedEntityMap[w] == nil or affectedEntityMap[w] == v then
                if affectedEntityMap[w] == nil then
                    data.stalled = false
                    data.lockPosition[w] = w.x - w.speedX
                    data.previousX[w] = w.speedX
                    if w.__type == "NPC" then
                        if w.dontMove or w.speedX == 0 then
                            data.previousX[w] = math.huge
                        end
                        if data.lastSpeedY < 0 and w.collidesBlockBottom then
                            data.stalled = true
                        end
                    end
                end
                affectedEntityMap[w] = v

                forcePosition(v, w, data)
                w.x = data.lockPosition[w]
                data.lockPosition[w] = data.lockPosition[w] + v.speedX
                data.timer = data.timer + 1
                data.state = 1.5

                if data.stalled and affectedEntityMap[w] == v then
                    v.speedY = 0
                    v.y = w.y + w.height
                end
            end
        elseif data.state == 2 then

            if data.stalled and affectedEntityMap[w] == v then
                v.speedY = -Defines.npc_grav
                v.y = w.y + w.height
            end
            if data.lockPosition[w] then
                w.x = data.lockPosition[w]
                data.lockPosition[w] = data.lockPosition[w] + v.speedX
            end
            if data.timer >= 4 then
                affectedEntityMap[w] = nil
                if data.previousX[w] and data.previousX[w] ~= math.huge then
                    w.speedX = data.previousX[w]
                end
                if w.__type == "Player" then
                    local force = math.abs(NPC.config[v.id].force)
                    local weakforce = NPC.config[v.id].weakforce
                    if weakforce < 0 then
                        weakforce = math.abs(weakforce) * force
                    end
                    w.speedY = - weakforce
                    if w.jumpKeyPressing or w.altJumpKeyPressing then
                        w.speedY = - force
                    end
                    w:mem(0x00, FIELD_BOOL, w.character == CHARACTER_TOAD and (w.powerup == 5 or w.powerup == 6)) -- Toad Doublejump
                    w:mem(0x0E, FIELD_BOOL, false) -- Fairy already used?
                    w:mem(0x18, FIELD_BOOL, w.character == CHARACTER_PEACH) -- Peach hover
                    springs.isSpringingPlayer[w.idx] = true
                elseif verticalBounceResponseMap[w.id] == nil or verticalBounceResponseMap[w.id](w, v) then
                    local force = math.abs(NPC.config[v.id].force)
                    local npcforce = NPC.config[v.id].npcforce
                    if npcforce < 0 then
                        npcforce = math.abs(npcforce) * force
                    end
                    recursiveBounceUp(w, npcforce, 0)
                    springs.isSpringingNPC[w.id] = true
                end
                SFX.play(24)
                data.previousX[w] = nil
                data.lockPosition[w] = nil
                data.timer = 0
                data.stalled = false
            else
                forcePosition(v, w, data)
            end
        end

        if (data.state == 1.5 and data.timer >= 4) or data.state ~= 1.5 then
            data.state = math.floor(data.state + 1)
        end
        
        if (data.state == 0) then
            for _,p in ipairs(Player.get()) do
                if springs.isSpringingPlayer[p.idx] then
                    springs.isSpringingPlayer[p.idx] = false
                end
            end
            for _,n in ipairs(NPC.get()) do
                if springs.isSpringingNPC[n.idx] then
                    springs.isSpringingNPC[n.idx] = false
                end
            end
        end
    end
    return collisions
end

local function bounceAI_vertical(v, data)
    if v.direction == -1 then
        return bounceAI_up(v, data)
    end

    local x = v.x
    local y = v.y + 0.5 * v.height
    local collisions = {}
    for k,w in NPC.iterateIntersecting(x, y, x + v.width, y + 0.5 * v.height) do
        if downwardsSpringValidityCheck(v, w) then
            table.insert(collisions, w)
        end
    end

    if v:mem(0x12E, FIELD_WORD) == 0 then
        local secondaryCollisions = Player.getIntersecting(x, y, x + v.width, y + 0.5 * v.height)
        for _, w in ipairs(secondaryCollisions) do
            if (w:mem(0x13E, FIELD_WORD) == 0 and w.forcedState == 0 and w.y + w.speedY < v.y + v.height + math.max(v.speedY, 0)) then
                table.insert(collisions, w)
            end
        end
    end

    for _,w in ipairs(collisions) do
        data.restoreTimer = 0
        if data.state == 2 then
            SFX.play(24)
            w.speedY = math.abs(NPC.config[v.id].force)
            if w.__type == "NPC" then
                if verticalBounceResponseMap[w.id] ~= nil then
                    verticalBounceResponseMap[w.id](w, v)
                end
                --w:mem(0x136, FIELD_BOOL, true)
            else
                w:mem(0x11C, FIELD_WORD, 0)
            end
        end
        data.state = data.state + 1
    end
    return collisions
end

local function bounceAI_side(v, data)
    local x = v.x
    local y = v.y
    local collisions = {}
    for k,w in NPC.iterateIntersecting(x - 12 + 2 * data.state, y + 4, x + v.width + 12 - 2 * data.state, y + v.height - 4) do
        if horizontalSpringValidityCheck(v, w) then
            table.insert(collisions, w)
        end
    end
    local secondaryCollisions = Player.getIntersecting(x - 8, y + 4, x + v.width + 8, y + v.height - 4)
    for _, w in ipairs(secondaryCollisions) do
        if (w.deathTimer == 0 and w.forcedState == 0) then
            table.insert(collisions, w)
        end
    end 
    local cfg = NPC.config[v.id]
    for _,w in ipairs(collisions) do
        data.restoreTimer = 0
        if data.state == 2 then
            local dirCalc = w.x + 0.5 * w.width > x + 0.5 * v.width
            
            local dir = -1
            
            if dirCalc then
                dir = 1
            end
    
            if cfg.usedirectiontobounce then
                dir = v.direction
            end

            SFX.play(24)
            w.direction = dir
            w.speedX = 7 * dir
            if w.__type == "NPC" then
                if horizontalBounceResponseMap[w.id] == nil or horizontalBounceResponseMap[w.id](w, v) then
                    if NPC.config[w.id].nogravity == false then
                        w.speedY = - math.abs(NPC.config[v.id].force)
                    end
                    if not NPC.SHELL_MAP[w.id] then
                        w.speedX = math.abs(NPC.config[v.id].force) * dir
                    end
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
springs.addType("UP", bounceAI_up)
springs.addType("SIDE", bounceAI_side)
springs.addType("VERTICAL", bounceAI_vertical)

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
	registerEvent(springs, "onTickEnd")
end

function springs.onTickEnd()
    for k,v in pairs(affectedEntityMap) do
        if v.data._basegame.state == 0 then
            affectedEntityMap[k] = nil
        end
    end
end

function springs.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = nil
		return
	end
	
	if data.state == nil then
		data.state = 0
		data.restoreTimer = 0
		data.previousGrabPlayer = 0
		data.dropCooldown = 0
		data.timer = 0
        data.stalled = false
        data.lastSpeedY = v.speedY
        data.lastLayerSpeed = vector.zero2
		data.previousX = {}
		data.lockPosition = {}
	end

    v:mem(0x136, FIELD_BOOL, false)


    local cfg = NPC.config[v.id]

    if cfg.nogravity and cfg.noblockcollision then
        local newLayerSpeed = vector.zero2
        if not Layer.isPaused() then
            newLayerSpeed = vector(v.layerObj.speedX, v.layerObj.speedY)
            v.speedX = v.speedX + newLayerSpeed.x - data.lastLayerSpeed.x
            v.speedY = v.speedY + newLayerSpeed.y - data.lastLayerSpeed.y
        end
        data.lastLayerSpeed = newLayerSpeed
    end
    
    -- SMW-style throwing
    if not NPC.config[v.id].isstationary then
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
    end
    
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
    -- 1 set of frames per state
    v.animationFrame = (math.floor(lunatime.tick()/cfg.framespeed) % cfg.frames)+ cfg.frames * math.clamp(math.floor(data.state), 0, 2)
    if cfg.framestyle > 0 and v.direction == 1 then
        v.animationFrame = v.animationFrame + cfg.frames * 3
    end
	v.animationTimer = 0
    data.lastSpeedY = v.speedY

    v:mem(0x12E, FIELD_WORD, math.min(v:mem(0x12E, FIELD_WORD), NPC.config[v.id].springdropcooldown or 30))
end

return springs