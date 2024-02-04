local snakeBlock =  {}

local BGOGetIntersecting

local newBGOSystem
pcall(function() newBGOSystem = require("see/newBGOSystem") end)

if newBGOSystem == nil then
    BGOGetIntersecting = BGO.getIntersecting
else
    BGOGetIntersecting = newBGOSystem.getIntersecting
end

local npcManager = require("npcManager")
local redirector = require("redirector")
local npcutils = require("npcs/npcutils")

local pnt = Colliders.Point(0,0)
local box = Colliders.Box(0,0,1,1)

local checkIDs = {}
local activateIDs = {}
local needsActivation
local needsChecking
local sectionMap

local BHV_EAT = DIR_LEFT
local BHV_CREATE = DIR_RIGHT

local stock = Graphics.loadImage(Misc.resolveFile("graphics/stock-32.png"))

local idMap = {}

function snakeBlock.register(id)
    npcManager.registerEvent(id,snakeBlock,"onTickNPC")
    npcManager.registerEvent(id,snakeBlock,"onDrawNPC")
    local cfg = NPC.config[id]
    if cfg.debug == 0 then
        Graphics.sprites.npc[id].img = stock
    end
    idMap[id] = true
end

local function doSpeedStuff(self)
	local speedMultiplier = NPC.config[self.id].basespeed * NPC.config[self.id].speed * self.data._settings.speed
	self.speedY = self.data._basegame.vector[2] * speedMultiplier
	if self.speedY > 8 then
		self.y = self.y + self.speedY - 8
	end
	if self.speedY == 0 or NPC.config[self.id].altdiagonalmovement then
		self.speedX = 0
		self.x = self.x + self.data._basegame.vector[1] * speedMultiplier
	else
		self.speedX = self.data._basegame.vector[1] * speedMultiplier
	end
end

function snakeBlock.onTick()
	if needsChecking then
		for _,p in ipairs(Player.get()) do
			for _,v in Block.iterateIntersecting(p.x,p.y+p.height,p.x+p.width,p.y+p.height+1) do
				if checkIDs[v.id] and v:collidesWith(p) == 1 then
					checkIDs[v.id] = nil
					activateIDs[v.id] = true
					needsActivation = true
				end
			end
			local v = p.standingNPC
			if v and idMap[v.id] then
				local npc = v
				if checkIDs[npc.data._basegame.id] then
					checkIDs[npc.data._basegame.id] = nil
					activateIDs[npc.data._basegame.id] = true
					needsActivation = true
				end
			end
		end
	end
	if needsActivation then
		for _,cam in ipairs(Camera.get()) do
			for _,v in NPC.iterateIntersecting(cam.x,cam.y,cam.x+cam.width,cam.y+cam.height) do
				local npc = v
				if idMap[v.id] and not v.isGenerator and npc.data._basegame.id and activateIDs[npc.data._basegame.id] and not npc.data._basegame.active and not npc.isHidden then
					npc.data._basegame.active = true
					if npc.direction == BHV_CREATE then
						local b = Block.spawn(npc.data._basegame.id,npc.x,npc.y)
						b.layerName = npc.layerName
					end
				end
			end
		end
	end
	checkIDs = {}
	activateIDs = {}
	needsActivation = false
	needsChecking = false
	sectionMap = table.map(Section.getActiveIndices())
end

local directions = {
	{-1,0},
	{0,-1},
	{1,0},
	{0,1},
}
 
local function initData(npc, data)
	local settings = npc.data._settings
	local data = npc.data._basegame
	data.id = settings.id or 696
	data.active = settings.active
	if data.active == nil then data.active = false end

	local origX = 1
	local origY = 0
	if settings.directionEnum then
		origX = directions[settings.directionEnum + 1][1]
		origY = directions[settings.directionEnum + 1][2]
	end

	data.originalVector = {origX,origY}

	data.hidden = false
end

