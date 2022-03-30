local saws = {}

local npcManager = require("npcManager")
local npcParse = require("npcParse")

--*************************************************************************
--*
--*								Saw Settings
--*
--*************************************************************************

--- These properties can be set in the .txt files for the Saw NPCs, and are case insensitive.
-- @table saw_npc.txt
-- @field inset How far the saw will be moved into the adjacent engine block on spawn (default: 8)
-- @field toplength The length of the "tip" of the saw (default: 16)
-- @field middlelength The length of the middle piece of the saw. (default: 16)
-- @field baselength The length of the base of the saw (default: 30)

--- These fields will be parsed by npcParse for saws.
-- @table saw_npcParse
-- @field length The Length of the saw. The middle piece of the saw will be repeated a number of times equal to this
-- setting. Must be a non-negative integer. (default: 1)

saws.sawSharedSettings = {
	gfxoffsetx = 0,
	frames = 2,
	framespeed = 4,
	framestyle = 1,
	width = 32,
	height = 32,
	nogravity = true,
	nowaterphysics = true,
	noblockcollision = true,
	jumphurt = true,
	spinjumpSafe = true,
	noiceball = true,
	npcblocktop = false,
	npcblock = false,
	noyoshi=true,
	notcointransformable = true,
	-- custom properties for saws
	inset = 8,
	toplength = 16,
	middlelength = 16,
	baselength = 30,
}

--*************************************************************************
--*
--*							Saw Event Handlers
--*
--*************************************************************************

-- Initialize the width, height, and position of the saw
function saws.onStartSaw(npc, horizontal)
	local data = npc.data._basegame
	local cfg = NPC.config[npc.id]
	
	local settings = npc.data._settings
	-- Handle npcParse fields
	settings.length = settings.length or 1
	
	-- positioning and size
	if not horizontal then
		if npc.direction == DIR_LEFT then
			npc.y = npc.y + npc.height + cfg.inset - cfg.toplength - cfg.middlelength * settings.length - cfg.baselength
		else
			npc.y = npc.y - cfg.inset
		end
		npc:mem(0xB0, FIELD_DFLOAT, npc.y) -- adjust spawnY
		
		npc.height = cfg.toplength + cfg.middlelength * settings.length + cfg.baselength
		npc:mem(0xB8, FIELD_DFLOAT, npc.height) -- adjust spawn height
	else
		if npc.direction == DIR_LEFT then
			npc.x = npc.x + npc.width + cfg.inset - cfg.toplength - cfg.middlelength * settings.length - cfg.baselength
		else
			npc.x = npc.x - cfg.inset
		end
		npc:mem(0xA8, FIELD_DFLOAT, npc.x) -- adjust spawnX
		
		npc.width = cfg.toplength + cfg.middlelength * settings.length + cfg.baselength
		npc:mem(0xC0, FIELD_DFLOAT, npc.width) -- adjust spawnWidth
	end
	
	data.direction = npc.direction
	
	-- animation data
	data.frame = 0
	data.frameTimer = 0
	data.init = true
end

function saws.onTickSaw(npc, horizontal)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame
		if not data.init then
			saws.onStartSaw(npc, horizontal)
		end
		local cfg = NPC.config[npc.id]
		
		data.frameTimer = (data.frameTimer + 1) % cfg.framespeed
		if data.frameTimer == 0 then
			data.frame = (data.frame + 1) % cfg.frames
		end
	end
end

-- Custom drawing for vertical Saws
function saws.onDrawSaw(npc, horizontal)
	
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		npc:mem(0x124, FIELD_BOOL, true)
		local cfg = NPC.config[npc.id]
		local data = npc.data._basegame
		if not data.init then return end
		local settings = npc.data._settings
		
		local img = Graphics.sprites.npc[npc.id].img
		local x,srcX,y,srcY,negative
		if not horizontal then
			x = npc.x
			srcX = 0
			srcW = cfg.gfxwidth
			srcH = cfg.toplength
			if data.direction == DIR_LEFT then
				y = npc.y
				srcY = cfg.gfxheight * data.frame
				negative = false
			else
				y = npc.y + cfg.baselength + cfg.middlelength * settings.length
				srcY = cfg.gfxheight * (data.frame + cfg.frames + 1) - cfg.toplength 
				negative = true
			end
		else
			y = npc.y
			srcW = cfg.toplength
			srcH = cfg.gfxheight
			if data.direction == DIR_LEFT then
				x = npc.x
				srcX = 0
				srcY = cfg.gfxheight * data.frame
				sign = 1
				negative = false
			else
				x = npc.x + cfg.baselength + cfg.middlelength * settings.length
				srcX = cfg.gfxwidth - cfg.toplength
				srcY = cfg.gfxheight * (data.frame + cfg.frames)
				negative = true
			end
		end
		local pr = -45.5
		if cfg.foreground then pr = -15.5 end
		
		-- draw the saw
		-- Add 1 to the number of loop iterations on both ends
		for i = 0, settings.length + 1 do
			Graphics.drawImageToSceneWP(
				img,
				x,
				y,
				srcX,
				srcY,
				srcW,
				srcH,
				pr
			)
			if i == 0 then -- *screams internally*
				if not horizontal then
					srcH = cfg.middlelength
					if not negative then
						y = y + cfg.toplength
						srcY = srcY + cfg.toplength
					else
						y = y - cfg.middlelength
						srcY = srcY - cfg.middlelength
					end
				else
					srcW = cfg.middlelength
					if not negative then
						x = x + cfg.toplength
						srcX = srcX + cfg.toplength
						if settings.length == 0 then
							srcX = srcX + cfg.middlelength
							srcW = cfg.baselength
						end
					else
						x = x - cfg.middlelength
						srcX = srcX - cfg.middlelength
						if settings.length == 0 then
							srcX = srcX - cfg.baselength
							srcW = cfg.baselength
						end
					end
				end
			elseif i == settings.length then
				if not horizontal then
					srcH = cfg.baselength
					if not negative then
						y = y + cfg.middlelength
						srcY = srcY + cfg.middlelength
					else
						y = y - cfg.baselength
						srcY = srcY - cfg.baselength
					end
				else
					srcW = cfg.baselength
					if not negative then
						x = x + cfg.middlelength
						srcX = srcX + cfg.middlelength
					else
						x = x - cfg.baselength
						srcX = srcX - cfg.baselength
					end
				end
			else
				if not horizontal then
					if not negative then
						y = y + cfg.middlelength
					else
						y = y - cfg.middlelength
					end
				else
					if not negative then
						x = x + cfg.middlelength
					else
						x = x - cfg.middlelength
					end
				end
			end
		end
		
		npc.animationFrame = 200
	end
end

return saws
