--[[
--    API NAME: v.lua
--    Author: Minus (with modifications by Saturnyoshi for basegame use)
--    Version: 2.0
--]]

local npcManager = require("npcManager")
local rng = require("rng")

local flutter = {}

local npcID = NPC_ID

flutter.config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 68,
	gfxwidth = 76,
	width = 64,
	height = 64,
	frames = 4,
	framestyle = 1,
	jumphurt = 0,
	noyoshi = -1,
	nofireball = -1,
	noiceball = -1,
	noblockcollision = -1,
	nogravity = -1,
	nowaterphysics = -1,

	chargespeed = 4.8,
	maxspeedx = 1.2,
	maxspeedy = 2.4,
	flightperiod = 180,
	stunframes = 120,
	stundecel = 0.1,
	zerospthreshold = 0.01,
})

npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED}, {
	[HARM_TYPE_FROMBELOW] = 251,
	[HARM_TYPE_HELD] = 251,
	[HARM_TYPE_NPC] = 251,
	[HARM_TYPE_PROJECTILE_USED] = 251})

local ST_FLYING = 0
local ST_STUN = 1
local ST_CHARGING = 2

local angryoffset = 2^flutter.config.framestyle * flutter.config.frames
local omega = 2 * math.pi / flutter.config.flightperiod

local function onInitTick(v)
	local data = v.data._basegame
	
	if v.direction == 0 then
		if rng.randomInt(1) == 0 then
			v.direction = -1
		else
			v.direction = 1
		end
	end

	local cfg = NPC.config[v.id]
	
	data.state = ST_FLYING
	v.speedX = v.direction * cfg.maxspeedx * cfg.speed
	v.speedY = 0
	data.timer = 0
end

local function onFlyingTick(v)
	local data = v.data._basegame
	
	local cfg = NPC.config[v.id]
	v.speedY = v.speedY - omega * cfg.maxspeedy * math.cos(omega * data.timer)
	
	data.timer = data.timer + 1
	
	if data.timer == cfg.flightperiod then
		data.timer = 0
	end
end

local function onStunTick(v)
	local data = v.data._basegame
	
	local cfg = NPC.config[v.id]
	if math.abs(v.speedX) < cfg.zerospthreshold then
		v.speedX = 0
	else
		v.speedX = v.speedX * cfg.stundecel
	end
	
	if math.abs(v.speedY) < cfg.zerospthreshold then
		v.speedY = 0
	else
		v.speedY = v.speedY * cfg.stundecel
	end
	
	if data.timer > 0 then
		data.timer = data.timer - 1
		return
	end
	
	data.state = ST_CHARGING
	
	-- The flutter will charge at the nearest player (exception: if the player is almost directly above the flutter, the
	-- flutter will pick the closest angle to the player's direction  of either 45 degrees from the horizontal or 135
	-- degrees from the horizontal - so as to make it extremely difficult for the player to ride the flutter upward
	-- when it charges).
	if v.dontMove then
		v.dontMove = false
	end

	local cx, cy = v.x + v.width * 0.5, v.y + v.height * 0.5
	local target = Player.getNearest(cx, cy)
	local vect = vector.v2((target.x + target.width / 2) - (cx), (target.y + target.height / 2) - (cy))
	local speed = cfg.chargespeed * vect:normalize()
	
	v.speedX = speed.x
	v.speedY = speed.y
end

function flutter.onInitAPI()
	npcManager.registerEvent(npcID, flutter, "onTickNPC")
	npcManager.registerEvent(npcID, flutter, "onDrawNPC")
	npcManager.registerEvent(npcID, flutter, "onDrawEndNPC")
	
	registerEvent(flutter, "onNPCHarm")
end

function flutter.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = nil
		return
	end
	local cfg = NPC.config[v.id]
	
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		if data.state == ST_STUN or data.state == ST_CHARGING then
			data.state = ST_STUN
			data.timer = cfg.stunFrames
		else
			data.state = nil
		end
		
		return
	end
	
	if data.state == nil then
		onInitTick(v)
	elseif data.state == ST_FLYING then
		onFlyingTick(v)
	elseif data.state == ST_STUN then
		onStunTick(v)
	end
end

function flutter.onDrawNPC(v)
	local data = v.data._basegame
	
	if data.state == ST_STUN then
		-- Set animation timer to 0 so as to freeze the animation.
		v.animationTimer = 0
	end
	
	if data.state == ST_STUN or data.state == ST_CHARGING then
		-- Set the sprite to that of the angry flutter by adding the appropriate offset from the base sprite.
		v.animationFrame = v.animationFrame + angryoffset
	end
end

function flutter.onDrawEndNPC(v)
	local data = v.data._basegame
	
	if data.state == ST_STUN or data.state == ST_CHARGING then
		-- Undo the offset so that the sprite continues to update in the normal SMBX way.
		v.animationFrame = v.animationFrame - angryoffset
	end
end

function flutter.onNPCHarm(eventObj, v, killReason, culprit)
	if v.id ~= npcID or (killReason ~= HARM_TYPE_JUMP and not (killReason == HARM_TYPE_SPINJUMP and type(culprit) == "Player" and culprit:mem(0x108, FIELD_WORD) ~= 2) and killReason ~= HARM_TYPE_SWORD) then
		return
	end
	
	eventObj.cancelled = true
	--SFX.play(9)
	local cfg = NPC.config[v.id]
	local data = v.data._basegame
	
	if data.state == nil or data.state == ST_FLYING then
		data.state = ST_STUN
		data.timer = cfg.stunframes
		
		v.speedX = 0
		v.speedY = 0
		
		local flower = Effect.spawn(207, v.x, v.y)
		flower.direction = v.direction
	end
	
	if killReason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP then
		if culprit.x + culprit.width / 2 < v.x + v.width / 2 then
			culprit.speedX = -4 + v.speedX
		else
			culprit.speedX = 4 + v.speedX
		end
	end
end

return flutter