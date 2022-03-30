local npcManager = require("npcManager")
local rng = require("rng")

local fliprus = {}

local frameMod = {}
local ST_IDLE = 1
local ST_ATK = 2
local ST_FLIP = 3

local idleFrames = {}
local attackFrames = {}
local flipFrames = {}

local timerLimit = {180, 54, 64}

local ids = {}

function fliprus.onStart()
	for k,v in ipairs(ids) do
		--calculate frame count based on sheet
		local cfg = NPC.config[v]
		frames = Graphics.sprites.npc[v].img.height / cfg.gfxheight * 0.5
		frameMod[v] = {cfg.idleFrames, cfg.attackFrames, cfg.flipFrames - 1}
		cfg.frames = frames
		idleFrames[v] = {
			[-1] = 0,
			[1] = frames
		}
		attackFrames[v] = {
			[-1] = frameMod[v][1] - 1,
			[1] = frames + frameMod[v][1] - 1
		}
		
		flipFrames[v] = {
			[-1] = frameMod[v][1] + frameMod[v][2],
			[1] = frames + frameMod[v][1] + frameMod[v][2]
		}
	end
end

function fliprus.register(id)
    npcManager.registerEvent(id, fliprus, "onTickEndNPC", "onTickFliprus")
    table.insert(ids, id)
end

function fliprus.onInitAPI()
	registerEvent(fliprus, "onStart", "onStart", false)
end

function fliprus.onTickFliprus(v)	
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = nil;
		return
	end
	
	if data.state == nil then
		data.state = ST_ATK;
		data.timer = timerLimit[data.state]
		data.randDir = false
		if v.direction == 0 then
			v.direction = rng.randomInt(0,1) * 2 - 1
			data.randDir = true
		end
	end
	
	if v.friendly or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.timer = timerLimit[ST_IDLE]
		data.state = ST_IDLE
	end
	if data.timer > 0 then
		if not v.friendly then
			data.timer = data.timer - 1
		end
	else
		data.state = (data.state % 3) + 1
		data.timer = timerLimit[data.state]
		if data.state == ST_ATK and data.randDir then
			v.direction = rng.randomInt(0,1) * 2 - 1
		end
	end
	
	if data.state == ST_IDLE then
		local f = v.animationFrame - idleFrames[v.id][v.direction]
		v.animationFrame = f % frameMod[v.id][ST_IDLE] + idleFrames[v.id][v.direction]
	elseif data.state == ST_ATK then
		if data.timer == timerLimit[data.state] then
			v.animationFrame = attackFrames[v.id][v.direction]
		end
		
		if v.animationFrame == attackFrames[v.id][v.direction] + frameMod[v.id][ST_ATK] then
			v.animationTimer = 0
		end

		if data.timer == timerLimit[data.state] - 2 * NPC.config[v.id].framespeed then
			data.snowball = NPC.spawn(NPC.config[v.id].spawnid, v.x + 0.5 * v.width, v.y, v:mem(0x146, FIELD_WORD), false, true)
			local snowball = data.snowball
			SFX.play(23)
			snowball.friendly = v.friendly
			snowball.layerName = "Spawned NPCs"
			snowball.data._basegame = {parent = v}
		end
	else
		if data.timer == timerLimit[data.state] then
			v.speedY = -8
			v.animationFrame = flipFrames[v.id][v.direction]
		end
		if v.speedY < -2 or v.animationFrame == flipFrames[v.id][v.direction] + frameMod[v.id][ST_FLIP] then
			v.animationTimer = 0
		end
		if data.snowball and data.snowball.isValid and v.speedY >= 0 then
			data.snowball.data._basegame.parent = nil
            data.snowball.direction = v.direction
            data.snowball.data._basegame.speed = NPC.config[v.id].throwspeedx
			data.snowball.speedY = NPC.config[v.id].throwspeedy
			SFX.play(25)
			data.snowball = false
		end
		if v.speedY >= 0 and v.collidesBlockBottom then
			data.timer = 0
		end
	end
	if math.abs(v.speedX) > 0.1 then
		v.speedX = v.speedX * 0.97
	else
		v.speedX = 0
	end
	
	if not (data.snowball and data.snowball.isValid) then return end
	
	local sb = data.snowball
	sb.speedY = v.speedY - Defines.npc_grav
	sb.x = v.x + 0.5 * v.width - 0.5 * sb.width
	if sb.y > v.y - sb.height - 14 then
		sb.speedY = sb.speedY - 2
	end
end
	
return fliprus