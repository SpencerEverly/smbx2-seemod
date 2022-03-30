local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")
local switch = require("blocks/ai/crashswitch")

local blockID = BLOCK_ID

local block = {}

local settings = blockmanager.setBlockSettings({
	id = blockID,
	smashable = 2,
	bumpable = true
})

local sound = Misc.resolveSoundFile("nitro")

local function trigger(v)
	SFX.play(sound)
	Defines.earthquake = 40
	
	for _,v in Block.iterateByFilterMap{[683]=true} do
		if blockutils.hiddenFilter(v) then
			blockutils.detonate(v, 5)
		end
	end
end

switch.registerSwitch(blockID, trigger, 1280)

return block