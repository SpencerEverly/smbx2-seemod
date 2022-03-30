local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 3,
	npcfilter = -1,
	ediblebyvine = true, -- edible by mutant vine
})

return block