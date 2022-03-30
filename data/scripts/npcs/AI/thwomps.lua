--- Configurable thwomps.
-- @module thwomps
local thwomps = {}

-- SUGGESTION
-- Thwomps may currently overshoot on their return path.  Preventing this would be good.

local npcManager = require("npcManager")
local rng = require("rng")
local smallSwitch = require("npcs/ai/smallswitch")
local whistle = require("npcs/ai/whistle")

local DIR_NEG = -1
local DIR_BOTH = 0
local DIR_POS = 1

thwomps.sharedSettings = {
	width = 48,
	height = 64,
	gfxwidth = 48,
	gfxheight = 64,
	nogravity = true,
	frames = 1,
	framestyle = 0,
	speed = 1,
	jumphurt = true,
	spinjumpsafe = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nowaterphysics = true,

	isheavy = 2,

	--lua settings
	slamspeed = 6, --Speed at which thwomp slams. Values above 8 will act a little weird due to vanilla physics.
	acceleration = 0.4, --Rate at which thwomp accelerates. Zero instantly reaches slamspeed.
	recoverspeed = 2, --Speed at which thwomp returns to home position
	accelrecover = 0.2, --Rate at which thwomp accelerates when recovering. Zero instantly reaches recoverspeed.
	earthquake = 0, --Number added to Defines.earthquake upon slamming
	smash = 0, -- 1 breaks a single layer of smashable blocks, 2 breaks through multiple layers, 3 doesn't lose momentum while doing so.
	smashsturdy = false, --Whether thwomp, if smash > 0, breaks "sturdy" blocks (?/Used Blocks + SMW stone tile)
	horizontal = false, --Whether thwomp is a maverick (moves horizontally instead of vertically)
	mad = 0, --Whether thwomp is mad (Constantly slams in either direction). 1 needs triggering, 2 does not.
	cooldown = 100, --How long thwomp stays still after slamming.
	range = 300, --How far "below" thwomp the player can be before he doesn't activate it.
	debug = false --Whether to draw any of the thwomp's box Colliders, and maybe print some text.
}

thwomps.sharedHarmTypes = {
	[HARM_TYPE_HELD] = 10,
	[HARM_TYPE_NPC] = 10, --Nitro blocks trigger this...
	--[HARM_TYPE_FROMBELOW] = 10, --Enable when smashBlocks uses v:hit(true) I guess
	[HARM_TYPE_LAVA] = 10 --Can't guarantee it's lava that's BELOW the thwomp anymore so poof of dust
}

local function collidePlayer(collider, filter) --Returns the first player colliding with a given collider (and not colliding with a second one)
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p, collider) then
			if filter == nil then
				return p
			elseif type(filter) == "function" and filter(p, collider) then
				return p
			elseif not Colliders.collide(p, filter) then
				return p
			end
		end
	end
end

local function smashBlocks(collider, npc_id)
	local count = 0
	local firstlist = Block.MEGA_SMASH
	if NPC.config[npc_id].smashsturdy then
		firstlist = firstlist .. Block.MEGA_STURDY
	end
	local blocks = Colliders.getColliding{
		a = collider,
		b = firstlist,
		btype = Colliders.BLOCK
	}
	for _,v in ipairs(blocks) do
		v:remove(true)
		count = count + 1
	end
	blocks = Colliders.getColliding{
		a = collider,
		b = Block.MEGA_HIT,
		btype = Colliders.BLOCK
	}
	for _,v in ipairs(blocks) do
		--v:hit(true) --Use this one pending some newBlocks fixes
		v:hit()
		count = count + 1
	end
	blocks = Colliders.getColliding{
		a = collider,
		b = 241,
		btype = Colliders.NPC
	}
	for _,v in ipairs(blocks) do
		v:harm(HARM_TYPE_PROJECTILE_USED)
		count = count + 1
	end
	return count
end

--- thwomps.registerThwomp registers an NPC ID as a thwomp.
-- @tparam table settings The NPC config settings, including an ID field.
-- @tparam[opt] table harmTypes The types of damage that should affect this thwomp. If omitted, will use some defaults.
-- @usage thwomps.registerThwomp({id = 1, horizontal = true, mad = 1}, {[HARM_TYPE_HELD] = 10})
function thwomps.registerThwomp(settings, harmTypes)
	if type(settings) == "number" then
		settings = {id = settings}
	end
	harmTypes = harmTypes or settings.harmTypes or thwomps.sharedHarmTypes
	settings = table.join(settings, thwomps.sharedSettings) --for posterity, this function brought to you by classExpander
	npcManager.setNpcSettings(settings)
	npcManager.registerHarmTypes(settings.id, table.unmap(harmTypes),harmTypes)
	NPC.config[settings.id].width  = NPC.config[settings.id].width - 1 --thanks redigit
	NPC.config[settings.id].height = NPC.config[settings.id].height - 1 --thanks redigit
	npcManager.registerEvent(settings.id, thwomps, "onTickNPC")
	npcManager.registerEvent(settings.id, thwomps, "onDrawNPC")
