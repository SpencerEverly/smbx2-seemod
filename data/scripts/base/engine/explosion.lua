local explosion = {}

if isOverworld then
	return nil
end

local explosionsList = {}
local explosionLights = {}
local typeRegister = {}
local collidingTable = {}

local configCache = { NPC = {}, Block = {} }

local function getConfig(typ, field, id)

	if id < 1 then
		return false
	end

	if configCache[typ][field] == nil then
		configCache[typ][field] = {}
	end
	if configCache[typ][field][id] == nil then
		configCache[typ][field][id] = _G[typ].config[id][field]
	end
	
	return configCache[typ][field][id]
end

local function npcfilter(v)
	return not v.isGenerator and not v.isHidden and not v.friendly and v:mem(0x124, FIELD_BOOL) and v.id ~= 13 and v.id ~= 291 and not getConfig("NPC", "isinteractable", v.id)
end

local function blockfilter(v)
	return not v.isHidden
end

local addrHitBlockArray = mem(0xB25798, FIELD_DWORD)
local addrHitBlockCount = 0xB25784

local function doBlockRemove(v)
	if v.id ~= 90 then
		v:mem(0x58, FIELD_WORD, -1)
		
		local newCount = mem(addrHitBlockCount, FIELD_WORD) + 1
		if (newCount < 20001) then
			mem(addrHitBlockCount, FIELD_WORD, newCount)
			mem(addrHitBlockArray + 2*newCount, FIELD_WORD, v.idx)
		end
	end
end

local function doExplosionModern(ex, playeridx)
	local multiplier = 0
	collidingTable.a = ex.collider
	collidingTable.b = NPC.ALL
	collidingTable.btype = Colliders.NPC
	collidingTable.filter = npcfilter
	
	configCache.NPC = {}
	
	-- NPC collisions
	for _,v in ipairs(Colliders.getColliding(collidingTable)) do
		multiplier = v:harm(HARM_TYPE_NPC, nil, multiplier)
		
		if getConfig("NPC", "isvegetable", v.id) then
			v:mem(0x136, FIELD_BOOL, true)
			v.speedY = -5.0
			v.speedX = RNG.random(-2,2)
		end
	end
	
	collidingTable.b = Block.SOLID..Block.SEMISOLID
	collidingTable.btype = Colliders.BLOCK
	collidingTable.filter = blockfilter
	
	-- Block collisions
	for _,v in ipairs(Colliders.getColliding(collidingTable)) do
		v:hit(false, Player(0))
		doBlockRemove(v)
		
		if ex.strong and v.id == 457 then
			v:remove(true)
		end
	end
	if not ex.friendly or mem(0x00B2D740, FIELD_BOOL) then --Battle mode check
		for _,v in ipairs(Player.get()) do
			if not ex.friendly or v.idx ~= playeridx then
				if ex.collider:collide(v) then
					v:harm()
				end
			end
		end
	end
end

local function doExplosionLegacy(ex, playeridx)

	local x = ex.collider.x
	local y = ex.collider.y
	local radius = ex.collider.radius
	local strong = ex.strong
	local friendly = ex.friendly
	local multiplier = 0
	
	configCache.NPC = {}

	for _,v in NPC.iterate() do
		if  not v.isHidden
		and v:mem(0x124, FIELD_BOOL)
		and not v.friendly
		and not v.isGenerator
		and v.id ~= 13
		and v.id ~= 291
		and not getConfig("NPC", "isinteractable", v.id) then
		
			local dx = v.x + (v.width * 0.5) - x
			local dy = v.y + (v.height * 0.5) - y
			
			local d2 = dx*dx + dy*dy
			
			local thresh = v.width * 0.25
			thresh = thresh + v.height * 0.25
			thresh = thresh + radius
			
			if thresh*thresh >= d2 then
				multiplier = v:harm(HARM_TYPE_NPC, nil, multiplier)
			
				if getConfig("NPC", "isvegetable", v.id) then
					v:mem(0x136, FIELD_BOOL, true)
					v.speedY = -5.0
					v.speedX = RNG.random(-2,2)
				end
			end
		end
	end
	
	configCache.Block = {}
	
	for _,v in Block.iterate() do
		if  not v.isHidden
		and not getConfig("Block", "passthrough", v.id) then
		
			local dx = v.x + (v.width * 0.5) - x
			local dy = v.y + (v.height * 0.5) - y
			
			local d2 = dx*dx + dy*dy
			
			local thresh = v.width * 0.25
			thresh = thresh + v.height * 0.25
			thresh = thresh + radius
			
			if thresh*thresh >= d2 then
				v:hit(false, Player(0))
				doBlockRemove(v)
				
				if strong and v.id == 457 then
					v:remove(true)
				end
			end
		end
	end
	
	if not friendly or mem(0x00B2D740, FIELD_BOOL) then --Battle mode check
		for _,v in ipairs(Player.get()) do
			if not friendly or v.idx ~= playeridx then
				local dx = v.x + (v.width * 0.5) - x
				local dy = v.y + (v.height * 0.5) - y
				
				local d2 = dx*dx + dy*dy
				
				local thresh = v.width * 0.25
				thresh = thresh + v.height*0.25
				thresh = thresh + radius
				
				if thresh*thresh >= d2 then
					v:harm()
				end
			end
		end
	end
end

