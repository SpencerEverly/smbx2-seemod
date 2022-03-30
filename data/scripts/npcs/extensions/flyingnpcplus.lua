local flyingplus = {}
local npcManager = require("npcManager")

local tableinsert = table.insert
local flyingIDs = {}

function flyingplus.onInitAPI()
    registerEvent(flyingplus, "onStart")
end

--catch late registrations through npc-config
function flyingplus.onStart()
    --someone please make an easier way to access a list of these
    for i=1, 1000 do
        if NPC.config[i].isflying then
            tableinsert(flyingIDs, i)
        end
    end
    if #flyingIDs > 0 then
        registerEvent(flyingplus, "onTickEnd")
    end
end

local function chase(v)
    local cx = v.x + 0.5 * v.width
    local cy = v.y + 0.5 * v.height
    local p = Player.getNearest(cx, cy)
    local d = -vector(cx - p.x + p.width, cy - p.y):normalize() * 0.1
    local speed = NPC.config[v.id].speed
    v.speedX = v.speedX + d.x * NPC.config[v.id].speed
    v.speedY = v.speedY + d.y * NPC.config[v.id].speed
    if v.collidesBlockUp then
        v.speedY = math.abs(v.speedY) + 3
    end
    v.speedX = math.clamp(v.speedX, -4, 4)
    v.speedY = math.clamp(v.speedY, -4, 4)
end

local function lowBounce(v)
    v.speedY = v.speedY + Defines.npc_grav
    if v.collidesBlockBottom then
        v.speedY = -6
    end
    v.speedX = NPC.config[v.id].speed * v.direction
end

local function flyh(v)
    v.ai2 = v.ai2 + 0.1
    v.speedX = NPC.config[v.id].speed * v.direction
    v.speedY = math.sin(v.ai2)
end

local function flyv(v)
    if v.ai3 == 0 then 
        v.ai3 = v.direction
    end
    if v.collidesBlockBottom or v.collidesBlockUp then
        v.ai3 = -v.ai3
    end
    v.speedY = NPC.config[v.id].speed * v.ai3
end

local exfuncs = {
    [4] = chase,
    [5] = lowBounce,
    [6] = flyh,
    [7] = flyv,
}

function flyingplus.onTickEnd(v)
    for k,v in ipairs(NPC.get(flyingIDs, Section.getActiveIndices())) do --npcmanager pls
        if Defines.levelFreeze then return end
        if v:mem(0x12A, FIELD_WORD) > 0 and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x136, FIELD_BOOL) == false and exfuncs[v.ai1] ~= nil then
            exfuncs[v.ai1](v)
        end
    end
end

-- Make lowBounce collide with semisolids
Misc._setSemisolidCollidingFlyType(5, true)

return flyingplus
