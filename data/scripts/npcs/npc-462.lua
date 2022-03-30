local npcManager = require("npcManager")
local imagic = require("imagic")

local heart = {}

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 0,
	jumphurt = 1, 
	nohurt = 1,
	nogravity = 1, 
	noblockcollision = 1,
	nofireball = 1,
	noiceball = 1,
	noyoshi = 1,
	lightradius = 64,
	lightbrightness = 1,
	lightcolor = Color.white,
	powerup = true
})

npcManager.registerEvent(npcID, heart, "onTickNPC")
npcManager.registerEvent(npcID, heart, "onDrawNPC")

local function initHeartData(v, spawned)
	local d = v.data._basegame
	if d.trueFriendly == nil then
		d.trueFriendly = v.friendly
	end
	v.friendly = true
	d.framecd = 0
	d.frame = 0
	d.state = 0
	d.timer = 0
	d.scale = 1
	d.angle = 0
	d.scene = true
	d.spawned = spawned
end

local function getIntersectingCamera(x, y)
	for _, v in ipairs(Camera.get()) do
		if x >= v.x and x <= v.x + v.width and x >= v.y and y <= v.y + v.height then
			return v
		end
	end
	return camera
end

local function sceneToScreen(x, y)
	local c = getIntersectingCamera(x, y)
	return x - c.x + c.renderX, y - c.y + c.renderY
end

function heart.onTickNPC(v)
	if Defines.levelFreeze then return end

	if v:mem(0x12A, FIELD_WORD) <= 0 or v.isHidden then

		local d = v.data._basegame

		if d.scene then
			d.state = nil
			return
		end
	end

	local d = v.data._basegame
	if not d.state then
		-- Set up spawned hearts
		initHeartData(v, true)
	end
	-- Force camera bound hearts to stay spawned
	if not d.scene then
		v:mem(0x12A, FIELD_WORD, 100)
	end

	if d.state == 0 then -- STATE 0: Can pick up
		if d.spawned then
	
			if v:mem(0x138, FIELD_WORD) == 0 then
				v.speedY = -0.5
				if d.frame == 0 then
					v.speedX = -0.25
				else
					v.speedX = 0.25
				end
			end
		end
		
		d.timer = d.timer + 1
		
		d.scale = 1.5 - math.abs(math.sin(d.timer / 8.5)) * 0.5
		if d.scale <= 1.05 and d.framecd == 0 then
			d.framecd = 10
			if d.frame == 0 then
				d.frame = 1
			elseif d.frame == 1 then
				d.frame = 0
			end
		elseif d.framecd > 0 then
			d.framecd = d.framecd - 1
		end
		
		-- Collect
		if not d.trueFriendly then
			for _, p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				d.valuable = (p.powerup == 1)-- or (p:mem(0x16, FIELD_WORD) < 3 and p) ) -- Needs heart check
				v.speedX = 0
				v.speedY = 0
				v.x, v.y = sceneToScreen(v.x, v.y)
				d.scene = false
				d.timer = 0
				d.state = 1
				d.scale = 1
				NPC.spawn(9, p.x, p.y, p.section, false, false) -- TEMPORARY
			end
		end
	elseif d.state == 1 then -- STATE 1: Move up
		d.angle = d.angle + 360 / 65
		v.speedY = -4
		d.timer = d.timer + 1
		if d.timer >= 11 then
			d.state = 2
			v.speedY = 0
		end
	elseif d.state == 2 then -- STATE 2: Shrink
		d.angle = d.angle + 360 * 1.3 / 65
		d.scale = d.scale - 1 / 65
		if d.valuable then
			if d.scale <= 0.3 then
				d.state = 3
				local dir = math.atan2(-v.x, 128 - v.y)
				v.speedX = math.sin(dir) * 8
				v.speedY = math.cos(dir) * 8
			end
		elseif d.scale <= 0 then
			v:kill()
		end
	elseif d.state == 3 then -- STATE 3: Fly to HUD
		d.angle = d.angle + 360 / 32
		d.scale = d.scale + 0.03
		if v.x < -32 and v.y < -32 then
			v:kill()
		end
	end
end

function heart.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) > 0 and not v.layerObj.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
		local d = v.data._basegame

		if not d.state then return end

		local p = -45
		if config.foreground then
			p = -15
		end

		v.animationFrame = 9999
		imagic.Draw{
			texture = Graphics.sprites.npc[npcID].img,
			align = imagic.ALIGN_CENTRE,
			priority = p,
			scene = d.scene,
			x = v.x + v.width / 2 + config.gfxoffsetx,
			y = v.y + v.height / 2 + config.gfxoffsety,
			width = config.gfxwidth * d.scale,
			height = config.gfxheight * d.scale,
			sourceWidth = config.gfxwidth,
			sourceHeight = config.gfxheight,
			sourceY = d.frame * config.gfxheight,
			rotation = d.angle
		}
	end
end

return heart