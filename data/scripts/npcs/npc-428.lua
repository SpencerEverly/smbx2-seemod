local kingbill = {}

local npcManager = require("npcManager")
local kingbillAI = require("npcs/ai/kingbill")
local npcID = NPC_ID
local settings = {id = npcID, effect = 201}

kingbillAI.register(npcID, settings)

return kingbill