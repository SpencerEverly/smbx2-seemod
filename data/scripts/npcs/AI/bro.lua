--[[
-- This code originally written by Minus
-- Heavily modified for basegame by Saturnyoshi
--]]

local rng = require("rng")
local npcManager = require("npcManager")
local playerStun = require("playerstun")

local hammerBros = {}

local configs = {}
function hammerBros.register(id)
	npcManager.registerEvent(id, hammerBros, "onTickNPC")
	npcManager.registerEvent(id, hammerBros, "onDrawNPC")
	configs[id] = NPC.config[id]
end

function hammerBros.setDefaultHarmTypes(id, effect)
	npcManager.registerHarmTypes(id,
		{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP},
		{
			[HARM_TYPE_JUMP] = {id = effect, speedX = 0, speedY = 0},
			[HARM_TYPE_FROMBELOW] = effect,
			[HARM_TYPE_HELD] = effect,
			[HARM_TYPE_PROJECTILE_USED] = effect,
			[HARM_TYPE_NPC] = effect,
			[HARM_TYPE_TAIL] = effect,
			[HARM_TYPE_SPINJUMP] = 10,
			[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
		}
	)
end

--[[local friendlyProjectileMap = {
	[617] = 171,
}]]

-----------------------------------------------------------

-- Get the x-coordinate of the player whose x-position is closest to the given bro.
local function getNearestPlayerX(bro)
	local nearestX = -1
	local nearestDist
	for k, p in ipairs(Player.get()) do
		if nearestX == -1 or math.abs(p.x - bro.x) < nearestDist then
			nearestX = p.x
			nearestDist = math.abs(p.x - bro.x)
		end
	end

	return nearestX
end

-- Get the direction the bro is actually facing.  This is independent of the "direction" field for the NPC, due to the fact that said field always adjusts
-- itself based on the speedX of the associated NPC, whereas hammer bros can walk backward but still be facing the same direction, for instance.
-- The direction the sprite is drawn and the direction hammers are thrown is always based on what we get from this value.
local function getDirectionFacing(bro)

	if not NPC.config[bro.id].followplayer then return bro.data._basegame.initialDirection end
	local grabbed = bro:mem(0x12E, FIELD_WORD) ~= 0 or bro:mem(0x136, FIELD_BOOL)

	-- The hammer bro faces the player if not grabbed or in a colliding state (i.e., when thrown or fired from a projectile generator), or the direction in
	-- the NPC direction field, otherwise.

	if (not grabbed) and bro.x < getNearestPlayerX(bro) or grabbed and bro.direction == 1 then
		return 1
	end

	return -1
end

local function drawHeldNPC(id, x, y, direction)
	local config = NPC.config[id]
	local offsy = 0
	local height = config.gfxheight
	if height <= 0 then
		height = config.height
	end
	local width = config.gfxwidth
	if width <= 0 then
		width = config.width
	end
	if config.framestyle ~= 0 and direction == 1 then
		offsy = height * config.frames
	end
	Graphics.drawImageToSceneWP(Graphics.sprites.npc[id].img, x + config.gfxoffsetx - width / 2, y - height + config.gfxoffsety, 0, offsy, width, height, 1, -46)
end

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the hammer bro's relevant parameters (no data is used here, due to
-- the small number of such parameters needed).
local function initialize(bro)
	local config = configs[bro.id]
	local data = bro.data._basegame
	-- Flag used to denote whether or not this NPC has been initialized previously.  Set to 1 when initialized.
	bro.ai1 = 1

	-- Left/right movement timer.  Starts at 100.  Once it reaches 0, the bro switches directions.
	data.walkTimer = config.walkframes
  
	-- The bro's jumping timer.  Starts at 300.  Once it reaches 0, the bro leaps high into the air.
	data.jumpTimer = config.jumpframes

	-- The bro's toss timer.  Some value between 50 and 80.  Once it reaches the target, the bro pulls out a hammer.  Once it reaches 0, the
    -- hammer is tossed.
	data.throwTimer = config.holdframes + rng.randomInt(config.waitframeslow, config.waitframeshigh) - (config.initialtimer or 0)

	-- The ID of the NPC the bro is currently holding.
	data.throwingID = nil 

	-- Set up the direction
	data.walkDirection = bro.direction
	if data.walkDirection == 0 then
		-- Random
		local rand = rng.randomInt(1)

		if rand == 0 then
			data.walkDirection = -1
		else
			data.walkDirection = 1
		end
	end
	data.initialDirection = data.walkDirection
	data.facingDirection = data.walkDirection

	-- Use a custom animation frame handler
	data.animationFrame = 0

	-- Whether the bro is being held by a player
	data.held = false

	bro.speedX = data.walkDirection * 0.8 * config.speed
end


