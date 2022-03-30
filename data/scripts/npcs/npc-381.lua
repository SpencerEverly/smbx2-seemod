local npcManager = require("npcManager");
local flyingSpiny = {}
local npcID = NPC_ID

flyingSpiny.spikeConfig = npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx = 8,
	gfxoffsety = 8,
	gfxwidth = 22, 
	gfxheight = 22, 
	width = 6,
	height = 6,
	frames = 8,
	harmlessgrab=true,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	framespeed = 8,
	framestyle = 0,
	nogravity=1,
	noblockcollision=1,
	jumphurt = 1,
	spinjumpsafe = false
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_TAIL}, 
{[HARM_TYPE_TAIL]=74});


local bullet = {}
for i=1, 8 do
	bullet[i] = {}
end
bullet[1].x, bullet[1].y = -1, 0
bullet[2].x, bullet[2].y = 1, 0
bullet[3].x, bullet[3].y = 0, 1
bullet[4].x, bullet[4].y = 0, -1
bullet[5].x, bullet[5].y = -1, -1
bullet[6].x, bullet[6].y = 1, -1
bullet[7].x, bullet[7].y = 1, 1
bullet[8].x, bullet[8].y = -1, 1

function flyingSpiny.onTickSpike(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end
		
	local data = v.data._basegame
	if data.spinyBulletDirection == nil then
		data.spinyBulletDirection = 1
		if v.direction == 1 then data.spinyBulletDirection = 2 end
	end
	local cfg = NPC.config[v.id]
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then return end
	v.speedX, v.speedY = cfg.speed * bullet[data.spinyBulletDirection].x * 2, cfg.speed * bullet[data.spinyBulletDirection].y * 2
	v.animationFrame = data.spinyBulletDirection - 1
	v.animationTimer = 500
end

function flyingSpiny.onInitAPI()
	npcManager.registerEvent(npcID, flyingSpiny, "onTickEndNPC", "onTickSpike")
end 
return flyingSpiny