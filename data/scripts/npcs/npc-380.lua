local npcManager = require("npcManager");
local flyingSpiny = {}
local npcID = NPC_ID
npcManager.setNpcSettings({
	id = npcID,
	gfxoffsety = -2,
	gfxwidth = 48, 
	gfxheight = 40, 
	width = 32,
	height = 32,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	nogravity=1,
	jumphurt=1,
	spinjumpsafe = true,
	spawnid = 381
})
npcManager.registerHarmTypes(npcID, {
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_TAIL,
	HARM_TYPE_SWORD,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_LAVA
}, 
{
	[HARM_TYPE_NPC]=204,
	[HARM_TYPE_HELD]=204,
	[HARM_TYPE_HELD]=204,
	[HARM_TYPE_PROJECTILE_USED]=204,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});

local waves = {{5,8}, {1,4}}

function flyingSpiny.onTickSpiny(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.spinyTimer = 0
		data.spinyPhase = 0
		data.spinyBall = 0
		data.spinySine = 0
		return
	end
	
	if v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.spinyTimer = 0
		data.spinyPhase = 0
		data.spinyBall = 0
		data.spinySine = 0
		return
	end
	
	local data = v.data._basegame
	if data.spinyPhase == nil then
		data.spinyTimer = 0
		data.spinyPhase = 0
		data.spinyBall = 0
		data.spinySine = 0
	end
	v.speedX = v.direction * NPC.config[v.id].speed
	v.speedY = -math.sin(data.spinySine * 0.04) * 0.5
	data.spinySine = data.spinySine + 1
	local cfg = NPC.config[v.id]
	
	if data.spinyTimer > 130 then
		data.spinyBall = 1
	end
	if data.spinyTimer == 210 then
		for i = waves[data.spinyPhase + 1][1], waves[data.spinyPhase + 1][2] do
			local needles = NPC.spawn(cfg.spawnid,v.x + 0.5 * v.width, v.y + 0.5 * v.height,player.section, false, true)
			needles.data._basegame = needles.data._basegame or {}
			local needleData = needles.data._basegame
			needleData.spinyBulletDirection = i
			needles.friendly = v.friendly
			needles.layerName = "Spawned NPCs"
		end
		data.spinyPhase = (data.spinyPhase + 1) % 2
	end
	if data.spinyTimer > 260 then
		data.spinyBall = 0
		data.spinyTimer = 0
	end
	data.spinyTimer = data.spinyTimer + 1
	
	v.animationTimer = 500
	if cfg.framestyle == 1 then
		v.animationFrame = math.floor(data.spinyTimer/cfg.framespeed)%cfg.frames + cfg.frames + (cfg.frames * v.direction)
	elseif cfg.framestyle == 0 then
		v.animationFrame = math.floor(data.spinyTimer/cfg.framespeed)%cfg.frames
	end
	if data.spinyBall == 1 then
		v.animationFrame = v.animationFrame + 2
	end
	local inItem = v:mem(0x138, FIELD_WORD)
	--something ain't right with vanilla here...
	if inItem == 1 or inItem == 3 then v.animationFrame = v.animationFrame + 1
	elseif inItem == 2 then v.animationFrame = v.animationFrame - 2 end
end

function flyingSpiny.onInitAPI()
	npcManager.registerEvent(npcID, flyingSpiny, "onTickEndNPC", "onTickSpiny")
end 
return flyingSpiny