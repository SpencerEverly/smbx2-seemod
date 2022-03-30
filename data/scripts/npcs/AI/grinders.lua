--- Adds Grinders of 3 different speeds, as well as the Grinder platform
-- @module grinders
-- @author Sambo
-- @version 2.0.4b

local grinders = {}

local lineguide = require("lineguide")
local npcManager = require("npcManager")
local colliders = require("colliders")
local ticker = require("npcs/ai/ticker")

--*************************************************************************
--*
--*								ID Registrations
--*
--*************************************************************************

local GRINDER_PLATFORM_ID = 334
local GRINDER_ID = 179
local GREEN_GRINDER_ID = 485
local YELLOW_GRINDER_ID = 486
local RED_GRINDER_ID = 487

local grinderIDs = {
	GRINDER_PLATFORM_ID,
	GREEN_GRINDER_ID,
	YELLOW_GRINDER_ID,
	RED_GRINDER_ID,
}

-- lineguide.registerNpcs(grinderIDs)

--*************************************************************************
--*
--*							Shared settings for grinders
--*
--*************************************************************************

grinders.sharedGrinderSettings = {
	width = 48,
	height = 24,
	gfxwidth = 64, 
	gfxheight = 64, 
	gfxoffsetx = 0, 
	gfxoffsety = 32,
	frames = 2, 
	framestyle = 0, 
	framespeed = 4, 
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = true,
	noyoshi = true,
	notcointransformable = true
}

grinders.sharedGrinderLineguideProps = {
	activeByDefault = true,
	sensorAlignV = lineguide.ALIGN_BOTTOM,
	fallWhenInactive = true,
}

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

function grinders.onStartGrinder(npc)
	-- initialize drawing data
	local data = npc.data._basegame
	data.frame = 0
	data.frameTimer = 0
end
function grinders.onTickEndGrinder(npc)
	if Defines.levelFreeze then return end

	if npc:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end

	if npc:mem(0x138, FIELD_WORD) > 0 then return end
	
	-- activate the ticking noise
	ticker.shouldTick = ticker.shouldTick or not npc:mem(0x128, FIELD_BOOL)
	
	local data = npc.data._basegame
	local cfg = NPC.config[npc.id]
	-- set the frame counters
	if not data.frame then
		grinders.onStartGrinder(npc)
	end
	data.frameTimer = (data.frameTimer + 1) % cfg.framespeed
	if data.frameTimer == 0 then
		data.frame = (data.frame + 1) % cfg.frames
	end
	
	-- make the grinder harm NPCs and players
	local offy, hitboxHeight = 0,2
	if npc.id == GRINDER_PLATFORM_ID then
		offy = npc.height
		hitboxHeight = 1
	end
	if not npc.friendly then
		for _,p in ipairs(NPC.getIntersecting(npc.x, npc.y + offy, npc.x + npc.width, npc.y + npc.height * hitboxHeight)) do
			if NPC.HITTABLE_MAP[p.id] and p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 then
				p:harm(HARM_TYPE_HELD)
			end
		end
		for _,p in ipairs(Player.getIntersecting(npc.x, npc.y + offy, npc.x + npc.width, npc.y + npc.height * hitboxHeight)) do
			if (not p:isInvincible()) and npc:mem(0x12C, FIELD_WORD) ~= p.idx and npc:mem(0x130, FIELD_WORD) ~= p.idx then
				p:harm()
			end
		end
	end
	
	if data.lineguide.state ~= lineguide.states.ONLINE then
		if npc.speedX == 0 then -- force the NPC to start moving if it isn't
			npc.speedX = lineguide.speeds[npc.id] * npc.direction
		end
	end
	
	-- prevent the grinder from turning around because it hit other NPCs
	if npc:mem(0x120, FIELD_BOOL) and not (npc.collidesBlockLeft or npc.collidesBlockRight) then
		npc:mem(0x120, FIELD_BOOL, false)
	end
	
	-- prevent the grinder from getting a huge combo and giving the player lives
	-- 0x24 = hit counter
	npc:mem(0x24, FIELD_WORD, 0)
end

function grinders.onDrawGrinder(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame
		if not data.frame then return end
		local cfg = NPC.config[npc.id]
		local pr = -75
		if data.lineguide.state == lineguide.states.ONLINE then
			pr = -45
		end

		if cfg.foreground then
			pr = -15
		end
		frameOffset = (cfg.framestyle > 0 and npc.direction == 1 and cfg.frames) or 0
		Graphics.drawImageToSceneWP(
			Graphics.sprites.npc[npc.id].img,
			npc.x + .5 * npc.width - .5 * cfg.gfxwidth + cfg.gfxoffsetx,
			npc.y + npc.height - cfg.gfxheight + cfg.gfxoffsety,
			0,
			(data.frame + frameOffset) * cfg.gfxheight,
			cfg.gfxwidth,
			cfg.gfxheight,
			pr
		)
		-- disable vanilla drawing
		npc.animationFrame = 200
	end
end

return grinders