local readmem = _G.readmem
local writemem = _G.writemem
local load = load
local error = error
local ffi_utils = {}

------------------
-- UTILITY CODE --
------------------

local ffi = ffi
local function makeSealedTable (table)
   local new = {}
   for k, v in pairs(table) do
      new[k] = v
   end
   local t = ffi.typeof("struct {}")
   ffi.metatype(t, {__index = new})
   return ffi.new(t)
end

function ffi_utils.earlyWarnCall(tbl, tblname, funcname, func)
	tbl[funcname] = function(...)
		if EventManager.onStartRan then
			tbl[funcname] = func
			return tbl[funcname](...)
		else
			Misc.warn("Improperly calling " .. tblname .. "." .. funcname .. " before onStart", 1)
			return func(...)
		end
	end
end

local function getFactory2(className, fieldName, metadata, classValidityChecker)
	-- Shortcut when 'get' is good enough
	if (metadata.alwaysValid) and (metadata.get) then
		return metadata.get
	end
	
	local fnName = "get_" .. fieldName
	
	local code = [[
	local classValidityChecker = classValidityChecker
	local get = metadata.get or false
	local decoder = metadata.decoder or false
	local readmem = readmem
	local error = error
	
	local function ]] .. fnName .. [[(obj)
	]]
	
	if (not metadata.alwaysValid) then
		code = code .. [[
			if (not classValidityChecker(obj)) then
				error("Invalid ]] .. className .. [[ object")
			end
		]]
	end
	
	if (metadata.get) then
		code = code .. [[
			local ret = get(obj)
		]]
	else
		code = code .. [[
			local ret = readmem(obj._ptr + ]] .. tostring(metadata[1]) .. [[, ]] .. tostring(metadata[2]) .. [[)
		]]
	end
	
	if (metadata.decoder) then
		code = code .. [[
			ret = decoder(ret)
		]]
	end
	
	code = code .. [[
		return ret
	end
	
	return ]] .. fnName .. [[
	]]
	
	local chunk = load(code, "=!" .. className .. ":" .. fieldName, "t", {
		metadata=metadata,
		classValidityChecker=classValidityChecker,
		readmem=readmem,
		error=error
	})
	
	return chunk()
end

local function indexfactory(className, classTbl, getters)
	local code = [[
	local classTbl = classTbl
	local getters = getters
	]]
	
	code = code .. [[
	local function __index(obj, key)
	]]
	
	for k,_ in pairs(getters) do
		code = code .. [[
		if key == "]] .. k .. [[" then
			return getters.]] .. k .. [[(obj)
		end
		]]
	end
	
	code = code .. [[
		return classTbl[key]
	end
	
	return __index
	]]
	
	local chunk, err = load(code, "=!" .. className, "t", {
		classTbl=classTbl,
		getters=makeSealedTable(getters),
	})
	
	return chunk()
end

function ffi_utils.implementClassMT(className, classTbl, classFields, classValidityChecker)
	
	-- Create the class metatable
	local classMT = {__type=className}
	
	local getters = {}
	for k,v in pairs(classFields) do
		getters[k] = getFactory2(className, k, v, classValidityChecker)
	end
	
	classMT.__index = indexfactory(className, classTbl, getters)

	classMT.__newindex = function(obj, key, val)
		-- Instance fields
		local metadata = classFields[key]
		if (metadata ~= nil) then
			if metadata.readonly then
				error("Field '" .. tostring(key) .. "' in " .. className .. " object is read-only")
			end
			
			if (not metadata.alwaysValid) and (not classValidityChecker(obj)) then
				error("Invalid " .. className .. " object")
			end
			
			if metadata.encoder then
				val = metadata.encoder(val)
			end
			
			if metadata.set then
				metadata.set(obj, val)
			else
				writemem(obj._ptr + metadata[1], metadata[2], val)
			end
			
		else
			-- Set in object
			rawset(obj, key, val)
		end
	end

	return classMT
end

return ffi_utils