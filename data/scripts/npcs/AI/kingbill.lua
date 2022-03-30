local kingbill = {}

local npcManager = require("npcManager")
local particles = require("particles")
local rng = require("rng")

local DIR_DOWN = DIR_RIGHT
local DIR_UP = DIR_LEFT

local sharedSettings = {
	--Vanilla settings
	gfxwidth = 384,
	gfxheight = 384,
	width = 384,
	height = 384,
	nogravity = true,
	frames = 1,
	framestyle = 1,
	noblockcollision = true,
	speed = 1,
	jumphurt = true,
	nohurt = true,
	noiceball = true,
	nowaterphysics = true,
	noyoshi = true,
	--Custom settings (specific to King Bills)
	baseSpeed = 5, --Base movement speed of NPC along its axis of travel
	
	breaksturdy = true, --Whether NPC breaks "sturdy" blocks (?/Used Blocks + SMW stone tile)
	effect = 201,
	
	vertical = false, --Whether NPC is a vertical king bill rather than a horizontal one.
	
	debug = 0 --Whether to display the hitbox and maybe some text
}

--Too lazy to do the math...
local defaultHitbox = {
	{0,28 / 512},
	{14 / 512,0},
	{90 / 512,0},
	{104 / 512,32 / 512},
	{136 / 512,32 / 512},
	{152 / 512,0},
	{264 / 512,0},
	{339 / 512,20 / 512},
	{408 / 512,60 / 512},
	{460 / 512,112 / 512},
	{500 / 512,184 / 512},
	{512 / 512,216 / 512},
	{512 / 512,296 / 512},
	{484 / 512,364 / 512},
	{464 / 512,396 / 512},
	{444 / 512,412 / 512},
	{420 / 512,416 / 512},
	{284 / 512,484 / 512},
	{260 / 512,512 / 512},
	{152 / 512,512 / 512},
	{136 / 512,480 / 512},
	{104 / 512,480 / 512},
	{90 / 512,512 / 512},
	{14 / 512,512 / 512},
	{0,484 / 512},
}

local hitboxes = {}

local exhaust_h = Misc.resolveFile("particles/p_exhaust_h.ini")
local exhaust_v = Misc.resolveFile("particles/p_exhaust_v.ini")

local exhaustTbl = {}

function kingbill.register(id, sett)
	npcManager.registerEvent(id,kingbill,"onTickNPC")
    local cfg = npcManager.setNpcSettings(table.join(sett, sharedSettings))
    hitboxes[id] = {}
    if not cfg.horizontal then
        for k,v in ipairs(defaultHitbox) do
            hitboxes[id][k] = {v[2] * cfg.width, v[1] * cfg.height}
        end
	else
        for k,v in ipairs(defaultHitbox) do
            hitboxes[id][k] = {v[1] * cfgh.width, v[2] * cfgh.height}
        end
	end
end

function kingbill.onInitAPI()
	registerEvent(kingbill,"onDraw")
end

local function collidePlayers(collider) --Returns a table of players colliding with a given collider.
	local t = {}
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(collider,p) then
			table.insert(t,p)
		end
	end
	return t
end

local function cor_forceJump(p)
	local x = p.speedY
	Routine.skip()
	p.speedY = x
end

