local chainreaction = {}
local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local idMap = {}
local ids = {}

chainreaction.timer = 12

function chainreaction.getIDMap()
    return idMap
end

function chainreaction.getIDList()
    return ids
end

function chainreaction.register(id)
    idMap[id] = true
    table.insert(ids, id)
    blockmanager.registerEvent(id, blockutils, "onStartBlock", "storeContainedNPC")
    blockmanager.registerEvent(id, chainreaction, "onTickBlock")
end

function chainreaction.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data._basegame
	if data.timer then
		data.timer = data.timer + 1;
		if(data.timer >= chainreaction.timer) then
			blockutils.kirbyDetonate(v, ids);
		end
	end
end

return chainreaction