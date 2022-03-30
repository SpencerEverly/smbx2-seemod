local blockmanager = require("blockmanager")
local sync = require("blocks/ai/synced")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	width = 64,
	height = 64
})

sync.registerSwitchableSpike(blockID, true)

return block