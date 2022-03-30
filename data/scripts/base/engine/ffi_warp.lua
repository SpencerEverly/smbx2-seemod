local LegacyWarp = Warp
local mem = mem
local ffi_utils = require("ffi_utils")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_WARP_ADDR = mem(0x00B258F4, FIELD_DWORD)
local GM_WARP_COUNT_ADDR = 0x00B258E2

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function warpGetIdx(warp)
	return warp._idx
end

local function warpGetIsValid(warp)
	local idx = warp._idx
	
	if (idx >= 0) and (idx < mem(GM_WARP_COUNT_ADDR, FIELD_WORD)) then
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

local function warpGetSectionExit(w)
	return Section.getIdxFromCoords(w.exitX, w.exitY, w.exitWidth, w.exitHeight)
end

local function warpGetSectionEntrance(w)
	return Section.getIdxFromCoords(w.entranceX, w.entranceY, w.entranceWidth, w.entranceHeight)
end

------------------------
-- FIELD DECLERATIONS --
------------------------
local WarpFields = {
	idx       = {get=warpGetIdx, readonly=true, alwaysValid=true},
	isValid   = {get=warpGetIsValid, readonly=true, alwaysValid=true},
	
	locked            = {0x00, FIELD_BOOL},
	allowItems 		  = {0x02, FIELD_BOOL},
	noYoshi           = {0x04, FIELD_BOOL},
	layer             = {0x08, FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
	layerName         = {0x08, FIELD_STRING},
	isHidden          = {0x0C, FIELD_BOOL},
	starsRequired     = {0x12, FIELD_WORD},
	entranceX         = {0x14, FIELD_DFLOAT},
	entranceY         = {0x1C, FIELD_DFLOAT},
	entranceHeight    = {0x24, FIELD_DFLOAT},
	entranceWidth     = {0x2C, FIELD_DFLOAT},
	entranceSpeedX    = {0x34, FIELD_DFLOAT},
	entranceSpeedY    = {0x3C, FIELD_DFLOAT},
	exitX             = {0x44, FIELD_DFLOAT},
	exitY             = {0x4C, FIELD_DFLOAT},
	exitHeight        = {0x54, FIELD_DFLOAT},
	exitWidth         = {0x5C, FIELD_DFLOAT},
	exitSpeedX        = {0x64, FIELD_DFLOAT},
	exitSpeedY        = {0x6C, FIELD_DFLOAT},
	warpType          = {0x74, FIELD_WORD},
	levelFilename     = {0x78, FIELD_STRING},
	warpNumber        = {0x7C, FIELD_WORD},
	toOtherLevel      = {0x84, FIELD_BOOL},
	fromOtherLevel    = {0x7E, FIELD_BOOL},
	entranceDirection = {0x80, FIELD_WORD},
	exitDirection     = {0x82, FIELD_WORD},
	worldMapX         = {0x86, FIELD_WORD},
	worldMapY         = {0x88, FIELD_WORD},
	
	entranceSection	  = {get=warpGetSectionEntrance, readonly = true},
	exitSection		  = {get=warpGetSectionExit, readonly = true},
	
	--Deprecated
	allowCarriedNPCs  = {0x02, FIELD_BOOL},
	isLevelEntrance   = {0x7E, FIELD_BOOL},
	isLevelExit       = {0x84, FIELD_BOOL},
}

-----------------------
-- CLASS DECLERATION --
-----------------------

local Warp = {__type="Warp"}
local WarpMT = ffi_utils.implementClassMT("Warp", Warp, WarpFields, warpGetIsValid)
local WarpCache = {}

-- Constructor
setmetatable(Warp, {__call=function(Warp, idx)
	if WarpCache[idx] then
		return WarpCache[idx]
	end
	
	local warp = {_idx=idx, _ptr=GM_WARP_ADDR + idx*0x90}
	setmetatable(warp, WarpMT)
	WarpCache[idx] = warp
	return warp
end})

-------------------------
-- METHOD DECLERATIONS --
-------------------------

-- 'mem' implementation
function Warp:mem(offset, dtype, val)
	if not warpGetIsValid(self) then
		error("Invalid warp object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

--------------------
-- STATIC METHODS --
--------------------

function Warp.count()
	return mem(GM_WARP_COUNT_ADDR, FIELD_WORD)
end

local getMT = {__pairs = ipairs}

function Warp.get()
	local ret = {}
	
	for idx=0,Warp.count()-1 do
		ret[#ret+1] = Warp(idx)
	end
	
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Warp, "Warp", "get", Warp.get)

local function getIntersecting(x1, y1, x2, y2, entrance)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end

	local x, y, width, height
	if entrance then
		x = "entranceX"
		y = "entranceY"
		width = "entranceWidth"
		height = "entranceHeight"
	else
		x = "exitX"
		y = "exitY"
		width = "exitWidth"
		height = "exitHeight"
	end
	
	local ret = {}
	for idx=0,Warp.count()-1 do
		local warp = Warp(idx)
		if ((x2 > warp[x]) and
		    (y2 > warp[y]) and
		    (warp[x] + warp[width] > x1) and
		    (warp[y] + warp[height] > y1)) then
			ret[#ret+1] = warp
		end
	end
	setmetatable(ret, getMT)
	return ret
end

function Warp.getIntersectingEntrance(x1, y1, x2, y2)
	return getIntersecting(x1, y1, x2, y2, true)
end
ffi_utils.earlyWarnCall(Warp, "Warp", "getIntersectingEntrance", Warp.getIntersectingEntrance)

function Warp.getIntersectingExit(x1, y1, x2, y2)
	return getIntersecting(x1, y1, x2, y2, false)
end
ffi_utils.earlyWarnCall(Warp, "Warp", "getIntersectingExit", Warp.getIntersectingExit)

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Warp = Warp
return Warp
