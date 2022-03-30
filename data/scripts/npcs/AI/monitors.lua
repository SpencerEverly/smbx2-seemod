local monitors = {}

local rewardFunctions = {}

local function triggerReward(r, p)
    Routine.waitFrames(30)
    r(p)
end

function monitors.onInitAPI()
    registerEvent(monitors, "onNPCHarm")
end

function monitors.register(id, rewardFunction)
    rewardFunctions[id] = rewardFunction
end

function monitors.onNPCHarm(event, v, reason, p)
    if rewardFunctions[v.id] and p and type(p) == "Player" then
        Routine.run(triggerReward, rewardFunctions[v.id], p)
    end
end

return monitors