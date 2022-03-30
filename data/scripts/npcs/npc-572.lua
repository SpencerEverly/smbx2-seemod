--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local darkness = require("darkness")
local rng = require("rng")

--Create the library table
local frightlight = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = 572

--Defines NPC config for our NPC. You can remove superfluous definitions.
local frightlightSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 192,
	gfxwidth = 192,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 128,
	height = 128,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	luahandlesspeed = true,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	lightradius = 400,
	lightbrightness = 1,
	lightoffsetx = 64,
	lightoffsety = -64,
	lightcolor = Color.white,

	--Define custom properties below
	hideframes = 32,
	hiderespawnframes = 160,
	invisibleframes = 128
}

--Applies NPC settings
npcManager.setNpcSettings(frightlightSettings)

--Registers the category of the NPC. Options include HITTABLE, UNHITTABLE, POWERUP, COLLECTIBLE, SHELL. For more options, check expandedDefines.lua

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE = {INVISIBLE=1, APPEAR=2, FOLLOW=3, HIDE=4, DISAPPEAR=5, SCARE=6, HOSTAGE=7}
local soundfx = {
	appear = Misc.resolveSoundFile("frightlight-appear"),
	spook = Misc.resolveSoundFile("frightlight-startle"),
	ambient = {
		Misc.resolveSoundFile("frightlight-wibrel"),
		Misc.resolveSoundFile("frightlight-wooble"),
		Misc.resolveSoundFile("frightlight-worble"),
		Misc.resolveSoundFile("frightlight-wurble")
	}
}

local wooblyInterval = 192
local appearDuration = 32
local disappearDuration = 32
local scareDuration = 48


local function stopWoobly(v)
	local data = v.data._basegame
	if  data.woobly ~= nil  then
		data.woobly:Stop()
		data.woobly = nil
	end
end

local function playWoobly(v, force)
	local data = v.data._basegame
	if  v.ai2 <= 0  or  force  then
		local chunks = Audio.SfxOpen(rng.randomEntry(soundfx.ambient))
		stopWoobly(v)
		data.woobly = Audio.SfxPlayObj(chunks, 0)
		v.ai2 = wooblyInterval
	end
end

local function disappear(v)
	v.ai1 = disappearDuration
	local data = v.data._basegame
	local light = {radius=0, brightness=0, parentoffset={x=0,y=0}}
	if  data._darkness ~= nil  then
		light = data._darkness[2]
	end

	data.state = STATE.DISAPPEAR
	data.disappearradius = light.radius
	data.disappearalpha = data.alpha
	data.disappearbrightness = light.brightness
	data.disappearoffset = {x=light.parentoffset.x, y=light.parentoffset.y}
end



--Register events
function frightlight.onInitAPI()
	npcManager.registerEvent(npcID, frightlight, "onTickNPC")
	npcManager.registerEvent(npcID, frightlight, "onTickEndNPC")
	npcManager.registerEvent(npcID, frightlight, "onDrawNPC")
	--registerEvent(frightlight, "onNPCKill")
	--registerEvent(frightlight, "onTick")
end

