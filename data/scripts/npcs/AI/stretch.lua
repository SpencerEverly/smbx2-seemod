local npcManager = require("npcManager")
local rng = require("rng")

local stretch = {}

local tableinsert = table.insert

stretch.TYPE = {
    ["FLOOR"] = 1,
    ["CEILING"] = 2,
    ["LEFTWALL"] = 3,
    ["RIGHTWALL"] = 4,
}

local ids = {}

function stretch.register(id, t)
    if t == nil or t <= 0 or t > 4 then
        error("Must provide valid stretch t. Types are stretch.TYPE.FLOOR/CEILING/LEFTWALL/RIGHTWALL.")
        return
    end

    ids[id] = t
	npcManager.registerEvent(id, stretch, "onTickEndNPC")
	npcManager.registerEvent(id, stretch, "onTickNPC")
end

-- let's be ambiguous about variables

local rightsideTerminology = {
    x = "x",
    y = "y",
    speedX = "speedX",
    speedY = "speedY",
    width = "width",
    height = "height",
}

local wallTerminology = {
    x = "y",
    y = "x",
    speedX = "speedY",
    speedY = "speedX",
    width = "height",
    height = "width",
}

local terms = {
    [stretch.TYPE.FLOOR] = rightsideTerminology,
    [stretch.TYPE.CEILING] = rightsideTerminology,
    [stretch.TYPE.LEFTWALL] = wallTerminology,
    [stretch.TYPE.RIGHTWALL] = wallTerminology,
}

local upSide = {
    [stretch.TYPE.FLOOR] = 1,
    [stretch.TYPE.CEILING] = -1,
    [stretch.TYPE.LEFTWALL] = -1,
    [stretch.TYPE.RIGHTWALL] = 1,
}

local function getDistanceX(k,p)
	return k.x - p.x, k.x < p.x
end

local function getDistanceY(k,p)
	return k.y - p.y, k.y < p.y
end

local getDistance = {
    [stretch.TYPE.FLOOR] = getDistanceX,
    [stretch.TYPE.CEILING] = getDistanceX,
    [stretch.TYPE.LEFTWALL] = getDistanceY,
    [stretch.TYPE.RIGHTWALL] = getDistanceY,
}

--blacklist functions

local function blckDefaultMap(v, npc)
	return Block.SOLID_MAP[v.id] or Block.HURT_MAP[v.id] or Block.SEMISOLID_MAP[v.id] or Block.PLAYER_MAP[v.id]
end

local function blckBlockSemisolid(v, npc)
	return not Block.SEMISOLID_MAP[v.id]
end

local function blckBlockTopLim(v, npc, t)
	return v[terms[t]["y"]] == npc[terms[t]["y"]] + npc[terms[t]["height"]]
end

local function blckBlockBotLim(v, npc, t)
	return v[terms[t]["y"]] + v[terms[t]["height"]] == npc[terms[t]["y"]]
end

local baseBlacklists = {
	[-1] = {
		blckDefaultMap,
		blckBlockBotLim
	},
	[1] = {
		blckDefaultMap,
		blckBlockTopLim
	}
}

local function filterLayers(v, boo)
	return (not boo.data._settings.layerfilter) or boo.layerName == "Spawned NPCs" or (v.layerName ~= "Spawned NPCs" and v.layerName == boo.layerName)
end

local function makeIntersectingNPCAndBlockMap(npc, x1, y1, width, height, blockBlacklist)
	local entries = {}
	for k,v in ipairs(Block.getIntersecting(x1, y1, x1 + width, y1 + height)) do
		if filterLayers(v, npc) and not ((not v.layerObj or v.layerObj.isHidden) or v:mem(0x5A, FIELD_WORD) ~= 0) then
			local cancel = false
			for _, n in ipairs(blockBlacklist) do
				if not n(v, npc, ids[npc.id]) then
					cancel = true
					break
				end
			end
			if not cancel then
				tableinsert(entries, v)
			end
		end
	end
	for k,v in ipairs(NPC.getIntersecting(x1, y1, x1 + width, y1 + height)) do 
		if filterLayers(v, npc) and not (NPC.config[v.id].playerblocktop == false or v.isHidden or v == npc or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x64, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0) then
			tableinsert(entries, v)
		end
	end
	return entries
end

local function fastIntersecting(tbl, x,y,x2,y2)
	local t = {}
	for k,v in ipairs(tbl) do
		if v.x + v.width >= x
		and v.x <= x2
		and v.y + v.height >= y
		and v.y < y2 then
			tableinsert(t, v)
		end
	end
	return t
