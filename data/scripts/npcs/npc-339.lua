-- SMW Wood Platform
local p = {}

local npcManager = require("npcManager")
local lineguide = require("lineguide")
local platforms = require("npcs/ai/platforms")
local npcID = NPC_ID
lineguide.registerNpcs(npcID)

--*************************************************************************
--*
--*								Settings
--*
--*************************************************************************

npcManager.setNpcSettings(table.join(
	{
		id = npcID, 
		width = 96, 
		height = 22
	}, 
	platforms.basicPlatformSettings
))

lineguide.properties[npcID] = {
	lineSpeed = 1.8, 
	activeByDefault = false, 
	fallWhenInactive = false, 
	activateOnStanding = true, 
	extendedDespawnTimer = true,
	buoyant = true
}

return p
