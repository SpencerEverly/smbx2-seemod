-- Green Grinder
local grinder = {}

local npcManager = require("npcManager")
local lineguide = require("lineguide")
local grinders = require("npcs/ai/grinders")

local npcID = NPC_ID

lineguide.registerNpcs(npcID)

--*********************************************************
--*
--*					Settings
--*
--*********************************************************

local greenGrinderSettings = table.join({id = npcID, speed = 2}, grinders.sharedGrinderSettings)
npcManager.setNpcSettings(greenGrinderSettings)
lineguide.properties[npcID] = table.join({lineSpeed = 2}, grinders.sharedGrinderLineguideProps)

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

npcManager.registerEvent(npcID, grinders, "onStartNPC", "onStartGrinder")
npcManager.registerEvent(npcID, grinders, "onTickEndNPC", "onTickEndGrinder")
npcManager.registerEvent(npcID, grinders, "onDrawNPC", "onDrawGrinder")

return grinder
