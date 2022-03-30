--[[
-- API NAME: playerStun.lua
-- Author: Minus
-- Version: 1.1
-- Description: API for stunning the player and temporarily disabling their basic controls.
--
-- (1.1) 13 June 2018
-- (*) Players now have a fancy "bounce" effect when stunned.
--]]

local BOUNCE_HEIGHT = 2

local playerStun = {}

local playerStunTimer = {}

local function canStun(p)
	-- No forced state, not in clown car
	return p.forcedState == 0 and p:mem(0x108, FIELD_WORD) ~= 2
end

-----------------------------------------------------------
------------------ EXTERNAL FUNCTIONS: --------------------
-----------------------------------------------------------

-- Stuns the given player (disables their inputs for the given duration and sets their previous horizontal speed to 0).
function playerStun.stunPlayer(id, duration)
	local p = Player(id)
	if canStun(p) then
		p.speedX = 0
		playerStunTimer[id] = duration
	end
end

-- Return a boolean denoting whether or not the given player is stunned (that is, it has a non-nil entry in the table).
function playerStun.isStunned(id)
	return playerStunTimer[id] ~= nil
end

-----------------------------------------------------------
--------------------- API FUNCTIONS: ----------------------
-----------------------------------------------------------

function playerStun.onInitAPI()
	registerEvent(playerStun, "onTick", "onTick", false)
	registerEvent(playerStun, "onTickEnd", "onTickEnd", false)
	registerEvent(playerStun, "onInputUpdate", "onInputUpdate", false)
end

function playerStun.onTick()
	for k, v in pairs(playerStunTimer) do
		local p = Player(k)
		if v > 0 and canStun(p) then
			-- Have the player bounce - give them a slight boost in vertical speed during any instant they are touching the ground.
			if p:isGroundTouching() then
				Player(k).speedY = -BOUNCE_HEIGHT
			end
			
			playerStunTimer[k] = v - 1
		else
			-- Delete this player from the stun timer table.
			
			playerStunTimer[k] = nil
		end
	end
end

function playerStun.onTickEnd()
	for k, v in pairs(playerStunTimer) do
		local p = Player(k)
		if p:mem(0x108, FIELD_WORD) ~= 3 then
			-- Force idle sprite
			p:setFrame(1)
		else
			------ Yoshi
			-- Force body to idle
			p:mem(0x7A, FIELD_WORD, p.direction == -1 and 0 or 7)
			local head = p:mem(0x72, FIELD_WORD)
			if head == 2 or head == 7 then
				p:mem(0x72, FIELD_WORD, head - 2)
			end
		end
	end
end

function playerStun.onInputUpdate()
	for k, _ in pairs(playerStunTimer) do
		local p = Player(k)
		
		-- Disable the player's basic inputs.
		player.keys.up = nil
		player.keys.left = nil
		player.keys.right = nil
		player.keys.down = nil
		player.keys.run = nil
		player.keys.jump = nil
		player.keys.altRun = nil
		player.keys.altJump = nil
	end
end

return playerStun