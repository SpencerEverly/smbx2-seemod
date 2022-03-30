local cannons = {}

local npcManager = require("npcManager")
local npcParse = require("npcParse")

local CANNON_CONTENTS = 134

--*************************************************************************
--*
--*								Helper functions
--*
--*************************************************************************

-- Function: areaObstructed
-- Description: checks if the given area is obstructed by players, npcs, or blocks
-- Arguments: x1,y1,x2,y2
--	x1,y1 = top left corner of area to check
--	x2,y2 = bottom right corner
-- Return:
--	true if the area is obstructed; false otherwise
local function areaObstructed(x1,y1,x2,y2,shouldOnlyCheckPlayer)
	if #Player.getIntersecting(x1,y1,x2,y2) > 0 then
		return true
	end

	if shouldOnlyCheckPlayer then return false end

	for _,v in ipairs(NPC.getIntersecting(x1,y1,x2,y2)) do
		if not v.isHidden then
			return true
		end
	end
	for _,v in ipairs(Block.getIntersecting(x1,y1,x2,y2)) do
		if not v.isHidden then
			return true
		end
	end
	return false
end

--*************************************************************************
--*
--*							Engine Block Cannon Settings
--*
--*************************************************************************

--- These properties can be set in npc.txt files for Engine Block Cannons.
-- @table cannon_npc.txt
-- @field containednpc The ID of the NPC to fire if the individual NPC does not provide one. (Default: 134 (SMB2 Bomb))

--- These fields are parsed by npcParse for Engine Block Cannons.
-- @table cannon_npcParse
-- @field containednpc The ID of the NPC to fire. The ID from the containednpc property is used if this is not given.
-- @field fireDelay The fire delay in seconds. (Default: 2.0)
-- @field fireDelayTicks The fire delay in ticks. Takes precedence over fireDelay if defined.

cannons.cannonSharedSettings = {
	gfxoffsetx = 0,
	frames = 1,
	framestyle = 1,
	width = 32,
	height = 32,
	speed = 1,
	nogravity = true,
	noblockcollision = true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	playerblocktop = false,
	playerblock = false,
	noiceball = true,
	jumphurt = true,
	nohurt = true,
	npcblocktop = false,
	npcblock = false,
	noyoshi=true,
	notcointransformable = true,
	-- custom properties
	containednpc = CANNON_CONTENTS,
}

--*************************************************************************
--*
--*							Cannon Event Handlers
--*
--*************************************************************************

function cannons.onStartCannon(npc)
	local parsedData = npc.data
	local data = parsedData._basegame
	local cfg = NPC.config[npc.id]
	
	if npc.ai1 > 0 then
		data.containednpc = npc.ai1
	else
		data.containednpc = cfg.containednpc
	end

	local settings = parsedData._settings

	settings.fireDelayTicks = settings.fireDelayTicks or 128
	
	data.section = npc:mem(0x146, FIELD_WORD)
	data.direction = npc.direction
	
	data.frame = 0
	data.frameTimer = 0
	
	data.fireTimer = 0
	data.init = true
end

function cannons.onTickCannon(npc, horizontal)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame
		if not data.init then
			cannons.onStartCannon(npc)
		end
		local cfg = NPC.config[npc.id]
		
		data.frameTimer = (data.frameTimer + 1) % cfg.framespeed
		if data.frameTimer == 0 then
			data.frame = (data.frame + 1) % cfg.frames
		end

		local settings = npc.data._settings
		
		data.fireTimer = (data.fireTimer + 1) % settings.fireDelayTicks
		if data.fireTimer == 0 then
			local projectile,puffX,puffY
			if not horizontal then -- vertical cannon
				puffX = npc.x + .5 * npc.width
				projectile = NPC.spawn(data.containednpc,npc.x+.5*npc.width,npc.y,data.section,false,true)
				if data.direction == DIR_LEFT then -- facing up
					puffY = npc.y
					projectile.speedY = -10 -- speed values based on comparison with vanilla generators
					projectile.y = projectile.y - projectile.height
				else -- facing down
					puffY = npc.y + npc.height
					projectile.speedY = 8
					projectile.y = npc.y + npc.height
				end
			else -- horizontal cannon
				puffY = npc.y + .5 * npc.height
				projectile = NPC.spawn(data.containednpc,npc.x+.5*npc.width,npc.y,data.section)
				projectile.y = npc.y + (npc.height - projectile.height) * .5
				if data.direction == DIR_LEFT then
					puffX = npc.x
					projectile.speedX = -7
					if (not NPC.config[projectile.id].staticdirection) then
						projectile.direction = DIR_LEFT
					end
					projectile.x = npc.x - projectile.width
				else
					puffX = npc.x + npc.width
					projectile.speedX = 7
					if (not NPC.config[projectile.id].staticdirection) then
						projectile.direction = DIR_RIGHT
					end
					projectile.x = npc.x + npc.width
				end
			end
			projectile.isHidden = true
			projectile.layerName = "Spawned NPCs"
			projectile.friendly = npc.friendly
			local cfg = NPC.config[projectile.id]
			if not areaObstructed(projectile.x,projectile.y,projectile.x+projectile.width,projectile.y+projectile.height, cfg.noblockcollision) then
				projectile.isHidden = false
				projectile:mem(0x136, FIELD_BOOL, not cfg.noblockcollision)
				
				SFX.play(22)
				
				-- spawn the puff effect and center it
                local anim = Animation.spawn(10,puffX,puffY)
                anim.x = anim.x - .5 * anim.width
                anim.y = anim.y - .5 * anim.height
			end
		end
	end
end

function cannons.onDrawCannon(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame
		if not data.init then return end
		local cfg = NPC.config[npc.id]
		frameOffset = (data.direction == -1 and 0) or cfg.frames
		local pr = -45.5
		if cfg.foreground then pr = -15.5 end
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

return cannons
