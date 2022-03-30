local configFileReader = require("configFileReader")
local npcManager = require("npcManager")
local waterleaper = require("npcs/AI/waterleaper")

local trouter = {}

--***********************************
--  DEFAULTS AND NPC CONFIGURATION  *
--***********************************

local npcID = NPC_ID;

function trouter.onInitAPI()
	waterleaper.register(npcID)

	npcManager.registerEvent(npcID, trouter, "onTickNPC");
end

local trouterData = {}

trouterData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 4,
	framespeed = 8, 
	framestyle = 0,
	score = 2,
	jumphurt = 0, 
	noblockcollision = 1,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	grabtop = 1,
	playerblocktop = 1,
	npcblocktop = 1,
	nowaterphysics=true,
	speed=0,
	--lua only
	--death stuff
	resttime=30,
	type=waterleaper.TYPE.SECTION,
	friendlyrest = true
})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=259,
[HARM_TYPE_PROJECTILE_USED]=259,
[HARM_TYPE_NPC]=259,
[HARM_TYPE_HELD]=259,
[HARM_TYPE_TAIL]=259,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});



--************
--  TROUTER  *
--************

function trouter.onTickNPC(self)
	if  Defines.levelFreeze then
		return
	end

	if self:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end

	local data = self.data._basegame

	-- Manage animation
	local framespeed = npcManager.getNpcSettings(self.id).framespeed

	self.animationTimer = 500
	if data.animTimer == nil then
		data.animTimer = 0
		data.mirror = false
	end
	data.animTimer = data.animTimer + 1
	if  data.animTimer >= framespeed  then
		data.animTimer = 0
		data.mirror = not data.mirror
	end

	local animFrame = 1
	if  self.speedY > 0  and  not isHeld  and  not isThrown  then
		animFrame = animFrame + 2
	end
	if  data.mirror  then
		animFrame = animFrame + 1
	end
	if  self.direction == DIR_RIGHT  then
		animFrame = animFrame - 2
	end

	self.animationFrame = animFrame
end

return trouter;