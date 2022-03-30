local npcManager = require("npcManager")

local trigger =  {}

local npcID = NPC_ID

local settings = npcManager.setNpcSettings({
	id = npcID,
	width = 32, 
	height = 32, 
	frames = 0,
	framestyle = 0,
	framespeed = 8,
	score = 2,
	speed = 0,
	playerblock=false,
	playerblocktop=false,
	npcblock=false,
	npcblocktop=false,
	spinjumpsafe=false,
	nowaterphysics=false,
	noblockcollision=true,
	cliffturn=false,
	nogravity = true,
	nofireball=false,
	noiceball=true,
	noyoshi=false,
	iswaternpc=false,
	iscollectablegoal=false,
	isvegetable=false,
	isvine=false,
	isbot=false,
	iswalker=false,
	grabtop = false,
	grabside = false,
	foreground=false,
	isflying=false,
	iscoin=false,
	isshoe=false,
	nohurt = false,
	jumphurt = false,
	isinteractable=true,
	iscoin=false,
	notcointransformable = true
})

return trigger