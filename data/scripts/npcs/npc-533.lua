-- Vertical Saw
local saw = {}

local npcManager = require("npcManager")
local engineBlocks = require("npcs/ai/engineBlocks")
local saws = require("npcs/ai/saws")

local npcID = NPC_ID
engineBlocks.registerAttachable(npcID)

--*************************************************************************
--*
--*								Settings
--*
--*************************************************************************

npcManager.setNpcSettings(table.join(
	{
		id = npcID,
		gfxwidth = 32,
		gfxheight = 76,
		gfxoffsety = 22,
		nogliding = true
	},
	saws.sawSharedSettings
))

--*************************************************************************
--*
--*								Event Handlers
--*
--*************************************************************************

npcManager.registerEvent(npcID, saw, "onStartNPC", "onStartSaw")
npcManager.registerEvent(npcID, saw, "onTickNPC", "onTickSaw")
npcManager.registerEvent(npcID, saw, "onDrawNPC", "onDrawSaw")

function saw:onStartSaw()
	saws.onStartSaw(self, false)
end

function saw:onTickSaw()
	saws.onTickSaw(self, false)
end

function saw:onDrawSaw()
	saws.onDrawSaw(self, false)
end

return saw
