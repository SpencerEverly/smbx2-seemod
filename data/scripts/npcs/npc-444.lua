local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local boohemothAI = require("npcs/ai/boohemoth")
local npcutils = require("npcs/npcutils")

local boohemoth = {}

local npcID = NPC_ID

boohemoth.settings = npcManager.setNpcSettings({
	id = 444,

	--Vanilla settings
	gfxwidth = 640,
	gfxheight = 580,
	width = 640,
	height = 580,
	nogravity = true,
	frames = 3,
	framestyle = 1,
	noblockcollision = true,
	speed = 1,
	jumphurt = true,
	nohurt = true,
	noiceball = true,
	nowaterphysics = true,
	noyoshi = true,

    --Custom settings (specific to Boohemoths)
    spawnerID = 636,
	luacontrolsspeed=true,      --Base movement speed of NPC along its axis of travel
	shufflespeedmultiplier=0.7, --Base movement speed of NPC when shuffling
	shytime=2,        --Amount of time (in seconds) the NPC hides before peeking
	peektime=2,       --Amount of time (in seconds) the NPC peeks at the player before moving
	bouncestrength=6, --Speed at which the player bounces back
	debug=0           --Whether to display the hitbox and maybe some text
})

boohemothAI.register(npcID)
boohemothAI.setProperties(npcID)

return boohemoth;