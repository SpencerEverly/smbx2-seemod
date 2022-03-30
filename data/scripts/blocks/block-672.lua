local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	customhurt = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n:mem(0x140,FIELD_WORD) == 0 and n:mem(0x13E,FIELD_WORD) == 0 then
			n:harm()
		end
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block