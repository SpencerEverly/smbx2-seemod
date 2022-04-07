--ninjabomberman.lua
--v0.0.2
--Created by Horikawa Otane, 2015
--Contact me at https://www.youtube.com/subscription_center?add_user=msotane

local colliders = require("colliders")
local savestate = require("savestate")
local pm = require("playerManager")
local ed = require("expandedDefines")
--local graphx = require("graphX")

local ninjabomberman = {}
local startedAsBomberman = false
local isInStartMenu = false
local oldGravity = 12
local hitBoxArray = {}
local frameCount = 0
local firstSave = false
local hasJumped = true
local hasTurnedHudOn = false
local deathTimer = -1;
local deathSoundChan = -1;

ninjabomberman.usesavestate = false;
ninjabomberman.deathDelay = lunatime.toTicks(0.5);

local sfx_death = pm.registerSound(CHARACTER_NINJABOMBERMAN,"nbm_death.ogg");
local sfx_deathquick = pm.registerSound(CHARACTER_NINJABOMBERMAN,"nbm_death_quick.ogg");

local function freezePlayer(pauseMusic, pauseSound, playerX, playerY)
	pauseMusic = pauseMusic or false
	pauseSound = pauseSound or false
	playerX = playerX or player.x
	playerY = playerY or player.y
	mem(0x00B2C8B4, FIELD_WORD, -1)
	player.x = playerX
	player.y = playerY
	player:mem(0x04, FIELD_WORD, -1)
	--player:mem(0x11E, FIELD_WORD, 1)
	if pauseMusic then
		Audio.SeizeStream(-1)
		Audio.MusicPause()
	end
	if pauseSound then
		Audio.SfxPause(-1)
	end
end

local function unFreezePlayer(musicPaused, soundPaused)
	musicPaused = musicPaused or false
	soundPaused = soundPaused or false
	mem(0x00B2C8B4, FIELD_WORD, 0)
	player:mem(0x04, FIELD_WORD, 0)
	--player:mem(0x11E, FIELD_WORD, -1) || don't do this, it enables autojump
	if musicPaused then
		Audio.MusicResume()
		Audio.ReleaseStream(-1)
	end
	if soundPaused then
		Audio.SfxResume(-1)
	end
end

function ninjabomberman.onInitAPI()
	registerEvent(ninjabomberman, "onTick", "onTick", false)
	registerEvent(ninjabomberman, "onKeyDown", "onKeyDown", false)
	registerEvent(ninjabomberman, "onInputUpdate", "onInputUpdate", false)
	registerEvent(ninjabomberman, "onJump", "onJump", false)
	registerEvent(ninjabomberman, "onJumpEnd", "onJumpEnd", false)
	if (player.isValid) then
		if (player.character == CHARACTER_NINJABOMBERMAN) then
			player:mem(0x16, FIELD_WORD, 1)
		end
	end
end

--OnTick

function ninjabomberman.onTick()
	if (player.character == CHARACTER_NINJABOMBERMAN) then
		if frameCount < 1 then
			frameCount = frameCount + 1
		elseif frameCount == 1 and not firstSave then
			state = savestate.save(savestate.STATE_ALL)
			firstSave = true
		end
		if isInStartMenu then
			Defines.gravity = 0
			freezePlayer(false, false, player.x, player.y)
			Text.printWP("Press run to Exit Level", 200, 200,-5)
		else
			unFreezePlayer(false, false)
			Defines.gravity = 12
		end
		if not startedAsBomberman then
			state = savestate.save(savestate.STATE_ALL)
			startedAsBomberman = true
		end
		player:mem(0x1A, FIELD_BOOL, false)
		player:mem(0x18, FIELD_BOOL, false)

		for k, v in pairs(NPC.get()) do
			if (v.id == 192) then
				if (colliders.collide(player, v)) then
					state = savestate.save(savestate.STATE_ALL)
				end
			end
		end
		
		--[[
		for _, v in pairs(NPC.get(291, player.section)) do
			graphx.boxLevel(v.x, v.y, v.width, v.height, 0xFF000066)
			for _, w in pairs(NPC.get(horikawaTools.hittableNPCs, player.section)) do
				Text.print(w.id, 100, 100)
				if (horikawaTools.npcList[w.id] or horikawaTools[w.id] == 2) then
					if (colliders.collide(v, w)) then
						canJump = true
						break
					end
				end
			end
		end
		]]
		
		for _, npcLister in pairs(NPC.get(NPC.HITTABLE, player.section)) do
			if (npcLister:mem(0x64, FIELD_WORD) == 0) and (npcLister:mem(0x40, FIELD_WORD) == 0) then
				local thePnpc = npcLister
				npcHitBox = hitBoxArray[thePnpc.uid]
				
				-- If we already had this NPC in hitBoxArray, don't replace our old object, just update the hitbox
				if npcHitBox == nil then
					npcHitBox = {}
					npcHitBox.thePnpc = thePnpc
					npcHitBox.hasBeenHit = false
					hitBoxArray[npcHitBox.thePnpc.uid] = npcHitBox
					npcHitBox.timeout = 0
				end
				
				npcHitBox.timeout = 0
				npcHitBox.x = npcLister.x
				npcHitBox.x2 = npcLister.x + npcLister.width
				npcHitBox.y = npcLister.y
				npcHitBox.y2 = npcLister.y + npcLister.height
				--graphx.boxLevel(npcLister.x, npcLister.y, npcLister.width, npcLister.height, 0x00FF0066)
			end
		end
		for _, hitBox in pairs(hitBoxArray) do			
			for _, hitAnimation in pairs(Animation.getIntersecting(hitBox.x, hitBox.y, hitBox.x2, hitBox.y2)) do
				if not hitBox.hasBeenHit and (hitAnimation.id == 148) then
					--graphx.boxLevel(hitAnimation.x, hitAnimation.y, hitAnimation.width, hitAnimation.height, 0xFF00FFFF)
					hitBox.hasBeenHit = true
					canJump = true
				end
			end
			
			-- If destroyed or marked as dead...
			if (not hitBox.thePnpc.isValid) or (hitBox.thePnpc.forcedState ~= 0) then
				hitBox.timeout = hitBox.timeout + 1
				if hitBox.timeout > 5 then
					hitBoxArray[hitBox.thePnpc.uid] = nil
				end
			end
		end

		if player:mem(0x16, FIELD_WORD) > 1 then
			player:mem(0x16, FIELD_WORD, 1)
		end
		if player:mem(0x13C, FIELD_DWORD) ~= 0 or player.forcedState == 227 or player.forcedState == 2 then
			player:kill()
			if SaveData.deathquickoption == false then
				Audio.SfxStop(-1)
				Audio.playSFX(pm.getSound(CHARACTER_NINJABOMBERMAN,sfx_death))
				player:mem(0x13E, FIELD_WORD,1)
				Misc.pause();
				deathTimer = 800;
			elseif SaveData.deathquickoption == true then
				--Audio.playSFX(pm.getSound(CHARACTER_NINJABOMBERMAN,sfx_deathquick))
			end
		end
		
		--Jumps
		 if (not player:isGroundTouching() and player:mem(0x34, FIELD_WORD) ~= 2) and (player:mem(0x48, FIELD_WORD) == 0) then
			if player:mem(0x40, FIELD_WORD) ~= 3 then
				if not hasJumped then
					canJump = true
					hasJumped = true
				end
			else
				canJump = false
				hasJumped = false
			end
			if  player.jumpKeyPressing or player.altJumpKeyPressing then
				if player.speedY > 0.2 then 
					player.speedY = 2.5
				end
				--Hover timer
				--player:mem(0x1C, FIELD_WORD) == 25
			end			
		else
			canJump = false
			hasJumped = false
		end
		--Quit level
		if player.keys.run == KEYS_PRESSED and isInStartMenu then
			unFreezePlayer(false, false)
			exitLevel()
		end
	end
