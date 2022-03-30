--moarrinkas 2.0 by enjl (original by aristocrat)

local rng = require("rng")
local colliders = require("colliders")
local vectr = require("vectr")

local moarRinkas = {}

moarRinkas.colors = {}
moarRinkas.colors.REGULAR =		0
moarRinkas.colors.RED = 		1
moarRinkas.colors.YELLOW = 		2
moarRinkas.colors.PURPLE = 		3
moarRinkas.colors.GREEN = 		4
moarRinkas.colors.CYAN = 		5
moarRinkas.colors.PINK = 		6
moarRinkas.colors.BLUE = 		7
moarRinkas.colors.WHITE = 		8
moarRinkas.colors.TURQUOISE = 	9
moarRinkas.colors.ORANGE = 		10
moarRinkas.colors.BLACK = 		11

moarRinkas.codes = {}
moarRinkas.codes[moarRinkas.colors.RED] = 		{red = true, 		multiply = true}
moarRinkas.codes[moarRinkas.colors.YELLOW] = 	{yellow = true, 	wrap = true, 		warp = true}
moarRinkas.codes[moarRinkas.colors.PURPLE] = 	{purple = true, 	rebound = true, 	bounce = true}
moarRinkas.codes[moarRinkas.colors.GREEN] = 	{green = true, 		follow = true, 		homing = true}
moarRinkas.codes[moarRinkas.colors.CYAN] = 		{cyan = true, 		cyber = true, 		glitch = true}
moarRinkas.codes[moarRinkas.colors.PINK] = 		{pink = true, 		slow = true}
moarRinkas.codes[moarRinkas.colors.BLUE] =	 	{blue = true, 		teleport = true}
moarRinkas.codes[moarRinkas.colors.WHITE] = 	{white = true, 		pure = true, 		nice = true, 	horikawaisradicola = true, 	friendly = true}
moarRinkas.codes[moarRinkas.colors.TURQUOISE] =	{turquoise = true,	dizzy = true, 		drunk = true}
moarRinkas.codes[moarRinkas.colors.ORANGE] = 	{orange = true, 	fast = true}
moarRinkas.codes[moarRinkas.colors.BLACK] = 	{black = true, 		kamikaze = true,	bomb = true}

local function customLoad(color)
	return Graphics.loadImage(Misc.multiResolveFile("rinka_" .. color .. ".png", "graphics/tweaks/moarRinkas/rinka_" .. color .. ".png"))
end

local spawnerSprite = customLoad("spawner")
local emptySprite = Graphics.loadImage(Misc.resolveFile("graphics/stock-0.png"))

for k,v in pairs(moarRinkas.colors) do
	moarRinkas[v] = {counter = 0, limit = 50, timer = 200, sprite = customLoad(k)}
end

moarRinkas.dialogue ={	"Boy are you swell",
						"You have nice shoes",
						"I think you smell nice today",
						"Don't sweat the small things",
						"Just live for today. You can do it!",
						"Dayum you sexy!",
						"How do you get your hair to look that great?? :O",
						"You're beautiful no matter what they say",
						"I'm so glad we met.",
						"My life would suck without you. Thanks, You're great.",
						"Playing video games with you would be fun.",
						"You're more fun than bubble wrap.",
						"You're so rad.",
						"I don't speak much English, but with you all I really need to say is beautiful.",
						"Hi, I'd like to know why you're so beautiful.",
						"Are you a Beaver? Cause Dam!",
						"You are the gravy to my mashed potatoes.",
						"You're so fancy, you already know.",
						"You're nicer than a day on the beach.",
						"I appreciate all of your opinions.",
						"You could invent words and people would use them.",
						"Any day spent with you is my favorite day.",
						"You make me think of beautiful things, like strawberries.",
						"You have a good fashion sense.",
						"Do you wanna build a snowman, with me?",
						"Your personality is brighter than the stars.",
						"You are unbelievably pleasant.",
						"You make everyone feel great.",
						"You are very neat.",
						"You tell exceptionally funny jokes."
					}

local function spawnRinka(v)
	if moarRinkas[v.data._moarRinkasType].counter < moarRinkas[v.data._moarRinkasType].limit then
		local newRinka = NPC.spawn(210, v.x + 0.5 * v.width, v.y + 0.5 * v.height, player.section, false, true)
		if v.data._moarRinkasType == moarRinkas.colors.CYAN then
			newRinka.x = newRinka.x + rng.randomInt(-128,128)
			newRinka.y = newRinka.y + rng.randomInt(-128,128)
		end
		newRinka.data._moarRinkasType = v.data._moarRinkasType
		moarRinkas[v.data._moarRinkasType].counter = moarRinkas[v.data._moarRinkasType].counter + 1
		return newRinka
	end
