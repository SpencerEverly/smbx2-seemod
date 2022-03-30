local mem = mem
local ffi_utils = require("ffi_utils")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_LIQUID_ADDR = mem(0x00B256F4, FIELD_DWORD)
local GM_LIQUID_COUNT_ADDR = 0x00B25700

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function liquidGetCount()
	return readmem(GM_LIQUID_COUNT_ADDR, FIELD_WORD)
end

local function liquidGetIdx(liquid)
	return liquid._idx
end

local function liquidGetIsValid(liquid)
	local idx = liquid._idx

	if (idx >= 0) and (idx <= liquidGetCount()) then
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

------------------------
-- FIELD DECLARATIONS --
------------------------
local LiquidFields = {
	idx         = {get=liquidGetIdx, readonly=true, alwaysValid=true},
	isValid     = {get=liquidGetIsValid, readonly=true, alwaysValid=true},

	layer       = {0x00, FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
	layerName   = {0x00, FIELD_STRING},
	isHidden    = {0x04, FIELD_BOOL},
	isQuicksand = {0x0C, FIELD_BOOL},
	x           = {0x10, FIELD_DFLOAT},
	y           = {0x18, FIELD_DFLOAT},
	height      = {0x20, FIELD_DFLOAT},
	width       = {0x28, FIELD_DFLOAT},
	speedX      = {0x30, FIELD_DFLOAT},
	speedY      = {0x38, FIELD_DFLOAT}
}

-----------------------
-- CLASS DECLARATION --
-----------------------
local Liquid = {}
local LiquidMT = ffi_utils.implementClassMT("Liquid", Liquid, LiquidFields, liquidGetIsValid)
local LiquidCache = {}

-- Constructor
setmetatable(Liquid, {__call = function(Liquid, idx)
	if LiquidCache[idx] then
		return LiquidCache[idx]
	end

	local liquid = {_idx = idx, _ptr = GM_LIQUID_ADDR + idx*0x40}
	setmetatable(liquid, LiquidMT)
	LiquidCache[idx] = liquid
	return liquid
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function Liquid:mem(offset, dtype, val)
	if not liquidGetIsValid(self) then
		error("Invalid Liquid object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

--------------------
-- STATIC METHODS --
--------------------
function Liquid.count()
	return liquidGetCount()
end

local getMT = {__pairs = ipairs}

function Liquid.get()
	local ret = {}
	for idx=1,liquidGetCount() do
		ret[#ret+1] = Liquid(idx)
	end
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Liquid, "Liquid", "get", Liquid.get)

function Liquid.getIntersecting(x1, y1, x2, y2)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end
	
	local ret = {}
	local ptr = GM_LIQUID_ADDR + 0x40
	for idx=1,liquidGetCount() do
		local bx = mem(ptr + 0x10, FIELD_DFLOAT)
		if (x2 > bx) then
			local by = mem(ptr + 0x18, FIELD_DFLOAT)
			if (y2 > by) then
				local bw = mem(ptr + 0x28, FIELD_DFLOAT)
				if (bx + bw > x1) then
					local bh = mem(ptr + 0x20, FIELD_DFLOAT)
					if (by + bh > y1) then
						ret[#ret+1] = Liquid(idx)
					end
				end
			end
		end
		ptr = ptr + 0x40
	end
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Liquid, "Liquid", "getIntersecting", Liquid.getIntersecting)

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Liquid = Liquid
return Liquid
