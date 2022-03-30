-- Vertical Engine Block Cannon
local cannon = {}

local npcManager = require("npcManager")
local npcParse = require("npcParse")
local engineBlocks = require("npcs/ai/engineBlocks")
local cannons = require("npcs/ai/cannons")

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
		gfxheight = 64,
		gfxoffsety = 16,
		nogliding = true,
		staticdirection = true
	},
	cannons.cannonSharedSettings
))

--*************************************************************************
--*
--*								Event Handlers
--*
--*************************************************************************

npcManager.registerEvent(npcID, cannons, "onStartNPC", "onStartCannon")
npcManager.registerEvent(npcID, cannon, "onTickNPC", "onTickCannon")
npcManager.registerEvent(npcID, cannons, "onDrawNPC", "onDrawCannon")

function cannon:onTickCannon()
	cannons.onTickCannon(self, false)
end

return cannon
