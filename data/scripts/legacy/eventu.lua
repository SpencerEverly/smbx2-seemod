--- Coroutine and scheduling library.
-- @module eventu

local eventu = {}

local secondsQueue = {}
local framesQueue = {}
local inputQueue = {}
local signalQueue = {}
local eventQueue = {}

local runpaused_frames = {};
local runpaused_secs = {};

local pausedQueue = {}
local breakQueue = {}

local debug_ids = setmetatable({}, {__mode="k"})

local id = 0

--- The time (in seconds) between the current frame and the previous one.
eventu.deltaTime = 0;
--- The current time (in seconds) since the start of the lua environment execution. 
eventu.time = 0;
--- The time (in seconds) since the last update (e.g. if the game is paused or has been tabbed out)
eventu.timeFrozen = 0;
--- The time (in seconds) between the current frame and the previous one, which does not stop when the game pauses.
eventu.pauseDeltaTime = 0;
--- The current time (in seconds) since the start of the lua environment execution, which updates even while the game is paused.
eventu.pauseTime = 0;
--- The time (in seconds) since the last update (e.g. if the game has been tabbed out), and is still updated while the game is paused.
eventu.pauseTimeFrozen = 0;

--- The maximum deltaTime value before the program is considered "frozen".
eventu.deltaTimeMax = 0.1;

function eventu.onInitAPI()
	registerEvent(eventu, "onStart", "init", true)
	registerEvent(eventu, "onTick", "update", true)
	registerEvent(eventu, "onKeyDown", "onKey", true)
	registerEvent(eventu, "onEvent", "onEvent", true)
	registerEvent(eventu, "onDraw", "onDraw", true)
end

function eventu.init()
	eventu.time = os.clock();
	eventu.pauseTime = os.clock();
end

local function resumeCoroutine(co, ...)
		 local coStatus, coMsg = coroutine.resume(co, ...)
         if (not coStatus) then
            -- Ignore dead coroutines because that's just the result of a normal non-error exit
            if (coMsg ~= "cannot resume dead coroutine") then
               -- Throw error up the chain, including a stack trace of the coroutine that we otherwise wouldn't get
               error(coMsg .. "\n=============\ncoroutine " .. debug.traceback(co))
            end
         end
		 return coStatus, coMsg;
end

function eventu.update()
	eventu.deltaTime = os.clock() - eventu.time;
	if(eventu.deltaTime > eventu.deltaTimeMax) then
		eventu.timeFrozen = eventu.deltaTime;
		eventu.deltaTime = 0;
	else
		eventu.timeFrozen = 0;
	end
	
	for k,v in pairs(secondsQueue) do
		if(pausedQueue[k] == nil) then
			secondsQueue[k] = v-eventu.deltaTime;
			if(v <= 0) then
				secondsQueue[k] = nil;
				runpaused_secs[k] = nil;
				resumeCoroutine (k)
			end
		end
	end
	
	for k,v in pairs(framesQueue) do
		if(pausedQueue[k] == nil) then
			framesQueue[k] = v-1;
			if(v <= 0) then
				framesQueue[k] = nil;
				runpaused_frames[k] = nil;
				resumeCoroutine (k)
			end
		end
	end
	
	eventu.time = os.clock();
end

function eventu.onDraw()
	if Misc.isPaused() then --only run while paused
		eventu.pauseDeltaTime = os.clock() - eventu.pauseTime;
		if(eventu.pauseDeltaTime > eventu.deltaTimeMax) then
			eventu.pauseTimeFrozen = eventu.pauseDeltaTime;
			eventu.pauseDeltaTime = 0;
		else
			eventu.pauseTimeFrozen = 0;
		end
		
		for k,_ in pairs(runpaused_secs) do
			if(pausedQueue[k] == nil) then
				secondsQueue[k] = secondsQueue[k]-eventu.pauseDeltaTime;
				if(secondsQueue[k] <= 0) then
					secondsQueue[k] = nil;
					runpaused_secs[k] = nil;
					resumeCoroutine (k)
				end
			end
		end
	
		for k,_ in pairs(runpaused_frames) do
			if(pausedQueue[k] == nil) then
				framesQueue[k] = framesQueue[k]-1;
				if(framesQueue[k] <= 0) then
					framesQueue[k] = nil;
					runpaused_frames[k] = nil;
					resumeCoroutine (k)
				end
			end
		end
		
		eventu.pauseTime = os.clock();
	end
