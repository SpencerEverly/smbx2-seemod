--by Nat The Porcupine--
local rng = require("rng")
local utils = require("npcs/npcutils")
local npcManager = require("npcManager");
local firesnake = {};

local headIDs = {}
local idMap = {}
local tailIDs = {}

function firesnake.registerHead(config)
	idMap[config.id] = true
	headIDs[config.tailid] = headIDs[config.tailid] or {}
	headIDs[config.tailid][config.id] = true
	npcManager.setNpcSettings(config)
	npcManager.registerEvent(config.id, firesnake, "onTickNPC", "onTickHead")
	npcManager.registerEvent(config.id, firesnake, "onDrawNPC", "onDrawHead")
end

function firesnake.registerTail(id)
	npcManager.registerEvent(id, firesnake, "onTickEndNPC", "onTickTail")
	table.insert(tailIDs, id)
end

function firesnake.onInitAPI()
	registerEvent(firesnake, "onNPCKill", "onNPCKill");
	--registerEvent(firesnake, "onTick", "onTick");
end
function firesnake.onDrawHead(v)
	if Defines.levelFreeze or v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then
		return
	end
	
	local cfg = NPC.config[v.id]
	local priority = -45
	if cfg.foreground then
		priority = -15
	end
	
	local gfxW = cfg.gfxwidth
	local gfxH = cfg.gfxheight
	local offX = cfg.gfxoffsetx
	local offY = cfg.gfxoffsety
	
	Graphics.drawImageToSceneWP(Graphics.sprites.npc[v.id].img,
								v.x + 0.5 * v.width - 0.5 * gfxW + offX,
								v.y + v.height - gfxH + offY,
								0,
								gfxH * v.animationFrame,
								gfxW,
								gfxH,
								priority)
end

local trails = {}

--This is never called any more.
local function getTrails(v,func)
    local needsCheck = false
	local cfg = NPC.config[v.id].tailid
    for i = #trails, 1, -1 do
        local t = trails[i]
        if t.isValid and t.id == cfg and not t:mem(0x64, FIELD_BOOL) and t.data._basegame.head == v then
			func(t)
		end
    end
end

--Yikes (this isn't registered any more so we're good)
function firesnake.onTick()
	trails = NPC.get(tailIDs, Section.getActiveIndices())
end

-- onNPCIDChange handling
function firesnake.onTickTail(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
    if data.head and (not data.head.isValid or not headIDs[v.id][data.head.id]) then
		if data.head.isValid then
			data.head.data._basegame.dirty = true
		end
		v:kill(9)
	end
end

function firesnake.onTickHead(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	local onScreenVal = v:mem(0x12A, FIELD_WORD)
	
	if v.isHidden or onScreenVal <= 0 then
		data.fireSnakeTrail = {}
		data.timer = 0
		data.fireTrailHistory = nil
		return
	end
	if data.fireSnakeTrail == nil then
		data.fireSnakeTrail = {}
		data.timer = 0
	end
    
    if data.dirty then
        for i = #data.fireSnakeTrail, 1, -1 do
            if data.fireSnakeTrail[i].isValid then
                data.fireSnakeTrail[i]:kill(9)
				data.fireSnakeTrail[i] = nil
            end
        end
        data.dirty = false
        v.ai2 = v:mem(0xE0, FIELD_WORD)
        data.fireTrailHistory = nil
    end
	
	if data.fireTrailHistory == nil then
		data.fireTrailHistory = {}
		for i=1, 4 * v.ai2 do
			data.fireTrailHistory[i] = {x = v.x + 0.5 * v.width, y = v.y + 0.5 * v.height}
		end
    end
	
    
	local isHeld = v:mem(0x132, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x134, FIELD_WORD) > 0
    if #data.fireSnakeTrail < v.ai2 and v:mem(0x138, FIELD_WORD) == 0 then
        local tid = NPC.config[v.id].tailid
		for i=v.ai2, 1, -1 do
			local s = NPC.spawn(tid, data.fireTrailHistory[i * 4].x, data.fireTrailHistory[i * 4].y, player.section, false, true)
			s.friendly = v.friendly or isHeld
			s.layerName = v.layerName
			s.noMoreObjInLayer = v.noMoreObjInLayer
			data.fireSnakeTrail[i] = s
			s.data._basegame.head = v
		end
	end
	v.speedY = v.speedY + 0.13
	--Artificial Intelligence--
	if v.collidesBlockBottom then
		data.timer = data.timer + 1
		v.speedX = 0
	end
	if data.timer == 14 then
		utils.faceNearestPlayer(v)
	end
	
	--Flags Fire Snake
	if data.timer >= 59 then
		data.fireSnakeJumped = true;
		data.timer = 0
		if rng.randomInt(1,2) == 1 then
			v.speedY = -5;
		else
			v.speedY = -4;
		end
		v.speedX = 1.55 * v.direction
	end
	--Fireball Tail--
	
	--Registers a table that keeps track of the npc's previous coordinates
	for i=#data.fireTrailHistory, 2, -1 do
		data.fireTrailHistory[i].x = data.fireTrailHistory[i - 1].x
		data.fireTrailHistory[i].y = data.fireTrailHistory[i - 1].y
	end
	
	if #data.fireTrailHistory >= 1 then
		data.fireTrailHistory[1].x = v.x + 0.5 * v.width
		data.fireTrailHistory[1].y = v.y + v.height
	end
	
	local k = 1
	
	for _,t in ipairs(data.fireSnakeTrail) do
		if t.isValid then
			if #data.fireTrailHistory > 0 then
				t.x = data.fireTrailHistory[k * 4].x - 0.5 * t.width
				t.y = data.fireTrailHistory[k * 4].y - t.height
			end
			t.friendly = isHeld or v.friendly
			t:mem(0x12A, FIELD_WORD, onScreenVal)
		end
		if k < v.ai2 then
			k = k + 1
		end
	end
	--[[getTrails(v, function(t)
			if #data.fireTrailHistory > 0 then
				t.x = data.fireTrailHistory[k * 4].x - 0.5 * t.width
				t.y = data.fireTrailHistory[k * 4].y - t.height
			end
			t.friendly = isHeld or v.friendly
			t:mem(0x12A, FIELD_WORD, onScreenVal)
			if k < v.ai2 then
				k = k + 1
			end
		end
	)]]
end

function firesnake.onNPCKill(event,v,reason)
	if idMap[v.id] then
		local data = v.data._basegame
		if data.fireSnakeTrail then
			for _,t in ipairs(data.fireSnakeTrail) do
				if t.isValid then
					t:kill(9)
				end
			end
		end
	--[[
		getTrails(v, function(t)
				t:kill(9)
			end
		)
	]]
   end
end

return firesnake;