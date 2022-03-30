local mem = mem
local ffi_utils = require("ffi_utils")

-- 
ffi.cdef([[
void LunaLuaSetBGORenderFlag(bool val);
]])
local LunaDLL = ffi.load("LunaDll.dll")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_BGO_ADDR = readmem(0x00B259B0, FIELD_DWORD)
local GM_BGO_COUNT_ADDR = 0x00B25958
local GM_BGO_LOCK_COUNT_ADDR = 0x00B250D6
local BGO_STRUCT_SIZE = 0x38

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function bgoGetCount()
	return readmem(GM_BGO_COUNT_ADDR, FIELD_WORD) + readmem(GM_BGO_LOCK_COUNT_ADDR, FIELD_WORD)
end

local function bgoGetIdx(bgo)
	return bgo._idx
end

local function bgoGetIsValid(bgo)
	local idx = bgo._idx
	
	if (idx >= 0) and (idx < bgoGetCount()) then
		return true
	end
	
	return false
end

local function layerNameToLayerObj(layerName)
	if (layerName == "") then return Layer(Layer.count()) end
	return Layer.get(layerName)
end

local function layerObjToLayerName(layerObj)
	if (layerObj == nil) then
		return ""
	end
	return layerObj.layerName
end

local function getBGOLight(bgo)
	local darkdata = bgo.data._basegame._darkness
	if darkdata and darkdata[2] then
		return darkdata[2]
	end
	return nil
end

local function setBGOLight(bgo, value)	
	local darkdata = bgo.data._basegame._darkness
	if darkdata then
		if darkdata[2] and darkdata[2] ~= value then
			darkdata[2]:destroy()
		end
	
		darkdata[2] = value
	else
		bgo.data._basegame._darkness = { bgo.id, value }
	end
end

