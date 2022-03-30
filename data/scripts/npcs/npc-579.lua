local nokobon = {}

local npcManager = require("npcManager")

local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 3,
	framespeed = 4,
	framestyle = 1,
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	noiceball=true,
	nofireball=true,
	warningdelay = 200,
	explosiondelay = 320,
	restingframes = 1,
	nospecialanimation = false
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_LAVA},
	{[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = 10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function nokobon.onTickNPC(npc)
	if Defines.levelFreeze then return end
	if npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x138, FIELD_WORD) > 0 then
		npc.ai1 = 0
		return
	end

	if npc.direction == 0 then
		npc.direction = 1
	end
	if not npc.friendly then
		npc.ai1 = npc.ai1 + 1
	end
	-- Copied from the springs NPC
	if npc.collidesBlockBottom then
		npc.speedX = npc.speedX * 0.5
	end
	if npc.ai1 >= NPC.config[npc.id].explosiondelay then
		npc:kill()
	end
end

function nokobon.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	npc.ai5 = 1
	if not config.nospecialanimation then
		
		local frames = config.restingframes
		local offset = 0
		local gap = config.frames - config.restingframes
		if npc.ai1 >= config.warningdelay then
			frames = config.frames - config.restingframes
			offset = config.restingframes
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

function nokobon.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and npc.ai5 == 1 then
		if reason == 2 or reason == 7 then
			eventObj.cancelled = true
			npc.speedX = 0
			npc.speedY = -5
		elseif reason ~= 9 then
			Explosion.spawn(npc.x + npc.width/2, npc.y + npc.height/2, 2)
			Animation.spawn(244, npc.x, npc.y)
		end
	end
end

function nokobon.onInitAPI()
	npcManager.registerEvent(npcID, nokobon, "onTickNPC")
	npcManager.registerEvent(npcID, nokobon, "onDrawNPC")
	registerEvent(nokobon, "onNPCKill", "onNPCKill")
end

return nokobon
