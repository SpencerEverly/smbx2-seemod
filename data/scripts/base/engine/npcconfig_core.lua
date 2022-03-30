--npcconfig.lua 
--v2.0.0
--Created by Hoeloe, (heavily) modified by Rednaxela
local npcconfig = {}

local ed = require("expandeddefines")

-- Declare encoder/decoder functions functions
local encodeHarmMask, decodeHarmMask
local maskableHarmTypeMap = {
	[HARM_TYPE_JUMP]=true,
	[HARM_TYPE_FROMBELOW]=true,
	[HARM_TYPE_NPC]=true,
	[HARM_TYPE_PROJECTILE_USED]=true,
	[HARM_TYPE_LAVA]=true,
	[HARM_TYPE_HELD]=true,
	[HARM_TYPE_TAIL]=true,
	[HARM_TYPE_SPINJUMP]=true,
	[HARM_TYPE_OFFSCREEN]=true,
	[HARM_TYPE_SWORD]=true
}
local function decodeHarmMask(mskVal)
	local tblVal = {}
	for v,_ in pairs(maskableHarmTypeMap) do
		if (bit.band(mskVal, bit.lshift(1, v)) ~= 0) then
			table.insert(tblVal, v)
		end
	end
	return tblVal
end
local function encodeHarmMask(tblVal)
	local mskVal = 0
	for _,v in ipairs(tblVal) do
		if maskableHarmTypeMap[v] then
			mskVal = bit.bor(mskVal, bit.lshift(1, v))
		end
	end
	return mskVal
end

-- Encoder for casting to boolean
local function encodeBoolean(value)
	return (value ~= false) and (value ~= 0) and (value ~= nil)
end

-- Encoder for casting to number
local function encodeNumber(value)
	if value == true then
		return 1
	elseif tonumber(value) then
		return tonumber(value)
	elseif not value then
		return 0
	else
		error("Cannot convert `" .. value .. "` (type: " .. type(value) .. ") to number")
	end
end

