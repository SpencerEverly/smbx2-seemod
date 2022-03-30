local blockmanager = require("blockmanager")
local pswitch = require("blocks/ai/pswitchable")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true,
	frames = 2
})

pswitch.registerSet(blockID - 1, blockID)

return block