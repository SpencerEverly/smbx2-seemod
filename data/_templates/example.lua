--------------------------------------------------
--===========Example LunaLua Library============--
--    Copypaste and edit this to make your      --
--                 own library!                 --
--    Load in a level with something like:      --
--     local example = API.load("example")      --
--------------------------------------------------

-- Declare our library table
local barebones = {}

-- Declare any local and library variables we might need:

-- Private variable. This can't be accessed outside of this code file.
local myVar = 0

-- Exposed variable. This can be accessed by anything that loads the API.
barebones.example = 0

-- Private function. Same deal.
local function myFunc(a, b)
	return a + b
end

-- Exposed function. Same deal.
function barebones.exampleFunc(x)
	return (x > 0)
end

-- Use onInitAPI to set up all the SMBX event handlers you'll need!
-- This runs as soon as library is loaded.
function barebones.onInitAPI()
	registerEvent(barebones, "onTick")

	-- Put stuff that should happen when the library is loaded here.
end

function barebones.onTick()
	-- Put onTick stuff here
end

return barebones