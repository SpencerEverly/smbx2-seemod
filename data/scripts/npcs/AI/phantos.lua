--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local whistle = require("npcs/ai/whistle")
local rng = require("rng")

--local textplus = require("textplus");    --for debugging


local idList  = {}
--local effectMap = {basic=1,aggro=1,furious=1}



--Create the library table
local phanto = {}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sharedSettings = {

	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
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
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false


	--Define custom properties below
	awakenoffscreen = true,

	flashstartframe=0,
	flashendframe=2,

	sleepstartframe=0,
	sleependframe=0,

	chasestartframe=0,
    chaseendframe=0,
    
    stoptype = 0 -- behaviour when a key is let go of: 0=stops, 1=continues, 2=continues even across sections
}

function phanto.register(config)
    table.insert(idList, config.id)
	local config = table.join(config, sharedSettings)
	npcManager.setNpcSettings(config)
	npcManager.registerEvent(config.id, phanto, "onTickNPC")
	npcManager.registerEvent(config.id, phanto, "onDrawNPC")
end


--Custom local definitions below
local STATE = {INACTIVE=1, AWAKEN=2, SHAKE=3, FOLLOW=4, HOSTAGE=5}
local soundfx = {
	awaken = Misc.resolveSoundFile("phanto-awaken"),
	shake = Misc.resolveSoundFile("phanto-shake"),
	move = Misc.resolveSoundFile("phanto-move")
}





local function setAnimBounds(v, typestr)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	data.startframe = config[typestr.."startframe"]
	data.endframe = config[typestr.."endframe"]
end




