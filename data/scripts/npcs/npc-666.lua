local prs = {}

local npcManager = require("npcManager")
local rng = require("rng")
									
local npcID = NPC_ID
local walkingBlockConfig = npcManager.setNpcSettings {
	id = npcID,
	gfxheight = 40,
	gfxwidth = 32,
	width = 32,
	height = 40,
	frames = 2,
	framestyle = 2,
	jumphurt = false,
	nofireball = true,
	noiceball = false,
	noyoshi = false,
	grabtop = true,
	playerblocktop = true,
	npcblocktop = true,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	walkshootdelay = 200,
	spawnid = 667,
	heldshootdelay = 100}
	
npcManager.registerHarmTypes(npcID, {
	HARM_TYPE_SWORD,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_TAIL,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_HELD,
	HARM_TYPE_NPC,
	HARM_TYPE_LAVA
}, {
	[HARM_TYPE_SWORD] = 63,
	[HARM_TYPE_PROJECTILE_USED] = 253,
	[HARM_TYPE_SPINJUMP] = 10,
	[HARM_TYPE_TAIL] = 253,
	[HARM_TYPE_FROMBELOW] = 253,
	[HARM_TYPE_HELD] = 253,
	[HARM_TYPE_NPC] = 253,
	[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

npcManager.registerEvent(npcID, prs, "onTickNPC", "tickGun")

local sfx_shoot = (Misc.resolveSoundFile("rinkygun-shoot"));

--Rinky Gun

local function initShooter(v)
	local data = v.data._basegame
	data.shootTimer = 0
	data.isHeld = false
	
	data.heldRinka = nil
end

local function initRinka(rink)
	local data = rink.data._basegame
	data.triggered = false
	data.thrownBy = nil
end

--I'm bascially stealing the foundation from snifits.lua, but it's okay! Prob... probably.
function prs.tickGun(v)
	
	local data = v.data._basegame
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.shootTimer = nil
		return
	end
	if data.shootTimer == nil then
		initShooter(v)
	end
	local held = v:mem(0x12C, FIELD_WORD)
	
	if v:mem(0x12E, FIELD_WORD) == 0 and held == 0 then
		--reset the shoot timer when changing between held and not held
		if data.isHeld then
			data.isHeld = false
			data.shootTimer = 0
		end
		
		--do walking guy stuff
		if data.heldRinka ~= nil then
			if (not data.heldRinka.isValid) or (data.heldRinka.ai1 == 1) then
				data.heldRinka = nil
				
				local np = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
				v.direction = math.sign((np.x + np.width/2) - (v.x + v.width/2))
			else
				v.animationTimer = 0
				v.animationFrame = 0
				data.heldRinka.x = v.x + v.width/2 - data.heldRinka.width/2
				data.heldRinka.y = v.y + v.height/2 - data.heldRinka.height/2
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			
		else
			
			if v:mem(0x138, FIELD_WORD) > 0 then return end
			if data.shootTimer >= NPC.config[v.id].walkshootdelay then
				data.heldRinka = NPC.spawn(210, v.x + v.width/2, v.y + v.height/2, v:mem(0x146, FIELD_WORD), false, true)
				data.shootTimer = 0
				data.heldRinka.layerName = "Spawned NPCs"
				data.heldRinka.friendly = v.friendly
			else
				data.shootTimer = data.shootTimer + rng.random(1, 2)
			end
			local spd = NPC.config[v.id].speed
			if v:mem(0x136, FIELD_BOOL) then return end
			if v:mem(0x12E, FIELD_WORD) == 0 and v.speedX ~= spd then
				if v.speedX == 0 then
					v.speedX = v.direction * spd
				elseif math.abs(v.speedX) > spd then
					v.speedX = v.speedX * 0.9
					if math.abs(v.speedX) < spd then
						v.speedX = v.direction * spd
					end
				else
					v.speedX = v.speedX * 1.25
					if math.abs(v.speedX) > spd then
						v.speedX = v.direction * spd
					end
				end
			end
			
		end
		
	elseif held ~= 0 then
		--reset the shoot timer when changing between held and not held
		if not data.isHeld then
			data.isHeld = true
			data.shootTimer = 0
			
			if data.heldRinka ~= nil and data.heldRinka.isValid then
				data.heldRinka:kill()
				data.heldRinka = nil
			end
		else
			if data.shootTimer >= NPC.config[v.id].heldshootdelay then
				SFX.play(sfx_shoot)
				local rink = NPC.spawn(NPC.config[v.id].spawnid, v.x + v.width/2, v.y + v.height/2, v:mem(0x146, FIELD_WORD), false, true)
				initRinka(rink)
				rink.layerName = "Spawned NPCs"
				rink.data._basegame.thrownBy = held
				rink.direction = v.direction
				data.shootTimer = 0
			else
				data.shootTimer = data.shootTimer + rng.random(1, 2)
			end
		end
	end
end

return prs