local ex_mt = {}
ex_mt.__type = "Explosion"
ex_mt.__index = function(tbl,key)
	if key == "x" then
		return tbl.collider.x
	elseif key == "y" then
		return tbl.collider.y
	elseif key == "radius" then
		return tbl.collider.radius
	else
		return rawget(tbl,key)
	end
end
ex_mt.__newindex = function(tbl,key,val)
	if key == "x" then
		tbl.collider.x = val
	elseif key == "y" then
		tbl.collider.y = val
	elseif key == "radius" then
		tbl.collider.radius = val
	else
		return rawset(tbl,key,val)
	end
end

-- Make a new explosion hitbox
function explosion.create(x, y, id, playeridx, spawnEffect)
	
	local data = typeRegister[id]
	
	-- Create explosion object
	local ex = setmetatable({friendly = data.friendly, strong = data.strong, id = id, collider = Colliders.Circle(x, y, data.radius), timer = 1}, ex_mt)
	
	-- Call onExplosion event
	local obj = {cancelled = false}
	EventManager.callEvent("onExplosion", obj, ex, Player(playeridx or 0))
	
	-- If the event was cancelled, return immediately
	if obj.cancelled then
		return nil
	end
	
	if (spawnEffect) then
		-- Spawn effect and sound
		SFX.play(data.sound)
		local e = Effect.spawn(data.effect, x, y)
		
		ex.effect = e
		
		-- Make a light
		table.insert(explosionLights, Darkness.addLight(Darkness.light(x, y, data.radius*1.5, 2, Color.white, true)))
	end
	
	-- If we're using .lvl format, explosions will use a Redigit circle-circle collision check, otherwise, we'll use proper hitboxes
	if Level.format() == "lvl" then
		doExplosionLegacy(ex, playeridx)
	else
		doExplosionModern(ex, playeridx)
	end
	
	return ex
end

--Register a new explosion type
function explosion.register(id, radius, effectID, sound, isstrong, isfriendly)

	--ID-less register
	if sound == nil or type(sound) == "boolean" then
		isfriendly = isstrong
		isstrong = sound
		sound = effectID
		effectID = radius
		radius = id
		id = #typeRegister + 1
	end

	if typeRegister[id] then
		error("Explosion ID "..id.." already exists. Cannot register over an existing ID", 2)
	end
	typeRegister[id] = {radius = radius, effect = effectID, sound = sound, strong = isstrong or false, friendly = isfriendly or false}
	return id
end

--Register vanilla explosion types
explosion.register(0, 32, 148, 22, true, true)
explosion.register(1, 0, 0, 0)
explosion.register(2, 52, 69, 43)
explosion.register(3, 64, 70, 43)

local crashSplode = Misc.resolveSoundFile("nitro")
explosion.register(4, 52, 272, crashSplode)
explosion.register(5, 52, 273, crashSplode)

--Spawn a new explosion object
function explosion.spawn(x, y, kind, plyr)
	-- Vanilla explosion implementation
	local playeridx = plyr and plyr.idx
	local data = typeRegister[kind]
	
	-- Invalid explosion type
	if data == nil or kind == 1 then
		return nil
	end
	
	-- If explosion type is player-driven (e.g. peach bomb), make sure it doesn't hurt anyone
	if data.friendly then
		playeridx = playeridx or 1
	end
	
	-- Make hitbox and check if it was cancelled
	local c = explosion.create(x, y, kind, playeridx, true)

	if c then
		-- Add to list for Explosion.get
		table.insert(explosionsList, c)
	end
	
	return c
end

--Legacy support
Misc.doBombExplosion = explosion.spawn


function explosion.get(id)
	local t = {}
	
	if id == nil then
		id = -1
	end
	
	if type(id) == "table" then
	
		id = table.map(id)
		
		for _,v in ipairs(explosionsList) do
			if id[v.id] then
				table.insert(t,v)
			end
		end
	else
		for _,v in ipairs(explosionsList) do
			if id == v.id or id == -1 then
				table.insert(t,v)
			end
		end
	end
	
	return t
end

registerEvent(explosion, "onTickEnd", "onTickEnd", true)

function explosion.onTickEnd()
	-- Reduce brightness of explosion lights over time
	for i=#explosionLights,1,-1 do
		local v = explosionLights[i]
		if v.brightness <= 0 then
			v:destroy()
			table.remove(explosionLights, i)
		else
			v.brightness = v.brightness - 0.1
		end
	end
	
	-- Explosion hitboxes only last for one frame, so clear the list. Use the timer to ensure they do actually hang around for at least one frame.
	for i=#explosionsList,1,-1 do
		if explosionsList[i].timer <= 0 then
			table.remove(explosionsList, i)
		else
			explosionsList[i].timer = explosionsList[i].timer - 1
		end
	end
end

registerEvent(explosion, "onExplosionInternal", "onExplosionInternal", true)
function explosion.onExplosionInternal(obj, src, kind, plyrIdx)
	-- Translate arguments
	local x = src.x + 0.5 * src.width
	local y = src.y + 0.5 * src.height	
	local plyr = nil
	if (plyrIdx > 0) then
		plyr = Player(plyrIdx)
	end

	-- Spawn Lua based explosion
	explosion.spawn(src.x + 0.5 * src.width, src.y + 0.5 * src.height, kind, plyr)

	-- Cancel the vanilla explosion?
	obj.cancelled = true
end

return explosion