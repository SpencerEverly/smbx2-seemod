local wiggler = {}

local npcManager = require("npcManager")
local wiggler = require("npcs/ai/wiggler")

local npcID = NPC_ID

wiggler.registerHead(npcID, {id = npcID, speed=1, gfxheight=52, trailID = 447})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP}, {
[HARM_TYPE_NPC]=208,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

return wiggler