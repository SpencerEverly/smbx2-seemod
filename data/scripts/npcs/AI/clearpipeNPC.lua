local clearpipeNPC = {}

local cNPC_ID

local clearpipe = require("blocks/ai/clearpipe")
local npcManager = require("npcmanager")
local rng = require("rng")

local helper = require("npcs/npcutils")
local frames = helper.frames
local framespeed = helper.framespeed
local framestyle = helper.framestyle

local UP, DOWN, LEFT, RIGHT = 1, 2, 3, 4

local drawnNPCs = {}

clearpipeNPC.sfx = Misc.resolveSoundFile("warp-short")

clearpipeNPC.groups = {
	shells = {5, 7, 24, 113, 114, 115, 116, 172, 174},
	mushroomBlocks = {154, 155, 156, 157},
	fireballs = {13},
	iceballs = {265},
	iceblocks = {263},
	nofireball = {154, 155, 156, 157},
	yesfireball = {5, 7, 24, 48, 113, 114, 115, 116, 134, 172, 174, 286},
	noiceball = {154, 155, 156, 157},
	yesiceball = {5, 7, 24, 113, 114, 115, 116, 134, 172, 174}
}

clearpipeNPC.maps = {}
for k, v in pairs(clearpipeNPC.groups) do
	clearpipeNPC.maps[k] = table.map(v)
end

clearpipeNPC.ids_map = table.map(table.append(
	{13, 265, 291}, --player projectiles
	{32, 238, 451, 452, 453, 454}, --switches
	clearpipeNPC.groups.shells, --shells
	clearpipeNPC.groups.mushroomBlocks, --mushroom blocks
	{26, 31, 45, 134, 158, 241, 263}, --other held items
	{48, 133, 202, 286, 300, 319, 320, 321, 333, 358, 361, 390, 500, 581, 611}, --bogeys
	NPC.POWERUP, --powerups
	{10, 33, 88, 103, 138, 152, 251, 252, 253, 258, 274}, --coins
	{90, 186, 187, 188, 293} --other collectibles
))
clearpipeNPC.ids_map[34] = nil --no raccoons either
clearpipeNPC.ids = table.unmap(clearpipeNPC.ids_map)

local dummyAnim = {x=0, y=0, width=0, height=0} --it shouldn't matter what happens to this guy

function clearpipeNPC.register(id)
    if not cNPC_ID then
        cNPC_ID = id
        npcManager.registerEvent(cNPC_ID, clearpipeNPC, "onTickNPC")
        npcManager.registerEvent(cNPC_ID, clearpipeNPC, "onDrawNPC")
        NPC.config[cNPC_ID].speed = 1;
    else
        error("The clearpipe NPC ID cannot be changed. If your goal is to change the NPC's behaviour, do so through the exposed fields in npcs/ai/clearpipeNPC.lua")
    end
end

local function spawnAnim(id, npc, variant, offX, offY)
	if Animation.count() > 995 then
		return dummyAnim
	end
	offX = offX or 0
	offY = offY or 0
	if variant then
		return Animation.spawn(id, npc.x+npc.width/2 + offX, npc.y+npc.height/2 + offY, variant)
	else
		return Animation.spawn(id, npc.x+npc.width/2 + offX, npc.y+npc.height/2 + offY)
	end
end

clearpipeNPC.onTickFunctions = {
	[13] = function(npc)
		-- Animation.spawn(77, npc.x+npc.width/2, npc.y+npc.height/2, npc.ai1)
		spawnAnim(77, npc, npc.ai1)
	end,
	[291] = function(npc)
		if rng.random() > 0.9 then
			for i = 1, rng.randomInt(1, 3) do
				-- local a = Animation.spawn(80, npc.x+npc.width/2, npc.y+npc.height/2)
				local a = spawnAnim(80, npc)
				a.x = a.x - a.width/2
				a.y = a.y - a.height/2
				a.speedX = rng.random() * 2 - 1
				a.speedY = rng.random() * 2 - 1
			end
		end
	end,
	[134] = function(npc)
		npc.ai1 = npc.ai1 + 1
		if npc.ai1 >= 350 then
			Explosion.spawn(npc.x+npc.width/2, npc.y+npc.height/2, 2)
			npc:kill()
		elseif npc.ai1 >= 250 then
			npc.ai2 = 1
		end
		if npc.ai2 == 1 then
			npc.ai3 = npc.ai3 + 1
			if npc.ai3 >= 15 then
				npc.ai3 = 0
			end
		end
	end,
	[263] = function(npc)
		npc.ai3 = 0
	end,
	[265] = function(npc)
		if rng.random() > 0.75 then
			-- Animation.spawn(80, npc.x+npc.width/2, npc.y+npc.height/2)
			spawnAnim(80, npc)
		end
	end,
	[300] = function(npc)
		local data = npc.data._basegame
		local data2 = data._clearpipe_storage --yeah sure I can do this no problem
		data2.direction.x = data.speedX * clearpipe.speed
		data2.direction.y = data.speedY * clearpipe.speed
		data2.sparkleTimer = (data2.sparkleTimer + 1) % 4
		if data2.sparkleTimer == 0  then
			-- local sparkle = Animation.spawn(80, npc.x+npc.width/2+rng.randomInt(-18, 18),  npc.y+npc.height/2+rng.randomInt(-18, 18))
			local sparkle = spawnAnim(80, npc, nil, rng.randomInt(-18, 18), rng.randomInt(-18, 18))
			sparkle.x = sparkle.x - sparkle.width/4
			sparkle.y = sparkle.y - sparkle.height/4
		end
	end,
	[390] = function(npc)
		-- Animation.spawn(77, npc.x+npc.width/2, npc.y+npc.height/2)
		spawnAnim(77, npc)
	end
}

