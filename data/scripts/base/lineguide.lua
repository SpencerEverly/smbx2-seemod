--**************************************************************************************************************--
--*       :::        ::::::::::: ::::    ::: :::::::::: ::::::::  :::    ::: ::::::::::: :::::::::  :::::::::: *--
--*      :+:            :+:     :+:+:   :+: :+:       :+:    :+: :+:    :+:     :+:     :+:    :+: :+:         *--
--*     +:+            +:+     :+:+:+  +:+ +:+       +:+        +:+    +:+     +:+     +:+    +:+ +:+          *--
--*    +#+            +#+     +#+ +:+ +#+ +#++:++#  :#:        +#+    +:+     +#+     +#+    +:+ +#++:++#      *--
--*   +#+            +#+     +#+  +#+#+# +#+       +#+   +#+# +#+    +#+     +#+     +#+    +#+ +#+            *--
--*  #+#            #+#     #+#   #+#+# #+#       #+#    #+# #+#    #+#     #+#     #+#    #+# #+#             *--
--* ########## ########### ###    #### ########## ########   ########  ########### #########  ##########       *--
--**************************************************************************************************************--
--**************************************************************************************************************--

--- This library adds all the line guides from SMW to SMBX and allows you to attach any NPC to line guides.
-- It also makes it so that line patterns that zigzag or turn sharply won't make the platforms fall off.
-- @module lineguide
-- @author Sambo

local lineguide = {}

local colliders = require("colliders")
local vectr = require("vectr")
local npcManager = require("npcManager")
local npcconfig

-- Create local copies of some math functions
-- These will be used often!
local max = math.max
local min = math.min
local abs = math.abs
local atan = math.atan
local PI = math.pi

--- These constants represent the states an NPC registered with lineguide can be in. DO NOT MODIFY.
-- @table lineguide.states
-- @field NORMAL not on a line or falling from a line
-- @field ONLINE on a line
-- @field FALLING falling off a line, but didn't hit the ground yet
lineguide.states = {
	NORMAL = 0,
	ONLINE = 1,
	FALLING = 2,
}

local NORMAL = lineguide.states.NORMAL
local ONLINE = lineguide.states.ONLINE
local FALLING = lineguide.states.FALLING

local ATTACH_COOLDOWN = 16

-- Stores the "speed" multiplier property of each NPC. 
lineguide.speeds = {}

--[[
API Settings: (in the lineguide namespace)
	debug = run debug mode if this is true
	disableLineNpcLoad = don't load the custom NPC AIs if set to true
	lineNpcs = list of IDs of NPCs registered with this system.
		NOTE: Do not try to directly access. use registerNpcs instead!
]]

--*************************************************************************
--*
--*							Names and IDs
--*
--*************************************************************************

-- Line names
local lineNames = {"buffer", "buffer2", "horiz", "vert", "slopeGent1", "slopeGent2", "slopeMid1", "slopeMid2", "slopeSteep1", "slopeSteep2", "circSmall1", "circSmall2", "circSmall3", "circSmall4", "circBig1", "circBig2", "circBig3", "circBig4",}

-- Default line IDs
-- NOT intended to be altered by the user
local defaultIds = {
	buffer      = 201,
	buffer2     = 202,
	horiz       = 203,
	vert        = 204,
	slopeGent1  = 205,
	slopeGent2  = 206,
	slopeMid1   = 207,
	slopeMid2   = 208,
	slopeSteep1 = 209,
	slopeSteep2 = 210,
	circSmall1  = 211,
	circSmall2  = 212,
	circSmall3  = 213,
	circSmall4  = 214,
	circBig1    = 215,
	circBig2    = 216,
	circBig3    = 217,
	circBig4    = 218,
}

--- Line IDs.
-- This will contain the IDs that are currently being used by this library.
-- The user can add IDs to this table to override the defaults.
-- Angles for the slopes are given in standard position (right = 0 degrees, CCW is positive)
-- @table ids
-- @field buffer The ID of the SMW direction switcher (default: 201)
-- @field buffer2 The ID of the SMB3 direction switcher
-- @field horiz The ID of the horizontal lineguide (default: 203)
-- @field vert The ID of the vertical lineguide (default: 204)
-- @field slopeMid1 The ID of the 45-degree lineguide (default: 207)
-- @field slopeMid2 The ID of the -45-degree lineguide (default: 208)
-- @field slopeGent1 The ID of the 27-degree lineguide (default: 205)
-- @field slopeGent2 The ID of the -27-degree lineguide (default: 206)
-- @field slopeSteep1 The ID of the 63-degree lineguide (default: 209)
-- @field slopeSteep2 The ID of the -63-degree lineguide (default: 210)
-- @field circSmall1 The ID of the top-left small circle piece (default: 211)
-- @field circSmall2 The ID of the top-right small circle piece (default: 212)
-- @field circSmall3 The ID of the bottom-left small circle piece (default: 213)
-- @field circSmall4 The ID of the bottom-right small circle piece (default: 214)
-- @field circBig1 The ID of the top-left large circle piece (default: 215)
-- @field circBig2 The ID of the top-right large circle piece (default: 216)
-- @field circBig3 The ID of the bottom-left large circle piece (default: 217)
-- @field circBig4 The ID of the bottom-right large circle piece (default: 218)
lineguide.ids = {}

--*************************************************************************
--*
--*							NPC Registration
--*
--*************************************************************************

lineguide.registeredNPCs = {} -- list of all IDs registered in lineguide

lineguide.registeredNPCMap = {}

--- Register the given ID with lineguide
-- @function registerNpcs
-- @tparam number id The ID to register
-- @usage lineguide.registerNpcs(1) -- register Goombas

