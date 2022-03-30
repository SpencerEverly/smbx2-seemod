local blockmanager = require("blockmanager")
local pb = require("blocks/ai/powerupblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true
})

pb.register(blockID, 1)

return block