end

--onkeydown

function ninjabomberman.onKeyDown(keycode)
	if (player.character == CHARACTER_NINJABOMBERMAN) then
		if (keycode) == KEY_SEL and ninjabomberman.usesavestate then
			if not isInStartMenu then
				oldGravity = Defines.gravity
			end
			isInStartMenu = not isInStartMenu
		elseif (keycode == KEY_JUMP) or (keycode == KEY_SPINJUMP) then
			--prevent hover 
			player:mem(0x1C, FIELD_WORD, 0)
			if (canJump) then
				player.speedY = -10
				playSFX(1)
				NPC.spawn(291, player.x, player.y, player:mem(0x15A, FIELD_WORD))
				canJump = false
			end
		end
	end
end

--onInputUpdate

function ninjabomberman.onInputUpdate()
	if (player.character == CHARACTER_NINJABOMBERMAN) then
		pm.winStateCheck()
		if isInStartMenu then
			player.leftKeyPressing = false
			player.rightKeyPressing = false
		end
		if(Misc.isPaused()) then
			if(deathTimer > 0) then
				deathTimer = deathTimer - 1;
			elseif(deathTimer == 0) then
				if(ninjabomberman.usesavestate) then
					savestate.load(state, savestate.STATE_ALL)
					player.jumpKeyPressing = false
					player:mem(0x16, FIELD_WORD, 1)
					Misc.unpause();
					deathTimer = -1;
				else
					Misc.unpause();
					player:mem(0x13E,FIELD_WORD,198);
				end
			end
		end
	end
end

--onjump

function ninjabomberman.onJump()
	if (player.character == CHARACTER_NINJABOMBERMAN) then
		canJump = true
		hasJumped = true
	end
end

function ninjabomberman.onJumpEnd()
	if (player.character == CHARACTER_NINJABOMBERMAN) then
		canJump = false
		for _, j in pairs(hitBoxArray) do
			j.hasBeenHit = false
		end
		hasJumped = false
	end
end

--CLEANUP

function ninjabomberman.initCharacter()
	-- CLEANUP NOTE: This is not safe if a level makes it's own use of gravity/jumpheight
	Defines.jumpheight = 10
	Defines.jumpheight_bounce = 12

	-- CLEANUP NOTE: This is not safe if a level makes it's own use of activateHud
	hasTurnedHudOn = false
	hud(false)
end

function ninjabomberman.cleanupCharacter()
	-- CLEANUP NOTE: This is not safe if a level makes it's own use of activateHud
	if not hasTurnedHudOn then
		hud(true)
		hasTurnedHudOn = true
	end
	
	isInStartMenu = false
	startedAsBomberman = false
	
	-- CLEANUP NOTE: This is not safe if a level makes it's own use of gravity/jumpheight
	Defines.jumpheight = nil
	Defines.jumpheight_bounce = nil
	Defines.gravity = 12
end

return ninjabomberman