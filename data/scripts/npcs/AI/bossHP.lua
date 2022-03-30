local npcManager = require("npcManager")
local configFileReader = require("configFileReader")

local bossHP = {}

local bossIDs = {}

local defaultHP = {}

function bossHP.register(id, default)
    table.insert(bossIDs, id)
    defaultHP[id] = default
    NPC.config[id].health = default
end

function bossHP.onInitAPI()
    registerEvent(bossHP, "onStart")
end

function bossHP.onStart()
    for k,v in ipairs(bossIDs) do
        if NPC.config[v].health and NPC.config[v].health ~= defaultHP[v] then
            --This should be updated to use onSpawn in the future...
            npcManager.registerEvent(v, bossHP, "onTickEndNPC")
        end
    end
end

function bossHP.onTickEndNPC(v)
    local data = v.data._basegame
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        data.init = false
        return
    end
    if not data.init then
        v:mem(0x148, FIELD_FLOAT, defaultHP[v.id] - NPC.config[v.id].health)
        data.init = true
    end
end

return bossHP