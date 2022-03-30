--------------------------------
-- Mutant Vine
--------------------------------
-- Created by Sambo, 29 Dec. 2017

local mutantVine = {}

local npcManager = require("npcManager")
local redirector = require("redirector")
local edibleIDMap

local bor = bit.bor

function mutantVine.onInitAPI()
	registerEvent(mutantVine, "onStart")
	registerEvent(mutantVine, "onDraw")
end

--*************************************************************************
--*
--*							Constants
--*
--*************************************************************************

-- block types
local TYPE_SOLID = 1
local TYPE_SEMISOLID = 2

-- Constants for determining the frame to draw on vines
-- Based on a base-2 system
local WEIGHT_UP = 8
local WEIGHT_RIGHT = 4
local WEIGHT_DOWN = 2
local WEIGHT_LEFT = 1

-- directions
local DIR_UP = -2
local DIR_DOWN = 2

local vineSettings = {}
local vineAnim = {}
local vineIDs = {}
local vineIDMap = {}
local headIDs = {}
local headIDMap = {}

--- Register a new mutant vine head. The IDs of vines for it to spawn are set with the custom NPC properties vineid and
-- thornedid.
-- @function mutantVine.registerHead
-- @tparam int id The ID to register.
function mutantVine.registerHead(id)
	if not vineIDMap[id] then
		npcManager.registerEvent(id, mutantVine, "onStartNPC", "onStartVineHead")
		npcManager.registerEvent(id, mutantVine, "onTickNPC", "onTickVineHead")
		npcManager.registerEvent(id, mutantVine, "onDrawNPC", "onDrawVineHead")
		table.insert(headIDs, id)
		headIDMap[id] = true
	end
end

