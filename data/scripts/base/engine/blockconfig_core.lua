--blockconfig.lua
--v1.0.0
--Created by Rednaxela based on npcconfig.lua
local blockconfig = {}

local blockutils = require("blocks/blockutils")
local ed = require("expandedDefines")
local tableinsert = table.insert
local tableremove = table.remove
local getFrames
local setFrames
local getFrameSpeed
local setFrameSpeed
local setcollidable
local getcollidable
local getSmashable
local setSmashable
local getCustomHurt
local setCustomHurt
local getIDsWithMultipleFrames
if Block ~= nil then
	local Block_hurt = {}
	local Block_smashable = {}
	local Block_collidable = {}

	function getcollidable(id)
		return Block_collidable[id]
	end

	function setcollidable(id, val)
		Block_collidable[id] = val
	end

	function getSmashable(id)
		return Block_smashable[id]
	end

	function setSmashable(id, val)
		Block_smashable[id] = val
	end

	function getCustomHurt(id)
		return Block_hurt[id]
	end

	function setCustomHurt(id, val)
		Block_hurt[id] = val
	end
	
	-- Moderately hacky. Fix this.
	local Block_frames = {}
	local Block_framespeeds = {}
	local Block_framesList = {}

	function getIDsWithMultipleFrames()
		return Block_framesList
	end
	
	function getFrames(id)
		Block_frames[id] = Block_frames[id] or 1
		return Block_frames[id]
	end

	function setFrames(id, val)
		Block_frames[id] = val

		if Block_frames[id] > 1 then
			tableinsert(Block_framesList, id)
		else
			local idx = table.ifind(Block_framesList, id)
			if idx then
				tableremove(Block_framesList, idx)
			end
		end
	end
	
	function getFrameSpeed(id)
		Block_framespeeds[id] = Block_framespeeds[id] or 8
		return Block_framespeeds[id]
	end

	function setFrameSpeed(id, val)
		Block_framespeeds[id] = val
	end
else
	function getFrames(id)
		return  1
	end

	function setFrames(id, val)
	end

	function getFrameSpeed(id)
		return 8
	end

	function setFrameSpeed(id, val)
	end

	function getcollidable(id)
		return false
	end

	function setcollidable(id, val)
	end

	function getSmashable(id)
		return false
	end

	function setSmashable(id, val)
	end

	function getCustomHurt(id)
		return false
	end

	function setCustomHurt(id, val)
	end
end

local lightdata = {};

local function getlightval(id, k)
	local t = lightdata[id]
	if t == nil then
		return nil
	else
		return t[k]
	end
end

local function setlightval(id, k, v)
	local t = lightdata[id]
	if t == nil then
		lightdata[id] = {}
		t = lightdata[id]
	end
	
	t[k] = v
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

local function getlightoffsetx(id)
	return getlightval(id, "offsetx")
end

local function setlightoffsetx(id, v)
	setlightval(id, "offsetx", encodeNumber(v))
end

local function getlightoffsety(id)
	return getlightval(id, "offsety")
end

local function setlightoffsety(id, v)
	setlightval(id, "offsety", encodeNumber(v))
end

local function getlightradius(id)
	return getlightval(id, "radius")
end

local function setlightradius(id, v)
	setlightval(id, "radius", encodeNumber(v))
end

local function getlightbrightness(id)
	return getlightval(id, "brightness")
end

local function setlightbrightness(id, v)
	setlightval(id, "brightness", encodeNumber(v))
end

local function getlightcolor(id)
	return getlightval(id, "color")
end

local function setlightcolor(id, v)
	setlightval(id, "color", Color.parse(v))
end

local function getlightflicker(id)
	return getlightval(id, "flicker")
end

local function setlightflicker(id, v)
	setlightval(id, "flicker", encodeBoolean(v))
end

local function getnoshadows(id)
	return getlightval(id, "noshadows")
end

local function setnoshadows(id, v)
	setlightval(id, "noshadows", encodeBoolean(v))
end

