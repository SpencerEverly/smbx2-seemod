local sinewave = require("npcs/ai/sinewave")
local npcManager = require("npcManager")

local blurp = {}
local npcID = NPC_ID

npcManager.setNpcSettings ({
    id = npcID,
    gfxheight = 32,
    gfxwidth = 32,
    width = 28,
    height = 28,
    frames = 2,
    framestyle = 1,
    jumphurt = 1,
    nogravity = 1,
    noblockcollision = 1,
    nofireball=0,
    noiceball=0,
    noyoshi=0,
    speed = 0.9,
    spinjumpsafe = true,
    nowaterphysics = -1,
    
    amplitude = 0.5,
    frequency  = 10,
    wavestart = 0,
    chase = false
})

npcManager.registerHarmTypes(npcID, 
	{HARM_TYPE_FROMBELOW, HARM_TYPE_HELD,HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_SWORD}, 
	{[HARM_TYPE_FROMBELOW]=118,
	[HARM_TYPE_HELD]=118,
	[HARM_TYPE_TAIL]=118,
	[HARM_TYPE_SWORD]=63,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});

function blurp.onInitAPI()
	sinewave.register(npcID)
end
	
return blurp