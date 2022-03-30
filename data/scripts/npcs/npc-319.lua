local npcManager = require("npcManager")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")
local whistle = require("npcs/ai/whistle")

local baseball = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

function baseball.onInitAPI()
	npcManager.registerEvent(npcID, baseball, "onTickEndNPC")
end

-- Baseball settings
npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_TAIL}, 
{[HARM_TYPE_TAIL]=176});

local baseballSettings = {
	id = npcID, 
	gfxwidth = 16, 
	gfxheight = 16, 
	width = 16,
	height = 16, 
	frames = 2,
	framespeed = 4, 
	framestyle = 0,
	score = 0,
	nofireball = 1,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	noyoshi = 1,
	noblockcollision = 1,
	blocknpc = 0,
	nogravity = 1,
	jumphurt = 1,
	speed = 1
}

npcManager.setNpcSettings(baseballSettings);

--*********************************************
--                                            *
--              pitching CHUCK                *
--                                            *
--*********************************************

function baseball.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	if v.dontMove then return end
	
	local d = v.data._basegame
	if (v:mem(0x12E, FIELD_WORD) == 30) then
		local p = Player(v:mem(0x130, FIELD_WORD))
		if p and not p.upKeyPressing then
			v.speedY = 0
		end
	end

	if not d.thrownPlayer then
		v:mem(0x136, FIELD_BOOL, false)
		return
	end
	
	if not d.collider then
		v.friendly = true
		d.collider = colliders.Box(v.x, v.y, v.width, v.height)
	end
	
	d.collider.x = v.x
	d.collider.y = v.y
	for k,p in ipairs(Player.get()) do
		if k ~= d.thrownPlayer then
			if colliders.collide(d.collider, p) then
				p:harm()
			end
		end
	end
	for k,n in ipairs(colliders.getColliding{a=d.collider, b=NPC.HITTABLE, btype=colliders.NPC,
		filter = function(other)
			if other.friendly == false and other:mem(0x12A, FIELD_WORD) > 0 and other.isHidden == false and other:mem(0x12C, FIELD_WORD) == 0 and other:mem(0x138, FIELD_WORD) == 0 then
				return true
			end
		end
	}) do
		n:harm(3)
		v:kill(7)
	end
end

return baseball;