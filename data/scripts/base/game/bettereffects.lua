---------------------------------------Created by Enjl - 2018----------------------------------------
-----------------------------------Library for customizable effects----------------------------------
----------------------------------------For Super Mario Bros X---------------------------------------
------------------------------------------------v0.2-------------------------------------------------
------------------------------------------REQUIRES RNG.lua-------------------------------------------
-----------------------------------------REQUIRES vector.lua------------------------------------------
-----------------------------------REQUIRES CONFIGFILEREADER.lua-------------------------------------
-------------------------------------REQUIRES EFFECTCONFIG.lua---------------------------------------

local iniParse = require("configFileReader")
local rng = require("rng")

--TODO
--Add particles range parameters for stuff like speed over time... would be neat if i had any idea how to read the particles code for that hah...
--figure out animation.spawn variations

local bfx = {}


-- Set this to false to enable the full overriding of vanilla effect support (experimental)
bfx.restricted = true

local FX_MAX_ID = 1000
local FX_INTERNAL_MAX_ID = 161

local sort = table.sort;
local mathhuge = math.huge;
local tableinsert = table.insert;
local tableremove = table.remove;
local abs = math.abs;
local ceil = math.ceil;
local floor = math.floor;
local max = math.max;
local min = math.min;

local enum_priority = {BACKGROUND = -60, FOREGROUND = -5}
local enum_align = {LEFT = 0, RIGHT = 1, BOTTOM = 1, TOP = 0, CENTRE = 0.5, MID = 0.5, CENTER = 0.5, MIDDLE = 0.5}
Animation.config = require("game/effectconfig")
local enum_imports = Animation.config.defaults
local enum_onTick = Animation.config.onTick
local enum_onDeath = Animation.config.onDeath

local animationSpawn = Animation.spawn
local animationGet = Animation.get
local animationCount = Animation.count
local animationIntersect = Animation.getIntersecting

local function resolveFXConfig(path)
	return Misc.resolveFile(path)
end
local function resolveFXImage(path)
	return Misc.multiResolveFile(path, "graphics/effect/"..path)
end

local function getImg(l)
	if l.img == nil then
		return Graphics.sprites.effect[l.id].img
	elseif type(l.img) == "number" then
		return Graphics.sprites.effect[l.img].img
	else 
		return l.img 
	end
end

local function deriveDimensions(l)
	local img = getImg(l)
	if l.width == nil then
		l.width = img.width
	end
	if l.height == nil then
		local framestyleMod = (l.framestyle or 0) + 1
		if framestyleMod == 3 then --goddamn quadrupling frame count
			framestyleMod = 4
		end
		l.height = img.height / (l.frames * framestyleMod or 1) / l.variants
	end
end

local fieldDefaults = {
	xOffset = 0,
	yOffset = 0,
	gravity = 0,
	lifetime = 65,
	delay = 0,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	animationFrame = 0,
	animationTimer = 0,
	
	sound = nil,
	
	priority = enum_priority.FOREGROUND,
	
	xAlign = enum_align.LEFT,
	yAlign = enum_align.TOP,
	
	spawnBindX = enum_align.LEFT,
	spawnBindY = enum_align.TOP,
	
	speedX = 0,
	speedY = 0,
	
	maxSpeedX=-1,
	maxSpeedY=-1,
	
	opacity = 1,
	
	direction = -1,
	
	npcID = 0,
	
	angle = 0,
	rotation = 0,
	
	variants = 1,
	variant = 1,
	frameOffset = 0
}

