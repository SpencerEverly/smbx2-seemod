--by Nat The Porcupine--
local npcManager = require("npcManager");
local fireSnakeAI = require("npcs/ai/firesnake");
local fireSnakeAPI = {};

local npcID = NPC_ID

npcManager.setNpcSettings({
id = npcID,
gfxoffsetx = 0,
gfxoffsety = 0,
gfxwidth = 16, 
gfxheight = 32, 
width = 16,
height = 32,
frames = 2,
framespeed = 8,
framestyle = 0,
nogravity=1,
noblockcollision=1,
jumphurt = 1,
ignorethrownnpcs = true,
nofireball=-1,
noiceball=-1,
noyoshi=-1,
spinjumpsafe=true,
lightradius=32,
lightcolor=Color.orange,
lightbrightness=0.5,
ishot = true,
durability = -1
})
fireSnakeAI.registerTail(npcID)

return fireSnakeAPI;