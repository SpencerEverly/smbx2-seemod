local routine = {}



-- Automated queues

-- Format: array of { routine, type ("s" or "f"), time }
local queue_time = {}


-- Format: array of { routine, type ("s" or "f"), time }
local queue_pausedtime = {}


-- Format: array of { routine, key constant }
local queue_input = {}


-- Format: map of [signal, {list of routines}]
local queue_signal = {}

-- Format: map of [event name, {list of routines}]
local queue_event = {}


-- List of active events for looping purposes
local event_list = {}



-- Maps of routines to various properties

-- Map of routines that are currently waiting
local waitMap = {}

-- Map of routines to a list of signals they're waiting for
local signalMap = {}

-- Map of paused routines
local pausedMap = {}

-- Map of timers that are about to break
local breakMap = {}

-- Map of routines that have manually yielded
local yieldMap = {}

-- Current routine ID
local id = 0

-- Maps classical coroutines to routine objects
local classMap = {}

-- Used for garbage collection
local routineList = {}

-- Used for garbage collection
local abortList = {}


-------------------
-- PUBLIC FIELDS --
-------------------


--- The time (in seconds) between the current frame and the previous one.
routine.deltaTime = 0
--- The current time (in seconds) since the start of the lua environment execution. 
routine.time = 0
--- The time (in seconds) since the last update (e.g. if the game is paused or has been tabbed out)
routine.timeFrozen = 0
--- The time (in seconds) between the current frame and the previous one, which does not stop when the game pauses.
routine.pauseDeltaTime = 0
--- The current time (in seconds) since the start of the lua environment execution, which updates even while the game is paused.
routine.pauseTime = 0
--- The time (in seconds) since the last update (e.g. if the game has been tabbed out), and is still updated while the game is paused.
routine.pauseTimeFrozen = 0

--- The maximum deltaTime value before the program is considered "frozen".
routine.deltaTimeMax = 0.1

-------------------------------
-- ROUTINE CLASS DECLARATION --
-------------------------------

local routine_class = { __type = "Routine" }

local function makeRoutine(co)
	local t = {_coroutine = co, id = id}
	id = id+1
	setmetatable(t, routine_class)
	classMap[co] = t
	table.insert(routineList, co)
	return t
end

-----------------------
-- PRIVATE FUNCTIONS --
-----------------------

local function getCurrentRoutine()
	local co = coroutine.running()
	
	-- If co is nil, that means we're on the main process, which isn't a coroutine and can't yield
	assert (co ~= nil, "The main thread cannot wait!")
	
	return classMap[co] or makeRoutine(co)
end

local function resumeRoutine(co, ...)
	waitMap[co] = nil
	local status, msg = coroutine.resume(co._coroutine, ...)
	if not status then
		-- Ignore dead coroutines because that's just the result of a normal non-error exit
		if msg ~= "cannot resume dead coroutine" then
		   -- Throw error up the chain, including a stack trace of the coroutine that we otherwise wouldn't get
		   error(msg .. "\n=============\nroutine " .. debug.traceback(co._coroutine), 2)
		end
	end
	return status, msg
end

local function check(co)
	assert((not waitMap[co]), "Routine is already waiting. Cannot wait twice at the same time.", 2)
	waitMap[co] = true
end

----------------------
-- PUBLIC FUNCTIONS --
----------------------

function routine.run(func, ...)
	local co = coroutine.create(func)
	local r = classMap[co] or makeRoutine(co)
	local status, msg = resumeRoutine(r, ...)
	
	if status then
		return r, status, msg
	else
		classMap[co] = nil
		return nil, status, msg
	end
end

function routine.waitRealSeconds(secs, canResumeWhilePaused)
	local co = getCurrentRoutine()
	check(co)
	
	-- Set up wait event
	local t = { co, "s", secs }
	
	-- Insert to waiting queue
	if(canResumeWhilePaused) then
		table.insert(queue_pausedtime, t)
	else
		table.insert(queue_time, t)
	end

	-- And suspend the process
	return coroutine.yield(co._coroutine)
end

function routine.waitFrames(frames, canResumeWhilePaused)
	local co = getCurrentRoutine()
	check(co)
	
	-- Set up wait event
	local t = { co, "f", math.max(1, frames) }
	
	-- Insert to waiting queue
	if(canResumeWhilePaused) then
		table.insert(queue_pausedtime, t)
	else
		table.insert(queue_time, t)
	end
	
	-- And suspend the process
	return coroutine.yield(co._coroutine)
end

function routine.wait(seconds, canResumeWhilePaused)
	return routine.waitFrames(lunatime.toTicks(seconds), canResumeWhilePaused)
end

