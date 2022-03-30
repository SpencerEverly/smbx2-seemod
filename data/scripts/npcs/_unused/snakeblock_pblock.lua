local snakeblock = {}

snakeblock.id = 344
local id = snakeblock.id

local colliders = require("colliders")
local npcManager = require("npcmanager")
local vectr = require("vectr")

local settings = npcManager.setNpcSettings{
	id = id,
	width = 32,
	height = 32,
	gfxwidth = 32,
	gfxheight = 32,
	jumphurt = true,
	nohurt = true,
	nowaterphysics = true,
	noiceball = true,
	nogravity = true,
	notcointransformable = true,
	-- custom properties
	block = 696
}

function snakeblock.onInitAPI()
	registerEvent(snakeblock, "onTick")
	npcManager.registerEvent(id, snakeblock, "onTickNPC")
	npcManager.registerEvent(id, snakeblock, "onTickEndNPC")
	npcManager.registerEvent(id, snakeblock, "onDrawNPC")
end

function snakeblock:initBlock()
	local data = self.data._basegame
	local block = Block.spawn(data.id, self.x, self.y)
	self.width = block.width
	self.height = block.height
	block.layerObj = self.layerObj
	data.block = block
end

function snakeblock:doThing(x, y)
	if self.direction == -1 then
		snakeblock.eatBlock(self, x, y)
	elseif self.direction == 1 then
		snakeblock.spawnBlock(self, x, y)
	end
	data.lastX = block.x
	data.lastY = block.y
end

function snakeblock:eatBlock(x, y)
	local data = self.data._basegame
	local x = x + data.block.width/2
	local y = y + data.block.height/2
	local score = mem(0x00B2C8E4, FIELD_DWORD)
	for _,b in Block.iterateIntersecting(x - 1, y - 1, x + 1, y + 1) do
		if b.id == data.id and b.layerName == self.layerName then
			b:remove(false)
		end
	end
	mem(0x00B2C8E4, FIELD_DWORD, score)
end

function snakeblock:spawnBlock(x, y)
	local data = self.data._basegame
	local block = Block.spawn(data.id, x, y)
	block.layerObj = self.layerObj
	block.contentID = data.block.contentID
end

function snakeblock:activate()
	local data = self.data._basegame
	self.active = true
	snakeblock.spawnBlock(self, self.x, self.y)
end

function snakeblock:drawBlock()
	local data = self.data._basegame
	Graphics.drawImageToSceneWP(Graphics.sprites.block[data.block.id].img, self.x, self.y, -45)
end

function snakeblock.onTick()
	local npcs = {}
	local needsActivation = false
	for _,c in ipairs(Camera.get()) do
		for _,v in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if v.id == id then
				local data = v.data._basegame
				if not data.active then
					npcs[data.id] = npcs[data.id] or {list = {}, map = {}}
					if not npcs[data.id].map[v] then
						npcs[data.id].map[v] = true
						table.insert(npcs[data.id].list, v)
					end
					needsActivation = true
				end
			end
		end
	end
	if needsActivation then
		local blocks = {list = {}, map = {}}
		for _,p in ipairs(Player.get()) do
			for _,v in Block.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + 1) do
				if (not blocks.map[v.id]) and v:collidesWith(p) == 1 then
					blocks.map[v.id] = true
					table.insert(blocks.list, v.id)
				end
			end
		end
		for _,id in ipairs(blocks.map) do
			if npcs[id] then
				for _,v in ipairs(npcs[id].list) do
					snakeblock.activate(v)
				end
			end
		end
	end
end

function snakeblock:onTickNPC()
	local data = self.data._basegame
	data.block.x = self.x
	data.block.y = self.y
	local lspdx = 0
	local lspdy = 0
	local layer = npc.layerObj
	if layer and not layer:isPaused() then
		lspdx = layer.speedX
		lspdy = layer.speedY
	end
	data.block.speedX = self.speedX + lspdx
	data.block.speedY = self.speedY + lspdy
	if self.speedY == 0 then
		for _,p in ipairs(Player.get()) do
			if p.standingNPC and p.standingNPC.idx == self.idx then
				data.block.speedX = self.layerObj.speedX
				break
			end
		end
	end
end

function snakeblock:onTickEndNPC()
	local data = self.data._basegame
	data.block.x = self.x
	data.block.y = self.y
	data.lastX = data.lastX + self.layerObj.speedX
	data.lastY = data.lastY + self.layerObj.speedY
	local abs = math.abs
	local sign = math.sign
	local dx = self.x - data.lastX
	local dy = self.y - data.lastY
	if abs(dx) >= data.block.lastX and abs(dy) >= data.block.lastY then
		snakeblock.doThing(self, data.lastX + data.block.width*sign(dx), data.lastY + data.block.height*sign(dy))
	elseif abs(dx) >= data.block.lastX then
		snakeblock.doThing(self, data.lastX + data.block.width*sign(dx), data.lastY + data.block.height*(dy/dx))
	elseif abs(dy) >= data.block.lastY then
		snakeblock.doThing(self, data.lastX + data.block.width*(dx/dy), data.lastY + data.block.height*sign(dy))
	end
end

function snakeblock:onDrawNPC()
	local data = self.data._basegame
	snakeblock.drawBlock(self)
end

return snakeblock