end

local function checkMessage(v)
	for k,codes in pairs(moarRinkas.codes) do
		if codes[v.msg] then
			v.msg = ""
			return k
		end
	end
	return 0
end
	
local function customSpawn()
	for k,v in pairs(NPC.get(211)) do
		if v.data._moarRinkasType == nil then
			v.data._moarRinkasType = checkMessage(v)
			v.data._customTicker = 0
		end
		v.ai1 = 0
		if (not v.layerObj.isHidden) and v:mem(0x12A, FIELD_WORD) > 0 then
			v.data._customTicker = v.data._customTicker + rng.random(1,2)
			if v.data._customTicker >= moarRinkas[v.data._moarRinkasType].timer then
				v.data._customTicker = 0
				spawnRinka(v)
			end
		end
	end
end

moarRinkas[moarRinkas.colors.RED].onTick = function(v)
	if v.data._multCounter == nil then
		v.data._multCounter = 0
	end
	if v.ai1 == 1 then
		v.data._multCounter = (v.data._multCounter + 1) % 120
		if v.data._multCounter == 0 then
			spawnRinka(v)
		end
	end
end

moarRinkas[moarRinkas.colors.YELLOW].onTick = function(v)
	if v.x < camera.x - v.width then
		v.x = v.x + camera.width + v.width
	elseif v.x > camera.x + camera.width then
		v.x = v.x - camera.width - v.width
	end
	if v.y < camera.y - v.height then
		v.y = v.y + camera.height + v.height
	elseif v.y > camera.y + camera.height then
		v.y = v.y - camera.height - v.height
	end
end

moarRinkas[moarRinkas.colors.GREEN].onTick = function(v)
	if v.data._reAimCounter == nil then
		v.data._reAimCounter = 0
	end
	v.data._reAimCounter = (v.data._reAimCounter + 1) % 100
	if v.data._reAimCounter == 0 then
		v.ai1 = 0
	end
end

moarRinkas[moarRinkas.colors.CYAN].onTick = function(v)
	if v.data._cyberShake == nil then
		v.data._cyberShake = 0
	end
	v.data._cyberShake = v.data._cyberShake + 1
	if v.data._cyberShake < 9 then
		v.speedX = 0
		v.speedY = 0
		xspeed = rng.randomInt(-1,1)
		yspeed = rng.randomInt(-1,1)
		v.x = v.x + rng.randomInt(0,10 * xspeed)
		v.y = v.y + rng.randomInt(0,10 * yspeed)
	end
	if v.data._cyberShake == 100 or v.data._cyberShake == rng.randomInt(1,99) then
		v.data._cyberShake = 0
	end
end

moarRinkas[moarRinkas.colors.PURPLE].onTick = function(v) --fuck this shit
	if v.data.prevSpeedX == nil then
		v.data.prevSpeedX = v.speedX
		v.data.prevSpeedY = v.speedY
	end
	if #Block.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) > 0 then
		local dirX = 1
		if v.speedX < 0 then
			dirX = -1
		end
		local dirY = 1
		if v.speedY < 0 then
			dirY = -1
		end
		local targets = Block.getIntersecting(v.x - 0.5 * v.width, v.y - 0.5 * v.height, v.x + 1.5 * v.width, v.y + 1.5 * v.height)
		local _, _, c = colliders.raycast(vectr.v2(v.x + 0.5 * v.width,v.y+0.5*v.height), vectr.down2, targets)
		if not c then
			_, _, c = colliders.raycast(vectr.v2(v.x + 0.5 * v.width,v.y+0.5*v.height), -vectr.down2, targets)
		end
		if not c then
			_, _, c = colliders.raycast(vectr.v2(v.x + 0.5 * v.width,v.y+0.5*v.height), vector.right2, targets)
		end
		if not c then
			_, _, c = colliders.raycast(vectr.v2(v.x + 0.5 * v.width,v.y+0.5*v.height), -vector.right2, targets)
		end
		result = inDirection - 2 * inDirection.project(inNormal) 
	end
	v.data.prevSpeedX = v.speedX
	v.data.prevSpeedY = v.speedY
end

moarRinkas[moarRinkas.colors.PINK].onTick = function(v)
	v.speedX = v.speedX * 0.99
	v.speedY = v.speedY * 0.99
	if v.ai1 == 1 then
		if v.speedX < 0.01 and v.speedX > -0.01 or v.speedY < 0.01 and v.speedY > -0.01 then
			v:kill(9)
		end
	end
