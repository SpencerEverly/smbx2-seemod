local npcManager = require("npcManager")
local rng = require("rng")

local fishbone = {}

local npcID = NPC_ID

local fishSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 30,
	gfxwidth = 48,
	width = 28,
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = -1,
	nogravity = -1,
	noblockcollision = -1,
	nofireball=-1,
	noiceball=0,
	noyoshi=0,
	nowaterphysics = -1,
	spinjumpsafe = true
}

npcManager.registerHarmTypes(npcID, {
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_SWORD,
	HARM_TYPE_PROJECTILE_USED
}, 
{
	[HARM_TYPE_NPC]=196,
	[HARM_TYPE_PROJECTILE_USED]=196,
	[HARM_TYPE_HELD]=196
});

npcManager.setNpcSettings(fishSettings)

function fishbone.onInitAPI()
	npcManager.registerEvent(npcID, fishbone, "onTickNPC")
	npcManager.registerEvent(npcID, fishbone, "onDrawNPC")
end

function fishbone.onDrawNPC(v)
	if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data._basegame
	
	v.animationfishboneTimer = 500
	if data.fishboneFrame then
		v.animationFrame = data.fishboneFrame
		if data.fishboneBlink > 0 then
			v.animationFrame = v.animationFrame + NPC.config[v.id].frames
		end
	end
end

function fishbone.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0  then
		data.fishboneBlink = 0
		data.fishboneTimer = 0
		return
	end
	
	if data.fishboneBlink == nil or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 then
		data.fishboneBlink = 0
		data.fishboneTimer = 0
		data.fishboneFrame = 0
		data.baseSpeedX = math.min(math.abs(v.speedX), 3)
		v.speedX = data.baseSpeedX * v.direction
	end
	
	if v.speedX == 0 then
		v.speedX = 0.4 * v.direction
		data.baseSpeedX = 0.4
	end
	
	if rng.randomInt(1,200) == 1 and data.fishboneBlink <= 0 then
		data.fishboneBlink = 4
	end
	
	local dirOffset = 0
	if v.direction == 1 then
		dirOffset = NPC.config[v.id].frames * 2
	end
	
	if data.fishboneTimer >= 0 and data.fishboneTimer <= 48 then
		v.speedX = v.speedX * 1.04
		data.fishboneFrame = math.floor(v.speedX * 8)%NPC.config[v.id].frames + dirOffset
	elseif data.fishboneTimer < 96 then
		v.speedX = v.speedX * 0.97
		data.fishboneFrame = dirOffset
	end
	
	if data.fishboneTimer > 132 then
		data.fishboneTimer = 0
		v.speedX = data.baseSpeedX * v.direction
	end
	
	data.fishboneBlink = data.fishboneBlink - 1
	data.fishboneTimer = data.fishboneTimer + 1
end
	
return fishbone
