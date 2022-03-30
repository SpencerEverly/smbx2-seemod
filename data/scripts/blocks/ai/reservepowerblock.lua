local rpb = {}

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local idMap = {}

function rpb.onStartBlock(v)
	blockutils.storeContainedNPC(v)
end

local function setReservePowerup(item, p)
	if item == nil or (item < 1000 and item > 0) then return end
	item = math.max(0, item - 1000)
	p.reservePowerup = item
	SFX.play(12)
end

function rpb.onPostBlockHit(v, fromUpper, playerOrNil)
    if not idMap[v.id] then return end
	if playerOrNil == nil then return end
    local data = v.data._basegame
	setReservePowerup(data.content, playerOrNil)
    Effect.spawn(261, v.x, v.y)
    local cfg = Block.config[v.id]
    if not cfg.hitid then return end
	v.id = cfg.hitid
	Block.config[v.id].bumpable = true
	v:hit()
	Block.config[v.id].bumpable = false
end

function rpb.onTickBlock(v)
    if v.contentID ~= 0 then
		blockutils.storeContainedNPC(v)
	end
end

function rpb.register(id)
    blockmanager.registerEvent(id, rpb, "onStartBlock")
    blockmanager.registerEvent(id, rpb, "onTickBlock")
    idMap[id] = true
end

function rpb.onInitAPI()
    registerEvent(rpb, "onPostBlockHit")
end

return rpb