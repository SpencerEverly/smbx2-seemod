local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	smashable = 3
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		blockutils.spawnNPC(v)
		v:remove(true)
		if n.jumpKeyPressing then
			n.speedY = -6;
		else
			n.speedY = -3.5;
		end
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
    blockmanager.registerEvent(blockID, blockutils, "onStartBlock", "storeContainedNPC")
end

return block