function snakeBlock.onTickNPC(npc)
	if Defines.levelFreeze then
		return
	end

	npc:mem(0x12A,FIELD_WORD,180)

	local data = npc.data._basegame
	local settings = npc.data._settings
	if data.hidden == nil then
		initData(npc, data)
	end

	if (not sectionMap[npc.section]) or npc.isHidden then
		data.hidden = true
		--npc.speedX = 0
		--npc.speedY = 0
	end

	if data.point == nil then
		data.point = {x=npc.x,y=npc.y}
		data.delta = {x=0,y=0}
		local block = Block.spawn(data.id,npc.x,npc.y)
		npc.width = block.width
		npc.height = block.height
		data.width = block.width
		data.height = block.height
		if data.active and npc.direction == BHV_CREATE then
			block.layerName = npc.layerName
		else
			block:delete()
		end
		data.vector = data.originalVector
		npc.dontMove = false
	end
	
	if (not sectionMap[npc.section]) or npc.isHidden then
		npc.x = data.point.x
		npc.y = data.point.y
		return
	end

	local isMoving = NPC.config[npc.id].nohitpause or not Layer.isPaused()
	
	if not data.active then
		if npc:mem(0x128,FIELD_WORD) == 0 then
			checkIDs[data.id] = true --Probably worth checking if npc is onscreen before doing this
			needsChecking = true
		end
	else

		local point = data.point
		local delta = data.delta

		local speedMultiplier = NPC.config[npc.id].basespeed * NPC.config[npc.id].speed * npc.data._settings.speed
		if isMoving then
			delta.x = delta.x + math.abs(data.vector[1]) * speedMultiplier
			delta.y = delta.y + math.abs(data.vector[2]) * speedMultiplier
		end
		
		-- This if statement caused the snake block to not properly update once the player entered its section (hidden became false) but before the snake block was scrolled on-screen.
		--if data.hidden then
		--	data.hidden = false
			npc.x = point.x + (delta.x * data.vector[1])
			npc.y = point.y + (delta.y * data.vector[2])
		--end
		
		if delta.x >= data.width or delta.y >= data.height then
			if delta.x >= data.width then
				point.x = point.x + data.width * data.vector[1]
				delta.x = delta.x % data.width
			else
				point.x = npc.x
				delta.x = 0
			end
			local sect = Player.getNearest(npc.x + 0.5 * npc.width, npc.y + 0.5 * npc.height).sectionObj
			if sect.isLevelWarp then
				if point.x < sect.boundary.left then
					point.x = sect.boundary.right
					npc.x = point.x
					delta.x = math.abs(data.vector[1]) * speedMultiplier
				elseif point.x + data.width > sect.boundary.right then
					point.x = sect.boundary.left - data.width
					npc.x = point.x
					delta.x = math.abs(data.vector[1]) * speedMultiplier
				end
			end
			if delta.y >= data.height then
				point.y = point.y + data.height * data.vector[2]
				delta.y = delta.y % data.width
			else
				point.y = npc.y
				delta.y = 0
			end
			local cids = {} --bad name, colliding IDs
			for _,bgo in ipairs(BGOGetIntersecting(npc.x,npc.y,npc.x+data.width,npc.y+data.height)) do
				pnt.x = bgo.x + 16
				pnt.y = bgo.y + 16
				box.x,box.y = point.x,point.y
				box.width = data.width
				box.height = data.height
				if Colliders.collide(pnt,box) and not bgo.isHidden then
					if redirector.MAP[bgo.id] == 3 then
						cids = {} --Don't even bother redirecting if there's a terminus
						npc:kill()
						Graphics.drawImageToSceneWP( --Shouldn't be necessary but without it there's a flicker
							Graphics.sprites.block[data.id].img, --img
							npc.x, --x
							npc.y, --y
							0, --sourceX
							0, --sourceY
							npc.width, --width
							npc.height, --height
							-9.9 --priority
						)
						break
					elseif redirector.MAP[bgo.id] then
						local fnd = false
						for _,v in ipairs(cids) do
							if v == bgo.id then
								fnd = true
								break
							end
						end
						if not fnd then
							table.insert(cids, bgo.id)
						end
					end
				end
			end
			local hasRedirected = false
			local origVector = {data.vector[1],data.vector[2]}
			for _,id in ipairs(cids) do
				if redirector.MAP[id] < 3 then
					if not hasRedirected then
						if redirector.VECTORS[id].x == -origVector[1] and redirector.VECTORS[id].y == -origVector[2] then
							if npc.direction == BHV_EAT then
								npc.direction = BHV_CREATE
							else
								npc.direction = BHV_EAT
							end
						end
						if redirector.TOGGLER == id then
							npc.direction = -npc.direction
						end
						if redirector.VECTORS[id] ~= vector.zero2 then
							data.vector = {redirector.VECTORS[id].x, redirector.VECTORS[id].y}
							--point.x = bgo.x --Used to do this back when assuming corner of BGO lined up with corner of block
							--point.y = bgo.y
							npc.x = point.x
							npc.y = point.y
							delta.x = math.abs(data.vector[1]) * speedMultiplier
							delta.y = math.abs(data.vector[2]) * speedMultiplier
						end
						hasRedirected = true
					elseif hasRedirected then
						local newNPC = NPC.spawn(npc.id,npc.x,npc.y,Player.getNearest(npc.x + 0.5 * npc.width, npc.y + 0.5 * npc.height).section)
						for _,v in ipairs({"active","id","width","height"}) do
							newNPC.data._basegame[v] = data[v]
						end
						newNPC.data._basegame.point = {x=newNPC.x,y=newNPC.y}
						newNPC.data._basegame.originalVector = {redirector.VECTORS[id].x, redirector.VECTORS[id].y}
						newNPC.data._basegame.vector = newNPC.data._basegame.originalVector
						newNPC.data._settings = npc.data._settings
						newNPC.height = data.height
						newNPC.width = data.width
						newNPC.layerObj = npc.layerObj
						newNPC.data._basegame.delta = {}
						newNPC.data._basegame.delta.x = math.abs(data.vector[1]) * speedMultiplier
						newNPC.data._basegame.delta.y = math.abs(data.vector[2]) * speedMultiplier
						if redirector.VECTORS[id].x == -origVector[1] and redirector.VECTORS[id].y == -origVector[2] then
							if npc.direction == BHV_EAT then
								newNPC.direction = BHV_CREATE
							else
								newNPC.direction = BHV_EAT
							end
						else
							newNPC.direction = npc.direction
						end
						doSpeedStuff(newNPC)
					end
				end
				
			end
			
			if npc.direction == BHV_EAT then
				local iBlockRefs = {}
				for k,v in Block.iterateIntersecting(point.x+2,point.y+2,point.x+npc.width-2,point.y+npc.height-2) do
					if v.id == data.id and not v.isHidden and not v:mem(0x5A, FIELD_BOOL) then
						table.insert(iBlockRefs, v)
					end
				end
				for i=#iBlockRefs, 1, -1 do
					iBlockRefs[i]:delete()
				end
			else
				local block = Block.spawn(data.id,point.x,point.y)
				
				block.layerName = npc.layerName
			end
		end
		
		--npc.speedY = npc.data.vector[2] * snakeBlock.spd
		--if npc.speedY > 8 then
		--	npc.y = npc.y + npc.speedY - 8
		--end
		--if npc.speedY == 0 or snakeBlock.settings.altdiagonalmovement then
		--	npc.speedX = 0
		--	npc.x = npc.x + npc.data.vector[1] * snakeBlock.spd
		--else
		--	npc.speedX = npc.data.vector[1] * snakeBlock.spd
		--end
		
		if isMoving then
			doSpeedStuff(npc)
		else
			npc.speedX = 0
			npc.speedY = 0
		end
	
		npc.ai5 = npc.ai5 + 1
		if npc.ai5 == 8 then --should maybe use data but it's probably fine
			npc.ai5 = 0
			for _,cam in ipairs(Camera.get()) do
				if npc.x > cam.x and npc.x < cam.x+cam.width and npc.y > cam.y and npc.y < cam.y+cam.height then
					SFX.play(NPC.config[npc.id].soundid or 74)
					break
				end
			end
		end
	end
end

function snakeBlock.onDrawNPC(npc)
	local data = npc.data._basegame
	if npc.isHidden then
		if data.point then
			npc.x = data.point.x
			npc.y = data.point.y
		end
		return
	end
	if data.id then
		npcutils.drawNPC(npc, {
			priority = snakeBlock.priority,
			texture = Graphics.sprites.block[data.id].img,
			frame = 0
		})
	end
end

function snakeBlock.onInitAPI()
	registerEvent(snakeBlock,"onTick")
end

return snakeBlock
