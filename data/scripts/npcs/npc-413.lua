local npcManager = require("npcManager")
local rng = require("rng")

local reznor = {}

local npcID = NPC_ID

local regularSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 64,
	gfxwidth = 64,
	width = 48,
	height = 48,
	frames = 2,
	framespeed=6,
	framestyle = 1,
	jumphurt = 1,
	nogravity = 0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	cliffturn=0,
	spinjumpsafe = false,
	projectileid = 414,
	turns = true
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
	},
	{
		[HARM_TYPE_NPC]=199,
		[HARM_TYPE_HELD]=199,
		[HARM_TYPE_FROMBELOW]=199
	}
);

npcManager.setNpcSettings(regularSettings)

function reznor.onInitAPI()
	npcManager.registerEvent(npcID, reznor, "onTickNPC", "onTickReznor")
	npcManager.registerEvent(npcID, reznor, "onDrawNPC", "onDrawReznor")
	registerEvent(reznor, "onNPCKill")
end

function reznor.onNPCKill(obj, v, rsn)
	if v.id == npcID and v.legacyBoss then
		local spawnOrb = true
		local section = v:mem(0x146, FIELD_WORD)
		for k,n in ipairs(NPC.get(npcID,section)) do
			if n ~= v and n.legacyBoss then
				spawnOrb = false
				break
			end
		end
		if spawnOrb then
			local orb = NPC.spawn(16, v.x + 0.5 * v.width, v.y + 0.5 * v.height, section, false, true)
			orb:mem(0xA8, FIELD_DFLOAT, 0)
			SFX.play(20)
			orb.speedY = -6
		end
	end
end

function reznor.onDrawReznor(v)
	if Defines.levelFreeze then return end
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then return end
	
	v.animationTimer = 500
	
	local data = v.data._basegame
	
	local dirOffset = v.direction + 1
	
	if v.direction == 0 then
		v.animationFrame = 4
		return
	end
	
	v.animationFrame = dirOffset
	
	if not data.fireTimer then return end
	
	if data.fireTimer > 180 or data.fireTimer < 0 then 
		v.animationFrame = dirOffset + 1
	end
end

function reznor.onTickReznor(v)
	if Defines.levelFreeze then return end
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 then
		return
	end
	
	local data = v.data._basegame
	
	if data.fireTimer == nil then
		data.fireTimer = 0
		data.turnTimer = 0
		data.isTurning = false
	end
	
	if data.isTurning then
		data.turnTimer = data.turnTimer + 1
		if data.turnTimer % 8 == 0 then
			local sx = v.speedX
			v.direction = v.direction + data.isTurning
			data.isTurning = false
			v.speedX = sx
		end
		return
	end

	if NPC.config[v.id].turns then
		data.turnTimer = data.turnTimer + rng.random(1,1.5)
	end

	if v.collidesBlockBottom then
		v.speedX = 0	
	end
	
	if v.friendly then return end
	
	data.fireTimer = data.fireTimer + rng.random(1,1.5)
	
	if data.fireTimer > 240
	and math.abs(v.direction) == 1 then
		local fire = NPC.spawn(NPC.config[v.id].projectileid, v.x + 0.5 * v.width, v.y + 0.5 * v.height, player.section, false, true)
		fire.direction = v.direction
		fire.layerName = "Spawned NPCs"
		data.fireTimer = -40
	end
	
	if data.turnTimer > 60 then
		data.turnTimer = 0
		local chasePlayer = player
		if player2 then
			if rng.randomInt(0,1) == 1 then
				chasePlayer = player2
			end
		end
		if (chasePlayer.x + 0.5 * chasePlayer.width > v.x + 0.5 * v.width and v.direction == -1)
		or (chasePlayer.x + 0.5 * chasePlayer.width < v.x + 0.5 * v.width and v.direction == 1) then
			data.isTurning = -v.direction
			local sx = v.speedX
			v.direction = 0
			v.speedX = sx
		end
	end
end
	
return reznor