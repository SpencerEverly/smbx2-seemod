local npcManager = require("npcManager")
local cpai = require("npcs/ai/checkpoints")
local cps = require("checkpoints")

local checkpoint = {}

local npcID = NPC_ID

cps.registerNPC(npcID)
cpai.addID(npcID, true)

local flagData = {}

flagData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 64, 
	width = 64, 
	height = 64, 
	frames = 3,
	framespeed=8,
	score = 0,
	speed = 0,
	playerblock=false,
	npcblock=false,
	nogravity = true,
	noblockcollision = true,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	grabside = false,
	isshoe=false,
	isyoshi=false,
	nohurt=true,
	iscoin=false,
	isinteractable=true,
	jumphurt=true,
	spinjumpsafe=false,
	notcointransformable = true,
	spawnoffsetx=-24,
	spawnoffsety=0
})

npcManager.registerHarmTypes(npcID, {}, {})

function checkpoint.onInitAPI()
	registerEvent(checkpoint, "onNPCKill")
	
	npcManager.registerEvent(npcID, checkpoint, "onTickNPC")
	npcManager.registerEvent(npcID, checkpoint, "onDrawNPC")
	npcManager.registerEvent(npcID, checkpoint, "onStartNPC")
end

checkpoint.onNPCKill = cpai.onNPCKill

--Set up the state of a flag checkpoint as necessary
local function initState(c)
	if c.data._basegame.state == nil then
		if c.friendly then
			c.data._basegame.state = 2
		else
			c.data._basegame.state = 0
		end
		c.data._basegame.frame = 0
	end
end

--Update the flags state based on collection state
local function updateState(c)
	if c.data._basegame.checkpoint ~= nil and c.data._basegame.checkpoint.collected then
		--Set the state of flag checkpoints
		if c.data._basegame.state == 0 then
			--Force collect a checkpoint if its state is 0 and it's collected (this means it's already been collected at level start)
			c.data._basegame.state = 2
			
		elseif c.data._basegame.state == 2 and cpai.getActiveID() ~= c.data._basegame.checkpoint.id then
			--Uncollect other flags
			c.data._basegame.checkpoint:reset()
			c.data._basegame.state = 1
			c.data._basegame.frame = 0
		end
	end
end

--This just ensures the checkpoint state is correct if the level pauses immediately after starting
function checkpoint.onStartNPC(c)
	initState(c)
	updateState(c)
end

function checkpoint.onTickNPC(c)
	--If a flag checkpoint hasn't been set up (this only happens if it's spawned after level start), set its state up
	if c.data._basegame.checkpoint == nil and c.data._basegame.frame == nil then
		c.data._basegame.state = 2
		c.data._basegame.frame = 0
	end
	
	updateState(c)
	
	cpai.doLayerMove(c)
	
	--Animation and state
	
	--Initialise the state if necessary
	initState(c)
			
	--Set up animation timer
	if c.data._basegame.animationTimer == nil then
		c.data._basegame.animationTimer = flagData.config.framespeed
	end
		
	c.animationTimer = 0
			
	if c.data._basegame.animationTimer <= 0 then
		--Advance frame if animation timer is 0, and reset timer
		c.data._basegame.frame = c.data._basegame.frame + 1
		c.data._basegame.animationTimer = flagData.config.framespeed
		
		--Reset frames if we reach the end of an animation
		if c.data._basegame.frame >= flagData.config.frames then
			c.data._basegame.frame = 0
			
			--If the flag state is 1 (transitioning state), update the state
			if c.data._basegame.state == 1 then
				
				if c.data._basegame.checkpoint.collected then
					c.data._basegame.state = 2
				else
					c.data._basegame.state = 0
				end
				
			end
		end
	end
	
	--Update animation timers (transition animation plays at double speed
	if c.data._basegame.state == 1 then
		c.data._basegame.animationTimer = c.data._basegame.animationTimer - 2
	else
		c.data._basegame.animationTimer = c.data._basegame.animationTimer - 1
	end
end

function checkpoint.onDrawNPC(c)
	--Initialise the state if necessary
	initState(c)
	
	--Set the NPC animation frame based on the frame and state data
	c.animationFrame = c.data._basegame.state * flagData.config.frames + c.data._basegame.frame
end

return checkpoint