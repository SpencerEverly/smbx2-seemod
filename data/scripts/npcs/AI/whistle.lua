local npcManager = require("npcManager")

local whistle = {}

--***********************************************************************************************
--                                                                                              *
--              DEFAULTS AND CONFIGURATION                                                      *
--                                                                                              *
--***********************************************************************************************

local state = false;
local cooldown = 0; -- enjl told me to add this because he SUCKS

local cooldownMax = 300;

-- Helpful functions
function whistle.setActive(c)
    state = true;
    cooldown = c or cooldownMax;
end

function whistle.getActive()
    return state;
end

-- setup
function whistle.onInitAPI()
	registerEvent(whistle, "onTickEnd")
end

-- Actually running
function whistle.onTickEnd()
	if cooldown <= 0 then return end;

    cooldown = cooldown - 1;

    state = (cooldown > 0);
end

return whistle;