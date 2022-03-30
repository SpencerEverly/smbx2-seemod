local tiltlift = require("NPCs/AI/tiltlift")
local npcManager = require("npcManager")

local multiArrowLift = {};

local npcID = NPC_ID

local config = {
	gfxwidth=224,
	width=224,

	defaultarrow = 2
};

tiltlift.register(npcID, config, tiltlift.LEFT, tiltlift.UP, tiltlift.RIGHT)

return multiArrowLift