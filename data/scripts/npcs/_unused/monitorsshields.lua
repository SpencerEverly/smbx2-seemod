local monitorsShields = {}

local npcManager = require("npcManager")
local colliders = require("colliders")
local vectr = require("vectr")
local ed = require("expandedDefines")
local inputs2 = require("inputs2")
local darkness = require("darkness")

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

monitorsShields.ringID = 494;
monitorsShields.blueID = 495;
monitorsShields.thunderID = 496;
monitorsShields.bubbleID = 497;
monitorsShields.flameID = 498;
monitorsShields.invincibilityID = 538;

-- constants because why not
monitorsShields.blueShield = 1;
monitorsShields.thunderShield = 2;
monitorsShields.bubbleShield = 3;
monitorsShields.flameShield = 4;

-- time to copypaste code because for loops don't work for this lol
local ringData = {}
ringData.config = npcManager.setNpcSettings({
	id = monitorsShields.ringID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white
})	

npcManager.registerHarmTypes(monitorsShields.ringID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

-- shield
local blueData = {}
blueData.config = npcManager.setNpcSettings({
	id = monitorsShields.blueID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	shieldwidth = 96, 
	shieldheight = 96, 
	shieldframes = 5, 
	shieldframespeed = 8.5,
	shieldgfx = Graphics.loadImage(Misc.multiResolveFile("shield-1.png", "graphics/shield/shield-1.png"))
})
npcManager.registerHarmTypes(monitorsShields.blueID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

monitorsShields.blueShieldSFX = Misc.resolveSoundFile("shield")

-- thunder
local thunderData = {}
thunderData.config = npcManager.setNpcSettings({
	id = monitorsShields.thunderID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	shieldwidth = 96, 
	shieldheight = 96, 
	shieldframes = 24, 
	shieldframespeed = 8.35,
	shieldgfx = Graphics.loadImage(Misc.multiResolveFile("shield-2.png", "graphics/shield/shield-2.png")),
	shieldattractradius = 240
})
npcManager.registerHarmTypes(monitorsShields.thunderID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

monitorsShields.thunderShieldSFX = Misc.resolveSoundFile("thunder-shield")
monitorsShields.thunderShieldJumpSFX = Misc.resolveSoundFile("thunder-shield-jump")

-- bubble
local bubbleData = {}
bubbleData.config = npcManager.setNpcSettings({
	id = monitorsShields.bubbleID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	shieldwidth = 96, 
	shieldheight = 96, 
	shieldframes = 9, 
	shieldframespeed = 8.2,
	shieldgfx = Graphics.loadImage(Misc.multiResolveFile("shield-3.png", "graphics/shield/shield-3.png")),
	shieldbouncewidth = 144, 
	shieldbounceheight = 96, 
	shieldbounceframes = 4, 
	shieldbounceframespeed = 8.35,
	shieldbouncegfx = Graphics.loadImage(Misc.multiResolveFile("shield-4.png", "graphics/shield/shield-4.png"))
})
npcManager.registerHarmTypes(monitorsShields.bubbleID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

monitorsShields.bubbleShieldSFX = Misc.resolveSoundFile("bubble-shield")
monitorsShields.bubbleShieldJumpSFX = Misc.resolveSoundFile("bubble-shield-jump")

-- flame
local flameData = {}
flameData.config = npcManager.setNpcSettings({
	id = monitorsShields.flameID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	shieldwidth = 96, 
	shieldheight = 96, 
	shieldframes = 18, 
	shieldframespeed = 8.4,
	shieldgfx = Graphics.loadImage(Misc.multiResolveFile("shield-5.png", "graphics/shield/shield-5.png")),
	shielddashwidth = 128, 
	shielddashheight = 96, 
	shielddashframes = 3, 
	shielddashframespeed = 8.5,
	shielddashgfx = Graphics.loadImage(Misc.multiResolveFile("shield-6.png", "graphics/shield/shield-6.png")),
	shielddashlength = 25;
})
npcManager.registerHarmTypes(monitorsShields.flameID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

monitorsShields.flameShieldSFX = Misc.resolveSoundFile("flame-shield")
monitorsShields.flameShieldDashSFX = Misc.resolveSoundFile("flame-shield-dash")

-- invincible
local invincibleData = {}
invincibleData.config = npcManager.setNpcSettings({
	id = monitorsShields.invincibilityID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white
})
npcManager.registerHarmTypes(monitorsShields.invincibilityID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

-- ready set go
function monitorsShields.onInitAPI()
	registerEvent(monitorsShields, "onNPCKill", "onNPCKill", false)
	registerEvent(monitorsShields, "onTick", "rewardLogic", false);
	registerEvent(monitorsShields, "onTickEnd", "shieldLogic", false);
	registerEvent(monitorsShields, "onDraw", "shieldDraw", false);
end

-- API-wide (no npc ties)
local rewardTimer = -1;
local upcomingReward = 0;
local shieldAnimFrame = 0;

local previousPowerup = 1;

local canShieldAttack = false;

local isBubbleBouncing = false;
local remainBounceTimer = -1;

local isFlameDashing = false;
local flameStoreSpeed = 0;
local dashTimer = -1;
local wasonground = true;

monitorsShields.hasShield = false;
monitorsShields.shieldType = 0;
local shieldLight;

monitorsShields.breakSound = Misc.resolveSoundFile("sonic-break")
monitorsShields.lossSound = Misc.resolveSoundFile("shield-loss")

local shieldCollider = colliders.Box(0,0,1,1);

monitorsShields.coinTable = {10, 33, 88, 103, 138, 152, 251, 252, 253, 258}

monitorsShields.ignore = {};
monitorsShields.ignore[108] = true;

local function shieldFilter(v)
	return colliders.FILTER_COL_NPC_DEF(v) and not monitorsShields.ignore[v.id];
end

--***************************************************************************************************
--                                                                                                  *
--              BEHAVIOR                                                                            *
--                                                                                                  *
--***************************************************************************************************

function monitorsShields.onNPCKill(eventObj, npc, killReason)
	if killReason ~= 9 then
		if (npc.id >= 494 and npc.id <= 498) or (npc.id == 538) then
			SFX.play(monitorsShields.breakSound)
			upcomingReward = npc.id;
			rewardTimer = 30;
		end
	end
end

-- pause for a bit on break of monitor
function monitorsShields.rewardLogic()
	-- putting this here because i'm lazy
	previousPowerup = player.powerup;
	
	-- fixes a bug that occurs because isGroundTouching is a frame off sometimes
	wasonground = player:isGroundTouching();

	-- decrement timer
	if rewardTimer > -1 then
		rewardTimer = rewardTimer - 1;
	
		-- Here he is.
		if rewardTimer == 0 then
			
			-- Ring monitor
			if upcomingReward == monitorsShields.ringID then
				SFX.play(56)
				mem(0x00B2C5A8, FIELD_WORD, mem(0x00B2C5A8, FIELD_WORD)+10)
			-- Invincibility monitor
			elseif upcomingReward == monitorsShields.invincibilityID then
				NPC.spawn(293, player.x, player.y, player.section)
			-- Vanilla shield monitor
			elseif upcomingReward == monitorsShields.blueID then
				SFX.play(monitorsShields.blueShieldSFX)
				monitorsShields.hasShield = true;
				monitorsShields.shieldType = 1;
				shieldLight = darkness.addLight(darkness.light(0,0,128,1,Color.white))
				shieldLight:attach(player, true)
				isBubbleBouncing = false;
				isFlameDashing = false;
			elseif upcomingReward == monitorsShields.thunderID then
				SFX.play(monitorsShields.thunderShieldSFX)
				monitorsShields.hasShield = true;
				monitorsShields.shieldType = 2;
				shieldLight = darkness.addLight(darkness.light(0,0,128,1,Color.white))
				shieldLight:attach(player, true)
				canShieldAttack = true;
				isBubbleBouncing = false;
				isFlameDashing = false;
			elseif upcomingReward == monitorsShields.bubbleID then
				SFX.play(monitorsShields.bubbleShieldSFX)
				monitorsShields.hasShield = true;
				monitorsShields.shieldType = 3;
				shieldLight = darkness.addLight(darkness.light(0,0,128,1,Color.cyan))
				shieldLight:attach(player, true)
				canShieldAttack = true;
				isFlameDashing = false;
			elseif upcomingReward == monitorsShields.flameID then
				SFX.play(monitorsShields.flameShieldSFX)
				monitorsShields.hasShield = true;
				monitorsShields.shieldType = 4;
				shieldLight = darkness.addLight(darkness.light(0,0,128,1,Color.orange))
				shieldLight:attach(player, true)
				canShieldAttack = true;
				isBubbleBouncing = false;
			end
		
		end
	end

end

-- Shields
function monitorsShields.shieldLogic()
	if monitorsShields.hasShield then
	
		-- animation
		if monitorsShields.shieldType == monitorsShields.blueShield then
			shieldAnimFrame = shieldAnimFrame + blueData.config.shieldframespeed;
			if shieldAnimFrame >= blueData.config.shieldframes then
				shieldAnimFrame = 0;
			end
		elseif monitorsShields.shieldType == monitorsShields.thunderShield then
			shieldAnimFrame = shieldAnimFrame + thunderData.config.shieldframespeed;
			if shieldAnimFrame >= thunderData.config.shieldframes then
				shieldAnimFrame = 0;
			end
		elseif monitorsShields.shieldType == monitorsShields.bubbleShield then
			if isBubbleBouncing then
				shieldAnimFrame = shieldAnimFrame + bubbleData.config.shieldbounceframespeed;
				if shieldAnimFrame > bubbleData.config.shieldbounceframes-1 and remainBounceTimer == -1 then
					shieldAnimFrame = bubbleData.config.shieldbounceframes-1;
				elseif remainBounceTimer > 0 then
					if shieldAnimFrame > bubbleData.config.shieldbounceframes-2 then
						shieldAnimFrame = 0;
					end
				end
			else
				shieldAnimFrame = shieldAnimFrame + bubbleData.config.shieldframespeed;
				if shieldAnimFrame >= bubbleData.config.shieldframes then
					shieldAnimFrame = 0;
				end
			end
		elseif monitorsShields.shieldType == monitorsShields.flameShield then
			if isFlameDashing then
				shieldAnimFrame = shieldAnimFrame + flameData.config.shielddashframespeed;
				if shieldAnimFrame >= flameData.config.shielddashframes then
					shieldAnimFrame = 0;
				end
			else
				shieldAnimFrame = shieldAnimFrame + flameData.config.shieldframespeed;
				if shieldAnimFrame >= flameData.config.shieldframes then
					shieldAnimFrame = 0;
				end
			end
		end
		
		-- losing shield
		if player:mem(0x122,FIELD_WORD) == 2 then
			player.powerup = previousPowerup;
			player:mem(0x122,FIELD_WORD,0)
			player:mem(0x140,FIELD_WORD,75)
			monitorsShields.loseShield()
			
			if inputs2.locked[1].all == true then
				inputs2.locked[1].all = false;
			end
		end
		
		-- kill thunder or flame shields if you go underwater
		if player:mem(0x34,FIELD_WORD) == 2 then
			if monitorsShields.shieldType == monitorsShields.thunderShield or monitorsShields.shieldType == monitorsShields.flameShield then
				monitorsShields.hasShield = false;
				monitorsShields.shieldType = 0;
				isBubbleBouncing = false;
				isFlameDashing = false;
				SFX.play(35)
				
				if inputs2.locked[1].all == true then
					inputs2.locked[1].all = false;
				end
			end
		end
		
		-- dont let peach or toad do weird stuff
		if (monitorsShields.shieldType == monitorsShields.thunderShield or monitorsShields.shieldType == monitorsShields.bubbleShield) and canShieldAttack then
			player:mem(0x18,FIELD_WORD,-1)
			player:mem(0x00,FIELD_WORD,0)
		end
		
		-- elemental shield behaviors
		if monitorsShields.shieldType > monitorsShields.blueShield then
			-- reset attack on touching ground
			if wasonground then
				canShieldAttack = true;
			end
			
			-- THUNDER Shields
			if monitorsShields.shieldType == monitorsShields.thunderShield then
				-- update attraction collider
				shieldCollider.x = player.x - (thunderData.config.shieldattractradius*.5);
				shieldCollider.y = player.y - (thunderData.config.shieldattractradius*.5);
				shieldCollider.width = player.width + thunderData.config.shieldattractradius;
				shieldCollider.height = player.height + thunderData.config.shieldattractradius;
			
				-- double jump
				if player.keys.jump == KEYS_PRESSED and canShieldAttack and not wasonground then
					for i=-4,4,8 do
						local smoke = Animation.spawn(80,player.x+(player.width/2),player.y+player.height) smoke.speedX = i; smoke.speedY = 4;
						local smoke = Animation.spawn(80,player.x+(player.width/2),player.y+player.height) smoke.speedX = i; smoke.speedY = -4;
					end
					player:mem(0x50, FIELD_WORD, 0) --spinjump
					player:mem(0x11C, FIELD_WORD, 12)
					SFX.play(monitorsShields.thunderShieldJumpSFX)
					canShieldAttack = false;
				end
				
				-- attract rings
				for k,v in ipairs(NPC.get(monitorsShields.coinTable, player.section)) do
					local temphome = v
					if colliders.collide(shieldCollider,v) then
						temphome.data.home = true;
					end
					
					if temphome.data.home ~= nil then
						local chasePlayer = player
						if player2 then
							local d1 = player.x + player.width * 0.5
							local d2 = player2.x + player2.width * 0.5
							local dr = v.x + v.width * 0.5
						
							if (v.direction == 1 and d1 < dr)
							or (v.direction == -1 and d1 > dr)
							or rng.randomInt(0,1) == 1 then
								chasePlayer = player2
							end
						end
						local dirVector = vectr.v2(chasePlayer.x + (0.5 * chasePlayer.width) - (v.x + 0.5 * v.width), 
								chasePlayer.y + (0.5 * chasePlayer.height) - (v.y + 0.5 * v.height))
							   
						dirVector = dirVector:normalize()
						--dirVector = dirVector * 1.25;
						v.speedX = v.speedX + dirVector.x
						v.speedY = v.speedY + dirVector.y*.9
					end
				end
			end
			
			-- BUBBLE shields
			if monitorsShields.shieldType == monitorsShields.bubbleShield then
				-- update attraction collider
				shieldCollider.x = player.x - 8;
				shieldCollider.y = player.y - 16;
				shieldCollider.width = player.width + 16;
				shieldCollider.height = player.height + 32;
				--shieldCollider:Debug(true)
				
				-- ground pound
				if player.keys.jump == KEYS_PRESSED and canShieldAttack and not wasonground and not isBubbleBouncing and player:mem(0x34,FIELD_WORD) ~= 2 then
					SFX.play(monitorsShields.bubbleShieldJumpSFX)
					shieldAnimFrame = 0;
					canShieldAttack = false;
					isBubbleBouncing = true;
					player:mem(0x50, FIELD_WORD, 0) --spinjump
					player.speedY = 12;
					player.speedX = 0;
				end
				
				if wasonground and isBubbleBouncing and remainBounceTimer == -1 then
					player.speedY = -5;
					player:mem(0x11C, FIELD_WORD, 35)
					remainBounceTimer = 30;
					SFX.play(monitorsShields.bubbleShieldJumpSFX)
					shieldAnimFrame = 0;
				end
				
				-- stop pound if you hit water
				if player:mem(0x34,FIELD_WORD) == 2 then
					isBubbleBouncing = false;
					remainBounceTimer = -1;
				end
				
				if remainBounceTimer > -1 then
					remainBounceTimer = remainBounceTimer - 1;
					if remainBounceTimer == 0 then
						isBubbleBouncing = false;
						shieldAnimFrame = 0;
					end
				end
				
				for _,v in ipairs(colliders.getColliding{a = shieldCollider, b = NPC.HITTABLE, btype = colliders.NPC, filter = shieldFilter}) do
					if isBubbleBouncing then
						v:harm(HARM_TYPE_EXT_HAMMER);
						SFX.play(monitorsShields.bubbleShieldJumpSFX)
						SFX.play(2)
						player.speedY = -5;
						player:mem(0x11C, FIELD_WORD, 35)
						remainBounceTimer = 30;
						canShieldAttack = true;
					end
				end
				
				-- failsafe
				if player.speedY < 0 and isBubbleBouncing and remainBounceTimer == -1 then
					remainBounceTimer = 30;
					SFX.play(monitorsShields.bubbleShieldJumpSFX)
					shieldAnimFrame = 0;
				end
			end
			
			-- FLAME shields
			if monitorsShields.shieldType == monitorsShields.flameShield then
				-- update attraction collider
				shieldCollider.x = player.x - 16;
				shieldCollider.y = player.y - 8;
				shieldCollider.width = player.width + 32;
				shieldCollider.height = player.height + 16;
				--shieldCollider:Debug(true)
				-- flame dash
				if player.keys.jump == KEYS_PRESSED and canShieldAttack and not wasonground and not isFlameDashing then
					SFX.play(monitorsShields.flameShieldDashSFX)
					shieldAnimFrame = 0;
					canShieldAttack = false;
					isFlameDashing = true;
					player:mem(0x50, FIELD_WORD, 0) --spinjump
					inputs2.locked[1].all = true;
					flameStoreSpeed = 14*player:mem(0x106,FIELD_WORD);
					dashTimer = flameData.config.shielddashlength;
					player.speedY = -1;
				end
				
				if isFlameDashing == true then
					player.speedX = flameStoreSpeed;
					shieldLight.brightness = 2;
					
					if dashTimer > -1 then
						dashTimer = dashTimer - 1;
						if dashTimer == 0 then
							isFlameDashing = false;
							shieldLight.brightness = 1;
							flameStoreSpeed = 0;
							dashTimer = -1;
							shieldAnimFrame = 0;
							inputs2.locked[1].all = false;
						end
					end
				end
				
				-- kill enemies with dash
				for _,v in ipairs(colliders.getColliding{a = shieldCollider, b = NPC.HITTABLE, btype = colliders.NPC, filter = shieldFilter}) do
					if isFlameDashing then
						v:harm(HARM_TYPE_EXT_HAMMER);
					end
				end
			end
		end
	end
end

function monitorsShields.shieldDraw()
	if monitorsShields.hasShield then
	
		-- Vanilla shield
		if monitorsShields.shieldType == monitorsShields.blueShield then
			Graphics.drawImageToSceneWP(blueData.config.shieldgfx, player.x + (player.width*0.5) - (blueData.config.shieldwidth*0.5), player.y + (player.height*0.5) - (blueData.config.shieldheight*0.5), 0, math.floor(shieldAnimFrame) * blueData.config.shieldheight, blueData.config.shieldwidth, blueData.config.shieldheight, .5, -25)
		elseif monitorsShields.shieldType == monitorsShields.thunderShield then
			Graphics.drawImageToSceneWP(thunderData.config.shieldgfx, player.x + (player.width*0.5) - (thunderData.config.shieldwidth*0.5), player.y + (player.height*0.5) - (thunderData.config.shieldheight*0.5), 0, math.floor(shieldAnimFrame) * thunderData.config.shieldheight, thunderData.config.shieldwidth, thunderData.config.shieldheight, .75, -25)
		elseif monitorsShields.shieldType == monitorsShields.bubbleShield then
			if isBubbleBouncing then
				Graphics.drawImageToSceneWP(bubbleData.config.shieldbouncegfx, player.x + (player.width*0.5) - (bubbleData.config.shieldbouncewidth*0.5), player.y + (player.height*0.5) - (bubbleData.config.shieldbounceheight*0.5), 0, math.floor(shieldAnimFrame) * bubbleData.config.shieldbounceheight, bubbleData.config.shieldbouncewidth, bubbleData.config.shieldbounceheight, .75, -25)
			else
				Graphics.drawImageToSceneWP(bubbleData.config.shieldgfx, player.x + (player.width*0.5) - (bubbleData.config.shieldwidth*0.5), player.y + (player.height*0.5) - (bubbleData.config.shieldheight*0.5), 0, math.floor(shieldAnimFrame) * bubbleData.config.shieldheight, bubbleData.config.shieldwidth, bubbleData.config.shieldheight, .75, -25)
			end
		elseif monitorsShields.shieldType == monitorsShields.flameShield then
			if isFlameDashing then
				if player:mem(0x106,FIELD_WORD) == -1 then
					Graphics.drawImageToSceneWP(flameData.config.shielddashgfx, player.x + (player.width*0.5) - (flameData.config.shielddashwidth*0.5), player.y + (player.height*0.5) - (flameData.config.shielddashheight*0.5), 0, math.floor(shieldAnimFrame) * flameData.config.shielddashheight, flameData.config.shielddashwidth, flameData.config.shielddashheight, 1, -25)
				else
					Graphics.drawImageToSceneWP(flameData.config.shielddashgfx, player.x + (player.width*0.5) - (flameData.config.shielddashwidth*0.5), player.y + (player.height*0.5) - (flameData.config.shielddashheight*0.5), 0, (flameData.config.shielddashheight *flameData.config.shielddashframes-1) + (math.floor(shieldAnimFrame) * (flameData.config.shielddashheight)), flameData.config.shielddashwidth, flameData.config.shielddashheight, 1, -25)
				end
			else
				Graphics.drawImageToSceneWP(flameData.config.shieldgfx, player.x + (player.width*0.5) - (flameData.config.shieldwidth*0.5), player.y + (player.height*0.5) - (flameData.config.shieldheight*0.5), 0, math.floor(shieldAnimFrame) * flameData.config.shieldheight, flameData.config.shieldwidth, flameData.config.shieldheight, .75, -25)
			end
		end
	end
end

-- shield loss effect accessible remotely
function monitorsShields.loseShield()
	SFX.play(35)
	player.speedX = 4 * -player:mem(0x106,FIELD_WORD);
	player.speedY = -7;
	monitorsShields.hasShield = false;
	monitorsShields.shieldType = 0;
	if(shieldLight ~= nil) then
		shieldLight:destroy();
		shieldLight = nil;
	end
	isBubbleBouncing = false;
	isFlameDashing = false;
	SFX.play(monitorsShields.lossSound)
end

return monitorsShields;