function hammerBros.onTickNPC(bro)
	if Defines.levelFreeze or bro.isHidden or bro:mem(0x12A, FIELD_WORD) <= 0 or bro:mem(0x124, FIELD_WORD) == 0 then
		return
	end

	if bro.ai1 ~= 1 then
		-- Set up newly spawned bros
		initialize(bro)
	end

	--[[if bro:mem(0x132, FIELD_WORD) > 0 or bro:mem(0x12E, FIELD_WORD) > 0 then
		-- Decelerate when thrown 
		bro.speedX = bro.speedX * 0.98
		bro.data._basegame.held = true
		return
	end]]

	local data = bro.data._basegame
	local config = configs[bro.id]

	if bro:mem(0x12C, FIELD_WORD) > 0 then
		-- Held
		--[[Text.print(friendlyProjectileMap[config.throwid], 32, 32)
		if friendlyProjectileMap[config.throwid] then
			data.throwTimer = data.throwTimer - 2
			if data.throwTimer <= 0 then
				data.throwTimer = config.holdFrames + rng.randomInt(config.waitframeslow, config.waitframeshigh)
			elseif data.throwTimer < config.holdFrames and data.throwingID == nil then
				data.throwingID = friendlyProjectileMap[config.throwid]
			end
		end]]
		data.held = true
		return 
	end

	if data.held then
		-- Just released
		data.throwTimer = config.holdframes + rng.randomInt(config.waitframeslow, config.waitframeshigh)
		data.throwingID = nil
		bro.speedX = data.walkDirection * 0.8 * config.speed
	end
	data.held = false
	data.facingDirection = getDirectionFacing(bro)
	data.animationFrame = (data.animationFrame + 1 / config.frameSpeed) % config.frames

	if data.throwTimer >= 0 then
		bro.speedX = data.walkDirection * 0.8 * config.speed

		if data.walkTimer == 0 then
			-- Switch directions.

			data.walkDirection = -data.walkDirection
			data.walkTimer = config.walkframes
		elseif bro.collidesBlockBottom then
			-- Only update the direction timer if the bro is not in the air.
			
			data.walkTimer = data.walkTimer - 1
		end

		if not config.quake then
			if data.jumpTimer == 0 then
				-- The bro performs a leap.
				bro.speedY = -config.jumpspeed
				data.jumpTimer = config.jumpframes
			elseif bro.collidesBlockBottom then
				-- Only update the jump timer if the bro is not in the air.
				data.jumpTimer = data.jumpTimer - 1
			end
		else
			if data.jumpTimer == 0 then
				-- The bro performs a leap.
				
				bro.speedY = -config.jumpspeed
				data.jumpTimer = -1
			elseif data.jumpTimer == -1 then
				-- The bro has performed a large leap into the air.  Check to see if the bro has landed.
				
				bro.speedX = 0
				
				if bro.collidesBlockBottom then
					-- Create an earthquake and, if not set to friendly, stun any players on the ground that are not already stunned in
					-- the NPC's section.
					
					Defines.earthquake = config.quakeintensity
					SFX.play(37)
					Effect.spawn(10, bro.x - 8, bro.y + bro.height - 16).speedX = -2
					Effect.spawn(10, bro.x + 8, bro.y + bro.height - 16).speedX = 2
					
					if not bro.friendly then
						for k, p in ipairs(Player.get()) do
							if p:isGroundTouching() and not playerStun.isStunned(k) and bro:mem(0x146, FIELD_WORD) == player.section then
								playerStun.stunPlayer(k, config.stunframes)
							end
						end
					end
					
					data.jumpTimer = config.jumpframes
				end
			elseif bro.collidesBlockBottom then
				-- Only update the jump timer if the bro is not in the air.
				
				data.jumpTimer = data.jumpTimer - 1
			end
		end

		data.throwTimer = data.throwTimer - 1

		if data.throwTimer <= config.holdframes and data.throwingID == nil then
			data.throwingID = config.throwid
		end
	elseif data.throwingID ~= nil then
		-- Fire a hammer and reset the hammer timer.

		SFX.play(25)
		local ham = NPC.spawn(data.throwingID, bro.x - data.facingDirection * config.throwoffsetx, bro.y - config.throwoffsety, bro:mem(0x146, FIELD_WORD), false)
		ham.data._basegame.ownerBro = bro
		ham.direction = data.facingDirection
		ham.layerName = "Spawned NPCs"
		ham.speedX = ham.direction * config.throwspeedx or 0
		ham.speedY = config.throwspeedy or 0
		ham.friendly = bro.friendly
		data.throwTimer = config.holdframes + rng.randomInt(config.waitframeslow, config.waitframeshigh)
		data.throwingID = nil
	end
end

function hammerBros.onDrawNPC(bro)
	if not bro.isValid or bro:mem(0x12A, FIELD_WORD) <= 0 or bro:mem(0x124, FIELD_WORD) == 0 then return end
	local config = configs[bro.id]
	local data = bro.data._basegame
	if data.animationFrame == nil then
		-- Detects that the NPC hasn't been set up yet
		return
	end

	local direction = data.facingDirection
	if data.held then
		direction = bro.direction
	end

	bro.animationFrame = data.animationFrame
	if config.frameStyle ~= 0 and direction == 1 then
		bro.animationFrame = bro.animationFrame + config.frames
	end

	-- If the hammer bro is about to fire a hammer, set its frame to the associated tossing sprite (adding index frames).
	if data.throwingID ~= nil then
		local totalFrames = config.frames
		if config.frameStyle == 1 then
			totalFrames = totalFrames * 2
		elseif config.frameStyle == 2 then
			totalFrames = totalFrames * 4
		end
		bro.animationFrame = bro.animationFrame + totalFrames
		drawHeldNPC(data.throwingID, bro.x - direction * config.holdoffsetx + bro.width / 2, bro.y + config.holdoffsety, direction)
	end
end

return hammerBros