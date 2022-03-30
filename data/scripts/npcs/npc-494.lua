local npcManager = require("npcManager")
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
	value=10
})
npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, {[HARM_TYPE_JUMP]=10, [HARM_TYPE_SPINJUMP]=10, [HARM_TYPE_SWORD]=10});

local offset_lives = 0x00B2C5AC
local offset_coins = 0x00B2C5A8

local function onMonitorCollected(p)
	SFX.play(56)
	Misc.coins(NPC.config[npcID].value)
end

function star.onInitAPI()
	monitors.register(npcID, onMonitorCollected)
end

return star;
