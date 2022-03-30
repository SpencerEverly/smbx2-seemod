local npcManager = require("npcManager")

local Magic = {}

local npcID = NPC_ID;

local Magic = {}

Magic.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 42, 
	gfxheight = 42, 
	width = 38, 
	height = 38, 
	frames = 16, 
	framespeed = 3, 
	gfxoffsetx = 2, 
	gfxoffsety = 2, 
	nogravity = 1, 
	noblockcollision = 1, 
	nofireball = 1, 
	noiceball = 1,
	jumphurt = 1,
	spinjumpsafe = 1,
	noyoshi=true,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	luahandlesspeed=true,
	--lua only
	movespeed = 3,
	sound = Misc.resolveSoundFile("magikoopa-magic"),
	transformations = {54, 112, 33, 185, 301, 165}
})

function Magic.onInitAPI()
    npcManager.registerEvent(Magic.config.id, Magic, "onTickNPC")
    --registerEvent(Magic, "onNPCKill")
end

--[[ function Magic.onNPCKill(ev, killedNPC, rsn)
    if (killedNPC.id == npcID) then --Magic
		local magic = killedNPC
		local data = magic.data._basegame
		data.sound:Stop()
	end 
end ]]

local function sparkle(x,y) 
	local spawnX = x + RNG.randomInt(-18, 18)
	local spawnY = y + RNG.randomInt(-18, 18)
	local anim = Animation.spawn(80, spawnX, spawnY)
	anim.x = anim.x - anim.width/4
	anim.y = anim.y - anim.height/4
end 

function Magic.onTickNPC(magic)
    if Defines.levelFreeze then return end
	local v = magic
	local data = magic.data._basegame
	if not v.isHidden and v:mem(0x124, FIELD_WORD) ~= 0 then
		if not data.initialized  then
			data.initialized = true
			data.sparkleTimer = 0
			local p = Player.getNearest(magic.x + 0.5 * magic.width, magic.y)
			data.playerX = p.x+p.width/2
			data.playerY = p.y+p.height/2
			data.direction = vector.v2(data.playerX - (magic.x+magic.width/2), data.playerY - (magic.y+magic.height/2)):normalise() * Magic.config.movespeed
			data.sound = SFX.play(Magic.config.sound)
		end
		data.sparkleTimer = (data.sparkleTimer + 1) % 4
		if(data.sparkleTimer == 0) then 
			sparkle(magic.x+magic.width/2, magic.y+magic.height/2)
		end 
		if not (v.dontMove or magic:mem(0x138, FIELD_WORD) > 0 or magic:mem(0x132, FIELD_WORD) > 0 or magic:mem(0x130, FIELD_WORD) > 0) then
				magic.speedX = data.direction.x * NPC.config[npcID].speed
				magic.speedY = data.direction.y * NPC.config[npcID].speed
			for _, intersectingBlock in pairs(Block.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if intersectingBlock.id == 90 and not intersectingBlock.isHidden then
					spawnedNpc = NPC.spawn(RNG.irandomEntry(Magic.config.transformations), intersectingBlock.x + 0.5 * intersectingBlock.width, intersectingBlock.y + intersectingBlock.height, magic:mem(0x146, FIELD_WORD))
					spawnedNpc.x = spawnedNpc.x -0.5 * spawnedNpc.width
					spawnedNpc.y = spawnedNpc.y - spawnedNpc.height
					spawnedNpc.layerName = "Spawned NPCs"
					spawnedNpc.friendly = magic.friendly
					if spawnedNpc.id == 33 then
						spawnedNpc.ai1 = 1
						spawnedNpc.speedX = RNG.random(-1, 1)
					end
					spawnedNpc.direction = RNG.randomInt(0, 1) * 2 - 1 -- either left (-1) or right (1)
					Animation.spawn(10, intersectingBlock.x, intersectingBlock.y)
					intersectingBlock:remove()
					v:kill()
					break
				elseif ((Block.SOLID_MAP[intersectingBlock.id] or Block.PLAYER_MAP[intersectingBlock.id]) and not intersectingBlock.isHidden) then
					v:kill()
				end
			end
		end
	end
	
end

return Magic