-- Main property table
local propertyTables = {
	-- Vanilla properties
	width             = {ptr=0xb2b9f8, t=FIELD_WORD},
	height            = {ptr=0xb2ba14, t=FIELD_WORD},
	sizable           = {ptr=0xb2b930, t=FIELD_BOOL},
	passthrough       = {ptr=0xb2c0d4, t=FIELD_BOOL},
	pswitchable       = {ptr=0xb2c0b8, t=FIELD_BOOL},
	lava              = {ptr=0xb2c064, t=FIELD_BOOL},
	semisolid         = {ptr=0xb2c048, t=FIELD_BOOL},
	floorslope        = {ptr=0xb2b94c, t=FIELD_WORD},
	ceilingslope      = {ptr=0xb2b968, t=FIELD_WORD},

	-- Properties with a meaning not precisely enough known to warrant a
	-- proper name yet.
	_unk_muncherspike = {ptr=0xb2c09c, t=FIELD_BOOL},
	_unk_lavarelated  = {ptr=0xb2c080, t=FIELD_BOOL},

	-- Extended properties
	bumpable     = {name="bumpable",     t=FIELD_BOOL},
	playerfilter = {name="playerfilter", t=FIELD_WORD},
	npcfilter    = {name="npcfilter",    t=FIELD_WORD},
	
	-- Lua extended properties
	smashable    = {get=getSmashable, set=setSmashable, t=FIELD_WORD},

	-- Placeholder for expandeddefines lists
	customhurt = 		{get=getCustomHurt, set=setCustomHurt, t=FIELD_BOOL},
	--Temporary kludge
	frames =			{get=getFrames, set=setFrames, t=FIELD_WORD},
	framespeed =		{get=getFrameSpeed, set=setFrameSpeed, t=FIELD_WORD},
	
	lightoffsetx =		{get=getlightoffsetx, set=setlightoffsetx},
	lightoffsety =		{get=getlightoffsety, set=setlightoffsety},
	lightradius =		{get=getlightradius, set=setlightradius},
	lightbrightness =	{get=getlightbrightness, set=setlightbrightness},
	lightcolor =		{get=getlightcolor, set=setlightcolor},
	lightflicker = 		{get=getlightflicker, set=setlightflicker},
	noshadows =			{get=getnoshadows, set=setnoshadows},

	-- For internal use only
	_cancollide =       {get=getcollidable, set=setcollidable}
	}

-- Deprecated aliases
local aliases = {
	sizeable = "sizable"
}

-- Externally-exposed list of all standard Block properties
blockconfig.properties = {}
for k,v in pairs(propertyTables) do
	table.insert(blockconfig.properties, k)
end
for k,v in pairs(aliases) do
	table.insert(blockconfig.properties, k)
end
table.sort(blockconfig.properties)
-- Map of the above
blockconfig.propertiesMap = table.map(blockconfig.properties)

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
		tbl.addr = Misc.__getBlockPropertyTableAddress(tbl.name)
	end
	
	-- Boolean field automatically get a casting encoder
	if (tbl.encoder == nil) and (tbl.t == FIELD_BOOL) then
		tbl.encoder = encodeBoolean
	end

	-- Fill in stride
	tbl.stride = fieldSizes[tbl.t]
end

-- Copy entries for aliaes
for alias,target in pairs(aliases) do
	propertyTables[alias] = propertyTables[target]
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
	for i = 1, BLOCK_MAX_ID do
		extraProperties[i] = {}
		extraTypes[i] = {}
		propsNextMap[i] = table.clone(standardPropsNextMap)
		unrecognizedTxtProperties[i] = {}
		nonDefaultProperties[i] = {}
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

-- Iterator for config objects
local function nextProp(t, k)
	local nextKey = propsNextMap[t.id][k]
	if nextKey ~= nil then
		return nextKey, t[nextKey]
	end
end

local function registerProperty(self, propName, propType)
	propName = escapeName(propName)
	if propName == "registerproperty" then
		error("Yo dawg, you can't register registerProperty as a property")
	elseif blockconfig.propertiesMap[propName] then
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
	if (not blockconfig.propertiesMap[propName]) and (extraTypes[self.id][propName] == nil) then
		registerProperty(self, propName, type(defaultValue))
	end
	
	-- If a property hasn't been set, try to set it
	if not nonDefaultProperties[self.id][propName] then
		self[propName] = defaultValue
		nonDefaultProperties[self.id][propName] = nil
	end
