local npcManager = require("npcManager")
local bro = require("npcs/AI/bro")

local boomerangBros = {}

local npcID = NPC_ID

local broSettings = {
	id = npcID,
	gfxheight = 48,
	gfxwidth = 32,
	height = 48,
	width = 32,
	frames = 2,
	framestyle = 1,
	speed = 1,
	score = 5,
	jumphurt = 0,
	gfxoffsety = 2,
	holdoffsetx = 16,
	holdoffsety = 26,
	throwoffsetx = 0,
	throwoffsety = 0,
	walkframes = 100,
	jumpframes = 300,
	jumpspeed = 7,
	throwspeedx = 0,
	throwspeedy = 0,
	initialtimer = 100,
	waitframeslow = 120,
	waitframeshigh = 180,
	holdframes = 30,
	throwid = 615,
	quake = false,
	stunframes = 0,
	quakeintensity = 0,
	followplayer = true
}
npcManager.setNpcSettings(broSettings)

bro.setDefaultHarmTypes(npcID, 262)
bro.register(npcID)

return boomerangBros