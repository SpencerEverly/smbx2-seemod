local npcManager = require("npcManager")

local shy = {}

local ids = {}
local idMap = {}

function shy.register(id, bonkFunc)
	table.insert(ids, id)
	idMap[id] = bonkFunc
	npcManager.registerEvent(id, shy, "onTickEndNPC")
end

function shy.onInitAPI()
	registerEvent(shy, "onNPCHarm", "onNPCHarm", false)
	registerEvent(shy, "onStart", "onStart", false)
end

local STATE_WALK = 1
local STATE_BOPPED = 2
local STATE_WAKING = 3

local stateSwitch = {2, 3, 1}
local timerLimit = {0, 180, 65}

local walkFrames = {}
local collapseFrame = {}
local wakeFrame = {}
local frameMod = {}
local framespeeds = {}
local frames = {}

local function initialise(v)
	local data = v.data._basegame
	data.state = STATE_WALK
    data.frame = 0
	data.timer = 65
	data.playerEvent = 0
	data.bonkAnimationTimer = 0
end

function shy.onStart()
	--calculate frame count based on sheet
	for k,id in ipairs(ids) do
		local cfg = NPC.config[id]
		frames[id] = Graphics.sprites.npc[id].img.height / cfg.gfxheight
		framespeeds[id] = cfg.frames
		frameMod[id] = {frames[id] * 0.5 - cfg.bonkedframes,1,1}
		cfg.frames = frames[id]
		collapseFrame[id] = {
			[-1] = frames[id] * 0.5 - cfg.bonkedframes,
			[1] = frames[id] - cfg.bonkedframes
		}
		wakeFrame[id] = {
			[-1] = frames[id] * 0.5 - 1,
			[1] = frames[id] - 1
		}
		
		walkFrames[id] = {
			[-1] = 0,
			[1] = frames[id] * 0.5
		}
	end
	
end

function shy.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = nil;
		return
	end
	
	if v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x136, FIELD_BOOL) then
		data.state = STATE_WALK;
		data.timer = timerLimit[data.state];
		data.frame = 0
		data.playerEvent = 0
		v.animationTimer = 99
		data.bonkAnimationTimer = 0
	else
		if data.state == STATE_WALK then
			v.speedX = v.direction * 1.25 * NPC.config[v.id].speed
		else
			v.speedX = 0
		end
	end

	if data.state == nil then
		initialise(v)
	end

	if data.playerEvent > 0 then
		idMap[v.id](Player(data.playerEvent), v)
		data.playerEvent = 0
	end
	
	if data.timer > 0 then
		data.timer = data.timer - 1
	elseif data.state ~= STATE_WALK then
		data.state = stateSwitch[data.state]
        data.timer = timerLimit[data.state]
        if data.state == STATE_WALK then
            v.speedY = -2.4
        end
	end

	if data.state == STATE_WALK then
		if v.animationTimer == 0 then
			data.frame = (data.frame + 1) % frameMod[v.id][data.state]
        end
        v.animationFrame = data.frame + walkFrames[v.id][v.direction]
	elseif data.state == STATE_BOPPED then
		v.animationTimer = 0
		local add = math.ceil(data.bonkAnimationTimer* 0.125)
		
		v.animationFrame = collapseFrame[v.id][v.direction] + add
	else
		v.animationTimer = 0
		v.animationFrame = wakeFrame[v.id][v.direction]
		
		--butt shake
		if data.timer < framespeeds[v.id] * 10 then
			if data.timer%4 > 0 and data.timer%4 < 3 then
				v.x = v.x + 2
			else
				v.x = v.x - 2
			end
		end
	end
	if data.bonkAnimationTimer > 0 then
		data.bonkAnimationTimer = data.bonkAnimationTimer - 0.5
	end
end

function shy.onNPCHarm(eventObj, v, killReason, culprit)
	if not idMap[v.id] then return end
	if killReason ~= HARM_TYPE_JUMP and killReason ~= HARM_TYPE_SPINJUMP and killReason ~= HARM_TYPE_TAIL then return end
	eventObj.cancelled = true
	local data = v.data._basegame
	
	if killReason ~= HARM_TYPE_TAIL then
		if data.state ~= STATE_WALK then
			for k, w in ipairs(Player.get()) do
				if Colliders.speedCollide(w, v) then
					data.playerEvent = k
				end
			end
		else
			Effect.spawn(10, v.x, v.y)
			v.speedY = -2
		end
	else
		Effect.spawn(10, v.x, v.y)
		v.speedY = -4

	end
		
	data.state = STATE_BOPPED
	data.timer = timerLimit[data.state]
	SFX.play(2)
end

return shy;