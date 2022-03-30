local npcManager = require("npcManager")
local whistle = require("npcs/ai/whistle")
local utils = require("npcs/npcutils")

local cobrats = {}

local directionOffset = {[-1]=0, [0]=0, [1]=1}
local chargeMap = {}
local hidingMap = {}


function cobrats.registerChasing(id)
	chargeMap[id] = true
	npcManager.registerEvent(id, cobrats, "onTickNPC")
	npcManager.registerEvent(id, cobrats, "onDrawNPC")
end

function cobrats.registerHiding(id)
	hidingMap[id] = true
	npcManager.registerEvent(id, cobrats, "onTickNPC")
	npcManager.registerEvent(id, cobrats, "onDrawNPC")
end


local function hitBlocks(v)
	for __, w in ipairs(Block.getIntersecting(v.x - 4 + v.speedX, v.y - 2, v.x + v.width + 4 + v.speedX, v.y + v.height + 2)) do
		if not w.isHidden and not w:mem(0x5A, FIELD_BOOL) and Block.SOLID_MAP[w.id] then
			w:hit()
			v:kill()
		end
	end
end

local function fireBullet(shootNPC, fromPlayer)
	local offs
	if shootNPC:mem(0x12C, FIELD_WORD) ~= 0 then
		offs = shootNPC.height - 22
	else
		offs = 22
	end

	local bullet = NPC.spawn(NPC.config[shootNPC.id].spawnid, shootNPC.x + shootNPC.width * .5 * (1 + shootNPC.direction), shootNPC.y + offs, shootNPC:mem(0x146, FIELD_WORD),false, true)
	bullet.direction = shootNPC.direction
	bullet.speedX = bullet.direction * 4
	bullet.friendly = shootNPC.friendly
	bullet.layerName = "Spawned NPCs"
	bullet:mem(0x156,FIELD_WORD,10)
	if fromPlayer > 0 then
		bullet.friendly = true
		bullet.speedX = bullet.speedX * 2
		bullet.data._basegame.playerFired = fromPlayer
		hitBlocks(bullet)
	end
	return bullet
end

local function cobratJump(npc)
	npc.speedY = -8
	npc.data._basegame.jumping = true
	npc.data._basegame.subtractLater = {0, 0}
end


local function setupCobrat(v)
	v.ai1 = 0             -- shoot timer for charger, jump timer for pipe
	v.ai2 = 25            -- face player timer for charger

	local data = v.data._basegame
	data.exists = true
	data.jumping = true
	data.specialJump = true
	v.speedY = -4
	v.speedX = 0
	data.mouthOpenTimer = 0
	data.forcedAnimFrame = 0
	data.hidingCounter = 0
	data.hasJumpAction = false
	data.hideCenterX = v.x
	data.hideCenterY = v.y
	data.hideCenterY = data.hideCenterY + v.height+NPC.config[v.id].hideoffset
	data.subtractLater = {0, 0}
end


--[[
local tickEvent = {[chargeID] = tickCobrat, [pipeID] = tickCobrat, [133] = tickBullet}
	if not Defines.levelFreeze and v:mem(0x12A, FIELD_WORD) > 0 and (not v.layerObj or not v.layerObj.isHidden) and v:mem(0x124,FIELD_WORD) ~= 0 then
		tickEvent[v.id](v)
	end
	--]]


