local npcManager = require("npcManager")
local rng = require("rng")
local npcID = NPC_ID

local firebros = {}

firebros.config = npcManager.setNpcSettings{
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
	friendlyProjectileid = 13
}

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

firebros.soundID = 18

local function randDir()
	return rng.irandomEntry{-1,1}
end

local function randJump()
	return rng.randomInt(-5,-4)
end

local function spawnFireballs(v, data, heldPlayer)
	local id = NPC.config[v.id].projectileID
	if v.friendly or heldPlayer then
		id = NPC.config[v.id].friendlyProjectileID
	end
	local spawn = NPC.spawn(id,v.x + 0.5 * v.width,v.y + 8,v:mem(0x146,FIELD_WORD), false, true)
	data.walk = 0
	spawn.direction = data.lockDirection
	spawn.speedX = 3 * spawn.direction
	spawn.layerName = "Spawned NPCs"
	SFX.play(firebros.soundID)
	data.count = 0
	data.shottimer = 0
	if heldPlayer and heldPlayer.upKeyPressing then
		spawn.speedY = -8
	end
end

function firebros.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v:mem(0x12A,FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.timer = nil
		data.forceFrame = 0
		data.lockDirection = v.direction
		return
	end
	
	local held = v:mem(0x12C, FIELD_WORD)
	
	if data.timer == nil then
		data.timer = 0
		data.walk = -1
		data.shottimer = 0
		data.standtimer = 0
		data.count = 0
		data.jumpshot = 0
		data.forceFrame = 0
		data.lockDirection = v.direction
	end
	
	local heldPlayer
	if held > 0 then
		heldPlayer = Player(held)
		data.lockDirection = heldPlayer.direction
	end
	
	if data.walk ~= 0 then
		
	
		if held > 0 then
			spawnFireballs(v, data, heldPlayer)
		end
	
		if v.speedY == 0 then
			if data.timer % 8 == 0 then
				data.forceFrame = (data.forceFrame + 1) % 2
			end
			if v:mem(0x12E,FIELD_WORD) == 0 then
				if Player.getNearest(v.x, v.y).x < v.x then
					data.lockDirection = -1
				else
					data.lockDirection = 1
				end
			end
			v.speedX = data.walk * 1.2 * firebros.config.speed
			data.timer = data.timer + 1
		else
			v.speedX = 0
		end
		data.shottimer = data.shottimer + 1
		if data.timer % 90 == 0 then
			data.walk = -data.walk
		end
		if data.timer % rng.randomInt(1,360) == 0 and v.collidesBlockBottom then
			v.speedY = randJump()
			v.speedX = 0
		end
		if data.count == 1 and v.speedY > -1 and v.speedX == 0 then
			spawnFireballs(v, data)
		end
		if data.shottimer % rng.randomInt(1,240) == 0 and data.shottimer > 120 then
			if v.speedY == 0 or data.jumpshoot == 1 then
				if rng.randomInt(1) == 0 and v.collidesBlockBottom then
					v.speedY = randJump()
					data.jumpshot = 1
				end
			else
				spawnFireballs(v, data)
			end
		end
	else
		v.speedX = 0
		data.jumpshot = 0
		data.forceFrame = 2
		data.standtimer = data.standtimer + 1

		if data.standtimer > 20 then

			data.forceFrame = 0
			data.standtimer = 0
			data.walk = randDir()
			if rng.randomInt(1) == 0 and v.collidesBlockBottom then
				v.speedY = randJump()
			end
		end
	end
end

function firebros.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data._basegame
	if data.forceFrame then
		v.animationTimer = 500
		v.animationFrame = data.forceFrame
		if data.lockDirection == 1 then v.animationFrame = v.animationFrame + 3 end
	end
end

function firebros.onInitAPI()
	npcManager.registerEvent(npcID, firebros, "onTickEndNPC")
	npcManager.registerEvent(npcID, firebros, "onDrawNPC")
end

addNPCToGlobalTable(npcID, firebros)

return firebros
