local npcManager = require("npcManager")
local babyYoshis = require("npcs/ai/babyyoshis")

local purpleBabyYoshi = {}
local npcID = NPC_ID;

--baby yoshi adaptations, please define your npc config here
local settings = {
	id = npcID,
	slamdelay = 20
}

-- Settings for npc
npcManager.setNpcSettings(table.join(settings, babyYoshis.babyYoshiSettings));

-- Final setup
local function swallowFunction (v)
	Misc.doPOW();
end

function purpleBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.PURPLE, swallowFunction);
end

return purpleBabyYoshi;