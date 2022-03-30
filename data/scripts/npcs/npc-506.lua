local birbs = {}
local npcManager = require("npcManager")
local bib = require("npcs/ai/birb")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth         = 16,
	gfxheight        = 16,
	gfxoffsetx       = 0,
	gfxoffsety       = 0,
	width            = 8,
	height           = 14,
	frames           = 2,
	framespeed       = 6,
	framestyle       = 1,
	score            = 0,
	blocknpctop      = 0,
	blocknpc         = 0,
	playerblocktop   = 0,
	playerblock      = 0,
	nogravity        = 0,
	noblockcollision = 1,
	jumphurt         = 0,
	nofireball       = 1,
	noiceball        = 1,
	noyoshi          = 1,
	grabside         = 0,
	grabtop          = 0,
	isshoe           = 0,
	isyoshi          = 0,
	nohurt           = -1,
	spinjumpsafe     = 0,
	togrounded = npcID - 4
})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA}, {
	[HARM_TYPE_LAVA] = 10
})

bib.register(npcID)

return birbs