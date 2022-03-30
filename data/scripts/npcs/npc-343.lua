-- YI Red Platform
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

npcManager.setNpcSettings(table.join({id = npcID}, platforms.yiPlatformSettings))

lineguide.properties[npcID] = table.join(
	{
		lineSpeed = 4,
		jumpSpeed = 8
	},
	platforms.yiPlatformLineguideSettings
)

return p