function routine.skip(canResumeWhilePaused)
	return routine.waitFrames(1, canResumeWhilePaused)
end

routine.waitSeconds = routine.wait

function routine.waitInput(key)
	local co = getCurrentRoutine()
	check(co)
	
	-- Set up wait event
	local t = { co, key }
	table.insert(queue_input, t)

	-- And suspend the process
	return coroutine.yield(co._coroutine)
end

routine.waitForInput = routine.waitInput

function routine.waitSignal(name, signalIsTable)
	local co = getCurrentRoutine()
	check(co)

	if signalMap[co] == nil then
		signalMap[co] = {}
	end

	-- Handle adding to signal queue, including table management
	if type(name) == "table" and not signalIsTable then
		for _,v in ipairs(name) do
			if queue_signal[v] == nil then
				queue_signal[v] = {}
			end

			table.insert(queue_signal[v], co)
			table.insert(signalMap[co], v)
		end
	else
		if queue_signal[name] == nil then
			queue_signal[name] = {}
		end

		table.insert(queue_signal[name], co)
		table.insert(signalMap[co], name)
	end

	-- And suspend the process
	return coroutine.yield(co._coroutine)
end


function routine.waitEvent(name)
	local co = getCurrentRoutine()
	check(co)
	
	-- Handle adding to event queue
	if queue_event[name] == nil then
		queue_event[name] = {}
		table.insert(event_list, name)
	end
	
	table.insert(queue_event[name], co)
	
	-- And suspend the process
	return coroutine.yield(co._coroutine)
end

function routine.yield()
	local co = getCurrentRoutine()
	check(co)
	yieldMap[co] = true
	return coroutine.yield(co._coroutine)
end

function routine.signal(name)
	if queue_signal[name] == nil then return end
	
	local t = queue_signal[name]
	queue_signal[name] = nil
	
	local reinsert
	
	local resumeQueue = {}
	
	-- Find all routines in signal list
	for _,v in ipairs(t) do
	
		if not pausedMap[v] then
			-- Get routine wait list
			local l = signalMap[v]
			
			if l == nil or #l == 0 or (#l == 1 and l[1] == name) then
				-- If wait list is empty or only contains this signal, resume the routine
				signalMap[v] = nil
				table.insert(resumeQueue, v)
			else
				-- Otherwise, find this signal and remove it from the list
				local idx = table.ifind(l, name)
				if idx then
					table.remove(l, idx)
				end
			end
		else
			-- If any routines were skipped from being paused, this signal isn't empty, so it needs reinserting
			if reinsert == nil then
				reinsert = {}
				queue_signal[name] = reinsert
			end
			table.insert(reinsert, v)
		end
	end
	
	--Done separately so that resumed routines cannot interfere with the queue
	for _,v in ipairs(resumeQueue) do
		if waitMap[v] then
			resumeRoutine(v)
		end
	end
end

function routine.loop(t, func, canResumeWhilePaused)
	for i=1,t do
		func(i)
		routine.waitFrames(1, canResumeWhilePaused)
	end
end

function routine.setTimer(secs, func, repeated, runWhilePaused)	
		local f
		repeated = repeated or false
		
		if type(repeated) == "number" then
			f = function()		
					for i=1,repeated do
						routine.wait(secs, runWhilePaused)
						func(i)
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					end
				end
			
		else
			f = function()
					repeat
						routine.wait(secs, runWhilePaused)
						func()
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					until not repeated
				end
				
		end
		
		return routine.run(f)
end

function routine.setFrameTimer(frames, func, repeated, runWhilePaused)	
		local f
		repeated = repeated or false
		
		if type(repeated) == "number" then
			f = function()	
					for i=1,repeated do
						routine.waitFrames(frames, runWhilePaused)
						func(i)
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					end
				end
			
		else
			f = function()	
					repeat
						routine.waitFrames(frames, runWhilePaused)
						func()
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					until not repeated
				end
				
		end
		
		return routine.run(f)
end

function routine.setRealTimer(secs, func, repeated, runWhilePaused)	
			local f
		repeated = repeated or false
		
		if type(repeated) == "number" then
			f = function()	
					for i=1,repeated do
						routine.waitRealSeconds(secs, runWhilePaused)
						func(i)
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					end
				end
			
		else
			f = function()	
					repeat
						routine.waitRealSeconds(secs, runWhilePaused)
						func()
						local co = getCurrentRoutine()
						if breakMap[co] then
							breakMap[co] = nil
							break
						end
					until not repeated
				end
				
		end
		
		return routine.run(f)
end

function routine.pause(co)	
	assert(co.isValid, "Attempted to access an invalid routine.", 2)
	pausedMap[co] = true
end

routine.pauseTimer = routine.pause