end

local valueSelectionFunctions = {
	[1] = function(v, t) return v[terms[t]["x"]] end,
	[-1] = function(v, t) return v[terms[t]["x"]] + v[terms[t]["width"]] end
}

local valueComparisonFunctions = {
	[1] = function(a, b) return a > b end,
	[-1] = function (a, b) return a < b end
}

local function checkFloorTiles(input, limit, step, dir, blocks, compareFunc, valueFunc, filter, t)
	if compareFunc(limit, input[terms[t]["x"]]) then return limit end

	local x1 = input[terms[t]["x"]]
	local x2 = x1 + step
	local y1 = input[terms[t]["y"]]
	local y2 = y1 + 4 * dir
	if x2 < x1 then
		x1, x2 = x2, x1
	end
	if y2 < y1 then
		y1, y2 = y2, y1
    end
    if terms[t]["x"] == "y" then
        x1, y1, x2, y2 = y1, x1, y2, x2
    end
	local b = fastIntersecting(blocks, x1, y1, x2, y2)
	local biggestX = input[terms[t]["x"]]
	for k,v in ipairs(b) do
		if not filter[v] then
			if compareFunc(biggestX, valueFunc(v, t)) then
				biggestX = valueFunc(v, t)
			end
		end
	end
    if input[terms[t]["x"]] ~= biggestX then
        input[terms[t]["x"]] = biggestX
		return checkFloorTiles(input, limit, step, dir, blocks, compareFunc, valueFunc, filter, t)
	end

	if compareFunc(limit, biggestX) then
		return limit
	end

	return biggestX
end

local function freeSpaceCheck(input, step, max, blocklist, rightside, dimensions, t)
	local x1 = input[terms[t]["x"]]
	local x2 = x1 + max * step
	local xmax = x2
	if x1 > x2 then
		x2, x1 = x1, x2
	end
	local y1 = input[terms[t]["y"]] - rightside * dimensions.y + 1
    local y2 = y1 + dimensions.y - 2
    local isc = vector(x1,y1,x2,y2)
	local checkFilter = {}
	local b = fastIntersecting(blocklist, isc.x, isc.y, isc.z, isc.w)
	if #b > 0 then
		local takeval
		for k,v in ipairs(b) do
			if ((v.__type == "Block" and not Block.SEMISOLID_MAP[v.id]) or v.__type == "NPC") and (takeval == nil or valueComparisonFunctions[step](takeval, valueSelectionFunctions[-step](v, t))) then
				takeval = valueSelectionFunctions[step](v, t)
			elseif (v.__type == "Block" and Block.SEMISOLID_MAP[v.id]) then
				checkFilter[v] = true
			end
		end
		if takeval then
			xmax = takeval
		end
	end

	y1 = input[terms[t]["y"]] - ((rightside + 1) % 2) * dimensions.y + 1
	y2 = y1 + dimensions.y - 2


	if step < 0 then
		x1 = xmax
	else
		x2 = xmax
    end

    local isc = vector(x1,y1,x2,y2)
	local b = fastIntersecting(blocklist, isc.x, isc.y, isc.z, isc.w)
	if #b > 0 then
		local tmpx2 = checkFloorTiles(vector(input.x, isc.y), xmax, step * dimensions.x, rightside * 2 - 1, b, valueComparisonFunctions[-step], valueSelectionFunctions[-step], checkFilter, t)
		if valueComparisonFunctions[step](xmax, tmpx2) then
			xmax = tmpx2
		end
	end

	return xmax
end

local function setFrame(start, speed, modulo, timer, forward)
	return start + forward * math.floor(timer/speed)%modulo
end

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function chasePlayers(v, t)
	if player2 then
		local p1, dir1 = getDistance[t](v, player)
		local p2, dir2 = getDistance[t](v, player2)
		if p1 > p2 then
			setDir(dir2, v)
		else
			setDir(dir1, v)
		end
	else
		local p1, dir1 = getDistance[t](v, player)
		setDir(dir1, v)
	end
end

