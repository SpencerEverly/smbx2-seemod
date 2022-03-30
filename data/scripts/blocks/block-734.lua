local blockmanager = require("blockmanager")
local brittle = require("blocks/ai/brittle")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 2,
	effectid = 270,
	floorslope = 1
})

brittle.register(blockID, "leaf")

return block