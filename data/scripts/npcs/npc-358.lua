local npcManager = require("npcManager")
local rng = require("rng")
local utils = require("npcs/npcutils")

local flame = {}

local npcID = NPC_ID

npcManager.registerHarmTypes(npcID, 	
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD,
		HARM_TYPE_NPC
	}, 
	{
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SWORD]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});


npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 24,
	width = 24,
	height = 24,
	frames = 2,
	harmlessgrab=true,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=1,
	noiceball=0,
	noyoshi=0,
	nowaterphysics = true,
	spinjumpsafe=true,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.orange,
	spawnid = 359,
	ishot = true,
	durability = -1
})

function flame.onInitAPI()
	npcManager.registerEvent(npcID, flame, "onTickNPC", "onTickFlame")
end

function flame.onTickFlame(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.flameTimer = nil
		return
	end
	
	if data.flameTimer == nil then
		data.flameTimer = 0
	end
	
	if v.collidesBlockBottom then
		if data.flameTimer == 0 then
			if rng.randomInt(1) == 1 then
				utils.faceNearestPlayer(v)
			end
		end
		data.flameTimer = data.flameTimer + 1 + math.pow(rng.random(0,2),2)
		v.speedX = 0
	else
		if v.speedY > 0 then
			v.speedY = v.speedY + Defines.npc_grav * 0.5
		end
		v.speedX = 2.2 * v.direction
		if v.underwater then
			v.speedY = v.speedY - Defines.npc_grav * 2
		end
	end
	
	if data.flameTimer > 140 then
		data.flameTimer = 0
		v.speedY = -4 - rng.randomInt(2,3) * 0.7
		data.jumpHeight = 0 + rng.randomInt(0,1) * 2
		local f = NPC.spawn(NPC.config[v.id].spawnid, v.x + 0.5 * v.width, v.y + 0.5 * v.height, player.section, false, true)
		f.direction = -1
		f.friendly = v.friendly
		f.layerName = "Spawned NPCs"
	end
end
	
return flame
