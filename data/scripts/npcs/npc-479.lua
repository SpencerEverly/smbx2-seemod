-- SMW Yellow Switch Platform
local p = {}

local npcManager = require("npcManager")
local lineguide = require("lineguide")
local switchcolors = require("switchcolors")
local platforms = require("npcs/ai/platforms")

local COLOR_ID = switchcolors.colors.blue

local npcID = NPC_ID
lineguide.registerNpcs(npcID)

--*************************************************************************
--*
--*								Settings
--*
--*************************************************************************

npcManager.setNpcSettings(table.join({id = npcID}, platforms.switchPlatformSettings))

lineguide.properties[npcID] = platforms.sharedSwitchPlatformSettings

--*************************************************************************
--*
--*								Library Event Handlers
--*
--*************************************************************************

local toggle

registerEvent(p, "onDrawEnd")

-- MUST be later than onTickEnd
function p.onDrawEnd()
	toggle = false
end

function switchcolors.onSwitch(color)
	if color == COLOR_ID then
		toggle = true
	end
end

--*************************************************************************
--*
--*								Event Handlers
--*
--*************************************************************************

npcManager.registerEvent(npcID, p, "onTickEndNPC", "onTickEndPlatform")

function p:onTickEndPlatform()
	platforms.onTickEndSwitchPlatform(self, toggle)
end

return p
