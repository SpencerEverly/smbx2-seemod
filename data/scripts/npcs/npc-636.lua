local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local boohemoth = require("npcs/ai/boohemoth")
local npcutils = require("npcs/npcutils")

local booSpawner = {}

local npcID = NPC_ID

spawner.register(npcID, boohemoth.spawn)

return booSpawner;