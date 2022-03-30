local rng = require ("rng")
local npcManager = require ("npcManager")

local fryguy = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
		id=npcID,
		gfxheight=32,
		gfxwidth=32,
		width=28,
		height=28,
		frames=2,
		framestyle=1,
		jumphurt=1,
		nogravity=0,
		noblockcollision=0,
		nofireball=1,
		spinjumpsafe=true,
		lightradius=64,
		lightbrightness=1,
		lightcolor=Color.orange,
		ishot = true,
		durability = -1
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SWORD]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function fryguy.onInitAPI()
	npcManager.registerEvent(npcID, fryguy, "onTickEndNPC")
end

function fryguy.onTickEndNPC(v)
	if  Defines.levelFreeze  then  return;  end;
	
	local data = v.data._basegame;
	
	-- Only update the fryguy's behavior if it is currently on-screen
	local isHeld = v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x130, FIELD_WORD) > 0
	
	if  v:mem(0x12A, FIELD_WORD) <= 0 or isHeld then
		data.jumpTimer = nil
		return
	end

	
	-- Init data
	if  data.jumpTimer == nil  then
		data.jumpTimer = rng.randomInt(55,65)
	end

	-- Movement and animation
	data.jumpTimer = data.jumpTimer - 1

	--v.animationFrame = 1
	if  v.collidesBlockBottom then
		v.speedX = 0
	end

	if  data.jumpTimer <= 0  then
		data.jumpTimer = 85
		v.speedY = rng.random(-6,-4)

		v.speedX = rng.random(1,4)
		
		local target = Player.getNearest(v.x, v.y)
		
		if  target.x < v.x  then  v.speedX = -1*v.speedX;  end;
	end
end

return fryguy