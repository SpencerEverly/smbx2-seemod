local npcManager = require("npcManager")
local whistle = require("npcs/ai/whistle")
local friendlyNPC = require("npcs/ai/friendlies")

local friendlies = {}
local npcID = NPC_ID

local defaults = {frames = 1, 
				  framestyle = 1, 
				  jumphurt = 1,
				  ignorethrownnpcs = 1,
				  nofireball=1,
				  noiceball=1,
				  noyoshi=1,
				  grabside=0,
				  grabtop=0,
				  isshoe=0,
				  isyoshi=0,
				  nohurt=1,
				  score = 0,
				  spinjumpsafe=0}

local megan = npcManager.setNpcSettings(table.join(
				 {id = npcID,
				  gfxheight = 64, 
				  gfxwidth = 32, 
				  ignorethrownnpcs = 0,
				  width = 32, 
				  height = 64, },
				  defaults))

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

friendlyNPC.register(npcID)

function friendlies.onInitAPI()
	npcManager.registerEvent(npcID, friendlies, "onTickEndNPC")
end

function friendlies.onTickEndNPC(v)
	if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if v.collidesBlockBottom then
		if (whistle.getActive()) then
			v.speedY = -2.5;
		end
	end
end

return friendlies