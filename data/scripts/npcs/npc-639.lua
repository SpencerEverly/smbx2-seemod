local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local npcutils = require("npcs/npcutils")

local cheepSpawner = {}

local npcID = NPC_ID

local fields = {
    "sound", "npc", "minSpeed", "maxSpeed", "delay", "enabled"
}

local cams = {{enabled = false, timer = 0}, {enabled = false, timer = 0}}

local function onSpawnerTriggered(cam, settings)
    for k,v in ipairs(fields) do
        cams[cam.idx][v] = settings[v]
    end
    cams[cam.idx].timer = 0
end

spawner.register(npcID, onSpawnerTriggered)

function cheepSpawner.onInitAPI()
    registerEvent(cheepSpawner, "onTickEnd")
end

function cheepSpawner.onTickEnd()
    if Defines.levelFreeze then return end

    for k,v in ipairs(Camera.get()) do
        local c = cams[v.idx]
        if c.enabled then
            c.timer = c.timer + 1
            if c.timer % c.delay == 0 then
                local y = v.y + 600
                local speedX = RNG.irandomEntry{c.minSpeed, c.maxSpeed}
                local x = -math.sign(speedX)
                local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                local n = NPC.spawn(c.npc, v.x + 0.5 * v.width - speedX * 100, y, p.section, false, true)
                n.speedY = -10
                n.layerName = "Spawned NPCs"
                n.ai1 = 2
                n.direction = x
                n.speedX = speedX
                if c.sound > 0 then
                    SFX.play(c.sound)
                end
            end
        end
    end
end

return cheepSpawner;