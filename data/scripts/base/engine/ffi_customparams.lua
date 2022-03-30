----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
	// Getting all customsparams for the loaded level
    const char*  LunaLuaGetLevelCustomParams(void);
    const char** LunaLuaGetSectionCustomParams(void);
    const char** LunaLuaGetNpcCustomParams(void);
    const char** LunaLuaGetBgoCustomParams(void);
    const char** LunaLuaGetBlockCustomParams(void);
	
	// Getting default customparams
    const char* LunaLuaGetDefaultLevelCustomParams(void);
    const char* LunaLuaGetDefaultSectionCustomParams(void);
    const char* LunaLuaGetDefaultNpcCustomParams(unsigned int id);
    const char* LunaLuaGetDefaultBgoCustomParams(unsigned int id);
    const char* LunaLuaGetDefaultBlockCustomParams(unsigned int id);
]]
local LunaDLL = ffi.load("LunaDll.dll")

local ffi_customparams = {}

---------------------
-- Processing Code --
---------------------

local typeRegister = {}
local typelist = {}

local function registerType(name, func)
	table.insert(typelist, name)
	typeRegister[name] = func
end

local function parseTypes(params)
	if params.__type then
		for _,v in ipairs(typelist) do
			if params.__type[v] then
				for _,w in ipairs(params.__type[v]) do
					local p = params
					local parent = nil
					local field = nil
					for _,x in ipairs(w) do
						parent = p
						field = x
						p = p[x]
						if p == nil then break end
					end
					if p ~= nil and parent ~= nil and field ~= nil then
						parent[field] = typeRegister[v](p)
					end
				end
			end
		end
		params.__type = nil
	end
end

local function parseParams(parsedParams)
	-- Format the local and global data tables in the expected way
	if parsedParams["local"] ~= nil then
		parseTypes(parsedParams["local"])
		parsedParams["local"]._global = parsedParams.global
		parsedParams = parsedParams["local"]
	else
		parsedParams._global = parsedParams.global
		parsedParams.global = nil
	end
					
	parsedParams._global = parsedParams._global or {}
	parseTypes(parsedParams._global)
					
	return parsedParams
end

local function processObjectParams(params, class, idx)
	if (params ~= nil) then
		-- We have a parameter for this NPC
		params = ffi.string(params)

		-- Use lunajson to decode
		local parsedParams
		pcall(function () parsedParams = json.decode(params) end)

		-- If we parsed correctly put in the data
		if parsedParams ~= nil then
			class(idx).data._settings = parseParams(parsedParams)
		end
	end
end

local function processObjectParamsSimple(v, params)
	if (params ~= nil) then
		-- We have a parameter for this Section
		params = ffi.string(params)
		-- Use lunajson to decode
		local parsedParams
		pcall(function () parsedParams = json.decode(params) end)

		-- If we parsed correctly put in the data
		if parsedParams ~= nil then
			parseTypes(parsedParams)
			v.settings = parsedParams
		else
			v.settings = {}
		end
	else
		v.settings = {}
	end
end

function ffi_customparams.onStart()

	-- Register types that need lua-side parsing
	registerType("color", Color.parse)
	registerType("point", function(obj) return vector.v2(obj.x, obj.y) end)
	registerType("rect", function(obj) return { left = obj.x, right = obj.x + obj.w, top = obj.y, bottom = obj.y + obj.h } end)

	-- Read in custom parameters for NPCs
	local npcCustomParams = LunaDLL.LunaLuaGetNpcCustomParams()
	for i = 0,NPC.count()-1 do
		processObjectParams(npcCustomParams[i], NPC, i)
	end

	-- Read in custom parameters for BGOs
	local bgoCustomParams = LunaDLL.LunaLuaGetBgoCustomParams()
	for i = 1,BGO.count() do
		processObjectParams(bgoCustomParams[i-1], BGO, i)
	end

	-- Read in custom parameters for blocks
	local blockCustomParams = LunaDLL.LunaLuaGetBlockCustomParams()
	for i = 1,Block.count() do
		processObjectParams(blockCustomParams[i-1], Block, i)
	end
	
	-- Read in custom parameters for levels
	local levelCustomParams = LunaDLL.LunaLuaGetLevelCustomParams()
	processObjectParamsSimple(Level, levelCustomParams)
	
	-- Read in custom parameters for sections
	local sectionCustomParams = LunaDLL.LunaLuaGetSectionCustomParams()
	for i = 0,20 do
		processObjectParamsSimple(Section(i), sectionCustomParams[i])
	end
end

function ffi_customparams.onNPCGenerated(generatorNpc, generatedNpc)
	-- Copy settings from generator
	generatedNpc.data._settings = table.deepclone(generatorNpc.data._settings)
end

local function makeDefaultSettingsFactory(getterFuncName)
	local cache = {}
	local function makeDefaultSettings(id)
		local parsedParams = cache[id]
		if parsedParams == nil then
			-- Wasn't cached, get new values
			params = LunaDLL[getterFuncName](id)
			if params ~= nil then
				params = ffi.string(params)
				-- Special case for "no params provided"
				if params ~= "{\"global\":null,\"local\":null}" then
					pcall(function () parsedParams = json.decode(params) end)
					if parsedParams ~= nil then
						parsedParams = parseParams(parsedParams)
					end
				end
			end
			if parsedParams == nil then
				parsedParams = false
			end
			cache[id] = parsedParams
		end
		
		if parsedParams == false then
			-- False means no params whatsoever, so just build the table directly
			return {_global = {}}
		else
			-- Return deep clone of the default parameters so the cache is untouched
			return table.deepclone(parsedParams)
		end
	end
	return makeDefaultSettings
end

local function makeDefaultSettingsSimpleFactory(getterFuncName)
	local parsedParams = nil
	local function makeDefaultSettings()
		if parsedParams == nil then
			-- Wasn't cached, get new values
			params = LunaDLL[getterFuncName]()
			if params ~= nil then
				params = ffi.string(params)
				pcall(function () parsedParams = json.decode(params) end)
				if parsedParams ~= nil then
					parseTypes(parsedParams)
				end
			end
			if parsedParams == nil then
				parsedParams = {} 
			end
		end
		
		-- Return deep clone of the default parameters so the cache is untouched
		return table.deepclone(parsedParams)
	end
	return makeDefaultSettings
end

Level.makeDefaultSettings   = makeDefaultSettingsSimpleFactory('LunaLuaGetDefaultLevelCustomParams')
Section.makeDefaultSettings = makeDefaultSettingsSimpleFactory('LunaLuaGetDefaultSectionCustomParams')
NPC.makeDefaultSettings     = makeDefaultSettingsFactory('LunaLuaGetDefaultNpcCustomParams')
BGO.makeDefaultSettings     = makeDefaultSettingsFactory('LunaLuaGetDefaultBgoCustomParams')
Block.makeDefaultSettings   = makeDefaultSettingsFactory('LunaLuaGetDefaultBlockCustomParams')

-- Register for a nice early onStart event
registerEvent(ffi_customparams, "onStart", "onStart", true)

-- Register onNPCGenerated for copying settings from generators to children
registerEvent(ffi_customparams, "onNPCGenerated", "onNPCGenerated", true)

return ffi_customparams