function phanto.onTickNPC(v)
	--Don't act during time freeze
	if  Defines.levelFreeze then  return  end

	local data = v.data._basegame
	local config = NPC.config[v.id]
	local cam = camera
	local currentSection = v:mem(0x146, FIELD_WORD)
	local canActivateOffscreen = (config.awakenoffscreen  and  player.section == currentSection)


	--If despawned OR not able to spawn offscreen when in the same section
	if  v:mem(0x12A, FIELD_WORD) <= 0  and  not canActivateOffscreen  then
		--Reset our properties, if necessary
		data.initialized = false
		return;
	end

	local settings = v.data._settings

	--Initialize
	if  not data.initialized  then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE.INACTIVE
		data.startframe = nil
		data.endframe = nil
		v.ai1 = 0
		v.ai2 = 0
		data.startSection = currentSection
		data.currentScreenLeft = v.x
		data.targetPlayer = nil
		data.exitSide = -1
		settings.targetId = settings.targetId  or  31
		if  settings.crossSection == nil  then
			settings.crossSection = false
		end
		if  data.startedFriendly == nil  then
			data.startedFriendly = v.friendly
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.state = STATE.HOSTAGE
	end


	-------- Execute main AI -----------
	local center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)


	-- STATE-AGNOSTIC BEHAVIOR
	local sectionObj = Section(currentSection)  or  Section(player.section)

	-- Animation handling
	data.startframe = nil
	data.endframe = nil

	-- General-purpose AI timer countdown
	v.ai1 = math.max(0, v.ai1-1)

	-- prevent from despawning when offscreen
	if  data.state ~= STATE.INACTIVE  or  canActivateOffscreen  then
		v:mem(0x124, FIELD_BOOL, true)
		v:mem(0x12A, FIELD_WORD, 180)
		v:mem(0x126, FIELD_BOOL, false)
		v:mem(0x128, FIELD_BOOL, false)
	end

	-- Handle the move sound effect, determining the target player and following them across sections
	if  data.state == STATE.AWAKEN  or  data.state == STATE.SHAKE  or  data.state == STATE.FOLLOW  then

		-- Reset target player
		local sectionToCheck = currentSection
		if  settings.crossSection  then
			sectionToCheck = -1
		end

		local heldDetected = false
		if not whistle.getActive() then
			if  config.stoptype == 0 then
				data.targetPlayer = nil
			end
			for  k,n in ipairs(NPC.get(settings.targetId, sectionToCheck))  do
				local pID = n:mem(0x12C,FIELD_WORD)
				if  pID > 0  then
					data.targetPlayer = Player(pID)
					heldDetected = true
					break;
				end
			end
		else
			heldDetected = true
			data.targetPlayer = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		end

		-- If a player took a target item to another section, or I'm just stubborn, follow them
		local stubbornTarget = data.targetPlayer  or  player
		if  data.targetPlayer ~= nil  or  config.stoptype == 2  then
			if  stubbornTarget.section ~= currentSection  and  settings.crossSection  and  (heldDetected  or  config.stoptype == 2)  then
				v:mem(0x146, FIELD_WORD, stubbornTarget.section)
				currentSection = v:mem(0x146, FIELD_WORD)
				data.currentScreenLeft = cam.x - 0.5*v.width
				v.speedY = rng.random(-3,0)
				v.y = cam.y-0.5*v.height
				data.startTick = lunatime.tick()-rng.randomInt(200)
				data.state = STATE.FOLLOW
			end

		elseif  stubbornTarget.section ~= currentSection  then
			data.initialized = false
			return;
		end

		-- Moving sound effect
		v.ai2 = (v.ai2 + 1)%128
		if  v.ai2 == 0  and  data.targetPlayer ~= nil  then
			SFX.play(soundfx.move)
		end
	end

	-- Friendly if not tracking the player
	v.friendly = (data.targetPlayer == nil)  or  data.startedFriendly



	-- INACTIVE
	if  data.state == STATE.INACTIVE  then
		setAnimBounds(v, "sleep")
		if whistle.getActive() then
			data.state = STATE.AWAKEN
			SFX.play(soundfx.move)
		end

		for  k,v in ipairs(NPC.get(settings.targetId, data.startSection))  do
			if  v:mem(0x12C,FIELD_WORD) > 0  then
				data.state = STATE.AWAKEN
				SFX.play(soundfx.move)
				break;
			end
		end
		v.ai1 = 32


	-- AWAKENING
	elseif  data.state == STATE.AWAKEN  then
		setAnimBounds(v, "flash")

		if  v.ai1 <= 0  then
			SFX.play(soundfx.shake)
			data.state = STATE.SHAKE
			v.ai1 = 65
		end


	-- SHAKING
	elseif  data.state == STATE.SHAKE  then
		setAnimBounds(v, "chase")

		if  v.ai1 <= 0  then
			data.state = STATE.FOLLOW
			data.startTick = lunatime.tick()
		end


	-- FOLLOWING
	elseif  data.state == STATE.FOLLOW  then
		setAnimBounds(v, "chase")

		-- Manage chasing and hovering behavior
		local boundary = sectionObj.boundary
		local sectionW = boundary.right - boundary.left

		local targetCenter
		if  data.targetPlayer ~= nil  then
			local targetP = data.targetPlayer
			targetCenter = vector.v2(targetP.x+0.5*targetP.width, targetP.y+targetP.height-32)
			data.exitSide = -math.sign(targetCenter.y-center.y)
			if  data.exitSide == 0  then
				data.exitSide = 1
			end

		else
			targetCenter = vector.v2(cam.x+cam.width*0.5, cam.y + 0.5*cam.width + cam.width*data.exitSide)
		end

		local toTarget = vector.v2(targetCenter.x-center.x, targetCenter.y-center.y)
		v.speedY = v.speedY + 0.15*math.sign(toTarget.y)
		v.speedY = math.clamp(v.speedY, -5,5)


		-- Horizontal movement
		local horzCycleDegrees = (lunatime.time()-lunatime.toSeconds(data.startTick))*50

		if  sectionW > cam.width  or  not sectionObj.isLevelWarp  then
			-- Shift to lax camera-based following depending on the section width and settings
			data.currentScreenLeft = math.lerp(data.currentScreenLeft, cam.x - 0.5*v.width, math.lerp(0,0.125, math.min(180,horzCycleDegrees)/180))
		end

		v.x = data.currentScreenLeft + cam.width*(0.5 + 0.5*math.cos(math.rad((horzCycleDegrees) % 360 + 180)))
		center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)


		-- Wrap around sections
		if  sectionObj.isLevelWarp  then

			if  center.x > boundary.right + 0.5*v.width  then
				v.x = v.x - sectionW - v.width

			elseif  center.x < boundary.left - 0.5*v.width  then
				v.x = v.x + sectionW + v.width
			end
		end


	-- HOSTAGE
	elseif  data.state == STATE.HOSTAGE  then
		local pID = v:mem(0x12C,FIELD_WORD)
		if  pID > 0  then
			data.targetPlayer = Player(pID)
		end
		setAnimBounds(v, "chase")

		if  v:mem(0x12C, FIELD_WORD) <= 0  then
			v:mem(0x136, FIELD_BOOL, false)
			data.currentScreenLeft = v.x
			data.state = STATE.FOLLOW
			data.startTick = lunatime.tick()
		end
	end



	-- DEBUG
	--[[
	--data.pos = vector.v2(math.floor(center.x), math.floor(center.y))
	--data.speed = vector.v2(math.floor(v.speedX), math.floor(v.speedY))
	local str = ""
	for  key,val in pairs(data)  do
		str = str .. key .. ": " .. tostring(val) .. "<br>"
	end
	textplus.print {text=str, x=20, y=20, priority = 0.985, color=Color.white, font=FONT_BASIC, align="topleft", pivot={0,0}, xscale=1, yscale=1}
	--data.pos = nil
	--data.speed = nil
	--]]

end

function phanto.onDrawNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	local shakeExtra = 0
	if  data.state == STATE.SHAKE and Defines.levelFreeze == false then
		shakeExtra = math.floor((lunatime.tick()%8)/4)
	end

	local animlength = 1
	if  data.startframe ~= nil  and  data.endframe ~= nil  then
		animlength = data.endframe - data.startframe + 1
	end

	npcutils.drawNPC(v, {
		frame=npcutils.getFrameByFramestyle(v, {
			offset = (data.startframe or 0),
			frames = animlength - (data.startframe or 0)}), 
		xOffset=config.gfxoffsetx + shakeExtra})
	npcutils.hideNPC(v)
end




--Gotta return the library table!
return phanto