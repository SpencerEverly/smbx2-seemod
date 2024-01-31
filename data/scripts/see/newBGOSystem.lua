local newBGOSystem = {}

local betterbgo = require("base/game/betterbgo")
local Sprite = require("base/sprite")

--Unregister all the betterbgo events, because they are not needed for this system
unregisterEvent(betterbgo,"onDraw")
unregisterEvent(betterbgo,"onCameraDraw")

BGO._SetVanillaBGORenderFlag(false)

--BGO spawned information.
local bgosSpawned = {}
--BGO saved information.
local bgosSaved = {}
--BGO count.
local count = 0
--Whenever the BGO system has started.
local bgoSystemStarted = false
--The speed var of BGOs. Used for speedX/Y.
local speedVar = 0.25
--For making the opacity for these 0
local redirectorBGOs = table.map{191,192,193,194,195,196,197,198,199,221,222}

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
        count = count + 1
        bgosSpawned[count] = {}

        bgosSpawned[count].idx = idx + 1
        bgosSpawned[count].isValid = true

        bgosSpawned[count].layerName = BGO(idx).layerName

        bgosSpawned[count].isHidden = BGO(idx).isHidden

        bgosSpawned[count].id = BGO(idx).id

        bgosSpawned[count].x = BGO(idx).x
        bgosSpawned[count].y = BGO(idx).y

        bgosSpawned[count].width = BGO(idx).width
        bgosSpawned[count].height = BGO(idx).height

        bgosSpawned[count].speedX = BGO(idx).speedX
        bgosSpawned[count].speedY = BGO(idx).speedY

        --extra values below
        bgosSpawned[count].priority = BGO.config[BGO(idx).id].priority
        bgosSpawned[count].opacity = 1

        bgosSpawned[count].color = Color.white
        
        bgosSpawned[count].rotation = 0
    end
    bgoSystemStarted = true
end

function newBGOSystem.count()
    return count
end

function newBGOSystem.getIdx(idx)
    return bgosSpawned[idx]
end

function newBGOSystem.get(idOrTable)
    local ret = {}
    if idOrTable == nil then
        for i = 1,#bgosSpawned do
            ret[#ret + 1] = bgosSpawned[i]
        end
    elseif (type(idOrTable) == "number") then
        for i = 1,#bgosSpawned do
            if idOrTable == bgosSpawned[i].id then
                ret[#ret + 1] = bgosSpawned[i]
            end
        end
    elseif (type(idOrTable) == "table") then
        local lookup = {}
        for _,id in ipairs(idOrTable) do
            lookup[id] = true
        end
        for _,id in ipairs(idOrTable) do
            if bgosSpawned[i] ~= nil then
                local id = bgosSpawned[i].id
                if lookup[id] then
                    ret[#ret + 1] = bgosSpawned[i]
                end
            else
                ret[#ret + 1] = {}
            end
        end
    end
    return ret
end

function newBGOSystem.getIntersecting(x1, y1, x2, y2)
    if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
        error("Invalid parameters to getIntersecting")
        return
    end

    local ret = {}
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
    return ret
end

function newBGOSystem.getConfig(id)
    return bgosSaved[id]
end

function newBGOSystem.spawn(id, x, y)
    if id > 0 and id < BGO_MAX_ID then
        for k,v in ipairs(newBGOSystem.get()) do
            count = count + 1
            bgosSpawned[count] = {}

            bgosSpawned[count].id = id

            bgosSpawned[count].x = x
            bgosSpawned[count].y = y

            bgosSpawned[count].width = BGO.config[id].width
            bgosSpawned[count].height = BGO.config[id].height

            bgosSpawned[count].speedX = 0
            bgosSpawned[count].speedY = 0
            
            bgosSpawned[count].layerName = "Default"

            bgosSpawned[count].isHidden = false
            
            bgosSpawned[idx].priority = BGO.config[id].priority
            if redirectorBGOs[id] then
                bgosSpawned[idx].opacity = 0
            else
                bgosSpawned[idx].opacity = 1
            end
        end
        
        return true
    else
        return false
    end
end

--This doesn't fully remove the BGO (code-wise), but it makes sure the original isn't visible
function newBGOSystem.remove(idx)
    BGO(idx - 1).width = 0
    BGO(idx - 1).height = 0
    return table.remove(bgosSpawned, idx)
end

function newBGOSystem.onInitAPI()
    registerEvent(newBGOSystem,"onStart")
    registerEvent(newBGOSystem,"onDraw")
end

function newBGOSystem.onStart()
    setAllBGOs()
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