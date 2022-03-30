local npcManager = require("npcManager")
local dryAI = require("npcs/ai/drybones")

local drybones = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 64,
	gfxwidth = 48,
	width = 32,
	height = 64,
	gfxoffsety=2,
	frames = 10,
	framestyle = 0,
	cliffturn=0,
	jumphurt = 0,
	nofireball=1,
	noyoshi=1,
	spawnid = 416
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_HELD,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP] = 160,
		[HARM_TYPE_FROMBELOW] = 200,
		[HARM_TYPE_PROJECTILE_USED] = 200,
		[HARM_TYPE_TAIL] = 200,
		[HARM_TYPE_HELD] = 200,
		[HARM_TYPE_NPC] = 200,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}});

dryAI.register(npcID)

return drybones;