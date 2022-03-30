local rng = require("rng")

local utils = {}

local npcsToReset = {}

local function addHiddenNPC(npcobject)
    local entry = {}
    entry.obj = npcobject
    entry.frame = npcobject.animationFrame
    entry.timer = npcobject.animationTimer
    table.insert(npcsToReset, entry)
end

--Turns and NPC invisible for a frame
function utils.hideNPC(npcobject)
    addHiddenNPC(npcobject)
    npcobject.animationFrame = -999
    npcobject.animationTimer = 1
end

function utils.restoreAnimation(npcobject)
    addHiddenNPC(npcobject)
end

--Shorthand for getNearest
function utils.getNearestPlayer(npcobject)
    return Player.getNearest(npcobject.x + 0.5 * npcobject.width, npcobject.y + 0.5 * npcobject.height)
end

--Automatically makes an NPC face the closest player object, the centers of each object
function utils.faceNearestPlayer(npcobject)
    local p = utils.getNearestPlayer(npcobject)
    if p.x + 0.5 * p.width > npcobject.x + 0.5 * npcobject.width then
        npcobject.direction = 1
    else
        npcobject.direction = -1
    end
end

--Returns npc frame when accounting for consistent framestyle
--[[
    args:
        frame = current frame of NPC. Defaults to animationFrame

        direction = current direction the npc should be considered facing. Defaults to vanilla direction

        frames = total frames of the current NPC frame loop. Defaults to config.frames.

        gap = if the frame loop doesn't cover the entire "left" or "right" half of the spritesheet, this value determines how many frames exist in in one of those directions in addition to the frames of the loop. In short: frames + gap = total frame count for one side

        offset = resulting frame gets clamped by frames value early on. In order to access, say, frames 3 and 4 in a frame loop clamped by 2, you'll use an offset of 3 to skip ahead to those frames.
]]

function utils.getFrameByFramestyle(npc, args)
    args = args or {}
    local cfg = NPC.config[npc.id]

    local frames = args.frames or cfg.frames
    local frame = args.frame or npc.animationFrame
    local dir = args.direction or npc.direction
    local gap = args.gap or 0
	local offset = args.offset or 0
    local totalFrames = frames + gap + offset

    local f = frame % frames
    f = f + offset
    
    if cfg.framestyle > 0 then
        if cfg.framestyle == 2 then
            if npc:mem(0x12C, FIELD_WORD) > 0 or npc:mem(0x132, FIELD_WORD) > 0 then
                f = f + 2 * totalFrames
            end
        end
        if dir == 1 then
            f = f + totalFrames
        end
    end
    return f
end


--Returns npc frame count when accounting for consistent framestyle
--[[
    args:
        frames = total frames of the current NPC frame loop. Defaults to config.frames.

        gap = if the frame loop doesn't cover the entire "left" or "right" half of the spritesheet, this value determines how many frames exist in in one of those directions in addition to the frames of the loop. In short: frames + gap = total frame count for one side

        offset = resulting frame gets clamped by frames value early on. In order to access, say, frames 3 and 4 in a frame loop clamped by 2, you'll use an offset of 3 to skip ahead to those frames.
]]

function utils.getTotalFramesByFramestyle(npc, args)
    args = args or {}
    local cfg = NPC.config[npc.id]

    local frames = args.frames or cfg.frames
    local gap = args.gap or 0
	local offset = args.offset or 0
    local totalFrames = frames + gap + offset

    local f = frames
    f = f + offset
    
    if cfg.framestyle > 0 then
        if cfg.framestyle == 2 then
                f = f + 2 * totalFrames
        end
        f = f + totalFrames
    end
    return f
end


--Renders an npc
--[[
    args:
        frame = frame to render, defaults to animationFrame,
        priority = priority to render at, defaults to -45 and -15 depending on foreground setting,
        width = width to render, defaults to config.gfxwidth
        height = height to render, defaults to config.gfxheight
        sourceX = start xOffset of render, defaults to 0
        sourceY = start yOffset of render, defaults to 0
        xOffset = x coordinate offset, defaults to config.gfxoffsetx
        yOffset = y coordinate offset, defaults to config.gfxoffsety
        texture = image, defaults to Graphics.sprites's image of the npc
        frames = override for config.frames for determining a shorter frame loop to clamp to
        opacity = opacity
        applyFrameStyle = whether to apply frame style calculations
]]
local spawnedbygenerator = {
    [1] = true,
    [3] = true,
    [4] = true,
}

