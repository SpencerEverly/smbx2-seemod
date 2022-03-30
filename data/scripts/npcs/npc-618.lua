local npcManager = require("npcManager")
local bro = require("npcs/AI/bro")

local sledgeBros = {}
local npcID = NPC_ID
local broSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 48,
	height = 64,
	width = 48,
	gfxoffsety = 2,
	frames = 2,
	framestyle = 1,
	speed = 1,
	score = 5,
	holdoffsetx = 32,
	holdoffsety = 20,
	throwoffsetx = 30,
	throwoffsety = 22,
	walkframes = 100,
	jumpframes = 240,
	jumpspeed = 8.3,
	throwspeedx = 3.4,
	throwspeedy = -8,
	waitframeslow = 80,
	waitframeshigh = 120,
	holdframes = 30,
	throwid = 617,
	quake = true,
	quakeintensity = 15,
	stunframes = 130,
	isheavy = 1,
	followplayer = true
}
npcManager.setNpcSettings(broSettings)

bro.setDefaultHarmTypes(npcID, 264)
bro.register(npcID)

return sledgeBros