end

-- Function to load NPC configuration from files
function blockconfig.loadAllTxt()
	local configFileReader = require("configFileReader")

	for id = 1,BLOCK_MAX_ID do
		--setFrames(id, getFrames(id))
		local configFile = configFileReader.parseTxt("block-" .. id .. ".txt")
		if(configFile ~= nil) then
			for npcCode, npcValue in pairs(configFile) do
				npcCode = npcCode:lower()
				if blockconfig.propertiesMap[npcCode] or extraTypes[id][npcCode] then
					-- If a property is known, store it normally
					blockconfig[id][npcCode] = npcValue
				else
					-- Store txt properties we don't recognize in case we register them later
					unrecognizedTxtProperties[id][npcCode] = npcValue
				end
			end
		end
	end
end

-- Define metatable for handling
local npcmt = {
	__newindex = function (tbl, key, value)
		key = escapeName(key)
		if key == "registerproperty" then
			error("registerProperty is not a Block property, make no attempt to reassign it")
		end
		if key == "setdefaultproperty" then
			error("setDefaultProperty is not an Block property, make no attempt to reassign it")
		end
		local prop = propertyTables[key]
		if prop ~= nil then
			if prop.encoder ~= nil then
				value = prop.encoder(value)
			end
			
			local ov
			if prop.get ~= nil then
				ov = prop.get(tbl.id)
			else
				ov = readmem(prop.addr + prop.stride * tbl.id, prop.t)
			end
			
			if prop.decoder ~= nil then
				ov = prop.decoder(ov)
			end
			
			if prop.set ~= nil then
				prop.set(tbl.id, value)
			else
				writemem(prop.addr + prop.stride * tbl.id, prop.t, value)
			end
			
			if value ~= ov then
				EventManager.callEvent("onBlockConfigChange", tbl.id, key, value, ov)
			end
		else
			local propType = extraTypes[tbl.id][key]
			if propType == nil then
				error("Property " .. key .. " not registered for Block " .. tbl.id)
			elseif propType ~= type(value) then
				if propType == "boolean" then
					value = encodeBoolean(value)
				elseif propType == "number" then
					value = encodeNumber(value)
				elseif propType == "string" then
					value = tostring(value)
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
				EventManager.callEvent("onBlockConfigChange", tbl.id, key, value, ov)
			end
		end
		ed.setBlockProperty(tbl, key, value)
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
		if prop ~= nil then
			local value
			if prop.get ~= nil then
				value = prop.get(tbl.id)
			else
				value = readmem(prop.addr + prop.stride * tbl.id, prop.t)
			end
			if prop.decoder ~= nil then
				value = prop.decoder(value)
			end
			return value
		else
			return extraProperties[tbl.id][key]
		end
	end
}

-- Declare the blockconfig object itself
setmetatable(blockconfig, {
	__newindex = function (tbl, key, value)
		error("Cannot assign directly to Block config. Try assigning to a field instead.", 2)
	end,
	__index = function (tbl, key)
		if type(key) == "number" and key >= 1 and key <= BLOCK_MAX_ID then
			local val = {id = key}
			setmetatable(val, npcmt)
			rawset(tbl, key, val)
			return val
		else
			return nil
		end
	end
})


