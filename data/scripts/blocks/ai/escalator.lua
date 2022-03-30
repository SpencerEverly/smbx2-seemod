local escalator = {}

local blockmanager = require("blockmanager")

function escalator.register(id)
    blockmanager.registerEvent(id, escalator, "onTickBlock")
end

function escalator.onTickBlock(v)
    v.extraSpeedX = (Block.config[v.id].speed or 0) * (Block.config[v.id].direction or 0)
end

return escalator