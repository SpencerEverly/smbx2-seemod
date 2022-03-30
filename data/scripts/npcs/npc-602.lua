local barrel = {}

local npcManager = require("npcManager")
local barrelAI = require("npcs/ai/launchBarrel")

local npcID = NPC_ID

barrelAI.registerBarrel(npcID, "straight")

return barrel