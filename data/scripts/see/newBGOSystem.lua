local newBGOSystem = {}

local betterbgo = require("base/game/betterbgo")

--Unregister all the betterbgo events, because they are not needed for this system
unregisterEvent(betterbgo,"onDraw")
unregisterEvent(betterbgo,"onCameraDraw")

BGO._SetVanillaBGORenderFlag(false)

local oldBGOGet = BGO.get
local oldBGOGetIntersecting = BGO.getIntersecting

--BGO count.
newBGOSystem.countRaw = 0
--BGO spawned information.
newBGOSystem.bgosSpawned = {}
--Original BGO count.
local originalCount = 0
--BGO saved information.
local bgosSaved = {}
--Whenever the BGO system has started.
local bgoSystemStarted = false
--The speed var of BGOs. Used for speedX/Y.
local speedVar = 0.25
--For making the opacity for these 0
local redirectorBGOs = table.map{191,192,193,194,195,196,197,198,199,221,222}
--For keyhole-related things
local keyholeBGOs = table.map{35}

--A function that gets a BGO sourceY value, used for animating BGOs.
local function getBGOSourceYFrameValue(v)
    local BGOSaved = newBGOSystem.getConfig(v.id)
    if BGOSaved.frames > 1 then
        return BGOSaved.frameToShow * v.height
    else
        return 0
    end
end

local function animateBGO()
    for i = 1,BGO_MAX_ID do
        if bgosSaved[i] ~= nil and not Misc.isPaused() then
            local BGOSaved = newBGOSystem.getConfig(i)
            if BGOSaved.frames > 1 then
                BGOSaved.frameTimer = BGOSaved.frameTimer + 1
                if BGOSaved.frameTimer >= BGOSaved.frameSpeed then
                    BGOSaved.frameTimer = 0
                    BGOSaved.frameToShow = BGOSaved.frameToShow + 1
                    if BGOSaved.frameToShow >= BGOSaved.frames then
                        BGOSaved.frameToShow = 1
                    end
                end
            else
                BGOSaved.frameToShow = 1
            end
        end
    end
end

local function drawBGO(v)
    if not v.isHidden then
        local BGOSaved = newBGOSystem.getConfig(v.id)
        Sprite.draw{
            texture = Graphics.sprites.background[v.id].img,
            x = v.x,
            y = v.y,
            rotation = v.rotation,
            width = v.width,
            height = v.height,
            frames = BGOSaved.frames,
            frame = BGOSaved.frameToShow,
            priority = v.priority,
            color = {v.color[1], v.color[2], v.color[3], v.opacity},
            scene = true,
        }
    end
end

local function moveBGO(v)
    if v.speedX > 0 then
        v.x = v.x + v.speedX * speedVar
    elseif v.speedX < 0 then
        v.x = v.x - v.speedX * -speedVar
    end
    
    if v.speedY > 0 then
        v.y = v.y + v.speedY * speedVar
    elseif v.speedY < 0 then
        v.y = v.y - v.speedY * -speedVar
    end
end

local function setAllBGOs()
    --Set all global BGO values
    for i = 1,BGO_MAX_ID do
        if Graphics.sprites.background[i].img ~= nil then
            bgosSaved[i] = {}
            bgosSaved[i].frames = BGO.config[i].frames
            bgosSaved[i].frameSpeed = BGO.config[i].framespeed
            bgosSaved[i].frameTimer = 0
            bgosSaved[i].frameToShow = 1
        end
    end
    --Save all old BGO values
    for idx = 0, BGO.count() - 1 do
        newBGOSystem.countRaw = newBGOSystem.countRaw + 1
        originalCount = originalCount + 1

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw] = {}

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].idx = idx + 1
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isValid = true

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].layerName = BGO(idx).layerName

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHidden = BGO(idx).isHidden

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].id = BGO(idx).id

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].x = BGO(idx).x
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].y = BGO(idx).y

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].width = BGO(idx).width
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].height = BGO(idx).height

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].speedX = BGO(idx).speedX
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].speedY = BGO(idx).speedY

        --extra values below
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].priority = BGO.config[BGO(idx).id].priority
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].opacity = 1

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].color = Color.white
        
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].rotation = 0

        if keyholeBGOs[BGO(idx).id] then
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHeyhole = true
        else
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHeyhole = false
        end
    end
    bgoSystemStarted = true
end

function newBGOSystem.count()
    return newBGOSystem.countRaw
end

function newBGOSystem.getIdx(idx)
    return newBGOSystem.bgosSpawned[idx]
end

local getMT = {__pairs = ipairs}

