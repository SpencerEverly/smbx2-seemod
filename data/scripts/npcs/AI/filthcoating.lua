local filth = {}

filth.id = 488

local npcManager = require("npcmanager")
local particles = require("particles")
local rng = require("rng")

local STATE = {
	TOP = 0,
	BOTTOM = 1,
	LEFT = 2,
	RIGHT = 3,
	UPFLOOR = 4,
	DOWNFLOOR = 5,
	UPCEIL = 6,
	DOWNCEIL = 7
}

local offsets = {
	[STATE.TOP]       = {0.5, 0.0},
	[STATE.BOTTOM]    = {0.5, 1.0},
	[STATE.LEFT]      = {0.0, 0.5},
	[STATE.RIGHT]     = {1.0, 0.5},
	[STATE.UPFLOOR]   = {0.5, 0.5},
	[STATE.DOWNFLOOR] = {0.5, 0.5},
	[STATE.UPCEIL]    = {0.5, 0.5},
	[STATE.DOWNCEIL]  = {0.5, 0.5}
}

local emitters = {}
local sounds = {}
local idMap = {}
local ids = {}
function filth.register(id, emitter, sound)
	if emitter then
		emitters[id] = particles.Emitter(0,0,Misc.multiResolveFile(emitter, "particles/".. emitter))
	end
	if sound then
		sounds[id] = Misc.resolveSoundFile(sound)
	end
	npcManager.registerEvent(id, filth, "onStartNPC")
	npcManager.registerEvent(id, filth, "onTickNPC")
	npcManager.registerEvent(id, filth, "onDrawNPC")
	idMap[id] = true
	table.insert(ids, id)
end

function filth.onInitAPI()
	registerEvent(filth, "onNPCKill")
	registerEvent(filth, "onDraw")
end

function filth.onNPCKill(event, npc, reason)
	if idMap[npc.id] then
		local data = npc.data._basegame
		if data.block then
			mem(0x00B2C8E4, FIELD_DWORD, mem(0x00B2C8E4, FIELD_DWORD) + 10)
			if sounds[npc.id] then
				SFX.play(sounds[npc.id])
			end
			if emitters[npc.id] then
				emitters[npc.id].x = data.block.x + offsets[data.state][1] * data.block.width
				emitters[npc.id].y = data.block.y + offsets[data.state][2] * data.block.height
				emitters[npc.id]:Emit(rng.randomInt(2, 4))
			end
		end
	end
end

function filth.onDraw()
	for _,v in ipairs(ids) do
		emitters[v]:Draw(-5)
	end
end

function filth:onStartNPC()
	local data = self.data._basegame
	local blocks = Colliders.getColliding{a = self, b = Block.SOLID, btype = Colliders.BLOCK}
	if #blocks ~= 1 then --filth needs to be attached to a specific block
		self:kill()
		return
	end
	local block = blocks[1]
	if self.y < block.y then
		data.state = STATE.TOP
	elseif self.y + self.height > block.y + block.height then
		data.state = STATE.BOTTOM
	elseif self.x < block.x then
		data.state = STATE.LEFT
	elseif self.x + self.width > block.x + block.width then
		data.state = STATE.RIGHT
	elseif Block.SLOPE_LR_FLOOR_MAP[block.id] then
		data.state = STATE.UPFLOOR
	elseif Block.SLOPE_LR_CEIL_MAP[block.id] then
		data.state = STATE.UPCEIL
	elseif Block.SLOPE_RL_FLOOR_MAP[block.id] then
		data.state = STATE.DOWNFLOOR
	elseif Block.SLOPE_RL_CEIL_MAP[block.id] then
		data.state = STATE.DOWNCEIL
	else --could not determine which side to attach
		self:kill()
		return
	end
	data.block = block
end

function filth:onTickNPC()
	local data = self.data._basegame
	if not data.block then
		filth.onStartNPC(self)
	end
	if (not data.block) or (not data.block.isValid) or (data.block.isHidden) then
		self:kill()
		return
	end
	self.isHidden = data.block.isHidden
	self.layerName = data.block.layerName
	self.x = data.block.x
	self.y = data.block.y
	if self.isHidden or self.friendly then
		return
	end
	for _,p in ipairs(Player.get()) do
		local collides = data.block:collidesWith(p)
		local state = data.state
		if collides == 1 and state == STATE.TOP or
		   collides == 2 and state == STATE.RIGHT or
		   collides == 3 and state == STATE.BOTTOM or
		   collides == 4 and state == STATE.LEFT or
		   collides == 5 and state >= STATE.UPFLOOR then
			self:kill()
		end
	end
end

local args = {
	priority = -25,
	sceneCoords = true,
	textureCoords = {0,0, 1,0, 1,1, 0,1},
	vertexCoords = {},
	primitive = Graphics.GL_TRIANGLE_FAN
}

local function setCoords(state, block)
	local tc = args.textureCoords
	local ty1, ty2 = state * 0.125, (state + 1) * 0.125 
	tc[2], tc[4], tc[6], tc[8] = ty1, ty1, ty2, ty2
	local vc = args.vertexCoords
	local x1, x2 = block.x - 0.5*block.width,  block.x + 1.5*block.width
	local y1, y2 = block.y - 0.5*block.height, block.y + 1.5*block.height
	vc[1],vc[2], vc[3],vc[4], vc[5],vc[6], vc[7],vc[8] = x1,y1, x2,y1, x2,y2, x1,y2
end

function filth:onDrawNPC()
	local data = self.data._basegame
	if data.state == nil then return end
	self.animationFrame = -1
	args.texture = Graphics.sprites.npc[self.id].img
	setCoords(data.state, data.block)
	Graphics.glDraw(args)
end

return filth