------------------------
-- FIELD DECLERATIONS --
------------------------
local BGOFields = {
		idx       	= {get=bgoGetIdx, readonly=true, alwaysValid=true},
		isValid  	= {get=bgoGetIsValid, readonly=true, alwaysValid=true},
		
		lightSource = {get=getBGOLight, set=setBGOLight},
		
		layer     	= {0x00, FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
		layerObj  	= {0x00, FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
		layerName 	= {0x00, FIELD_STRING},
		isHidden  	= {0x04, FIELD_BOOL},
		id        	= {0x06, FIELD_WORD},
		x         	= {0x08, FIELD_DFLOAT},
		y         	= {0x10, FIELD_DFLOAT},
		height    	= {0x18, FIELD_DFLOAT},
		width     	= {0x20, FIELD_DFLOAT},
		speedX    	= {0x28, FIELD_DFLOAT},
		speedY    	= {0x30, FIELD_DFLOAT}
}

-----------------------
-- CLASS DECLERATION --
-----------------------

local BGO = {__type="BGO"}
local BGOMT = ffi_utils.implementClassMT("BGO", BGO, BGOFields, bgoGetIsValid)
local BGOCache = {}

-- Constructor
setmetatable(BGO, {__call=function(BGO, idx)
	if BGOCache[idx] then
		return BGOCache[idx]
	end
	
	local bgo = {_idx=idx, _ptr=GM_BGO_ADDR + idx*0x38, data = {_basegame = {}, _settings = BGO.makeDefaultSettings(readmem(GM_BGO_ADDR + idx*BGO_STRUCT_SIZE + 0x06,  FIELD_WORD)) }}
	setmetatable(bgo, BGOMT)
	BGOCache[idx] = bgo
	return bgo
end})

-------------------------
-- METHOD DECLERATIONS --
-------------------------

-- 'mem' implementation
function BGO:mem(offset, dtype, val)
	if not bgoGetIsValid(self) then
		error("Invalid BGO object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

--------------------
-- STATIC METHODS --
--------------------

function BGO.count()
	return bgoGetCount()
end

local getMT = {__pairs = ipairs}

function BGO.get(idFilter)
	local ret = {}
	
	if (idFilter == nil) then
		for idx=0,bgoGetCount()-1 do
			ret[#ret+1] = BGO(idx)
		end
	elseif (type(idFilter) == "number") then
		local ptr = GM_BGO_ADDR + 0x06
		for idx=0,bgoGetCount()-1 do
			if (readmem(ptr, FIELD_WORD) == idFilter) then
				ret[#ret+1] = BGO(idx)
			end
			ptr = ptr + 0x38
		end
	elseif (type(idFilter) == "table") then
		local lookup = {}
		for _,id in ipairs(idFilter) do
			lookup[id] = true
		end
		
		local ptr = GM_BGO_ADDR + 0x06
		for idx=0,bgoGetCount()-1 do
			if lookup[readmem(ptr, FIELD_WORD)] then
				ret[#ret+1] = BGO(idx)
			end
			ptr = ptr + 0x38
		end
	else
		error("Invalid parameters to get")
	end
	
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(BGO, "BGO", "get", BGO.get)

function BGO:transform(newID, centered)
	local x = self.x
	local y = self.y
	if centered == nil then
		centered = true
	end
		
	local cfg = BGO.config[newID]
	if centered then
		x = x+self.width*0.5
		y = y+self.height
	end	
	
	self.id = newID
	
	--set the physical width and height
	local w = cfg.width
	local h = cfg.height
	
	self.width = w
	self.height = h
	
	if centered then
		x = x-w*0.5
		y = y-h
	end
	
	--Destroy lights associated with this BGO
	local darkdata = self.data._basegame._darkness
	if darkdata and darkdata[2] then
		darkdata[2]:destroy()
	end
	
	--Reset _basegame table for re-initialisation.
	self.data._basegame = {}
		
	local gsettings = self.data._settings._global
	--Update _settings table with a table of default values
	self.data._settings = BGO.makeDefaultSettings(newID)
	self.data._settings._global = gsettings
end

function BGO.getIntersecting(x1, y1, x2, y2)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end
	
	local ret = {}
	local ptr = GM_BGO_ADDR
	for idx=0,bgoGetCount()-1 do
		local bx = readmem(ptr + 0x08, FIELD_DFLOAT)
		if (x2 > bx) then
			local by = readmem(ptr + 0x10, FIELD_DFLOAT)
			if (y2 > by) then
				local bw = readmem(ptr + 0x20, FIELD_DFLOAT)
				if (bx + bw > x1) then
					local bh = readmem(ptr + 0x18, FIELD_DFLOAT)
					if (by + bh > y1) then
						ret[#ret+1] = BGO(idx)
					end
				end
			end
		end
		ptr = ptr + 0x38
	end
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(BGO, "BGO", "getIntersecting", BGO.getIntersecting)

-- Iterator for filtering by id 
 local function iteratewithid(id, i)
	local count = bgoGetCount()
	while(i < count) do
		if readmem(GM_BGO_ADDR + 0x06 + (BGO_STRUCT_SIZE * i), FIELD_WORD) == id then
			return i + 1, BGO(i)
		end
		i = i + 1
	end
 end

 -- Iterator with no filter
local function iterate(_, i)
	local count = bgoGetCount()
	if (i < count) then
		return i + 1, BGO(i)
	end
end

-- Iterator for filtering by map
local function iteratewithfilter(tbl, i)
	local count = bgoGetCount()
	while(i < count) do
		if tbl[readmem(GM_BGO_ADDR + 0x06 + (BGO_STRUCT_SIZE * i), FIELD_WORD)] then
			return i + 1, BGO(i)
		end
		i = i + 1
	end
 end
 
function BGO.iterateByFilterMap(filterMap)
	if (type(filterMap) ~= "table") then
		error("Invalid parameters to iterateByFilterMap",2)
	end
	return iteratewithfilter, filterMap, 0
end
ffi_utils.earlyWarnCall(BGO, "BGO", "iterateByFilterMap", BGO.iterateByFilterMap)

function BGO.iterate(args)
	if(args == nil or args == -1) then
		return iterate, nil, 0
	elseif(type(args) == "number" and args ~= -1) then
		return iteratewithid, args, 0
	elseif(type(args) == "table") then
		return iteratewithfilter, tablemap(args), 0
	else
		error("Invalid parameters to iterate", 2)
	end
end
ffi_utils.earlyWarnCall(BGO, "BGO", "iterate", BGO.iterate)

function BGO.getByFilterMap(filterMap)
	local ret = {}
	
	if (type(filterMap) ~= "table") then
		error("Invalid parameters to getByFilterMap")
	end
	
	local ptr = GM_BGO_ADDR + 0x06
	for idx=0,bgoGetCount()-1 do
		if filterMap[readmem(ptr, FIELD_WORD)] then
			ret[#ret+1] = BGO(idx)
		end
		ptr = ptr + BGO_STRUCT_SIZE
	end
	
	setmetatable(ret, getMT)	
	return ret
end
ffi_utils.earlyWarnCall(BGO, "BGO", "getByFilterMap", BGO.getByFilterMap)

local function iterateintersecting(args, i)
	while i < args[5] do
		local ptr = GM_BGO_ADDR + (BGO_STRUCT_SIZE * i);
		
		local bx = readmem(ptr + 0x08, FIELD_DFLOAT)
		if (args[3] > bx) then
			local by = readmem(ptr + 0x10, FIELD_DFLOAT)
			if (args[4] > by) then
				local bw = readmem(ptr + 0x20, FIELD_DFLOAT)
				if (bx + bw > args[1]) then
					local bh = readmem(ptr + 0x18, FIELD_DFLOAT)
					if (by + bh > args[2]) then
						return i + 1, BGO(i)
					end
				end
			end
		end
		i = i + 1
	end
end

function BGO.iterateIntersecting(x1, y1, x2, y2)
	local bgoiterator = {x1, y1, x2, y2, bgoGetCount()}
	return iterateintersecting, bgoiterator, 0
end
ffi_utils.earlyWarnCall(BGO, "BGO", "iterateIntersecting", BGO.iterateIntersecting)

function BGO._SetVanillaBGORenderFlag(val)
	LunaDLL.LunaLuaSetBGORenderFlag(val)
end

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.BGO = BGO
return BGO
