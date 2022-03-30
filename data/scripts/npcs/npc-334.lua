-- Grinder Platform
local gp = {}

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

npcManager.setNpcSettings(table.join(
	{
		id = npcID, 
		width = 64, 
		height = 32, 
		speed = 3,
		gfxheight = 64, 
		gfxwidth = 64, 
		gfxoffsety = 32, 
		frames = 2, 
		framespeed = 4,
		framestyle = 0,
		nohurt = false, 
		jumphurt=false,
		spinjumpsafe=false,
		noblockcollision = false,
		playerblocktop = true,
		npcblocktop = true,
	},
	grinders.sharedGrinderSettings
))
lineguide.properties[npcID] = table.join(
	{
		lineSpeed = 3, 
		activateOnStanding = true, 
	},
	grinders.sharedGrinderLineguideProps
)

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

npcManager.registerEvent(npcID, grinders, "onStartNPC", "onStartGrinder")
npcManager.registerEvent(npcID, grinders, "onTickEndNPC", "onTickEndGrinder")
npcManager.registerEvent(npcID, grinders, "onDrawNPC", "onDrawGrinder")

return gp
