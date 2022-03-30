--- Adds SMW Fuzzies
-- @module smwfuzzy
-- @author Sambo
-- @version 2.0.4b

local smwfuzzy = {}

local lineguide = require("lineguide")
local npcManager = require("npcManager")

local npcID = NPC_ID

lineguide.registerNpcs(npcID)

-- settings
npcManager.setNpcSettings{
	id = npcID, 
	width = 32, 
	height = 32, 
	frames = 2, 
	noiceball = true, 
	noblockcollision = true,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpSafe = true
}

lineguide.properties[npcID] = {lineSpeed = 3}

return smwfuzzy