function routine.resume(co)
	assert(co.isValid, "Attempted to access an invalid routine.", 2)
	pausedMap[co] = nil
end

routine.resumeTimer = routine.resume

function routine.getTime(co)
	assert(co.isValid, "Attempted to access an invalid routine.", 2)
	if waitMap[co] then
		for _,v in ipairs(queue_time) do
			if v[1] == co then
				return v[3], v[2]
			end
		end
		for _,v in ipairs(queue_pausedtime) do
			if v[1] == co then
				return v[3], v[2]
			end
		end
		return 0
	else
		return 0
	end
end

routine.getTimer = routine.getTime

function routine.breakTimer()
		local co = getCurrentRoutine()
		breakMap[co] = true
end

function routine.continue(co)
	assert(co.isValid, "Attempted to access an invalid routine.", 2)
	if not waitMap[co] or not yieldMap[co] then
		local w = "Cannot continue a routine that was not yielded."
		Misc.warn(w, 2)
		return false, w
	elseif not pausedMap[co] then
		yieldMap[co] = nil
		return resumeRoutine(co)
	end
end

function routine.abort(co)
	if co ~= nil and co.isValid then
		if waitMap[co] then
			if signalMap[co] then
				for _,v in ipairs(signalMap[co]) do
					local idx = table.ifind(queue_signal[v], co)
					if idx then
						table.remove(queue_signal[v], idx)
					end
				end
				signalMap[co] = nil
			else
				local ti = 1
				local pti = 1
				local ii = 1
				local ei = 1
				
				local qt = queue_time[ti]
				local qpt = queue_pausedtime[pti]
				local qi = queue_input[ii]
				local qe = event_list[ei]
				
				while qt ~= nil or qpt ~= nil or qi ~= nil or qe ~= nil do
					if qt and qt[1] == co then
						table.remove(queue_time, ti)
						break
					else
						ti = ti+1
						qt = queue_time[ti]
					end
					
					if qpt and qpt[1] == co then
						table.remove(queue_pausedtime, pti)
						break
					else
						pti = pti+1
						qpt = queue_pausedtime[pti]
					end
					
					if qi and qi[1] == co then
						table.remove(queue_input, ii)
						break
					else
						ii = ii+1
						qi = queue_input[ii]
					end
					
					if qe then
						local l = queue_event[qe]
						local idx = table.ifind(l, co)
						if idx then
							table.remove(l, idx)
							break
						else
							ei = ei+1
							qe = event_list[ei]
						end
					end
				end
			end
			
			pausedMap[co] = nil
			breakMap[co] = nil
			waitMap[co] = nil
			yieldMap[co] = nil
			classMap[co._coroutine] = nil
			abortList[co._coroutine] = true
		else
			Misc.warn("Tried to abort a routine that wasn't waiting.",2)
		end
	else
		Misc.warn("Tried to abort an invalid routine.",2)
	end
end

function routine.registerKeyEvent(key, func, consume)
		consume = consume or false
		local _,c = routine.run(function()
						repeat
							routine.waitInput(key)
							func()
							local co = getCurrentRoutine()
							if breakMap[co] then
								breakMap[co] = nil
								break
							end
						until consume
					end)
		return c
end

function routine.registerVanillaEvent(event, func, repeated)
		repeated = repeated or false
		local _,c = routine.run(function()
						repeat
							routine.waitEvent(event)
							func()
							local co = getCurrentCoroutine()
							if breakMap[co] then
								breakMap[co] = nil
								break
							end
						until not repeated
					end)
		return c
end

function routine.getDebugID(co)
	return co.id
end

routine.registerSMBXEvent = routine.registerVanillaEvent


------------------------------
-- ROUTINE CLASS DEFINITION --
------------------------------

local function getRoutineIsValid(co)
	return classMap[co._coroutine] == co and coroutine.status(co._coroutine) ~= "dead"
end

function routine_class.__index(tbl, k)
	if k == "isValid" then
		return getRoutineIsValid(tbl)
	elseif k == "paused" then
		return getRoutineIsValid(tbl) and pausedMap[tbl] == true
	elseif k == "yielded" then
		return getRoutineIsValid(tbl) and yieldMap[tbl] == true
	elseif k == "waiting" then
		return getRoutineIsValid(tbl) and waitMap[tbl] == true
	elseif k == "getTimer" or k == "getTime" then
		return routine.getTime
	elseif k == "abort" then
		return routine.abort
	elseif k == "pause" then
		return routine.pause
	elseif k == "resume" then
		return routine.resume
	elseif k == "continue" then
		return routine.continue
	end
end

function routine_class.__tostring(r)
	return "thread:"..r.id
end

-----------------
-- EVENT HOOKS --
-----------------

