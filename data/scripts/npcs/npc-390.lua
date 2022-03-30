local npcManager = require("npcManager");

local enemyfire = {}

local npcID = NPC_ID

local fireSettings = {
	id = npcID,
	gfxheight = 16,
	gfxwidth = 16,
	width = 16,
	height = 16,
	frames = 4,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=1,
	noiceball=-1,
	noyoshi=1,
	speed=1.5,
	ignorethrownnpcs = true,
	linkshieldable = true,
	bounces=3,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.orange,
	luahandlesspeed=true,
	ishot = true
}

local fireConfig = npcManager.setNpcSettings(fireSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA
	},
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

local firespeed   = fireConfig.speed
local firebounces = fireConfig.bounces
function enemyfire.onInitAPI()
	npcManager.registerEvent(npcID, enemyfire, "onTickNPC")
end


function enemyfire.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then return end
	
	if v.collidesBlockRight or v.collidesBlockLeft or v.collidesBlockUp then
		v:kill(4)
	end
	
	if v:mem(0x136, FIELD_BOOL) then return end
	
	if math.abs(v.speedX) < NPC.config[v.id].speed then
		v.speedX = v.direction*NPC.config[v.id].speed
	end
	v.ai1=v.ai1+1
	if v.ai1==2 then 
		local e = Effect.spawn(77, v.x + v.width*0.5, v.y+v.height*0.5)
		e.x = e.x-e.width*0.5
		e.y = e.y-e.height*0.5
		v.ai1=0
	end
	if v.collidesBlockBottom then
		v.speedY=-4
		v.ai2=v.ai2+1
		if v.ai2 > firebounces then v:kill(4) end
	end
end

return enemyfire