local birbs = {}
local npcManager = require("npcManager")
local rng = require("rng")
local whistle = require("npcs/ai/whistle")

local flapSound = Misc.resolveSoundFile("birdflap")

birbs.ids = {}

function birbs.register(id)
    npcManager.registerEvent(id, birbs, "onTickNPC")
    birbs.ids[id] = true
end

local moveState = {HOP=1,PECK=2,FLYAWAYNOWFLYAWAYNOWFLYAWAY=3}

local function performTurn(self)
	local data = self.data._basegame

	--windowDebug("TURN")

	if  self.direction == DIR_LEFT  then
		self.direction = DIR_RIGHT
	else
		self.direction = DIR_LEFT
	end
	self.speedX = -self.speedX
	data.turning = true
	data.moveTimer = 5
end


-- Checks to see if at the edge; if so, performs a turn and returns true.  Otherwise, returns false
local function turnAtEdge(self)
	local dirMult = 1
	if  self.direction == DIR_LEFT  then  dirMult = -1;  end;
	local feet = Colliders.Box(self.x + 0.5 * self.width + self.width*dirMult,self.y+self.height,self.width,1)

	local footCollisions = Colliders.getColliding{
	
		a=	feet,
		b=	Block.SOLID ..
			Block.PLAYER ..
			Block.SEMISOLID .. 
			Block.SIZEABLE,
		btype = Colliders.BLOCK,
		filter= function(other)
			if (not other.isHidden  and  other:mem(0x5A, FIELD_WORD) == 0) then
				if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
					return true
				end
				if feet.y <= other.y + 2 then
					return true
				end
			end
			return false
		end

	}

	if #footCollisions == 0 then
		performTurn(self)
	end
end


local function performHop(self)
	turnAtEdge(self)
	self.speedY = -2
	if  self.direction == DIR_LEFT  then
		self.speedX = -1
	elseif  self.direction == DIR_RIGHT  then
		self.speedX = 1
	end
end


local function performPeck(self)
	local data = self.data._basegame

	data.longpeck = true
	data.moveTimer = 22

	if  rng.random() > 0.5  then
		data.pecking = true
		data.longpeck = false
		data.moveTimer = 6
	end
end


local function startPecking(self)
	local data = self.data._basegame

	data.turning   = false
	data.pecking   = false
	data.moveState = moveState.PECK
	data.moveCount = rng.randomInt(1,8)
	data.moveTimer = 0
end

local function startHopping(self)
	local data = self.data._basegame

	if  rng.random() > 0.5  then
		performTurn(self)
	end
	data.moveCount = rng.randomInt(4,8)
	data.moveState = moveState.HOP
end


function birbs:onTickNPC()

	if Defines.levelFreeze then
		return
	end

	local birb = self


	-- Initialize properties
	local frameCount = NPC.config[birb.id].frames

	local data = birb.data._basegame

	if  data.moveState == nil  then
		data.pecking = false
		data.longpeck = false
		data.turning = false
		data.moveState = moveState.HOP
		if  NPC.config[birb.id].togrounded ~= nil  then
			data.moveState = moveState.FLYAWAYNOWFLYAWAYNOWFLYAWAY
		end
	end

	data.moveCount  = data.moveCount  or  rng.randomInt(2,4)
	data.moveTimer  = data.moveTimer  or  0
	data.initID     = data.initID     or  birb.id
	data.flapFrame  = data.flapFrame  or  0

	if  data.brave == nil  then
		data.brave = birb.friendly
	end

	if  birb.direction == DIR_RANDOM  then
		birb.direction = rng.irandomEntry{DIR_LEFT, DIR_RIGHT}
	end


	-- Reset stuff and stop the update if despawned
	if  birb:mem(0x12A, FIELD_WORD) <= 0  or  birb:mem(0x124, FIELD_WORD) == 0 or  birb:mem(0x138, FIELD_WORD) > 0 then
		birb.id = data.initID
		birb.speedX = 0
		birb.speedY = 0
		data.moveCount = rng.randomInt(4,8)
		data.moveState = nil
		return
	end

	-- if not set friendly in the editor, flee when approached
	if  not birb.friendly  then
		birb.friendly = true
	end

	-- Manage animation
	data.animFrame = data.animFrame  or  1

	if  data.moveState == moveState.HOP  then
		birb.animationTimer = 500
		data.animFrame = -1
		if  data.turning  then
			data.animFrame = 1
		end

	elseif  data.moveState == moveState.PECK  then
		birb.animationTimer = 500
		data.animFrame = -1
		if  data.pecking  then
			data.animFrame = 0
		end

	elseif  data.moveState == moveState.FLYAWAYNOWFLYAWAYNOWFLYAWAY  then
		data.animFrame = nil
		--birb.animationFrame = math.max(3, birb.animationFrame)
		--if  birb.direction == DIR_RIGHT  then
		--	birb.animationFrame = math.max(frameCount+3, birb.animationFrame)
		--end
	end

	if  birb.direction == DIR_RIGHT  and  data.animFrame ~= nil  then
		data.animFrame = data.animFrame + frameCount
	end

	birb.animationFrame = data.animFrame  or  birb.animationFrame
	--Graphics.draw {type = RTYPE_TEXT, x=birb.x, y=birb.y-60, text=tostring(birb.animationFrame), isSceneCoordinates=true}


	-- Manage movement
	data.moveTimer = data.moveTimer - 1

	if  not data.brave  and  data.moveState ~= moveState.FLYAWAYNOWFLYAWAYNOWFLYAWAY  then
		local p = Player.getNearest(birb.x + 0.5 * birb.width, birb.y + 0.5 * birb.height)
		if  (math.abs(p.x + 0.5 * p.width - birb.x + 0.5 * birb.width) < 96  and  math.abs(p.y + 0.5 * p.height - birb.y + birb.height) < 64)
		or  (whistle.getActive())		then
			birb.speedY = -1
			data.moveState = moveState.FLYAWAYNOWFLYAWAYNOWFLYAWAY
			birb.id = NPC.config[birb.id].toflying  or  birb.id
			birb.dontMove = false

			birb.direction = DIR_LEFT
			if  p.x + 0.5 * p.width < birb.x + 0.5 * birb.width  then  birb.direction = DIR_RIGHT;  end;

			SFX.play(flapSound)
		end
	end


	if  data.moveState == moveState.HOP  then
		-- Stop turning
		if  data.moveTimer <= 0  then
			data.turning = false
		end

		-- If grounded, either keep hopping or start pecking
		if  birb:mem(0x0A, FIELD_WORD) == 2  then
			birb.speedX = 0.01*birb.speedX
			if  data.moveCount > 0  then
				data.moveCount = data.moveCount-1
				performHop(birb)
			else
				startPecking(birb)
			end
		end

	elseif  data.moveState == moveState.PECK  then
		birb.speedX = 0
		if  data.moveTimer <= 0  then

			-- Start a long peck
			if  data.longpeck  then
				data.longpeck = false
				data.pecking = true
				data.moveTimer = 8

			-- Stop a peck
			elseif  data.pecking  then
				data.pecking = false
				data.moveCount = data.moveCount-1
				data.moveTimer = 8

			-- Start a peck
			else
				if  data.moveCount <= 0  then
					startHopping(birb)
				else
					performPeck(birb)
				end
			end
		end

	elseif  data.moveState == moveState.FLYAWAYNOWFLYAWAYNOWFLYAWAY  then
		birb.speedY = birb.speedY - 0.29
		if  birb.direction == DIR_LEFT  then
			birb.speedX = -3
		else
			birb.speedX = 3
		end
	end
end


return birbs