local tiltlift = require("NPCs/AI/tiltlift")
local npcManager = require("npcManager")

local multiArrowLift = {};

local npcID = NPC_ID

local config = {
	gfxwidth=128,
	width=128
};

tiltlift.register(npcID, config, tiltlift.LEFT, tiltlift.RIGHT)

return multiArrowLift