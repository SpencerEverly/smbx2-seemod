local snailicorn = {}

local npcutils = require("npcs/npcutils")

local invulnerableHarmTypes = table.map({
    HARM_TYPE_JUMP,
    HARM_TYPE_FROMBELOW,
    HARM_TYPE_TAIL,
    HARM_TYPE_SPINJUMP,
    HARM_TYPE_SWORD,
})

snailicorn.STATE = {
    IDLE = 1,
    CHASING = 2,
    HURT = 3,
}

function snailicorn.init(v, chasing)
    local data = v.data._basegame

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        data.init = false
        return false
    end
	
	if not data.init then
		data.state = snailicorn.STATE.IDLE
		data.frame = 0
		data.timer = 0
		
		if chasing then 
			data.target = nil
			data.chaseDirection = nil
			data.visionCollider = data.visionCollider or Colliders.Box(0,0,256, v.height)
		else
			data.bounced = false
		end

		data.init = true
    end
	
    if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
        data.state = snailicorn.STATE.IDLE
        data.timer = 0
        return false
    end
	
	return true
end

function snailicorn.updateAnimation(v, direction)
    if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then
        return
    end
	
    local data = v.data._basegame
	
    local frames = NPC.config[v.id].frames - 1
	
    if v.animationTimer == 0 and not Defines.levelFreeze then
        data.frame = (data.frame + 1) % (frames)
    end

    if not data.init then return end

    local frameOverride = nil
    local offset = nil
	local gap = 1


    if data.state == snailicorn.STATE.HURT then
        frameOverride = 0
        offset = frames
		frames = 1
		gap = 0
    elseif not v.collidesBlockBottom then
        frameOverride = frames - 1
    end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
            frame = frameOverride or data.frame,
            offset = offset,
			frames = frames,
            gap=gap,
            direction = direction or v.direction
        })
end


function snailicorn.hurt(eventObj, v, killReason, npcID)
	if v.id ~= npcID then return false end

	--Yikes! Actually Dead!
	if not invulnerableHarmTypes[killReason] then return false end

	eventObj.cancelled = true

	SFX.play(2)
	
	return true
end

return snailicorn