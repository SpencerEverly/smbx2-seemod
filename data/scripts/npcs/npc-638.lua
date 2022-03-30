local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local npcutils = require("npcs/npcutils")

local billSpawner = {}

local npcID = NPC_ID

local fields = {
    "sound", "npc", "speed", "delay", "enabled", "homing"
}

local cams = {{enabled = false, timer = 0}, {enabled = false, timer = 0}}

local function onSpawnerTriggered(cam, settings)
    for k,v in ipairs(fields) do
        cams[cam.idx][v] = settings[v]
    end
    cams[cam.idx].timer = 0
end

spawner.register(npcID, onSpawnerTriggered)

function billSpawner.onInitAPI()
    registerEvent(billSpawner, "onTickEnd")
end

function billSpawner.onTickEnd()
    if Defines.levelFreeze then return end

    for k,v in ipairs(Camera.get()) do
        local c = cams[v.idx]
        if c.enabled then
            c.timer = c.timer + 1
            if c.timer % c.delay == 0 then
                local x = RNG.irandomEntry{-1, 1}
                local y = v.y + RNG.random(100, v.height - 100)
                local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                if c.homing then
                    y = RNG.random(p.y - 10, p.y + p.height + 10)
                end
                local n = NPC.spawn(c.npc, v.x + 0.5 * v.width + x * 0.5 * v.width, y, p.section, false, true)
                n.x = n.x + x * 0.5 * n.width
                n.layerName = "Spawned NPCs"
                n.direction = -x
                n.speedX = -x * c.speed
                if c.sound > 0 then
                    SFX.play(c.sound)
                end
            end
        end
    end
end

return billSpawner;