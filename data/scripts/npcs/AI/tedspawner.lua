local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local torpedoTeds = {}

local STATE_WAIT = 0
local STATE_DOWN = 1
local STATE_RELEASE = 2
local STATE_UP = 3

local countDown = {}
countDown[STATE_WAIT] = true
countDown[STATE_RELEASE] = true

local anchors = {
	[-1] = -1,
	[1] = 0
}

function torpedoTeds.register(id)
	npcManager.registerEvent(id, torpedoTeds, "onTickEndNPC", "onTickEndGrip", true)
	npcManager.registerEvent(id, torpedoTeds, "onDrawNPC", "onDrawGrip")
end

function torpedoTeds.onTickEndGrip(v)
	if Defines.levelFreeze or v:mem(0x138, FIELD_WORD) > 0 then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		data.gripTimer = nil
		return
	end
	local cfg = NPC.config[v.id]
	local held = v:mem(0x12C, FIELD_WORD)
	if data.gripTimer == nil then
		data.lastHeld = held
		data.gripTimer = cfg.delay
		data.gripState = STATE_WAIT
		data.animationFrame = 0
		local yMod = -cfg.traveldistance
		if v:mem(0x138, FIELD_WORD) > 0 or held > 0 then
			yMod = 0
		end
		data.startY = v:mem(0xB0,FIELD_DFLOAT) + yMod
		if data.startY == 0 then data.startY = v.y end
		v.y = v.y + yMod
		data.direction = v.direction
	end
	if data.lastHeld > 0 and held == 0 then
		data.startY = v.y
	end
	data.lastHeld = held
	
	v.animationFrame = 500
	v.animationTimer = 500
	if v:mem(0x12C, FIELD_WORD) > 0  then return end
	local lSpeedX, lSpeedY = npcutils.getLayerSpeed(v)
    data.startY = data.startY + lSpeedY
	v.x = v.x + lSpeedX
	v.y = v.y + lSpeedY
	v.speedY = 0
	if countDown[data.gripState] then
		data.gripTimer = data.gripTimer - 1
	end
	if data.gripState == STATE_DOWN then
        if cfg.traveldistance < 0 then
            v.y = v.y - cfg.spawnspeed
            if v.y <= data.startY + cfg.traveldistance then
                data.gripState = (data.gripState + 1)%4
                data.gripTimer = cfg.delay
				if data.grippedTed.isValid then
					data.grippedTed:mem(0x12C, FIELD_WORD, 0)
				end
                data.grippedTed = nil
                v.y = data.startY + cfg.traveldistance
            end
        else
            v.y = v.y + cfg.spawnspeed
            if v.y >= data.startY + cfg.traveldistance then
                data.gripState = (data.gripState + 1)%4
                data.gripTimer = cfg.delay
				if data.grippedTed.isValid then
					data.grippedTed:mem(0x12C, FIELD_WORD, 0)
				end
                data.grippedTed = nil
                v.y = data.startY + cfg.traveldistance
            end
        end
	elseif data.gripState == STATE_UP then
        if cfg.traveldistance < 0 then
            v.y = v.y + cfg.spawnspeed
            if v.y >= data.startY then
                data.gripState = (data.gripState + 1)%4
                data.gripTimer = cfg.delay
                v.y = data.startY
            end
        else
            v.y = v.y - cfg.spawnspeed
            if v.y <= data.startY then
                data.gripState = (data.gripState + 1)%4
                data.gripTimer = cfg.delay
                v.y = data.startY
            end
        end
	end
	if data.gripState < 2 then
		data.animationFrame = 0
	else
		data.animationFrame = 1
	end
	if data.gripTimer == 0 then
		if data.gripState == STATE_WAIT then
			if v.direction == 0 then
				data.direction = -1
				if Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height).x > v.x + 0.5 * v.width then
					data.direction = -1
				end
			end
			local t = NPC.spawn(cfg.spawnid, v.x + 0.5 * v.width, v.y + v.height + NPC.config[cfg.spawnid].height * anchors[cfg.anchory], v:mem(0x146, FIELD_WORD), false, true)
			t.direction = data.direction
			t.friendly = v.friendly
			t.speedY = cfg.force
			t:mem(0x12C, FIELD_WORD, -1)
			t.layerName = "Spawned NPCs"
			data.grippedTed = t
		end
		data.gripState = (data.gripState + 1)%4
		data.gripTimer = 100
	end
	if data.grippedTed ~= nil then
		if data.grippedTed.isValid then
			data.grippedTed.x = v.x + 0.5 * v.width - 0.5 * data.grippedTed.width
			data.grippedTed.y = v.y + 0.5 * v.height + data.grippedTed.height * anchors[cfg.anchory]
		end
	end
end

function torpedoTeds.onDrawGrip(v)
	if v.isHidden or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local cfg = NPC.config[v.id]
	
	local data = v.data._basegame
	if data.gripTimer == nil then
		data.gripTimer = cfg.delay
		data.gripState = STATE_WAIT
		data.animationFrame = 0
		local yMod = -64
		if v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 then
			yMod = 0
		end
		data.startY = v:mem(0xB0,FIELD_DFLOAT) + yMod
		if data.startY == 0 then data.startY = v.y end
		v.y = v.y + yMod
		data.direction = v.direction
	end
	
	Graphics.drawImageToSceneWP(
		Graphics.sprites.npc[v.id].img,
		v.x + 0.5 * v.width - 0.5 * cfg.gfxwidth + cfg.gfxoffsetx,
		v.y + 0.5 * v.height - 0.5 * cfg.gfxheight + cfg.gfxoffsety,
		0,
		cfg.gfxheight * data.animationFrame,
		cfg.gfxwidth,
		cfg.gfxheight,
		cfg.spawnerpriority
    )
    npcutils.hideNPC(v)
    if data.grippedTed and data.grippedTed.isValid then
        local heldframe = cfg.heldframe
		cfg = NPC.config[data.grippedTed.id]

		local gfxwidth, gfxheight = cfg.gfxwidth, cfg.gfxheight
		if gfxwidth == 0 then gfxwidth = cfg.width end
		if gfxheight == 0 then gfxheight = cfg.height end

		Graphics.drawImageToSceneWP(
			Graphics.sprites.npc[data.grippedTed.id].img,
			data.grippedTed.x + 0.5 * data.grippedTed.width - 0.5 * gfxwidth + cfg.gfxoffsetx,
			data.grippedTed.y + 0.5 * data.grippedTed.height - 0.5 * gfxheight + cfg.gfxoffsety,
			0,
			(gfxheight + gfxheight * data.grippedTed.direction * cfg.framestyle) + gfxheight * heldframe,
			gfxwidth,
			gfxheight,
			NPC.config[v.id].spawnerpriority - 0.01
		)
		npcutils.hideNPC(data.grippedTed)
	end
end
	
return torpedoTeds