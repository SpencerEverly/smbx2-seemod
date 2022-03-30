local blockmanager = require("blockmanager")
local rpb = require("blocks/ai/reservepowerblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 4,

	hitid = 738
})

rpb.register(blockID)

return block