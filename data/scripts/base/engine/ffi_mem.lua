---------------------------------
-- Implement mem calls via FFI --
---------------------------------

local oldmem = mem
local ffi = ffi
local ffi_cast = ffi.cast
local FIELD_BYTE = FIELD_BYTE
local FIELD_WORD = FIELD_WORD
local FIELD_DWORD = FIELD_DWORD
local FIELD_FLOAT = FIELD_FLOAT
local FIELD_DFLOAT = FIELD_DFLOAT
local FIELD_STRING = FIELD_STRING
local FIELD_BOOL = FIELD_BOOL

local typeMap = {}
typeMap[FIELD_BYTE]   = ffi.typeof("uint8_t*")
typeMap[FIELD_WORD]   = ffi.typeof("int16_t*")
typeMap[FIELD_DWORD]  = ffi.typeof("int32_t*")
typeMap[FIELD_FLOAT]  = ffi.typeof("float*")
typeMap[FIELD_DFLOAT] = ffi.typeof("double*")

ffi.cdef([[
const char* LunaLuaMemReadString(unsigned int addr);
void LunaLuaMemWriteString(unsigned int addr, const char* str);
]])
local LunaDLL = ffi.load("LunaDll.dll")

local function readmem(addr, dtype)
	if (dtype == FIELD_STRING) then
		local ptr = LunaDLL.LunaLuaMemReadString(addr)
		if (ptr == nil) then
			return nil
		end
		return ffi.string(ptr)
	elseif (dtype == FIELD_BOOL) then
		local ptr = ffi_cast(typeMap[FIELD_WORD], addr)
		return ptr[0] ~= 0
	else
		local ptr = ffi_cast(typeMap[dtype], addr)
		return ptr[0]
	end
end

local function writemem(addr, dtype, val)
	if (dtype == FIELD_STRING) then
		LunaDLL.LunaLuaMemWriteString(addr, val)
	elseif (dtype == FIELD_BOOL) then
		local ptr = ffi_cast(typeMap[FIELD_WORD], addr)
		if (val == true) then
			ptr[0] = -1
		elseif (val == false) then
			ptr[0] = 0
		elseif (val == 0) then
			ptr[0] = 0
		elseif (val) then
			ptr[0] = -1
		else
			ptr[0] = 0
		end
	else
		local ptr = ffi_cast(typeMap[dtype], addr)
		ptr[0] = val
	end
end

local function mem(addr, dtype, val)
	if (val == nil) then
		return readmem(addr, dtype)
	else
		return writemem(addr, dtype, val)
	end
end

--------------------
-- Assign globals --
--------------------
_G.readmem = readmem
_G.writemem = writemem
_G.mem = mem