clearpipeNPC.onDrawFunctions = {
	[13] = function(npc)
		return frames(npc, 13) * (npc.ai1 - 1)
	end,
	[134] = function(npc)
		if npc.ai2 == 1 then
			local bombOffsets = {0, 0, 3, 3, 1, 1, 2, 2, 0, 0, 3, 3, 1, 1, 2} --this sequence taken from frame analysis and the fact that ai3 cycles from 0 to 14
			return frames(npc, 134) * bombOffsets[npc.ai3 + 1] --what in tarnation was redigit thinking
		end
	end,
	[265] = function(npc)
		if npc.ai1 == 5 then
			return frames(npc, 265)
		end
	end,
	[291] = function(npc)
		return frames(npc, 291) * rng.randomInt(0, 2) --close enough
	end
}

local function getDirection(npc)
	local speedX = npc.data._basegame.speedX
	local speedY = npc.data._basegame.speedY
	if speedY < 0 then
		return UP
	elseif speedY > 0 then
		return DOWN
	elseif speedX < 0 then
		return LEFT
	elseif speedX > 0 then
		return RIGHT
	end
	return 0 --what is this I don't even
end

local function getCollidingBlocks(obj, npc, dir, excludeValidPipes)
	local ids = Block.SOLID .. Block.PLAYER
	if dir == DOWN then
		ids = ids .. Block.SEMISOLID
	end
	local y = npc.y + npc.height
	if npc.id == cNPC_ID then
		y = y - clearpipe.speed
	end
	return Colliders.getColliding{
		a = obj,
		b = ids,
		btype = Colliders.BLOCK,
		filter = function(block)
			if block.isHidden then
				return false
			elseif excludeValidPipes and clearpipe.PIPES[block.id] and clearpipe.PIPES[block.id][dir] then
				return false
			elseif dir == DOWN and Block.SEMISOLID_MAP[block.id] and y > block.y then
				return false
			elseif Block.LAVA_MAP[block.id] then
				return false
			end
			return true
		end
	}
end

local function enterPipe(pipe, npc)
	local dir = 0
	if clearpipe.ENDS[pipe.id] == clearpipe.END.HORZ then
		if npc.speedX < 0 then
			dir = LEFT
		elseif npc.speedX > 0 then
			dir = RIGHT
		end
	elseif clearpipe.ENDS[pipe.id] == clearpipe.END.VERT then
		if npc.speedY < 0 then
			dir = UP
		elseif npc.speedY > 0 then
			dir = DOWN
		end
	end
	
	if clearpipe.PIPES[pipe.id][dir] and #getCollidingBlocks(pipe, npc, dir, true) == 0 then
		local warpOffset = {}
		if dir <= DOWN then
			warpOffset.x = pipe.width/2 - 16
			if dir == UP then
				warpOffset.y = pipe.height
			else
				warpOffset.y = -32
			end
		else
			warpOffset.y = pipe.height/2 - 16
			if dir == LEFT then
				warpOffset.x = pipe.width
			else
				warpOffset.x = -32
			end
		end
		local warpBox = Colliders.Box(pipe.x + warpOffset.x, pipe.y + warpOffset.y, 32, 32)
		if Colliders.collide(warpBox, npc) then
			local tempData = npc.data._basegame or {}
			local tempID = npc.id
			local animFrame = npc.animationFrame
			local animTimer = npc.animationTimer
			
			if tempID == 13 then
				animFrame = animFrame % 4
			end
			
			npc.id = cNPC_ID
			
			npc.data._basegame = {_clearpipe_storage = tempData, id = tempID, animationFrame = animFrame, animationTimer = animTimer}
			
			npc.data._basegame.speedX = clearpipe.DIR_VECTORS[dir].x
			npc.data._basegame.speedY = clearpipe.DIR_VECTORS[dir].y
			npc.speedX = 0
			npc.speedY = 0
			npc:mem(0x120, FIELD_WORD, 0)
			
			local npcOffset = {}
			if dir <= DOWN then
				npcOffset.x = pipe.width/2 - npc.width/2
				if dir == UP then
					npcOffset.y = pipe.height
				else
					npcOffset.y = -npc.height
				end
			else
				npcOffset.y = pipe.height/2 - npc.height/2
				if dir == LEFT then
					npcOffset.x = pipe.width
				else
					npcOffset.x = -npc.width
				end
			end
			npc.x = pipe.x + npcOffset.x
			npc.y = pipe.y + npcOffset.y
			
			if npc:mem(0x12A, FIELD_WORD) >= 179 then
				SFX.play(clearpipeNPC.sfx)
			end
			
			npcManager.refreshEvents(npc)
			
			return true
		end
	end
