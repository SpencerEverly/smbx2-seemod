-- Bill Blaster
local bb = {}

local npcManager = require("npcManager") -- for NPC settings and event handlers
local rng = require("rng")
local billBlaster = require("npcs/ai/billBlaster")

local npcID = NPC_ID
local BULLET_BILL_ID = 17

local billBlasterSettings = {
	id = npcID,
	frames = 8,
	gfxwidth = 44,
	gfxheight = 32, 
	width = 32,
	height = 32,
	isheavy = 1,
	
	projectileid = 17,
	coinid = 10,
}
npcManager.setNpcSettings(table.join(billBlasterSettings,billBlaster.billBlasterSharedSettings))

local function spawnBullet(npc, data, id, dir, speed)
	local x,y = npc.x,npc.y
	local w,h = npc.width,npc.height
	local cfg = NPC.config[id]

	local bullet = NPC.spawn(id, x + npc.width * .5 + npc.width * .5 * dir, y + 0.5 * h, npc.section, false, true)
	bullet.x = bullet.x + bullet.width * .5 * dir
	
	local blocked = false
	for _,v in ipairs(Player.get()) do
		if Colliders.collide(v, bullet) then
			blocked = true
			break
		end
	end
	if blocked then
		bullet:kill(HARM_TYPE_VANISH)
	else
		local held = npc:mem(0x12C, FIELD_WORD)
		if held > 0 then
			bullet:mem(0x130, FIELD_WORD, held)
			bullet:mem(0x132, FIELD_WORD, held)
			bullet:mem(0x136, FIELD_BOOL, true)
		end
		bullet.direction = dir
		bullet.speedX = speed*dir
		if cfg.iscoin then
			bullet.ai1 = 1
			bullet.speedY = RNG.random(-4,0)
		end
		bullet.friendly = npc.friendly
		bullet.layerName = "Spawned NPCs"
		
		SFX.play(22)
		local effect = Animation.spawn(10,npc.x + 0.5*w + w * dir,npc.y + h*.5)
		effect.x = effect.x - effect.width * .5
		effect.y = effect.y - effect.height * .5
		
		return true -- indicate a successful spawn
	end
end

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

npcManager.registerEvent(npcID, billBlaster, "onStartNPC", "onStartBillBlaster")
npcManager.registerEvent(npcID, bb, "onTickNPC", "onTickBillBlaster")
npcManager.registerEvent(npcID, bb, "onStartNPC")

--------------------------------------------------
-- onStartNPC 
--  initialize the contained NPC value
--------------------------------------------------
function bb.onStartNPC(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	local cfg = NPC.config[npcID]
	
	if settings.projectile == nil or settings.projectile == 0 then
		data.projectileID = cfg.projectileid
	else
		data.projectileID = settings.projectile
	end
	local id = data.projectileID > 0 and data.projectileID or 10
end

--------------------------------------------------
-- onTick Bill Blaster
--	synchronize bill blasters with the global timers
--------------------------------------------------
function bb.onTickBillBlaster(npc)
	if Defines.levelFreeze then return end

	if npc:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	local data = npc.data._basegame
	local settings = npc.data._settings
	if npc:mem(0x138, FIELD_WORD) > 0 then
		data.init = false
		return
	end
	if not data.init then
		billBlaster.onStartBillBlaster(npc)
		bb.onStartNPC(npc)
	end
	
	local timer = billBlaster.timers[data.timer]
	if not timer.phase then
		billBlaster.startTimer(timer)
	end

	-- animation
	npc.animationTimer = 0 -- disable vanilla animation
	if settings.rotates then
		npc.animationFrame = (timer.frame + data.frameOffset) % NPC.config[npcID].frames
	else
		npc.animationFrame = data.frame
	end

	npc.speedX = npc.speedX * 0.96
	if math.abs(npc.speedX) < 0.1 then
		npc.speedX = 0
	end
	
	-- bullet firing
	if timer.phase == 1 then
		local direction = npc.animationFrame == 0 and DIR_LEFT or DIR_RIGHT
		if data.projectileID > 0 then
			spawnBullet(npc, data, data.projectileID, direction, 8)
		else
			local coinid = NPC.config[npcID].coinid
			for i = -1,data.projectileID,-1 do
				if not spawnBullet(npc, data, coinid, direction, RNG.random(4,8)) then
					break
				end
			end
		end
	end
end

return bb
