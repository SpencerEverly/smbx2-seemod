--------------------------------
-- Mutant Vine
--------------------------------
-- Created by Sambo, 29 Dec. 2017

local mutantVine = {}

local npcManager = require("npcManager")
local mutantVineAI = require("npcs/ai/mutantvine")

local npcID = NPC_ID


local headSettings = {
	id = npcID,
	-- animation
	frames = 2,
	-- physics
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	-- player interaction
	noiceball = true,
	jumphurt = true,
    nohurt = true,
    
    playercontrolled = false,
    vineid = 552,
	thornedid = 554,
	eatsblocks=true,
}
npcManager.setNpcSettings(headSettings)

mutantVineAI.registerHead(npcID)

return mutantVine