end
	
local function turnElbow(pipe, npc)
	local data = npc.data._basegame
	data.speedX, data.speedY = data.speedY*clearpipe.ELBS[pipe.id], data.speedX*clearpipe.ELBS[pipe.id] --multiple assignment is cool
	npc.x = pipe.x + pipe.width/2  - npc.width/2
	npc.y = pipe.y + pipe.height/2 - npc.height/2
end

local function turnJunction(pipe, npc)
	local data = npc.data._basegame
	local dir = getDirection(npc)
	local forks = clearpipe.JUNC_FORKS[clearpipe.JUNCS[pipe.id]]
	local offsets = clearpipe.JUNC_OFFSETS[clearpipe.JUNCS[pipe.id]]
	
	local redirect
	local bgos = BGO.getIntersecting(pipe.x, pipe.y, pipe.x+pipe.width, pipe.y+pipe.height)
	for _,bgo in ipairs(bgos) do
		local re_dir = clearpipe.REDIRECTS[bgo.id]
		if re_dir ~= nil and re_dir+re_dir%2 ~= dir+dir%2 and forks[re_dir] then
			redirect = re_dir
			break
		end
	end
	if redirect == nil and not forks[dir] then
		for re_dir, v in ipairs(forks) do
			if v and re_dir+re_dir%2 ~= dir+dir%2 then
				redirect = re_dir
				break
			end
		end
	end
	
	if redirect then
		data.speedX = clearpipe.DIR_VECTORS[redirect].x
		data.speedY = clearpipe.DIR_VECTORS[redirect].y
		npc.x = pipe.x + pipe.width  * offsets.x - npc.width/2
		npc.y = pipe.y + pipe.height * offsets.y - npc.height/2
	end
end

local function isEntering(pipe, npc)
	local data = npc.data._basegame
	return (npc.x < pipe.x and data.speedX > 0) or
	(npc.y < pipe.y and data.speedY > 0) or
	(npc.x + npc.width  > pipe.x + pipe.width  and data.speedX < 0) or
	(npc.y + npc.height > pipe.y + pipe.height and data.speedY < 0)
end

local function interact(npcA, npcB, idA, idB)
	local dataA = npcA.data._basegame
	local dataB = npcB.data._basegame
	local idA = dataA.id
	local idB = dataB.id
	local maps = clearpipeNPC.maps
	if maps.shells[idA] and maps.shells[idB]
	or maps.yesfireball[idA] and maps.fireballs[idB] then
		npcA.id = idA
		npcA:harm(HARM_TYPE_EXT_FIRE)
		npcB:kill()
	elseif maps.yesiceball[idA] and maps.iceballs[idB] then
		npcA.id = idA
		npcA:toIce()
		dataA.id = npcA.id
		npcA.id = cNPC_ID
		npcB:kill()
	elseif maps.iceblocks[idA] and maps.fireballs[idB] then
		dataA.id = npcA.ai1
		npcA.id = cNPC_ID
		npcA.ai1 = 0
		npcB:kill()
	elseif maps.noiceball[idA] and maps.iceballs[idB]
	or maps.nofireball[idA] and maps.fireballs[idB] then
		npcB:kill()
	else
		return false
	end
	return true
end

local tableinsert = table.insert