--- Register a new mutant vine.
-- @function mutantVine.registerVine
-- @tparam int id The ID to register.
-- @tparam[opt] table animationSequence A table of integers representing a custom animation sequence. Zero-indexed. If nil,
-- the default animation sequence (0 - #frames-1) is used
function mutantVine.registerVine(id, animationSequence)
	if not vineIDMap[id] then
		npcManager.registerEvent(id, mutantVine, "onStartNPC", "onStartVine")
		npcManager.registerEvent(id, mutantVine, "onDrawNPC", "onDrawVine")
		table.insert(vineIDs, id)
		vineAnim[id] = {frame = 0, timer = 0, sequence = animationSequence}
		vineIDMap[id] = true
	end
end

function mutantVine.registerEdibleBlock(id)
	table.insert(Block.EDIBLEBYVINE, id)
	Block.EDIBLEBYVINE_MAP[id] = true
	-- update the cached copy in case this was called at runtime for some reason
	edibleIDMap = Block.EDIBLEBYVINE_MAP
end

function mutantVine.onStart()
    for k,v in ipairs(vineIDs) do
        vineSettings[v] = NPC.config[v]
        if vineSettings[v].gfxwidth == 0 then
            vineSettings[v].gfxwidth = vineSettings[v].width
        end
		-- Set the animation sequence to the default sequence. This is delayed until here to ensure that the config for
		-- this NPC ID has been loaded.
		if not vineAnim[v].sequence then
			local sequence = {}
			for i = 0, vineSettings[v].frames - 1 do
				sequence[#sequence+1] = i
			end
			vineAnim[v].sequence = sequence
		end
		-- Get the map for edible blocks
		edibleIDMap = Block.EDIBLEBYVINE_MAP
    end
end

-------------------------------------------------
-- Function: onDraw
-- Description: update the frame counters for the vines
-------------------------------------------------
function mutantVine.onDraw()
    for k,v in ipairs(vineIDs) do
        if vineSettings[v] ~= nil and vineSettings[v].frames ~= nil and vineSettings[v].frames > 1 then
            vineAnim[v].timer = (vineAnim[v].timer + 1) % vineSettings[v].frameSpeed
            if vineAnim[v].timer == 0 then
                vineAnim[v].frame = (vineAnim[v].frame + 1) % vineSettings[v].frames
            end
        end
    end
end

--*************************************************************************
--*
--*							Helper Tables/Functions
--*
--*************************************************************************


-------------------------------------------------
-- Function: get block type
-- Description: returns the type of the block with the given ID
-- Arguments: 
--	id = the ID of the block to check
-- Return: 
--	the type of the block (0 if type not recognized)
-------------------------------------------------
local function getBlockType(id)
	if Block.SIZEABLE_MAP[id] then
		return TYPE_SIZEABLE
	elseif Block.SEMISOLID_MAP[id] and not (Block.PLAYER_MAP[id] or Block.config[id].npcfilter ~= 0) then
		return TYPE_SEMISOLID
	elseif Block.SOLID_MAP[id] then
		return TYPE_SOLID
	else
		return 0
	end
end

--*************************************************************************
--*
--*							Mutant Vine
--*
--*************************************************************************

-- event handlers

-------------------------------------------------
-- Function: onStart vine
-- Description: connects the vine to adjacent vines and blocks
--	note: this connection is for aesthetic purposes only
-------------------------------------------------
function mutantVine.onStartVine(npc)
	local data = npc.data._basegame
	
	local frameOffset = data.frameOffset or 0
	local funcTbl = {NPC.getIntersecting, Block.getIntersecting} -- how to avoid duplicate code
	
	if frameOffset == 0 then
		for i = 1,2 do
			for _,v in ipairs(funcTbl[i](npc.x-32,npc.y-32,npc.x+npc.width+32,npc.y+npc.height+32)) do
				local blockType = 0
				if i == 2 then
					blockType = getBlockType(v.id)
				end
				if v.layerName == npc.layerName and (blockType ~= 0 or (v.__type == "NPC" and vineSettings[v.id])) then
					if npc.y >= v.y and npc.y <= v.y + v.height and blockType ~= TYPE_SEMISOLID and blockType ~= TYPE_SIZEABLE then -- aligned vertically
						if v.x < npc.x then -- adjacent to left
							frameOffset = bor(frameOffset, WEIGHT_LEFT)
						elseif v.x > npc.x then -- to right
							frameOffset = bor(frameOffset, WEIGHT_RIGHT)
						end
					elseif npc.x >= v.x and npc.x <= v.x + v.width then -- aligned horizontally
						if v.y < npc.y and blockType ~= TYPE_SEMISOLID and blockType ~= TYPE_SIZEABLE then -- above
							frameOffset = bor(frameOffset, WEIGHT_UP)
						elseif v.y > npc.y then -- below
							frameOffset = bor(frameOffset, WEIGHT_DOWN)
						end
					end
				end
			end
		end
	end
	
	data.frameOffset = frameOffset
	
	data.initMV = true
end

-------------------------------------------------
-- Function: onDraw vine
-- Description: draws the vine
-------------------------------------------------
function mutantVine.onDrawVine(npc)
	if npc:mem(0x128, FIELD_BOOL) or npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	local data = npc.data._basegame
	if not data.initMV then
		mutantVine.onStartVine(npc)
	end

	-- disable vanilla drawing
	npc.animationFrame = 200
	
	-- set the frame
	local frame, settings = vineAnim[npc.id].sequence[vineAnim[npc.id].frame + 1], vineSettings[npc.id]
	
	local p = -75
	if NPC.config[npc.id].foreground then 
		p = -15
	end

	-- draw the vine
	Graphics.drawImageToSceneWP(
		Graphics.sprites.npc[npc.id].img,
		npc.x + npc.width * .5 - settings.gfxwidth * .5 + settings.gfxoffsetx,
		npc.y + npc.height - settings.gfxheight + settings.gfxoffsety,
		frame * settings.gfxwidth,
		data.frameOffset * settings.gfxheight,
		settings.gfxwidth,
		settings.gfxheight,
		p
	)
end

--*************************************************************************
--*
--*							Mutant Vine Head
--*
--*************************************************************************

-------------------------------------------------
-- Function: onStart vine head
-- Description: initialize the vine head
-------------------------------------------------
function mutantVine.onStartVineHead(npc)
	local data = npc.data._basegame
	data.destX = npc.x
	data.destY = npc.y
	if tostring(npc.layerName) ~= "Default" and tostring(npc.layerName) ~= "" then
		data.layer = tostring(npc.layerName)
	end
	if NPC.config[npc.id].playercontrolled then
		data.inputDirection = DIR_UP
	end
	if not data.direction then data.direction = DIR_UP end
end

-------------------------------------------------
-- Function: get direction
-- Description: returns a set of direction instructions based on the redirectors found in the area
-- Arguments: 
--	x1,y1 = the upper left corner of the zone to check
--	x2,y2 = the lower right corner
-- Return: 
--	directions = a table of direction instructions. Nil if a Terminus was hit. Empty if no direction change
-------------------------------------------------
local function getDirections(x1,y1,x2,y2)
	local directions = {}
	local swapThorned,swapBlockIgnore
	for _,v in ipairs(BGO.getIntersecting(x1,y1,x2,y2)) do
		if not v.isHidden then
			if v.id == redirector.TERMINUS then
				return nil
			elseif v.id == redirector.UP then
				v.isHidden = true
				directions[#directions+1] = DIR_UP
			elseif v.id == redirector.DOWN then
				v.isHidden = true
				directions[#directions+1] = DIR_DOWN
			elseif v.id == redirector.LEFT then
				v.isHidden = true
				directions[#directions+1] = DIR_LEFT
			elseif v.id == redirector.RIGHT then
				v.isHidden = true
				directions[#directions+1] = DIR_RIGHT
			elseif v.id == redirector.TOGGLE then
				swapThorned = true
				v.isHidden = true
			elseif v.id == redirector.SOLIDTOGGLE then
				swapBlockIgnore = true
				v.isHidden = true
			end
		end
	end
	return directions, swapThorned, swapBlockIgnore
end

-------------------------------------------------
-- Function: connect
-- Description: connect the vine to an adjacent vine or block in the given direction
-- Arguments:
--	vData = the data field of the vine to connect 
--	direction = the direction to connect in; one of the direction constants
-------------------------------------------------
local directionToWeight = {
	[DIR_UP]    = WEIGHT_UP,
	[DIR_RIGHT] = WEIGHT_RIGHT,
	[DIR_DOWN]  = WEIGHT_DOWN,
	[DIR_LEFT]  = WEIGHT_LEFT,
}
local function connect(vData, direction)
	vData.frameOffset = bor(vData.frameOffset, directionToWeight[direction])
end

-------------------------------------------------
-- Function: set destination
-- Description: set the destination of the vine head based on the direction it is facing
-- Arguments: hData = the data field of the vine head 
-------------------------------------------------
local directionToDest = {
	[DIR_UP]    = {0, -32},
	[DIR_RIGHT] = {32, 0},
	[DIR_DOWN]  = {0, 32},
	[DIR_LEFT]  = {-32, 0},
}
local function setDestination(hData)
	hData.destX = hData.destX + directionToDest[hData.direction][1]
	hData.destY = hData.destY + directionToDest[hData.direction][2]
end

-------------------------------------------------
-- Function: set speed
-- Description: set the speed of the vine head based on the direction it is facing
-- Arguments:
--	vine = the vine NPC
--	data = the vine NPC's data field
-------------------------------------------------
local directionToSpeed = {
	[DIR_UP]    = {0, -2},
	[DIR_RIGHT] = {2, 0},
	[DIR_DOWN]  = {0, 2},
	[DIR_LEFT]  = {-2, 0},
}
local function setSpeed(vine, data)
	vine.speedX = directionToSpeed[data.direction][1]
	vine.speedY = directionToSpeed[data.direction][2]
end

-------------------------------------------------
-- Function: onTick vine head
-- Description: the AI for the vine head
-------------------------------------------------
function mutantVine.onTickVineHead(npc)
	local data = npc.data._basegame
	if not data.destX then
		mutantVine.onStartVineHead(npc)
	end

	local secs = Section.getActiveIndices()
	local selfsec = npc:mem(0x146,FIELD_WORD)
	
	if not (selfsec == secs[1] or selfsec == secs[2]) then return end
	
	-- prevent despawning
	npc:mem(0x12A, FIELD_WORD, 180)
	npc:mem(0x136, FIELD_BOOL, false)

	if npc:mem(0x12C, FIELD_WORD) > 0 then
		data.destX = npc.x
		data.destY = npc.y
		return
	end
	
	if Defines.levelFreeze then return end
	
	npc.dontMove = false
	-- have we reached the destination?
	local destReached
	if (data.direction == DIR_UP and npc.y <= data.destY) or (data.direction == DIR_DOWN and npc.y >= data.destY) or (data.direction == DIR_LEFT and npc.x <= data.destX) or (data.direction == DIR_RIGHT and npc.x >= data.destX) then
		destReached = true
	end
	
	local noSpawn = false
	
	--Text.windowDebug("dest reached: "..tostring(destReached))
	
	local directions = {}
	-- is the NPC contained in something?
	local containedIn = npc:mem(0x138, FIELD_WORD)
	if containedIn ~= 0 then
		if containedIn == 1 or containedIn == 3 then -- emerging from a block
			if containedIn == 1 then
				npc:mem(0x13C, FIELD_DFLOAT, 32)
			else
				data.direction = DIR_DOWN
				npc:mem(0x13C, FIELD_DFLOAT, 31)
			end
			data.noSpawn = true -- don't spawn a vine behind the block
			--Text.windowDebug("set not to spawn a vine this frame")
			data.connectLast = true
			npc.layerName = "Spawned NPCs"
		end
		return
	end
	
	-- Text.windowDebug("passed containment check")
	
	if destReached then
		npc.x = data.destX
		npc.y = data.destY
		
		-- If overlapping an edible block, then eat it
		if NPC.config[npc.id].eatsblocks then
			for _,v in ipairs(Block.getIntersecting(npc.x+4,npc.y+4,npc.x+npc.width-4,npc.y+npc.height-4)) do
				if edibleIDMap[v.id] then
					v:remove(false)
				end
			end
		end
		
		-- kill the vine head if it has left the section bounds
		local bounds = Section.get(npc:mem(0x146, FIELD_WORD)+1).boundary
		if (npc.x + npc.width <= bounds.left) or (npc.y + npc.height <= bounds.top) or (npc.x >= bounds.right) or (npc.y >= bounds.bottom) then
			npc:kill(1)
			return
		end
		
		-- process the BGOs in the current position to determine what the vine head will do
		local directions,swapThorned,swapBlockIgnore = getDirections(npc.x+4,npc.y+4,npc.x+npc.width-4,npc.y+npc.height-4)
		
		if swapThorned then
			data.spawnThorned = not data.spawnThorned
		end
		if swapBlockIgnore then
			data.ignoreBlocks = not data.ignoreBlocks
		end
		
		local vine, vData
		if not data.noSpawn then
			--Text.windowDebug("spawning a vine this frame")
			-- check for a vine in this position
			local hitVine
			for _,v in ipairs(NPC.getIntersecting(npc.x,npc.y,npc.x+npc.width,npc.y+npc.height)) do
				if vineSettings[v.id] and (v.layerName == npc.layerName or npc.layerName == "Spawned NPCs") then
					hitVine = true
					vine = v
					break
				end
			end
			
			-- spawn a new vine if there isn't one
			-- do it for the vine!
			if not vine then
				-- determine the type of vine to spawn
				local id = (data.spawnThorned and NPC.config[npc.id].thornedid) or NPC.config[npc.id].vineid
				-- 0x146 is the NPC's current section
				-- spawned NPC will respawn
				vine = NPC.spawn(id, npc.x+npc.width/2, npc.y+npc.height/2, npc:mem(0x146, FIELD_WORD), true, true)
				vine.layerName = data.layer or npc.layerName
				vine.friendly = npc.friendly
			end
			
			vine.data._basegame = vine.data._basegame or {}
			vData = vine.data._basegame
			vData.frameOffset = vData.frameOffset or 0 -- initialize the frame offset value
			
			-- connect to the last spawned vine
			-- we are going "into" the vine, so the direction opposite of the direction faced is set
			if data.connectLast then
				connect(vData, -data.direction)
			else
				data.connectLast = true
			end
			
			-- kill the vine head if a vine was hit
			if hitVine then
				npc:kill(1)
				return
			end
		end
		
		-- determine the direction the head will go based on the table of directions
		-- kill the vine head if a terminus or vine was reached
		if (not directions) then -- kill instruction
			-- Text.windowDebug("killing head...")
			npc:kill(1)
			npc:mem(0xDC, FIELD_WORD, 0)
			return -- this NPC is done with life and doesn't need to be processed anymore
		end
		if not NPC.config[npc.id].playercontrolled then -- normal mutant vine head
			if #directions == 1 then -- one direction instruction
				data.direction = directions[1]
			elseif #directions > 1 then -- multiple instructions. more vine heads needed
				for i = 1,(#directions-1) do
					local head = NPC.spawn(npc.id, npc.x, npc.y, npc:mem(0x146, FIELD_WORD))
					head.data._basegame = {}
					head.friendly = npc.friendly
					head.layerName = npc.layerName
					local hData = head.data._basegame
					hData.spawnThorned = data.spawnThorned
					hData.ignoreBlocks = data.ignoreBlocks
					hData.direction = directions[i]
					hData.destX = npc.x
					hData.destY = npc.y
					setDestination(hData)
					hData.noSpawn = true
					hData.connectLast = true
					if vData then
						connect(vData, directions[i])
					end
				end
				data.direction = directions[#directions]
			end
			-- direction is unchanged if the direction instruction set is empty
		else -- player-controlled head (can only be controlled by p1)
			data.direction = data.inputDirection
		end
		
		-- connect the spawned vine to the next vine
		-- set the next destination
		if vData then
			connect(vData, data.direction)
		end
		setDestination(data)
		
		-- check the destination for obstructions
		if not data.ignoreBlocks then
			for _,v in ipairs(Block.getIntersecting(data.destX+4,data.destY+4,data.destX+npc.width-4,data.destY+npc.height-4)) do
				local blockType = getBlockType(v.id)
				if not (NPC.config[npc.id].eatsblocks and edibleIDMap[v.id]) and blockType == TYPE_SOLID and not v.isHidden then
					if data.direction == DIR_DOWN then
						v:hit(true) -- from upper side
					else
						v:hit()
					end
					npc:kill(1) -- kill the vine head if the target area is obstructed
					return
				end
			end
		end
	end
    
    local pi = NPC.config[npc.id].playercontrolled
    if pi then
        local p = Player(pi)
		if p.keys.up then
			data.inputDirection = DIR_UP
		elseif p.keys.left then
			data.inputDirection = DIR_LEFT
		elseif p.keys.down then
			data.inputDirection = DIR_DOWN
		elseif p.keys.right then
			data.inputDirection = DIR_RIGHT
		end
	end
	
	data.noSpawn = false
	
	-- Text.windowDebug("moving head...")
	-- move the vine head
	setSpeed(npc, data)
end

-------------------------------------------------
-- Function: onDraw vine head
-- Description: drawing logic for the vine head
-------------------------------------------------
local directionToFrameOffset = {
	[DIR_UP]    = 0,
	[DIR_LEFT]  = 1,
	[DIR_DOWN]  = 2,
	[DIR_RIGHT] = 3,
}
function mutantVine.onDrawVineHead(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then -- not offscreen
		local data = npc.data._basegame
		local frameOffset
		frameOffset = directionToFrameOffset[data.direction] or 0
		
		if not data.frame then
			data.frame = 0
			data.frameTimer = 0
			local config = NPC.config[npc.id]
			data.frames = config.frames
			data.frameSpeed = config.framespeed
		end
		
		-- disable vanilla animationTimer
		npc.animationTimer = 0
		
		-- set the frame
		npc.animationFrame = data.frame + frameOffset*data.frames
		
		-- advance timers
		if data.frames > 1 then
			data.frameTimer = (data.frameTimer + 1) % data.frameSpeed
			if data.frameTimer == 0 then
				data.frame = (data.frame + 1) % data.frames
			end
		end
	end
end

return mutantVine