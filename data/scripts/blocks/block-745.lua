local blockmanager = require("blockmanager")
local feet = require("blocks/ai/sharedstorage")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 2,
	bumpable = true
})

local storedMount = 0
local storedCol = 0

local function onBump(v)
	local p, r = storedMount, storedCol
	storedMount = v.mount
	storedCol = v.mountColor
	if storedMount == 0 then storedCol = 0 end
	v.mount = p
	v.mountColor = r

	return storedCol + storedMount > 0
end

feet.register(blockID, onBump)

return block