local function commonAI(v, vDir, t)
	local data = v.data._basegame
	local settings = v.data._settings
	
	local cfg = NPC.config[v.id]

	local framespeed = cfg.framespeed
	local stretchframes = cfg.stretchframes
	local frames = cfg.frames - stretchframes
	
	if not data.friendly then
		data.timer = data.timer + 1
	else
		data.timer = (data.timer + 1) % (framespeed * frames)
	end
		
	if data.state == 0 then
		if not data.friendly then
			v.friendly = false
		end
		if not v.dontMove then
			v[terms[t]["speedX"]] = v[terms[t]["speedX"]] + 2 * v.direction
		end
		
		-- teleportation
		if data.timer > settings.walktimerlimit then
			v.friendly = true
			local layer = v.layerObj
			if layer and not layer:isPaused() then
				v[terms[t]["speedX"]] = layer[terms[t]["speedX"]]
			else
				v[terms[t]["speedX"]] = 0
			end
			if data.timer > settings.walktimerlimit + stretchframes * framespeed - 1 then
				data.timer = 0
				data.state = 1
			end
		end
	else
		if data.timer == 2 * framespeed then
			if not settings.reappear then
				v:kill(9)
			else
				data.rayCol[terms[t]["x"]] = v[terms[t]["x"]]
				data.rayCol[terms[t]["y"]] = v[terms[t]["y"]] + 0.5 * v[terms[t]["height"]] + 0.5 * v[terms[t]["height"]] * vDir
				if vDir == -1 then
					data.rayCol[terms[t]["y"]] = v[terms[t]["y"]] - data.rayCol[terms[t]["height"]]
				end
				local rayCandidates = makeIntersectingNPCAndBlockMap(v, data.rayCol.x, data.rayCol.y, data.rayCol.width, data.rayCol.height, {blckDefaultMap})

				local skipTeleport = false

				if #rayCandidates > 0 then
					local success = false
					for k,n in ipairs({0.5, 0, 1}) do
						local origin = vector.v2(v[terms[t]["x"]] + n * v[terms[t]["width"]], v[terms[t]["y"]] + 0.5 * v[terms[t]["height"]])
                        local dir = vector.v2(0, data.rayCol[terms[t]["height"]] * vDir)
                        if terms[t]["x"] == "y" then
                            origin.x, origin.y = origin.y, origin.x
                            dir.x, dir.y = dir.y, dir.x
                        end
						local p,_,n,o = Colliders.raycast(origin,dir,rayCandidates)
						if p then
                            success = true
							if vDir == 1 then
								v[terms[t]["y"]] = o[terms[t]["y"]] - v[terms[t]["height"]]
							else
								v[terms[t]["y"]] = o[terms[t]["y"]] + o[terms[t]["height"]]
                            end
							break
						end
					end
					if not success then skipTeleport = true end
				else
					skipTeleport = true
				end

				if not skipTeleport then
					local w = v[terms[t]["width"]] * 0.5
					local h = v[terms[t]["height"]] * 0.5
                    
                    local input = vector(v[terms[t]["x"]] + w, v[terms[t]["y"]] + h + h * vDir)
                    local inx, iny, inw, inh = input[terms[t]["x"]] - 150 - w, input[terms[t]["y"]] - h * 2, 300 + w * 2, h * 4
                    if (terms[t][x] == "y") then
                        inx, iny, inw, inh = iny, inx, inh, inw
                    end
                    local candidates = makeIntersectingNPCAndBlockMap(v, inx, iny, inw, inh, {blckDefaultMap})
					local l = freeSpaceCheck(input, -1, 150 + w, candidates, (vDir + 1) * 0.5, vector(w, h * 2), t) + 3
                    local r = freeSpaceCheck(input, 1, 150 + w, candidates, (vDir + 1) * 0.5, vector(w, h * 2), t) - v[terms[t]["width"]] - 5
					v[terms[t]["x"]] = rng.randomInt(math.min(l, r), math.max(l, r))
				end

				chasePlayers(v, t)
			end
			
		elseif data.timer > 7 * framespeed + stretchframes * framespeed - 1 then
			data.timer = 0
			data.state = 0
		end
	end
end

