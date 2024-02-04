local npcManager = require("npcManager")
local rng = require("rng")
local npcID = NPC_ID

local firebros = {}

npcManager.setNpcSettings{
	id = npcID,
	gfxoffsety = 2,
	gfxwidth = 32,
	gfxheight = 48,
	width = 32,
	height = 32,
	frames = 3,
	framespeed = 8,
	framestyle = 1,
	nogravity=0,
	speed = 1,
	projectileid = 390,
	friendlyProjectileid = 13,
	lowjumpheight = 4,
	highjumpheight = 6,
	shotcount = 2,
	walktime = 60,
	jumptimemin = 65,
	jumptimemax = 85,
	shoottimemin = 135,
	shoottimemax = 180,
	shotspeedx = 3.5,
	shotsound = 18,
	npcheldfirerate = 0.75
}

firebros.soundID = 18

npcManager.registerHarmTypes(
	npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_JUMP]={id=185, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]=185,
		[HARM_TYPE_NPC]=185,
		[HARM_TYPE_HELD]=185,
		[HARM_TYPE_TAIL]=185,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

local function spawnFireballs(v, data, heldPlayer)
	local id = NPC.config[v.id].projectileID
	if v.friendly or heldPlayer then
		id = NPC.config[v.id].friendlyProjectileID
	end
	local spawn = NPC.spawn(id,v.x + 0.5 * v.width,v.y + 8,v:mem(0x146,FIELD_WORD), false, true)
	spawn.direction = data.lockDirection
	spawn.speedX = NPC.config[v.id].shotspeedx * spawn.direction
	spawn.layerName = "Spawned NPCs"
    if type(firebros.soundID) ~= "string" then
        SFX.play(NPC.config[v.id].shotsound)
    else
        SFX.play(firebros.soundID)
    end
	if heldPlayer and heldPlayer.keys.up then
		spawn.speedY = -8
	end
end

function firebros.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 or (v.forcedState > 0 and (v.forcedState ~= 208 or v.forcedCounter1 > 0)) or v.isProjectile then
		data.timer = nil
		data.forceFrame = 0
		data.lockDirection = v.direction
		if data.wasHeld and data.wasHeld > 0 then
			v:kill(3)
		end
		return
	end

	local cfg = NPC.config[v.id]
	
	local walkframes = cfg.frames - 1
	local held = v:mem(0x12C, FIELD_WORD)

	local skipShooting = false
	if held < 0 then
		data.wasHeldByNPC = true
		skipShooting = true
	elseif held > 0 then
		data.wasHeldByNPC = false
	end

	if data.wasHeldByNPC and v.forcedState == 208 then
		held = -1
		data.lockDirection = v.direction
	end
	
	if data.timer == nil then
		data.timer = cfg.walktime * 0.5
		data.jumptimer = RNG.randomInt(cfg.jumptimemin, cfg.jumptimemax)
		data.walk = v.direction
		data.shottimer = RNG.randomInt(cfg.shoottimemin, cfg.shoottimemax)
		data.wasHeld = held
		if held ~= 0 then
			data.shottimer = 120
		end
		data.forceFrame = 0
		data.lockDirection = v.direction
	end
	
	local heldPlayer
	if held > 0 then
		heldPlayer = Player(held)
		data.lockDirection = heldPlayer.direction
	end

	if data.walk == 0 then
		data.walk = RNG.irandomEntry{-1, 1}
	end
	
	data.jumptimer = data.jumptimer - 1
	data.wasHeld = held
	
	if skipShooting then
		return
	end

	if held == 0 then
		if v.collidesBlockBottom then
			v.speedX = 0
			
			if data.timer % 8 == 0 then
				data.forceFrame = (data.forceFrame + 1) % walkframes
			end
			if v:mem(0x12E,FIELD_WORD) == 0 then
				if Player.getNearest(v.x, v.y).x < v.x then
					data.lockDirection = -1
				else
					data.lockDirection = 1
				end
			end
			v.speedX = data.walk * 1.2 * NPC.config[v.id].speed
			if data.shottimer > 20 then
				data.timer = data.timer + 1
			end

			if data.jumptimer <= 0 then
				if data.shottimer > 30 then
					v.speedY = -math.abs(NPC.config[v.id].lowjumpheight)
					v.speedX = 0
				end
				data.jumptimer = RNG.randomInt(cfg.jumptimemin, cfg.jumptimemax)
			else
				data.shottimer = data.shottimer - 1
			end
		else
			if data.jumptimer <= 0 then
				data.jumptimer = RNG.randomInt(cfg.jumptimemin, cfg.jumptimemax)
			elseif data.shottimer <= 20 then
				data.shottimer = data.shottimer - 1
			end
		end
	else
		if held < 0 then
			data.shottimer = data.shottimer - 1 * NPC.config[v.id].npcheldfirerate
		else
			data.shottimer = data.shottimer - 1
		end
		if data.shottimer <= 100 then
			spawnFireballs(v, data, heldPlayer)
			data.shottimer = 140
		end
		if data.shottimer <= 108 or data.shottimer >= 132 then
			data.forceFrame = walkframes
		else
			data.forceFrame = walkframes - 1
		end
	end

	if data.timer % cfg.walktime == 0 then
		data.walk = -data.walk
	end
	if data.shottimer <= 20 then
		v.speedX = 0
		data.forceFrame = walkframes
		if data.shottimer % 40 == 0 then
			spawnFireballs(v, data)
		end
		if data.shottimer == -40 * (cfg.shotcount - 1) + 20 and RNG.randomInt(0, 1) == 1 then
			v.speedY = -math.abs(NPC.config[v.id].highjumpheight)
		end
		if data.shottimer < -40 * (cfg.shotcount - 1) - 10 then
			data.shottimer = RNG.randomInt(cfg.shoottimemin, cfg.shoottimemax)
			data.jumptimer = data.jumptimer + 60
		end
	end
end

function firebros.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data._basegame
	if data.forceFrame then
		v.animationTimer = 500
		v.animationFrame = data.forceFrame
		if data.lockDirection == 1 then v.animationFrame = v.animationFrame + NPC.config[v.id].frames end
	end
end

function firebros.onInitAPI()
	npcManager.registerEvent(npcID, firebros, "onTickEndNPC")
	npcManager.registerEvent(npcID, firebros, "onDrawNPC")
end

addNPCToGlobalTable(npcID, firebros)

return firebros
