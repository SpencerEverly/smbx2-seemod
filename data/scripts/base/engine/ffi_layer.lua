local mem = mem
local ffi_utils = require("ffi_utils")

----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
void LunaLuaShowLayer(short layerIndex, bool noSmoke);
void LunaLuaHideLayer(short layerIndex, bool noSmoke);
]]
local LunaDLL = ffi.load("LunaDll.dll")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_LAYER_ADDR = mem(0x00B2C6B0, FIELD_DWORD)

local MAX_LAYERS = 255

local GM_BLOCK_ADDR = mem(0xB25A04, FIELD_DWORD)

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function layerGetCount()
	for idx=0,MAX_LAYERS-1 do
		if readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_DWORD) == 0 or #readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING) == 0 then 
			return idx
		end
	end
	return 0
end

local function layerGetIsValid(layer)
	return layer._idx >= 0 and layer._idx < MAX_LAYERS
end

local function layerGetIdx(layer)
	return layer._idx
end

local function layerUpdateContents(layer)
	--If both speeds are set to 0
	--Note: While we set the pauseDuringEffect flag, we don't check it, because neither does the core game code
	--      and it never really was a "moving" flag to begin with. More a flag to indicate if the layer needed to
	--      get paused when certain effects occur.
	if readmem(GM_LAYER_ADDR+layer._idx*0x14+0x0C, FIELD_FLOAT) == 0 and readmem(GM_LAYER_ADDR+layer._idx*0x14+0x10, FIELD_FLOAT) == 0 then
		writemem(GM_LAYER_ADDR+layer._idx*0x14+0x00, FIELD_BOOL, false)
		
		local n = readmem(GM_LAYER_ADDR+layer._idx*0x14+0x04, FIELD_STRING)
		
		--Stop all blocks attached to this layer
		local ptr = GM_BLOCK_ADDR
		for idx=1,Block.count() do
			ptr = ptr + 0x68
			--Check layer name matches
			if readmem(ptr + 0x18, FIELD_STRING) == n then
				--Set speedX and speedY to 0
				writemem(ptr + 0x40, FIELD_DFLOAT, 0)
				writemem(ptr + 0x48, FIELD_DFLOAT, 0)
			end
		end
		
		--Stop all vine and grass NPCS
		
		--This is a faster way to do a config and ID check than a full NPC.get loop
		local l = {91}
		for _,v in ipairs(NPC.VINE) do
			l[#l+1] = v
		end
		
		--Set NPC speeds to 0 if the layer name matches
		for _,v in ipairs(NPC.get(l)) do
			if v.layerName == n then
				v:mem(0x98, FIELD_DFLOAT, 0)
				v:mem(0xA0, FIELD_DFLOAT, 0)
			end
		end
	else -- Update pauseDuringEffect flag if either layer is moving
		writemem(GM_LAYER_ADDR+layer._idx*0x14+0x00, FIELD_BOOL, true)
	end
end

local function layerGetSpeedX(layer)
	return readmem(GM_LAYER_ADDR+layer._idx*0x14+0x0C, FIELD_FLOAT)
end

local function layerSetSpeedX(layer, value)
	local old = readmem(GM_LAYER_ADDR+layer._idx*0x14+0x0C, FIELD_FLOAT)
	if old ~= value then
		writemem(GM_LAYER_ADDR+layer._idx*0x14+0x0C, FIELD_FLOAT, value)
		if value == 0 then
			layerUpdateContents(layer)
		else
			-- Update pauseDuringEffect flag if either layer is moving
			writemem(GM_LAYER_ADDR+layer._idx*0x14+0x00, FIELD_BOOL, true)
		end
	end
end

local function layerGetSpeedY(layer)
	return readmem(GM_LAYER_ADDR+layer._idx*0x14+0x10, FIELD_FLOAT)
end

local function layerSetSpeedY(layer, value)
	local old = readmem(GM_LAYER_ADDR+layer._idx*0x14+0x10, FIELD_FLOAT)
	if old ~= value then
		writemem(GM_LAYER_ADDR+layer._idx*0x14+0x10, FIELD_FLOAT, value)
		if value == 0 then
			layerUpdateContents(layer)
		else
			-- Update pauseDuringEffect flag if either layer is moving
			writemem(GM_LAYER_ADDR+layer._idx*0x14+0x00, FIELD_BOOL, true)
		end
	end
end

------------------------
-- FIELD DECLARATIONS --
------------------------
local LayerFields = {
	idx  = {get=layerGetIdx, readonly=true, alwaysValid=true},
	
	-- Regular fields
	name              = {0x04, FIELD_STRING},
	isHidden          = {0x08, FIELD_BOOL},
	speedX            = {get=layerGetSpeedX, set=layerSetSpeedX},
	speedY            = {get=layerGetSpeedY, set=layerSetSpeedY},
	pauseDuringEffect = {0x00, FIELD_BOOL},
	
	-- Deprecated
	moving      = {0x00, FIELD_BOOL, readonly=true},
	layerName   = {0x04, FIELD_STRING},
	layerIndex  = {get=layerGetIdx, readonly=true, alwaysValid=true},
}

-----------------------
-- CLASS DECLARATION --
-----------------------
local Layer = {}
local LayerMT = ffi_utils.implementClassMT("Layer", Layer, LayerFields, layerGetIsValid)
local LayerCache = {}

-- Constructor
setmetatable(Layer, {__call = function(Layer, idx)
	if LayerCache[idx] then
		return LayerCache[idx]
	end

	local layer = {_idx = idx, _ptr = GM_LAYER_ADDR + idx*0x14}
	setmetatable(layer, LayerMT)
	LayerCache[idx] = layer
	return layer
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function Layer:mem(offset, dtype, val)
	if not layerGetIsValid(self) then
		error("Invalid Layer object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

Layer.setSpeedX = layerSetSpeedX
Layer.setSpeedY = layerSetSpeedY

function Layer:stop()
	writemem(GM_LAYER_ADDR+self._idx*0x14+0x0C, FIELD_FLOAT, 0)
	writemem(GM_LAYER_ADDR+self._idx*0x14+0x10, FIELD_FLOAT, 0)
	layerUpdateContents(self)
end

function Layer:hide(noSmoke)
	LunaDLL.LunaLuaHideLayer(self._idx, noSmoke)
end

function Layer:show(noSmoke)
	LunaDLL.LunaLuaShowLayer(self._idx, noSmoke)
end

function Layer:toggle(noSmoke)
	if self.isHidden then
		self:show(noSmoke)
	else
		self:hide(noSmoke)
	end
end

--Values of player 0x122 (forced animation state) that allow layers to move (currently only 0 is confirmed to be valid, keeping it as a table for now in case others are found)
local layerMoveStates = {[0]=true, [3]=true}

-- Checks if layer movement has been paused by player states
-- Can be called either as an instance method, or static. In the latter case it assumes a layer that pauses during effects
function Layer:isPaused()
	-- If a specific layer is specified, and doesn't pause during effects, return false always 
	if (self ~= nil) and (not self.pauseDuringEffect) then
		return false
	end

	-- Otherwise, check if any player is in a state that should pause layer movement
	for _,p in ipairs(Player.get()) do
		if(not layerMoveStates[p:mem(0x122,FIELD_WORD)]) then
			return true;
		end
	end
	return false;
end

--------------------
-- STATIC METHODS --
--------------------
function Layer.count()
	return layerGetCount()
end

local getMT = {__pairs = ipairs}

function Layer.get(name)
	if name == nil then
		local ret = {}
		for idx=0,MAX_LAYERS-1 do
			if readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_DWORD) == 0 or #readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING) == 0 then 
				break 
			end
			
			ret[#ret+1] = Layer(idx)
		end
		setmetatable(ret, getMT)
		return ret
	else
		for idx=0,MAX_LAYERS-1 do
			if readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_DWORD) == 0 or #readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING) == 0 then 
				break 
			end
			
			if readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING) == name then
				return Layer(idx)
			end
		end
		return nil
	end
end
ffi_utils.earlyWarnCall(Layer, "Layer", "get", Layer.get)

function Layer.find(name)	
	local ret = {}
	for idx=0,MAX_LAYERS-1 do
		if readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_DWORD) == 0 or #readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING) == 0 then 
			break 
		end
		
		if string.find(readmem(GM_LAYER_ADDR+idx*0x14+0x04, FIELD_STRING), name, 1, true) then
			ret[#ret+1] = Layer(idx)
		end
	end
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Layer, "Layer", "find", Layer.find)

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Layer = Layer
return Layer
