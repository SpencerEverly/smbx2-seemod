local rng = require("rng")
local npcManager = require("npcManager")

local drybones = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 4,
	framestyle = 0,
	jumphurt = 1,
	nofireball=1,
	noyoshi=1,
	ignorethrownnpcs = true,
	linkshieldable=true,
	nogravity=-1,
	noblockcollision=-1,
	spinjumpsafe=false
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_SWORD
	},
	{		});

function drybones.onInitAPI()
	npcManager.registerEvent(npcID, drybones, "onTickNPC", "onTickBone")
end

function drybones.onTickBone(v)
	if Defines.levelFreeze then return end

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		return
	end

	v.speedX = 3 * v.direction
end

return drybones;
