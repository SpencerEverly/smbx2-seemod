-- The Frickin' Rope
local rope = {}

local npcManager = require("npcManager")
local npcParse = require("npcParse")
local engineBlocks = require("npcs/ai/engineBlocks")

local npcID = NPC_ID

engineBlocks.registerAttachable(npcID)

local function playerClimbingNPC(plr, npc)
	return plr.climbing and plr.climbingNPC and plr.climbingNPC == npc
end

--*************************************************************************
--*
--*								Rope Settings
--*
--*************************************************************************

--- These properties can be set in the .txt files for Rope NPCs, and are case insensitive.
-- @table rope_npc.txt
-- @field mainlength The length of the main piece of the rope. (default: 32)
-- @field endlength The length of the end piece of the rope. (default: 32)
-- @field extension The length of extra rope to be drawn at the top. This is to prevent cutoff when attached to engine
-- blocks. (default: 4)
-- @field centerplayers Whether players climbing the rope will be centered on the rope like in SMW. (default: true)

--- These fields are parsed by npcParse for ropes.
-- @table rope_npcParse
-- @field length The number of times the main piece of the rope will be repeated. Must be a non-negative integer.
-- (default: 1)

npcManager.setNpcSettings{
	id = npcID, 
	width = 12, 
	height = 64, 
	gfxwidth = 12,
	gfxheight = 64,
	noblockcollision = true, 
	nowaterphysics = true,
	nohurt = true, 
	jumphurt = true,
	isvine = true,
	nogravity = true,
	noyoshi=true,
	-- Custom properties
	mainlength = 32,
	endlength = 32,
	extension = 4,
	centerplayers = true,
	activeByDefault = false,
	nogliding = true,
	notcointransformable = true
}

--*************************************************************************
--*
--*								Rope Event Handlers
--*
--*************************************************************************

npcManager.registerEvent(npcID, rope, "onStartNPC", "onStartRope")
npcManager.registerEvent(npcID, rope, "onTickNPC", "onTickRope")
npcManager.registerEvent(npcID, rope, "onTickEndNPC", "onTickEndRope")
npcManager.registerEvent(npcID, rope, "onDrawNPC", "onDrawRope")

function rope.onStartRope(npc)
	local data = npc.data._basegame
	local cfg = NPC.config[npc.id]
	
	local settings = npc.data._settings
	settings.length = settings.length or 1
	
	npc.height = cfg.mainlength * settings.length + cfg.endlength
	npc:mem(0xB8, FIELD_DFLOAT, npc.height)
	
	data.frame = 0
	data.frameTimer = 0

	if settings.activeByDefault == nil or settings.activeByDefault == 0 then
		settings.activeByDefault = NPC.config[npc.id].activeByDefault
	else
		settings.activeByDefault = settings.activeByDefault == 1
	end
	data.activated = settings.activeByDefault
end

function rope.onTickRope(npc)
	local data = npc.data._basegame
	
	if not data.frame then
		rope.onStartRope(npc)
	end
	
	data.velocity = {
		x = npc.speedX,
		y = npc.speedY,
	}
end

local invalidStates = { [3] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [499] = true }

function rope.onTickEndRope(npc)

	local data = npc.data._basegame
	if not data.frame then
		rope.onStartRope(npc)
	end

	local settings = npc.data._settings
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local cfg = NPC.config[npc.id]
		
		data.frameTimer = (data.frameTimer + 1) % cfg.framespeed
		if data.frameTimer == 0 then
			data.frame = (data.frame + 1) % cfg.frames
		end
		if data.parent then
			data.parent.data._basegame.lineguide.activeByDefault = settings.activeByDefault
			data.parent.data._basegame.lineguide.active = data.activated
		end

		local lyr = npc.layerObj
		
		if not lyr or (lyr.speedX == 0 and lyr.speedY == 0) then
			npc.x = npc.x + npc.speedX
			npc.y = npc.y + npc.speedY
		else
			npc.x = npc.x - npc.speedX + data.velocity.x
			npc.y = npc.y - npc.speedY + data.velocity.y
		end
		
		for _,v in ipairs(Player.get()) do
			if playerClimbingNPC(v, npc) then
				-- move the player if it won't clip them through a wall, and isn't trying to warp away/hasn't been moved to a new section
				if cfg.centerplayers and not invalidStates[v.forcedState] and v.section == npc.section and v.deathTimer == 0 and v:mem(0x148, FIELD_WORD) == 0 and v:mem(0x14C, FIELD_WORD) == 0 then
					v.x = npc.x + .5 * (npc.width - v.width)
				elseif invalidStates[v.forcedState] then
					v:mem(0x40, FIELD_WORD, 0)
				end
				if v.y < npc.y then
					v.y = npc.y -- fix for players occasionally falling off the rope if they're at the very top.
				end
				-- activate the engine block if it is inactive
				if not data.activated then
					if data.parent then
						data.parent.data._basegame.lineguide.active = true
					end
					data.activated = true
				end
			end
		end
	else
		local data = npc.data._basegame
		data.activated = settings.activeByDefault
	end
end

function rope.onDrawRope(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame
		local cfg = NPC.config[npc.id]
		if data.frame == nil then return end
		
		local img = Graphics.sprites.npc[npc.id].img
		local x = npc.x + .5 * (npc.width - cfg.gfxwidth)
		local y = npc.y
		
		local pr
		if data.parent then
			pr = -45.5
		else
			pr = -75
		end
		
		if cfg.foreground then pr = -15.5 end

		local settings = npc.data._settings
		
		-- draw the extension at the top
		Graphics.drawImageToSceneWP(
			img,x,
			y - cfg.extension,
			0,
			cfg.mainlength - cfg.extension,
			cfg.gfxwidth,
			cfg.extension,
			pr
		)
		
		for i = 1, settings.length do
			Graphics.drawImageToSceneWP(
				img,x,y,0,0,
				cfg.gfxwidth,
				cfg.mainlength,
				pr
			)
			y = y + cfg.mainlength
		end
		
		Graphics.drawImageToSceneWP(
			img,x,y,0,
			cfg.mainlength,
			cfg.gfxwidth,
			cfg.endlength,
			pr
		)
	
		npc.animationFrame = -1
	end
end

return rope
