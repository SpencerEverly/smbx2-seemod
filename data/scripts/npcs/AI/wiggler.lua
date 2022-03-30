local rng = require("rng")
local npcManager = require("npcManager");
local wiggler = {};
local npcutils = require("npcs/npcutils")

-- TODO: Implement onNPCIDChange and ice flower mechanics

wiggler.sharedBody = {
	gfxwidth = 36, 
	gfxheight = 36, 
	width = 24,
	height = 24,
	gfxoffsety = 2,
	frames = 4,
	framespeed = 8,
	framestyle = 1,
	jumphurt=0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=0,
	nogravity=0,
	cliffturn=-1,
	score = 0,
	spinjumpsafe = true,

	trailcount=4,
	trailID = 447,
	distance = 16,
	angryID = 448
}


wiggler.sharedTrail = {
	gfxoffsetx = 0,
	gfxoffsety = 2,
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 24,
	height = 24,
	frames = 4,
	framespeed = 8,
	framestyle = 1,
	noblockcollision=-1,
	jumphurt=0,
	nogravity=-1,
	nohurt=0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	score = 0,
	spinjumpsafe = true,

	angryID = 449
}

wiggler.speed = {}
wiggler.headMap = {}
wiggler.trailMap = {}

function wiggler.registerHead(id, config)
	local settings = npcManager.setNpcSettings(table.join(config, wiggler.sharedBody))

	npcManager.registerEvent(id, wiggler, "onTickNPC", "onTickHead")
	npcManager.registerEvent(id, wiggler, "onStartNPC", "initialize")
	npcManager.registerEvent(id, wiggler, "onDrawNPC", "onDrawHead")
	wiggler.speed[id] = NPC.config[id].speed
	wiggler.headMap[id] = true

	NPC.config[id].speed = 1
end

function wiggler.registerTrail(id, config)
	npcManager.setNpcSettings(table.join(config, wiggler.sharedTrail))
	
	npcManager.registerEvent(id, wiggler, "onTickNPC", "onTickBody")
	npcManager.registerEvent(id, wiggler, "onDrawNPC", "onDrawBody")
	wiggler.trailMap[id] = true
end

function wiggler.onInitAPI()	
	registerEvent(wiggler, "onNPCHarm");
end

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function chasePlayers(v)
	local p = Player.getNearest(v.x + 0.5 * v.width, v.y)
	setDir(p.x + 0.5 * p.width > v.x + 0.5 * v.width, v)
	v.data._basegame.chaseTimer = rng.randomInt(45, 85)
end

local function getTrails(v,func)
	local data = v.data._basegame
	if data.trackedData then
		for k,t in ipairs(data.trackedData) do
			if t.isValid then
				func(t)
			end
		end
	end
end

function wiggler.initialize(v)
	if v.data._basegame.trackedData then return end
	
	local data = v.data._basegame
	
	local sec = v:mem(0x146, FIELD_WORD)
	local dir = v:mem(0xD8,FIELD_FLOAT)
	
	if v.direction == 0 then
		v.direction = rng.randomInt(0, 1) * 2 - 1
	end
	
	local cfg = NPC.config[v.id]
	
	data.trackedData = {}
	data.turningAngry = false
	data.chaseTimer = 0
	data.groundTimer = 0 --slopes
	data.distance = cfg.distance
	data.isAngry = cfg.angryID == v.id
	
	for i = 1, cfg.trailcount do
		table.insert(data.trackedData, NPC.spawn(cfg.trailID, v.x, v.y, sec))
		data.trackedData[i]:mem(0xD8, FIELD_FLOAT, dir)
		data.trackedData[i].layerName = v.layerName
		data.trackedData[i].noMoreObjInLayer = v.noMoreObjInLayer
	end
			
	for k, t in ipairs(data.trackedData) do
		t.friendly = v.friendly or (v:mem(0x12C, FIELD_WORD) > 0)
		if t.data._basegame == nil then t.data._basegame = {} end
		t.data._basegame.trackedData = data.trackedData[k-1]
		t.data._basegame.hierarchyPosition = k
		t.data._basegame.head = v
	end
	data.trackedData[1].data._basegame.trackedData = v
end

function wiggler.onDrawBody(v)
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	
	if v.data._basegame == nil then v.data._basegame = {} end
	local data = v.data._basegame
	
	if (data.head and data.head.isValid) then
		npcutils.hideNPC(v)
	elseif v:mem(0xDC, FIELD_WORD) == 0 then
		v:kill(9)
	end
end

function wiggler.onDrawHead(v)
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	
	if v.data._basegame == nil then v.data._basegame = {} end
	local data = v.data._basegame
	if not data.trackedData then return end

	for i = #data.trackedData, 1, -1 do
		local t = data.trackedData[i]
		if t.isValid then
			local tdata = t.data._basegame
			t.animationFrame = (v.animationFrame - tdata.hierarchyPosition)%NPC.config[t.id].frames + NPC.config[t.id].frames * (t.direction + 1) * 0.5
			npcutils.drawNPC(t)
		end
	end
	npcutils.drawNPC(v)

	npcutils.hideNPC(v)
end

local function squared(x)
	return math.min(x * x, math.abs(x)) * math.sign(x)
end

