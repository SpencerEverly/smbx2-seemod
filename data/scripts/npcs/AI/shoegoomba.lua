local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local shoegoomba = {}

local sharedSettings = {
	gfxheight = 48,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 1,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=0,
	noiceball=0,
    noyoshi=0,
    
    jumpheight=8.6,
    shoeid = 35,
    flytime = 0,
    lavaproof = false,
    spawnednpc = 0
}

local idMap = {}

function shoegoomba.register(settings)
    idMap[settings.id] = true
	npcManager.registerEvent(settings.id, shoegoomba, "onTickNPC")
	npcManager.registerEvent(settings.id, shoegoomba, "onDrawNPC")
    npcManager.setNpcSettings(table.join(settings, sharedSettings))
end


function shoegoomba.onInitAPI()
	registerEvent(shoegoomba, "onNPCKill", "onNPCKill", false)
end
function shoegoomba.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	if v:mem(0x12A, FIELD_WORD) < 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then return end
    
    local cfg = NPC.config[v.id]

	if v.collidesBlockBottom then
		v.speedX = 0
		
		if cfg.lavaproof then 				-- Fire shoe 
			local doSpawnParticles = false
			for _,b in ipairs(Block.getIntersecting(v.x+4, v.y+v.height, v.x+v.width-4, v.y+v.height+4)) do
				if Block.LAVA_MAP[b.id] and not b.isHidden and not b:mem(0x5A, FIELD_BOOL) then
					doSpawnParticles = true
				end
			end
			if doSpawnParticles then
				for i=math.random(2),0,-1 do
					Effect.spawn(74, v.x+(v.width+8)*math.random()-4, v.y+v.height-2)
				end
			end
        end
        
        if v.ai1 == 0 and cfg.spawnednpc > 0 then
            local sec = v:mem(0x146, FIELD_WORD)
            local newFire=NPC.spawn(cfg.spawnednpc, v.x+v.width/2, v.y+v.height-24, sec, false, true)
            newFire.direction=-1
            newFire.layerName = "Spawned NPCs"
            newFire.friendly = v.friendly
            newFire=NPC.spawn(cfg.spawnednpc, v.x+v.width/2, v.y+v.height-24, sec, false, true)
            newFire.direction=1
            newFire.layerName = "Spawned NPCs"
            newFire.friendly = v.friendly
            SFX.play(18)
            Animation.spawn(75, v.x+v.width/2-16, v.y+v.height-24)
        end
		
		v.ai1 = v.ai1 + 1
		v.ai2 = 0
		v.ai3 = 0
		if v.ai1 == 65 then
			v.speedY = -math.abs(cfg.jumpheight)
			v.speedX = 0
			local myplayer=Player.getNearest(v.x,v.y)
			if v.x < myplayer.x then
				v.direction = 1
			else
				v.direction = -1
			end
			v.ai2 = NPC.config[v.id].flytime
		end
	else
		v.ai1 = 0
		v.speedX = v.direction * 2
		if cfg.flytime > 0 then
			if math.random() <= 0.3 then
				Effect.spawn(80, v.x+v.width*math.random(), v.y+v.height*math.random())
			end
			if v.speedY >= 5 then
				v.ai3 = 1
			end
			if v.ai3 == 1 and v.ai2 > 0 then
				v.ai2 = v.ai2-1
				v.speedX = v.direction * 1.4
				v.speedY = math.max(v.speedY - 0.65, -4)
				if v.animationTimer == 0 then
					SFX.play(50)
				end
			end
		end
	end
end

function shoegoomba.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if v.ai1 ~= 0 and NPC.config[v.id].flytime > 0 then
		if v.direction == -1 then
			v.animationFrame = 0
		else
			v.animationFrame = NPC.config[v.id].frames
		end
	end
		
	local headoffset = 0
	
	if v.ai1 <= 20 then
		headoffset = 1 - v.ai1 / 20 
	elseif v.ai1 >= 45 then
		headoffset = (v.ai1 - 45) / 20 
    end
    
    local cfg = NPC.config[v.id]
    local height = cfg.height
    local gfxheight = cfg.gfxheight
    local headheight = gfxheight - height
	
	--head
	npcutils.drawNPC(v, {
		frame = 0,
		height = headheight,
		yOffset = headoffset * headheight
	})
	--shoulders, knees, toes
	local sourceY = headheight
	local height = height
	if v.animationFrame % 2 == 1 then
		sourceY = 0
		height = height + headheight
	end
	npcutils.drawNPC(v, {
		sourceY = sourceY,
		height = height,
		yOffset = sourceY
	})
	npcutils.hideNPC(v)
end

function shoegoomba.onNPCKill(event, npc, reason)
	if idMap[npc.id] then
		if reason == 7 or reason == 5 or reason == 2 then
			local newShoe=NPC.spawn(NPC.config[npc.id].shoeid, npc.x, npc.y, npc:mem(0x146, FIELD_WORD))
			newShoe.direction=npc.direction
			newShoe.friendly = npc.friendly
			newShoe.layerName = "Spawned NPCs"
		end
	end
end

return shoegoomba