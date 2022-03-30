local npcManager = require("npcManager")

local balls = {}

local npcID = NPC_ID

local ballsSettings = {
	id = npcID,
	gfxheight = 96,
	gfxwidth = 96,
	width = 44,
	height = 80,
	frames = 8,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	spinjumpsafe=-1,
	isheavy = 2
}

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_LAVA}, 
{
[HARM_TYPE_SPINJUMP]=257,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

local configFile = npcManager.setNpcSettings(ballsSettings)
local stompSfx = Misc.resolveSoundFile("chuck-stomp")
local thumpSFX = Misc.resolveSoundFile("bowlingball")

function balls.onInitAPI()
	npcManager.registerEvent(npcID, balls, "onTickNPC")
end

function balls.onTickNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12A, FIELD_WORD) <= 0
		or v:mem(0x138, FIELD_WORD) > 0 then return end
	
	v.speedX = math.clamp(v.speedX, -2, 2)

	if v.collidesBlockBottom then
		if (v.ai1 > 0) then
			if v.ai3 < 4 then
				if v.ai2 == 0 then --hasPlayedSound
					SFX.play(thumpSFX)
					v.ai2 = 1
					v.ai5 = 1 --initial fall
					Defines.earthquake = 5
				else
					SFX.play(stompSfx)
				end
				v.ai3 = v.ai3 + 1 --bounce count
				v.speedY = -6.5/v.ai3
			else
				v.ai3 = 0
				v.ai2 = 0
			end
		end
		v.speedX = 2 * v.direction
	else
		if v.ai3 == 0 and v.ai5 == 0 then
			v.animationFrame = 0
			v.animationTimer = 8
		end
	end
	v.ai1 = v.ai1 + 1
	if v.collidesBlockBottom then
		v.ai1 = 0 --collision check
	end
	if v.ai1 > 60 then
		v.ai3 = 0
		v.ai2 = 0
	end
	if v.collidesBlockLeft or v.collidesBlockRight then
		v:kill(8)
		SFX.play(36)
	end
end
	
return balls
