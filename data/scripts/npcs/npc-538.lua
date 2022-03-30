local npcManager = require("npcManager")
local starman = require("npcs/ai/starman")
local monitors = require("npcs/ai/monitors")

local star = {}

local npcID = NPC_ID;

local settings = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 56, 
	gfxheight = 64, 
	width = 56, 
	height = 64, 
	frames = 1, 
	framespeed = 8, 
	framestyle = 0, 
	score = 4,
	jumphurt = 0, 
	nowaterphysics = 1, 
	spinjumpsafe = 0, 
	playerblock = true, 
	ignorethrownnpcs = true,
	blocknpc = true, 
	blocknpctop = true, 
	nohurt = 1,
	lightoffsety=-8,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	noiceball=true,
	noyoshi=true,
	duration = 13,
	powerup = true
})
npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

local function onMonitorCollected(p)
	starman.start(p, npcID)
end

function star.onInitAPI()
	starman.register(npcID, true)
	monitors.register(npcID, onMonitorCollected)
end

return star;