function clearpipeNPC.onTick()
	local activeSectionBounds = {}
	for k,v in ipairs(Section.getActiveIndices()) do
		local s = Section(v)
		tableinsert(activeSectionBounds, 
			{
				min = s.boundary.left * 100000 + s.boundary.top,
				max = s.boundary.right * 100000 + s.boundary.bottom
			}
		)
	end

	local npcs = {}
	local npcmap = {}
	for _,v in Block.iterateByFilterMap(clearpipe.ENDS) do
		local continue = true
		local x,y,w,h = v.x,v.y,v.width,v.height
		for k,b in ipairs(activeSectionBounds) do
			if b.min < (x+w) * 100000 + y+h and b.max > x*100000 + y then
				continue = false
				break
			end
		end
		if not continue then
			for _,npc in ipairs(NPC.getIntersecting(x-32, y-32, x+w+32, y+h+32)) do
				if clearpipeNPC.ids_map[npc.id] and not npcmap[npc.idx] then
					tableinsert(npcs, npc)
					npcmap[npc.idx] = true
				end
			end
		end
	end
	for _,npc in ipairs(npcs) do
		if npc:mem(0x12C, FIELD_WORD) == 0 and npc:mem(0x12A, FIELD_WORD) > 0 and not(npc:mem(0x64, FIELD_BOOL) or npc.isHidden) then
			local blocks = Colliders.getColliding{
				a = Colliders.Box(npc.x + npc.speedX, npc.y + npc.speedY, npc.width, npc.height),
				b = clearpipe.ENDS_LIST,
				btype = Colliders.BLOCK
			}
			for _,block in ipairs(blocks) do
				if enterPipe(block, npc) then
					break
				end
			end
		end
	end
	local collisions = Colliders.getColliding{
		a = cNPC_ID,
		b = cNPC_ID,
		atype = Colliders.NPC,
		btype = Colliders.NPC
	}
	for _,collision in ipairs(collisions) do
		local npc1, npc2 = unpack(collision)
		if npc1.idx > npc2.idx then
			local id1 = npc1.data._basegame.id
			local id2 = npc2.data._basegame.id
			local interacted = interact(npc1, npc2)
			if id1 ~= id2 and not interacted then
				interact(npc2, npc1)
			end
		end
	end
end

function clearpipeNPC.onNPCKill(event, npc, reason)
	if reason == HARM_TYPE_PROJECTILE_USED and clearpipeNPC.ids_map[npc.id] then
		local box = Colliders.getHitbox(npc)
		if box then --????????????????????
			box.x = box.x + npc.speedX
			box.y = box.y + npc.speedY
			local blocks = Colliders.getColliding{
				a = box,
				b = clearpipe.ENDS_LIST,
				btype = Colliders.BLOCK
			}
			for _,block in ipairs(blocks) do
				if enterPipe(block, npc) then
					event.cancelled = true
					break
				end
			end
		end
	elseif npc.id == cNPC_ID then
		npc.id = npc.data._basegame.id
		npc:kill(reason)
	end
end

