local blockmanager = require("blockmanager")
local switches = require("blocks/ai/switchblock")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
	frames = 4,

	offswitchid = 725,
	onswitchid = 724,
	color = "yellow"
})

switches.register(blockID, "PALACE")

return block