-- Main property table
local propertyTables = {
	-- Vanilla properties
	gfxoffsetx        = {ptr=0x00B25B70, t=FIELD_WORD},
	gfxoffsety        = {ptr=0x00B25B8C, t=FIELD_WORD},
	width             = {ptr=0x00B25BA8, t=FIELD_WORD},
	height            = {ptr=0x00B25BC4, t=FIELD_WORD},
	gfxwidth          = {ptr=0x00B25BE0, t=FIELD_WORD},
	gfxheight         = {ptr=0x00B25BFC, t=FIELD_WORD},
	speed             = {ptr=0x00B25C18, t=FIELD_FLOAT},
	isshell           = {ptr=0x00B25C34, t=FIELD_BOOL},
	npcblock          = {ptr=0x00B25C50, t=FIELD_BOOL},
	npcblocktop       = {ptr=0x00B25C6C, t=FIELD_BOOL},
	isinteractable    = {ptr=0x00B25C88, t=FIELD_BOOL},
	iscoin            = {ptr=0x00B25CA4, t=FIELD_BOOL},
	isvine            = {ptr=0x00B25CC0, t=FIELD_BOOL},
	iscollectablegoal = {ptr=0x00B25CDC, t=FIELD_BOOL},
	isflying          = {ptr=0x00B25CF8, t=FIELD_BOOL},
	iswaternpc        = {ptr=0x00B25D14, t=FIELD_BOOL},
	jumphurt          = {ptr=0x00B25D30, t=FIELD_BOOL},
	noblockcollision  = {ptr=0x00B25D4C, t=FIELD_BOOL},
	score             = {ptr=0x00B25D68, t=FIELD_WORD},
	playerblocktop    = {ptr=0x00B25D84, t=FIELD_BOOL},
	grabtop           = {ptr=0x00B25DA0, t=FIELD_BOOL},
	cliffturn         = {ptr=0x00B25DBC, t=FIELD_BOOL},
	nohurt            = {ptr=0x00B25DD8, t=FIELD_BOOL},
	playerblock       = {ptr=0x00B25DF4, t=FIELD_BOOL},
	grabside          = {ptr=0x00B25E2C, t=FIELD_BOOL},
	isshoe            = {ptr=0x00B25E48, t=FIELD_BOOL},
	isyoshi           = {ptr=0x00B25E64, t=FIELD_BOOL},
	noyoshi           = {ptr=0x00B25E9C, t=FIELD_BOOL},
	foreground        = {ptr=0x00B25EB8, t=FIELD_BOOL},
	isbot             = {ptr=0x00B25ED4, t=FIELD_BOOL},
	isvegetable       = {ptr=0x00B25F0C, t=FIELD_BOOL},
	nofireball        = {ptr=0x00B25F28, t=FIELD_BOOL},
	noiceball         = {ptr=0x00B25F44, t=FIELD_BOOL},
	nogravity         = {ptr=0x00B25F60, t=FIELD_BOOL},
	frames            = {ptr=0x00B25F7C, t=FIELD_WORD},
	framespeed        = {ptr=0x00B25F98, t=FIELD_WORD},
	framestyle        = {ptr=0x00B25FB4, t=FIELD_WORD},
	iswalker          = {ptr=0x00b25ef0, t=FIELD_BOOL},
	
	-- Extended properties
	vulnerableharmtypes = {name="vulnerableharmtypes", t=FIELD_DWORD, encoder=encodeHarmMask, decoder=decodeHarmMask},
	spinjumpsafe         = {name="spinjumpsafe",         t=FIELD_BOOL},
	nowaterphysics       = {name="nowaterphysics",       t=FIELD_BOOL},
	harmlessgrab         = {name="harmlessgrab",         t=FIELD_BOOL},
	harmlessthrown       = {name="harmlessthrown",       t=FIELD_BOOL},
	ignorethrownnpcs     = {name="ignorethrownnpcs",     t=FIELD_BOOL},
	linkshieldable       = {name="linkshieldable",       t=FIELD_BOOL},
	noshieldfireeffect   = {name="noshieldfireeffect",   t=FIELD_BOOL},
	notcointransformable = {name="notcointransformable", t=FIELD_BOOL},
	staticdirection      = {name="staticdirection",      t=FIELD_BOOL},
	luahandlesspeed      = {name="luahandlesspeed",      t=FIELD_BOOL},
	lightradius          = {t="number"},
	lightbrightness      = {t="number"},
	lightoffsetx         = {t="number"},
	lightoffsety         = {t="number"},
	lightcolor           = {t=Color.parse},
	lightflicker         = {t="boolean"},
	health               = {t="number"},
	nogliding            = {t="boolean"},
	isheavy              = {t="boolean"},
	ishot                = {t="boolean"}, -- used by elemental blocks
	iscold               = {t="boolean"}, -- used by elemental blocks
	durability           = {t="number"}, -- used by elemental blocks
	lineguided           = {t="boolean"},
	linespeed            = {t="number"},
	linejumpspeed        = {t="number"},
	usehiddenlines       = {t="boolean"},
	linefallwheninactive     = {t="boolean"},
	lineactivebydefault      = {t="boolean"},
	lineactivateonstanding   = {t="boolean"},
	lineactivatenearby       = {t="boolean"}, -- for skull rafts on lineguides. Currently has no effect.
	linesensoralignh         = {t="number", default=0.5},
	linesensoralignv         = {t="number", default=0.5},
	linesensoroffsetx        = {t="number"},
	linesensoroffsety        = {t="number"},
	extendeddespawntimer = {t="boolean"}, -- I feel like this one ...
	buoyant              = {t="boolean"}, -- ... and this one should be separated from lineguide
	collideswhenattached = {t="boolean", default=false}, -- used by lineguide
	
	-- expandeddefines pizazz. don't do anything other than indexing.
	iscustomswitch       = {t="boolean"},
	powerup              = {t="boolean"},
	}

-- Deprecated aliases
local aliases = {
	blocknpc="npcblock",
	blockplayer="playerblock",
	blocknpctop ="npcblocktop"
}

-- Externally-exposed list of all standard NPC properties
npcconfig.properties = {}
for k,v in pairs(propertyTables) do
	table.insert(npcconfig.properties, k)
end
for k,v in pairs(aliases) do
	table.insert(npcconfig.properties, k)
end
-- Map of the above
npcconfig.propertiesMap = table.map(npcconfig.properties)

-- Mapping of field types to field sizes
local fieldSizes = {
	[FIELD_WORD]   = 2,
	[FIELD_BOOL]   = 2,
	[FIELD_DWORD]  = 4,
	[FIELD_BYTE]   = 1,
	[FIELD_FLOAT]  = 4,
	[FIELD_DFLOAT] = 8,
	[FIELD_STRING] = 4,
	}

