local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")
local switch = require("blocks/ai/crashswitch")

local blockID = BLOCK_ID

local block = {}

local settings = blockmanager.setBlockSettings({
	id = blockID,
	smashable = 2,
	bumpable = true
})

local function trigger(v)
end

switch.registerSwitch(blockID, trigger, 1280)

return block