function wiggler.onTickHead(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	
	local onScreenValue = v:mem(0x12A, FIELD_WORD)
	local containVal = v:mem(0x138, FIELD_WORD)
	
	if v.isHidden or onScreenValue <= 0 or containVal > 0 then
		getTrails(v, function(t) t:kill(9) end)
		data.trackedData = nil
		return
	end
	
	if data.trackedData == nil then
		wiggler.initialize(v)
	end

	--horizontal speed
	local collideVal = v:mem(0x136, FIELD_BOOL)
	
	if not collideVal then
		if (not data.turningAngry) and (not v.dontMove) then
			v.speedX = wiggler.speed[v.id] * v.direction
		else
			v.speedX = 0
		end
	end
	
	local grabTimerVal = v:mem(0x12E, FIELD_WORD)
	local grabPlayerVal = v:mem(0x12C, FIELD_WORD)
	local grabVal = v:mem(0x130, FIELD_WORD)
	local grabVal2 = v:mem(0x132, FIELD_WORD)
	
	--update trail
	--update positioning of trail
	local cfg = NPC.config[v.id]

	if not data.turningAngry then
		getTrails(v, function(t)
			local tData = t.data._basegame
			local parent = tData.trackedData
			if parent.isValid then
				local dist = 0.5 * cfg.distance
				local distanceToParent = vector(
						parent.x - t.x,
						parent.y + parent.height - t.y - t.height
				)
				local catchup = math.max(distanceToParent.length-2*dist, 0)
				local spd = squared(catchup) * distanceToParent:normalise()
				if math.abs(spd.x) < 0.3 and math.abs(spd.y) < 0.3 then
					spd = vector(
						(parent.x - dist * parent.direction - t.x) * 0.1,
						(parent.y + parent.height - t.y - t.height) * 0.2
					)
				end
				t.friendly = v.friendly or (grabPlayerVal > 0)
				t.x = t.x + spd.x
				t.y = t.y + spd.y
				t:mem(0x12A, FIELD_WORD, onScreenValue)
				t:mem(0x12E, FIELD_WORD, grabTimerVal)
				t:mem(0x130, FIELD_WORD, grabVal)
				t:mem(0x136, FIELD_BOOL, false)
				t:mem(0x132, FIELD_WORD, grabVal2)
				t:mem(0x138, FIELD_WORD, containVal)
			end
		end)
	else
		--oh i just got hit
		getTrails(v, function(t)
			t.x = t.x + v.speedX
			t.y = t.y + v.speedY
		end)
		v.animationTimer = 0
	end
	
	if data.isAngry then
		--grr im so chasery
		data.chaseTimer = data.chaseTimer - 1
		if data.turningAngry then
			if data.chaseTimer <= 0 then
				data.turningAngry = false
			end
		else
			if data.chaseTimer <= 0 then
				chasePlayers(v)
			end
		end
	elseif data.turningAngry then
		data.chaseTimer = 65
		data.distance = cfg.distance
		data.isAngry = true
		v:transform(cfg.angryID)
		v.speedX = 0
		v.speedY = 0
		v.data._basegame = data
		getTrails(v, function(t)
			local d = t.data._basegame
			t:transform(NPC.config[t.id].angryID)
			t.data._basegame = d
		end)
	end
end

function wiggler.onTickBody(v)
	if Defines.levelFreeze or v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v.data._basegame.trackedData == nil then
		return
	end
	
	local data = v.data._basegame
	
	if data.wigglerPrevX == nil then
		data.wigglerPrevX = v.x
	end
	if v.x < data.wigglerPrevX then
		v.direction = -1
	elseif v.x > data.wigglerPrevX then
		v.direction = 1
	end
	if not data.trackedData.isValid then
		v:kill(9)
		return
	end
	v.friendly = data.trackedData.friendly or data.trackedData:mem(0x12C, FIELD_WORD) > 0
	data.wigglerPrevX = v.x
end

function wiggler.onNPCHarm(event,npc,reason,culprit)
	if not (wiggler.headMap[npc.id] or wiggler.trailMap[npc.id]) then
		return
	end
	if reason == 1 or reason == 8 then
		event.cancelled = true
		
		if culprit.__type == "Player" then
			if reason == 8 then
				Colliders.bounceResponse(culprit, 6)
			end
			SFX.play(9)
		end
		if wiggler.trailMap[npc.id] then
			npc = npc.data._basegame.head
		end
		if not npc or not npc.isValid then
			return
		end
		if npc.data._basegame.isAngry then
			return
		end
		if not npc.data._basegame.trackedData then return end
		if npc.data._basegame.turningAngry then return end
		npc.data._basegame.turningAngry = true
		local flower = Effect.spawn(207, npc.x, npc.y)
		flower.direction = npc.direction
		return
	end

	--[[
	local wt = npc.data._basegame.trackedData
		if culprit and culprit.__type == "NPC" then
			local c = culprit
			if c == npc.data._basegame.head then
				event.cancelled = true
				return
			else
				local tbl = wt
				if type(wt) ~= "table" then
					tbl = c.data._basegame.trackedData
				end

				if tbl then
					for k,n in ipairs(tbl) do
						if n == c or n == npc then
							event.cancelled = true
							return
						end
					end
				end
			end
		end
	]]

	if wiggler.trailMap[npc.id] and reason ~= 9 then
		local v = npc.data._basegame.head
		if v.isValid then
			v:harm(reason)
			getTrails(v, function(t) t:harm(9) end)
		end
	end
end

return wiggler;