--- Register all the IDs in the given table with lineguide
-- @tparam table(number) ids The IDs to register
-- @usage lineguide.registerNpcs({1,2}) -- register Goombas and red Goombas
function lineguide.registerNpcs(npcs)
	if type(npcs) == "number" then
		if not lineguide.registeredNPCMap[npcs] then
			npcManager.registerEvent(npcs, lineguide, "onStartNPC")
			npcManager.registerEvent(npcs, lineguide, "onTickNPC")
			npcManager.registerEvent(npcs, lineguide, "onTickEndNPC")
			npcManager.registerEvent(npcs, lineguide, "onDrawNPC")
			npcManager.registerEvent(npcs, lineguide, "onDrawEndNPC")
			table.insert(lineguide.registeredNPCs, npcs)
			lineguide.registeredNPCMap[npcs] = true
		end
	elseif type(npcs) == "table" then
		for _,v in ipairs(npcs) do
			if not lineguide.registeredNPCMap[v] then
				npcManager.registerEvent(v, lineguide, "onStartNPC")
				npcManager.registerEvent(v, lineguide, "onTickNPC")
				npcManager.registerEvent(v, lineguide, "onTickEndNPC")
				npcManager.registerEvent(v, lineguide, "onDrawNPC")
				npcManager.registerEvent(v, lineguide, "onDrawEndNPC")
				table.insert(lineguide.registeredNPCs, v)
				lineguide.registeredNPCMap[v] = true
			end
		end
	else
		error("Invalid input of " ..type(npcs).. " to function. Input must be a number or table.")
	end
end
lineguide.registerNPCs = lineguide.registerNpcs

--*************************************************************************
--*
--*							Properties
--*
--*************************************************************************

-- Alignment values for the sensors.
lineguide.ALIGN_TOP = 0
lineguide.ALIGN_LEFT = lineguide.ALIGN_TOP
lineguide.ALIGN_CENTER = .5
lineguide.ALIGN_CENTRE = lineguide.ALIGN_CENTER
lineguide.ALIGN_BOTTOM = 1
lineguide.ALIGN_RIGHT = lineguide.ALIGN_BOTTOM

local stringToAlign = {
	TOPLEFT     = {x =  0, y =  0},
	TOP         = {x = .5, y =  0},
	TOPRIGHT    = {x =  1, y =  0},
	LEFT        = {x =  0, y = .5},
	CENTER      = {x = .5, y = .5},
	RIGHT       = {x =  1, y = .5},
	BOTTOMLEFT  = {x =  0, y =  1},
	TOP         = {x = .5, y =  1},
	BOTTOMRIGHT = {x =  1, y =  1},
}
stringToAlign.CENTRE = stringToAlign.CENTER

-- NPC lineguide property names
local propNames = {"lineSpeed", "jumpSpeed", "useHiddenLines", "extendedDespawnTimer", "fallWhenInactive", "activateOnStanding", "activateNearby", "sensorAlignH", "sensorAlignV", "sensorOffsetX", "sensorOffsetY", "buoyant"}

local textProps = {"linespeed", "linejumpspeed", "usehiddenlines", "linefallwheninactive", "lineactivateonstanding", "lineactivatenearby", "linesensoralignh", "linesensoralignv", "linesensoroffsetx", "linesensoroffsety", "extendeddespawntimer", "buoyant"}

-- Used for getting property values into lineguide.properties from .txt files
-- I'm keeping the same internal property names for compatibility with older code that messes with lineguide stuff
local txtAliasMap = {
	lineSpeed = "linespeed",
	jumpSpeed = "linejumpspeed",  -- This apparently hasn't done anything for some time ...
	useHiddenLines = "usehiddenlines",
	fallWhenInactive = "linefallwheninactive",
	activateOnStanding = "lineactivateonstanding",
	activateNearby = "lineactivatenearby",
	sensorAlignH = "linesensoralignh",
	sensorAlignV = "linesensoralignv",
	sensorOffsetX = "linesensoroffsetx",
	sensorOffsetY = "linesensoroffsety",
	
	-- These ought to be separated from lineguide at some point
	extendedDespawnTimer = "extendeddespawntimer",
	buoyant = "buoyant",
}

-- Default properties
local defaultProps = {
	lineSpeed          = 2,
	jumpSpeed          = 4,
	useHiddenLines     = false,
	fallWhenInactive   = false,
	activeByDefault    = true,
	activateOnStanding = false,
	activateNearby     = false,
	sensorAlignH       = lineguide.ALIGN_CENTER,
	sensorAlignV       = lineguide.ALIGN_CENTER,
	sensorOffsetX      = 0,
	sensorOffsetY      = 0,
	extendedDespawnTimer = false,
	buoyant            = false
}