end

function thwomps:onTickNPC()
	local score = mem(0x00B2C8E4, FIELD_DWORD) --darned block:destroy() score
	
	--Brevity stuff
	local settings  = NPC.config[self.id]
	local horz      = settings.horizontal
	local vert      = not horz
	local mad       = settings.mad > 0
	local smash     = settings.smash
	local slam      = settings.slamspeed
	local accel     = settings.acceleration
	local recover   = settings.recoverspeed
	local accel_rec = settings.accelrecover
	local range     = settings.range
	local spawnX    = self:mem(0xA8, FIELD_DFLOAT)
	local spawnY    = self:mem(0xB0, FIELD_DFLOAT)
	
	--Very weird but very useful additional brevity stuff
	--Prevents writing a lot of code twice for mavericks
	--Necessary only so long as thwomps are axis-aligned
	--Each of these variables is named after what it represents for a vertical thwomp.
	--For a horizontal thwomp, it represents its corresponding property.
	local x                   = "x"
	local y                   = "y"
	local width               = "width"
	local height              = "height"
	local speedX              = "speedX"
	local speedY              = "speedY"
	local collidesBlockBottom = 0x0A --"collidesBlockBottom"
	local collidesBlockUp     = 0x0E --"collidesBlockUp"
	if horz then
		--foul, fair = fair, foul
		x, y = y, x
		width, height = height, width
		speedX, speedY = speedY, speedX
		collidesBlockBottom = 0x120 --"collidesBlockRight"
		collidesBlockUp     = 0x120 --"collidesBlockLeft"
	end
	--Initialization
	local data = self.data._basegame
	if not data.init then
		data.init = true
		if settings.mad > 1 and self.direction == DIR_BOTH then
			self.direction = DIR_POS
		end
		data.direction = self.direction
		self.x = self.x + 0.5 --thanks redigit
		self:mem(0xA8, FIELD_DFLOAT, self.x) --thanks redigit
		spawnX = self.x --thanks redigit
		if self:mem(0x138, FIELD_WORD) == 0 then
			self.y = self.y + 0.5 --thanks redigit
		end
		self:mem(0xB0, FIELD_DFLOAT, self.y) --thanks redigit
		spawnY = self.y --thanks redigit
		data.warnbox = Colliders.Box(0, 0, 1, 1)
		data.warnbox[width] = 2 * self[width] + 64
		data.warnbox[height] = self[height] + range
		data.slambox = Colliders.Box(0, 0, 1, 1)
		data.slambox[width] = self[width] + 64
		data.slambox[height] = self[height] + range
		data.ignorebox = Colliders.Box(0, 0, 1, 1)
		data.ignorebox[width] = data.warnbox[width]
		if data.direction == DIR_BOTH then
			data.warnbox[height] = data.warnbox[height] + range
			data.slambox[height] = data.slambox[height] + range
			data.ignorebox[height] = self[height] - 24
			self.direction = 2 * (math.floor(rng.random() + 0.5) - 0.5) --Random value of either 1 or -1
		end
		data.smashbox = Colliders.Box(0, 0, 1, 1)
		data.smashbox[width] = self[width]
		data.state = 0
		data.timer = 0
		data.previous = {speedX = 0, speedY = 0}
	end
	
	if (not Defines.levelFreeze) and self:mem(0x12A, FIELD_WORD) > 0 and self:mem(0x12C, FIELD_WORD) == 0 and self:mem(0x138, FIELD_WORD) == 0 then --Make sure the self's not despawned/hidden/frozen
		
		--Update positions of main box Colliders
		data.warnbox[x] = self[x] - self[width]/2 - 32
		data.warnbox[y] = self[y]
		data.slambox[x] = self[x] - 32
		data.slambox[y] = self[y]
		if data.direction ~= DIR_POS then
			data.warnbox[y] = self[y] - range
			data.slambox[y] = self[y] - range
		end
		data.ignorebox[x] = data.warnbox[x]
		if data.direction == DIR_BOTH then
			data.ignorebox[y] = self[y] + 12
		elseif data.direction == DIR_POS then
			data.ignorebox[y] = self[y] - 2
		else
			data.ignorebox[y] = self[y] + self[height] + 1
		end


		self[speedX] = data.previous[speedX]
		self[speedY] = data.previous[speedY]
		
		--Debug (recommended to turn this on if you want to see how it works)
		if settings.debug then
			if data.state == 0 or not mad then
				data.warnbox:Draw(0xFFFF003F)
				data.slambox:Draw(0xFF00007F)
				if data.direction == DIR_BOTH then
					data.ignorebox:Draw(0xFFFFFF7F)
				else
					data.ignorebox:Draw(0xFFFFFFFF)
				end
			end
			if settings.smash ~= 0 then
				data.smashbox:Draw(0x0000FFFF)
			end
		end
		
		--Slope detection
		if self[speedY] ~= 0 then
			local sign = 1
			if self[speedY] < 0 then
				sign = -1
			end
			local castbox = Colliders.getHitbox(self)
			if castbox then --????????
				castbox[height] = castbox[height] + math.abs(self[speedY])
				if self[speedY] < 0 then
					castbox[y] = castbox[y] + self[speedY]
				end
				local blocks = Colliders.getColliding{
					a = castbox,
					b = Block.SLOPE,
					btype = Colliders.BLOCK
				}
				local marchbox = Colliders.getHitbox(self)
				local function checkForSlopes()
					for _,block in ipairs(blocks) do
						if Colliders.collide(marchbox, block) then
							return true
						end
					end
				end
				marchbox[y] = marchbox[y] + self[speedY]
				if checkForSlopes() then
					for i = sign, self[speedY], sign do
						marchbox[y] = self[y] + i
						if checkForSlopes() then
							self[y] = marchbox[y] - sign
							if vert and self[speedY] < 0 then --thanks redigit
								self[y] = self[y] - sign --thanks redigit
							end --thanks redigit
							self[speedY] = 0
							break
						end
					end
				end
			end
		end
		
		--AI
		if data.state == 0 then --Idle
			local p = data.lastPlayerCheck
			if settings.mad > 1 then
				if data.direction == DIR_BOTH then
					data.direction = 2 * (math.floor(rng.random() + 0.5) - 0.5) --Random value of either 1 or -1
				end
				if data.direction == DIR_POS then
					data.state = 1
				else
					data.state = 4
				end
			elseif p ~= nil and (Colliders.collide(p, data.slambox) and not Colliders.collide(p,data.ignorebox)) or (whistle.getActive()) then
				if data.direction == DIR_BOTH and not whistle.getActive() then
					if p[y] + p[height]/2 >= self[y] + self[height]/2 then
						data.state = 1
					else
						data.state = 4
					end
				elseif data.direction == DIR_POS then
					data.state = 1
				else
					data.state = 4
				end
			end
		elseif data.state == 1 or data.state == 4 then --Slam (Either direction)
			data.smashbox[x] = self[x]
			if data.state == 1 then
				data.smashbox[y] = self[y] + self[height]
			else
				data.smashbox[y] = self[y] - 1
			end
			if (data.state == 1 and (self:mem(collidesBlockBottom,FIELD_WORD)~=0 or self[speedY] <= 0)) or (data.state == 4 and (self:mem(collidesBlockUp,FIELD_WORD)~=0 or self[speedY] >= 0)) then
				if smash > 0 then
					smashBlocks(data.smashbox,self.id)
				end
				local a = Animation.spawn(10, 0, 0)
				a[x] = self[x] - 3
				a[y] = self[y] - a[height]/2
				if data.state == 1 then
					a[y] = a[y] + self[height]
				end
				a[speedX] = -1.5
				local b = Animation.spawn(10, 0, 0)
				b[x] = self[x] + self[width] + 3 - b[width]
				b[y] = a[y]
				b[speedX] = 1.5
				data.state = data.state + 1
			end
			if smash > 1 then
				data.smashbox[y] = data.smashbox[y] + self[speedY]
				local smashedBlocks = smashBlocks(data.smashbox, self.id)
				if smashedBlocks > 0 and smash <= 2 then
					self[speedY] = 0
				end
			end
		elseif data.state == 2 or data.state == 5 then --Cooldown (Either direction)
			if data.timer == 0 then
				SFX.play(37)
				Defines.earthquake = Defines.earthquake + settings.earthquake
				if data.state == 2 and vert then
					for _,v in ipairs(NPC.getIntersecting(self.x, self.y + self.height, self.x + self.width, self.y + self.height + 1)) do
						if v.id == 32 or v.id == 238 then
							v:harm(1)
						elseif smallSwitch.settings[v.id] then
							smallSwitch.press(v)
						end
					end
				end
			end
			if data.timer >= settings.cooldown then
				if mad then
					if data.state == 2 then
						data.state = 4
					else
						data.state = 1
					end
				else
					data.state = data.state + 1
				end
				data.timer = 0
			else
				data.timer = data.timer + 1
			end
		elseif data.state == 3 then --Recovery (positive direction)
			if self:mem(collidesBlockUp,FIELD_WORD)~=0 or (self.y <= spawnY and vert) or (self.x <= spawnX and horz) then
				data.state = 0
				--[[if vert then
					self.y = spawnY
				else
					self.x = spawnX
				end]]
			elseif self[speedY] > 0 then
				data.state = 2
				data.timer = 1
			end
		elseif data.state == 6 then --Recovery (negative direction)
			if self:mem(collidesBlockBottom,FIELD_WORD)~=0 or (self.y >= spawnY and vert) or (self.x >= spawnX and horz) then
				data.state = 0
				--[[if vert then
					self.y = spawnY
				else
					self.x = spawnX
				end]]
			elseif self[speedY] < 0 then
				data.state = 5
				data.timer = 1
			end
		end
		
		--Movement
		if self:mem(0x1C, FIELD_WORD) == 2 then
			slam = slam/2
		end
		if data.state == 1 or data.state == 4 then
			if accel == 0 then
				if data.state == 1 then
					self[speedY] = slam
				else
					self[speedY] = -slam
				end
			else
				--This should probably use a proper clamp function
				if data.state == 1 then
					self[speedY] = math.min( slam, self[speedY] + accel)
				else
					self[speedY] = math.max(-slam, self[speedY] - accel)
				end
			end
		elseif data.state == 3 or data.state == 6 then
			if accel == 0 then
				if data.state == 3 then
					self[speedY] = -recover
				else
					self[speedY] =  recover
				end
			else
				--This should also probably use a proper clamp function
				if data.state == 3 then
					self[speedY] = math.max(-recover, self[speedY] - accel_rec)
				else
					self[speedY] = math.min( recover, self[speedY] + accel_rec)
				end
			end
		else
			self[speedY] = 0
		end

		data.previous[speedX] = self[speedX]
		data.previous[speedY] = self[speedY]

		local layer = self.layerObj
		if layer and not layer:isPaused() then
			self[speedX] = self[speedX] + layer[speedX]
			self[speedY] = self[speedY] + layer[speedY]
		end
	elseif self:mem(0x12A, FIELD_WORD) <= 0 then --Reset used ai values if not spawned
		data.state = 0
		data.timer = 0
	end
	mem(0x00B2C8E4, FIELD_DWORD, score) --darned block:destroy() score