local enums = table.join(enum_priority, enum_align, enum_imports, enum_onTick, enum_onDeath)
function ParseIni(path, id, fdef)
	local layers = iniParse.parseWithHeaders(path, {General = true, effect = true}, enums, true);
	
	for k,v in ipairs(layers) do
		--import predefined behaviour from lua file
		if v.import ~= nil then
			if(type(v.import) == "table") then
				for field,value in pairs(v.import) do
					if v[field] == nil then
						v[field] = value
					end
				end
			else
				--Uncomment to error if import is invalid
				--error("Invalid effect behaviour '"..tostring(v.import).."' specified for effect "..id, 3);
			end
		end
		--import predefined fields from other sections in the file
		if(v.template ~= nil) then
			for i = k,1,-1 do
				if(v.template == layers[i].name) then
					for l,w in pairs(layers[i]) do
						if(l ~= "name" and v[l] == nil) then
							v[l] = w;
						end
					end
					break;
				end
			end
		end
		for _, f in ipairs({"onInit", "onTick", "onDeath"}) do
			if type(v[f]) == "string" then
				v[f] = Effect.config[f][v[f]]
			end
		end
		--get image
		if v.img == nil then
			--v.img = Graphics.sprites.effect[id].img
			--v.img = Graphics.loadImage(resolveFXImage("effect-" .. tostring(id) .. ".png"))
			Graphics.sprites.Register("effect", "effect-"..id)
		elseif type(v.img) ~= "LuaImageResource" then
			if tonumber(v.img) then
				--v.img = Graphics.sprites.effect[v.img].img
				--v.img = Graphics.loadImage(resolveFXImage("effect-" .. tostring(v.img) .. ".png"))
				Graphics.sprites.Register("effect", "effect-"..v.img)
				v.img = tonumber(v.img)
			else
				v.img = Graphics.loadImage(resolveFXImage(tostring(v.img) .. ".png") or resolveFXImage(tostring(v.img)))
			end
		end
		--fill in the rest if necessary
		if fdef == fieldDefaults then
			for key,field in pairs(fdef) do
				if v[key] == nil then
					v[key] = field
				end
			end
		else
			if fdef[k] == nil then
				fdef[k] = fdef[k-1]
			end
			for key,field in pairs(fdef[k]) do
				if v[key] == nil then
					v[key] = field
				end
			end
		end
		v.id = id
	end
	return layers;
end

function bfx.onInitAPI()
	registerEvent(bfx, "onDraw", "onDraw", false);
	registerEvent(bfx, "onTickEnd", "onTickEnd", true);
	registerEvent(bfx, "onStart", "onStart", true);
	registerEvent(bfx, "onRunEffectInternal", "onRunEffectInternal", true);
end

--postpone loading to onStart to allow custom defined imports
function bfx.onStart()

	local fxDefs = {}
	for i=1,FX_MAX_ID do
		local ini = resolveFXConfig("config/effects/effect-"..i..".txt");
		local ini2 = resolveFXConfig("effect-"..i..".txt");
		if(ini ~= nil) then
			fxDefs[i] = ParseIni(ini, i, fieldDefaults);
		end
		if(ini2 ~= nil) then
			fxDefs[i] = ParseIni(ini2, i, fxDefs[i] or fieldDefaults);
		end
		if fxDefs[i] then
			for k,v in ipairs(fxDefs[i]) do
				deriveDimensions(v)
			end
		end
	end
	Animation.config = table.join(fxDefs, Animation.config)
end

--make sure not to crash during this
local function getRandomFromRange(field)
	if type(field) == "table" then
		return rng.random(field[1], field[2])
	end
	return field
end

--contains all layers
local activeFXSpawners = {}
--spawned from the layers
local activeFXObjects = {}

function Animation.getIntersecting(x1, y1, x2, y2)
	if bfx.restricted then
		return animationIntersect(x1, y1, x2, y2)
	end
	
	local results = {}
	
	for k,v in ipairs(activeFXObjects) do
		local leftEdge = v.x - v.width * v.xAlign
		local topEdge = v.y - v.height * v.yAlign
		if leftEdge > x1
		and leftEdge + v.width < x2
		and topEdge > y1
		and topEdge + v.height < y2
			then
			tableinsert(results, v)
		end
	end
	
	return results
end

function Animation.count()
	if bfx.restricted then
		return animationCount()
	end
	return #activeFXObjects
end

local function getObjectsFromTable(t, id)
	if id then
		if id <= FX_INTERNAL_MAX_ID then
			error("Cannot get effects for vanilla effect ids via bettereffects.")
			return {}
		end
		if type(id) == "table" then
			local idMap = {}
			local results = {}
			for k,v in ipairs(id) do
				idMap[k] = true
			end
			for k,v in ipairs(t) do
				if idMap[v.id] then
					tableinsert(results, v)
				end
			end
			return results
		elseif type(id) == "number" then
			local results = {}
			for k,v in ipairs(t) do
				if id == v.id then
					tableinsert(results, v)
				end
			end
			return results
		else
			error("Wrong type of Animation.get argument")
		end
	else
		return t
	end
end

function bfx.getEffectSpawners(id)
	return getObjectsFromTable(activeFXSpawners, id)
