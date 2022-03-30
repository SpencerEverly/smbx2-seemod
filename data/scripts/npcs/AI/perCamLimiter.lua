local pcl = {}

local idMap = {}

function pcl.isCamFree(camIdx, npcID)
    return idMap[npcID] == nil or idMap[npcID][camIdx] == nil
end

function pcl.registerNPC(camIdx, npc, overwrite)
    idMap[npc.id] = idMap[npc.id] or {}
    if overwrite or pcl.isCamFree(camIdx, npc.id) then
        idMap[npc.id][camIdx] = npc
        return true
    end
    return false
end

function pcl.getNPC(camIdx, npcID)
    idMap[npcID] = idMap[npcID] or {}
    return idMap[npcID][camIdx]
end

function pcl.getUnregisterNPC(camIdx, npcID)
    idMap[npcID] = idMap[npcID] or {}
    local n = idMap[npcID][camIdx]
    idMap[npcID][camIdx] = nil
    return n
end

return pcl