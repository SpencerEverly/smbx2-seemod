---------------------------------------Created by Enjl - 2018----------------------------------------
---------------------- -------Library for customizable effect configs--------------------------------
----------------------------------------For Super Mario Bros X---------------------------------------
------------------------------------------------v0.1-------------------------------------------------

local rng = require("rng")
local bettereffects

local cfg = {}

--onInit function presets for when npcs spawn
cfg.onInit = {}
--onTick function presets for various over-time behaviour
cfg.onTick = {}
--onDeath function presets for managing conditional death
cfg.onDeath = {}
--add default behaviours here for easy importing with the import argument
cfg.defaults = {}

--local functions

local function legacyBoss(v)
	if v.npcID ~= 0 then
		local npc = NPC.spawn(v.npcID, v.parent.x + 0.5 * v.parent.width, v.parent.y + 0.5 * v.parent.height, player.section, false,  true)
		npc.speedY = -6
		if npc.id == 16 then
			npc:mem(0xA8, FIELD_DFLOAT, 0)
		end
	end
end

local function syncFrame(v)
	v.animationTimer = 0
	v.animationFrame = mem(mem(0xb2bf30, FIELD_DWORD) + 2 * 3, FIELD_WORD)
end

--place onTick presets here

local EGG_colOffsetTable = {
	[96] = 0,
	[98] = 3,
	[99] = 5,
	[100] = 7,
	[148] = 9,
	[149] = 11,
	[150] = 13,
	[228] = 15,
}

