local bumper = {}

local npcManager = require("npcManager")
local bumperAI = require("npcs/ai/bumper")

local npcID = NPC_ID

local config = {
	id = npcID,
	width = 32,
	gfxwidth = 32,
	height = 32,
	gfxheight = 32,
	noblockcollision = true,
	nogravity = true,
	jumphurt = true,
	nohurt = true,
	iscoin = false,
	harmlessgrab = true,
	harmlessthrown = true,
	frames = 1,
	framespeed = 8,
	framestyle = 0,
	noiceball = true,
	noyoshi = true,
	notcointransformable = true,
	ignorethrownnpcs = true,
	-- custom
	bouncestrength = 5,
	jumpmultiplier = 2,
	bounceplayer = true,
	bouncenpc = false,
	hitbox = Colliders.getHitbox
}
npcManager.setNpcSettings(config)

bumperAI.registerBumper(npcID)

return bumper