local rotaryLift = {}
local npcManager = require("npcManager")
local rng = require("rng")
local lineguide = require("lineguide")
local utils = require("npcs/npcutils")

local npcID = NPC_ID
rotaryLift.config = npcManager.setNpcSettings{
	id = npcID,
	gfxwidth = 0,
	gfxheight = 0,
	width = 112,
	height = 16,
	frames = 1,
	framespeed = 8,
	framestyle = 0,
	score = 0,
	blocknpctop = true,
	playerblocktop = true,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	noiceball = true,
	noyoshi = true,
	spinjumpsafe = false,
	jumphurt = true,
	ignorethrownnpcs = true,
	notcointransformable = true,
	staticdirection = true,

	radius = -1,
	force = 0.1,
	rotationspeed = 16,
	affectsNPC = true,
	forcetype = 2,
	spinTime = 200,
	coolTime = 200,
	bias = 1.85 -- Smaller values for forcetype = 2 applies greater perpendicular force at edges.
}
lineguide.registerNpcs(npcID)

if rotaryLift.config.radius == -1 then
	rotaryLift.config.radius = rotaryLift.config.width*0.5
end

local function drawLift(npc, data, sprite)
    local config = rotaryLift.config

    sprite.x = npc.x + npc.width*0.5 + config.gfxoffsetx
    sprite.y = npc.y + npc.height*0.5 + config.gfxoffsety
    local p = -45
    if config.foreground then
        p = -15
    end
	
	local y = sprite.texposition.y
	sprite.texposition.y = y - utils.gfxheight(npc)*npc.animationFrame
	sprite:draw{priority = p, sceneCoords = true}
	sprite.texposition.y = y
	utils.hideNPC(npc)
end

local function updateSizeCache(npc, data)
	data.gfxwidth = npc:mem(0xC0, FIELD_DFLOAT)
	data.gfxheight = npc:mem(0xB8, FIELD_DFLOAT)
	data.width = npc.width
	data.height = npc.height
	local img = Graphics.sprites.npc[npc.id].img
	data.imgwidth = img.width
	data.imgheight = img.height
end

local function dataCheck(npc)
	local data = npc.data._basegame
	
	local img = Graphics.sprites.npc[npc.id].img
	
	if data.sprite == nil then
		local config = rotaryLift.config
		local settings = npc.data._settings

		local w, h = utils.gfxwidth(npc), utils.gfxheight(npc)

		settings.spinTime = settings.spinTime or 200
		settings.coolTime = settings.coolTime or 200

		data.sprite = Sprite{x = npc.x, y = npc.y, width = w, height = h, texture = Graphics.sprites.npc[npcID].img, pivot = Sprite.align.CENTER}
		data.sprite.texscale = vector(img.width, img.height)
		data.timer = 0
		data.wasFriendly = npc.friendly

		if not settings.override then
			settings.spinTime = config.spinTime
			settings.coolTime = config.coolTime
		end
		data.spinning = settings.coolTime ~= 0
		
		else
		if data.gfxwidth ~= npc:mem(0xC0, FIELD_DFLOAT) or data.gfxheight ~= npc:mem(0xB8, FIELD_DFLOAT) or (data.gfxwidth == 0 and data.width ~= npc.width) or (data.gfxheight == 0 and data.height ~= npc.height) then
			data.sprite.width,data.sprite.height = getGFXSize(npc)
		end
		
		if data.imgwidth ~= img.width or data.imgheight ~= img.height then
			data.sprite.texscale = vector(img.width, img.height)
		end
	end

	updateSizeCache(npc,data)
end

local function applyForce(obj, npcCX, npcCY, dir)
	local objCX = obj.x + obj.width/2
	local objCY = obj.y + obj.height/2
	local vec
	if rotaryLift.config.forcetype == 0 then
		-- Force the object away from the rotary lift.

		vec = -vector.v2(npcCX - objCX, npcCY - objCY)*rotaryLift.config.force*dir
	elseif rotaryLift.config.forcetype == 1 then
		-- Force the object in the direction of the rotary lift's rotation.

		vec = -vector.v2(npcCX - objCX, npcCY - objCY):rotate(90)*rotaryLift.config.force*dir
	else
		-- Additional forcetype to combine the two.  Toward the center, push the object away from the rotary lift,
		-- and toward the edges, force the object in the direction of the lift's rotation (biasing toward the first
		-- slightly in our calculations, so that the object doesn't get stuck moving in circles on the rotary lift).

		sqrDist = (npcCX - objCX)^2 + (npcCY - objCY)^2
		radiusSqr = (rotaryLift.config.radius * rotaryLift.config.bias)^2
		ratio = sqrDist / radiusSqr

		vec = -(1 - ratio) * vector.v2(npcCX - objCX, npcCY - objCY)*rotaryLift.config.force +
			-ratio * vector.v2(npcCX - objCX, npcCY - objCY):rotate(90)*rotaryLift.config.force*dir
	end
	obj.speedX = vec.x
	obj.speedY = vec.y
end

local function npcfilter(v)
    local cfg = NPC.config[v.id]
    return not v:mem(0x64, FIELD_BOOL) and not v.isHidden and not cfg.nogravity and not cfg.iscoin and not cfg.isinteractable
end

function rotaryLift.onTickNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 or (npc.layerObj and npc.layerObj.isHidden) then return end
	-- if Defines.levelFreeze  or npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x12C, FIELD_WORD) ~= 0 or npc:mem(0x138, FIELD_WORD) ~= 0 then return end
	dataCheck(npc)

	utils.applyLayerMovement(npc)

	if npc:mem(0x136, FIELD_BOOL) then
		npc.speedX = 0
		npc.speedY = 0
		return
	end

	local data = npc.data._basegame
	local config = rotaryLift.config
	local settings = npc.data._settings
	local sprite = data.sprite

	data.timer = data.timer + 1
	if not data.spinning and data.timer > settings.coolTime and settings.coolTime ~= 0 then
		data.spinning = true
		data.timer = 0
		npc.friendly = true
	elseif data.spinning and data.timer > settings.spinTime and settings.spinTime ~= 0 then
		data.spinning = false
		data.timer = 0
		sprite.rotation = 0
		if not data.wasFriendly then
			npc.friendly = false
		end
	end

	if data.spinning then
		sprite:rotate(config.rotationspeed*npc.direction)
		local npcCX = npc.x + npc.width*0.5
		local npcCY = npc.y + npc.height*0.5
		local R = config.radius
		local c = Colliders.Circle(npcCX, npcCY, R)
		for _, p in ipairs(Player.getIntersecting(npcCX - R, npcCY - R, npcCX + R, npcCY + R)) do
		  if c:collide(p) then
		    applyForce(p, npcCX, npcCY, npc.direction)
		  end
		end
		if config.affectsNPC then
			for _, n in ipairs(Colliders.getColliding{a = Colliders.Circle(npcCX, npcCY, R), b = NPC.ALL, btype = Colliders.NPC, filter = npcfilter}) do
				applyForce(n, npcCX, npcCY, npc.direction)
			end
		end
	end
end

function rotaryLift.onDrawNPC(npc)
	local data = npc.data._basegame
	if npc:mem(0x12A, FIELD_WORD) <= 0 or not data.sprite then return end

	drawLift(npc, data, data.sprite)
end

function rotaryLift.onInitAPI()
	npcManager.registerEvent(npcID, rotaryLift, "onTickNPC")
	npcManager.registerEvent(npcID, rotaryLift, "onDrawNPC")
end

return rotaryLift
