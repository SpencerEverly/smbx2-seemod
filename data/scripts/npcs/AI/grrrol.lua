local npcManager = require("npcManager")
local imagic = require("imagic")

local grrrol = {}

    -----------------------------------------
   -----------------------------------------
  ------- Initialize NPC settings ---------
 -----------------------------------------
-----------------------------------------

local shared_settings = {
	frames = 4,
	framestyle = 0,
	jumphurt = true,
	nofireball = true,
	noyoshi = true,
	nohurt = false,
	jumphurt = true,
	noiceball = true,
	spinjumpsafe = true,
	iswalker = true,
	-- NPC-specific settings
	destroyblocks = true,
	isheavy=1,
	grrrolstrength=0
}

local ids = {}

local idMap = {}

function grrrol.register(settings)
    npcManager.registerEvent(settings.id, grrrol, "onDrawNPC")
    npcManager.registerEvent(settings.id, grrrol, "onTickNPC")
    npcManager.setNpcSettings(table.join(settings, shared_settings))
    idMap[settings.id] = true
    table.insert(ids, settings.id)
end

    -----------------------------------------
   -----------------------------------------
  ------- Helper functions ----------------
 -----------------------------------------
-----------------------------------------

function drawNPCFrame(id, frame, x, y, angle)
	local settings = npcManager.getNpcSettings(id)
	local priority = -45
	if settings.foreground then
		priority = -15
	end
	imagic.Draw{
		texture = Graphics.sprites.npc[id].img,
		sourceWidth = settings.gfxwidth,
		sourceHeight = settings.gfxheight,
		sourceY = frame * settings.gfxheight,
		scene = true,
		x = x + settings.gfxoffsetx + settings.gfxwidth  * 0.5,
		y = y + settings.gfxoffsety + settings.gfxheight * 0.5,
		rotation = angle,
		align = imagic.ALIGN_CENTRE,
		priority = -45
	}
end

-- stolen from 0x
local function doCollision(n, collider, heavy)
	local count = 0
	do
		if NPC.config[n.id].destroyblocks then
			local firstlist = Block.MEGA_SMASH
			--firstlist = firstlist..Block.MEGA_STURDY
			local blocks = Colliders.getColliding{
				a = collider,
				b = firstlist,
				btype = Colliders.BLOCK
			}
			for _,v in ipairs(blocks) do
				if v.y >= n.y + n.height then
					n.speedY = 0
				end
				v:remove(true)
				count = count + 1
			end
			blocks = Colliders.getColliding{
				a = collider,
				b = Block.MEGA_HIT,
				btype = Colliders.BLOCK
			}
			for _,v in ipairs(blocks) do
				--v:hit(true) --Use this one pending some newBlocks fixes
				v:hit()
				count = count + 1
			end
		end
	end
	if not n.friendly then

		-- Hit other Grrrols
		local blocks = Colliders.getColliding{
			a = collider,
			b = ids,
			btype = Colliders.NPC
		}
		for _,v in ipairs(blocks) do
			if v.idx ~= n.idx then
				local killme, killother

				local otherStrength = NPC.config[v.id].grrrolstrength

				killother = true
				if otherStrength then
					if otherStrength > heavy then
						killother = false
						killme = true
					elseif otherStrength == heavy then
						killother = false
					end
				end

				if killme then
					n:kill(HARM_TYPE_NPC)
				end
				if killother then
					v:kill(HARM_TYPE_NPC)
				end
			end
		end

		blocks = Colliders.getColliding{
			a = collider,
			b = NPC.HITTABLE,
			btype = Colliders.NPC
		}
		for _,v in ipairs(blocks) do
			if v.idx ~= n.idx and not idMap[v.id] then
				v:harm(HARM_TYPE_NPC)
			end
		end
	
	end
		
	return count
end

    -----------------------------------------
   -----------------------------------------
  ------- NPC Behaviour -------------------
 -----------------------------------------
-----------------------------------------

function grrrol.onInitAPI()
	registerEvent(grrrol, "onNPCHarm")
end

function grrrol.onNPCHarm(obj, v, rsn, culprit)
	if rsn == HARM_TYPE_NPC and idMap[v.id] then
		if culprit then
			if culprit.__type == "NPC" then
				if culprit:mem(0x132, FIELD_WORD) > 0 then
					obj.cancelled = true
				end
			end
		end
	end
end

local rad2deg = 180/math.pi

function grrrol.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x138, FIELD_WORD) > 0 then
		return
	end
	if v:mem(0x12A, FIELD_WORD) > 0 and not v.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
		local data = v.data._basegame
		-- Rotation
		if data.angle == nil then
			data.angle = 0
			data.timer = 0
		else
			data.angle = data.angle + (v.speedX / (0.5 * v.height)) * rad2deg
			if v:mem(0x12C, FIELD_WORD) > 0 then
				data.angle = data.angle + 15
			end
		end
		if v:mem(0x12C, FIELD_WORD) ~= 0 then return end
		data.timer = data.timer + v.direction * v.speedX
		-- Collision
		if data.collider == nil then
			data.collider = Colliders.Box(0, 0, v.width, v.height)
		end
		data.collider.x, data.collider.y = v.x + v.speedX + 1 * math.sign(v.speedX), v.y + v.speedY + 1 * math.sign(v.speedY)
		doCollision(v, data.collider, NPC.config[v.id].grrrolstrength)
		if v:mem(0x120,FIELD_BOOL) then
			SFX.play(37)
		end
	else
		local data = v.data._basegame
		data.timer = 0
		data.angle = 0
	end
end

function grrrol.onDrawNPC(v)
	if v:mem(0x138, FIELD_WORD) > 0 then
		v.animationFrame = 0
		return
	end
	if v:mem(0x144, FIELD_WORD) > 0 then
		return
	end
	if v:mem(0x12A, FIELD_WORD) > 0 and (not v.layerObj or not v.layerObj.isHidden) and v:mem(0x124,FIELD_WORD) ~= 0 then
		local tid = v.id
		local tdir = v.data._basegame.angle or 0
		
		if tdir == nil then return end
		v.animationFrame = 999999999
		
		local drawX = v.x + 0.5 * v.width - 0.5 * NPC.config[v.id].gfxwidth
		local drawY = v.y + v.height - NPC.config[v.id].gfxheight
		
		drawNPCFrame(tid, 1, drawX, drawY, tdir)
		drawNPCFrame(tid, 2, drawX, drawY, 0)
		drawNPCFrame(tid, 3, drawX, drawY, tdir)
		local eyeOffsetX = NPC.config[v.id].eyeOffsetX
		local eyeOffsetY = -NPC.config[v.id].eyeOffsetY
		local eyeVecL = vector.v2(-eyeOffsetX, eyeOffsetY):rotate(tdir)
		local eyeVecR = vector.v2(eyeOffsetX, eyeOffsetY):rotate(tdir)

		local timer = v.data._basegame.timer or 0
		
		local eyeVecLFinal = eyeVecL + vector.v2(-3, 0):rotate(timer * 1.5)
		local eyeVecRFinal = eyeVecR + vector.v2(3, 0):rotate(-timer * 1.5)
		drawNPCFrame(tid, 4, drawX + eyeVecLFinal.x, drawY + eyeVecLFinal.y, 0)
		drawNPCFrame(tid, 4, drawX + eyeVecRFinal.x, drawY + eyeVecRFinal.y, 0)
	end
end

return grrrol