function frightlight.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	local config = NPC.config[v.id]


	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		v.ai1 = 0;
		
		if v:mem(0x12A, FIELD_WORD) < 0 then
			v:mem(0x12A, FIELD_WORD, 180)
			v:mem(0x124, FIELD_BOOL, true)
		end
		return
	end

	--Initialize
	if  not data.initialized  then
		--Initialize necessary data.
		if  data.startedFriendly == nil  then
			data.startedFriendly = v.friendly
		end
		data.target = -1
		data.state = STATE.INVISIBLE
		data.alpha = 0
		data.frame = -1
		data.fixedDirection = nil
		v.ai1 = config.invisibleframes
		v.ai2 = 0
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.state = STATE.HOSTAGE
	end


	--Execute main AI
	local center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)
	local targetCenter = vector.v2(center.x+9999,center.y+9999)

	if  data.target ~= -1  then
		targetCenter = vector.v2(data.target.x+0.5*data.target.width, data.target.y+data.target.height-32)
	end

	local toTarget = vector.v2(targetCenter.x-center.x, targetCenter.y-center.y)
	local dirToTarget = toTarget:normalize()
	local distance = toTarget.length
	local targetLooking = data.target ~= -1  and  ((dirToTarget.x > 0  and  data.target.direction == DIR_LEFT)  or  (dirToTarget.x <= 0  and  data.target.direction == DIR_RIGHT))
	local light = {radius=0, brightness=0, parentoffset={x=0,y=0}}
	if  data._darkness ~= nil  then
		light = data._darkness[2]
	end


	-- STATE-AGNOSTIC BEHAVIOR
	v.ai1 = math.max(0, v.ai1-1)
	v.ai2 = math.max(0, v.ai2-1)
	light.parentoffset.x = config.lightoffsetx
	light.parentoffset.y = config.lightoffsety

	if  data.state ~= STATE.DISAPPEAR  and  data.state ~= STATE.INVISIBLE  then
		data.frame = nil
	end

	if  data.state ~= STATE.SCARE  then
		v.direction = DIR_RIGHT
		if  dirToTarget.x <= 0  then
			v.direction = DIR_LEFT
		end
	end


	-- INVISIBLE
	if  data.state == STATE.INVISIBLE  then
		light.radius = 0
		data.frame = -1
		data.alpha = 0
		v.friendly = true

		if  v.ai1 <= 0  then

			-- Determine target
			local cam = camera
			v.x = cam.x + 0.5*cam.width - 0.5*v.width
			v.y = cam.y + 0.5*cam.height - 0.5*v.height
			data.target = npcutils.getNearestPlayer(v)

			-- Appear
			v.x = data.target.x - 350*data.target.direction - 0.5*v.width
			v.y = data.target.y - v.height
			data.state = STATE.APPEAR
			SFX.play(soundfx.appear)
			playWoobly(v, true)
			v.ai1 = appearDuration
		end


	-- APPEARING
	elseif  data.state == STATE.APPEAR  then
		local percent = math.clamp((appearDuration-v.ai1)/appearDuration, 0,1)
		data.alpha = percent

		light.parentoffset.x = percent*config.lightoffsetx
		light.parentoffset.y = percent*config.lightoffsety
		light.radius = percent*config.lightradius
		light.brightness = config.lightbrightness

		if  v.ai1 <= 0  then
			data.state = STATE.FOLLOW
		end


	-- FOLLOWING
	elseif  data.state == STATE.FOLLOW  then
		v.friendly = data.startedFriendly
		v.ai1 = 0
		v.ai3 = 0
		data.alpha = 1
		light.brightness = math.min(config.lightbrightness, light.brightness + config.lightbrightness/16)
		--light.radius = math.min(config.lightradius, light.radius+16)

		if  distance <= 64  then
			disappear(v)
		else
			-- Hide if the player looks at it
			if  targetLooking  then

				-- Scare
				if  distance < 160  then
					SFX.play(soundfx.spook)
					stopWoobly(v)
					data.state = STATE.SCARE
					data.fixedDirection = v.direction
					v.ai1 = scareDuration
					v.speedY = 0
					
					v.speedX = data.fixedDirection*-14

				-- Hide
				else
					data.state = STATE.HIDE
					v.ai1 = config.hideframes
				end

			-- otherwise follow
			else
				local absCfgSpeed = math.abs(config.speed)
				v.speedX = math.clamp(v.speedX + dirToTarget.x * absCfgSpeed * 0.5, -8*absCfgSpeed, 8*absCfgSpeed)
				v.speedY = math.clamp(v.speedY + dirToTarget.y * absCfgSpeed * 0.05, -8*absCfgSpeed, 8*absCfgSpeed)
			end
		end


	-- HIDING
	elseif  data.state == STATE.HIDE  then
		v.speedX = 0
		v.speedY = 0
		data.alpha = 0.5
		light.brightness = math.max(0, light.brightness - config.lightbrightness/(64))
		--light.radius = math.max(0, light.radius-64)
		data.frame = 4
		data.fixedDirection = nil

		if  v.ai3 > config.hiderespawnframes  then
			disappear(v)
		elseif  v.ai1 <= 0  then
			playWoobly(v)
			data.state = STATE.FOLLOW
		elseif  targetLooking  then
			v.ai1 = config.hideframes
			v.ai3 = v.ai3+1
		end


	-- DISAPPEARING
	elseif  data.state == STATE.DISAPPEAR  then
		v.friendly = true

		local percent = v.ai1/disappearDuration
		light.brightness = data.disappearbrightness
		light.radius = math.min(data.disappearradius, data.disappearradius * (4 * percent - 3))

		if  (data.fixedDirection ~= nil)  then
			v.direction = data.fixedDirection
			data.fixedDirection = nil
		end

		local offsetMult = math.lerp(-2,1,percent)
		light.parentoffset.x = data.disappearoffset.x*-v.direction-- * offsetMult
		light.parentoffset.y = data.disappearoffset.y-- * offsetMult

		data.alpha = percent * data.disappearalpha
		if  v.ai1 <= 0  then
			light.radius = 0
			data.initialized = false
		end


	-- SCARE
	elseif  data.state == STATE.SCARE  then
		data.frame = 4
		light.parentoffset.x = math.lerp(light.parentoffset.x, -config.lightoffsetx, 0.2)
		light.brightness = math.lerp(light.brightness, config.lightbrightness*1.5, 0.1)
		light.radius = math.lerp(light.radius, config.lightradius*1.5, 0.1)
		--v.speedX = data.fixedDirection*-14
		v.speedX = v.speedX*0.9

		if  v.ai1 <= 0  then
			disappear(v)
		end


	-- HOSTAGE
	elseif  data.state == STATE.HOSTAGE  then
		data.frame = 4
		data.alpha = 1

		if  v:mem(0x12C, FIELD_WORD) <= 0  and  not v:mem(0x136, FIELD_BOOL)  then
			disappear(v)
		end
	end
end

function frightlight.onTickEndNPC(v)
	local data = v.data._basegame

	if  not data.initialized  then
		return;
	end

	if  data.state == STATE.HIDE  then
		v.speedX = 0
		v.speedY = 0
	end


	if  data.frame == -1  then
		npcutils.hideNPC(v)

	elseif  data.frame ~= nil  then
		v.animationFrame = npcutils.getFrameByFramestyle(v, {frame=data.frame, direction=data.fixedDirection})

	elseif  v.animationFrame == npcutils.getFrameByFramestyle(v, {frame=4, direction=data.fixedDirection})  then
		v.animationFrame = npcutils.getFrameByFramestyle(v, {frame=0, direction=data.fixedDirection})
	end
end

function frightlight.onDrawNPC(v)
	local data = v.data._basegame
	
	if data.initialized then
		npcutils.drawNPC(v, {opacity = (data.alpha  or  0)*0.85})
	end
	npcutils.hideNPC(v)
end


--Gotta return the library table!
return frightlight