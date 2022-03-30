local npcManager = require("npcManager")
local babyYoshis = require("npcs/ai/babyyoshis")

local blackBabyYoshi = {}
local npcID = NPC_ID;

--baby yoshi adaptations, please define your npc config here
local settings = {
	id = npcID
}

-- Settings for npc
npcManager.setNpcSettings(table.join(settings, babyYoshis.babyYoshiSettings));

-- Final setup
local function swallowFunction (v)
end

function blackBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.BLACK, swallowFunction);
end

return blackBabyYoshi;