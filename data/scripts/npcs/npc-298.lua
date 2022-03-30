local npcManager = require("npcManager")
local rebounder = require("npcs/ai/rebounder");

local diagonals = {}
local npcID = NPC_ID
				  
npcManager.setNpcSettings({id = npcID,
				  gfxheight = 32, 
				  gfxwidth = 32, 
				  width = 28, 
				  height = 28, 
				  gfxoffsety = 2,
				  frames = 2,
				  framestyle = 1,
				  nogravity=1,
				  jumphurt = 1,
				  nofireball=1,
				  noiceball=1,
				  grabside=0,
				  grabtop=0,
				  noyoshi=1,
				  playerblock=0,
				  spinjumpsafe=true,
				  taillength=5})

rebounder.register(npcID)
return diagonals