function newBGOSystem.get(idOrTable)
    local ret = {}
    if newBGOSystem.bgosSpawned[idOrTable] ~= nil or newBGOSystem.bgosSpawned[idOrTable] ~= {} then
        if idOrTable == nil then
            for i = 1,#newBGOSystem.bgosSpawned do
                ret[#ret + 1] = newBGOSystem.bgosSpawned[i]
            end
        elseif (type(idOrTable) == "number") then
            for i = 1,#newBGOSystem.bgosSpawned do
                if idOrTable == newBGOSystem.bgosSpawned[i].id then
                    ret[#ret + 1] = newBGOSystem.bgosSpawned[i]
                end
            end
        elseif (type(idOrTable) == "table") then
            local lookup = {}
            for _,id in ipairs(idOrTable) do
                lookup[id] = true
            end
            for _,id in ipairs(idOrTable) do
                if newBGOSystem.bgosSpawned[i] ~= nil then
                    local id = newBGOSystem.bgosSpawned[i].id
                    if lookup[id] then
                        ret[#ret + 1] = newBGOSystem.bgosSpawned[i]
                    end
                else
                    ret[#ret + 1] = {}
                end
            end
        end
        setmetatable(ret, getMT)
        return ret
    else
        ret[#ret + 1] = {}
        return ret
    end
end

function newBGOSystem.getIntersecting(x1, y1, x2, y2)
    if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
        error("Invalid parameters to getIntersecting")
        return
    end

    local ret = {}
    if newBGOSystem.bgosSpawned[idOrTable] ~= nil or newBGOSystem.bgosSpawned[idOrTable] ~= {} then
        for k,v in ipairs(newBGOSystem.get()) do
            local bx = v.x
            if (x2 > bx) then
                local by = v.y
                if (y2 > by) then
                    local bw = v.width
                    if (bx + bw > x1) then
                        local bh = v.height
                        if (by + bh > y1) then
                            ret[#ret + 1] = v
                        end
                    end
                end
            end
        end
        setmetatable(ret, getMT)
        return ret
    else
        ret[#ret + 1] = {}
        return ret
    end
end

function newBGOSystem.getConfig(id)
    return bgosSaved[id]
end

function newBGOSystem.spawn(id, x, y)
    if id > 0 then
        newBGOSystem.countRaw = newBGOSystem.countRaw + 1
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw] = {}

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].id = id
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].idx = newBGOSystem.countRaw

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].x = x
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].y = y

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].width = BGO.config[id].width
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].height = BGO.config[id].height

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].speedX = 0
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].speedY = 0
        
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].layerName = "Default"

        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHidden = false
        
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].priority = BGO.config[id].priority

        if redirectorBGOs[newBGOSystem.countRaw] then
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].opacity = 0
        else
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].opacity = 1
        end
        
        newBGOSystem.bgosSpawned[newBGOSystem.countRaw].color = Color.white

        if keyholeBGOs[id] then
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHeyhole = true
        else
            newBGOSystem.bgosSpawned[newBGOSystem.countRaw].isHeyhole = false
        end
        
        return true
    else
        return false
    end
end

--This doesn't fully remove the BGO (code-wise), but it makes sure the original isn't visible
function newBGOSystem.remove(idx)
    if BGO(originalCount - 1).isValid and BGO(idx - 1).isValid and BGO(originalCount - 1).width ~= 0 and BGO(originalCount - 1).height ~= 0 then
        BGO(originalCount - 1).width = 0
        BGO(originalCount - 1).height = 0
    end
    table.remove(newBGOSystem.bgosSpawned, idx)
    newBGOSystem.countRaw = newBGOSystem.countRaw - 1
end

function newBGOSystem.onInitAPI()
    registerEvent(newBGOSystem,"onStart")
    registerEvent(newBGOSystem,"onDraw")
    registerEvent(newBGOSystem,"onTick")
end

function newBGOSystem.onStart()
    setAllBGOs()

    function BGO.get(idOrTable)
        return newBGOSystem.get(idOrTable)
    end

    function BGO.getIntersecting(idOrTable)
        return newBGOSystem.getIntersecting(idOrTable)
    end
end

function newBGOSystem.onTick()
    if bgoSystemStarted then
        for k,v in ipairs(newBGOSystem.get()) do
            --Keyhole system
            if v.isHeyhole then
                for _,p in ipairs(Player.get()) do
                    local bgoCollision = Colliders.Box(v.x, v.y, v.width, v.height)
                    if p.holdingNPC and p.holdingNPC.id == 31 and Colliders.collide(p.holdingNPC, bgoCollision) then
                        Audio.SeizeStream(p.section)
                        Audio.MusicStop()
                        SFX.play(31)
                        Level.endState(LEVEL_END_STATE_KEYHOLE)
                    end
                end
            end
        end
    end
end

function newBGOSystem.onDraw()
    if bgoSystemStarted then
        --BGO animation system
        animateBGO()
        for k,v in ipairs(newBGOSystem.get()) do
            --BGO drawing system
            drawBGO(v)
            --BGO speedX/Y system
            moveBGO(v)
        end
    end
end

return newBGOSystem