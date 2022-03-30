local npcManager = require("npcManager")
local shyAI = require("npcs/ai/hatter")

local shy = {}
local npcID = NPC_ID

npcManager.setNpcSettings{
	id = npcID, 
	gfxheight = 48,
	gfxwidth = 32,
	width = 30,
	height = 32,
	gfxoffsety=2,
	score = 0,
	frames = 4,
	framestyle = 1,
	cliffturn=1,
	jumphurt = 0,
	noyoshi=1,
	bonkedframes = 2,
	spinjumpsafe = true
}

npcManager.registerHarmTypes(npcID,
{
	HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_HELD,
	HARM_TYPE_NPC,
	HARM_TYPE_TAIL,
	HARM_TYPE_LAVA,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_SWORD
}, 
{
	[HARM_TYPE_JUMP] = 10,
	[HARM_TYPE_FROMBELOW]=232,
	[HARM_TYPE_HELD]=232,
	[HARM_TYPE_TAIL]=10,
	[HARM_TYPE_NPC]=232,
	[HARM_TYPE_SPINJUMP]=10,
	[HARM_TYPE_PROJECTILE_USED] = 232,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});


local bonkEvent = function(p)
		if p.mount == 0 and not p:mem(0x50, FIELD_BOOL) then
			p:harm()
		end
	end

shyAI.register(npcID, bonkEvent)

return shy;