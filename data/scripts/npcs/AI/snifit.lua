-- Written by Saturnyoshi
-- "Inspired" by and some code stolen from Spinda

local npcManager = require("npcManager")

local snifits = {}

local sharedSettings = {
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 2,
	framespeed = 8,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	grabtop = 1,
	playerblocktop = 1,
	iswalker = false,
    speed = 1,
    
    burst = 0,
    interval = 48,
    jumps = false,
    prepare = true,
    shottimer = 150
}

function snifits.register(settings)
    npcManager.setNpcSettings(table.join(settings, sharedSettings))
    npcManager.registerEvent(settings.id, snifits, "onTickNPC")
end

local function hitBlocks(v, pID)
	for __, w in ipairs(Block.getIntersecting(v.x - 4 + v.speedX, v.y - 2, v.x + v.width + 4 + v.speedX, v.y + v.height + 2)) do
		if not w.isHidden and Block.SOLID_MAP[w.id] then
			local p = Player(pID)
			local pChar = p.character
			p.character = 1
			w:hit(false, p)
			p.character = pChar
			v:kill()
		end
	end
end

local function fireBullet(shootNPC, fromPlayer)
	local offs
	if shootNPC:mem(0x12C, FIELD_WORD) ~= 0 then
		offs = 10
	else
		offs = shootNPC.height - 10
	end
	local bullet = NPC.spawn(133, shootNPC.x + shootNPC.width * .5 * (1 + shootNPC.direction), shootNPC.y + offs, shootNPC:mem(0x146, FIELD_WORD))
	bullet.x = bullet.x - bullet.width/2
	bullet.y = bullet.y - bullet.height/2
	bullet.direction = shootNPC.direction
	bullet.speedX = bullet.direction * 4
	bullet.layerName = "Spawned NPCs"
	bullet.friendly = shootNPC.friendly
	bullet:mem(0x156,FIELD_WORD,10)
	if fromPlayer then
		bullet.friendly = true
		bullet.speedX = bullet.speedX * 2
		bullet.data._basegame = {playerFired = fromPlayer}
		hitBlocks(bullet, fromPlayer)
	end
	return bullet
end

local function setupSnifit(v)
	local data = v.data._basegame
	data.burstNumber = 0
	data.burstTimer = 0
	data.shootTimer = 0
	data.heldShootTimer = 0
	data.shake = 0
	data.jumpTimer = 0
end

function snifits.onTickNPC(v)
        if not Defines.levelFreeze and v:mem(0x12A, FIELD_WORD) > 0 and not v.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
        local held = v:mem(0x12C, FIELD_WORD)
        local data = v.data._basegame
        if data.shootTimer == nil then
            setupSnifit(v)
        end
        if v:mem(0x12E, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and held == 0 then
            data.heldShootTimer = 0
            data.shootTimer = data.shootTimer + 1
            if NPC.config[v.id].jumps then
                data.jumpTimer = data.jumpTimer + 1
                if v.collidesBlockBottom then
                    data.jumping = false
                    if data.jumpTimer == 132 then
                        v.speedY = -4
                        data.jumping = true
                    elseif data.jumpTimer == 194 then
                        v.speedY = -5
                        data.jumping = true
                    end
                    if data.jumpTimer > 220 then
                        data.jumpTimer = 0
                    end
                end
                if data.jumping then
                    v.animationTimer = 0
                end
            end
            if data.shootTimer >= NPC.config[v.id].shottimer - 29 and NPC.config[v.id].prepares then
                if data.shake == 1 then
                    data.shake = 0
                    v.x = v.x + 2
                else
                    data.shake = 1
                    v.x = v.x - 2
                end
                v.speedX = 0
                v.animationTimer = 0
            else
                local targSpeed = NPC.config[v.id].speed
                if math.abs(v.speedX) > targSpeed then
                    if v.speedX > 0 then
                        v.speedX = v.speedX - 0.25
                    else
                        v.speedX = v.speedX + 0.25
                    end
                else
                    v.speedX = v.direction * targSpeed
                end
            end
            if data.burstNumber > 0 then
                data.burstTimer = data.burstTimer + 1
            end
            if data.shootTimer >= NPC.config[v.id].shottimer or data.burstTimer > 20 then
                data.burstTimer = 0
                if data.burstNumber == 0 then
                    data.burstNumber = NPC.config[v.id].burst
                else
                    data.burstNumber = data.burstNumber - 1
                end
                fireBullet(v)
                data.shootTimer = 0
            end
        elseif held ~= 0 then
            data.shootTimer = 0
            data.heldShootTimer = data.heldShootTimer + 1
            local maxval = NPC.config[v.id].interval
            if data.heldShootTimer > maxval - 10 then
                v.animationTimer = 0
            end
            if data.burstNumber > 0 then
                data.burstTimer = data.burstTimer + 1
            end
            if data.heldShootTimer > maxval or data.burstTimer > 10 then
                data.burstTimer = 0
                if data.burstNumber == 0 then
                    data.burstNumber = NPC.config[v.id].burst
                else
                    data.burstNumber = data.burstNumber - 1
                end
                fireBullet(v, held)
                data.heldShootTimer = 0
            end
        end
    end
end

return snifits