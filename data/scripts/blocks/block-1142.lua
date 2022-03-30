local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		local held = n.holdingNPC
		if held then
			held:kill(9)
			n:mem(0x154, FIELD_WORD, 0)
		end
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block