local rng = require("rng")
local npcManager = require("npcManager")

local waddledoo = {}

local npcID = NPC_ID
npcManager.setNpcSettings{
	id = npcID,
	width = 20,
	height = 20,
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 6,
	gfxoffsety = 6,
	framestyle = 0,
	framespeed = 8,
	speed = 0,
	npcblock=false,
	npcblocktop=false,
	noiceball=true,
	nogravity = true,
	ignorethrownnpcs = true,
	noblockcollision = true,
	jumphurt = true,
	spinjumpsafe = false,    
	lightradius=48,
    lightbrightness=1,
    lightcolor=Color.white,
	dooid = 472
}

function waddledoo.onInitAPI()
	npcManager.registerEvent(npcID, waddledoo, "onTickNPC", "onTickSpark")
end

function waddledoo.onTickSpark(v)
	if Defines.levelFreeze then return end

	local d = v.data._basegame

	if d.parent then
		if not (d.parent.isValid and d.parent.id == NPC.config[v.id].dooid) then
			v:kill()
		end
	end
end

return waddledoo