local npcManager = require("npcManager")
local rng = require("rng")

local torpedoTeds = {}

local npcID = NPC_ID


local tedSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 64,
	width = 64,
	height = 32,
	framestyle = 1,
	frames = 2,
	jumphurt = 1,
	nogravity = 1,
	noblockcollision = 1,
	nofireball=1,
	noiceball=0,
	noyoshi=1,
	spinjumpsafe = true,
	leftspeed = 3,
	framespeed = 4,
	rightspeed = 3,
	acceleration = 1.035,
	deceleration = 0.975,
	nowaterphysics = -1,
	luahandlesspeed=true
}

npcManager.registerHarmTypes(npcID, 
	{HARM_TYPE_FROMBELOW, HARM_TYPE_HELD,HARM_TYPE_NPC}, 
	{[HARM_TYPE_FROMBELOW]=164,
	[HARM_TYPE_HELD]=164,
	[HARM_TYPE_NPC]=164
});

npcManager.setNpcSettings(tedSettings)

function torpedoTeds.onTickEndTed(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		data.tedDirection = nil
		return
	end
	
	if data.tedDirection == nil then
		data.tedDirection = v.direction
		if v.direction == 0 then
			data.tedDirection = rng.randomInt(1)
			if data.tedDirection == 0 then data.tedDirection = -1 end
		end
		local cfg = NPC.config[v.id]
		data.frame = 0
		data.frameStyle = cfg.framestyle
		data.animationTimer = 0
		data.frameSpeed = cfg.framespeed
	end
	local heldPlayer = v:mem(0x12C, FIELD_WORD)
	if heldPlayer > 0 then
		data.tedDirection = Player(heldPlayer).direction
	elseif heldPlayer == 0 then
		v.animationFrame = 500
		v.animationTimer = 500
		local cfg = NPC.config[v.id]
		if v.speedX == 0 then
			v.speedX = 0.1 * data.tedDirection * NPC.config[npcID].speed
		else
			v.speedX = v.speedX * cfg.acceleration
		end
		
		v.speedX = math.clamp(v.speedX, -cfg.leftspeed, cfg.rightspeed) * NPC.config[npcID].speed
		
		v.speedY = v.speedY * cfg.deceleration
		data.animationTimer = data.animationTimer + 1/data.frameSpeed
		data.frame = math.floor(data.animationTimer)%cfg.frames
		
		if data.animationTimer%2==0 and (not v.dontMove) and ((v.speedX > 0.5) or (v.speedX < -0.5)) then
			local a = Effect.spawn(10, v.x + 0.5 * v.width - 0.5 * v.width * data.tedDirection, v.y + 0.5 * v.height)
			a.x = a.x - 0.5 * a.width
			a.y = a.y - 0.5 * a.height
			a.speedX = -data.tedDirection
			a.animationFrame = 2
		end
		local f = 0
		if data.frameStyle == 1 and v.direction == 1 then
			f = cfg.frames
		end
		v.animationFrame = data.frame + f
	end
end

function torpedoTeds.onInitAPI()
	npcManager.registerEvent(npcID, torpedoTeds, "onTickEndNPC", "onTickEndTed")
end
	
return torpedoTeds
