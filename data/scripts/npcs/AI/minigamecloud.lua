local npcManager = require("npcManager")

local minigameCloud = {}

local ids = {}

function minigameCloud.registerCloud(id)
    table.insert(ids, id)
end

local coinMap = {}

function minigameCloud.registerCoin(id)
    coinMap[id] = true
end

function minigameCloud.onInitAPI()
	registerEvent(minigameCloud, "onNPCKill")
	registerEvent(minigameCloud, "onStart")
end

function minigameCloud.onStart()
    for k,v in ipairs(ids) do
        minigameCloud.registerCoin(NPC.config[v].spawnid)
    end
end

function minigameCloud.onNPCKill(e, v, r)
    if not coinMap[v.id] then return end
    if r ~= 9 then return end
	if not npcManager.collected(v, r) then return end
	
	if v.isGenerator then return end
	
	local data = v.data._basegame
	
	if not (data.minigameCloudParent and data.minigameCloudParent.isValid) then return end
	
	local parentData = data.minigameCloudParent.data._basegame
	parentData.collected = parentData.collected + 1
	if parentData.collected >= data.minigameCloudParent.ai2 then
		parentData.collectedAll = true
	end
end

function minigameCloud.isRewardValid(v)
    return v.data._basegame.collectedAll
end

function minigameCloud.initCoin(v, coin)
    coin.data._basegame = {minigameCloudParent = v}
end
	
return minigameCloud