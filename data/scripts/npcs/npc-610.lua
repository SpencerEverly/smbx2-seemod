local lakitu = {}

local npcManager = require("npcManager")
local klonoa = require("characters/klonoa")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID
klonoa.UngrabableNPCs[npcID] = true

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 48,
	width = 32,
	height = 48,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	score = 5,
	nogravity = true,
	noblockcollision = true,

	delay = 230,
	spawnID = 611,
	idleframes = -1,
	animationlength = 25,
	centeroffset = 0,
	xspmax = 8,
	distaccelfactor = 0.005,
	minaccel = 0.2,
	eggxsp = 2,
	eggysp = 7
})

if config.idleframes == -1 then
	config.idleframes = math.floor(config.frames*0.5)
end

npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD},
	{[HARM_TYPE_JUMP] = 246,
	[HARM_TYPE_FROMBELOW] = 246,
	[HARM_TYPE_NPC] = 246,
	[HARM_TYPE_HELD] = 246,
	[HARM_TYPE_TAIL] = 246,
	[HARM_TYPE_PROJECTILE_USED] = 246
})

local function dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	if data.check == nil then
		data.check = true
		if not settings.override then
			settings.delay = config.delay
		end
		if npc.ai1 ~= 0 then
			data.spawnid = npc.ai1
		else
			data.spawnid = NPC.config[npc.id].spawnid
		end
	end
end

local function closestPlayerX(npc)
	local pMin
	local distMin

	-- Find the closest player to the NPC (only X axis)
	for _, p in ipairs(Player.get()) do
		local dist = (p.x + p.width / 2) - (npc.x + npc.width / 2)
		if not distMin or math.abs(dist) < math.abs(distMin) then
			distMin = dist
			pMin = p
		end
	end

	return pMin, distMin
end

local function sgn(n)
	if n > 0 then
		return 1
	elseif n == 0 then
		return 0
	else
		return -1
	end
end

function lakitu.onInitAPI()
	npcManager.registerEvent(npcID, lakitu, "onTickNPC")
	npcManager.registerEvent(npcID, lakitu, "onDrawNPC")
end

function lakitu.onTickNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x12C, FIELD_WORD) > 0 then return end
  local data = npc.data._basegame
	dataCheck(npc)

	npc.ai4 = npc.ai4 + 1
	local p, d = closestPlayerX(npc)
	d = d + config.centeroffset

	local settings = npc.data._settings

	-- Throw egg
	if npc.ai4 >= settings.delay then
		npc.ai4 = 0
		local egg = NPC.spawn(data.spawnid, npc.x + npc.width/2, npc.y + npc.height/2, npc:mem(0x146, FIELD_WORD))
		egg.x = egg.x - egg.width/2
		egg.y = egg.y - egg.height/2
		egg.speedY = -config.eggysp
		egg.speedX = config.eggxsp*sgn(d)
		egg.friendly = npc.friendly
		egg:mem(0x3C, FIELD_STRING, "Spawned NPCs")
		SFX.play(25)
	end

	local dir = sgn(d)
	local sp = math.min(math.abs(d*config.distaccelfactor), config.minaccel)
	npc.speedX = npc.speedX + sp*dir
	if math.abs(npc.speedX) > config.xspmax then
		npc.speedX = config.xspmax*dir
	end
end

function lakitu.onDrawNPC(npc)
	if not config.nospecialanimation then
		local data = npc.data._basegame
		local settings = npc.data._settings
		local frames = config.idleframes
		local offset = 0
		local gap = config.frames - config.idleframes
		if npc.ai4 >= settings.delay - config.animationlength then
			frames = config.frames - config.idleframes
			offset = config.idleframes
			gap = 0
		end
		npcutils.restoreAnimation(npc)
		npc.animationFrame = npcutils.getFrameByFramestyle(npc, {
			frames = frames,
			offset = offset,
			gap = gap
		})
	end
end

return lakitu
