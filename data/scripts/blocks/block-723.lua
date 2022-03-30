local blockmanager = require("blockmanager")
local cp = require("blocks/ai/clearpipe")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 64,
	height = 64
})

-- Up, down, left, right
cp.registerPipe(blockID, "CANNON", "HORZ", {false, false, true,  true})

return block