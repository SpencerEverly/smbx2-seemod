local blockmanager = require("blockmanager")
local bd = require("blocks/ai/breakingdirt")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	smashable = 3
})

bd.register(blockID)

return block