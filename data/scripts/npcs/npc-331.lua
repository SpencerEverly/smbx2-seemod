local npcManager = require("npcManager")
local babyYoshis = require("npcs/ai/babyyoshis")

local pinkBabyYoshi = {}
local npcID = NPC_ID;

--baby yoshi adaptations, please define your npc config here
local settings = {
	id = npcID,
	spawnnpc = 147
}

-- Settings for npc
npcManager.setNpcSettings(table.join(settings, babyYoshis.babyYoshiSettings));

-- Final setup
local function swallowFunction (v)
	local veggie = NPC.spawn(NPC.config[npcID].spawnnpc, v.x, v.y, v:mem(0x146, FIELD_WORD), false, true);
	veggie.speedX = -2.5 * v.direction;
	veggie.speedY = -4.5;
	veggie.layerName = "Spawned NPCs"
	SFX.play(75);
end

function pinkBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.PINK, swallowFunction);
end

return pinkBabyYoshi;