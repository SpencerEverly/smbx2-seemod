local crate = require("npcs/ai/crate")
local npcManager = require("npcManager")

local crates = {}
local npcID = NPC_ID

local config = {
    id = npcID,
    explosive = true
}

npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_LAVA, HARM_TYPE_SWORD}, {});

function crates.onInitAPI()
	crate.register(npcID, config)
end
	
return crates