local npcManager = require("npcManager");
local pwheelAI = require("npcs/ai/paddlewheel")

local paddleWheel = {};

local npcID = NPC_ID

paddleWheel.linkConfig = npcManager.setNpcSettings{
	id=npcID, 
	gfxwidth=32, 
	gfxheight=32, 
	width=32, 
	height=32, 
	frames=1,
	score=0,
	playerblock=false,
	playerblocktop=false,
	ignorethrownnpcs = true,
	npcblock=false,
	npcblocktop=false,
	nogravity=true,
	noblockcollision=true,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	grabside=false,
	isshoe=false,
	isyoshi=false,
	nohurt=true,
	jumphurt=true,
	speed=1,
	notcointransformable = true,
	
	maxrotspeed=0.3,
	resist=0.01,
	linespeedmultiplier = 5,
	platformid = 422,
    autorotate = false
};

pwheelAI.register(npcID)

return paddleWheel