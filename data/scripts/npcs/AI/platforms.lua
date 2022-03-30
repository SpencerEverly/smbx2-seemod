--- Platforms that folow line guides
-- @module platforms
-- @author Sambo
-- @version 2.0.b4

local platforms = {}

local lineguide = require("lineguide")
local npcManager = require("npcManager")

local switchcolors = require("switchcolors")

--*************************************************************************
--*
--*								Basic Platform Settings
--*
--*************************************************************************
--]]
--Basic platform settings
platforms.basicPlatformSettings = {
	speed = 1,
	playerblocktop = true,
	npcblocktop = true,
	nohurt = true,
	nowaterphysics = true,
	frames = 1,
	framestyle = 0,
	noiceball = true,
	noblockcollision = true,
	harmlessgrab=true,
	harmlessthrown=true,
	ignorethrownnpcs = true,
	noyoshi=true,
	notcointransformable = true
}

--*************************************************************************
--*
--*								YI Variable-speed Platform Settings
--*
--*************************************************************************

--base YI platform settings
platforms.yiPlatformSettings = table.join(
	{
		width = 96,
		height = 24
	},
	platforms.basicPlatformSettings
)

platforms.yiPlatformLineguideSettings = {
	activeByDefault = false,
	fallWhenInactive = false,
	activateOnStanding = true,
	extendedDespawnTimer = true,
	buoyant=true
}
--[[
--*************************************************************************
--*
--*								Blue Skull Raft
--*
--*************************************************************************

-- settings
npcManager.setNpcSettings(table.join(
	{
		id = BLUE_SKULL_RAFT_ID, 
		width = 32, 
		height = 20, 
		gfxwidth = 32, 
		gfxheight = 32, 
		gfxoffsetx = 0, 
		gfxoffsety = 12, 
		speed = 4, 
		noblockcollision = false, 
		npcblock = false, 
		npcblocktop = false, 
		noblockcollision = true,
	}, 
	basicPlatformSettings
))

lineguide.properties[BLUE_SKULL_RAFT_ID] = {
	activeByDefault = false, 
	activateOnStanding = true, 
	activateNearby = true, 
	lineSpeed = 4, 
	jumpSpeed = 4
}

-- event handler
npcManager.registerEvent(BLUE_SKULL_RAFT_ID, platforms, "onTickEndNPC", "onTickEndBlueSkullRaft")

-- Manage Skull Raft activation (for blue skull rafts)
-- Sets the speed on skull rafts that have been activated
-- Speed will be set to a value provided by the user or a default value if none is provided
function platforms.onTickEndBlueSkullRaft(npc)
	if not npc.data._basegame.active then
		npc.speedX = 0
	else
		npc.speedX = platforms.blueRaftSpeed * npc.direction
	end
end
--]]
--*************************************************************************
--*
--*								SMB3 Wood Platform (new)
--*
--*************************************************************************

--base 96 x 32 platform settings
platforms.thickPlatformSettings = table.join(
	{
		width=96,
		height=32
	},
	platforms.basicPlatformSettings
)

--*************************************************************************
--*
--*								Switch platforms (new)
--*
--*************************************************************************

--base switch platform settings
platforms.switchPlatformSettings = table.join(
	{
		frames = 2,
		framestyle = 0
	},
	platforms.thickPlatformSettings
)

platforms.sharedSwitchPlatformSettings = {
	lineSpeed = 2, 
	activeByDefault = false, 
	fallWhenInactive = false, 
	activateOnStanding = false, 
	extendedDespawnTimer = true,
}

function platforms.onTickEndSwitchPlatform(npc, toggle)
	local data = npc.data._basegame
	
	if not data.lineguide then
		lineguide.onStartNPC(npc)
	end
	local lgData = data.lineguide
	
	if not data.frameSet then
		if lgData.active then
			npc.animationFrame = 0
		else
			npc.animationFrame = 1
		end
		data.frameSet = true
	end

	data.frameSet = npc:mem(0x12A, FIELD_WORD) > 0
	
	if toggle then
		if lgData.active then -- deactivation; store velocity
			data.storedVelocity = vector.v2(npc.speedX, npc.speedY)
			npc.speedX = 0
			npc.speedY = 0
			npc.animationFrame = 1
		else -- activation; restore saved velocity if there is one
			if data.storedVelocity then
				npc.speedX = data.storedVelocity.x
				npc.speedY = data.storedVelocity.y
			else
				npc.speedX = 0
				npc.speedY = 0
			end
			npc.animationFrame = 0
		end
		lgData.active = not lgData.active
	end
	npc.animationTimer = 0 -- prevent frame advancement
end

return platforms
