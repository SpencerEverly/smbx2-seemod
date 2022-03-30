local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

local function resetStatue(p)
	p:mem(0x4A, FIELD_BOOL, false)
end

local function resetFlight(p)
	if p.powerup == 4 or p.powerup == 5 then
		p:mem(0x16E, FIELD_BOOL, false)
		p:mem(0x164, FIELD_WORD, 0)
		p:mem(0x164, FIELD_WORD, 0)
		resetStatue(p)
	end
end

blockmanager.setBlockSettings({
	id = blockID,
	passthrough = true
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n:mem(0x122, FIELD_WORD) == 0 and not n.isMega then
			resetFlight(n)
			n.powerup = 1
		end
    end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block