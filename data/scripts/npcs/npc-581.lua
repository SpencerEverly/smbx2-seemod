local bunbun = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 14,
	gfxheight = 32,
	width = 8,
	height = 32,
	frames = 1,
	ignorethrownnpcs = true,
	framespeed = 8,
	framestyle = 0,
	jumphurt = true,
	score = 1,
	nofireball=true,
	noiceball=true,
	noblockcollision = true
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_NPC, HARM_TYPE_LAVA, HARM_TYPE_SWORD},
	{[HARM_TYPE_NPC] = 10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function bunbun.onTickNPC(npc)
	if Defines.levelFreeze then return end
	npc.speedY = 2.5
end

function bunbun.onInitAPI()
	npcManager.registerEvent(npcID, bunbun, "onTickNPC")
end

return bunbun
