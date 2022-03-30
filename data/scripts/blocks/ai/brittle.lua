local brittle = {}
local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local brittleIDs = {}
local sfx = {}
local brittleIDMap = {}

function brittle.getIDs()
    return brittleIDs
end

function brittle.getIDMap()
    return brittleIDMap
end

function brittle.register(id, soundname)
    table.insert(brittleIDs, id)
    brittleIDMap[id] = true
    sfx[id] = Misc.resolveSoundFile(soundname)
    blockmanager.registerEvent(id, brittle, "onCollideBlock")
    blockmanager.registerEvent(id, brittle, "onCameraDrawBlock")
    blockmanager.registerEvent(id, brittle, "onTickBlock")
    blockmanager.registerEvent(id, blockutils, "onStartBlock", "storeContainedNPC")
end

function brittle.destroyBrittleBlock(v)
    if (v.__type == "Block" and brittleIDMap[v.id]) then
        v:remove(false)
        if sfx[v.id] then
            SFX.play(sfx[v.id])
        end
        Effect.spawn(Block.config[v.id].effectid, v)
        blockutils.spawnNPC(v)
    end
end

function brittle.onInitAPI()
    registerEvent(brittle, "onDraw")
end

function brittle.onCollideBlock(v, n)
    --if v.y + v.height < n.y + n.height then return end
    if (n.__type == "NPC" and (n:mem(0x12C, FIELD_WORD) ~= 0 or n.isHidden or n:mem(0x138, FIELD_WORD) > 0 or (not NPC.config[n.id].isheavy))) then return end
    if Block.config[v.id].semisolid and (n.y + n.height > v.y or ((type(n) == "Player" and not n:isGroundTouching()) or (n.__type == "NPC" and not n.collidesBlockBottom))) then return end
    v.data._basegame.touched = true
end

function brittle.onDraw()
    for k,v in ipairs(brittleIDs) do
        blockutils.setBlockFrame(v, -1)
    end
end

function brittle.onCameraDrawBlock(v, cam)
    local cam = Camera(cam)
    if not blockutils.visible(cam, v.x, v.y, v.width, v.height) then return end
    if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
    local frame = 0
    if v.data._basegame.touched then
        frame = 1
    end
    Graphics.drawImageToSceneWP(
        Graphics.sprites.block[v.id].img,
        v.x,
        v.y,
        0,
        v.height * frame,
        v.width,
        v.height,
        -65
    )
end

function brittle.onTickBlock(v)
    if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
    local data = v.data._basegame

    if data.touched then
        data.touched = false
    elseif data.touched == false then
        brittle.destroyBrittleBlock(v)
    end
end

return brittle