local donutblock = {}

local npcManager = require("npcmanager")
local rng = require("rng")
local imagic = require("imagic")
local utils = require("npcs/npcutils")

local function inactive(npc)
	return Defines.levelFreeze or npc.isHidden or npc:mem(0x12A, FIELD_WORD) <= 0
end

local function cor_respawn(self)
	local x, y, layer, id, section, width, height, spawnid = self.x, self.y, self.layerObj, self.id, self:mem(0x146, FIELD_WORD), self.width, self.height, self:mem(0xDC, FIELD_WORD)
	for i = 1, lunatime.toTicks(NPC.config[id].cooldown - 0.25) do
		if layer then
			x = x + layer.speedX
			y = y + layer.speedY
		end
		Routine.skip()
	end
	while self.isValid and self:mem(0x12A, FIELD_WORD) >= 179 do
		Routine.skip()
	end
	local tex = Graphics.sprites.npc[id].img
	for scale = 0, 1, 1/lunatime.toTicks(0.25) do
		if layer then
			x = x + layer.speedX
			y = y + layer.speedY
		end
		imagic.Draw{
			texture = tex,
			x = x + width/2,
			y = y + height/2,
			width = tex.width * scale,
			height = tex.height/(2*NPC.config[id].frames) * scale,
			sourceHeight = tex.height/(2*NPC.config[id].frames),
			scene = true,
			priority = -45,
			align = imagic.ALIGN_CENTER
		}
		Routine.skip()
	end
	local npc = NPC.spawn(id, x, y, section, spawnid > 0)
	local lname
	if layer then
		lname = layer.layerName
	else
		lname = ""
	end
	npc:mem(0x3C, FIELD_STRING, lname)
	npc:mem(0xDC, FIELD_WORD, spawnid)
	npc.direction = DIR_LEFT
end

donutblock.ids = {}

function donutblock.register(id)
	npcManager.registerEvent(id, donutblock, "onTickNPC")
	npcManager.registerEvent(id, donutblock, "onDrawNPC")
    npcManager.registerEvent(id, donutblock, "onDrawEndNPC")
    donutblock.ids[id] = true
end

function donutblock:tick()
	local data = self.data._basegame
	if data.shake then
		return
	end
	data.time = (data.time or 0) + 1
	if data.time >= NPC.config[self.id].time then
		data.falling = true
		Routine.run(cor_respawn, self)
		self:mem(0xDC, FIELD_WORD, 0)
	end
	data.shake = true
end

function donutblock:fall()
	self.data._basegame.forcefall = true
end

local donutCollider = Colliders.Box(0,0,0,1)

function donutblock:onTickNPC()
	if inactive(self) then
		return
	end
	local data = self.data._basegame
	if data.falling == nil then
		data.falling = false
	end
	data.time = data.time or 0
	if data.shake then
		data.shake = nil
	else
		data.time = 0
	end
	if data.falling then
		self.speedY = math.min(self.speedY + Defines.npc_grav, NPC.config[self.id].maxspeed)
	else
		self.speedX, self.speedY = utils.getLayerSpeed(self)
		if data.forcefall then
			donutblock.tick(self)
			if data.falling then
				data.forcefall = false
			end
		else
            for _,p in ipairs(Player.get()) do
                donutCollider.x = p.x
                donutCollider.y = p.y + p.height
                donutCollider.width = p.width
				if p.forcedState == 0 and p.deathTimer == 0 and p.y + p.height <= self.y + 0.5 and p.y + p.height >= self.y - 0.5 and p:isGroundTouching() and Colliders.collide(self, donutCollider) then
					donutblock.tick(self)
					break
				end
			end
			
			for _,n in ipairs(NPC.getIntersecting(self.x, self.y - 1, self.x + self.width, self.y)) do
				if not n:mem(0x64, FIELD_BOOL) and NPC.config[n.id].isheavy and n:mem(0x12A, FIELD_WORD) > 0 and n:mem(0x12C, FIELD_WORD) == 0 and n:mem(0x138, FIELD_WORD) == 0 and (((n.y + n.height <= self.y) and n.y + n.height >= self.y - 2) and
					(NPC.config[n.id].nogravity) or n.collidesBlockBottom) then
					donutblock.tick(self)
				end
			end
		end
	end
end

function donutblock:onDrawNPC()
	if inactive(self) then
		return
	end
	local data = self.data._basegame
	if data.falling then
		self.animationFrame = self.animationFrame + NPC.config[self.id].frames
	elseif data.shake then
		self.animationFrame = self.animationFrame + NPC.config[self.id].frames
		if Misc.isPaused() then return end
		data.x = self.x
		self.x = self.x + rng.randomInt(-2, 2)
	end
end

function donutblock:onDrawEndNPC()
	if inactive(self) then
		return
	end
	local data = self.data._basegame
	self.animationFrame = self.animationFrame % NPC.config[self.id].frames
	if Misc.isPaused() then return end
	self.x = data.x or self.x
	data.x = nil
end

return donutblock