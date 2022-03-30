local pswitchable = {}
local blockutils = require("blocks/blockutils")

local sets = {}
local registeredIDs = {}

function pswitchable.registerSet(id1, id2)
    if registeredIDs[id1] or registeredIDs[id2] then return end
    table.insert(sets, {id1, id2})
    registeredIDs[id1] = true
    registeredIDs[id2] = true
end

function pswitchable.onEventDirect(obj, eventName)
    if eventName == "P Switch - Start" or eventName == "P Switch - End" then
        for k,v in ipairs(sets) do
            blockutils.queueSwitch(v[1], v[2])
        end
	end
end

function pswitchable.onInitAPI()
    registerEvent(pswitchable, "onEventDirect")
end

return pswitchable