end

function bfx.getEffectObjects(id)
	return getObjectsFromTable(activeFXObjects, id)
end

function Animation.get(id)
	if bfx.restricted then
		if(id == nil) then
			return animationGet();
		else
			return animationGet(id);
		end
	end
	return bfx.getEffectObjects(id)
end

local function chooseOverride(a, b)
	if a == nil then
		return b
	end
	return a
end

local function internalUpdate(v)
	v.x = v.x + v.speedX
	v.y = v.y + v.speedY

	v.speedY = v.speedY + v.gravity

	if v.maxSpeedX >= 0 then
		v.speedX = math.clamp(v.speedX, -v.maxSpeedX, v.maxSpeedX)
	end

	if v.maxSpeedY >= 0 then
		v.speedY = math.clamp(v.speedY, -v.maxSpeedY, v.maxSpeedY)
	end

	v.angle = v.angle + v.rotation

	if v.framespeed > 0 then
		if v.animationTimer >= v.framespeed then
			v.animationTimer = 0
			v.animationFrame = (v.animationFrame + 1) % v.frames
		end
		v.animationTimer = v.animationTimer + 1
	end
	v.timer = v.timer - 1
end

local function realignChildrenInternal(spawner)
	for k,obj in ipairs(spawner.effects) do
		local def = Effect.config[spawner.id][k]
		local spawnBindX = chooseOverride(spawner.spawnBindX, def.spawnBindX)
		local spawnBindY = chooseOverride(spawner.spawnBindY, def.spawnBindY)
		obj.x = spawner.x + getRandomFromRange(chooseOverride(spawner.xOffset, def.xOffset)) + spawnBindX * obj.parent.width
		obj.y = spawner.y + getRandomFromRange(chooseOverride(spawner.yOffset, def.yOffset)) + spawnBindY * obj.parent.height
		--obj.x = obj.x  + obj.xAlign * obj.width
		--obj.y = obj.y  + obj.yAlign * obj.height
	end
	spawner.skipPositionUpdate = true
end

function bfx.onInit(fx)
	--fx.x = fx.x + 0.5 * fx.parent.width
	--fx.y = fx.y + 0.5 * fx.parent.height
end

local function spawnEntry(spawner, def)
	local obj = {}
	--copy all properties into the spawned object
	
	obj.x = spawner.x + getRandomFromRange(chooseOverride(spawner.xOffset, def.xOffset))
	obj.y = spawner.y + getRandomFromRange(chooseOverride(spawner.yOffset, def.yOffset))
	obj.gravity = getRandomFromRange(chooseOverride(spawner.gravity, def.gravity))
	

	obj.speedX = spawner.spawnerSpeedX + chooseOverride(spawner.speedX, getRandomFromRange(def.speedX))
	obj.speedY = spawner.spawnerSpeedY + chooseOverride(spawner.speedY, getRandomFromRange(def.speedY))
	
	obj.maxSpeedX = getRandomFromRange(chooseOverride(spawner.maxSpeedX, def.maxSpeedX))
	obj.maxSpeedY = getRandomFromRange(chooseOverride(spawner.maxSpeedY, def.maxSpeedY))
	
	obj.priority = chooseOverride(spawner.priority, def.priority)
	
	obj.lifetime = getRandomFromRange(chooseOverride(spawner.lifetime, def.lifetime))
	obj.timer = obj.lifetime
	obj.subTimer = chooseOverride(spawner.subTimer, 0)
	
	obj.xAlign = chooseOverride(spawner.xAlign, def.xAlign)
	obj.yAlign = chooseOverride(spawner.yAlign, def.yAlign)
	
	local w = spawner.width
	if spawner.width == Effect.config[spawner.id][1].width then
		w = nil
	end
	local h = spawner.height
	if spawner.height == Effect.config[spawner.id][1].height then
		h = nil
	end
	
	local spawnBindX = chooseOverride(spawner.spawnBindX, def.spawnBindX)
	local spawnBindY = chooseOverride(spawner.spawnBindY, def.spawnBindY)
	
	obj.parent = spawner.parent
	obj.isHidden = false
	
	obj.width = chooseOverride(w, def.width)
	obj.height = chooseOverride(h, def.height)

	obj.x = obj.x + spawnBindX * obj.parent.width
	obj.y = obj.y + spawnBindY * obj.parent.height
	
	--obj.x = obj.x + spawnBindX * obj.parent.width + obj.xAlign * obj.width
	--obj.y = obj.y + spawnBindY * obj.parent.height + obj.yAlign * obj.height
	obj.img = chooseOverride(spawner.img, def.img)
	obj.id = spawner.id
	
	obj.animationFrame = chooseOverride(spawner.animationFrame, def.animationFrame)
	obj.animationTimer = chooseOverride(spawner.animationTimer, def.animationTimer)
	obj.frames = chooseOverride(spawner.frames, def.frames)
	obj.framestyle = chooseOverride(spawner.framestyle, def.framestyle)
	obj.framespeed = chooseOverride(spawner.framespeed, def.framespeed)
	
	obj.direction = chooseOverride(spawner.direction, def.direction)
	
	obj.angle = chooseOverride(spawner.angle, def.angle)
	obj.rotation = getRandomFromRange(chooseOverride(spawner.rotation, def.rotation))
	
	obj.onTick = spawner.onTick or def.onTick
	obj.onDeath = spawner.onDeath or def.onDeath
	
	obj.onInit = spawner.onInit or def.onInit or bfx.onInit
	
	obj.variant = spawner.variant or def.variant
	obj.variants = chooseOverride(spawner.variants, def.variants)
	obj.frameOffset = spawner.frameOffset or 0
	
	obj.npcID = chooseOverride(spawner.npcID, def.npcID)
	obj.drawOnlyMask = chooseOverride(spawner.drawOnlyMask, false) --needs to be implemented using the shadowstar shader or something... maybe later.
	local playedSound = chooseOverride(spawner.sound, def.sound)
	if playedSound then
		SFX.play(playedSound)
	end
	
	tableinsert(activeFXObjects, obj)
	
	obj.kill = function(o) o.timer = 0 end
	
	obj:onInit()
	obj.update = internalUpdate;
	
	if obj.variants > 1 then
		local framestyleMod = obj.framestyle + 1
		if framestyleMod == 3 then framestyleMod = 4 end
		obj.frameOffset = (math.clamp(obj.variant, 1, obj.variants) - 1) * obj.frames * framestyleMod
	end
	return obj
