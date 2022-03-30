local snakeBlock =  {}

local npcManager = require("npcManager")
local sblock = require("npcs/ai/snakeblock")

local npcID = NPC_ID

npcManager.setNpcSettings{
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	nogravity = true, 
	frames = 1,
	noblockcollision = true,
	playerblock = true, 
	playerblocktop = true, 
	npcblock = true, --WHY IN TARNATION DOES THIS NOT WORK
	npcblocktop = true,
	speed = 1,
	foreground = false,
	jumphurt = true,
	nohurt = true,
	score = 0,
	noyoshi=true,
	noiceball=true,
	nowaterphysics=true,
	notcointransformable = true,
	staticdirection = true,
	luahandlesspeed = true,
	--Settings below this line are custom-made for level creators to use in their thingies
	altdiagonalmovement=false,
	basespeed=1.5, --A speed value that can have a default other than 1, so that the actual `speed` one is 
	debug=0,
	soundid = 74
}

sblock.register(npcID)

return snakeBlock