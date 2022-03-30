local npcManager = require("npcManager")
local cpai = require("npcs/ai/checkpoints")
local cps = require("checkpoints")

local checkpoint = {}

local npcID = NPC_ID

cps.registerNPC(npcID)
cpai.addID(npcID)

local checkpointData = {}

checkpointData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 1,
	score = 0,
	speed = 0,
	isshell=false,
	jumphurt=false,
	noyoshi=true,
	iswaternpc=false,
	iscollectablegoal=false,
	isinteractable=true,
	isvegetable=false,
	playerblocktop=false,
	playerblock=false,
	npcblock=false,
	npcblocktop=false,
	nogravity=true,
	isyoshi=false,
	spinjumpsafe=false,
	nowaterphysics=false,
	noblockcollision=true,
	cliffturn=false,
	nofireball=true,
	noiceball=true,
	nohurt=true,
	isbot=false,
	isvine=false,
	iswalker=false,
	grabtop=false,
	grabside=false,
	isflying=false,
	isshoe=false,
	iscoin=false,
	notcointransformable = true,
	spawnoffsetx=0,
	spawnoffsety=0
})

npcManager.registerHarmTypes(npcID, {}, {})

function checkpoint.onInitAPI()
	registerEvent(checkpoint, "onNPCKill")
	
	npcManager.registerEvent(npcID, checkpoint, "onTickNPC")
	npcManager.registerEvent(npcID, checkpoint, "onStartNPC")
end

checkpoint.onNPCKill = cpai.onNPCKill

--This just ensures the checkpoint isn't visible if the level pauses immediately after starting, by killing and despawning it
function checkpoint.onStartNPC(c)
	if c.data._basegame.checkpoint ~= nil and c.data._basegame.checkpoint.collected then
		c:kill()
		c:mem(0x124, FIELD_BOOL, false)
		c:mem(0x128, FIELD_WORD, 0)
	end
end

function checkpoint.onTickNPC(c)
	if c.data._basegame.checkpoint ~= nil and c.data._basegame.checkpoint.collected then
		c:kill()
	end
	
	cpai.doLayerMove(c)
end

return checkpoint