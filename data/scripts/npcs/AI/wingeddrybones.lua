local rng = require("rng")
local npcManager = require("npcManager")

local drybones = {}

local idMap = {}

function drybones.register(id)
    npcManager.registerEvent(id, drybones, "onTickEndNPC", "onTickEndWinged")
    idMap[id] = true
end

function drybones.onInitAPI()
	registerEvent(drybones, "onNPCKill")
end

function drybones.onTickEndWinged(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	data.frame = v.animationFrame

	if data.sineCounter == nil then
		data.sineCounter = 0
		if v.direction == 0 then
			v.direction = rng.randomInt(1)
			if v.direction == 0 then v.direction = -1 end
		end
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.sineCounter = 0
		return
	end

	data.sineCounter = data.sineCounter + 0.05
	if not v.dontMove then
		v.speedX = 0.8 * v.direction
	end
	v.speedY = 1 * math.cos(data.sineCounter)
end

function drybones.onNPCKill(eventObj,v,killReason)
	if not idMap[v.id] then return end
    local data = v.data._basegame
    local cfg = NPC.config[v.id]
	if (killReason == 1 or killReason == 8 or killReason == 10) then
		SFX.play(9)
		eventObj.cancelled = true
        local lastDontMove = v.dontMove
        v:transform(cfg.transformid)
		v.data._basegame = {dontMove = lastDontMove, friendly = v.friendly, direction = v.direction}
        if cfg.playsound then
            SFX.play(cfg.playsound)
        end
        v.ai1 = 1
        v.ai2 = cfg.recovery or 1
        v.friendly = true
        v.dontMove = true
		return
	end
	if killReason == 6 or killReason == 9 then return end
	Effect.spawn(cfg.effectid, v.x, v.y + v.height)
end

return drybones;