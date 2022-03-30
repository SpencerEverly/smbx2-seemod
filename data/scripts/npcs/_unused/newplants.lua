-- newPlants.lua
-- Written by Saturnyoshi

local npcManager = require("npcManager")
local colliders = require("colliders")
local rng = require("rng")

local newPlants = {}


local defaults = {
	gfxheight = 48,
	gfxwidth = 32,
	width = 32,
	height = 46,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	jumphurt = 1,
	nogravity = 1,
	noblockcollision = 1,
	spinjumpsafe = true,

	-- newPlants stuff
	horizontal = false,			-- When true plant moves left / right instead of up / down.
	ignoreplayers = false,		-- Comes up even if a player is in it's path, like the red SMB2J plants.
	jumping = false,			-- SMW style.

	waittime = 42,				-- Number of ticks to wait before coming out of pipe.
	waittimeblocked = 1,		-- Number of ticks to wait if trying to come out of pipe but blocked.
	extendtime = 52,			-- Number of ticks to stay revealed for.

	hideframes = 32,			-- Speed to retreat back into pipe at.
	extendframes = 32,			-- Speed to come out of pipe at.

	dofire = false,				-- Whether or not this plant shoots.
	firedelay = 61,				-- Number of ticks to wait before firing after revealed.
	firespeed = 3,				-- Speed at which the fireballs move.
	firespeedrand = 2,			-- Random range of projectile speed.
	fireamount = 1,				-- How many fireballs the NPC will shoot.
	firebursts = 1,				-- How many bursts to shoot.
	fireburstdelay = 10,		-- Delay in ticks between bursts.
	fireburstdirection = 0,		-- Angle to add to shot direction each burst.
	fireburstalternate = false, -- Flips direction every other burst if true
	firetype = -1,				-- NPC ID to shoot, or negative for type of physics affected fireball to shoot.
	firespread = 0,				-- Distance in degrees between fireballs.
	fireaimed = true,			-- Whether the fire is shot towards the player.
	firemirror = false,			-- Mirrors fired shots in opposite direction
	firedirection = 0,			-- Offset from the direction to fire in.
	firedirectionrand = 0		-- Range to randomly add or subtract from the firing direction.
}

function newPlants.onInitAPI() end

local plantSettings = {}
function newPlants.registerPlant(settings)
	npcManager.registerEvent(settings.id, newPlants, "onTickNPC")
	npcManager.registerEvent(settings.id, newPlants, "onDrawNPC")
	plantSettings[settings.id] = npcManager.setNpcSettings(table.join(settings, defaults))
	npcManager.registerHarmTypes(settings.id,
	{HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD},
	{[HARM_TYPE_NPC] = 10, [HARM_TYPE_HELD] = 10, [HARM_TYPE_TAIL] = 10})
end
------------------------ VANILLA PLANTS ------------------------------

------ SMB3 ----------------
-- Short, green
newPlants.registerPlant({id = 512, staticdirection = true})
-- Long, red
newPlants.registerPlant({id = 513, height = 64, gfxheight = 64, staticdirection = true})
-- Sideways
newPlants.registerPlant({id = 514, horizontal = true, width = 48, gfxwidth = 48, height = 32, gfxheight = 32})
-- Big boy
newPlants.registerPlant({id = 515, width = 48, gfxwidth = 48, height = 64, gfxheight = 64, staticdirection = true})
-- Venus fire trap
newPlants.registerPlant({id = 516, dofire = true, firetype = 246, width = 32, height = 64, gfxwidth = 32, gfxheight = 64, frames = 4, staticdirection = true})
-- Sidways venus fire trap
newPlants.registerPlant({id = 517, horizontal = true, dofire = true, firetype = 246, width = 64, height = 32, gfxwidth = 64, gfxheight = 32, frames = 4})

------ SMW -----------------
--[[
-- Jumping piranha plant
newPlants.registerPlant({id = ???, width = 32, height = 42, gfxwidth = 32, gfxheight = 42, jumping = true})
-- Sideways jumping piranha plant
newPlants.registerPlant({id = ???, width = 42, height = 32, gfxwidth = 42, gfxheight = 32, jumping = true, horizontal = true})
-- Jumping fire piranha plant
newPlants.registerPlant({id = 520, width = 32, height = 42, gfxwidth = 32, gfxheight = 42, jumping = true, dofire = true, fireaimed = false, fireamount = 2, firespeed = 6, firespread = 60, firetype = -3, staticdirection = true})
]]
-- Normal
newPlants.registerPlant({id = 521, height = 64, gfxheight = 64, staticdirection = true})

------ SMB1 ----------------
-- Normal
newPlants.registerPlant({id = 522, staticdirection = true})
-- SMB2J red plant
newPlants.registerPlant({id = 523, ignoreplayers = true, staticdirection = true})
-- Pink fire spewing plant
newPlants.registerPlant({id = 524, dofire = true, fireaimed = false, firedirectionrand = 20, fireamount = 3, firespeed = 8, firespeedrand = 2, firetype = -1, staticdirection = true})