end

function eventu.onKey(key)
	for k,v in pairs(inputQueue) do
		if(v == key) then
			inputQueue[k] = nil;
			resumeCoroutine (k)
		end
	end
end

function eventu.onEvent(name)
		local waketable = {}
		if(eventQueue[name] ~= nil) then
			for k,v in pairs(eventQueue[name]) do
				eventQueue[name][k] = nil;
				table.insert(waketable, v);
			end
			eventQueue[name] = nil;
			
			for _,v in ipairs(waketable) do
				resumeCoroutine (v)
			end
		end
end

local function getCurrentCoroutine()
		local co = coroutine.running ()
		
		-- If co is nil, that means we're on the main process, which isn't a coroutine and can't yield
		assert (co ~= nil, "The main thread cannot wait!")
		
		return co;
end


--- Runs an eventu function, which can contain eventu wait processes.
-- @tparam function func The function that should be run. Can contain wait processes to schedule multiple-frame events.
-- @param[opt] arg Optional argument to be passed to the function. More than one argument can be passed this way (see usage).
-- @treturn bool,coroutine Whether the coroutine was successfully started, followed by the coroutine object.
-- @usage eventu.run(myFunctionName)
-- @usage eventu.run(myFunctionName, myArg1, myArg2, myArg3)
-- @usage eventu.run(function(x,y)
--			eventu.waitFrames(x)
--			myVar = myVar+y
-- 	   end, myArg1, myArg2)
-- @see eventu.waitFrames
-- @see eventu.waitSeconds
function eventu.run(func, ...)
		local co = coroutine.create (func)
		debug_ids[co] = id
		id = id+1
		return resumeCoroutine (co, ...), co
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine for the specified number of real-time seconds (adjusted for framerate).
-- @tparam number secs The number of real-time seconds to pause the coroutine for.
-- @tparam[opt=false] bool canResumeWhilePaused If set to true, the timer will tick down even while the game is paused, allowing the coroutine to resume in the paused state. By default, pausing the game will also pause the wait timer.
-- @usage eventu.run(function()
--			eventu.waitRealSeconds(2)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
-- @see eventu.waitFrames
function eventu.waitRealSeconds(secs, canResumeWhilePaused)
		local co = getCurrentCoroutine();
		secondsQueue[co] = secs;
		
		if(canResumeWhilePaused) then
			runpaused_secs[co] = true;
		end

		-- And suspend the process
		return coroutine.yield (co)
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine for the specified number of game ticks.
-- @tparam number frames The number of game ticks (approximately 1/64 seconds) to pause the coroutine for.
-- @tparam[opt=false] bool canResumeWhilePaused If set to true, the timer will tick down even while the game is paused, allowing the coroutine to resume in the paused state. By default, pausing the game will also pause the wait timer.
-- @usage eventu.run(function()
--			eventu.waitFrames(100)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
-- @see eventu.waitSeconds
function eventu.waitFrames(frames, canResumeWhilePaused)
		local co = getCurrentCoroutine();
		framesQueue[co] = frames-1;
		
		if(canResumeWhilePaused) then
			runpaused_frames[co] = true;
		end

		-- And suspend the process
		return coroutine.yield (co)
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine for the specified number of seconds.
-- @tparam number seconds The number of game-time seconds to pause the coroutine for.
-- @tparam[opt=false] bool canResumeWhilePaused If set to true, the timer will tick down even while the game is paused, allowing the coroutine to resume in the paused state. By default, pausing the game will also pause the wait timer.
-- @usage eventu.run(function()
--			eventu.waitSeconds(2)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
-- @see eventu.waitFrames
function eventu.waitSeconds(seconds, canResumeWhilePaused)
	return eventu.waitFrames(lunatime.toTicks(seconds), canResumeWhilePaused)
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine for the specified number of seconds.
-- @function wait
-- @tparam number seconds The number of game-time seconds to pause the coroutine for.
-- @tparam[opt=false] bool canResumeWhilePaused If set to true, the timer will tick down even while the game is paused, allowing the coroutine to resume in the paused state. By default, pausing the game will also pause the wait timer.
-- @usage eventu.run(function()
--			eventu.wait(2)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
-- @see eventu.waitFrames
eventu.wait = eventu.waitSeconds

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine until the specified key is pressed.
-- @tparam keycode key The keycode to listen for.
-- @usage eventu.run(function()
--			eventu.waitForInput(KEY_JUMP)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
function eventu.waitForInput(key)
		local co = getCurrentCoroutine();
		inputQueue[co] = key;

		-- And suspend the process
		return coroutine.yield (co)
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine until the given flag is signalled.
-- @param flag The flag object to listen for. If a table is provided (and the isTable field is not true), this will be considered as a list of flags, all of which must be signalled before resuming.
-- @tparam[opt=false] bool isTable Whether the flag object is a table. If this is false, and the "flag" parameter is a table, it will be considered to be a list of flags to listen for, rather than a single object.
-- @usage eventu.run(function()
--			eventu.waitSignal("mySignal")
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.run(function()
--			eventu.waitSignal({"mySignal1", "mySignal2"})
--			myVar = myVar+1
-- 	   end)
-- @usage local myTable = {a=0, b=1}
-- eventu.run(function()
--			eventu.waitSignal(myTable, true)
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
-- @see eventu.signal
function eventu.waitSignal(name, signalIsTable)
		local co = getCurrentCoroutine();
		
		if(type(name) == "table") and (not signalIsTable) then
			for _,v in ipairs(name) do
				if(signalQueue[v] == nil) then
					signalQueue[v] = {};
				end
		
				table.insert(signalQueue[v], co);
			end
		else
			if(signalQueue[name] == nil) then
				signalQueue[name] = {};
			end
		
			table.insert(signalQueue[name], co);
		end
		
		-- And suspend the process
		return coroutine.yield (co)
end

--- To be used inside an eventu coroutine, and pauses the execution of the coroutine until the specified SMBX event is executed.
-- @tparam string event The name of the event to listen for.
-- @usage eventu.run(function()
--			eventu.waitEvent("myEvent")
--			myVar = myVar+1
-- 	   end)
-- @see eventu.run
function eventu.waitEvent(name)
		local co = getCurrentCoroutine();
		
		if(eventQueue[name] == nil) then
			eventQueue[name] = {};
		end
		
		table.insert(eventQueue[name], co);
		
		-- And suspend the process
		return coroutine.yield (co)
end

--- Sends a signal to resume events that were waiting for the given flag.
-- @param flag The flag to signal.
-- @usage eventu.signal("mySignal")
-- @see eventu.waitSignal
function eventu.signal(name)
		if(signalQueue[name] == nil) then return end;
		local waketable = {}
		
		for k,v in pairs(signalQueue[name]) do
			signalQueue[name][k] = nil;
			
			local dontwake = false;
			for k2,v2 in pairs(signalQueue) do
				if(k2 ~= name and table.ifind(v2,v)) then
					dontwake = true;
					break;
				end
			end
			if(not dontwake) then
				table.insert(waketable, v);
			end
		end
		signalQueue[name] = nil;
		
		for _,v in ipairs(waketable) do
			resumeCoroutine (v)
		end
end

--- To be used inside an eventu coroutine, and runs the given function every tick for the specified number of ticks, only resuming the coroutine when finished.
-- @tparam number frames The number of game ticks (approximately 1/64 seconds) to repeat the function for.
-- @tparam function function The function to be run every tick. Other wait functions CAN be used here, and will pause the execution of the repeat function. The function will be passed one argument, `t`, containing the current loop count.
-- @tparam[opt=false] bool canResumeWhilePaused If set to true, the timer will tick down even while the game is paused, allowing the coroutine to resume in the paused state. By default, pausing the game will also pause the wait timer.
-- @usage eventu.run(function()
--			eventu.loop(100, function(t) myVar = myVar + 1 end)
-- 	   end)
-- @see eventu.run
-- @see eventu.waitFrames
function eventu.loop(t, func, canResumeWhilePaused)
	for i=1,t do
		func(i)
		eventu.waitFrames(1, canResumeWhilePaused)
	end
end

--- Creates a coroutine that counts down the given number of seconds, and then runs the provided function.
-- @function setTimer
-- @tparam number secs The number of game-time seconds to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] bool repeat If set to true, the timer will repeat once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setTimer(4, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setTimer(4, myFunc, true)

--- Creates a coroutine that counts down the given number of seconds, and then runs the provided function.
-- @tparam number secs The number of game-time seconds to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] int repeat If set, the timer will repeat the given number of times once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setTimer(4, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setTimer(4, myFunc, 2)
function eventu.setTimer(secs, func, repeated)	
		local f;
		if(repeated == nil or type(repeated) ~= "number") then
			repeated = repeated or false;
			
			f = function()	
						repeat
							eventu.waitSeconds(secs);
							func();
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								repeated = false;
							end
						until repeated == false;
					end
		else
			f = function()	
						for i=1,repeated do
							eventu.waitSeconds(secs);
							func(i);
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								break;
							end
						end
					end
		end
		local _,c = eventu.run(f);
		return c;
end

--- Creates a coroutine that counts down the given number of real-time seconds (adjusted for framerate), and then runs the provided function.
-- @function setRealTimer
-- @tparam number secs The number of real-time seconds to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] bool repeat If set to true, the timer will repeat once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setRealTimer(4, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setRealTimer(4, myFunc, true)

--- Creates a coroutine that counts down the given number of real-time seconds (adjusted for framerate), and then runs the provided function.
-- @tparam number secs The number of real-time seconds to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] int repeat If set, the timer will repeat the given number of times once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setRealTimer(4, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setRealTimer(4, myFunc, 2)
function eventu.setRealTimer(secs, func, repeated)	
		local f;
		if(repeated == nil or type(repeated) ~= "number") then
			repeated = repeated or false;
			
			f = function()	
						repeat
							eventu.waitRealSeconds(secs);
							func();
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								repeated = false;
							end
						until repeated == false;
					end
		else
			f = function()	
						for i=1,repeated do
							eventu.waitRealSeconds(secs);
							func(i);
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								break;
							end
						end
					end
		end
		local _,c = eventu.run(f);
		return c;
end

--- Creates a coroutine that counts down the given number of game ticks, and then runs the provided function.
-- @function setFrameTimer
-- @tparam number frames The number of game ticks (approximately 1/64 seconds) to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] bool repeat If set to true, the timer will repeat once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setFrameTimer(200, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setFrameTimer(200, myFunc, true)

--- Creates a coroutine that counts down the given number of game ticks, and then runs the provided function.
-- @tparam number frames The number of game ticks (approximately 1/64 seconds) to count down before running the function.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt] int repeat If set, the timer will repeat the given number of times once the function has finished executing.
-- @treturn coroutine The coroutine object.
-- @usage eventu.setFrameTimer(200, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.setTimer(200, myFunc, 2)
function eventu.setFrameTimer(frames, func, repeated)
		local f;
		if(repeated == nil or type(repeated) ~= "number") then
			repeated = repeated or false;
			
			f = function()
						repeat
							eventu.waitFrames(frames);
							func();
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								repeated = false;
							end
						until repeated == false;
					end
			
		else
			f = function()
						for i = 1,repeated do
							eventu.waitFrames(frames);
							func(i);
							local co = getCurrentCoroutine();	
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								break;
							end
						end
					end
		end
		local _,c = eventu.run(f);
		return c;
end

--- Pauses a given coroutine timer that is currently counting down.
-- @tparam coroutine event A coroutine currently waiting on a timer, which should be paused.
-- @usage local c = eventu.setTimer(200, myFunc)
--eventu.pauseTimer(c)
-- @see setTimer
-- @see setFrameTimer
-- @see resumeTimer
function eventu.pauseTimer(co)
		pausedQueue[co] = true;	
end

--- Resumes a given coroutine timer that was previously paused.
-- @tparam coroutine event A coroutine currently waiting on a timer, which was previously paused and should be resumed.
-- @usage local c = eventu.setTimer(200, myFunc)
--eventu.pauseTimer(c)
--eventu.resumeTimer(c)
-- @see setTimer
-- @see setFrameTimer
-- @see pauseTimer
function eventu.resumeTimer(co)
		pausedQueue[co] = nil;
end

--- Returns the current timer count of a given coroutine that is currently waiting on a timer.
-- @tparam coroutine event A coroutine currently waiting on a timer, the remaining time of which should be returned.
-- @treturn number The current remaining time of the given timer. May be in seconds or ticks, depending on which type of timer was used. Will return 0 if the coroutine is not waiting on a timer.
-- @usage local c = eventu.setTimer(200, myFunc)
--eventu.getTimer(c)
-- @see setTimer
-- @see setFrameTimer
function eventu.getTimer(co)
		if(secondsQueue[co] ~= nil) then
			return secondsQueue[co];
		elseif(framesQueue[co] ~= nil) then
			return framesQueue[co];
		else
			return 0;
		end
end

--- To be used inside an eventu coroutine timer, and forces it to cancel any future execution or repetitions.
-- @usage eventu.setFrameTimer(200, function()
--			myVar = myVar+1
--			eventu.breakTimer()
-- 	   end, 2)
-- @see eventu.setTimer
-- @see eventu.setFrameTimer
function eventu.breakTimer()
		local co = getCurrentCoroutine();
		breakQueue[co] = true;
end

--- Aborts a currently waiting eventu coroutine, preventing it from resuming.
-- @tparam coroutine event A coroutine that is currently waiting to resume, and should be prevented from doing so.
-- @usage local _,c = eventu.run(function()
--			eventu.waitFrames(100)
--			myVar = myVar+1
-- 	   end)
-- eventu.abort(c)
-- @see eventu.run
function eventu.abort(co)
	if(co ~= nil) then
		secondsQueue[co] = nil;
		runpaused_secs[co] = nil;
		framesQueue[co] = nil;
		runpaused_frames[co] = nil;
		inputQueue[co] = nil;
		for k,v in pairs(signalQueue) do
			for l,w in ipairs(v) do
				if(w == co) then
					table.remove(v,l);
					break;
				end
			end
		end
		for k,v in pairs(eventQueue) do
			for l,w in ipairs(v) do
				if(w == co) then
					table.remove(v,l);
					break;
				end
			end
		end
		pausedQueue[co] = nil;
	else
		Misc.warn("Tried to abort a nil coroutine.",2);
	end
end

--- Creates a coroutine that waits for a given key event, and then runs the provided function.
-- @tparam keycode key The keycode to listen for.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt=false] bool consume If set to false, the function will run every time the given key event is triggered. Otherwise, the event will be "consumed" after the first key press.
-- @treturn coroutine The coroutine object.
-- @usage eventu.registerKeyEvent(KEY_JUMP, function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.registerKeyEvent(KEY_JUMP, myFunc, true)
function eventu.registerKeyEvent(key, func, consume)
		consume = consume or false;
		local _,c = eventu.run(function()
						repeat
							eventu.waitForInput(key);
							func();
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								consume = true;
							end
						until consume == true;
					end);
		return c;
end

--- Creates a coroutine that waits for a given SMBX event, and then runs the provided function.
-- @tparam string event The name of the event to listen for.
-- @tparam function func The function that should be run. Can contain wait processes.
-- @tparam[opt=true] bool repeated If set to true, the function will run every time the given SMBX event is triggered. Otherwise, the event will be "consumed" after the first time the event is activated.
-- @treturn coroutine The coroutine object.
-- @usage eventu.registerSMBXEvent("myEvent", function()
--			myVar = myVar+1
-- 	   end)
-- @usage eventu.registerKeyEvent("myEvent", myFunc, true)
function eventu.registerSMBXEvent(event, func, repeated)
		repeated = repeated or false;
		local _,c = eventu.run(function()
						repeat
							eventu.waitEvent(event);
							func();
							local co = getCurrentCoroutine();
							if(breakQueue[co] == true) then
								breakQueue[co] = nil;
								repeated = false;
							end
						until repeated == false;
					end);
		return c;
end


function eventu.getDebugID(co)
	return debug_ids[co]
end

return eventu;