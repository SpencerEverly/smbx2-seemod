local wiggler = {}

local npcManager = require("npcManager")
local wiggler = require("npcs/ai/wiggler")

local npcID = NPC_ID

wiggler.registerTrail(npcID, {id = npcID})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD}, {})

return wiggler