-- Horizontal Saw
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
		gfxwidth = 76,
		gfxheight = 32,
		gfxoffsety = 0,
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
	saws.onStartSaw(self, true)
end

function saw:onTickSaw()
	saws.onTickSaw(self, true)
end

function saw:onDrawSaw()
	saws.onDrawSaw(self, true)
end

return saw
