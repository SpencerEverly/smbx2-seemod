local blockmanager = require("blockmanager")
local feet = require("blocks/ai/sharedstorage")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 2,
	bumpable = true
})

local storedPower = 1
local storedHearts = 1

local function onBump(v)
	local p, h = storedPower, storedHearts
	storedPower = v.powerup
	storedHearts = v:mem(0x16, FIELD_WORD)

	v.powerup = p
	v:mem(0x16, FIELD_WORD, h)

	return storedPower > 1
end

feet.register(blockID, onBump)

return block