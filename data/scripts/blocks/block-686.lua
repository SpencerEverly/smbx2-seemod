local blockmanager = require("blockmanager")
local chainreaction = require("blocks/ai/chainreaction")

local blockID = BLOCK_ID

local block = {}

--[[blockmanager.setBlockSettings({
	id = blockID,
})]]

chainreaction.register(blockID)

return block