local blockmanager = require("blockmanager")
local feet = require("blocks/ai/stoodon")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	semisolid = true,
	customhurt = true
})

function block.onPlayerStood(v, p)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	if p.mount ~= 0 then return end
	p:harm()
end

feet.register(blockID, block.onPlayerStood)

return block