end

--copy defs over to object
--x can also be "momentum". then y is variant, etc...
function Animation.spawn(id, x, y, variant, npcID, drawOnlyMask)
	if bfx.restricted and id <= FX_INTERNAL_MAX_ID then
		if type(x) ~= "number" then
			variant = y
			y = x.y
			x = x.x
		end
		if variant then
			return animationSpawn(id, x,y,variant)
		else
			return animationSpawn(id, x,y)
		end
	end
	
	local fxObj = {}
	
	fxObj.parent = {}
	if type(x) ~= "number" then
		fxObj.parent = {x = x.x, y = x.y, width = x.width, height = x.height, speedX = x.speedX, speedY = x.speedY, ref = x}
		fxObj.variant = y
		fxObj.npcID = variant or 0
		fxObj.drawOnlyMask = npcID or false
	else
		fxObj.parent = {x = x, y = y, width = 0, height = 0, speedX = 0, speedY = 0}
		fxObj.variant = variant
		fxObj.npcID = npcID or 0
		fxObj.drawOnlyMask = drawOnlyMask or false
	end
	
	fxObj.id = id
	fxObj.x = fxObj.parent.x
	fxObj.y = fxObj.parent.y
	fxObj.speedX = nil
	fxObj.speedY = nil
	fxObj.spawnerSpeedX = 0
	fxObj.spawnerSpeedY = 0
	fxObj.lastX = fxObj.x
	fxObj.lastY = fxObj.y
	fxObj.width = Effect.config[id][1].width
	fxObj.height = Effect.config[id][1].height
	fxObj.timer = 0
	fxObj.subTimer = 0
	fxObj.frameOffset = 0
	fxObj.waitingToRemove = false
	fxObj.skipPositionUpdate = false
	fxObj.effects = {}
	--store spawn timings into subtable and keep reference to id for later
	fxObj.startTimes = {}
	fxObj.finished = {}
	for k,v in ipairs(Effect.config[id]) do --gotta switch this out if id changes
		fxObj.startTimes[k] = v.delay
		fxObj.finished[k] = false
	end

	fxObj.realignChildren = realignChildrenInternal
	
	fxObj.kill = function(obj)
		for _,f in ipairs(obj.effects) do
			f:kill()
		end
		for i=#activeFXSpawners, 1, -1 do
			if activeFXSpawners[i] == obj then
				tableremove(activeFXSpawners, i)
			end
		end
		obj = nil
	end
	
	tableinsert(activeFXSpawners, fxObj)
	return fxObj
