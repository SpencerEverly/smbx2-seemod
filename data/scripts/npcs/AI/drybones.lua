local rng = require("rng")
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local drybones = {}

local frameMod = {}
local FR_WALK = 1
local FR_SPIKE = 2
local FR_COLLAPSE = 3

local collapseFrames = {}
local walkFrames = {}
local throwFrames = {}

local idMap = {}
local ids = {}

function drybones.register(id)
	npcManager.registerEvent(id, drybones, "onTickEndNPC", "onTickEndThrowsBones")
	table.insert(ids, id)
	idMap[id] = true
end

function drybones.onInitAPI()
	registerEvent(drybones, "onNPCKill", "onNPCKill", false)
	registerEvent(drybones, "onStart", "onStart", false)
end

local STATE_WALK = 1
local STATE_BOPPED = 2
local STATE_THROW = 3

local stateSwitch = {3,1,1}
-- make this configurable in the future
local timerLimit = {260, 380, 60}

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function initialise(v)
	local data = v.data._basegame
	if v.direction == 0 then
		setDir(rng.irandomEntry({-1, 1}), v)
	end

	if v.friendly == false then
		v.speedX = 0;
	else
		v.speedX = 1 * v.direction;
	end
	data.state = STATE_WALK
	data.timer = 65
	data.friendly = v.friendly
	data.direction = v.direction
	data.dontMove = v.dontMove
end

function drybones.onStart()
	for k,v in ipairs(ids) do
		--calculate frame count based on sheet
		local cfg = NPC.config[v]
		local frames = Graphics.sprites.npc[v].img.height / cfg.gfxheight
		frameMod[v] = {(frames - 6) * 0.5,1,2}
		cfg.frames = frames
		collapseFrames[v] = {
			[-1] = frames - 4,
			[0] = 0,
			[1] = frames - 2
		}
		throwFrames[v] = {
			[-1] = frames - 6,
			[0] = 0,
			[1] = frames - 5
		}

		walkFrames[v] = {
			[-1] = 0,
			[0] = 0,
			[1] = (frames - 6) * 0.5
		}
	end
end

function drybones.onTickEndThrowsBones(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		if data.friendly == nil then
			data.friendly = v.friendly
		end
		v.friendly = data.friendly
		data.state = nil;
		return
	end

	if(v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x12E, FIELD_WORD) ~= 0) or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.state = STATE_WALK;
		data.timer = timerLimit[data.state];
	end

	if data.state == nil then
		initialise(v)
	end

	if data.timer > 0 then
		if not data.friendly then
			data.timer = data.timer - 1
		end
	else
		if data.state == STATE_BOPPED then
			utils.faceNearestPlayer(v)
		end
		data.state = stateSwitch[data.state]
		data.timer = timerLimit[data.state]

		--bopped state switch handled in onNPCKill
		if not data.friendly then
			v.friendly = false
			v.dontMove = data.dontMove or false
		end
	end

	if data.state ~= STATE_BOPPED then
		data.direction = v.direction
	end

	if data.state == STATE_WALK then

		if data.timer == math.floor(timerLimit[STATE_WALK] * 0.5) then
			utils.faceNearestPlayer(v)
		end
		if v:mem(0x136, FIELD_BOOL) == false then
			v.speedX = v.direction * 1.25
		end
		v.animationFrame = v.animationFrame % frameMod[v.id][FR_WALK] + walkFrames[v.id][v.direction]

	elseif data.state == STATE_BOPPED then
		v.speedX = 0
		v.animationTimer = 0
		if collapseFrames[v.id] and data.direction and collapseFrames[v.id][data.direction] then
			v.animationFrame = collapseFrames[v.id][data.direction]
		end
		local cfg = NPC.config[v.id]
		if data.timer > cfg.framespeed and data.timer < timerLimit[data.state] - cfg.framespeed then
			v.animationFrame = v.animationFrame + 1
			--butt shake
			if data.timer < cfg.framespeed * 10 then
				if data.timer%4 > 0 and data.timer%4 < 3 then
					v.x = v.x + 2
				else
					v.x = v.x - 2
				end
			end
		end
	else
		v.speedX = 0

		v.animationTimer = 0
		v.animationFrame = throwFrames[v.id][v.direction]
		if data.timer == 1 then
			local bone = NPC.spawn(NPC.config[v.id].spawnid, v.x + 0.5 * v.width, v.y + 0.25 * v.height, v:mem(0x146, FIELD_WORD), false, true)
			bone.friendly = v.friendly
			bone.direction = v.direction
			bone.layerName = "Spawned NPCs"
		end
	end
end

function drybones.onNPCKill(eventObj,v,killReason)
	if not idMap[v.id] then return end

	if not v.data._basegame then v.data._basegame = {} end

	local data = v.data._basegame

	if killReason == 1 or killReason == 8 or killReason == 10 then
		eventObj.cancelled = true;
		SFX.play(57)
		data.state = STATE_BOPPED
		data.timer = timerLimit[data.state] - v.ai2
		v.ai2 = 0
		if not data.friendly then
			v.friendly = true
		end
	end
end

return drybones;