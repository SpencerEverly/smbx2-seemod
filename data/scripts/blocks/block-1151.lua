local blockmanager = require("blockmanager")
local elementals = require("blocks/ai/elementalblocks")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	customhurt = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n.powerup ~= 7 and not (n.mount == 1 and n.mountColor == 2) then
			n:harm()
		end
	end
end

function block.onStartBlock(v)
	blockutils.storeContainedNPC(v)
end

elementals.register(blockID, "iscold")

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
    blockmanager.registerEvent(blockID, block, "onStartBlock")
end

return block