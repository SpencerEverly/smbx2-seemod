local npcManager = require("npcManager")
local rng = require("rng");
local babyYoshis = require("npcs/ai/babyyoshis")

local cyanBabyYoshi = {}
local npcID = NPC_ID;

--baby yoshi adaptations, please define your npc config here
local settings = {
	id = npcID,
	spawnnpc=237
}

-- Settings for npc
npcManager.setNpcSettings(table.join(settings, babyYoshis.babyYoshiSettings));

-- Final setup
local function swallowFunction (v)
	local iceball = NPC.spawn(NPC.config[npcID].spawnnpc, v.x, v.y, v:mem(0x146, FIELD_WORD), false);
	iceball.speedX = 3.5 * v.direction;
	iceball.speedY = -2;
	iceball.layerName = "Spawned NPCs"
	
	for i = 1, 14 do
		Effect.spawn(80, v.x + (v.width / 2) + rng.randomInt(-24, 24), v.y + (v.height / 2) + rng.randomInt(-24, 24));
	end
	
	SFX.play(18);
end

function cyanBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.CYAN, swallowFunction);
end

return cyanBabyYoshi;