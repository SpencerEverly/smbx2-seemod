local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	customhurt = true,
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n:mem(0x140,FIELD_WORD) == 0 --[[changing powerup state]] and n.deathTimer == 0 --[[already dead]] and not Defines.cheat_donthurtme then
			n:kill()
		end
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block