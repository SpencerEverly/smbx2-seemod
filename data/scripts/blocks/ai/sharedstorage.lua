local storage = {}

local blockutils = require("blocks/blockutils")

local storages = {}
local storageList = {}

function storage.register(id, func)
    local entry = {}
    entry.hasStorage = false
    entry.func = func
    storages[id] = entry
    table.insert(storageList, id)
end

function storage.onPostBlockHit(v, fromUpSide, culprit)
    if not storages[v.id] then return end
    if culprit == nil then return end
    if culprit.__type == "Player" and v:mem(0x56, FIELD_WORD) == 0 then
        storages[v.id].hasStorage = storages[v.id].func(culprit)
        SFX.play(41)
        Effect.spawn(131, culprit.x, culprit.y)
        if storages[v.id].hasStorage then
            Effect.spawn(10, v.x, v.y - 0.5 * v.height)
        else
            Effect.spawn(147, v.x, v.y - v.height)
        end
    end
end

function storage.onInitAPI()
    registerEvent(storage, "onDraw")
    registerEvent(storage, "onPostBlockHit")
end

function storage.onDraw()
    for k,v in ipairs(storageList) do
        local frame = 0
        if storages[v].hasStorage then
            frame = 1
        end
        blockutils.setBlockFrame(v, frame)
    end
end

return storage