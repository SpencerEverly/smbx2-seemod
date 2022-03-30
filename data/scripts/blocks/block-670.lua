local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true
})
local hitPswitchEvent

function block.onPostBlockHit(v)
	if v.id ~= blockID then return end
	if(not Defines.levelFreeze) then
		playSFX(32)
		hitPswitchEvent = function() Misc.doPSwitch() end
	end
end

function block.onTickEnd()
	if hitPswitchEvent then
		hitPswitchEvent()
		hitPswitchEvent = nil
	end
end

function block.onInitAPI()
    registerEvent(block, "onPostBlockHit")
    registerEvent(block, "onTickEnd")
end

return block