local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		n.mount = 0
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block