function routine.onInitAPI()
	registerEvent(routine, "onStart", "onStart", true)
	registerEvent(routine, "onTick", "onTick", true)
	registerEvent(routine, "onKeyDown", "onKeyDown", true)
	registerEvent(routine, "onEvent", "onEvent", true)
	registerEvent(routine, "onInputUpdate", "onInputUpdate", true)
end

function routine.onStart()
	routine.time = Misc.clock()
	routine.pauseTime = Misc.clock()
end

function routine.onTick()

	--Update deltaTime
	routine.deltaTime = Misc.clock() - routine.time
	if routine.deltaTime > routine.deltaTimeMax then
		routine.timeFrozen = routine.deltaTime
		routine.deltaTime = 0
	else
		routine.timeFrozen = 0
	end
	
	--Update time waiting queue
	local i = 1
	local lastidx = #queue_time
	
	local resumeQueue = {}
	
	while i <= lastidx do
		local v = queue_time[i]
		local co = v[1]
		if pausedMap[co] then
			i = i+1
		else
			local typ = v[2]
			if typ == "s" then
				v[3] = v[3]-routine.deltaTime
			else
				v[3] = v[3]-1
			end
			if v[3] <= 0 then
				table.remove(queue_time, i)
				lastidx = lastidx - 1
				table.insert(resumeQueue, co)
			else
				i = i+1
			end
		end
	
	end
	
	--Done separately so that resumed routines cannot interfere with the queue
	for _,v in ipairs(resumeQueue) do		
		if waitMap[v] then
			resumeRoutine(v)
		end
	end
	
	routine.time = Misc.clock();
end


function routine.onInputUpdate()

	do
		local i = 1
		while i <= #routineList do
			if coroutine.status(routineList[i]) == "dead" or abortList[routineList[i]] then
				classMap[routineList[i]] = nil
				abortList[routineList[i]] = nil
				table.remove(routineList, i)
			else
				i = i+1
			end
		end
	end
	--Update pauseDeltaTime
	routine.pauseDeltaTime = Misc.clock() - routine.pauseTime
	if routine.pauseDeltaTime > routine.deltaTimeMax then
		routine.pauseTimeFrozen = routine.pauseDeltaTime
		routine.pauseDeltaTime = 0
	else
		routine.pauseTimeFrozen = 0
	end
	
	--Update "run while paused" time waiting queue
	local i = 1
	local lastidx = #queue_pausedtime
	
	local resumeQueue = {}
	
	while i <= lastidx do
		local v = queue_pausedtime[i]
		local co = v[1]
		if pausedMap[co] then
			i = i+1
		else
			local typ = v[2]
			if typ == "s" then
				v[3] = v[3]-routine.pauseDeltaTime
			else
				v[3] = v[3]-1
			end
			if v[3] <= 0 then
				table.remove(queue_pausedtime, i)
				lastidx = lastidx - 1
				table.insert(resumeQueue, co)
			else
				i = i+1
			end
		end
	end
	
	--Done separately so that resumed routines cannot interfere with the queue
	for _,v in ipairs(resumeQueue) do	
		if waitMap[v] then
			resumeRoutine(v)
		end
	end
	
	routine.pauseTime = Misc.clock()
end

function routine.onKeyDown(key)
	local i = 1	
	local lastidx = #queue_input
	
	local resumeQueue = {}
	
	while i <= lastidx do
		local v = queue_input[i]
		if v[2] == key and not pausedMap[co] then
			table.remove(queue_input, i)
			lastidx = lastidx - 1
			table.insert(resumeQueue, v[1])
		else
			i = i+1
		end
	end
	
	--Done separately so that resumed routines cannot interfere with the queue
	for _,v in ipairs(resumeQueue) do
		if waitMap[v] then
			resumeRoutine(v)
		end
	end
end

function routine.onEvent(name)
	if queue_event[name] ~= nil then
		local t = queue_event[name]
		queue_event[name] = nil
		
		local idx = table.ifind(event_list, name)
		if idx then
			table.remove(event_list, idx)
		end
	
		local resumeQueue = {}
		
		local reinsert
		for _,v in ipairs(t) do
			if not pausedMap[v] then 
				table.insert(resumeQueue, v)
			else
				-- If any routines were skipped from being paused, this signal isn't empty, so it needs reinserting
				if reinsert == nil then
					reinsert = {}
					table.insert(event_list, name)
					queue_event = reinsert
				end
				table.insert(reinsert, v)
			end
		end
	
		--Done separately so that resumed routines cannot interfere with the queue
		for _,v in ipairs(resumeQueue) do
			if waitMap[v] then
				resumeRoutine(v)
			end
		end
	end
end

return routine