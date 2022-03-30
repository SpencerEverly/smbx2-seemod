local npcManager = require("npcManager")
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

-- rocky was here too
 local tails = npcManager.setNpcSettings(table.join(
				 {id = npcID,
				  frames = 5,
				  gfxheight = 64, 
				  gfxwidth = 100, 
				  width = 32, 
				  height = 64},
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

return friendlies