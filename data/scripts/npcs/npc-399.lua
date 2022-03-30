local npcManager = require("npcManager")
local berries = require("npcs/ai/berries")
local timer = require("timer")
local utils = require("npcs/npcutils")

local berry = {}
local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 4,
	framestyle = 0,
	jumphurt = -1,
	nogravity = -1,
	nohurt=-1,
	noblockcollision = -1,
	ignorethrownnpcs = true,
	noiceball=1,
	noyoshi=0,
	harmlessgrab=true,
	harmlessthrown=true,
	notcointransformable = true,
	limit=1
})

local function rewardFunc(p)
	if timer.isActive() then
		timer.add(10)
	end
end

function berry.onInitAPI()
	berries.register(npcID, rewardFunc)
	npcManager.registerEvent(npcID, berry, "onTickEndNPC")
end

function berry.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then return end
	
	utils.applyLayerMovement(v)
end
	
return berry
