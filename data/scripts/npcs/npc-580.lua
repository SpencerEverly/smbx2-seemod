local bunbun = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 40,
	gfxheight = 38,
	width = 28,
	height = 26,
	gfxoffsety=6,
	frames = 5,
	framespeed = 8,
	framestyle = 1,
	score = 1,
	nogravity = true,

	delay = 80,
	spawnid = 581,
	idleframes = 2,
	nospecialanimation = false,
	npcspawndelay = 16
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 245,
	[HARM_TYPE_FROMBELOW] = 245,
	[HARM_TYPE_NPC] = 245,
	[HARM_TYPE_HELD] = 245,
	[HARM_TYPE_TAIL] = 245,
	[HARM_TYPE_PROJECTILE_USED] = 245,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

local function dataCheck(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	if data.check == nil then
		data.check = true
		if not settings.override then
			settings.delay = config.delay
		end
		data.spawnid = npc.ai1
		if data.spawnid == 0 then
			data.spawnid = config.spawnid
		end
	end
end

function bunbun.onTickNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x12C, FIELD_WORD) ~= 0 or npc:mem(0x136, FIELD_BOOL) or npc:mem(0x138, FIELD_WORD) > 0 then return end
	local data = npc.data._basegame
	local settings = npc.data._settings
	dataCheck(npc)
	npc.ai4 = npc.ai4 + 1

	if npc.ai4 >= settings.delay then
		npc.speedX = 0
		if npc.ai4 == settings.delay + config.npcspawndelay then
			local spear = NPC.spawn(data.spawnid, npc.x + npc.width/2, npc.y + npc.height/2, npc:mem(0x146, FIELD_WORD))
			spear.x = spear.x - spear.width/2
			spear.friendly = npc.friendly
			SFX.play(25)
			spear.layerName = "Spawned NPCs"
		elseif npc.ai4 >= settings.delay + (config.frames - config.idleframes)*config.framespeed then
			npc.ai4 = 0
		end
	else
		npc.speedX = 2*npc.direction
	end
end

function bunbun.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 or config.nospecialanimation then return end
	local data = npc.data._basegame
	local settings = npc.data._settings

	local frames = config.idleframes
	local offset = 0
	local gap = config.frames - config.idleframes
	if npc.ai4 >= settings.delay then
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

function bunbun.onInitAPI()
	npcManager.registerEvent(npcID, bunbun, "onTickNPC")
	npcManager.registerEvent(npcID, bunbun, "onDrawNPC")
end

return bunbun
