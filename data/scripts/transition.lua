--- Easing function handling for manipulating fields and individual values.
-- @module transition
-- @author PixelPest

local transition = {};

local running = {};
local waiting = {};

-- helper function to check if a table is empty
local function tableIsEmpty(t)
	if t == nil then
		return true;
	end

	for _ in pairs(t) do
		return false;
	end
	
	return true;
end

-- Returns an eased value.
-- @tparam number iteration The time elapsed, between 0 and transitionTime.
-- @tparam number start The initial value.
-- @tparam number target The target value.
-- @tparam number transitionTime The end time, at which the return value is the target value.
-- @tparam function easingFunction The transition.EASING_**** constant, or a custom easing function, determining how the property/properties change over time.
-- @tparam[opt=false] bool relative Whether the target values are offsets relative to the current values, true, or raw values, false.
-- @return number
function transition.easeValue(iteration, start, target, easingFunc, transitionTime, relative)
	local delta;

	if relative then
		delta = target;
	else
		delta = target - start;
	end

	return easingFunc(iteration, start, delta, transitionTime);
end

-- creates the coroutine to run the transition and manages what happens when it finishes
local function performTransition(obj, property, start, target, easingFunc, transitionTime, iterationEasingFunc, relative)
	local transitionObj = {};

	local co = Routine.run(
		function()
			if type(start) == "table" then
				start = table.deepclone(start);
			end
		
			for i = 1, transitionTime do
				if obj == nil then
					break;
				end
				
				if iterationEasingFunc then
					i = transition.easeValue(i, 1, transitionTime, iterationEasingFunc, transitionTime);
				end

				if type(start) == "table" then
					for key in pairs(obj[property]) do
						obj[property][key] = transition.easeValue(i, start[key], target[key], easingFunc, transitionTime, relative);
					end
				else
					obj[property] = transition.easeValue(i, start, target, easingFunc, transitionTime, relative);
				end
				
				Routine.skip()
			end
			
			running[obj][property] = {};
			
			if (waiting[obj] == nil) or ((waiting[obj] ~= nil) and (tableIsEmpty(waiting[obj][property]))) then
				running[obj][property] = nil;
			
				if tableIsEmpty(running[obj]) then
					Routine.signal(obj);
				end
			else
				local queued = waiting[obj];
			
				if (waiting[obj] ~= nil) and (waiting[obj][property] ~= nil) then
					queued = waiting[obj][property][1];
				
					if queued ~= nil then
						running[obj][property] = performTransition(
							obj, property, obj[property], queued.target, queued.easingFunc, queued.transitionTime, queued.relative
						);
						
						table.remove(waiting[obj][property], 1);
					end
				end
			end
		end
	);
	
	transitionObj.co = co;
	
	return transitionObj;
end

-- set up transition.EASING_**** constants
for name, func in pairs(require("ext/easing")) do
    transition["EASING_"..name:upper()] = func;
end

--- Yields the current coroutine until the transition is completed, then resumes it.
-- @param object
function transition.wait(obj)
	Routine.waitSignal(obj, true);
end

--- Aborts all transitions on an object and depending on the value of preserveWaiting may also destroy queued transitions.
-- @param object
-- @tparam[opt=false] bool preserveWaiting Whether or not to clear queued transitions on the object.
function transition.clear(obj, preserveWaiting)
	local runningTransitions = running[obj];

	if runningTransitions ~= nil then
		for property, t in pairs(runningTransitions) do
			if t.co ~= nil then
				t.co:abort();
			end
			
			running[obj][property] = {};
			
			if preserveWaiting then
				if (waiting[obj] ~= nil) and (waiting[obj][property] ~= nil) then
					local queued = waiting[obj][property][1];
					
					runningTransitions[property] = performTransition(
						obj, property, obj[property], queued.target, queued.easingFunc, queued.transitionTime, queued.relative
					);
				end
			else
				running[obj][property] = nil;
			end
		end
	end
	
	if not preserveWaiting then
		waiting[obj] = {};
	end
end

--- Transitions one or more properties of an object over time, according to an easing function.
-- @param object.
-- @tparam number transitionTime The length of time, in frames, to transition the object.
-- @tparam function easingFunction The transition.EASING_**** constant, or a custom easing function, determining how the property/properties change over time.
-- @tparam table targets A list of property, target pairs.
-- @tparam[opt=transition.EASING_LINEAR] function iterationEasingFunc Determines how the iteration values change over time.
-- @tparam[opt=false] bool relative Whether the target values are offsets relative to the current values, true, or raw values, false.
-- @tparam[opt=false] override Whether or not to override a current transition on an object's property if one exists already, otherwise it is queued.
-- @return A table of transition objects on the object indexed by property of the object and the list of queued transitions on the object.
function transition.to(obj, transitionTime, easingFunc, targets, iterationEasingFunc, relative, override)
	assert(transitionTime >= 0, "Invalid value for transitionTime; must be a whole number.");

	-- all transitions that are running are added to the running table when started, and removed when completed
	-- if a transition is already running for a specified property of the object, that transition is aborted

	if running[obj] == nil then
		running[obj] = {}; -- create a table for transitions involving the object
	end
	
	local transitionList = running[obj];
	
	local queued = false;
	
	for property in pairs(targets) do
		if not tableIsEmpty(transitionList[property]) then
			if override then
				transitionList[property].co:abort();
			else
				queued = true;
			
				if waiting[obj] == nil then
					waiting[obj] = {};
				end
				
				if waiting[obj][property] == nil then
					waiting[obj][property] = {};
				end
				
				table.insert(
					waiting[obj][property],
					{
						transitionTime = transitionTime,
						easingFunc = easingFunc,
						target = targets[property],
						iterationEasingFunc = iterationEasingFunc,
						relative = relative
					}
				);
			end
		end

		if not queued then
			local transitionObj = performTransition(obj, property, obj[property], targets[property], easingFunc, transitionTime, iterationEasingFunc, relative);
			
			transitionList[property] = transitionObj;
		end
		
		queued = false;
	end
	
	return transitionList, waiting[obj];
end

return transition