local graf = {}

local grafAI = require("npcs/ai/graf")
local npcManager = require("npcManager")
local npcID = NPC_ID

local settings = {
	id = npcID,
	parametric = false,
	jumphurt = true,
	noiceball = true,
	nofireball = true,
	noyoshi = true,
	nogravity=false
}

grafAI.register(settings)

return graf