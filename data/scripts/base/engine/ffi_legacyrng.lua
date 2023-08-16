local ffi_utils = require("ffi_utils")

----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
unsigned int LunaLuaLegacyRNGGetSeed();
void LunaLuaLegacyRNGSetSeed(unsigned int newSeed);
float LunaLuaLegacyRNGGetLastGeneratedNumber();
float LunaLuaLegacyRNGGenerateNumber();
]]
local LunaDLL = ffi.load("LunaDll.dll")

-----------------------
-- CLASS DECLARATION --
-----------------------
local LegacyRNG = {}

-------------------------
-- METHOD DECLARATIONS --
-------------------------
function LegacyRNG.getLastGeneratedNumber()
    return LunaDLL.LunaLuaLegacyRNGGetLastGeneratedNumber();
end

function LegacyRNG.generateNumber()
    return LunaDLL.LunaLuaLegacyRNGGenerateNumber()
end

------------------------
-- FIELD DECLARATIONS --
------------------------
setmetatable(LegacyRNG, {
    __index = function(tbl, key)
        if key == "seed" then
            return LunaDLL.LunaLuaLegacyRNGGetSeed();
        end
        return nil
    end,

    __newindex = function(tbl, key, value)
        if key == "seed" then
            LunaDLL.LunaLuaLegacyRNGSetSeed(value);
        else
            error("Field '" .. tostring(key) .. "' in LegacyRNG is read-only")
        end
    end
})

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.LegacyRNG = LegacyRNG
return LegacyRNG