-----------------------------------------------------------------------

local fireID = 511
do
	local fireEvents = {}
	local fireSettings = npcManager.setNpcSettings(
			{id = fireID, 
			gfxheight=16, 
			gfxwidth=16, 
			width = 16, 
			height = 16, 
			frames = 4, 
			framestyle = 0, 
			framespeed = 4, 
			jumphurt = 1, 
			noblockcollision = 1, 
			nofireball = 1, 
			npcblock = 0,
			lightradius=32,
			lightbrightness=1,
			lightcolor=Color.orange
			})
	npcManager.registerEvent(fireID, fireEvents, "onTickNPC")
	registerEvent(fireID, fireEvents, "onDrawNPC")
	function fireEvents.onTickNPC(v)
		v.animationFrame = v.animationFrame - v.ai1 * fireSettings.frames
		v:mem(0x156, FIELD_WORD, 100)
	end
	function fireEvents.onDrawNPC(v)
		v.animationFrame = v.animationFrame + v.ai1 * fireSettings.frames
	end
end

local fieldSize = {[false] = "height", [true] = "width"}
local fieldPos = {[false] = "y", [true] = "x"}

local function getHeadPos(v)
	local horizontal = plantSettings[v.id].horizontal
	if horizontal then
		if v.direction == -1 then
			return v.x + 16, v.y + v.height / 2
		else
			return v.x + v.width - 16, v.y + v.height / 2
		end
	else
		if v.direction == -1 then
			return v.x + v.width / 2, v.y + 16
		else
			return v.x + v.width / 2, v.y + v.height - 16
		end
	end
end

local function pointDirection(x1, y1, x2, y2)
	return math.deg(math.atan2(x2 - x1, y2 - y1))
end

local function playerNearest(x, y)
	local maxD = 9999999
	local myP = player
	for _, v in ipairs(Player.get()) do
		local xo = math.abs(x - v.x)
		local yo = math.abs(y - v.y)
		local d = math.sqrt((xo * xo) + (yo * yo))
		if d < maxD then
			myP = v
			maxD = d
		end
	end
	return myP
end

local function playerInRegion(x1, y1, x2, y2)
	for _, v in ipairs(Player.getIntersecting(x1, y1, x2, y2)) do
		return true
	end
	return false
end

local function configTrue(val)
	if val == 0 then
		return false
	else
		if val then
			return true
		else
			return false
		end
	end
end

local function createFireball(x, y, section, firetype, direction, speed, friendly)
	if firetype ~= 0 then
		local newfire
		direction = math.rad(direction)
		if firetype > 0 then
			newfire = NPC.spawn(firetype, x, y, section, false, true)
		else
			newfire = NPC.spawn(fireID, x, y, section, false, true)
			newfire.ai1 = math.abs(firetype) - 1
		end
		newfire.speedX = math.sin(direction) * speed
		newfire.speedY = math.cos(direction) * speed
		newfire.friendly = friendly
		return newfire
	end
end
-- sog told me to put this in
local function fireBurst(v, burstnumber)
	local settings = plantSettings[v.id]
	local hx, hy = getHeadPos(v)

	local baseAngle
	local mulAngle = 1
	if configTrue(settings.fireaimed) then
		local p = playerNearest(v.x + v.width / 2, v.y + v.width / 2)
		baseAngle = pointDirection(hx, hy, p.x + p.width / 2, p.y + p.height - 16)
	else
		if settings.horizontal then
			if v.direction == -1 then
				baseAngle = 270
			else
				baseAngle = 90
			end
		else
			if v.direction == -1 then
				baseAngle = 180
			else
				baseAngle = 0
			end
		end
	end

	if configTrue(settings.fireburstalternate) then
		if math.floor(burstnumber / 2) == burstnumber / 2 then
			mulAngle = mulAngle * -1
		end
	end

	local offsAngle = -settings.firespread * (settings.fireamount - 1) / 2 + settings.fireburstdirection * burstnumber

	for i = 1, settings.fireamount do
		local modAngle = settings.firedirection
		local modSpeed = settings.firespeed
		if settings.firedirectionrand ~= 0 then
			modAngle = modAngle + rng.random(-settings.firedirectionrand / 2, settings.firedirectionrand / 2)
		end
		if settings.firespeedrand ~= 0 then
			modSpeed = modSpeed + rng.random(-settings.firespeedrand / 2, settings.firespeedrand / 2)
		end
		local finalAngle = (modAngle + offsAngle) * mulAngle
		createFireball(hx, hy, 0, settings.firetype, baseAngle + finalAngle, modSpeed, v.friendly)
		if settings.firemirror then
			createFireball(hx, hy, 0, settings.firetype, baseAngle - finalAngle, modSpeed, v.friendly)
		end
		offsAngle = offsAngle + settings.firespread
	end
end