function cobrats.onTickNPC(v)
	if Defines.levelFreeze  then return end 
	local data = v.data._basegame
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
		data.exists = nil
		return
	end
	local held = v:mem(0x12C, FIELD_WORD)
	if  data.exists == nil then
		setupCobrat(v)
	end


	-- Face player
	local p = Player.getNearest(v.x, v.y)
	if  (v.ai2 == 0  and  chargeMap[v.id] == false)  then
		if v.x > p.x then
			v.direction = -1;
		else
			v.direction = 1;
		end
	end


	-- Animation overriding
	if  v.animationTimer == 0  then
		data.forcedAnimFrame = (data.forcedAnimFrame+1)%2
	end

	data.mouthOpenTimer = math.max(0, data.mouthOpenTimer-1)
	if  data.mouthOpenTimer > 0  then
		data.forcedAnimFrame = 2
	end
	if  data.mouthOpenTimer == 5  then
		fireBullet(v, held)
	end


	-- Increment shooting counter
	v.ai1 = (v.ai1 + 1)%150
	v.ai2 = (v.ai2 + 1)%75

	if hidingMap[v.id] then
		local lsx,lsy = utils.getLayerSpeed(v)
		data.hideCenterX = data.hideCenterX + lsx
		data.hideCenterY = data.hideCenterY + lsy
	end

	-- Held by the player
	if  held ~= 0  then
		--v.ai1 = 0
		v.ai2 = 0
		
		if hidingMap[v.id] then
			v:transform(NPC.config[v.id].transformid)
		end

		if v.ai1 == 0 then
			data.mouthOpenTimer = 20
		end

	-- Jumping
	elseif  data.jumping  then
		if hidingMap[v.id] then
			local lsx,lsy = utils.getLayerSpeed(v)
			v.speedX = lsx
			v.speedY = v.speedY + lsy - data.subtractLater[2]
			data.subtractLater = {lsx, lsy}
		end
		if not data.hasJumpAction and not data.specialJump then
			local cfg = NPC.config[v.id]
			if  cfg.transformonjump  then
				if  math.abs(v.speedY) <= 1  then
					v:transform(cfg.transformid)
				end
			elseif  data.mouthOpenTimer == 0  and  not cfg.transformonjump  then
				data.mouthOpenTimer = 28
				data.hasJumpAction = true
			end
		end
		
		if  (v.collidesBlockBottom  or v:mem(0x04, FIELD_WORD) == 2 or v.y > data.hideCenterY)  and  v.speedY >= 0  then
			data.jumping = false
			data.hasJumpAction = false
			data.specialJump = false
			v.y = math.min(v.y, data.hideCenterY)
			
			_, v.speedY = utils.getLayerSpeed(v)
		end



	-- Hiding
	elseif hidingMap[v.id]  then
		if v.x > p.x then
			v.direction = -1;
		else
			v.direction = 1;
		end

		data.hidingCounter = (data.hidingCounter+15)%360
		v.x = data.hideCenterX
		v.y = data.hideCenterY + 4 * math.cos(math.rad(data.hidingCounter))
		v.speedX = 0
		v.speedY = 0
		local transformonjump = NPC.config[v.id].transformonjump
		if  ((not transformonjump)  and  v.ai1 == 0)
		or  ((math.abs(p.x - v.x) <= 64 or whistle.getActive())  and  transformonjump)  then
			cobratJump (v)
		end

	-- Chargers moving about while not recovering from a throw
	else
		-- Charger shooting
		if v.ai1 == 0 then
			data.mouthOpenTimer = 20
		end

		-- Set speed
		local targSpeed = NPC.config[v.id].speed * 2 
		v.speedX = v.direction * targSpeed

		-- cobrats aren't affected by quicksand
		if v:mem(0x04, FIELD_WORD) == 2  then
			v:mem(0x18, FIELD_FLOAT, 3*v.speedX)
			v.speedY = -2
		end
	end
end


function cobrats.onDrawNPC(v)
	local data = v.data._basegame
	local grabbedOffset = 0
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		return
	end
	
	if v:mem(0x12C, FIELD_WORD) ~= 0 then  grabbedOffset = 6; end;
	
	if data.exists == nil then
		setupCobrat(v)
	end
	
	local cfg = NPC.config[v.id]

	data.absAnimFrame = data.forcedAnimFrame + directionOffset[v.direction] * cfg.frames + grabbedOffset

	--Graphics.draw {type = RTYPE_TEXT, x = v.x, y = v.y-20, text = tostring(data.absAnimFrame)}--, isSceneCoordinates=true}

	if hidingMap[v.id] then
		local sprites = Graphics.sprites.npc[v.id].img;


		local _,modifier = utils.getLayerSpeed(v)
		local ext = 0;
		local prio = -75
		if cfg.foreground then
			prio = -15
		end
		local gfxwidth = cfg.gfxwidth
		local gfxheight = cfg.gfxheight
		local gfxoffsetx = cfg.gfxoffsetx
		local gfxoffsety = cfg.gfxoffsety
		
		if v.height > 0 then
			Graphics.drawImageToSceneWP(
				sprites, v.x + 0.5 * v.width - 0.5 * gfxwidth + gfxoffsetx, v.y + modifier + v.height - gfxheight + gfxoffsety, 0, gfxheight--[[data.startHeight--]]*(data.absAnimFrame), gfxwidth, gfxheight, prio
			);
		end


		if  v.animationFrame < 9999  then
			v.animationFrame = v.animationFrame+9999;
		end
	else
		v.animationFrame = data.absAnimFrame
	end
end

return cobrats