local rng = require("rng")
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local ptooie = {}

local idMap = {}

function ptooie.register(id)
	npcManager.registerEvent(id, ptooie, "onTickEndNPC", "onTickEndPtooie")
	idMap[id] = true
end

function ptooie.onInitAPI()
	registerEvent(ptooie, "onNPCKill", "onNPCKill", false)
end


function ptooie.onTickEndPtooie(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 then
		data.ballexists = nil
		return
	end
	
    local cfg = NPC.config[v.id]
	if data.ballexists == nil then
		if v:mem(0x12E,FIELD_WORD) == 0 and v:mem(0x136, FIELD_BOOL) == false then
			data.myball = NPC.spawn(NPC.config[v.id].ballid, v.x+0.5 * v.width, v.y, v:mem(0x146, FIELD_WORD), false, true)
			data.myball.layerName = "Spawned NPCs"
			data.myball.friendly = v.friendly
			data.myball.data._basegame = {}
			local d2 = data.myball.data._basegame
			d2.parent=v
			d2.parentexists = true
			data.ballexists = true
		else
			data.ballexists = false 
		end
		data.ballflip=1
		data.fliptimer=0
		data.animtimer = 0
		data.moveback=0 --Walking ptooie
		data.blowing=false
		data.recalc = false
		data.blowheights = {}
        local n = 1
		while cfg["blowheight" .. n] do
			table.insert(data.blowheights, cfg["blowheight" .. n])
			n = n + 1
		end
		data.blowheight = rng.irandomEntry(data.blowheights)
	end
	if cfg.ptooiespeed > 0 then
		if v:mem(0x136, FIELD_BOOL) == false then
			data.moveback = data.moveback - 1
			if data.moveback <= 0 then
				v.direction = -v.direction
				data.moveback = 65 * math.abs(cfg.walktimer)
			end
			v.speedX = v.direction * cfg.ptooiespeed
		end
	else
		v.speedX, v.speedY = utils.getLayerSpeed(v)
	end
	
	if not data.ballexists then
		data.fliptimer = data.fliptimer + 1
		if data.fliptimer == 4 then
			data.blowing = not data.blowing
			data.fliptimer = 0
		end
	else
		if not data.myball.isValid then
			data.ballexists = false
		elseif data.myball.id ~= cfg.ballid then
			data.ballexists = false
		else
			data.fliptimer = data.fliptimer + 1
			if data.fliptimer == 4 then
				data.fliptimer = 0
				data.ballflip = - data.ballflip
			end
			data.myball.x = v.x + v.width/2 - data.myball.width/2 + data.ballflip * 2 + v.speedX
			if (data.myball.y+data.myball.height > v.y-32 and data.myball.speedY > 0) or (data.myball.y+data.myball.height > v.y-data.blowheight and data.myball.speedY < 0) then
				data.myball.speedY = data.myball.speedY - 0.6
				data.blowing = true
				data.recalc = true
			else
				data.blowing = false
            end
            local maxspeed = NPC.config[cfg.ballid].maxspeed
			data.myball.speedY=math.max(math.min(data.myball.speedY,maxspeed),-maxspeed)
			if data.recalc and not data.blowing then
				data.blowheight = rng.irandomEntry(data.blowheights)
				data.recalc = false
			end 
		end
	end 
	v.animationTimer = 9999
	data.animtimer = data.animtimer + 1
	local framestyle = cfg.framestyle
	v.animationFrame = math.floor(data.animtimer/cfg.framespeed)% cfg.frames
	if framestyle > 0  and v.direction == 1 then
		v.animationFrame = v.animationFrame + cfg.frames
	end
	if framestyle == 2 then
		v.animationFrame = v.animationFrame + cfg.frames * 2
	end
	if not data.blowing then
		v.animationFrame = v.animationFrame + cfg.frames
	end
end


function ptooie.onNPCKill(event, npc, reason)
	if idMap[npc.id] then
		local data = npc.data._basegame
		if data.ballexists and data.myball.isValid then
			data.myball.friendly = true 
			data.myball.data._basegame.parentexists=false
		end
	end
end

return ptooie