-- Reset to default values
local baseDefaultProps = {width=32, height=32, sizable=false, passthrough=false, pswitchable=false, lava=false, semisolid=false, floorslope=0, ceilingslope=0, _unk_muncherspike=0, _unk_lavarelated=false, lightoffsetx = 0, lightoffsety = 0, lightradius = 0, lightbrightness = 0, lightcolor = Color.alphablack, lightflicker = false}
local defaults = {}
defaults.width = {[21]=64, [22]=64, [34]=64, [35]=64, [36]=64, [37]=64, [61]=128, [78]=64, [91]=64, [92]=128, [93]=128, [103]=64, [104]=64, [113]=64, [114]=64, [125]=64, [137]=64, [138]=64, [139]=64, [140]=64, [141]=64, [142]=64, [143]=64, [144]=64, [145]=64, [146]=64, [182]=96, [184]=64, [185]=128, [187]=128, [194]=64, [195]=64, [196]=64, [197]=64, [206]=64, [224]=64, [225]=64, [226]=64, [262]=128, [301]=128, [302]=128, [303]=128, [304]=128, [306]=64, [308]=64, [312]=64, [314]=64, [319]=128, [320]=128, [321]=128, [322]=128, [324]=64, [325]=64, [336]=64, [338]=64, [340]=64, [342]=64, [357]=64, [360]=64, [361]=64, [364]=64, [365]=64, [366]=64, [367]=64, [368]=64, [378]=64, [472]=64, [474]=64, [476]=64, [479]=64, [505]=64, [506]=64, [507]=64, [508]=64, [527]=64, [534]=48, [535]=48, [536]=128, [537]=128, [540]=64, [571]=64, [572]=64, [599]=64, [604]=64, [605]=64, [613]=64, [615]=64, [616]=64, [617]=64, [634]=64, [636]=64, [638]=64, [691]=64, [1001]=64, [1002]=64, [1003]=64, [1004]=64, [1005]=64, [1031]=128, [1055]=64, [1056]=64, [1057]=64, [1076]=64, [1078]=64, [1082]=64, [1099]=96, [1100]=64, [1101]=64, [1110]=96, [1119]=64, [1121]=64, [1123]=64, [1125]=64, [1129]=64, [1130]=64, [1138]=64, [1140]=64, [1166]=64, [1167]=64, [1168]=64, [1169]=64, [1170]=64, [1180]=64, [1182]=64, [1205]=64, [1206]=64, [1207]=64, [1208]=64, [1215]=64, [1222]=64, [1223]=64, [1228]=64, [1230]=64, [1234]=64, [1235]=64, [1241]=64, [1246]=64, [1251]=64, [1258]=64, [1259]=64, [1260]=64, [1261]=64}
defaults.height = {[23]=64, [24]=64, [61]=128, [91]=64, [92]=128, [93]=128, [125]=64, [147]=64, [148]=64, [149]=64, [150]=64, [151]=64, [152]=64, [153]=64, [154]=64, [155]=64, [156]=64, [157]=64, [158]=64, [182]=96, [184]=64, [187]=128, [206]=64, [211]=64, [212]=64, [224]=64, [225]=64, [226]=64, [262]=128, [376]=64, [377]=64, [378]=64, [506]=64, [527]=96, [529]=64, [534]=128, [535]=128, [536]=48, [537]=48, [569]=64, [570]=64, [571]=64, [572]=64, [575]=64, [595]=64, [596]=64, [597]=64, [599]=64, [634]=64, [691]=64, [1001]=64, [1002]=64, [1003]=64, [1004]=64, [1005]=64, [1031]=128, [1063]=64, [1064]=64, [1065]=64, [1077]=64, [1079]=64, [1080]=64, [1081]=64, [1082]=64, [1106]=64, [1107]=64, [1108]=64, [1109]=64, [1110]=64, [1245]=64, [1246]=64, [1247]=64}
defaults.sizable = {[25]=true, [26]=true, [27]=true, [28]=true, [38]=true, [79]=true, [108]=true, [130]=true, [161]=true, [240]=true, [241]=true, [242]=true, [243]=true, [244]=true, [245]=true, [259]=true, [260]=true, [261]=true, [287]=true, [288]=true, [437]=true, [438]=true, [439]=true, [440]=true, [441]=true, [442]=true, [443]=true, [444]=true, [445]=true, [568]=true, [575]=true, [579]=true}
defaults.passthrough = {[172]=true, [175]=true, [178]=true, [181]=true, [665]=true}
defaults.pswitchable = {[4]=true, [60]=true, [89]=true, [188]=true, [280]=true, [293]=true}
defaults.lava = {[30]=true, [371]=true, [404]=true, [405]=true, [406]=true, [420]=true, [459]=true, [460]=true, [461]=true, [462]=true, [463]=true, [464]=true, [465]=true, [466]=true, [467]=true, [468]=true, [469]=true, [470]=true, [471]=true, [472]=true, [473]=true, [474]=true, [475]=true, [476]=true, [477]=true, [478]=true, [479]=true, [480]=true, [481]=true, [482]=true, [483]=true, [484]=true, [485]=true, [486]=true, [487]=true, [1268]=true}
defaults.semisolid = {[8]=true, [69]=true, [121]=true, [122]=true, [123]=true, [168]=true, [289]=true, [290]=true, [370]=true, [372]=true, [373]=true, [374]=true, [375]=true, [379]=true, [380]=true, [381]=true, [382]=true, [389]=true, [391]=true, [392]=true, [446]=true, [447]=true, [448]=true, [506]=true, [507]=true, [508]=true, [572]=true, [688]=true}
defaults.floorslope = {[299]=-1, [300]=1, [301]=1, [302]=-1, [305]=-1, [306]=-1, [307]=1, [308]=1, [315]=1, [316]=-1, [319]=1, [321]=-1, [324]=-1, [325]=1, [326]=-1, [327]=1, [332]=-1, [333]=1, [340]=-1, [341]=-1, [342]=1, [343]=1, [357]=-1, [358]=-1, [359]=1, [360]=1, [365]=-1, [366]=1, [451]=1, [452]=-1, [472]=-1, [474]=1, [480]=-1, [482]=1, [600]=-1, [601]=1, [604]=-1, [605]=1, [616]=-1, [617]=1, [635]=-1, [636]=-1, [637]=1, [638]=1}
defaults.ceilingslope = {[77]=1, [78]=1, [309]=1, [310]=-1, [311]=1, [312]=1, [313]=-1, [314]=-1, [317]=1, [318]=-1, [328]=-1, [329]=1, [334]=-1, [335]=1, [361]=1, [362]=1, [363]=-1, [364]=-1, [367]=-1, [368]=1, [476]=1, [479]=-1, [485]=-1, [486]=1, [523]=-1, [528]=1, [613]=-1, [614]=-1}
defaults._unk_muncherspike = {[109]=true, [110]=true, [267]=true, [268]=true, [269]=true, [407]=true, [408]=true, [428]=true, [429]=true, [430]=true, [431]=true, [511]=true, [598]=true}
defaults._unk_lavarelated = {[460]=true, [461]=true, [462]=true, [463]=true, [464]=true, [465]=true, [466]=true, [467]=true, [472]=true, [474]=true, [476]=true, [479]=true, [480]=true, [482]=true, [485]=true, [486]=true}
defaults.frames = {[4]=4, [5]=4, [30]=4, [55]=4, [88]=4, [109]=8, [169]=4, [170]=4, [173]=4, [176]=4, [179]=4, [193]=4, [322]=4, [371]=8, [379]=4, [380]=4, [381]=4, [382]=4, [389]=4, [391]=4, [392]=4, [404]=4, [458]=6, [459]=4, [460]=4, [461]=4, [462]=4, [463]=4, [464]=4, [465]=4, [466]=4, [468]=4, [469]=4, [470]=4, [471]=4, [472]=4, [474]=4, [475]=4, [476]=4, [477]=4, [478]=4, [479]=4, [480]=4, [481]=4, [482]=4, [483]=4, [484]=4, [485]=4, [486]=4, [487]=4, [511]=4, [530]=4, [536]=4, [598]=4, [623]=5, [624]=5, [625]=5, [626]=4, [627]=4, [628]=4, [631]=4, [632]=4}
defaults.lightoffsetx = {}
defaults.lightoffsety = {}
defaults.lightradius = {[30]=64, [193]=64, [371]=64, [404]=64, [405]=64, [406]=64, [420]=64, [459]=64, [460]=64, [461]=64, [462]=64, [463]=64, [464]=64, [465]=64, [466]=64, [467]=64, [468]=64, [469]=64, [470]=64, [471]=64, [472]=64, [473]=64, [474]=64, [475]=64, [476]=64, [477]=64, [478]=64, [479]=64, [480]=64, [481]=64, [482]=64, [483]=64, [484]=64, [485]=64, [486]=64, [487]=64, [530]=64, [539]=64, [598]=64, [682]=64, [683]=64, [1151]=64, [1268]=64}
defaults.lightbrightness = {[30]=1, [193]=0.5, [371]=1, [404]=1, [405]=1, [406]=1, [420]=1, [459]=1, [460]=1, [461]=1, [462]=1, [463]=1, [464]=1, [465]=1, [466]=1, [467]=1, [468]=1, [469]=1, [470]=1, [471]=1, [472]=1, [473]=1, [474]=1, [475]=1, [476]=1, [477]=1, [478]=1, [479]=1, [480]=1, [481]=1, [482]=1, [483]=1, [484]=1, [485]=1, [486]=1, [487]=1, [530]=0.5, [539]=0.5, [598]=1, [682]=0.25, [683]=0.5, [1151]=1, [1268]=1}
defaults.lightcolor = {[30]=Color.red, [193]=Color.white, [371]=Color.red, [404]=Color.red, [405]=Color.red, [406]=Color.red, [420]=Color.red, [459]=Color.red, [460]=Color.red, [461]=Color.red, [462]=Color.red, [463]=Color.red, [464]=Color.red, [465]=Color.red, [466]=Color.red, [467]=Color.red, [468]=Color.red, [469]=Color.red, [470]=Color.red, [471]=Color.red, [472]=Color.red, [473]=Color.red, [474]=Color.red, [475]=Color.red, [476]=Color.red, [477]=Color.red, [478]=Color.red, [479]=Color.red, [480]=Color.red, [481]=Color.red, [482]=Color.red, [483]=Color.red, [484]=Color.red, [485]=Color.red, [486]=Color.red, [487]=Color.red, [530]=Color.red, [539]=Color.red, [598]=Color.white, [682]=Color.red, [683]=Color.green, [1151]=Color.orange, [1268]=Color.red}
defaults.lightflicker = {[30]=true, [193]=false, [371]=true, [404]=true, [405]=false, [406]=false, [420]=false, [459]=true, [460]=true, [461]=true, [462]=true, [463]=true, [464]=true, [465]=true, [466]=true, [467]=false, [468]=true, [469]=true, [470]=true, [471]=true, [472]=true, [473]=true, [474]=true, [475]=true, [476]=true, [477]=true, [478]=true, [479]=true, [480]=true, [481]=true, [482]=true, [483]=true, [484]=true, [485]=true, [486]=true, [487]=true, [530]=false, [539]=false, [598]=false, [682]=false, [683]=false, [1151]=false, [1268]=true}

