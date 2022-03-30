--- Manages the ticking sound for grinders and the like
-- @module ticker
-- @author Sambo
-- @version 2.b4

local ticker = {}

local TICK_DELAY = 8

registerEvent(ticker, "onTick")

local tickTimer = 0
function ticker.onTick()
	if ticker.shouldTick then
		ticker.shouldTick = false
		tickTimer = (tickTimer + 1) % TICK_DELAY
		if tickTimer == 0 then
			SFX.play(74)
		end
	end
end

return ticker