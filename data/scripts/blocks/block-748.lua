local blockmanager = require("blockmanager")
local switches = require("blocks/ai/switchblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 4,

	offswitchid = 729,
	onswitchid = 728,
	color = "green"
})

switches.register(blockID, "PALACE")

return block