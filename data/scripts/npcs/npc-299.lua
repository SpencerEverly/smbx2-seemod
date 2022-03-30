local npcManager = require("npcManager")
local rng = require("rng")

local magikoopa = {}

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local Kamek = {}

local npcID = NPC_ID;

Kamek.config = npcManager.setNpcSettings{
	id = npcID, 
	gfxoffsety = 2,
	gfxwidth = 68, 
	gfxheight = 64, 
	width = 32, 
	height = 62, 
	frames = 4,
	framespeed = 8, 
	framestyle = 1,
	noyoshi=true,
	--lua only
	sparkleoffsetx = -0,
	sparkleoffsety = -21, -- -22 - 1 (offset) 
	magicoffsetx = 28,
	magicoffsety = 7, -- +6 - 1 (offset)
	premagictime = 48,
	postmagictime = 64,

	appeartime = 32,
	disappeartime = 16,
	hiddentime = 128,
	respawntime = 256, --negative = dies forever

	magic = 300,

	minframeright = 0,
	maxframeright = 0,
	minframeleft = 0,
	maxframeleft = 0
}
Kamek.config.minFrameRight = Kamek.config.frames
Kamek.config.maxFrameRight = (Kamek.config.frames * 2) - 1
Kamek.config.minFrameLeft = 0
Kamek.config.maxFrameLeft = Kamek.config.frames - 1

