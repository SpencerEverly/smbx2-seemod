local blockmanager = require("blockmanager")
local sync = require("blocks/ai/synced")

local blockID = BLOCK_ID

local block = {}

--[[blockmanager.setBlockSettings({
	id = blockID
})]]

sync.registerBlinkingBlock(blockID, false)

return block