function stretch.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	local settings = v.data._settings
	if not data.timer then return end
	
	local cfg = NPC.config[v.id]
			
	local framespeed = cfg.framespeed
	local stretchframes = cfg.stretchframes
	local frames = cfg.frames - stretchframes

	if data.state == 0 then
		-- animation
		v.animationTimer = 500
		
		
		if framestyle == 0 then
			v.animationFrame = setFrame(0, framespeed, frames, data.timer, 1)
		else
			if v.direction == -1 then
				v.animationFrame = setFrame(0, framespeed, frames, data.timer, 1)
			else
				v.animationFrame = setFrame(frames + stretchframes, framespeed, frames, data.timer, 1)
			end
		end
		-- teleportation
		if data.timer > settings.walktimerlimit then
			if framestyle == 0 then
				v.animationFrame = setFrame(frames, framespeed, stretchframes, data.timer - settings.walktimerlimit, 1)
			else
				if v.direction == -1 then
					v.animationFrame = setFrame(frames, framespeed, stretchframes, data.timer - settings.walktimerlimit, 1)
				else
					v.animationFrame = setFrame(2 * frames + stretchframes, framespeed, stretchframes, data.timer - settings.walktimerlimit, 1)
				end
			end
		end
	else
		v.animationTimer = 500
		if data.timer > 7 * framespeed then
			if framestyle == 0 then
				v.animationFrame = setFrame(frames, framespeed, stretchframes, data.timer, -1)
			else
				if v.direction == -1 then
					v.animationFrame = setFrame(frames, framespeed, stretchframes, data.timer, -1)
				else
					v.animationFrame = setFrame(2 * frames + stretchframes, framespeed, stretchframes, data.timer, -1)
				end
			end
		else
			v.animationFrame = -1
		end
	end
end

function stretch.onTickNPC(v)
	if Defines.levelFreeze then return end
	
    local t = ids[v.id]
	local rightsideUp = upSide[t]
	
	local lspdx = 0
    local lspdy = 0
	local layer = v.layerObj
	if layer and not layer:isPaused() then
		lspdx = layer[terms[t]["speedX"]]
		lspdy = layer[terms[t]["speedY"]]
	end
	v[terms[t]["speedX"]] = lspdx
	v[terms[t]["speedY"]] = lspdy
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x134, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.timer = 0
		data.state = 0
		settings.walktimerlimit = settings.walktimerlimit or 100
		if settings.reappear == nil then
			settings.reappear = true
		end
		return
	end
	
	if not data.timer then
		data.timer = 0
		data.state = 0
		settings.walktimerlimit = settings.walktimerlimit or 100
		if settings.reappear == nil then
			settings.reappear = true
		end
	end
	
	if not data.wallCollider then
		data.friendly = v.friendly
		data.cliffCollider = Colliders.Box(v.x,v.y,2,2)
		data.rayCol = Colliders.Box(v.x,v.y,v.width,600)
        data.wallCollider = Colliders.Box(v.x, v.y, 4, v.height - 4)
        if terms[t]["x"] == "y" then
            data.cliffCollider.width, data.cliffCollider.height = data.cliffCollider.height, data.cliffCollider.width
            data.rayCol.width, data.rayCol.height = data.rayCol.height, data.rayCol.width
            data.wallCollider.width, data.wallCollider.height = data.wallCollider.height, data.wallCollider.width
        end
	end
	
	commonAI(v, rightsideUp, t)
	
	if v.layerObj and v[terms[t]["speedX"]] == v.layerObj[terms[t]["speedX"]] or v[terms[t]["speedX"]] == 0 then return end
	
	data.wallCollider[terms[t]["x"]] = v[terms[t]["x"]] + 0.5 * v[terms[t]["width"]] - 0.5 * data.wallCollider[terms[t]["width"]] + v.direction * (0.5 * v[terms[t]["width"]] - 0.5 * data.wallCollider[terms[t]["width"]])
	data.wallCollider[terms[t]["y"]] = v[terms[t]["y"]] + 2
	local wallblocks = makeIntersectingNPCAndBlockMap(v, data.wallCollider.x, data.wallCollider.y, data.wallCollider.width, data.wallCollider.height, {blckDefaultMap})
	for _,q in ipairs(wallblocks) do
		if not Block.SEMISOLID_MAP[q.id] then
			v.direction = -v.direction;
			v[terms[t]["x"]] = v[terms[t]["x"]] + 2 * v.direction
			return
		end
	end
	
	data.cliffCollider[terms[t]["x"]] = v[terms[t]["x"]] + 0.5 * v[terms[t]["width"]] - 1 + v.direction * (0.5 * v[terms[t]["width"]] + 1)
	data.cliffCollider[terms[t]["y"]] = v[terms[t]["y"]] + 0.5 * v[terms[t]["height"]] - 1 + rightsideUp * (0.5 * v[terms[t]["height"]] + 1)
	local edgeBlocks = makeIntersectingNPCAndBlockMap(v, data.cliffCollider.x, data.cliffCollider.y, data.cliffCollider.width, data.cliffCollider.height, baseBlacklists[rightsideUp])
	if #edgeBlocks == 0 then v.direction = -v.direction end
end
	
return stretch