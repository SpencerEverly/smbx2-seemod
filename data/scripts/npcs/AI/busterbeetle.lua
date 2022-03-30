local rng = require("rng")
local npcManager = require("npcManager")

local beetle =  {}

local idMap = {}

function beetle.register(id)
    npcManager.registerEvent(id, beetle, "onTickEndNPC")
    idMap[id] = true
end

function beetle.onInitAPI()
	registerEvent(beetle, "onNPCKill")
end

function beetle.onNPCKill(obj, v, rsn)
	if idMap[v.id] then
		local data = v.data._basegame
		if data.heldNPC and data.heldNPC.isValid then
			data.heldNPC.friendly = false
			data.heldNPC:mem(0x138, FIELD_WORD, 0)
			data.heldNPC:mem(0x12C, FIELD_WORD, 0)
		end
	end
end

local ST_WALKING = 0
local ST_PICKUP = 1
local ST_THROW = 2

local function coinHandle(v)
	v.ai1 = 1
end

local specialIDHandlers = {
	[10] = coinHandle,
	[33] = coinHandle,
	[45] = coinHandle,
	[88] = coinHandle,
	[103] = coinHandle,
	[138] = coinHandle,
	[152] = coinHandle,
	[251] = coinHandle,
	[252] = coinHandle,
	[253] = coinHandle,
	[258] = coinHandle,
}

function beetle.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
		data.state = nil;
		return
	end

	local cfg = NPC.config[v.id]
	
	if data.state == nil then
		data.state = ST_WALKING;
		data.timer = 0
		data.heldNPC = nil
		data.targets = {}

		-- In case we get multiple npcs to pick up in the future
		local n = 1
		while cfg["target" .. n] do
			table.insert(data.targets, cfg["target" .. n])
			n = n + 1
		end

		if v.direction == 0 then
			v.direction = rng.randomInt(0,1) * 2 - 1
		end
	end
	if data.collider == nil then
		data.collider = Colliders.Box(0,0,2 * cfg.range + v.width,1)
	end
	
	data.collider.x = v.x - cfg.range
	data.collider.y = v.y + v.height + cfg.collideryoffset
	if data.state == ST_WALKING then
		v.speedX = v.direction * 1.2
		
		local collidingGrass = Colliders.getColliding{a=data.collider, b=data.targets, btype=Colliders.NPC}
		for _,g in ipairs(collidingGrass) do
			data.heldNPC = g
			data.state = ST_PICKUP
			SFX.play(73)
			data.timer = 0
            data.heldNPC.friendly = true
			if cfg.useai1 then
				if data.heldNPC.ai1 > 0 then
					data.heldNPC:transform(data.heldNPC.ai1)
				else
					data.heldNPC:kill()
				end
			end
			data.heldNPC.direction = v.direction
			break
		end
	else
		v.speedX = 0
		data.timer = data.timer + 1
		v.animationTimer = 500
		if data.heldNPC and data.heldNPC.isValid then
			if data.state == ST_PICKUP then
				v.animationFrame = cfg.frames * 2 + 1 + v.direction
				data.heldNPC.x = v.x + 0.5 * v.width - 0.5 * data.heldNPC.width + v.direction * 0.5 * data.heldNPC.width * math.cos(data.timer * 0.1)
                data.heldNPC.y = v.y + 0.5 * v.height - 2 - 0.5 * data.heldNPC.height - (0.5 * v.height + 0.5 * data.heldNPC.height) * math.sin(data.timer * 0.1)
                data.heldNPC.speedY = 0
                data.heldNPC:mem(0x12C, FIELD_WORD, -1)
				if data.timer == 8 then
					data.state = ST_THROW
					data.heldNPC.x = v.x + 0.5 * v.width - 0.5 * data.heldNPC.width
					data.heldNPC.y = v.y - data.heldNPC.height - 2
                    data.heldNPC.friendly = false
					data.timer = 0
					data.heldNPC:mem(0x12C, FIELD_WORD, 0)
					if specialIDHandlers[data.heldNPC.id] then
						specialIDHandlers[data.heldNPC.id](data.heldNPC)
					end
				end
			else
				data.heldNPC:mem(0x138, FIELD_WORD, 5)
				if data.heldNPC:mem(0x12C, FIELD_WORD) > 0 then
					data.heldNPC:mem(0x138, FIELD_WORD, 0)
					data.heldNPC:mem(0x12E, FIELD_WORD, 0)
					data.heldNPC:mem(0x132, FIELD_WORD, 0)
					data.heldNPC:mem(0x136, FIELD_BOOL, false)
					data.heldNPC = nil
					data.timer = 0
					data.state = ST_WALKING
				else
					data.heldNPC:mem(0x12C, FIELD_WORD, 0)
					v.animationFrame = cfg.frames * 2 + 2 + v.direction
					if data.timer >= 16 and not v.friendly then
						data.state = ST_WALKING
						data.heldNPC:mem(0x12E, FIELD_WORD, 30)
						data.heldNPC:mem(0x132, FIELD_WORD, -1)
						data.heldNPC:mem(0x136, FIELD_BOOL, true)
						data.heldNPC.speedX = cfg.throwspeedx * v.direction
						data.heldNPC.speedY = cfg.throwspeedy
						data.timer = 0
					end
				end
			end
		else
			if data.state == ST_THROW then
				if data.timer >= 16 then
					data.state = ST_WALKING
				end
				v.animationFrame = NPC.config[v.id].frames * 2 + 2 + v.direction
			else
				if data.timer >= 8 then
					data.state = ST_THROW
				end
				v.animationFrame = NPC.config[v.id].frames * 2 + 1 + v.direction
			end
			data.heldNPC = nil
		end
	end
end

return beetle