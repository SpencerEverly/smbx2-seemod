local spiny = {}
local npcManager = require("npcManager")

local npcID = NPC_ID
spiny.config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 0,
	framespeed = 8,
	jumphurt = true,
	spinjumpsafe = true,
	transformid = 612
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA},
	{[HARM_TYPE_FROMBELOW] = 247,
	[HARM_TYPE_NPC] = 247,
	[HARM_TYPE_HELD] = 247,
	[HARM_TYPE_TAIL] = 247,
	[HARM_TYPE_PROJECTILE_USED] = 247,
	[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
})

function spiny.onTickNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x12C, FIELD_WORD) ~= 0 then return end
	if npc.collidesBlockBottom then
		local p = Player.getNearest(npc.x + 0.5 * npc.width, npc.y)
		if p.x < npc.x then
			npc.direction = -1
		else
			npc.direction = 1
		end
		local tid = npc.ai1
		if npc.ai1 == 0 then
			tid = NPC.config[npc.id].transformid
		end
		npc:transform(tid)
	end
end

function spiny.onInitAPI()
	npcManager.registerEvent(npcID, spiny, "onTickNPC")
end

return spiny
