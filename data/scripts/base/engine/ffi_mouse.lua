local ffi_utils = require("ffi_utils")

local moose = {}

----------------------
-- FFI DECLARATIONS --
----------------------

ffi.cdef[[
int LunaLuaGetMouseSize();
int LunaLuaGetMouseBaseSize();

int LunaLuaGetMouseWidth();
int LunaLuaGetMouseHeight();
]]

--------------------
-- STATIC METHODS --
--------------------

function Mouse.getSize()
    return LunaDLL.LunaLuaGetMouseSize()
end

function Mouse.getBaseSize()
    return LunaDLL.LunaLuaGetMouseBaseSize()
end

function Mouse.width()
    return LunaDLL.LunaLuaGetMouseWidth()
end

function Mouse.height()
    return LunaDLL.LunaLuaGetMouseHeight()
end

return moose