function clearpipeNPC:onTickNPC()
	local onscreen = self:mem(0x12A, FIELD_WORD)
	self:mem(0x12A, FIELD_WORD, 180)
	local data = self.data._basegame
	
	if Defines.levelFreeze then
		return
	elseif data.speedX == nil or data.speedY == nil then
		self:transform(data.id or 428--[[because if you're getting unexpected King Bills then you KNOW something is wrong]])
		return
	end
	local bounce = false
	local dir = getDirection(self)
	local blocks = getCollidingBlocks(self, self, dir, false)
	for _,v in ipairs(blocks) do
		if clearpipe.PIPES[v.id] and (clearpipe.PIPES[v.id][dir] or not isEntering(v, self)) then
			if clearpipe.ELBS[v.id] or clearpipe.JUNCS[v.id] or clearpipe.CANNONS[v.id] then
				local midNPC = {}
				local midPipe = {}
				midNPC.x = self.x + self.width/2
				midNPC.nextX = midNPC.x + data.speedX * clearpipe.speed
				midNPC.y = self.y + self.height/2
				midNPC.nextY = midNPC.y + data.speedY * clearpipe.speed
				if clearpipe.ELBS[v.id] or clearpipe.CANNONS[v.id] then
					midPipe.x = v.x + v.width/2
					midPipe.y = v.y + v.height/2
				elseif clearpipe.JUNCS[v.id] then
					midPipe.x = v.x + v.width  * clearpipe.JUNC_OFFSETS[clearpipe.JUNCS[v.id]].x
					midPipe.y = v.y + v.height * clearpipe.JUNC_OFFSETS[clearpipe.JUNCS[v.id]].y
				end
				--if, in the course of this frame's movement, the NPC would pass through the pipe's midpoint, then
				if (dir == UP    and midNPC.y > midPipe.y and midNPC.nextY <= midPipe.y) or
				   (dir == DOWN  and midNPC.y < midPipe.y and midNPC.nextY >= midPipe.y) or
				   (dir == LEFT  and midNPC.x > midPipe.x and midNPC.nextX <= midPipe.x) or
				   (dir == RIGHT and midNPC.x < midPipe.x and midNPC.nextX >= midPipe.x) then
					if clearpipe.ELBS[v.id] then
						turnElbow(v, self)
					elseif clearpipe.JUNCS[v.id] then
						turnJunction(v, self)
					elseif clearpipe.CANNONS[v.id] and data.cannonTimer == nil then
						data.cannonTimer = 0
						data.inCannon = true
						if dir == UP or dir == DOWN then
							self.y = midPipe.y - self.height/2
						else
							self.x = midPipe.x - self.width/2
						end
					end
				end
			end
		else
			bounce = true
		end
	end
	if bounce then
		data.speedX = -data.speedX
		data.speedY = -data.speedY
	end
	
	if data.inCannon then
		if data.cannonTimer < NPC.config[self.id].cannontime then
			data.cannonTimer = data.cannonTimer + 1
		else
			data.cannonTimer = 0 --deliberately not nil, so it doesn't trigger the thingy multiple times
			data.inCannon = false
			data.speedX = data.speedX * clearpipe.cannonBoost
			data.speedY = data.speedY * clearpipe.cannonBoost
			clearpipe.cannonEffect(self)
		end
	else
		self.x = self.x + data.speedX * clearpipe.speed
		self.y = self.y + data.speedY * clearpipe.speed
	end
	self.speedX = 0
	self.speedY = 0
	
	if data.speedX < 0 then
		self.direction = DIR_LEFT
	elseif data.speedX > 0 then
		self.direction = DIR_RIGHT
	end

	if type(clearpipeNPC.onTickFunctions[data.id]) == "function" then
		clearpipeNPC.onTickFunctions[data.id](self)
	end
	
	local frames = frames(self, data.id)
	local framespeed = framespeed(self, data.id)
	data.animationTimer = data.animationTimer + 1
	if data.animationTimer >= framespeed then
		data.animationTimer = 0
		data.animationFrame = data.animationFrame + 1
		if data.animationFrame >= frames then
			data.animationFrame = 0
		end
	end
	
	blocks = Colliders.getColliding{
		a = self,
		b = clearpipe.PIPES_LIST,
		btype = Colliders.BLOCK
	}
	if #blocks == 0 then
		
		local dir = getDirection(self)
		for _,p in ipairs(Player.getIntersecting(self.x, self.y, self.x+self.width, self.y+self.height)) do
			if dir == UP and NPC.config[data.id].playerblocktop then
				p.y = self.y - p.height
			elseif NPC.config[data.id].playerblock then
				if dir == LEFT then
					p.x = self.x - p.width
				elseif dir == RIGHT then
					p.x = self.x + self.width
				end
			end
		end
		
		local tempData = self.data._basegame._clearpipe_storage
		local tempID = data.id
		local animFrame = data.animationFrame
		local animTimer = data.animationTimer
		self.id = tempID
		self.speedX = clearpipe.exitBoost * data.speedX * clearpipe.speed
		self.speedY = clearpipe.exitBoost * data.speedY * clearpipe.speed
		self.animationFrame = animFrame
		self.animationTimer = animTimer
		self.data._basegame = tempData
		
		if onscreen > 179 then
			SFX.play(clearpipeNPC.sfx)
		end
	end
end

function clearpipeNPC:onDrawNPC()
	local data = self.data._basegame
	if data.animationFrame == nil then
		self:transform(data.id or 428--[[because if you're getting unexpected King Bills then you KNOW something is wrong]])
		return
	end
	
	local frameOffset
	if type(clearpipeNPC.onDrawFunctions[data.id]) == "function" then
		frameOffset = clearpipeNPC.onDrawFunctions[data.id](self)
	end

	self.animationFrame = data.animationFrame + (frameOffset or 0)
	self.id = data.id
	tableinsert(drawnNPCs, self)
end

function clearpipeNPC.onDrawEnd()
	for _,npc in ipairs(drawnNPCs) do
		npc.id = cNPC_ID
	end
	drawnNPCs = {}
end

function clearpipeNPC.onInitAPI()
	registerEvent(clearpipeNPC, "onTick")
	registerEvent(clearpipeNPC, "onNPCKill")
	registerEvent(clearpipeNPC, "onDrawEnd")
end

return clearpipeNPC