--- The "engine blocks" and NPCs that attach to them
-- @module engineBlocks
-- @author Sambo

local engineBlocks = {}

local lineguide = require("lineguide")
local npcManager = require("npcManager")
local npcParse = require("npcParse")
local ticker = require("npcs/ai/ticker")
local vectr = require("vectr")
local colliders = require("colliders")

local xmem = require("xmem")

local LEFT_PUFF_FRAME = 0
local RIGHT_PUFF_FRAME = 2

--*************************************************************************
--*
--*								ID Registrations
--*
--*************************************************************************

-- engine block and attachments
local ENGINE_BLOCK_GREEN_ID = 335
local ENGINE_BLOCK_BLUE_ID = 336
local ENGINE_BLOCK_RED_ID = 337
local SAW_VERT_ID = 533
local SAW_HORZ_ID = 534
local CANNON_VERT_ID = 535
local CANNON_HORZ_ID = 536
local ROPE_ID = 338

local engineBlockIDs = {
	ENGINE_BLOCK_GREEN_ID,
	ENGINE_BLOCK_BLUE_ID,
	ENGINE_BLOCK_RED_ID,
}

-- lineguide.registerNpcs(engineBlockIDs)

--- Attachables
-- A list of NPCs that are registered to attach to engine blocks.
-- Do not modify this table to add a new ID. Call registerAttachable().
engineBlocks.attachables = {}

--- Register Attachable
-- Register an NPC as an engine block attachment.
-- @function registerAttachable
-- @tparam int id The ID to register
local attachablesMap = {}
function engineBlocks.registerAttachable(id)
	table.insert(engineBlocks.attachables, id)
	attachablesMap[id] = true
end

--*************************************************************************
--*
--*							Engine Block Settings
--*
--*************************************************************************

engineBlocks.engineBlockSharedSettings = {
	frames = 4,
	noblockcollision = true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	jumphurt = true,
	nohurt = true,
	noiceball = true,
	noyoshi=true,
	notcointransformable = true
}

--*************************************************************************
--*
--*						Engine Block Event Handlers
--*
--*************************************************************************

-- Attach ropes, saws, and engine block cannons to the engine block
function engineBlocks.onStartEngineBlock(npc)
	local npcsToAttach = {}
	-- TODO: Make this more accurate. Engine blocks placed next to each other "steal" each other's stuff.
	local grab1 = NPC.getIntersecting(npc.x-16,npc.y+8,npc.x+npc.width+16,npc.y+npc.height-8)
	local grab2 = NPC.getIntersecting(npc.x+8,npc.y-16,npc.x+npc.width-8,npc.y+npc.height+16)
	for _,v in ipairs(table.append(grab1, grab2)) do
		if attachablesMap[v.id] and not v.isHidden then
			table.insert(npcsToAttach, v)
			v.isHidden = true -- prevent duplicates
		end
	end
	if #npcsToAttach > 0 then
		lineguide.attachNPCs(npc, npcsToAttach)
		for _,v in ipairs(npcsToAttach) do
			v.isHidden = false
		end
	end
	npc.data._basegame.init = true
end

function engineBlocks.onTickEngineBlock(npc)
	if not npc.data._basegame.init then
		engineBlocks.onStartEngineBlock(npc)
	end
end

function engineBlocks.onTickEndEngineBlock(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		ticker.shouldTick = ticker.shouldTick or not npc:mem(0x128, FIELD_BOOL)
		if npc.animationFrame == LEFT_PUFF_FRAME and npc.animationTimer == 0 then
			Animation.spawn(74, npc.x + 4, npc.y)
		elseif npc.animationFrame == RIGHT_PUFF_FRAME and npc.animationTimer == 0 then
			Animation.spawn(74, npc.x + npc.width - 12, npc.y)
		end
	end
end

return engineBlocks
