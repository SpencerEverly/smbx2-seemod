local blockmanager = require("blockmanager")
local feet = require("blocks/ai/stoodon")
local slime = require("blocks/ai/slime")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 2,
	semisolid = true
})

slime.register(blockID)
feet.register(blockID, slime.onPlayerStood)

return block