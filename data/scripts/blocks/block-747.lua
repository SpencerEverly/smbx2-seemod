local blockmanager = require("blockmanager")
local switches = require("blocks/ai/switchblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 4,

	offswitchid = 727,
	onswitchid = 726,
	color = "blue"
})

switches.register(blockID, "PALACE")

return block