end

function bfx.onTickEnd()
	local length = #activeFXSpawners
	local lf = Defines.levelFreeze
	for i=length, 1, -1 do
		local v = activeFXSpawners[i]
		v.x = v.x + v.spawnerSpeedX
		v.y = v.y + v.spawnerSpeedY
		if not v.skipPositionUpdate then
			for _,e in ipairs(v.effects) do
				e.x = e.x + v.x - v.lastX
				e.y = e.y + v.y - v.lastY
			end
		else
			v.skipPositionUpdate = false
		end
		v.lastX = v.x
		v.lastY = v.y
		if v.waitingToRemove and #v.effects == 0 then
			table.remove(activeFXSpawners, i)
			v = nil
		end
		if v then
			for k,t in pairs(v.startTimes) do
				if v.timer == t and not v.finished[k] then
					local def = Effect.config[v.id][k]
					tableinsert(v.effects, spawnEntry(v, def))
					
					v.finished[k] = true
					--cleanup
					local broke = false
					for _,f in ipairs(v.finished) do
						if f == false then
							broke = true
							break
						end
					end
					if not broke then
						v.waitingToRemove = true
					end
				end
			end
			if not lf then
				v.timer = v.timer + 1
			end
		end
	end
	if lf then return end
	for i=#activeFXObjects, 1, -1 do
		local v = activeFXObjects[i]
		
		if not v.isHidden then
			v:update()
		end
		
		if v.onTick then
			v:onTick()
		end
		
		if v.timer <= 0 then
			local cancelled = false
			if v.onDeath then
				cancelled = v:onDeath()
			end
			if not cancelled then
				tableremove(activeFXObjects, i)
				v = nil
			end
		end
	end
end

local function rotateObj(sprite, angle)
	local s = sprite
	for k,v in ipairs(s) do
        s[k] = v:rotate(angle);
    end
end

function bfx.onDraw()
	for k,v in ipairs(activeFXObjects) do
		if not v.isHidden then
			local xAl = v.xAlign
			local yAl = v.yAlign
			local w,h = v.width, v.height
			
			local x = v.x 
			local y = v.y
			local wL = w * -xAl
			local hT = h * -yAl
			local wR = w * (1 - xAl)
			local hB = h * (1 - yAl)
			
			local edges = {
				vector.v2(wL, hT),
				vector.v2(wR, hT),
				vector.v2(wR, hB),
				vector.v2(wL, hB),
			}
			
			if v.angle ~= 0 then
				rotateObj(edges, v.angle)
			end
			
			local frame = v.animationFrame + v.frameOffset
			local framestyleMod = v.framestyle + 1
			if framestyleMod == 3 then framestyleMod = 4 end
			
			local maxFrames = v.frames * framestyleMod * v.variants
			
			if v.framestyle > 0 and v.direction == 1 then
				frame = frame + v.frames
			end
			if v.framestyle == 2 then
				frame = frame + 2 * v.frames
			end
			local f = frame / maxFrames
			local f1 = (frame + 1) / maxFrames
			local tx = {
				0, f,
				1, f,
				1, f1,
				0, f1,
			}
			
			Graphics.glDraw{
				vertexCoords = {
					x + edges[1].x, y + edges[1].y,
					x + edges[2].x, y + edges[2].y,
					x + edges[3].x, y + edges[3].y,
					x + edges[4].x, y + edges[4].y,
				},
				textureCoords = tx,
				texture = getImg(v),
				primitive = Graphics.GL_TRIANGLE_FAN,
				priority = v.priority,
				sceneCoords = true
			}
		end
	end
end

function bfx.onRunEffectInternal(eventObj, id, coords, variant, npcID, drawOnlyMask)
	if not bfx.restricted then
		eventObj.cancelled = true -- Cancel non-better effect spawning
		
		-- Run bettereffects spawning
		-- NOTE: coords may contain speed/size information we're currently ignoring?
		Animation.spawn(id, coords.x, coords.y, variant, npcID, drawOnlyMask)
	end
end

_G["Effect"] = Animation

return bfx