end

function thwomps:onDrawNPC()
	local data = self.data._basegame
	if data.init then
		local frame = 0
		local settings = NPC.config[self.id]
		local p = collidePlayer(data.warnbox)
		if data.state == 1 or data.state == 4 or (settings.mad > 0 and data.state ~= 0) then
			frame = 2
		else
			if p == nil and data.state == 0 and data.direction == DIR_BOTH then
				frame = 6
			elseif p ~= nil and collidePlayer(data.slambox, data.ignorebox) then
				frame = 2
			elseif p ~= nil and collidePlayer(data.warnbox, data.ignorebox) then
				frame = 1
			else
				frame = 0
			end
		end
		if (data.direction == DIR_POS and (settings.mad == 0 or data.state == 0)) or data.state == 1 or (settings.mad > 0 and data.state == 2) or (data.direction == DIR_BOTH and (data.state == 2 or data.state == 3)) then
			frame = frame + 3
		elseif data.direction == DIR_BOTH and (settings.mad == 0 or data.state == 0) and p ~= nil then
			local y, height = "y", "height"
			if settings.horizontal then
				y, height = "x", "width"
			end
			if p[y] + p[height]/2 >= self[y] + self[height]/2 then
				frame = frame + 3
			end
		end
		self.animationFrame = frame * NPC.config[self.id].frames
		data.lastPlayerCheck = p
	end
end

return thwomps