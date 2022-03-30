local npcManager = require("npcManager")
local wingedAI = require("npcs/ai/wingeddrybones")

local drybones = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	width = 32,
	height = 64,
	frames = 2,
	gfxoffsety = 2,
	framestyle = 1,
	jumphurt = 0,
	nofireball=1,
	nogravity=-1,
	noyoshi=1,
    transformid = 415,
    effectid = 200,
	recovery = 200
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP] = 160,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});


wingedAI.register(npcID)

return drybones;