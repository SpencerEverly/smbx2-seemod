local kingbill = {}

local npcManager = require("npcManager")
local kingbillAI = require("npcs/ai/kingbill")
local npcID = NPC_ID
local settings = {id = npcID, vertical = true, effect = 202, staticdirection = true }

kingbillAI.register(npcID, settings)

return kingbill