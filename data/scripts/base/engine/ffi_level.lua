------------------------------------
-- Level function implementations --
------------------------------------

local GM_EPISODE_MODE    = 0x00B2C5B4
local GM_LEVEL_MODE      = 0x00B2C620
local GM_LEVEL_WINTYPE   = 0x00B2C5D4
local GM_LEVEL_END_FLAG  = 0x00B2C59C
local GM_ENDSTATE        = 0x00B2C59E
local GM_ENDSTATE_TIMER  = 0x00B2C5A0
local GM_STR_CHECKPOINT  = 0x00B250B0
local GM_FULLPATH        = 0x00B2C618

function Level.exit(winType)
	if (winType ~= nil) then
		writemem(0x00B2C5D4, FIELD_WORD, winType)
	else
		winType = readmem(0x00B2C5D4, FIELD_WORD)
	end
	
	if (winType > 0) then
		local currentCheckpoint = readmem(GM_STR_CHECKPOINT, FIELD_STRING)
		local currentLevel = readmem(GM_FULLPATH, FIELD_STRING)
		if (currentCheckpoint == currentLevel) then
			-- If winning exit type and refers to the current level, clear checkpoint string
			writemem(GM_STR_CHECKPOINT, FIELD_STRING, "")
		end
	end
	
	writemem(GM_EPISODE_MODE, FIELD_BOOL, true)
	writemem(GM_LEVEL_MODE, FIELD_BOOL, false)
end

function Level.endState(endState)
	if (endState == nil) then
		-- Read
		return readmem(GM_ENDSTATE, FIELD_WORD)
	else
		-- Write
		writemem(GM_ENDSTATE, FIELD_WORD, endState)
	end
end

-- Triger level ending with a particular end state
function Level.finish(endState, delayed)
	if (endState ~= nil) then
		-- We have a specified end state
		writemem(GM_ENDSTATE, FIELD_WORD, endState)
	else
		-- Get the existing end state
		endState = readmem(GM_ENDSTATE, FIELD_WORD)
	end

	if (endState == 0) then
		-- No endstate animation
		writemem(GM_LEVEL_END_FLAG, FIELD_BOOL, true)
	elseif not delayed then
		-- Not delayed, expedite end animation
		writemem(GM_ENDSTATE_TIMER, FIELD_WORD, 1000)
		
		-- For end state 1, need players off screen
		if (endState == LEVEL_END_STATE_ROULETTE) or (endState == LEVEL_END_STATE_TAPE) then
			for _,p in ipairs(Player.get()) do
				p.x = p.sectionObj.boundary.right
			end
		end
	end
end

-- Mapping from win type (i.e. map unlocks) to end state (i.e. end of level animation)
function Level.winTypeToEndState(winType)
	if (winType == LEVEL_WIN_TYPE_ROULETTE) then
		return LEVEL_END_STATE_ROULETTE
	elseif (winType == LEVEL_WIN_TYPE_SMB3ORB) then
		return LEVEL_END_STATE_SMB3ORB
	elseif (winType == LEVEL_WIN_TYPE_KEYHOLE) then
		return LEVEL_END_STATE_KEYHOLE
	elseif (winType == LEVEL_WIN_TYPE_SMB2ORB) then
		return LEVEL_END_STATE_SMB2ORB
	elseif (winType == LEVEL_WIN_TYPE_STAR) then
		return LEVEL_END_STATE_STAR
	elseif (winType == LEVEL_WIN_TYPE_TAPE) then
		return LEVEL_END_STATE_TAPE
	else
		-- No 1-to-1 match (none, offscreen, or warp)
		return 0
	end
end

-- Mapping from end state (i.e. end of level animation) to win type (i.e. map unlocks)
function Level.endStateToWinType(endState)
	if (endState == LEVEL_END_STATE_ROULETTE) then
		return LEVEL_WIN_TYPE_ROULETTE
	elseif (endState == LEVEL_END_STATE_SMB3ORB) then
		return LEVEL_WIN_TYPE_SMB3ORB
	elseif (endState == LEVEL_END_STATE_KEYHOLE) then
		return LEVEL_WIN_TYPE_KEYHOLE
	elseif (endState == LEVEL_END_STATE_SMB2ORB) then
		return LEVEL_WIN_TYPE_SMB2ORB
	elseif (endState == LEVEL_END_STATE_STAR) then
		return LEVEL_WIN_TYPE_STAR
	elseif (endState == LEVEL_END_STATE_TAPE) then
		return LEVEL_WIN_TYPE_TAPE
	else
		-- No 1-to-1 match (none, gameend)
		return LEVEL_WIN_TYPE_NONE
	end
end

------------------------
-- Deprecated aliases --
------------------------
Level.exitLevel = Level.exit
_G.exitLevel = Level.exit
Level.winState = Level.endState
_G.winState = Level.endState
