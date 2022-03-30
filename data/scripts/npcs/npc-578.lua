local nokobon = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 56,
	width = 32,
	height = 32,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	score = 2,
	cliffturn = true,
	iswalker = true,
	spawnid = 579
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 10,
	[HARM_TYPE_FROMBELOW] = 10,
	[HARM_TYPE_NPC] = 244,
	[HARM_TYPE_HELD] = 244,
	[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = 244,
	[HARM_TYPE_LAVA]={id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function nokobon.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and (reason == 1 or reason == 2 or reason == 7) then
		eventObj.cancelled = true
		npc:transform(NPC.config[npc.id].spawnid)
		if reason == 2 or reason == 7 then
			npc.speedY = -5
		end
		npc.speedX = 0
	end
end

function nokobon.onInitAPI()
	registerEvent(nokobon, "onNPCKill", "onNPCKill")
end

return nokobon