--- This table contains the Property objects for NPCs (indexed by ID). Contains non-default properties only.
-- To change the properties of an NPC registered with lineguide, create a Property object and insert it into this table.
-- Alternatively, the fields can be defined using npc.txt files (case insensitive). These methods will set the properties for all instances of the selected ID.
-- To define them for an individual instance, use the npcParse fields of that instance.
-- @table properties
-- @usage -- properties table
-- -- This sets the line speed of SMW Fuzzies (ID 333) to 2 and moves the positioning sensor
-- -- 16px to the left.
-- lineguide.properties[333] = {
--     lineSpeed = 2,
--     sensorOffsetX = -16,
-- }
-- @usage -- npc.txt
-- -- file: npc-333.txt
-- linespeed=2
-- sensoroffsetx=-16
-- @usage -- npcParse (in an NPC's message field)
-- -- This changes the properties for only the NPC instance on which it is used.
-- {lineSpeed = 2, sensorOffsetX = -16}
-- @see Property
lineguide.properties = {}

--- This object contains the lineguide properties for all instances of an NPC.
-- Note that the defaults given here are for the lineguide library, not for all SMBX2 lineguide NPCs.
-- @table Property
-- @field lineSpeed (number) The speed, in px/tick, at which the NPC moves while on a line. (default: 2)
-- @field jumpSpeed (number) The speed, in px/tick, at which the NPC will "jump off" when the end of a line is reached. This only applies if there is any upward movement at that point. (default: 4)
-- @field useHiddenLines (boolean) If true, the NPC will follow lineguides that are on hidden layers. (default: false)
-- @field fallWhenInactive (boolean) If true, the NPC is affected by gravity when inactive. (default: false)
-- @field activeByDefault (boolean) If true, the NPC will be active when it spawns. (default: true)
-- @field activateOnStanding (boolean) If true, the NPC will become active when a player stands on it. (default: false)
-- @field activateNearby (boolean) If true, This NPC will activate all adjacent NPCs of the same ID when it becomes active. (default: false)
-- @field sensorAlignH (number) The horizontal alignment of the NPC's position sensor (the point at which it attaches to lineguides). (default: lineguide.ALIGN_CENTER)
-- @field sensorAlignV (number) The vertical alignment of the NPC's position sensor. (default: lineguide.ALIGN_CENTER)
-- @field sensorOffsetX (number) The horizontal offset of the NPC's position sensor relative to its alignment. (default: 0)
-- @field sensorOffsetY (number) The vertical offset of the NPC's position sensor relative to its alignment. (default: 0)
-- @field extendedDespawnTimer (bool) If true, the NPC will take 3000 ticks to despawn after going offscreen. (default: false)
-- @field buoyant (bool) If true, the NPC floats on water (default: false)

-- Initialize the NPC's properties
local function initProps(npc)
	local id = npc.id
	local globalProps = lineguide.properties[id] or {}
	
	if not lineguide.speeds[id] then
		-- Store the value of the speed property, then force it to 1
		-- (Non-1 values cause jank)
		lineguide.speeds[id] = NPC.config[id].speed
		NPC.config[id].speed = 1
	end
	
	npc.data._basegame.lineguide = npc.data._basegame.lineguide or {}
	local data = npc.data._basegame.lineguide
	local settings = npc.data._settings

	local activeData = data.activeStateOverride or "Default"
	
	for _,propName in ipairs(propNames) do
		if globalProps[propName] ~= nil then -- a global property has been set
			data[propName] = globalProps[propName]
		else -- the property was not set. Use the default value
			data[propName] = defaultProps[propName]
		end
	end
	--this one is per-npc
	if data.activeByDefault ~= nil then return end
	
	data.activeByDefault = globalProps.activeByDefault
	if data.activeByDefault == nil then
		data.activeByDefault = defaultProps.activeByDefault
	end
	if settings.activeByDefault ~= nil and settings.activeByDefault ~= 0 then
		data.activeByDefault = settings.activeByDefault == 1
	end
end

-- Align the sensor
local function alignSensor(npc)
	local data = npc.data._basegame.lineguide;
	data.sensorOffsetX = data.sensorOffsetX + npc.width * data.sensorAlignH;
	data.sensorOffsetY = data.sensorOffsetY + npc.height * data.sensorAlignV;
end

-- Check if the NPC is affected by gravity
local function hasGravity(id)
	local config = NPC.config[id]
	return not (config.nogravity or config.iscoin or config.isvine)
end

--*************************************************************************
--*
--*							NPC Functions
--*
--*************************************************************************

-- remove vanilla gravity
local function removeVanillaGravity(npc)
	npc.speedY = npc.speedY - Defines.npc_grav
end

-- Update the sensor's position
local function updateSensor(npc, data)
	data.sensor.x = npc.x + data.sensorOffsetX
	data.sensor.y = npc.y + data.sensorOffsetY
end

-- Force the NPC to the sensor's position
local function lockToSensor(npc, data)
	data.adjustmentX = (data.adjustmentX or 0) + data.sensor.x - (npc.x + data.sensorOffsetX)
	data.adjustmentY = (data.adjustmentY or 0) + data.sensor.y - (npc.y + data.sensorOffsetY)
end

--- Attach NPCs
-- This function attaches a set of NPCs to another NPC that is registered with lineguide.
-- npcblock and npcblocktop will not work with NPCs that are attached in this way.
-- @function attachNPCs
-- @tparam wrappedNPC npc The NPC to attach the other NPCs to. This NPC must be registered with lineguide
-- @tparam table(NPC) npcsToAttach The NPCs to attach. These shouldn't be registered with lineguide
-- @usage lineguide.attachNPCs(npc, npcsToAttach)
function lineguide.attachNPCs(npc, npcsToAttach)
	local attachedNPCs = {}
	for _,v in ipairs(npcsToAttach) do
		v.data._basegame.parent = npc
		table.insert(attachedNPCs, v)
	end
	npc.data._basegame.lineguide = npc.data._basegame.lineguide or {}
	npc.data._basegame.lineguide.attachedNPCs = attachedNPCs
end

local function bounceOff(npc)
	npc.speedX = -npc.speedX
	npc.speedY = -npc.speedY - Defines.npc_grav
end

--*************************************************************************
--*
--*							Line Attachment
--*
--*************************************************************************

local colliderGenerators

local function createColliderGenerators()
	colliderGenerators = {
		--                    type                           offsetX  offsetY  width        height
		[ids.horiz]       = { colliderType=colliders.Box,             yoff=16, arg1=32,     arg2=16 },
		[ids.vert]        = { colliderType=colliders.Box,    xoff=8,           arg1=16,     arg2=32 },
		--                                                                     p1           p2            p3            p4
		[ids.slopeMid1]   = { colliderType=colliders.Poly,                     arg1={0,28}, arg2={32,-4}, arg3={32,4 }, arg4={0,36} },
		[ids.slopeMid2]   = { colliderType=colliders.Poly,                     arg1={0,-4}, arg2={32,28}, arg3={32,36}, arg4={0,4 } },
		[ids.slopeGent1]  = { colliderType=colliders.Poly,                     arg1={0,28}, arg2={64,-4}, arg3={64,4 }, arg4={0,36} },
		[ids.slopeGent2]  = { colliderType=colliders.Poly,                     arg1={0,-4}, arg2={64,28}, arg3={64,36}, arg4={0,4 } },
		[ids.slopeSteep1] = { colliderType=colliders.Poly,                     arg1={0,64}, arg2={32,-4}, arg3={32,4 }, arg4={0,68} },
		[ids.slopeSteep2] = { colliderType=colliders.Poly,                     arg1={0,0},  arg2={32,56}, arg3={32,68}, arg4={0,4 } },
		--                                                                     radius   innerRadius
		[ids.circSmall1]  = { colliderType=colliders.Circle, xoff=32, yoff=32, arg1=32,                },
		[ids.circSmall2]  = { colliderType=colliders.Circle,          yoff=32, arg1=32,                },
		[ids.circSmall3]  = { colliderType=colliders.Circle, xoff=32,          arg1=32, innerRadius=24 },
		[ids.circSmall4]  = { colliderType=colliders.Circle,                   arg1=32, innerRadius=24 },
		[ids.circBig1]    = { colliderType=colliders.Circle, xoff=64, yoff=64, arg1=64,                },
		[ids.circBig2]    = { colliderType=colliders.Circle,          yoff=64, arg1=64,                },
		[ids.circBig3]    = { colliderType=colliders.Circle, xoff=64,          arg1=64, innerRadius=56 },
		[ids.circBig4]    = { colliderType=colliders.Circle,                   arg1=64, innerRadius=56 },
	}
end

local function generateCollider(bgo)
	local collider, collider2
	
	local t = colliderGenerators[bgo.id]
	if t then
		collider = t.colliderType(bgo.x+(t.xoff or 0), bgo.y+(t.yoff or 0), t.arg1, t.arg2, t.arg3, t.arg4)
		if t.innerRadius then 
			collider2 = colliders.Circle(bgo.x+(t.xoff or 0), bgo.y+(t.yoff or 0), t.innerRadius) 
		end
	end
	
	return collider, collider2
end

-- Get the square root of x, or return 0 if x < 0
-- This is only useful here because x < 0 only occurs in VERY limited cases.
local function safeSqrt(x)
	if x >= 0 then
		return math.sqrt(x)
	else
		return 0
	end
end

local attachHeightFunctions

local function createAttachHeightFunctions()
	attachHeightFunctions = {
		[ids.slopeMid1]   = function(x) return 32 - x end,
		[ids.slopeMid2]   = function(x) return x end,
		[ids.slopeGent1]  = function(x) return 32 - x/2 end,
		[ids.slopeGent2]  = function(x) return x/2 end,
		[ids.slopeSteep1] = function(x) return 64 - x*2 end,
		[ids.slopeSteep2] = function(x) return x*2 end,
		[ids.circSmall1]  = function(x) return 32 - safeSqrt(32*32 - (32-x)*(32-x)) end,
		[ids.circSmall2]  = function(x) return 32 - safeSqrt(32*32 - x*x) end,
		[ids.circSmall3]  = function(x) return safeSqrt(32*32 - (32-x)*(32-x)) end,
		[ids.circSmall4]  = function(x) return safeSqrt(32*32 - x*x) end,
		[ids.circBig1]    = function(x) return 64 - safeSqrt(64*64 - (64-x)*(64-x)) end,
		[ids.circBig2]    = function(x) return 64 - safeSqrt(64*64 - x*x) end,
		[ids.circBig3]    = function(x) return safeSqrt(64*64 - (64-x)*(64-x)) end,
		[ids.circBig4]    = function(x) return safeSqrt(64*64 - x*x) end,
	}
end

-- These vectors are multiplied by the lineSpeed field to determine the movement direction
-- They tend toward moving down, or to the right on a horizontal line.
local baseMotionVectors

local function createBaseMotionVectors()
	baseMotionVectors = {
		[ids.horiz]       = vectr.v2(1, 0),
		[ids.vert]        = vectr.v2(0, 1),
		[ids.slopeMid1]   = vectr.v2(1,-1),
		[ids.slopeMid2]   = vectr.v2(1,1),
		[ids.slopeGent1]  = vectr.v2(1,-.5),
		[ids.slopeGent2]  = vectr.v2(1,.5),
		[ids.slopeSteep1] = vectr.v2(.5,-1),
		[ids.slopeSteep2] = vectr.v2(.5,1),
	}
end

local distancesFromCenter

local function createDistanceFromCenterFunctions()
	distancesFromCenter = { --                          dy          dx          off   sign
		[ids.circSmall1] = function(bx,by,nx,ny) return ny-(by+32), nx-(bx+32), PI,   1  end,
		[ids.circSmall2] = function(bx,by,nx,ny) return ny-(by+32), nx-bx,      2*PI, -1 end,
		[ids.circSmall3] = function(bx,by,nx,ny) return ny-by,      nx-(bx+32), PI,   -1 end,
		[ids.circSmall4] = function(bx,by,nx,ny) return ny-by,      nx-bx,      0,    1  end,
		[ids.circBig1]   = function(bx,by,nx,ny) return ny-(by+64), nx-(bx+64), PI,   1  end,
		[ids.circBig2]   = function(bx,by,nx,ny) return ny-(by+64), nx-bx,      2*PI, -1 end,
		[ids.circBig3]   = function(bx,by,nx,ny) return ny-by,      nx-(bx+64), PI,   -1 end,
		[ids.circBig4]   = function(bx,by,nx,ny) return ny-by,      nx-bx,      0,    1  end,
	}
end

local function getStartAngle(line, sensor)
	local dy, dx, off, sign = distancesFromCenter[line.id](line.x, line.y, sensor.x, sensor.y)
	
	dx = abs(dx)
	dy = abs(dy)
	
	local rawAngle
	if dx == 0 then
		rawAngle = .5 * PI
	else
		rawAngle = atan(dy/dx)
	end
	return off + sign * rawAngle
end

-- These generate the nodes at the end of lines
local nodeGenerators

local function createNodeGenerators()
	nodeGenerators = {
		[ids.horiz]       = {node1 = {xoff = 0,  yoff = 16, dir = 0},  node2 = {xoff = 32, yoff = 16, dir = 8}},
		[ids.vert]        = {node1 = {xoff = 16, yoff = 0,  dir = 12}, node2 = {xoff = 16, yoff = 32, dir = 4}},
		[ids.slopeMid1]   = {node1 = {xoff = 0,  yoff = 32, dir = 2},  node2 = {xoff = 32, yoff = 0,  dir = 10}},
		[ids.slopeMid2]   = {node1 = {xoff = 0,  yoff = 0,  dir = 14}, node2 = {xoff = 32, yoff = 32, dir = 6}},
		[ids.slopeGent1]  = {node1 = {xoff = 0,  yoff = 32, dir = 1},  node2 = {xoff = 64, yoff = 0,  dir = 9}},
		[ids.slopeGent2]  = {node1 = {xoff = 0,  yoff = 0,  dir = 15}, node2 = {xoff = 64, yoff = 32, dir = 7}},
		[ids.slopeSteep1] = {node1 = {xoff = 0,  yoff = 64, dir = 3},  node2 = {xoff = 32,  yoff = 0, dir = 11}},
		[ids.slopeSteep2] = {node1 = {xoff = 0,  yoff = 0,  dir = 13}, node2 = {xoff = 32, yoff = 64, dir = 5}},
		
		[ids.circSmall1]  = {node1 = {xoff = 0,  yoff = 32, dir = 4},  node2 = {xoff = 32, yoff = 0,  dir = 8}},
		[ids.circSmall2]  = {node1 = {xoff = 0,  yoff = 0,  dir = 0},  node2 = {xoff = 32, yoff = 32, dir = 4}},
		[ids.circSmall3]  = {node1 = {xoff = 32, yoff = 32, dir = 8},  node2 = {xoff = 0,  yoff = 0,  dir = 12}},
		[ids.circSmall4]  = {node1 = {xoff = 32, yoff = 0,  dir = 12}, node2 = {xoff = 0,  yoff = 32, dir = 0}},
		[ids.circBig1]    = {node1 = {xoff = 0,  yoff = 64, dir = 4},  node2 = {xoff = 64, yoff = 0,  dir = 8}},
		[ids.circBig2]    = {node1 = {xoff = 0,  yoff = 0,  dir = 0},  node2 = {xoff = 64, yoff = 64, dir = 4}},
		[ids.circBig3]    = {node1 = {xoff = 64, yoff = 64, dir = 8},  node2 = {xoff = 0,  yoff = 0,  dir = 12}},
		[ids.circBig4]    = {node1 = {xoff = 64, yoff = 0,  dir = 12}, node2 = {xoff = 0,  yoff = 64, dir = 0}},
	}
end

-- Get the nodes for the ginen line.
-- Return:
--	col1 = the first node
--	d1   = the first node's direction
--	col2 = the second node
--	d2   = the second node's direction
local function getNodes(line)
	local t = nodeGenerators[line.id]
	if t then
		return colliders.Point(line.x + t.node1.xoff, line.y + t.node1.yoff), t.node1.dir,
			   colliders.Point(line.x + t.node2.xoff, line.y + t.node2.yoff), t.node2.dir,
			   t.sign
	end
end

-- Attach to a circle
-- forceSwap is used by turnAround() to make turning around on circles work properly
local function attachToCircle(data, lineData, forceSwap)
	local id = lineData.line.id
	local v = vectr.v2(0,1) -- down
	data.angle = getStartAngle(lineData.line, data.sensor)
	data.velocity = v:rotate(math.deg(data.angle))
	data.omega = 1 / lineData.line.width
	
	if forceSwap then
		data.velocity = -data.velocity
		data.omega = -data.omega
	end
end

local function attachToLine(npc, data, lineData)
	local id = lineData.line.id
	
	-- Get the start and destination nodes
	--local start, startDir, dest, destDir = getNodes(line)
	local start = lineData.start
	local startDir = lineData.startDir
	local dest = lineData.dest
	local destDir = lineData.destDir
	local swapped = lineData.swapped
	
	-- Set the motion vector
	local v = baseMotionVectors[id]
	if v then -- linear motion
		data.omega = nil
	else -- circular motion
		attachToCircle(data, lineData)
		v = data.velocity
	end
	
	-- Lock onto the line if we are not attaching from a previous line
	if data.state ~= ONLINE then
		local s = data.sensor
		if id == ids.horiz then
			s.y = lineData.line.y + 16
		elseif id == ids.vert then
			s.x = lineData.line.x + 16
		else
			s.y = lineData.line.y + attachHeightFunctions[id](s.x - lineData.line.x)
		end
		lockToSensor(npc, data)
		-- Calculate the dot product of the npc's motion vector and the line's motion vector
		-- If it's negative, we know we need to reverse the line's motion vector to move in the right direction
		local dotProd
		if npc.speedX == 0 and npc.speedY >= 0 and npc.speedY <= Defines.npc_grav*2 then
			dotProd = 0
		else
			dotProd = v:dot(vectr.v2(npc.speedX, npc.speedY))
		end
		
		swapped = dotProd < 0 or (dotProd == 0 and npc.direction == -1)
		if swapped then
			start, dest, startDir, destDir = dest, start, destDir, startDir
		end
	end
	
	if swapped then
		v = -v
		if data.omega then
			data.omega = -data.omega
		end
	end
	
	-- set the nev velocity
	data.velocity = v
	
	if data.omega and lineData.swapped == nil then
		lineData.swapped = data.omega < 0
	end
		
	-- Store the nodes and the line
	data.start = start
	data.dest = dest
	data.lineData = lineData
	data.dir = (destDir + 8) % 16 -- The direction is set to the exit direction
	
	-- This data is needed for turning around
	data.startDir = startDir
	data.destDir = destDir
	
	data.state = ONLINE

	
	npc:mem(0x130, FIELD_WORD, 0)
	npc:mem(0x132, FIELD_WORD, 0)
	npc:mem(0x136, FIELD_BOOL, false)
	
	-- Stop colliding with blocks now that the NPC is attached to the line
	if not NPC.config[npc.id].collideswhenattached then
		npc.noblockcollision = true
	end
end

--*************************************************************************
--*
--*							Checks
--*
--*************************************************************************

-- Check if there is a line for the NPC to attach to. If so, return it.
local function checkForLine(npc, data)
	local s = data.sensor
	for _,v in ipairs(BGO.getIntersecting(s.x - 8, s.y - 8, s.x + 8, s.y - 8)) do
		if not v.isHidden or data.useHiddenLines then
			if v.id == ids.buffer or v.id == ids.buffer2 then
				bounceOff(npc)
				return
			end
			local collider, collider2 = generateCollider(v)
			if (collider and colliders.collide(s, collider)) and (not collider2 or not colliders.collide(s, collider2)) then
				return v
			end
			-- local collider, inverted = generateCollider(v)
			-- if collider then
				-- if lineguide.debug then collider:Draw() end
				-- local colliding = colliders.collide(s, collider)
				-- if (inverted and not colliding) or (not inverted and colliding) then
					-- return v
				-- end
			-- end
		end
	end
end

-- Check if the end of the current line has been reached
local function checkPosition(data)
	local sensor = data.sensor
	local dest = data.dest
	local dir = data.dir
	
	return ((dir > 13 or dir <= 2) and sensor.x >= dest.x) or
	(dir > 2  and dir <= 5  and sensor.y <= dest.y) or
	(dir > 5  and dir <= 10 and sensor.x <= dest.x) or
	(dir > 10 and dir <= 13 and sensor.y >= dest.y)
end

-- Check if the NPC is colliding with a block
-- This uses 4 memory accesses and could probably be more efficient
local function checkForBlockCollision(npc)
	return npc:mem(0x0A,FIELD_WORD) == 2 or -- collides below
	npc:mem(0x0C,FIELD_WORD) == 2 or -- collides left
	npc:mem(0x0E,FIELD_WORD) == 2 or -- collides above
	npc:mem(0x10,FIELD_WORD) == 2
end

local function checkShouldFreeze()
	local forcedStateFreeze
	for _,p in ipairs(Player.get()) do
		if p.forcedState ~= 0 and p.forcedState ~= 7 and p.forcedState ~= 3 then
			forcedStateFreeze = true
		end
	end
	return forcedStateFreeze or Defines.levelFreeze
end

--*************************************************************************
--*
--*							Line Movement logic
--*
--*************************************************************************
local zeroVector = vectr.v2(0,0)

local function applyVector(npc, velocity, movingAttachedNPC, adjustmentX, adjustmentY)
	local data = npc.data._basegame.lineguide
	if not npc.dontMove and not checkShouldFreeze() then
		-- use abs(lineSpeed) because lineSpeed could be nagative,
		-- and actually making lineguide work backward would be excruciating
		npc.speedX = velocity.x * ((data and abs(data.lineSpeed)) or 1)
		npc.speedY = velocity.y * ((data and abs(data.lineSpeed)) or 1)
	else -- halt movement if we are in a state that freezes layer movement
		npc.speedX = 0
		npc.speedY = 0
	end
	if hasGravity(npc.id) then
		removeVanillaGravity(npc)
	end
	if adjustmentX then
		npc.speedX = npc.speedX + adjustmentX
		npc.speedY = npc.speedY + adjustmentY
	end
	
	-- Temporary fix for ropes, which are unaffected by max fallspeed
	npc.speedY = min(npc.speedY, 8)
	
	if not movingAttachedNPC then
		local attachedNPCs = data.attachedNPCs
		if attachedNPCs then
			if not npc.dontMove then
				for _,v in ipairs(attachedNPCs) do
					applyVector(v, velocity * abs(data.lineSpeed), true, adjustmentX, adjustmentY)
				end
			else
				for _,v in ipairs(attachedNPCs) do
					applyVector(v, zeroVector, true, adjustmentX, adjustmentY)
				end
			end
		end
	end
end

local function applyLayerSpeed(npc, data)
	local layer = data.lineData.line.layerObj
	if layer and not checkShouldFreeze() then
		if layer.speedX ~= 0 or layer.speedY ~= 0 then
			npc.speedX = npc.speedX + layer.speedX
			npc.speedY = npc.speedY + layer.speedY
			data.start.x = data.start.x + layer.speedX
			data.start.y = data.start.y + layer.speedY
			data.dest.x = data.dest.x + layer.speedX
			data.dest.y = data.dest.y + layer.speedY
			if data.attachedNPCs then
				for _,v in ipairs(data.attachedNPCs) do
					v.speedX = v.speedX + layer.speedX
					v.speedY = v.speedY + layer.speedY
				end
			end
		end
	end
end

local function rotateVector(data)
	if not checkShouldFreeze() then
		local omega = data.omega * abs(data.lineSpeed)
		data.velocity = data.velocity:rotate(math.deg(omega))
		data.angle = data.angle + omega
	end
end

-- Get a table of all lines that may be the next line
-- This table will have entries with the following structure: {line, entranceCol, entranceDir, exitCol, exitDir, swapped}
--	line = the candidate lineguide BGO
--	entranceCol = the "entrance" node for this candidate
--	entranceDir = the direction of the endtrance node
--	similar for exitCol and exitDir
--	swapped = true if the "lower" node was the one touched
-- Return the table, or nil if a buffer has been reached
local function getAdjacentNodes(data)
	local candidates = {}
	local sensor = colliders.Circle(data.sensor.x, data.sensor.y, 8)
	for _,line in ipairs(BGO.getIntersecting(sensor.x - 8, sensor.y - 8, sensor.x + 8, sensor.y + 8)) do
		if not line.isHidden or data.useHiddenLines then
			if line.id == ids.buffer or line.id == ids.buffer2 then -- A buffer was hit
				return nil
			end
			col1, d1, col2, d2, sign = getNodes(line)
			if col1 then
				local col2Hit = colliders.collide(sensor, col2)
				if col2Hit then
					col1, col2 = col2, col1
					d1, d2 = d2, d1
				end
				
				-- Exclude the line that the NPC is currently on
				if ((not line.isHidden) or data.useHiddenLines) and line.idx ~= data.lineData.line.idx and (col2Hit or colliders.collide(sensor, col1)) then
					table.insert(candidates, {line = line, start = col1, startDir = d1, dest = col2, destDir = d2, swapped = col2Hit, sign = sign})
				end
			end
		end
	end
	return candidates
end

-- Get the node that will change the direction the least drastically
local function getNearestNode(candidates, currentDir)
	local key
	local leastDiff = 9
	for k,v in ipairs(candidates) do		
		local diff = (v.startDir - currentDir) % 16
		if diff > 8 then
			diff = (currentDir - v.startDir) % 16
		end
		
		if diff < leastDiff then
			leastDiff = diff
			key = k
		end
		
		if diff == 0 then break end -- A closer direction cannot be found
	end
	
	return candidates[key]
end

local function turnAround(npc, data)
	data.velocity = -data.velocity
	
	-- Swap the start and destination
	data.start, data.dest = data.dest, data.start
	data.startDir, data.destDir = data.destDir, data.startDir
	
	data.dir = (data.destDir + 8) % 16
	
	-- Reverse angular velocity if on a circle
	if data.omega then
		data.lineData.swapped = not data.lineData.swapped
		attachToCircle(data, data.lineData, data.lineData.swapped)
	end
end

local function goToNextLine(npc, data)	
	local nextLineCandidates = getAdjacentNodes(data)
	
	if not nextLineCandidates then -- A buffer has been reached
		turnAround(npc, data)
		return
	end
	
	-- Iterate through the nodes and get the one with the direction closest to the current direction.
	-- Don't go back onto the same line.
	if #nextLineCandidates > 0 then -- If a line was found, connect to it.
		local nearestNode = getNearestNode(nextLineCandidates, data.dir)
		attachToLine(npc, data, nearestNode)
	else -- Otherwise, detach from the line.
		data.attachCooldown = ATTACH_COOLDOWN
		data.state = FALLING
		if not NPC.config[npc.id].collideswhenattached then
			npc.noblockcollision = false -- Allow collision now that not on line
		end
		if npc.speedY < 0 then
			if not NPC.config[npc.id].nogravity then
				npc.speedY = math.abs(data.jumpSpeed) * -1
			end
			if data.dir ~= 4 then -- Don't jump to the side if moving straight up
				npc.speedX = math.abs(data.jumpSpeed) * npc.direction
			else
				npc.speedX = 0 -- removes horizontal speed when jumping from a circle
			end
		end
	end
end

--*************************************************************************
--*
--*							Init
--*
--*************************************************************************

do
	-- set the line IDs. User-defined IDs can override the defaults
	local function setLineIDs()
		ids = lineguide.ids
		for _,name in ipairs(lineNames) do
			ids[name] = ids[name] or defaultIds[name]
		end
	end

	function lineguide.onInitAPI()
		setLineIDs()
		createColliderGenerators()
		createAttachHeightFunctions()
		createBaseMotionVectors()
		createDistanceFromCenterFunctions()
		createNodeGenerators()
		
		registerEvent(lineguide, "onStart")
	end
	
	local function setupLineguidedTxtConfigs()
		for i = 1,NPC_MAX_ID do
			local cfg = npcconfig[i]
			if cfg.lineguided then
				local props = lineguide.properties[i] or {}
				lineguide.registerNPCs(i)
				
				for _,k in ipairs(propNames) do
					local property = cfg[txtAliasMap[k]]
					if property == nil then
						props[k] = defaultProps[k]
					else
						props[k] = property
					end
				end
				
				-- This must be handled separately because, due to how it is implemented, including it in propNames breaks it
				local active = cfg.lineactivebydefault
				if active == nil then
					props.activeByDefault = defaultProps.activeByDefault
				else
					props.activeByDefault = active
				end
				
				lineguide.properties[i] = props
			end
		end
	end
	
	function lineguide.onStart()
		npcconfig = NPC.config
		setupLineguidedTxtConfigs()
	end
end

--*************************************************************************
--*
--*							NPC Event Handlers
--*
--*************************************************************************

--[[
NPC Data: -- not needed by the user
	dir = direction index (Not the same as NPC.direction)
	sensor = positioning sensor
	startPoint = start point for the line the NPC is on
	destPoint = destination point for the line the NPC is on
	state = NORMAL, ONLINE, FALLING; the state of the NPC
	lineObj = the line BGO the NPC is on.
	active = if true, the NPC will move on lines
	attachCooldown = a cooldown for line attachment. Prevents immediate reattachment to the line the NPC just left.
	velocity = the movement vector
	omega = the angular velocity
	reversed = true if lineSpeed < 0. Used to handle turning around when using dynamic lineSpeed.
]]--

local SENSOR_RADIUS = 8

-- initialize the NPC's settings
function lineguide.onStartNPC(npc)
	initProps(npc)
	alignSensor(npc)

	local data = npc.data._basegame.lineguide
	
	-- set up the NPC's data
	data.sensor = colliders.Circle(0,0,SENSOR_RADIUS)
	data.state = NORMAL
	data.active = data.activeByDefault
	data.attachCooldown = 0
	if not NPC.config[npc.id].collideswhenattached then
		npc.noblockcollision = false -- Allow collision since not consider on a line yet
	end
end

-- This Pseudo-event is called on NPCs when they despawn
-- Adding this event to basegame might not be a bad idea
function lineguide.onDespawnNPC(npc)
	local data = npc.data._basegame.lineguide

	data.state = NORMAL
	data.active = data.activeByDefault
	data.attachCooldown = 0
	if not NPC.config[npc.id].collideswhenattached then
		npc.noblockcollision = false -- Allow collision since not consider on a line yet
	end
	
	data.angle = nil
	data.omega = nil
end

function lineguide.onTickNPC(npc)
	if npc:mem(0x138, FIELD_WORD) > 0 then return end
	if not npc.data._basegame.lineguide then
		lineguide.onStartNPC(npc)
	end

	local data = npc.data._basegame.lineguide
	
	local despawnTimer = npc:mem(0x12A, FIELD_WORD)
	
	-- force the npc to spawn if its attachments have spawned
	if despawnTimer > 0 and data.attachedNPCs then
		for _,v in ipairs(data.attachedNPCs) do
			local dt = v:mem(0x12A, FIELD_WORD)
			if dt > 0 then
				despawnTimer = max(despawnTimer, dt)
			elseif dt == -1 then
				despawnTimer = 0
				break
			end
		end
		npc:mem(0x12A, FIELD_WORD, despawnTimer)
		for _,v in ipairs(data.attachedNPCs) do
			v:mem(0x12A, FIELD_WORD, despawnTimer)
		end
	end
	
	if despawnTimer > 0 then
		data.despawned = false
		
		-- Handle inactive NPCs
		if not data.active then
			
			-- prevent NPCs from falling if they don't fall when inactive
			if not data.fallWhenInactive then
				local lyr = npc.layerObj
				npc.speedX = lyr.speedX
				npc.speedY = lyr.speedY
				if hasGravity(npc.id) then
					removeVanillaGravity(npc)
				end
			end
			
			-- Activate when a player is standing on this NPC if set to do so
			if data.activateOnStanding then
				for _,plr in ipairs(Player.get()) do
					if plr.standingNPC and (plr.standingNPC == npc) then
						data.active = true
						break
					end
				end
			end
		end
		
		if data.state == ONLINE and data.active then
		
			-- Handling for negative lineSpeed
			-- abs(lineSpeed) is used for speed computations later
			-- I'm "faking" negative lineSpeed because doing it "for real" would require a fundamental rewrite
			if data.lineSpeed < 0 and not data.reversed then
				turnAround(npc, data)
				data.reversed = true
			elseif data.lineSpeed >= 0 and data.reversed then
				turnAround(npc, data)
				data.reversed = false
			end
		
			applyVector(npc, data.velocity, false, data.adjustmentX, data.adjustmentY)
			if data.adjustmentX then
				data.adjustmentX = nil
				data.adjustmentY = nil
			end
			applyLayerSpeed(npc, data)
			if data.omega then
				rotateVector(data)
			end
		elseif data.state == FALLING then
			if NPC.config[npc.id].npcblocktop then
				-- Force npcs standing on the platform to "stick" to the platform.
				for _,v in ipairs(NPC.getIntersecting(npc.x, npc.y - 4, npc.x + npc.width, npc.y)) do
					if not v:mem(0x64, FIELD_BOOL) then
						if hasGravity(v.id) and (v.y + v.height <= npc.y) and not v.data._basegame.lineguide then -- standing on an NPC
							v.speedY = npc.speedY + Defines.npc_grav
						end
					end
				end
			end
		end
		
		if data.state ~= ONLINE then
			if checkShouldFreeze() then
				if not data.storedSpeedX then
					data.storedSpeedX = npc.speedX
					data.storedSpeedY = npc.speedY
				end
				npc.speedX = 0
				npc.speedY = 0
				if hasGravity(npc.id) then
					removeVanillaGravity(npc)
				end
			else
				if data.storedSpeedX then
					npc.speedX = data.storedSpeedX
					npc.speedY = data.storedSpeedY
					data.storedSpeedX = nil
					data.storedSpeedY = nil
				end
			end
			local velocity = vectr.v2(npc.speedX, npc.speedY)
			if hasGravity(npc.id) then
				velocity.y = velocity.y + Defines.npc_grav
				if data.buoyant and npc.underwater and data.active then
					local isSinking = npc.speedY > 0
					local multiplier = 1
					if isSinking then
						multiplier = 1.2
					end
					local buoyancyAmount = 1.2 * multiplier * Defines.npc_grav
					velocity.y = math.max(velocity.y - buoyancyAmount, -2.5)
					npc.speedY = math.max(npc.speedY - buoyancyAmount, -2.5)
				end
			end
			if data.attachedNPCs then
				for _,v in ipairs(data.attachedNPCs) do
					applyVector(v, velocity, true)
				end
			end
		end
	else
		if not data.despawned then
			data.despawned = true
			lineguide.onDespawnNPC(npc)
		end
		if data.attachedNPCs then
			for _,v in ipairs(data.attachedNPCs) do
				if v.isValid then
					v:mem(0x12A, FIELD_WORD, 0)
				end
			end
		end
	end
end

function lineguide.onTickEndNPC(npc)
	if npc:mem(0x138, FIELD_WORD) > 0 then return end

	if npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame.lineguide
		if data == nil then
			lineguide.onStartNPC(npc)
			data = npc.data._basegame.lineguide
		end
		if (data.state == NORMAL or data.state == FALLING) and data.active then
			updateSensor(npc, data)
			-- Don't search for lines if the cooldown hasn't ended
			if not checkShouldFreeze() then
				if data.attachCooldown == 0 then
					local line = checkForLine(npc, data)
					if line then
						local col1, d1, col2, d2, sign = getNodes(line)
						lineData = {line = line, start = col1, startDir = d1, dest = col2, destDir = d2, sign = sign}
						attachToLine(npc, data, lineData)
					end
				else
					data.attachCooldown = data.attachCooldown - 1
				end
			end
			
			if data.state == FALLING and npc.collidesBlockBottom then
				npc.speedX = lineguide.speeds[npc.id] * npc.direction
				npc.speedY = 0 -- Don't bounce
				data.state = NORMAL
				if not NPC.config[npc.id].collideswhenattached then
					npc.noblockcollision = false -- Allow collision since not on line
				end
			end
		elseif data.state == ONLINE then
			-- detatch from the line if it becomes hidden
			if (not data.useHiddenLines) and data.lineData.isHidden then
				data.attachCooldown = ATTACH_COOLDOWN
				data.state = FALLING
				if not NPC.config[npc.id].collideswhenattached then
					npc.noblockcollision = false -- Allow collision since no longer on line
				end
				return
			end
			-- prevent the NPC from turning around because it hit other NPCs
			if npc:mem(0x120, FIELD_BOOL) and (npc:mem(0x0C, FIELD_WORD) ~= 2 and npc:mem(0x10, FIELD_WORD) ~= 2) then
				npc:mem(0x120, FIELD_BOOL, false)
			end
			
			updateSensor(npc, data)
			if checkPosition(data) then
				data.sensor.x = data.dest.x
				data.sensor.y = data.dest.y
				lockToSensor(npc, data)
				goToNextLine(npc, data)
			end
			-- turn the NPC araound if it hits a wall
			if not NPC.config[npc.id].noblockcollision and checkForBlockCollision(npc) then
				npc:mem(0x120, FIELD_BOOL, false)
				turnAround(npc, data)
			end
		end
	end
end

function lineguide.onDrawNPC(npc)
	if lineguide.debug and npc:mem(0x12A, FIELD_WORD) > 0 then
		local data = npc.data._basegame.lineguide
		if data then
			if data.sensor then data.sensor:Draw() end
			start = data.start
			dest = data.dest
			if start then
				colliders.Circle(start.x, start.y, 4):Draw(0x00FF0088)
				colliders.Circle(dest.x, dest.y, 4):Draw(0x0000FF88)
			end
		end
	end
end

function lineguide.onDrawEndNPC(npc)
	-- Misc.dialog("onDrawEndNPC") -- too late to print
	if npc.data._basegame and npc.data._basegame.lineguide then
		-- if data.extendedDespawnTimer and npc:mem(0x12A, FIELD_WORD) > 0 then
		if npc.data._basegame.lineguide.extendedDespawnTimer and not npc:mem(0x128, FIELD_BOOL) then
			npc:mem(0x12A, FIELD_WORD, 3000)
		end
	end
end

return lineguide;
