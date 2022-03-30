-- name is a bit weird: this one runs a function only when a block is stood on by a player.

local feet = {}
local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local feetIDMap = {}

function feet.register(id, func)
    feetIDMap[id] = func
end

function feet.onInitAPI()
    registerEvent(feet, "onTickEnd")
end

function feet.onTickEnd()
    for k,p in ipairs(Player.get()) do
        if p:isGroundTouching() then
            for k,v in Block.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + 1) do
                if v.y >= p.y + p.height and feetIDMap[v.id] then
                    feetIDMap[v.id](v, p)
                end
            end
        end
    end
end

return feet