end

moarRinkas[moarRinkas.colors.BLUE].onTick = function(v)
	if v.data._blueCounter == nil then
		v.data._blueCounter = 0
	end
	if v.ai1 == 1 then
		v.data._blueCounter = (v.data._blueCounter + 1)%100
		if v.data._blueCounter == 0 then
			local posornegx = rng.randomInt(0,1)
			local posornegy = rng.randomInt(0,1)
			if posornegx == 1 then
				v.x = rng.randomInt(player.x+(player.width/2)+128,camera.x+camera.width-v.width)
			else
				v.x = rng.randomInt(camera.x,player.x+(player.width/2)-128)
			end
			if posornegy == 1 then
				v.y = rng.randomInt(player.y+(player.height/2)+128,camera.y+camera.height-v.height)
			else
				v.y = rng.randomInt(camera.y,player.y+(player.height/2)-128)
			end
			v.ai1 = 0
		end
	end
end

moarRinkas[moarRinkas.colors.WHITE].onTick = function(v)
	if v.msg == "" then
		v.friendly = true
		v.msg = moarRinkas.dialogue[rng.randomInt(1, #moarRinkas.dialogue)]
	end
end

moarRinkas[moarRinkas.colors.TURQUOISE].onTick = function(v)
	if v.ai1 == 1 then
		v.x = v.x + math.sin(v.y/32)
		v.y = v.y + math.cos(v.x/32)
	end
end

moarRinkas[moarRinkas.colors.ORANGE].onTick = function(v)
	v.speedX = v.speedX * 1.01
	v.speedY = v.speedY * 1.01
end

moarRinkas[moarRinkas.colors.BLACK].onTick = function(v)
	if v.ai1 == 1 then
		for i=1, 3 do
			v.data._moarRinkasType = 0
			local newRinka = spawnRinka(v)
			if player.x+player.width/2 > v.x+v.width/2 then
				newRinka.speedX = rng.randomInt(1,3)
			else
				newRinka.speedX = rng.randomInt(-1,-3)
			end
			if player.y+player.height/2 > v.y+v.height/2 then
				newRinka.speedY = rng.randomInt(1,3)
			else
				newRinka.speedY = rng.randomInt(-3,-1)
			end
			newRinka.ai1 = 1
		end
		v:kill(9)
	end
end

moarRinkas[moarRinkas.colors.REGULAR].onTick = function(v)
	--vanilla behaviour
end

function moarRinkas.onInitAPI()
    registerEvent(moarRinkas, "onCameraUpdate", "onCameraUpdate", false)
    registerEvent(moarRinkas, "onTick", "onTick", false)
    registerEvent(moarRinkas, "onStart", "onStart", false)
	registerEvent(moarRinkas, "onNPCKill", "onNPCKill", false)
end

function moarRinkas.onStart()
	Graphics.sprites.npc[210].img = emptySprite
	Graphics.sprites.npc[211].img = emptySprite
end

function moarRinkas.onCameraUpdate()
	for k,v in pairs(NPC.get(211, player.section)) do
		if (not v.layerObj.isHidden) and v:mem(0x12A, FIELD_WORD) > 0 then
			if (v.data._moarRinkasType) then
				Graphics.drawImageToSceneWP(spawnerSprite, v.x, v.y, v.width * v.data._moarRinkasType, v.height * v.animationFrame, 32, 32, -45)
			end
		end
	end
	for k,v in pairs(NPC.get(210, player.section)) do
		if (not v.layerObj.isHidden) and v:mem(0x12A, FIELD_WORD) > 0 then
			if (v.data._moarRinkasType) then
				Graphics.drawImageToSceneWP(moarRinkas[v.data._moarRinkasType].sprite, v.x, v.y, 0, v.height * v.animationFrame, 28, 32, -45)
			end
		end
	end
end

function moarRinkas.onTick()
	customSpawn()
	for k,v in pairs(NPC.get(210, player.section)) do
		if (not v.layerObj.isHidden) and v:mem(0x12A, FIELD_WORD) > 0 then
			if not v.data._moarRinkasType then
				v.data._moarRinkasType = 0
			end
			moarRinkas[v.data._moarRinkasType].onTick(v)
		end
	end
end

function moarRinkas.onNPCKill(butt, killed, reason)
	if killed.id == 210 then
		moarRinkas[killed.data._moarRinkasType].counter = moarRinkas[killed.data._moarRinkasType].counter - 1
	end
end

return moarRinkas