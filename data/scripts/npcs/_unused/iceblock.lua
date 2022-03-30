local npcManager = require("npcManager")

local iceblock = {}

iceblock.normalID = 589
iceblock.grabbedID = 590

npcManager.setNpcSettings({
	id = iceblock.normalID,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	nohurt=true,
	playerblock=true,
	playerblocktop=true,
	npcblock=true,
	npcblocktop=true,
	nogravity = true,
	nofireball= true,
	grabside = true,
	grabtop = true,
	noiceball= true,
	noyoshi= false
})

npcManager.setNpcSettings({
	id = iceblock.grabbedID,
	width = 32,
	height = 32,
	gfxoffsety = 2,
	frames = 4,
	framestyle = 0,
	nohurt=true,
	playerblock=false,
	jumphurt = true,
	nogravity = false,
	nofireball= true,
	npcblock = false,
	playerblocktop = false,
	npcblocktop = false,
	grabside = true,
	noblockcollision=false,
	grabtop = false,
	noiceball= true,
	noyoshi= false,
})

npcManager.registerHarmTypes(iceblock.grabbedID, {HARM_TYPE_LAVA},
{[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

function iceblock.onInitAPI()
	npcManager.registerEvent(iceblock.normalID, iceblock, "onTickNPC", "onTickNormal")
	npcManager.registerEvent(iceblock.grabbedID, iceblock, "onTickEndNPC", "onTickGrabbed")
end

function iceblock.onTickNormal(v)
	local lspdx = 0
	local lspdy = 0
	local layer = npc.layerObj
	if layer and not layer:isPaused() then
		lspdx = layer.speedX
		lspdy = layer.speedY
	end
	v.speedX = lspdx
	v.speedY = lspdy
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) == 5 or v.speedX ~= 0 then
		v:transform(iceblock.grabbedID)
	end
end

function iceblock.onTickGrabbed(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.previousGrabPlayer = 0
		return
	end

	if data.time == nil then
		data.previousGrabPlayer = 0
		data.dropCooldown = 0
		data.time = 0
		data.sliding = 0
		data.yoshi = v:mem(0x138, FIELD_WORD) == 5
	elseif data.sliding == 0 then
		data.time = data.time + 1
		if data.time > 65 * 6 then
			Effect.spawn(131, v.x, v.y)
			v:kill(HARM_TYPE_PROJECTILE_USED)
		end
	end

	if data.yoshi and v:mem(134, FIELD_WORD) == 5 then
		v.speedX = 6.5 * v.direction
		v.speedY = 0
		data.sliding = math.sign(v.speedX)
	end

	if data.previousGrabPlayer > 0 and v:mem(0x136, FIELD_WORD) == -1 then
		local p = Player(data.previousGrabPlayer)
		if p and p:mem(0x108, FIELD_WORD) == 0 then
			if p.upKeyPressing then
				v.speedX = p.speedX * 0.5
				v.speedY = - 12
			elseif p.downKeyPressing then
				v.speedX = 0.5 * p.direction
				v.speedY = -0.5
			else
				--[[if p:mem(0x12E, FIELD_WORD) ~= 0 or p.speedX == 0 or (not p.rightKeyPressing and not p.leftKeyPressing) then
					v.speedX = 0.5 * p.FacingDirection
					v.speedY = -0.5
				else
					v.speedY = 0
				end]]
				v.speedX = 6 * p.direction + 0.5 * p.speedX
				v.speedY = 0
				data.sliding = math.sign(v.speedX)
			end
			data.dropCooldown = 16
		end
	end

	if v:mem(0x12C, FIELD_WORD) == 1 then
		v.collidesBlockBottom = false
	end

	if data.sliding ~= 0 then
		if v.direction ~= data.sliding then
			v:kill(HARM_TYPE_PROJECTILE_USED)
		end
	else
		if v.collidesBlockBottom then
			v.speedX = v.speedX * 0.5
		end
	end

	data.previousGrabPlayer = v:mem(0x12C, FIELD_WORD)
	data.dropCooldown = data.dropCooldown - 1
end
return iceblock
