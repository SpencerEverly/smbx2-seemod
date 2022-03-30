local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n:mem(0x122, FIELD_WORD) == 0 and not n.isMega then
			n.powerup = 5
		end
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block