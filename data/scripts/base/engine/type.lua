-- Implementation of the 'type' function.
-- Based upon: https://github.com/jirutka/mtype

-- The MIT License

-- Copyright 2017 Jakub Jirutka <jakub@jirutka.cz>.

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.


local getmetatable = getmetatable
local io_type = io.type
local rawtype = type


--- Returns (enhanced) type name of the given *value*.
--
-- * If the *value* is a table or an userdata with a metatable, then it looks
--   for a metafield `__type`.
--
--    * If the metafield is a string, then it returns it as a type name.
--
--    * If it's a function, then it calls it with the *value* as an argument.
--      If the result is not nil, then it returns it as a type name;
--      otherwise continues.
--
-- * If the *value* is an IO userdata (file), then it calls `io.type` and
--   returns result as a type name.
--
-- * If nothing above applies, then it returns a raw type of the *value*,
--   i.e. the same as built-in type function.
--
-- @param value
-- @treturn string A type name of the value.
local function type (value)
  local rtype = rawtype(value)

  if rtype ~= 'table' and rtype ~= 'userdata' then
    return rtype
  end

  local mt = getmetatable(value)
  if mt and (rawtype(mt) == 'table') then
    local mttype = mt.__type

    if mttype and rawtype(mttype) == 'function' then
      mttype = mttype(value)
    end

    if mttype then
      return mttype
    end
  end

  if rtype == 'userdata' then
    local itype = io_type(value)
    if itype then
      return itype
    end
  end

  return rtype
end

-- Replace global type implementation
_G.rawtype = rawtype
_G.type = type
