local blockmanager = require("blockmanager")

local block = {}

local blockID = BLOCK_ID

--disable vanilla collision
blockmanager.setBlockSettings({
    id = blockID,
	frames = 3,
	framespeed = 8,
	npcfilter = -1,
	ceilingslope = 1,
	ediblebyvine = true, -- edible by mutant vine
})


return block