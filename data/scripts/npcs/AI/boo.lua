local boo = {}

local npcManager = require("npcManager")
local condsById = {}

function boo.register(id, condition)
    condsById[id] = condition
	npcManager.registerEvent(id, boo, "onTickEndNPC")
end

function boo.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) ~= 0 then return end

	local cfg = NPC.config[v.id]
	local p = condsById[v.id](v)
    if p then
        if p.__type ~= "Player" then
            p = player
        end
		if v.x + v.width/2 < p.x + p.width/2 then
			if v.speedX < cfg.maxspeedx then
				v.speedX = v.speedX + cfg.accelx
			end
			v.animationFrame = 2
		else
			if v.speedX > -cfg.maxspeedx then
				v.speedX = v.speedX - cfg.accelx
			end
			v.animationFrame = 0
		end

		if v.y + v.height/2 < p.y + p.height/2 then
			if v.speedY < cfg.maxspeedy then
				v.speedY = v.speedY + cfg.accely
			end
		elseif v.speedY > -cfg.maxspeedy then
			v.speedY = v.speedY - cfg.accely
		end
	else
		if v.speedX ~= 0 then
			if v.speedX > 0 then
				v.speedX = v.speedX - cfg.decelx
			elseif v.speedX < 0 then
				v.speedX = v.speedX + cfg.decelx
			end
		    if math.abs(v.speedX) < cfg.decelx then
				v.speedX = 0
			end
		end
		if v.speedY ~= 0 then
			if v.speedY > 0 then
				v.speedY = v.speedY - cfg.decely
			elseif v.speedY < 0 then
				v.speedY = v.speedY + cfg.decely
			end
		    if math.abs(v.speedY) < cfg.decely then
				v.speedY = 0
			end
		end
		if v.direction == 1 then
			v.animationFrame = 3
		else
			v.animationFrame = 1
		end
	end
end

return boo