local function initPlant(v)
	local data = v.data._basegame
	local settings = plantSettings[v.id]
	local moveaxis = fieldPos[settings.horizontal]
	v.ai1 = 1
	-- Only need to set these once, copied for convenience
	if data.base == nil then
		data.horizontal = configTrue(settings.horizontal)
		data.smw = configTrue(settings.jumping)
		data.size = settings[fieldSize[data.horizontal]]
	end
	-- Set on respawn
	data.base = v[moveaxis]
	data.hiding = true
	data.moving = false
	data.firing = 0
	data.bursttimer = 0
	data.timer = 7
	-- Force plant into pipe
	v[moveaxis] = v[moveaxis] + v[fieldSize[data.horizontal]]
end

function newPlants.onTickNPC(v)
	if v:mem(0x12A, FIELD_WORD) > 0 and not v.layerObj.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
		v.animationFrame = v.animationFrame - 9999
		local data = v.data._basegame
		if not Defines.levelFreeze then
			local data = v.data._basegame
			local settings = plantSettings[v.id]
			local fsize = fieldSize[data.horizontal]
			local fpos = fieldPos[data.horizontal]

			if v.ai1 == 0 then -- AI values reset on respawn
				initPlant(v)
			end

			-- Move with layer
			do
				local l = v.layerObj
				v.x = v.x + l.speedX
				v.y = v.y + l.speedX
				if v.horizontal then
					data.base = data.base + l.speedX
				else
					data.base = data.base + l.speedY
				end
			end

			    ------------------------------------------
			  ---------- IDLE --------------------------
			------------------------------------------
			if data.firing == 0 and not data.moving then
				data.timer = data.timer - 1
				if data.timer <= 0 then
					local blocked = false

					-- Check if player in front of pipe
					if not settings.ignoreplayers and data.hiding then
						local x1, y1, x2, y2
						if settings.horizontal then
							local b = v.y + settings.height / 2
							y1 = b - 31
							y2 = b + 31
							x1 = data.base - settings.width
							x2 = data.base + settings.width
						else
							local b = v.x + settings.width / 2
							x1 = b - 48
							x2 = b + 48
							y1 = data.base - 400
							y2 = data.base + 400
						end

						blocked = playerInRegion(x1, y1, x2, y2)
					end

					if not blocked then
						-- No player or ignoring, move
						data.moving = true
						data.hiding = not data.hiding
						if data.hiding then
							data.timer = settings.waittime
						else
							data.timer = settings.extendtime
						end
					else
						-- Player found, wait
						data.timer = settings.waittimeblocked
					end
				end
			end

			    ------------------------------------------
			  ---------- MOVE --------------------------
			------------------------------------------
			if data.moving then
				if data.hiding then
					moveamount = data.size / settings.hideframes
				else
					moveamount = -data.size / settings.extendframes
				end
				moveamount = moveamount * -v.direction

				v[fpos] = v[fpos] + moveamount

				-- Target position
				local targetPos
				if data.hiding then
					targetPos = data.base - data.size * v.direction
				else
					targetPos = data.base
				end

				if (moveamount > 0 and v[fpos] > targetPos) or (moveamount < 0 and v[fpos] < targetPos) then
					v[fpos] = targetPos
					data.moving = false
					-- Start firing
					if data.hiding == false and configTrue(settings.dofire) then
						data.firing = 1
						data.bursttimer = settings.firedelay
					end
				end
			end

			    ------------------------------------------
			  ---------- FIRE --------------------------
			------------------------------------------
			if data.firing ~= 0 and configTrue(settings.dofire) and not data.moving then
				data.bursttimer = data.bursttimer - 1
				if data.bursttimer <= 0 then
					fireBurst(v, data.firing - 1)
					data.bursttimer = settings.fireburstdelay
					data.firing = data.firing + 1
					if data.firing > settings.firebursts then
						data.firing = 0
					end
				end
			end
		end
	end
end

function newPlants.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) > 0 and not v.layerObj.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
		local settings = plantSettings[v.id]
		local data = v.data._basegame
		if not data.hiding or data.moving then
			local modifyLeft, modifyRight, modifyTop, modifyBottom, offsX, offsY = 0, 0, 0, 0, 0, 0
			local move = (data.base - v[fieldPos[data.horizontal]])
			-- Only draw if not fully covered
			if math.abs(move) < settings[fieldSize[data.horizontal]] then
				-- Also don't clip sprite if fully showing
				if move ~= 0 then
					if data.horizontal then
						if v.direction == -1 then
							modifyRight = move
						else
							modifyRight = move * -1
							offsX = move
							modifyLeft = move
						end
					else
						if v.direction == -1 then
							modifyBottom = move
						else
							modifyBottom = move * -1
							offsY = move
							modifyTop = move
						end
					end
				end
				-- Draw it
				Graphics.drawImageToSceneWP(Graphics.sprites.npc[v.id].img, v.x + offsX, v.y + offsY, modifyLeft, v.animationFrame * settings.gfxheight + modifyTop, settings.gfxwidth + modifyRight, settings.gfxheight + modifyBottom, 1, -75)
			end
		end

		-- Hide original sprite
		if v.animationFrame < 9999 then
			v.animationFrame = v.animationFrame + 9999
		end
	end
end

return newPlants
