local blockmanager = require("blockmanager")
local pswitch = require("blocks/ai/pswitchable")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 4
})

pswitch.registerSet(blockID, blockID + 1)

return block