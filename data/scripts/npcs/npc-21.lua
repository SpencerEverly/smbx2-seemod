local blaster = {}

local utils = require("npcs/npcutils")

local npcID = NPC_ID

local function spawnNPC(id, dir, v, speed)
	local n = NPC.spawn(id, v.x, v.y, v.section)
	
	n.y = n.y+v.height*0.5-n.height*0.5

	n.layerName = "Spawned NPCs"
	
	if dir == 1 then
		n.x = n.x + v.width
	else
		n.x = n.x - n.width
	end
	
	n.direction = dir
	n.speedX = dir*speed
	n.friendly = v.friendly
	
	if NPC.config[n.id].iscoin then
		n.ai1 = 1
		n.speedY = RNG.random(-4,0)
	end
	
	return n
end

function blaster.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end
	local settings = v.data._settings
	local data = v.data._basegame
	
	if (settings.projectile ~= 0 and settings.projectile ~= 17) or settings.shootWhenClose or settings.timer ~= 200 then
		v.ai1 = 0
		data.timer = (data.timer or 0)+1
		
		if data.timer >= settings.timer then
			local tooClose = false
			if not settings.shootWhenClose then
				for _,p in ipairs(Player.get()) do
					if  v.x <= p.x + p.width + 32 and v.x + v.width >= p.x - 32
					and v.y <= p.y + p.height + 300 and v.y + v.height >= p.y - 300 then
						tooClose = true
						break
					end
				end
			end
			if not tooClose then
				local id = settings.projectile
				if id == 0 then
					id = 17
				end
				
				local p = utils.getNearestPlayer(v)
				local dir
				if p.x + p.width * 0.5 > v.x + v.width * 0.5 then
					dir = 1
				else
					dir = -1
				end
				
				
				local n
				if id > 0 then
					n = spawnNPC(id, dir, v, 8)
				else
					for i = -1,id,-1 do
						n = spawnNPC(10, dir, v, RNG.random(4, 8))
					end
				end
				
				v.ai1 = 0
				data.timer = 0
				
				local e = Effect.spawn(10, n.x + n.width*0.5, n.y + n.height*0.5)
				e.x = e.x - e.width*0.5
				e.y = e.y - e.height*0.5
				SFX.play(22)
			end
		end
	end
end

function blaster.onInitAPI()
	NPC.registerEvent(blaster, "onTickNPC")
end

return blaster