function kingbill.onTickNPC(npc)

	local score = mem(0x00B2C8E4,FIELD_DWORD) --darned block:destroy() score
	
	--The random direction is bad, 'kay?
	if npc.direction == DIR_RANDOM then
		npc.direction = rng.irandomEntry({-1,1})
	end
	
	--Pre-init
	local data = npc.data._basegame
	
	local cfg = NPC.config[npc.id]
	--Brevity stuff
	local horz = not cfg.vertical
	
	--Initialization
	if not data.init then
		data.init = true
		if horz then
			
			data.hitbox = Colliders.Poly(npc.x,npc.y,unpack(hitboxes[npc.id]))
			data.effect = particles.Emitter(npc.x,npc.y,exhaust_h)
			data.effect:setParam("yOffset", "0:"..npc.height)
			if npc.direction == DIR_LEFT then
				data.hitbox:Scale(-1,1)
				data.hitbox:Translate(npc.width,0)
				data.effect.x = data.effect.x + npc.width
				data.effect:FlipX()
			end
		else
		
			data.hitbox = Colliders.Poly(npc.x,npc.y,unpack(hitboxes[npc.id]))
			data.effect = particles.Emitter(npc.x,npc.y,exhaust_v)
			data.effect:setParam("xOffset", "0:"..npc.width)
			if npc.direction == DIR_UP then
				data.hitbox:Scale(1,-1)
				data.hitbox:Translate(0,npc.height)
				data.effect.y = data.effect.y + npc.height
				data.effect:FlipY()
			end
		end
		exhaustTbl[data.effect] = npc
		data.respawn = lunatime.tick() > 1 --Does playing sound on the first tick just not work or what
		data.facing = npc.direction
	end
	
	if npc:mem(0x12A,FIELD_WORD) > 0 and npc:mem(0x138, FIELD_WORD) == 0 then --darned despawned/hidden npcs
		
		--Play sound if it just spawned/respawned
		if data.respawn then
			if npc:mem(0x12C,FIELD_WORD) == 0 then
				SFX.play(22)
			end
			data.respawn = false
		end
		
		if npc:mem(0x12C,FIELD_WORD) == 0 then
			if data.held then
				data.held = false
				if horz then
					npc.speedY = 0
				else
					npc.speedX = 0
				end
			end
		else
			data.held = true
		end
		
		--Update hitbox's position
		data.hitbox.x = npc.x
		data.hitbox.y = npc.y
		
		--Perform any necessary flipping
		if data.facing ~= npc.direction then
			if horz then
				data.hitbox:Scale(-1,1)
				data.hitbox:Translate(npc.width,0)
				data.effect:FlipX()
			else
				data.hitbox:Scale(1,-1)
				data.hitbox:Translate(0,npc.height)
				data.effect:FlipY()
			end
			data.effect:KillParticles()
			data.facing = npc.direction
		end
		
		--Update exhaust effect's position
		if horz then
			if npc.direction == DIR_LEFT then
				data.effect.x = npc.x + npc.width
			elseif npc.direction == DIR_RIGHT then
				data.effect.x = npc.x
			end
			data.effect.y = npc.y
		else
			data.effect.x = npc.x
			if npc.direction == DIR_UP then
				data.effect.y = npc.y + npc.height
			elseif npc.direction == DIR_DOWN then
				data.effect.y = npc.y
			end
		end
		
		--Player interaction logic
		if not(npc.friendly or npc:mem(0x12E,FIELD_WORD) > 0) then
			for _,p in ipairs(collidePlayers(data.hitbox)) do
				if p.isMega and Colliders.bounce(p, npc) then
					p.keys.jump = true
					Colliders.bounceResponse(p)
					Routine.run(cor_forceJump, p)
					npc:kill()
					local a = Animation.spawn(cfg.effect, npc.x, npc.y)
					a.speedX = npc.speedX
					a.speedY = npc.speedY
					a.direction = npc.direction
					break
				else
					p:harm()
				end
			end
		end
		
		--Smashing!
		local blocklist = Block.MEGA_SMASH
		if cfg.breaksturdy and cfg.breaksturdy ~= 0 then
			blocklist = blocklist..Block.MEGA_STURDY
		end
		local blocks = Colliders.getColliding{
			a = data.hitbox,
			b = blocklist,
			btype = Colliders.BLOCK
		}
		for _,v in ipairs(blocks) do
			v:remove(true)
		end
		blocks = Colliders.getColliding{
			a = data.hitbox,
			b = Block.MEGA_HIT,
			btype = Colliders.BLOCK
		}
		for _,v in ipairs(blocks) do
			v:hit()
		end
	
		--Movement
		if horz then
			npc.speedX = cfg.baseSpeed * npc.direction
		else
			if not npc.dontMove then
				npc.speedY = cfg.baseSpeed * npc.direction * cfg.speed
			else
				npc.speedY = 0
			end
		end
		
		--Debug
		if cfg.debug ~= 0 then
			data.hitbox:Draw()
			Text.print(npc:mem(0x12A,FIELD_WORD),0,0) --darned despawn timer
		end
	else
		if (not data.fixed) and (npc:mem(0x138, FIELD_WORD) == 2) then
			-- TEMPORARY, I HOPE HOPE HOPE
			-- Fixes collider positioning when dropped from item box.
			exhaustTbl[data.effect] = nil
			npc:transform(npc.id)
			data = npc.data._basegame
			data.fixed = true
		end
		data.respawn = true
	end
	mem(0x00B2C8E4,FIELD_DWORD,score) --darned block:destroy() score
end

function kingbill.onDraw()
	for exhaust,npc in pairs(exhaustTbl) do
		if npc.isValid then
			if ((NPC.config[npc.id].vertical and npc.speedY ~= 0) or
			((not NPC.config[npc.id].vertical) and npc.speedX ~= 0)) and
			not npc.data._basegame.respawn then
				exhaust.enabled = true
			else
				exhaust.enabled = false
			end
		else
			exhaust.enabled = false
			if exhaust:Count() == 0 then
				exhaustTbl[exhaust] = nil
			end
		end
		exhaust:Draw(-45.1) --Correct this priority if it's a bad one
	end
end

return kingbill