function utils.drawNPC(npcobject, args)
    args = args or {}
    if npcobject.__type ~= "NPC" then
        error("Must pass a NPC object to draw. Example: drawNPC(myNPC)")
    end
    local frame = args.frame or npcobject.animationFrame

    local afs = args.applyFrameStyle
    if afs == nil then afs = true end

    local cfg = NPC.config[npcobject.id]
    
    --gfxwidth/gfxheight can be unreliable
    local trueWidth = cfg.gfxwidth
    if trueWidth == 0 then trueWidth = npcobject.width end

    local trueHeight = cfg.gfxheight
    if trueHeight == 0 then trueHeight = npcobject.height end

    --drawing position isn't always exactly hitbox position
    local x = npcobject.x + 0.5 * npcobject.width - 0.5 * trueWidth + cfg.gfxoffsetx + (args.xOffset or 0)
    local y = npcobject.y + npcobject.height - trueHeight + cfg.gfxoffsety + (args.yOffset or 0)

    --cutting off our sprite might be nice for piranha plants and the likes
    local w = args.width or trueWidth
    local h = args.height or trueHeight

    local o = args.opacity or 1

    --the bane of the checklist's existence
    local p = args.priority or -45
    if cfg.foreground then
        p = -15
    end

    if spawnedbygenerator[npcobject:mem(0x138, FIELD_WORD)] then
        p = -75
    end

    local sourceX = args.sourceX or 0
    local sourceY = args.sourceY or 0

    --framestyle is a weird thing...

    local frames = args.frames or cfg.frames
    local f = frame or 0
    --but only if we actually pass a custom frame...
    if args.frame and afs and cfg.framestyle > 0 then
        if cfg.framestyle == 2 then
            if npcobject:mem(0x12C, FIELD_WORD) > 0 or npcobject:mem(0x132, FIELD_WORD) > 0 then
                f = f + 2 * frames
            end
        end
        if npcobject.direction == 1 then
            f = f + frames
        end
    end

    Graphics.drawImageToSceneWP(args.texture or Graphics.sprites.npc[npcobject.id].img, x, y, sourceX, sourceY + trueHeight * f, w, h, o, p)
end

function utils.setRandomDirection(npc)
    npc.direction = rng.randomInt(0,1) * 2 - 1
end


function utils.onInitAPI()
    registerEvent(utils, "onDrawEnd")
end

--Let's restore the frame of our disabled bretheren
function utils.onDrawEnd()
    for i=#npcsToReset, 1, -1 do
        local v = npcsToReset[i]
        v.obj.animationFrame = v.frame
        v.obj.animationTimer = v.timer
        npcsToReset[i] = nil
    end
end

--npc_helper code

local framespeeds = {
	[134] = 2,
	[293] = 8
}

local framestyles = {
	[31] = 1,
	[183] = 1,
	[277] = 1,
	[321] = 1
}

function utils.gfxwidth(npc,id)
	id = id or npc.id
	if NPC.config[id].gfxwidth ~= 0 then
		return NPC.config[id].gfxwidth
	else
		return npc.width
	end
end

function utils.gfxheight(npc,id)
	id = id or npc.id
	if NPC.config[id].gfxheight ~= 0 then
		return NPC.config[id].gfxheight
	else
		return npc.height
	end
end

function utils.frames(npc,id)
	id = id or npc.id
	local result
	if NPC.config[id].frames ~= 0 then
		result = NPC.config[id].frames
	else
		result = Graphics.sprites.npc[id].img.height / utils.gfxheight(npc,id)
	end
	local framestyle = utils.framestyle(npc,id)
	if framestyle == 2 then
		result = result/4
	elseif framestyle == 1 then
		result = result/2
	end
	if id == 13 then
		return result/5
	elseif id == 134 then
		return result/4
	elseif id == 265 then
		return result/2
	elseif id == 291 then
		return result/3
	elseif id == 26 then
		return 1
	end
	return result
end

function utils.framespeed(npc,id)
	id = id or npc.id
	if framespeeds[id] then
		return framespeeds[id]
	elseif NPC.config[id].framespeed ~= 8 then
		return NPC.config[id].framespeed
	else
		return 4 --convenient
	end
end

function utils.framestyle(npc,id)
	id = id or npc.id
	return framestyles[id] or NPC.config[id].framestyle
end

function utils.getLayerSpeed(npc)
	local layer = npc.layerObj
	if layer and not layer:isPaused() then
		return layer.speedX, layer.speedY
	else
		return 0,0
	end
end

function utils.applyLayerMovement(npc)
	local layer = npc.layerObj
	if layer and not layer:isPaused() then
		npc.x = npc.x + layer.speedX
		npc.y = npc.y + layer.speedY
	end
end

return utils