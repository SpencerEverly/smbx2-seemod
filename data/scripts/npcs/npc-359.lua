local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local flame = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 16,
	gfxwidth = 12,
	width = 12,
	height = 16,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	ignorethrownnpcs = true,
	nofireball=1,
	noiceball=1,
	npcblock=0,
	noyoshi=1,
	spinjumpsafe = false,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.orange,
	ishot = true,
})

function flame.onInitAPI()
	npcManager.registerEvent(npcID, flame, "onTickNPC", "onTickTrail")
	npcManager.registerEvent(npcID, flame, "onDrawNPC", "onDrawTrail")
end

function flame.onTickTrail(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.flameTimer = nil
		return
	end
	
	if data.flameTimer == nil then
		data.flameTimer = 0
	end
	
	data.flameTimer = data.flameTimer + 1
	if data.flameTimer > 100 then
		v.friendly = true
	end
	if data.flameTimer == 200 then
		v:kill(9)
	end
end

function flame.onDrawTrail(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		return
	end
	
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		Animation.spawn(10, v)
		SFX.play(9)
		v:kill(7)
		
		return
	end
	
	if data.flameTimer == nil then
		data.flameTimer = 0
	end
	
	if data.flameTimer > 100 and data.flameTimer%8==0 then
		utils.hideNPC(v)
	end
end
	
return flame
