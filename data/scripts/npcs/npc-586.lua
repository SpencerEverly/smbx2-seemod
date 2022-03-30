local reverseBoo = {}

local npcManager = require("npcManager")

local boo = require("npcs/ai/boo")

-- Defaults --
local npcID = NPC_ID

npcManager.registerHarmTypes(npcID,{HARM_TYPE_NPC},{[HARM_TYPE_NPC]=243})

reverseBoo.config = npcManager.setNpcSettings(
	{id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 2,
	framespeed = -1,
	framestyle = 1,
	nogravity = true,
	jumphurt = true,
	speed = 1,
	nowaterphysics = true,
	spinjumpsafe = true,
	nogravity = true,
	noblockcollision=true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,

	maxspeedx = 1,
	maxspeedy = 1,
	accelx = 0.025,
	accely = 0.025,
	decelx = 0.075,
	decely = 0.075,
})

local function conditionFunction(v)
	local centerX = v.x + 0.5 * v.width
	for k,p in ipairs(Player.get()) do
		if math.sign(p.x + p.width * 0.5 - centerX) ~= p.direction and not p:mem(0x50,FIELD_BOOL) then
			return p
		end
	end
	return false
end

boo.register(npcID, conditionFunction)

return reverseBoo
