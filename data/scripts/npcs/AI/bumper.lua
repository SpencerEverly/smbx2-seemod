local bumper = {}

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local imagic = require("imagic")
local rng = require("rng")

local bounceSFX = Misc.resolveSoundFile("bumper")
local jumpSFX = Misc.resolveSoundFile("bumper2")

bumper.ids = {}

function bumper.registerBumper(id)
	npcManager.registerEvent(id, bumper, "onTickNPC")
	npcManager.registerEvent(id, bumper, "onDrawNPC")
    npcManager.registerEvent(id, bumper, "onDrawEndNPC")
    bumper.ids[id] = true
end

local dirFlipMap = table.map{31, 280, 267, 265, 179, 13, 78, 17, 86, 472,133,160, 266, 205, 207, 206}

function bumper.onInitAPI()
	registerEvent(bumper, "onNPCHarm")
end

local function max(old, new)
	local sign, abs = math.sign, math.abs
	if (sign(old) == sign(new) or new == 0) and abs(old) > abs(new) then
		return old
	else
		return new
	end
end

function bumper:bounce(v, midpoint)
	local data = self.data._basegame

	if type(v) == "Player" and self:mem(0x130, FIELD_WORD) == v.idx then
		return
	end

	local playSound = true
	data.ai1 = 60

	local mid_v = Colliders.Point(v.x + v.width/2, v.y + v.height/2)
	
	local collision, point, normal, collider
	if type(data.hitbox) == "CircleCollider" then
		normal = vector.v2(v.x + v.width/2 - midpoint.x, v.y + v.height/2 - midpoint.y):normalize()
	elseif type(data.hitbox) == "BoxCollider" then
		local oldX, oldY = v.x - v.speedX, v.y - v.speedY
		if oldY + v.height <= self.y then
			normal = vector.v2(0, -1)
		elseif oldY >= self.y + self.height then
			normal = vector.v2(0, 1)
		elseif oldX + v.width <= self.x then
			normal = vector.v2(-1, 0)
		elseif oldX > self.x + self.width then
			normal = vector.v2(1, 0)
		else
			normal = vector.zero2
		end
	else
		collision, point, normal, collider = Colliders.linecast(mid_v, midpoint, data.hitbox)
	end

	if normal.x == 0 and normal.y == 0 then
		playSound = false --if you're in this block, the object is inside the bumper, and it would be quite loud to play sound
		normal = vector.v2(v.x + v.width/2 - midpoint.x, v.y + v.height/2 - midpoint.y):normalize()
	end
	
	-- Move the object there and "bounce" them
	local layerSpdX, layerSpdY = utils.getLayerSpeed(self)
	
    local cfg = NPC.config[self.id]
	
	v.speedX = max(v.speedX, normal.x * cfg.bouncestrength + self.speedX + layerSpdX)
	if (type(v) == "NPC" or v.__type == "NPC") and (not NPC.config[v.id].staticdirection) and v.speedX ~= 0 and math.sign(v.speedX) ~= v.direction then
		local cfg = NPC.config[v.id]
		if dirFlipMap[v.id] or cfg.isshell or cfg.isvegetable or cfg.isbot then
			v.direction = -v.direction
			if v.id == 205 or v.id == 206 or v.id == 207 -- wall crawlers
			or v.id == 179 -- grinder
			or v.id == 267 then -- larry
				v.ai2 = -v.ai2
			end
		else
			v:mem(0x120, FIELD_BOOL, true)
			v.speedX = -v.speedX
		end
	end
	local normSpeed = normal.y * cfg.bouncestrength + self.speedY + layerSpdY
	local jumpSpeed = normal.y * cfg.bouncestrength * cfg.jumpmultiplier + self.speedY + layerSpdY
	if type(v) == "Player" then
		v.UpwardJumpingForce = 0
		if normal.y < 0 and v.keys.jump or v.keys.altJump then
			if playSound then
				SFX.play(jumpSFX, nil, nil, 10)
			end
			v.speedY = max(v.speedY, jumpSpeed)
		else
			if playSound then
				SFX.play(bounceSFX, nil, nil, 10)
			end
			v.speedY = max(v.speedY, normSpeed)
		end
	else
		v.speedY = max(v.speedY, normSpeed)
		if playSound then
			SFX.play(bounceSFX, nil, nil, 10)
		end
	end
end

function bumper:onTickNPC()
	local data = self.data._basegame

	if self.isHidden or self:mem(0x12A, FIELD_WORD) <= 0 or self:mem(0x138, FIELD_WORD) ~= 0 then
		local contained = self:mem(0x138, FIELD_WORD)
		if (not data.fixed) and (contained == 2 or contained == 3) then
			-- TEMPORARY, I HOPE HOPE HOPE
			self:transform(self.id)
			data = self.data._basegame
			data.fixed = true
		end
		return
	end

	utils.applyLayerMovement(self)
	
	data.ai1 = data.ai1 or 0

	if not Defines.levelFreeze then
		if data.ai1 > 0 then
			data.ai1 = data.ai1 - 1
		elseif rng.random() < 0.01 then
			data.ai1 = 5
		end
	end

    if self.friendly then return end
    
    local cfg = NPC.config[self.id]

	local midpoint = Colliders.Point(self.x + self.width/2, self.y + self.height/2)
	if not data.hitbox then
		data.hitbox = cfg.hitbox(self)
	end
	if type(data.hitbox) == "BoxCollider" then
		data.hitbox.x = self.x
		data.hitbox.y = self.y
	else
		data.hitbox.x = midpoint.x
		data.hitbox.y = midpoint.y
		if type(data.hitbox) == "CircleCollider" then
			data.hitbox.radius = self.width/2
		end
	end
	
	if cfg.bounceplayer then
		for _,v in ipairs(Player.get()) do
			if v.forcedState == 0 and v.deathTimer == 0 and Colliders.collide(v, data.hitbox) then
				bumper.bounce(self, v, midpoint)
			end
		end
	end
	if cfg.bouncenpc and not Defines.levelFreeze then
		for _,v in ipairs(Colliders.getColliding{a=data.hitbox, btype=Colliders.NPC}) do
			if v.idx ~= self.idx and v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and not NPC.config[v.id].noblockcollision and not v.noblockcollision then
				bumper.bounce(self, v, midpoint)
			end
		end
	end
end

function bumper:onDrawNPC()
	local data = self.data._basegame
	local frame = 0
    data.ai1 = data.ai1 or 0
    local cfg = NPC.config[self.id]
	if data.ai1 > 0 then
		if data.ai1 >= 30 then
			local tex = Graphics.sprites.npc[self.id].img
			local txHeight = tex.height / (2 * cfg.frames * 2^cfg.framestyle)
			frame = -1
			local scale = -math.cos(math.pi * data.ai1 / 5) * 0.1 + 1.1
			imagic.Draw{
				texture = tex,
				x = self.x + self.width/2 + cfg.gfxoffsetx,
				y = self.y + self.height/2 + cfg.gfxoffsety,
				sourceY = txHeight * self.animationFrame,
				width = tex.width * scale,
				height = txHeight * scale,
				sourceHeight = txHeight,
				scene = true,
				priority = cfg.foreground and -15 or -45,
				align = imagic.ALIGN_CENTER
			}
		elseif data.ai1 < 30 and data.ai1 % 15 <= 5 then
			frame = 1
		end
	end
	self.animationFrame = self.animationFrame + frame*(cfg.frames * 2^cfg.framestyle)
end

function bumper:onDrawEndNPC()
	self.animationFrame = self.animationFrame % (NPC.config[self.id].frames * 2^NPC.config[self.id].framestyle)
end

return bumper