local splitter = {}
local npcManager = require("npcManager")

splitter.SFX_die_giant = Misc.resolveSoundFile("giantgoomba-die")
--bigGoomba.SFX_hit_giant = Misc.resolveSoundFile("giantgoomba-hit")
splitter.SFX_die_mega = Misc.resolveSoundFile("megagoomba-die")
--bigGoomba.SFX_hit_mega = Misc.resolveSoundFile("megagoomba-hit")

local IDs = {}

function splitter.register(id, sound)
    IDs[id] = sound or splitter.SFX_die_giant
end

function splitter.onInitAPI()
	registerEvent(splitter, "onNPCHarm")
end

function splitter.onNPCHarm(event, n, reason, culprit) 
	if not IDs[n.id] then return end
    if reason == 7 or reason == 9 then return end
    
    local cfg = NPC.config[n.id]

    if culprit and culprit.__type == "NPC" and culprit.id == 13 and not cfg.nofireball then
        SFX.play(18)
        n.data._basegame = n.data._basegame or {}
        local d = n.data._basegame
        d.hp = d.hp or cfg.health

        d.hp = d.hp - 1
        if d.hp > 0 then
            event.cancelled = true
            return
        end
    end
    local id = cfg.splitid
    local lim = cfg.splits
    local s = IDs[n.id]

    local section = n:mem(0x146,FIELD_WORD)
    for i=0, lim - 1 do
        local iOff = i/(lim-1) - 0.5
        local dir = math.sign(iOff)
        local t = NPC.spawn(id, n.x + n.width * 0.5 + n.width * 0.2 * iOff, n.y + n.height * 0.5, section, false, true)
        t.direction = dir
        t.speedX = 8 * iOff
        t.speedY = - 4
        t.friendly = n.friendly
		
		--This makes the NPC not damage the player for a short time after spawning - useful to prevent sudden damage
		Routine.run(function(t)
			t:mem(0x12C, FIELD_WORD, -1)
			Routine.waitFrames(11)
			if t.isValid and t:mem(0x12C, FIELD_WORD) == -1 then
				t:mem(0x12C, FIELD_WORD, 0)
			end
		end, t)
        t.layerName = n.layerName
        t.noMoreObjInLayer = n.noMoreObjInLayer
        t.dontMove = n.dontMove
        t:mem(0x156,FIELD_WORD,10)
        t = Effect.spawn(10, n.x + n.width / 2, n.y + n.height - 16)
        t.speedX = 2 * dir
    end
    SFX.play(s)
end

return splitter