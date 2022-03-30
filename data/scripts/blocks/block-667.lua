local blockmanager = require("blockmanager")
local chainreaction = require("blocks/ai/chainreaction")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	smashable = 2
})

function block.onPostBlockHit(v)
	if v.id ~= blockID then return end
	blockutils.kirbyDetonate(v, chainreaction.getIDList())
end

function block.onInitAPI()
    registerEvent(block, "onPostBlockHit")
end

chainreaction.register(blockID)

return block