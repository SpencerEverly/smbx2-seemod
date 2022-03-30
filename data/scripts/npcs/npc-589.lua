local npcManager = require("npcManager")
local rng = require("rng")
local waterleaper = require("npcs/AI/waterleaper")

local podoboo = {}

--***********************************
--  DEFAULTS AND NPC CONFIGURATION  *
--***********************************

local npcID = NPC_ID;

function podoboo.onInitAPI()
	waterleaper.register(npcID)

	npcManager.registerEvent(npcID, podoboo, "onTickNPC");
	registerEvent(podoboo, "onNPCHarm");
end

local trouterData = {}

trouterData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 28, 
	gfxheight = 32, 
	width = 28, 
	height = 32, 
	frames = 4,
	framespeed = 8, 
	framestyle = 0,
	score = 2,
	jumphurt = 1,
	spinjumpsafe=true,
	noblockcollision = 1,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	nowaterphysics=true,
	speed=0,
	--lua only
	--death stuff
	resttime=120,
	type=waterleaper.TYPE.LAVA,
	sound=16,
	effect=13,
	lightradius=64,
    lightbrightness=1,
    lightcolor=Color.orange,
	ishot = true,
	durability = -1

})

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL}, 
{[HARM_TYPE_PROJECTILE_USED]=10,
[HARM_TYPE_NPC]=10,
[HARM_TYPE_TAIL]=10,
[HARM_TYPE_HELD]=10});



--************
--  TROUTER  *
--************

function podoboo.onNPCHarm(ev,v,rsn,p)
	if v.id ~= npcID or p == nil then return end
	if rsn == 8 and p:mem(0x50, FIELD_BOOL) then
		ev.cancelled = true
	end
end

function podoboo.onTickNPC(self)
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
		if data.state ~= waterleaper.STATE.RESTING then
			local offsetY = 0
			if self.speedY < 0 then
				offsetY = self.height
			end
			local e = Effect.spawn(265, self.x + rng.random(4, self.width - 4), self.y + offsetY)
			e.speedY = self.speedY * 0.15
		end
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

return podoboo;