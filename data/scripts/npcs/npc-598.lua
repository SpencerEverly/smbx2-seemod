local bumper = {}

local npcManager = require("npcManager")
local bumperAI = require("npcs/ai/bumper")

local npcID = NPC_ID

local config = {
	id = npcID,
	width = 92,
	gfxwidth = 92,
	height = 92,
	gfxheight = 92,
	noblockcollision = true,
	nogravity = true,
	jumphurt = true,
	nohurt = true,
	iscoin = false,
	harmlessgrab = true,
	harmlessthrown = true,
	frames = 2,
	framespeed = 8,
	framestyle = 0,
	noiceball = true,
	noyoshi = true,
	notcointransformable = true,
	ignorethrownnpcs = true,
	-- custom
	bouncestrength = 7.5,
	jumpmultiplier = 2,
	bounceplayer = false,
	bouncenpc = true,
	hitbox = function(self)
		return Colliders.Circle(self.x + self.width/2, self.y + self.height/2, self.width/2)
	end
}
npcManager.setNpcSettings(config)

bumperAI.registerBumper(npcID)

return bumper