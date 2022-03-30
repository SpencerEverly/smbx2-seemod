local npcManager = require("npcManager")

local fliprus = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 48,
	gfxwidth = 48,
	width = 32,
	height = 32,
	frames = 4,
	framestyle = 0,
	framespeed = 6,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	noiceball=-1,
	noyoshi=-1,
	spinjumpsafe=-1,
	fliprusid = 539,
	isheavy = 1,
	iscold = true,
	durability = -1
})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=230,
[HARM_TYPE_FROMBELOW]=230,
[HARM_TYPE_PROJECTILE_USED]=230,
[HARM_TYPE_NPC]=230,
[HARM_TYPE_HELD]=230,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

function fliprus.onInitAPI()
	npcManager.registerEvent(npcID, fliprus, "onTickNPC", "onTickSnowball")
end

function fliprus.onTickSnowball(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data._basegame
	
	if v.underwater then
		v:kill(1)
		SFX.play(64)
	end
	if data.speed == nil then
		data.speed = 3
	end
	
	if data.parent then
		if data.parent.isValid then
			if data.parent.id == NPC.config[v.id].fliprusid
			and data.parent:mem(0x12A, FIELD_WORD) > 0
			then
				return
			else
				v:kill(9)
			end
		else
			v:kill(9)
		end
	elseif not v:mem(0x136, FIELD_BOOL) then
		v.speedX = v.direction * data.speed
	end
	if v.collidesBlockLeft or v.collidesBlockRight then
		v:kill(1)
		SFX.play(64)
	end
end
	
return fliprus
