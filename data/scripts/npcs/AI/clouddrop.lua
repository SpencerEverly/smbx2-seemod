local npcManager = require("npcManager")
local rng = require("rng")

local cDrop = {}

function cDrop.register(id)
	npcManager.registerEvent(id, cDrop, "onTickEndNPC")
end

local function dropAI(v, cfg)
	local data = v.data._basegame

	local held = v:mem(0x12C, FIELD_WORD)
	local thrown = v:mem(0x136, FIELD_BOOL)
	local frozen = v:mem(0x138, FIELD_WORD)

	if frozen > 0 or held > 0 then 
		data.init = false
		data.held = held
		return
	end

	local x,y = "x", "y"
	local sx,sy = "speedX", "speedY"
	if not cfg.horizontal then
		x,y = y,x
		sx, sy = sy, sx
	end

	if not data.init then
		data.init = true
		data.timer = 0
		if v.direction == 0 then
			v.direction = rng.randomInt(0,1) * 2 - 1
		end

		local offs = {x=0xA8, y=0xB0}
		data.origin = {}
		data.origin[x] = v:mem(offs[x], FIELD_DFLOAT)
		data.origin[y] = v[y]

		if data.held then
			if data.held > 0 then
				local p = player
				v.direction = p.direction
				if not cfg.horizontal then
					v.direction = -1
				end
				data.origin[x] = v[x]
			else
				data.origin[x] = v[x]
			end
		end

		data.direction = v.direction
	end
	
	data.timer = (data.timer + 1) % 189

	local dir = data.direction or v.direction

	if not thrown then
		local layer = v.layerObj
		if layer and not layer:isPaused() then
			data.origin[x] = data.origin[x] + layer[sx]
			data.origin[y] = data.origin[y] + layer[sy]
		end
	else
		data.origin[x] = data.origin[x]
		data.origin[y] = data.origin[y] + v[sy]
	end
	
	local goal = {}

	goal[x] = data.origin[x] + dir * math.sin((data.timer) / 30) * cfg.range
	goal[y] = data.origin[y]

	v[sx] = goal[x] - v[x]
	if not thrown then
		v[sy] = goal[y] - v[y]
	end

	if v.dontMove then
		v[sx] = 0
	end
end

function cDrop.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		data.init = false
		return
	end
	dropAI(v, NPC.config[v.id])

	v.animationTimer = 666

	if not data.init then
		v.animationFrame = 7
	
		if (data.direction or v.direction) == -1 then
			v.animationFrame = (v.animationFrame + 7) % 14
		end
		return
	end

	local animTimer = data.timer - 22

	if animTimer < 0 then
		local t = animTimer
		v.animationFrame = math.floor((t)/8) % 4 + 7
	elseif animTimer < 22 then
		v.animationFrame = math.floor((animTimer)/8) % 3 + 11
	elseif animTimer < 92 then
		local t = animTimer - 22
		v.animationFrame = math.floor(t/8) % 4
	elseif animTimer < 114 then
		local t = animTimer - 92
		v.animationFrame = math.floor((t)/8) % 3 + 4
	else
		local t = animTimer - 114
		v.animationFrame = math.floor((t)/8) % 4 + 7
	end
	
	if (data.direction or v.direction) == -1 then
		v.animationFrame = (v.animationFrame + 7) % 14
	end
end
	
return cDrop