-- Resolve addresses and field sizes ahead of time
for _,tbl in pairs(propertyTables) do
	-- Fill in resolved address for vanilla types
	if (tbl.ptr ~= nil) and (tbl.addr == nil) then
		tbl.addr = readmem(tbl.ptr, FIELD_DWORD)
	end
	
	-- Fill in resolved address for extended types
	if (tbl.name ~= nil) and (tbl.addr == nil) then
		tbl.addr = Misc.__getNPCPropertyTableAddress(tbl.name)
	end
	
	-- Boolean field automatically get a casting encoder
	if (tbl.encoder == nil) and (tbl.t == FIELD_BOOL) then
		tbl.encoder = encodeBoolean
	end
	
	-- Fill in stride
	tbl.stride = fieldSizes[tbl.t]
end

local extraProperties, extraTypes, propsNextMap, unrecognizedTxtProperties
do
	-- Table for non-standard properties used by Lua NPCs
	extraProperties = {}
	-- Table for the types of the above properties
	extraTypes = {}
	-- Map from each property to the next one for iteration without next()
	propsNextMap = {}
	-- Table for early storage of loaded properties not registered yet
	unrecognizedTxtProperties = {}
	-- Table for non default properties
	nonDefaultProperties = {}
	
	local standardPropsNextMap = {}
	local standardPropsList = table.unmap(propertyTables)
	for k,v in ipairs(standardPropsList) do
		standardPropsNextMap[v] = standardPropsList[k+1]
		standardPropsNextMap[0] = v
	end
	standardPropsNextMap[""] = standardPropsList[1]
	for i = 1, NPC_MAX_ID do
		extraProperties[i] = {}
		extraTypes[i] = {}
		propsNextMap[i] = table.clone(standardPropsNextMap)
		unrecognizedTxtProperties[i] = {}
		nonDefaultProperties[i] = {}
	end
end

-- Copy entries for aliaes
for alias,target in pairs(aliases) do
	propertyTables[alias] = propertyTables[target]
end

-- Iterator for config objects
local function nextProp(t, k)
	local nextKey = propsNextMap[t.id][k]
	if nextKey ~= nil then
		return nextKey, t[nextKey]
	end
end

-- Property names are iNsEnSiTiVe_SnAkE_cAsE
local escapeName
do
	local string_lower, string_gsub = string.lower, string.gsub
	function escapeName(name)
		return string_lower(name)
	end
end

local function registerProperty(self, propName, propType)
	propName = escapeName(propName)
	if propName == "registerproperty" then
		error("Yo dawg, you can't register registerProperty as a property")
	elseif npcconfig.propertiesMap[propName] then
		error("Cannot register standard property " .. propName)
	end
	local props = extraTypes[self.id]
	local nextMap = propsNextMap[self.id]
	if props[propName] ~= nil then
		error("Property " .. propName .. " already registered as type " .. props[propName] .. " for NPC " .. self.id)
	else
		props[propName] = propType
		nextMap[nextMap[0]] = propName
		nextMap[0] = propName
	end
	
	-- Set value if we loaded it earlier
	local earlyValue = unrecognizedTxtProperties[self.id][propName]
	if (earlyValue ~= nil) then
		unrecognizedTxtProperties[self.id][propName]  = nil
		self[propName] = earlyValue
	end
end

local function setDefaultProperty(self, propName, defaultValue)
	propName = escapeName(propName)
	
	-- If a property hasn't been registered, register it when we do this
	if (not npcconfig.propertiesMap[propName]) and (extraTypes[self.id][propName] == nil) then
		registerProperty(self, propName, type(defaultValue))
	end
	
	-- If a property hasn't been set, try to set it
	if not nonDefaultProperties[self.id][propName] then
		self[propName] = defaultValue
		nonDefaultProperties[self.id][propName] = nil
	end
end

local function getDefaultFromType(t)
	if t == "number" then
		return 0
	elseif t == "boolean" then
		return false
	end
end