for prop,default in pairs(baseDefaultProps) do
	local deftable = defaults[prop]
	for i=1,BLOCK_MAX_ID do
		local val = default
		if deftable[i] ~= nil then
			val = deftable[i]
		end
		blockconfig[i][prop] = val
	end
end

local blockAnimation = {}

local timerOffset = readmem(0x00B2BEBC,FIELD_DWORD)
local frameOffset = readmem(0x00B2BEA0,FIELD_DWORD)

function blockAnimation.onDraw()
	for k,i in ipairs(getIDsWithMultipleFrames()) do
		local cfg = Block.config[i]
        local timerLoc = timerOffset+(2*(i-1));
        local frameLoc = frameOffset+(2*(i-1));
        writemem(timerLoc,FIELD_WORD,readmem(timerLoc,FIELD_WORD)-1);
        if(readmem(timerLoc,FIELD_WORD) <= 0) then
            writemem(frameLoc,FIELD_WORD,(readmem(frameLoc,FIELD_WORD)+1)%cfg.frames);
            writemem(timerLoc,FIELD_WORD,cfg.framespeed)
        end
    end
end

function blockAnimation.onTickEnd()
	blockutils.resolveSwitchQueue()
end

if Block ~= nil then
	registerEvent(blockAnimation, "onTickEnd")
	registerEvent(blockAnimation, "onDraw")
end

-- Patch in a 'config' member variable in the Block namespace
if(Block == nil) then
	_G.Block = {};
end
Block.config = blockconfig

return blockconfig
