local npcManager = require("npcManager")
local rng = require("rng")

local sinewave = {}

function sinewave.register(id)
	npcManager.registerEvent(id, sinewave, "onTickNPC")
end

local function chasePlayers(v)
	local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	if p.x > v.x then
		v.direction = 1
	else
		v.direction = -1
	end
end

function sinewave.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame

    if v:mem(0x12A,FIELD_WORD) <= 0 or v.isHidden or v:mem(0x138, FIELD_WORD) ~= 0 then
		data.sineCounter = nil
		return
	end
    
    local cfg = NPC.config[v.id]

	if data.sineCounter == nil then
		data.sineCounter = cfg.wavestart
		data.dir = v.direction
		if v.direction == 0 then
			data.dir = rng.randomInt(1)
            if data.dir == 0 then data.dir = -1 end
            v.direction = data.dir
        end
        if cfg.chase then
            chasePlayers(v)
            data.dir = v.direction
        end
    end

	do 
		local holdingPlayer = v:mem(0x12C, FIELD_WORD)
		if holdingPlayer ~= 0 then
			v.direction = Player(holdingPlayer).direction
			data.dir = v.direction
			return
		end
	end
	
    data.sineCounter = data.sineCounter + 1/cfg.frequency
    v.speedX = v.direction * cfg.speed
	v.speedY = cfg.amplitude * math.cos(data.sineCounter)
end
	
return sinewave