-- Define metatable for handling 
local npcmt = {
	__newindex = function (tbl, key, value)
		key = escapeName(key)
		if key == "registerproperty" then
			error("registerProperty is not an NPC property, make no attempt to reassign it")
		end
		if key == "setdefaultproperty" then
			error("setDefaultProperty is not an NPC property, make no attempt to reassign it")
		end
		local prop = propertyTables[key]
		if prop ~= nil and prop.addr ~= nil then
			if prop.encoder ~= nil then
				value = prop.encoder(value)
			end
			local ov = readmem(prop.addr + prop.stride * tbl.id, prop.t)
			if prop.decoder ~= nil then
				ov = prop.decoder(ov)
			end
			writemem(prop.addr + prop.stride * tbl.id, prop.t, value)
			if value ~= ov then
				EventManager.callEvent("onNPCConfigChange", tbl.id, key, value, ov)
			end
		else
			local propType;
			if prop ~= nil then
				propType = prop.t
			else
				propType = extraTypes[tbl.id][key]
			end
			if propType == nil then
				error("Property " .. key .. " not registered for NPC " .. tbl.id)
			elseif propType ~= type(value) then
				if propType == "boolean" then
					value = encodeBoolean(value)
				elseif propType == "number" then
					value = encodeNumber(value)
				elseif propType == "string" then
					value = tostring(value)
				elseif type(propType) == "function" then
					value = propType(value)
				elseif propType == "Color" then
					value = Color.parse(value)
				else
					error("Cannot convert `" .. value .. "` (type: " .. type(value) .. ") to " .. propType)
				end
			end
			local ov = extraProperties[tbl.id][key]
			if prop ~= nil and ov == nil then
				ov = prop.default
			end
			extraProperties[tbl.id][key] = value
			
			if value ~= ov then
				EventManager.callEvent("onNPCConfigChange", tbl.id, key, value, ov)
			end
		end
		nonDefaultProperties[tbl.id][key] = true
		ed.setNPCProperty(tbl, key, value)
	end,
	__index = function (tbl, key)
		key = escapeName(key)
		if key == "registerproperty" then
			return registerProperty
		end
		if key == "setdefaultproperty" then
			return setDefaultProperty
		end
		local prop = propertyTables[key]
		if prop ~= nil and prop.addr ~= nil then
			local value = readmem(prop.addr + prop.stride * tbl.id, prop.t)
			if prop.decoder ~= nil then
				value = prop.decoder(value)
			end
			return value
		elseif prop ~= nil then
			if extraProperties[tbl.id][key] == nil then
				if prop.default == nil then
					return getDefaultFromType(prop.t)
				else
					return prop.default
				end
			else
				return extraProperties[tbl.id][key]
			end
		else
			return extraProperties[tbl.id][key]
		end
	end,
	__pairs = function (tbl)
		return nextProp, tbl, ""
	end
}

-- Function to load NPC configuration from files
function npcconfig.loadAllTxt()
	local configFileReader = require("configFileReader")

	for id = 1,NPC_MAX_ID do
		local configFile = configFileReader.parseTxt("npc-" .. id .. ".txt")
		if(configFile ~= nil) then
			for npcCode, npcValue in pairs(configFile) do
				npcCode = npcCode:lower()
				if npcconfig.propertiesMap[npcCode] or extraTypes[id][npcCode] then
					-- If a property is known, store it normally
					npcconfig[id][npcCode] = npcValue
				else
					-- Store txt properties we don't recognize in case we register them later
					unrecognizedTxtProperties[id][npcCode] = npcValue
				end
			end
		end
	end
end

-- Declare the npcconfig object itself
setmetatable(npcconfig, {
	__newindex = function (tbl, key, value)
		error("Cannot assign directly to NPC config. Try assigning to a field instead.", 2)
	end,
	__index = function (tbl, key)
		if type(key) == "number" and key >= 1 and key <= NPC_MAX_ID then
			local val = {id = key}
			setmetatable(val, npcmt)
			rawset(tbl,key,val)
			return val
		else
			return nil
		end
	end
})

-- Patch in some semi-legacy properties on NPC class
if (NPC ~= nil) then
	local vulnerableHarmTypesMetatable = {
		__index = function(tbl, id)
			Misc.warn("NPC.vulnerableHarmTypes used for NPC " .. id)
			return npcconfig[id].vulnerableharmtypes
		end,
		__newindex = function(tbl, id, val)
			Misc.warn("NPC.vulnerableHarmTypes used for NPC " .. id)
			npcconfig[id].vulnerableharmtypes = val
		end
	}
	NPC.vulnerableHarmTypes = setmetatable({}, vulnerableHarmTypesMetatable)

	local spinjumpSafeMetatable = {
		__index = function(tbl, id)
			Misc.warn("NPC.spinjumpSafe used for NPC " .. id)
			return npcconfig[id].spinjumpsafe
		end,
		__newindex = function(tbl, id, val)
			Misc.warn("NPC.spinjumpSafe used for NPC " .. id)
			npcconfig[id].spinjumpsafe = val
		end
	}
	NPC.spinjumpSafe = setmetatable({}, spinjumpSafeMetatable)
end

-- Patch in a 'config' member variable in the NPC namespace
if(NPC == nil) then
	_G.NPC = {};
end
NPC.config = npcconfig

return npcconfig
