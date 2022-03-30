--------------------------------
-- Mutant Vine
--------------------------------
-- Created by Sambo, 29 Dec. 2017

local mutantVine = {}

local npcManager = require("npcManager")
local mutantVineAI = require("npcs/ai/mutantvine")

local npcID = NPC_ID

local mutantVineSettings = {
	id = npcID,
	-- graphics
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 4,
	-- animation
	frames = 6,
	framespeed = 8,
	framestyle = 0,
	-- physics
	width = 24,
	height = 24,
	isvine = true,
	notcointransformable = true,
	-- player interaction
	jumphurt = true,
	nohurt = true,
	noyoshi = true,
}
npcManager.setNpcSettings(mutantVineSettings)

local animSequence = {0,1,2,3,2,1}

mutantVineAI.registerVine(npcID, animSequence)

return mutantVine