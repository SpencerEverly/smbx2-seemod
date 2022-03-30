local npcManager = require("npcManager")
local babyYoshis = require("npcs/ai/babyyoshis")

local yellowBabyYoshi = {}
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

function yellowBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.YELLOW, swallowFunction);
end

return yellowBabyYoshi;