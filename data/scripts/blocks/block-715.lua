local blockmanager = require("blockmanager")
local cp = require("blocks/ai/clearpipe")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true
})

-- Up, down, left, right
cp.registerPipe(blockID, "STRAIGHT", "HORZ", {false, true,  true,  true})

return block