npcManager.registerHarmTypes(
	npcID, 	
	{
		HARM_TYPE_JUMP, 
		HARM_TYPE_FROMBELOW, 
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC, 
		HARM_TYPE_HELD, 
		HARM_TYPE_TAIL, 
		HARM_TYPE_SPINJUMP, 
		HARM_TYPE_SWORD, 
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_JUMP]={id=167, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]=167,
		[HARM_TYPE_PROJECTILE_USED]=167,
		[HARM_TYPE_NPC]=167,
		[HARM_TYPE_HELD]=167,
		[HARM_TYPE_TAIL]=167,
		[HARM_TYPE_SPINJUMP]=76,
		[HARM_TYPE_SWORD]=63,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

-----------------------------------------------------------------------------------------------------



--***************************************************************************************************
--                                                                                                  *
--              PRIVATE MEMBERS                                                                     *
--                                                                                                  *
--***************************************************************************************************

local MAX_VISIBLE_TIMER = Kamek.config.premagictime + Kamek.config.postmagictime
local MAX_HIDDEN_TIMER = Kamek.config.hiddentime + Kamek.config.appeartime + Kamek.config.disappeartime

local NPC_X_OFFSET = 0.015 --SMBX reduces the width of NPCs by 0.03, and moves them to the right by 0.015. THANKS REDIGIT! (maybe only for 32px NPCS!?)

local magikoopaDirection = {
	[-1] = Kamek.config.minFrameLeft,
	[0] = Kamek.config.minFrameLeft,
	[1] = Kamek.config.minFrameRight
}

--***************************************************************************************************
--                                                                                                  *
--              PUBLIC MEMBERS                                                                      *
--                                                                                                  *
--***************************************************************************************************
magikoopa.teleportingKameks = magikoopa.teleportingKameks or {}

--***************************************************************************************************
--                                                                                                  *
--              LOCAL FUNCTIONS                                                                     *
--                                                                                                  *
--***************************************************************************************************

local function isOnscreen(kamek)
	for _,cam in ipairs(Camera.get()) do 
		if kamek.x+kamek.width < cam.x then
			return false
		elseif kamek.x > cam.x+cam.width then
			return false
		elseif kamek.y+kamek.height < cam.y then
			return false
		elseif kamek.y > cam.y+cam.height then
			return false
		end 
	end 
	return true
end

local function canSpawnHere(block, kamek)
	local kamekX = block.x + 0.5 * (block.width - kamek.width)

	--cannot spawn on top of this block
	if not ( --allowed blocks
		Block.SOLID_MAP[block.id] 
		or Block.SEMISOLID_MAP[block.id]
		or Block.PLAYER_MAP[block.id]
	)
	or block.isHidden
	or Block.LAVA_MAP[block.id] 
	then
		return false
	end 

	--if we're filtering layers, check for that too
	if kamek.data._settings.layerfilter and block.layerName ~= kamek.layerName then
		return false
	end

	--too close to the player
	if #Player.getIntersecting(kamekX - (kamek.width * 2), block.y - kamek.height, kamekX + (kamek.width * 3), block.y) > 0 then
		return false
	end 
	--inside of a solid block
	local interruptingBlocks = Block.getIntersecting( 
		kamekX,                 block.y - kamek.height, 
		kamekX + kamek.width/2, block.y 
	)
	for _,iBlock in pairs(interruptingBlocks) do
		if not iBlock.isHidden 
		and (
			Block.SOLID_MAP[iBlock.id]
			or Block.PLAYER_MAP[iBlock.id]
			or Block.LAVA_MAP[iBlock.id]
		) 
		then
			return false
		end
	end

	--off the top of the screen
	local section = kamek:mem(0x146, FIELD_WORD)
	if section >= 0 and section <= 20 then -- just in case
		local topBound = Section(section).boundary.top
		if block.y <= topBound then
			return false
		end
	end

	return true
end 

local function teleport(kamek)
	local cam = camera
	local availableBlocks = table.ishuffle(Block.getIntersecting(cam.x, cam.y, cam.x + cam.width, cam.y + cam.height))
	for _,block in ipairs(availableBlocks) do
		if canSpawnHere(block, kamek) then
			kamek.x = block.x + 0.5 * (block.width - kamek.width)
			kamek.y = block.y - kamek.height
			return true
		end
	end
	return false
end

local function spawnMagic(npc)

	local spawnX = npc.x + npc.width/2 + (Kamek.config.magicoffsetx * npc.direction)
	local spawnY = npc.y + npc.height/2 + (Kamek.config.magicoffsety)

	local theThrownNpc = NPC.spawn(Kamek.config.magic, spawnX, spawnY, npc:mem(0x146, FIELD_WORD), false, true)
	theThrownNpc.direction = npc.direction
	theThrownNpc.friendly = npc.friendly
	theThrownNpc.layerName = "Spawned NPCs"
end 

local function drawTeleportImage(kamek)
	local data = kamek.data._basegame
	if data.isHidden and not data.isKilled then

		if(MAX_HIDDEN_TIMER - data.visibilityTimer <= Kamek.config.disappeartime) then --disappearing
			data.opacity = 1 - (MAX_HIDDEN_TIMER - data.visibilityTimer) / Kamek.config.disappeartime
		elseif(data.visibilityTimer <= Kamek.config.appeartime) then --appearing
			data.opacity = 1 - data.visibilityTimer / Kamek.config.appeartime
		elseif(data.opacity > 0) then --spawning interrupted
			--TODO: if Mario touches a spawning magikoopa, prevent spawning and teleport somewhere else?
			data.opacity = math.max(data.opacity - 1/Kamek.config.disappeartime, 0)
		end 

		if(data.opacity > 0) then 
			local p = Player.getNearest(kamek.x + 0.5 * kamek.width, kamek.y)
			local sourceY = (data.drawX+kamek.width*0.5 > p.x+p.width*0.5) -- 4th frame (TODO:allow more frame customization?)
				and (Kamek.config.minFrameLeft+3) * Kamek.config.gfxheight
				or (Kamek.config.minFrameRight+3) * Kamek.config.gfxheight
			local priority = -45
			if kamek.config.foreground then
				priority = -15
			end
			Graphics.draw {
				type = RTYPE_IMAGE,
				image = Graphics.sprites.npc[npcID].img,
				isSceneCoordinates = true,
				x = data.drawX + (Kamek.config.gfxoffsetx or 0) - (Kamek.config.gfxwidth  - kamek.width)*0.5, 
				y = data.drawY + (Kamek.config.gfxoffsety or 0) - (Kamek.config.gfxheight - kamek.height),
				sourceX = 0,
				sourceY = sourceY,
				sourceWidth = Kamek.config.gfxwidth,
				sourceHeight = Kamek.config.gfxheight,
				opacity = data.opacity,
				priority = priority
			}

		end
	end
end 

local function sparkle(x,y) 
	local spawnX = x + rng.randomInt(-18, 18)
	local spawnY = y + rng.randomInt(-18, 18)
	local anim = Animation.spawn(80, spawnX, spawnY)
	anim.x = anim.x - anim.width/4
	anim.y = anim.y - anim.height/4
end 

local function despawn(kamek)
	kamek:mem(0x124, FIELD_WORD, 0)
	kamek:mem(0x128, FIELD_WORD, -1)
	kamek:mem(0x12A, FIELD_WORD, -1)
end 


local function despawnOnscreen(kamek)
	kamek:mem(0x124, FIELD_WORD, 0)
	kamek:mem(0x128, FIELD_WORD, 0)
	kamek:mem(0x12A, FIELD_WORD, -1)
end 


local function spawn(kamek)
	kamek:mem(0x124, FIELD_WORD, -1) 
	kamek:mem(0x128, FIELD_WORD, 0) 
	kamek:mem(0x12A, FIELD_WORD, 180) 
	kamek.animationFrame = magikoopaDirection[kamek.direction] -- first frame
end 

function Kamek.onCameraUpdate(cameraIndex)
	if cameraIndex == 1 then
		if not Defines.levelFreeze then 
			for k, v in pairs(magikoopa.teleportingKameks) do
				local kamek = v
				local data = kamek.data._basegame
				if (kamek.dontMove or teleport(kamek)) then
					data.drawX = kamek.x
					data.drawY = kamek.y
					data.drawDir = kamek.direction
				elseif data.drawX == kamek.x and data.drawY == kamek.y then
					data.visibilityTimer = data.visibilityTimer + 1
				end 
			end
			magikoopa.teleportingKameks = {}
		end 
	end
end

function Kamek.onTickNPC(kamek)
	if Defines.levelFreeze then return end
	
	local data = kamek.data._basegame
	local settings = kamek.data._settings

	local p = Player.getNearest(kamek.x + 0.5 * kamek.width, kamek.y) --closest player is likely to be in the same section
	if(kamek:mem(0x146, FIELD_WORD) ~= p.section or kamek.isHidden) then --in different section or on hidden layer
		if(data.initialized) then 
			data.initialized = false 
			kamek.x = kamek:mem(0xA8, FIELD_DFLOAT) + NPC_X_OFFSET
			kamek.y = kamek:mem(0xB0, FIELD_DFLOAT)
		end  
	elseif (not data.initialized) and (kamek:mem(0x138, FIELD_WORD) > 0 or kamek:mem(0x132, FIELD_WORD) > 0 or kamek:mem(0x130, FIELD_WORD) > 0) then
		data.initialized = true
		data.visibilityTimer = 0
		data.isHidden = false
		data.isKilled = false
		data.opacity = 1
		data.drawX = kamek:mem(0xA8, FIELD_DFLOAT) + NPC_X_OFFSET
		data.drawY = kamek:mem(0xB0, FIELD_DFLOAT)
		
	
	elseif(not data.initialized and 
		(kamek:mem(0x12A, FIELD_WORD) == 180 or --onscreen
		(kamek:mem(0x12A, FIELD_WORD) == -1 and kamek:mem(0x128, FIELD_WORD) == 0 and kamek:mem(0x124, FIELD_WORD) == 0))) --timer -1, oflag 0, prvnt 0
	then --onscreen, but not initialized		
		
		--[[ DEBUG	
		Text.windowDebug("timer "..tostring(v:mem(0x12A, FIELD_WORD))..
										"\nprvnt "..tostring(v:mem(0x124, FIELD_WORD))..
										"\noflag "..tostring(v:mem(0x128, FIELD_WORD)));		
		]]--
		data.initialized = true
		--data.visibilityTimer = data.visibilityTimer or (Kamek.config.appeartime - 1)
		data.visibilityTimer = MAX_VISIBLE_TIMER
		data.isKilled = false
		if settings.teleports == nil then settings.teleports = true end
		if settings.respawns == nil then settings.respawns = true end
		if settings.layerfilter == nil then settings.layerfilter = false end
		data.isHidden = false
		settings.volley = settings.volley or 1
		data.currentvolley = settings.volley
		data.drawX = kamek:mem(0xA8, FIELD_DFLOAT) + NPC_X_OFFSET
		data.drawY = kamek:mem(0xB0, FIELD_DFLOAT)
	elseif(data.initialized and not Defines.levelFreeze) then --main magikoopa logic
		--disable vanilla smbx animation
		kamek.animationTimer = 1
		if (kamek:mem(0x138, FIELD_WORD) > 0 or kamek:mem(0x132, FIELD_WORD) > 0 or kamek:mem(0x130, FIELD_WORD) > 0) then
			data.visibilityTimer = 0
			data.isHidden = false
			kamek.animationFrame = magikoopaDirection[kamek.direction]
			return
		end

		--make the magikoopa face the player
		if kamek.x+kamek.width/2 < p.x+p.width/2 then -- facing right
			kamek.direction = 1
		else -- facing left
			kamek.direction = -1
		end

		--animate the magikoopa and 
		--spawn magic
		if(not data.isHidden) then
			if settings.teleports then
				kamek:mem(0x12A, FIELD_WORD, 180) --prevent despawn
			elseif kamek:mem(0x12A, FIELD_WORD) <= 0 then
				data.initialized = false
			end
			--TODO:  if offscreen before firing, teleport somewhere else?
			if(data.visibilityTimer > MAX_VISIBLE_TIMER - Kamek.config.premagictime) then 
				--preMagic animation
				kamek.animationFrame = magikoopaDirection[kamek.direction]

				if(data.visibilityTimer % 4 == 0) then 
					sparkle(kamek.x+kamek.width/2+(Kamek.config.sparkleoffsetx*kamek.direction), kamek.y+kamek.height/2+(Kamek.config.sparkleoffsety))
				end 
			elseif(data.visibilityTimer == MAX_VISIBLE_TIMER - Kamek.config.premagictime) then 
				--fire the magic after Kamek.config.premagictime frames
				kamek.animationFrame = magikoopaDirection[kamek.direction]
				
				spawnMagic(kamek)
			elseif(data.visibilityTimer >= 0) then
				--postMagic animation 

				if(math.floor(data.visibilityTimer / Kamek.config.framespeed) % 2 == 0) then 
					kamek.animationFrame = magikoopaDirection[kamek.direction] + 1
				else 
					kamek.animationFrame = magikoopaDirection[kamek.direction] + 2
				end 
				if data.visibilityTimer == math.max(Kamek.config.postmagictime - 10, 0) then
					if data.currentvolley > 1 then
						data.visibilityTimer = MAX_VISIBLE_TIMER - Kamek.config.premagictime + 1
						data.currentvolley = data.currentvolley - 1
					else
						data.currentvolley = settings.volley
					end
				end
			end 
		end  

		--despawning, respawning and teleporting
		if(data.visibilityTimer == 0) then
			if settings.teleports then
				if(not data.isHidden) then --despawn the NPC (the fading image is still drawn)
					data.visibilityTimer = MAX_HIDDEN_TIMER
					data.drawX = kamek.x
					data.drawY = kamek.y
					data.drawDir = kamek.direction
					despawn(kamek)
					data.isHidden = true
				else --respawn the NPC (no more appearing image)
					data.visibilityTimer = MAX_VISIBLE_TIMER
					kamek.x = data.drawX
					kamek.y = data.drawY
					spawn(kamek)
					data.isHidden = false
				end
			else
				data.visibilityTimer = MAX_VISIBLE_TIMER
				kamek.x = data.drawX
				kamek.y = data.drawY
				data.isHidden = false
			end
		elseif(data.isHidden and data.visibilityTimer == Kamek.config.appeartime) then
			--teleport (appearing image starts being drawn)
			data.isKilled = false
			if settings.teleports then
				table.insert(magikoopa.teleportingKameks, kamek)
			end
		end

		data.visibilityTimer = data.visibilityTimer -1
	end
end

function Kamek.onDrawNPC(kamek)
	if not kamek.isHidden then
		drawTeleportImage(kamek)
	end
end 

--***************************************************************************************************
--                                                                                                  *
--              API FUNCTIONS                                                                       *
--                                                                                                  *
--***************************************************************************************************

function magikoopa.onNPCKill(eventObj,killedNPC,killReason)

	if killedNPC.id == npcID and 
	   Kamek.config.respawntime >= 0 and 
	   killedNPC:mem(0x64, FIELD_WORD) ~= -1 
	then --Kamek
	
		--[[ 
		if Kamek.config.respawntime is set to a positive number,  
        the magikoopa cannot be killed, but will instead despawn 
		for a set amount of frames defined by Kamek.config.respawntime
		]]--
		local kamek = killedNPC
		local settings = kamek.data._settings
		if not settings.respawns then return end
		local data = kamek.data._basegame
		eventObj.cancelled = true;
		data.visibilityTimer = Kamek.config.respawntime
		data.drawX = kamek.x
		data.drawY = kamek.y
		data.drawDir = kamek.direction
		data.isHidden = true
		data.isKilled = true
		if(isOnscreen(kamek)) then 
			despawnOnscreen(kamek)
		else
			despawn(kamek)
		end
	end
end 

function magikoopa.onInitAPI()
	registerEvent(magikoopa, "onNPCKill", "onNPCKill", false)
	registerEvent(Kamek, "onCameraUpdate", "onCameraUpdate", false)
	npcManager.registerEvent(npcID, Kamek, "onTickNPC")
	npcManager.registerEvent(npcID, Kamek, "onDrawNPC")
end

return magikoopa