local npcManager = require("npcManager")
local rng = require("rng")

local minigameCloud = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 28,
	gfxheight = 32,
	width = 28,
	height = 32,
	frames = 1,
	framestyle = 0,
	jumphurt = -1,
	nogravity = 0,
	nohurt=-1,
	noblockcollision = -1,
	noyoshi=0,
	iscoin=true,
	harmlessgrab=true,
	harmlessthrown=true,
	isinteractable=true
})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_OFFSCREEN}, {
[HARM_TYPE_OFFSCREEN]=10});

function minigameCloud.onInitAPI()
	npcManager.registerEvent(npcID, minigameCloud, "onTickNPC", "onTickCoin")
end

function minigameCloud.onTickCoin(v)
	if Defines.levelFreeze then return end
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		return
	end
	v.speedY = v.speedY + 0.1
end
	
return minigameCloud