function cfg.onTick.TICK_EGG(v)
	if v.timer >= v.lifetime - v.framespeed * 2 then
		if EGG_colOffsetTable[v.npcID] then
			if v.timer > v.lifetime - v.framespeed then
				v.animationFrame = EGG_colOffsetTable[v.npcID]
			else
				v.animationFrame = EGG_colOffsetTable[v.npcID] + 1
			end
		elseif v.npcID == 0 then
			v.timer = v.lifetime - v.framespeed * 2
			v.animationFrame = 2
			Animation.spawn(364, v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		end
	else
		if v.animationFrame ~= 2 then
			Animation.spawn(364, v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		end
		v.animationFrame = 2
		v.animationTimer = 0
	end
end

function cfg.onTick.TICK_WIGGLE(v)
	v.speedX = math.sin(v.timer * 0.5) * 2
end

function cfg.onTick.TICK_STARCOIN(v)
	if v.timer == 40 then
		v.speedY = -4
		v.gravity = 0.2
	end
end

function cfg.onTick.TICK_TURNBLOCK(v)
	syncFrame(v)
	if v.timer == 1 then
		local p = Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)
		if #p > 0 then
			v.timer = 2
		end
	end
end

function cfg.onTick.TICK_SLEEP(v)
	-- pop it stop it
	if v.animationFrame ~= 3 then
		v.x = v.x + (.125 * v.direction)
		v.speedX = math.sin(v.timer * 0.25) * -v.direction -- wave + going slowly right
	else
		v.speedX = 0;
		v.speedY = 0;
	end

	-- animate
	if v.timer == 120 or v.timer == 60 or v.timer == 10 then
		v.animationFrame = v.animationFrame + 1;
	end
end

--for score
function cfg.onTick.TICK_SLOWDOWN(v)
	v.speedY = v.speedY * 0.97
end

--for sb3 bomb
function cfg.onTick.TICK_BOMB_SMB3(v)
	if v.timer % 6 == 0 then
		local e = Effect.spawn(71, v, math.floor(v.timer / 6)%4)
	end
end

--for doors
function cfg.onTick.TICK_PINGPONG(v)
	if v.animationFrame > -1 then
		v.timer = 2

		if not v.reversed then
			if v.reversed == false and v.animationFrame == 0 and v.animationTimer == 1 then
				v.reversed = true
				v.animationTimer = -4
				v.animationFrame = v.frames - 1
			end
			if v.reversed == nil then v.reversed = false end
		else
			if v.animationTimer == 1 then
				v.animationFrame = v.animationFrame - 2
			end
		end
	else
		v.timer = 0
	end
end

--for effects that only play once
function cfg.onTick.TICK_SINGLE(v)
	if v.animationFrame == 0 then
		if v.timer == 1 then
			v:kill()
		end
	else
		v.timer = 2
	end
end

function cfg.onTick.TICK_DOUBLESPEED(v)
	v.x = v.x + v.speedX
	v.y = v.y + v.speedY
end

function cfg.onTick.TICK_WATERBUBBLE(v)
	v.y = v.y - 2
	if v.npcID == 0 then
		v.timer = 1
		
		for _,l in ipairs(Liquid.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if not l.isHidden then
				v.timer = 0
				break
			end
		end
	end
end

function cfg.onTick.TICK_WATERSPLASH(v)
	v.animationTimer = 0
	if v.timer % 3 == 0 then
		v.animationFrame = v.frames
	else
		v.animationFrame = (math.floor((v.lifetime - v.timer)/v.framespeed)) % v.frames
	end
	if v.animationFrame == v.frames - 1 and v.timer % 3 ~= 2 then
		v.timer = 0
	end
end

function cfg.onTick.TICK_MOTHER(v)
	if v.timer % 5 == 0 then
		Effect.spawn(108, v.x + rng.random(0, v.width), v.y + rng.random(0, v.height))
	end
end

function cfg.onTick.TICK_SINGLE_DOUBLESPEED(v)
	cfg.onTick.TICK_SINGLE(v)
	v.x = v.x + v.speedX
end

function cfg.onTick.TICK_SLIDEPUFF(v)
	cfg.onTick.TICK_SINGLE(v)
	v.y = v.y - 0.1
end

function cfg.onTick.TICK_FIREBALL(v)
	cfg.onTick.TICK_SINGLE(v)
	v.x = v.x + rng.random(-1, 1)
	v.y = v.y + rng.random(-1, 1)
end

function cfg.onTick.TICK_PEACHBOMB(v)
	cfg.onTick.TICK_SINGLE(v)
	if rng.randomInt(1, 5) == 1 then
		local n = Effect.spawn(77, v, 3)
		n.x = n.x + 0.5 * v.width
		n.y = n.y + 0.5 * v.height
		n.speedX = rng.random(-1.5, 1.5)
		n.speedY = rng.random(-1.5, 1.5)
	end
end

function cfg.onTick.TICK_ARC(v)
	v.speedX = v.speedX * 0.99
end

function cfg.onTick.TICK_LARRY(v)
	if v.timer <= v.lifetime - 60 then
		if v.timer == v.lifetime - 60 then
			SFX.play(63)
		end
		v.speedY = -8
	end
end

function cfg.onTick.TICK_BLAARG(v)
	if v.timer > 80 then
		v.speedY = -2.8
	elseif v.timer > 70 then
		v.speedY = 0.5
	elseif v.timer > 30 then
		v.speedY = 0
	else
		v.speedY = 2
	end
end

function cfg.onTick.TICK_RESERVESPARK(v)
	if v.timer == v.lifetime - 1 then
		v.speedY = -12
	end
	v.speedY = v.speedY + 0.4
	cfg.onTick.TICK_SINGLE(v)
end

local coin_frame = {
	2,2,1,1,0,0
}
coin_frame[0] = 2
function cfg.onTick.TICK_COIN(v)
	if v.timer > 6 then
		v.speedY = v.speedY + 0.4
		if v.animationFrame == 4 then
			v.animationFrame = 0
		end
	else
		v.animationFrame = 4 + coin_frame[v.timer]
		v.speedY = -v.timer % 2
	end
end

local chuckFrame = {
	1,1,1,2,2,
	3,2,2,2,2,
	4,5,4,5,4,
	5,4,5,4,5,
	2,2,2,2,2
};
function cfg.onTick.TICK_CHUCK(v)
	if v.parent.ref.isValid then
		
		-- setup variable
		if (v.hurtIncrement == nil) then
			v.hurtIncrement = 0;
			v.pid = v.parent.ref.id
		end
		
		-- animation time
		if (v.timer <= 75 and v.timer % 3 == 0) then
			v.hurtIncrement = v.hurtIncrement + 1;
			
			v.animationFrame = chuckFrame[v.hurtIncrement] or 0;
		end
		if v.pid ~= v.parent.ref.id then
			v.isHidden = true
		end
	else
		v.isHidden = true
	end
end

function cfg.onTick.TICK_CRASHSWITCH(v)
	v.speedY = -v.timer/100
	
	if v.timer < 40 then
		if v.timer%8 < 4 then
			v.frameOffset = -1
		else
			v.frameOffset = 0
		end
	end
end

--place onDeath presets here

function cfg.onDeath.DEATH_TURNBLOCK(v)
	if v.npcID > 0 then
		local b = Block(v.npcID)
		b.isHidden = false
	end
end

local scoreTable = {
	10, 100, 200, 400, 800, 1000, 2000, 4000, 8000
}
local livesTable = {
	1, 2, 3, 5
}

--local coin_variant = 1

function cfg.onDeath.DEATH_COIN(v)
	local coin_variant = v.variant

	if (not coin_variant) or coin_variant <= 0 then return end -- Weeeeird bug can happen without this?
	
	if coin_variant <= 9 then
		local score = mem(0x00B2C8E4, FIELD_DWORD)
		mem(0x00B2C8E4, FIELD_DWORD, score + scoreTable[coin_variant])
	else
		SFX.play(15)
		local lives = mem(0x00B2C8E4, FIELD_DWORD)
		mem(0x00B2C5AC, FIELD_DWORD, lives + livesTable[coin_variant - 9])
	end
	Effect.spawn(79, v, coin_variant)
	
	-- Below is logic for setting coin score 
	-- This isn't compatible with how 1.3 treats the end of effect 11.
	--[[
	coin_variant = coin_variant + 1
	if coin_variant > 13 then
		coin_variant = 10
	end]]
end

function cfg.onDeath.DEATH_EGG(v)
	if EGG_colOffsetTable[v.npcID] or v.npcID == 95 then
		local n = Effect.spawn(58, v.x, v.y)
		n.npcID = v.npcID
	elseif v.npcID ~= nil and v.npcID ~= 0 then
		NPC.spawn(v.npcID, v.x, v.y, player.section)
	end
end

function cfg.onDeath.DEATH_SMOKE(v)
	Effect.spawn(10, v.x, v.y)
end

function cfg.onDeath.DEATH_SHELL(v)
	Effect.spawn(133, v.x, v.y)
end

function cfg.onDeath.DEATH_SPAWNNPCID(v)
	if v.npcID ~= 0 then
		local npc = NPC.spawn(v.npcID, v.parent.x + 0.5 * v.parent.width, v.parent.y + 0.5 * v.parent.height, player.section, false,  true)
	end
end

function cfg.onDeath.DEATH_LEGACYBOSS(v)
	legacyBoss(v)
	SFX.play(20)
end

--init functions

function cfg.onInit.INIT_LEGACYBOSS(v)
	bettereffects.onInit(v)
	legacyBoss(v)
end

function cfg.onInit.INIT_SETDIR(v)
	bettereffects.onInit(v)
	v.direction = 1
	if v.speedX > 0 then
		v.direction = -1
	end
	
end

function cfg.onInit.INIT_EMPTY(v)
end

function cfg.onInit.INIT_VARFRAME(v)
	v.animationFrame = math.max(0, 4 - v.variant)
end

local YOSHI_colOffsetTable = {
	[96] = 0,
	[98] = 1,
	[99] = 2,
	[100] = 3,
	[148] = 4,
	[149] = 5,
	[150] = 6,
	[228] = 7
}

function cfg.onInit.INIT_BABYYOSHI(v)
	bettereffects.onInit(v)
	v.variant = YOSHI_colOffsetTable[v.npcID] or 0
	SFX.play(48)
end

function cfg.onInit.INIT_GLASSSHARDS(v)
	bettereffects.onInit(v)
	v.variant = rng.randomInt(0,v.variants - 1)
end

--simulates 1-indexing for variants
function cfg.onInit.INIT_1INDEXED(v)
	bettereffects.onInit(v)
	v.variant = math.max(v.variant - 1, 0)
end

--i need this now

function cfg.onInitAPI()
	bettereffects = require("game/bettereffects")
	registerEvent(cfg, "onTickEnd", "baseTick")
end

function cfg.baseTick()
	coin_variant = 1
end

--place defaults here

--drops lol
cfg.defaults.AI_DROP = {
	lifetime = 500,
	gravity = 0.5,
	maxSpeedY=10
}

--stomped
cfg.defaults.AI_STOMPED = {
	lifetime = 20,
	--sound=2
}
--for effects that only play once
cfg.defaults.AI_SINGLE = {
	onTick = "TICK_SINGLE",
	xAlign=0,
	yAlign=0,
	lifetime = 100
}
--for effects that only play once but for some reason don't follow speedY rules
cfg.defaults.AI_SLIDEPUFF = {
	onTick = "TICK_SLIDEPUFF",
	xAlign=0,
	yAlign=0,
	lifetime = 20
}
--for effects that only play once but have twice the speed
cfg.defaults.AI_SINGLE_DOUBLESPEED = {
	onTick = "TICK_SINGLE_DOUBLESPEED",
	xAlign=0,
	yAlign=0,
	lifetime = 65
}

--door
cfg.defaults.AI_DOOR = {
	lifetime = 120,
	onTick = "TICK_PINGPONG",
	frames=5,
	sound=46
}

--player death
cfg.defaults.AI_PLAYER = {
	lifetime = 180,
	speedY = -11,
	gravity=0.25,
	sound=8
}

--performs an arc similar to most items when knocked
cfg.defaults.AI_ARC = {
	onTick = "TICK_ARC",
	lifetime = 500,
	speedX = {-3, 3},
	speedY = -10,
	gravity = 0.5,
	maxSpeedY=10
}

--executes the yoshi egg ai as closely as possible (wip)
cfg.defaults.AI_EGG = {
	lifetime = 31,
	framespeed = 10,
	onTick = "TICK_EGG",
	onDeath = "DEATH_EGG",
	img = 56
}

--spinjump does some weird stuff
cfg.defaults.AI_SPINJUMP = {
	lifetime = 16,
	xAlign=0,
	yAlign=0,
	onTick = "TICK_DOUBLESPEED",
}

--wiggler piece ai
cfg.defaults.AI_WIGGLE = {
	lifetime = 500,
	onTick = "TICK_WIGGLE",
	speedY = -8,
	gravity=0.25
}

--starcoin bounce
cfg.defaults.AI_STARCOIN = {
	frames = 4,
	lifetime = 70,
	framespeed = 3,
	framestyle = 0,
	onTick = "TICK_STARCOIN"
}

--coin effect
cfg.defaults.AI_COIN = {
	frames = 7,
	lifetime = 45,
	framespeed = 3,
	onTick = "TICK_COIN",
	onDeath= "DEATH_COIN",
	speedY=-8
}

--rip van fish ZZZs
cfg.defaults.AI_SLEEP = {
	lifetime = 150,
	framespeed = 0,
	onTick = "TICK_SLEEP",
	speedX = {-.25, .25},
	speedY = -.4
}

--fireballs
cfg.defaults.AI_FIREBALL = {
	framespeed = 4,
	onTick = "TICK_FIREBALL",
	onInit = "INIT_1INDEXED",
	frames=3,
	variants=5
}

--iceballs
cfg.defaults.AI_ICEBALL = {
	framespeed = 4,
	onTick = "TICK_FIREBALL",
	frames=3
}

--baby binch
cfg.defaults.AI_BABYYOSHI = {
	framespeed = 10,
	onInit = "INIT_BABYYOSHI",
	onDeath = "DEATH_SPAWNNPCID",
	frames=2,
	variants=8
}

--turb block
cfg.defaults.AI_TURNBLOCK = {
	onTick = "TICK_TURNBLOCK",
	onDeath = "DEATH_TURNBLOCK",
	frames=4,
	lifetime=300,
	onInit = "INIT_EMPTY"
}

--yknow
cfg.defaults.AI_PEACHBOMB = {
	onTick = "TICK_PEACHBOMB",
	frames=4,
	framespeed=3
}

--yknow
cfg.defaults.AI_LARRY = {
	onTick = "TICK_LARRY",
	frames=8,
	framespeed=4,
	lifetime=200
}

--yknow
cfg.defaults.AI_MOTHER = {
	onTick = "TICK_MOTHER",
	framestyle=1,
	lifetime=300
}

--yknow
cfg.defaults.AI_BOMB_SMB3 = {
	onTick="TICK_BOMB_SMB3",
	lifetime=42
}

--yknow
cfg.defaults.AI_WATERBUBBLE = {
	onTick="TICK_WATERBUBBLE",
	lifetime=100,
	frames=2,
	framespeed=3
}

--yknow
cfg.defaults.AI_WATERSPLASH = {
	onTick="TICK_WATERSPLASH",
	lifetime=1000,
	frames=5,
	framespeed=8
}

--yknow
cfg.defaults.AI_RESERVESPARK = {
	onTick="TICK_RESERVESPARK",
	lifetime=100,
	frames=10,
	framespeed=4,
	xAlign=0,
	yAlign=0,
}

--yknow
cfg.defaults.AI_CRASHSWITCH = {
	onTick = "TICK_CRASHSWITCH",
	lifetime=100
	
}

return cfg
