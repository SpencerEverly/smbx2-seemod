local warpTransition = require("warpTransition")

local littleDialogue = require("littleDialogue")
local redtimer = false
local timerMS = 65*11 --Red Coin Timer (11 Seconds)
local audioplayer = true --Used to play a sound clip
RNG = 0
--globalsave = SaveData["episode"]
--local coinCounter = globalsave.starcoin

function onStart() 
	coinLayer = Layer.get("Red") --!!CREATE A LAYER NAMED "Red"
	
	RB = Layer.get("RouletteBlock") --Roulette Blocks
	RB_Empty = Layer.get("RouletteEmpty")
end

function onEvent(eventname)
	if eventname == "RedRing" then
		coinLayer:show(false)
		redtimer = true
	end
	
	if eventname == "RedRing_Empty" then --When you collect all the Red Coins
		local randnum = math.random(100) --Used when there is RNG spawning (EX: 50% chance of spawning fire or ice flwoer)
		Audio.SfxStop(-1)
		if player.powerup == 1 then --If the player is Small Mario, always spawn a Mushroom
			NPC.spawn(9,player.x,player.y,player.section+1)
		end
		if player.powerup==2 then --If the Player is Big Mario, Spawn a Fire or Ice Flower
			if randnum < 50 then --50% chance of spawning a Fire Flower
				NPC.spawn(14,player.x,player.y,player.section+1)
			elseif randnum >= 50 then --50% chance of spawning a Nice Flower
				NPC.spawn(264,player.x,player.y,player.section+1)
			end
		elseif player.powerup==3 or player.powerup==7 then --If the Player is Fire Mario or Ice Mario, Spawn a Leaf
			NPC.spawn(34,player.x,player.y,player.section+1)
		elseif player.powerup==4 or player.powerup==5 or player.powerup==6 then --If the Player is Leaf Mario, Hammer Mario, or Tanookie Mario, Spawn a 1-Up  -- 100% chance of spawning a 1-up, Regardless of the Player's State
			NPC.spawn(90,player.x,player.y,player.section+1)
		end
	end
	
	if eventname=="Roulette" then --The Roulette Script. Randomly gives you a Mushroom/Fireflower/Leaf/Star/Iceflower. Each is a 20% Chance
		RNG = math.random(1,5)
		
		if RNG==1 then
			NPC.spawn(9,player.x,player.y,player.section+1) --Mushroom
		elseif RNG==2 then
			NPC.spawn(14,player.x,player.y,player.section+1) --Fire Flower
		elseif RNG==3 then
			NPC.spawn(264,player.x,player.y,player.section+1) --Ice Flower
		elseif RNG==4 then
			NPC.spawn(34,player.x,player.y,player.section+1) --Leaf
		elseif RNG==5 then
			NPC.spawn(293,player.x,player.y,player.section+1) --Starman
		end
		
		Audio.playSFX(32)
		RB:hide(true)
		RB_Empty:show(true)
	end
end

function onTick()
	if redtimer==true then --Used for the Red Coin Timer System (11 Seconds)
			if audioplayer == true then
				Audio.playSFX("redSwitchTimer.ogg")
				audioplayer = false
			end
		timerMS = timerMS-1
		if timerMS <= 0 then --When you run out of Time
			coinLayer:hide(false)
				redtimer = false
				audioplayer = true
		end
	end
	
	for k,v in pairs (NPC.get(32)) do --Prevents Despawn Below
 
		if v:mem(0x12A, FIELD_WORD) == 1 then
	
			v:mem(0x12A, FIELD_WORD, 180)
		
		end
	end
	
	for k,v in pairs (NPC.get(278)) do
 
		if v:mem(0x12A, FIELD_WORD) == 1 then
	
			v:mem(0x12A, FIELD_WORD, 180)
		
		end
	end
	
	for k,v in pairs (NPC.get(26)) do
 
		if v:mem(0x12A, FIELD_WORD) == 1 then
	
			v:mem(0x12A, FIELD_WORD, 180)
		
		end
	end
end