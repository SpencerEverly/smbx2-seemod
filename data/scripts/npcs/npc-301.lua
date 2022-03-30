local npcManager = require("npcManager")
local rng = require("rng")

local thwimp = {}
local npcID = NPC_ID

local thwimpSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 28,
	height = 28,
	frames = 1,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=1,
	noiceball=-1,
	noyoshi=1,
	nowaterphysics=true,
	spinjumpsafe = true,
	jumpspeed = 12,
	jumpforce = 7,
	speed = 1,
	luahandlesspeed=true,
	waittime = 65
}

npcManager.registerHarmTypes(npcID,
{HARM_TYPE_HELD,HARM_TYPE_NPC, HARM_TYPE_LAVA}, 
{[HARM_TYPE_HELD]=165,
[HARM_TYPE_NPC]=165,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

local stompSfx = Misc.resolveSoundFile("chuck-stomp")

local configFile = npcManager.setNpcSettings(thwimpSettings)

local STATE_WAIT = 1
local STATE_JUMP = 2

local upwardsForce = math.abs(configFile.jumpspeed) * -1
local sidewaysForce = 2.4
local waitingTime = configFile.waittime

function thwimp.onInitAPI()
	npcManager.registerEvent(npcID, thwimp, "onTickNPC")
end

function thwimp.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.direction == 0 then
		v.direction = -1
		if rng.randomInt(0,1) == 1 then
			v.direction = 1
		end
	end
	
	if data.thwimpTimerMax == nil then
		data.thwimpTimerMax = waitingTime
		data.thwimpAIState = STATE_WAIT
		data.thwimpJumpDirection = v.direction
		data.thwimpPlayedSound = false;
		data.jumpforce = 0
		data.thwimpTimer = data.thwimpTimerMax
		data.thwimpJumpSpeed = sidewaysForce
		if v.dontMove then
			data.thwimpJumpSpeed = 0
		end
	end
	
	if v:mem(0x12A, FIELD_WORD) <=0 then
		data.thwimpAIState = STATE_WAIT
		data.thwimpJumpDirection = v.direction
		data.thwimpTimer = data.thwimpTimerMax
		return
	end
	
	if (not v.isHidden) and (v:mem(0x124, FIELD_WORD) ~= 0) then
		if data.thwimpAIState == STATE_WAIT then
			data.thwimpTimer = data.thwimpTimer - 1
			if not v.collidesBlockBottom then
				data.thwimpTimer = data.thwimpTimerMax
			else
				v.speedX = 0
			end
			if data.thwimpTimer == 0 then
				data.jumpforce = configFile.jumpforce
				v.direction = data.thwimpJumpDirection
				v.speedX = data.thwimpJumpSpeed * data.thwimpJumpDirection * NPC.config[npcID].speed
				data.thwimpAIState = STATE_JUMP
			end
		else
			if v.collidesBlockBottom then
				v.speedX = 0
				data.thwimpTimer = data.thwimpTimerMax
				data.thwimpAIState = STATE_WAIT
				data.thwimpJumpDirection = -data.thwimpJumpDirection
				v.direction = data.thwimpJumpDirection
			end
		end
	end
	
	-- hi enji-senpai
	if v.collidesBlockBottom and data.thwimpPlayedSound == false then
		SFX.play(stompSfx)
		data.jumpforce = 0
		data.thwimpPlayedSound = true;
	end
	
	if data.jumpforce > 0 then
		data.jumpforce = data.jumpforce - 1
		v.speedY = upwardsForce
	end
	
	if v.speedY ~= 0 and not v.collidesBlockBottom then
		data.thwimpPlayedSound = false;
		v.speedY = v.speedY + 0.4 --better matches the jumparc of smw thwimps
	end
end
	
return thwimp
