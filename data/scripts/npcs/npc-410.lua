local npcManager = require("npcManager")
local rng = require("rng")
local cloudAI = require("npcs/ai/minigamecloud")

local minigameCloud = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 0,
	jumphurt = -1,
	nogravity = -1,
	nohurt=-1,
	noblockcollision = -1,
	ignorethrownnpcs = true,
	noyoshi=-1,
	thrown = 10,
	harmlessgrab=true,
	harmlessthrown=true,
	spawnid = 411
})

cloudAI.registerCloud(npcID)

function minigameCloud.onInitAPI()
	npcManager.registerEvent(npcID, minigameCloud, "onTickNPC")
end

local function moveAndSpawn(v, data)
	if data.sineTimer < 70 then
		data.riseTimer = data.riseTimer + 0.085
	elseif data.sineTimer > 120 * (v.ai2 + 1) then
		data.riseTimer = data.riseTimer - 0.065
		if data.sineTimer == 120 * (v.ai2 + 1) + 1 and cloudAI.isRewardValid(v) then
			data.collectedAll = false
			local coin = NPC.spawn(v.ai1, v.x + 0.5 * v.width, v.y, v:mem(0x146, FIELD_WORD), false, true)
			coin.speedY = -4
			coin.friendly = v.friendly
			coin.layerName = "Spawned NPCs"
			SFX.play(7)
		end
	end
	
	v.speedY = math.sin(data.sineTimer * 0.04) * 1.2 + data.riseTimer
	
	if data.sineTimer <= 120 * v.ai2 then
		if data.sineTimer % 120 == 0 then
			local coin = NPC.spawn(NPC.config[v.id].spawnid, v.x + 0.5 * v.width, v.y, v:mem(0x146, FIELD_WORD), false, true)
			coin.speedY = -4
			coin.friendly = v.friendly
			coin.layerName = "Spawned NPCs"
			cloudAI.initCoin(v, coin)
		end
	end
end

function minigameCloud.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.sineTimer = nil
		return
	end
	
	local held = v:mem(0x12C, FIELD_WORD) > 0
	
	if v.ai1 == 0 then
		v.ai1 = 187
	end
	if v.ai2 < 0 then
		v.ai2 = math.max(0, NPC.config[v.id].thrown)
	end
	
	if data.sineTimer == nil then
		data.sineTimer = 0
		data.riseTimer = -6
		data.collected = 0
		if v.ai2 == 0 then
			v.ai2 = math.max(0, NPC.config[v.id].thrown)
		end
		data.collectedAll = v.ai2 == 0
	end
	
	v.speedX = 0.75
	
	data.sineTimer = data.sineTimer + 1
	moveAndSpawn(v, data)
	if held then
		for i=1,7 do
			data.sineTimer = data.sineTimer + 1
			moveAndSpawn(v, data)
			if held and data.sineTimer > 120 * (v.ai2 + 1) then
				v:kill(9)
				Effect.spawn(10, v)
				return
			end
		end
	end
end
	
return minigameCloud
