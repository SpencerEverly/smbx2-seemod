local LegacyNPC = NPC
local mem = mem
local readmem = readmem
local writemem = writemem
local ffi_utils = require("ffi_utils")

-----------------------------
-- EXTENDED FIELDS SUPPORT --
-----------------------------

local extendedNpcFieldsArray = nil
do
	ffi.cdef([[
		const char* LunaLuaGetNPCextendedFieldsStruct();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	-- Define structure
	ffi.cdef(ffi.string(LunaDLL.LunaLuaGetNPCextendedFieldsStruct()))
	
	ffi.cdef([[
		ExtendedNPCFields* LunaLuaGetNPCExtendedFieldsArray();
	]])
	extendedNpcFieldsArray = LunaDLL.LunaLuaGetNPCExtendedFieldsArray()
end

----------------------
-- MEMORY ADDRESSES --
----------------------
local NPC_STRUCT_SIZE = 0x158
local GM_NPC_ADDR = readmem(0x00B259E8, FIELD_DWORD) + 129*NPC_STRUCT_SIZE
local GM_NPC_COUNT_ADDR = 0x00B2595A

--------------
-- COUNTERS --
--------------

local npcUidCounter = 1

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function npcGetCount()
	return readmem(GM_NPC_COUNT_ADDR, FIELD_WORD)
end

local function npcGetIdx(npc)
	return npc._idx
end

local function npcGetIsValid(npc)
	return npc._ptr ~= -1
end

local function sectionToSectionObj(idx)
	if (idx >= 21) then
		return nil
	end
	return Section(idx)
end

local function layerNameToLayerObj(layerName)
	if (layerName == "") then return Layer(Layer.count()) end
	return Layer.get(layerName)
end

local function layerObjToLayerName(layerObj)
	if (layerObj == nil) then
		return ""
	end
	return layerObj.layerName
end

local function numToCollidesBlockBool(v)
	return (v == 2)
end

local function collidesBlockBoolToNum(v)
	if v then
		return 2
	end
	return 0
end

local function setDontMove(npc, val)
	writemem(npc._ptr+0x48, FIELD_BOOL, val)
	writemem(npc._ptr+0x4A, FIELD_BOOL, val) -- dontMove2?
end

local function setDirection(npc, val)
	writemem(npc._ptr+0xEC, FIELD_FLOAT, val)
	if not NPC.config[npc.id].staticdirection then
		writemem(npc._ptr+0x98, FIELD_DFLOAT, 0) -- speedX
	end
end

local function getNoBlockCollision(npc)
	if extendedNpcFieldsArray[npc._idx+1].noblockcollision then
		return true
	else
		return false
	end
end

local function setNoBlockCollision(npc, value)
	if value then
		value = true
	else
		value = false
	end
	extendedNpcFieldsArray[npc._idx+1].noblockcollision = value
end

local function getNPCLight(npc)
	local darkdata = npc.data._basegame._darkness
	if darkdata and darkdata[2] then
		return darkdata[2]
	end
	return nil
end

local function setNPCLight(npc, value)	
	local darkdata = npc.data._basegame._darkness
	if darkdata then
		if darkdata[2] and darkdata[2] ~= value then
			darkdata[2]:destroy()
		end
	
		darkdata[2] = value
	else
		npc.data._basegame._darkness = { npc.id, value }
	end
end

------------------------
-- FIELD DECLARATIONS --
------------------------
local NPCFields = {
	idx                 = {get=npcGetIdx, readonly=true, alwaysValid=true},
	isValid             = {get=npcGetIsValid, readonly=true, alwaysValid=true},
	
	-- pnpc compatibility
	uid                 = {get=function(npc) return npc._uid end, readonly=true, alwaysValid=true},
	pid                 = {get=function(npc) return npc._uid end, readonly=true, alwaysValid=true},
	pidIsDirty          = {get=function(npc) return false end, readonly=true, alwaysValid=true},

	-- extended
	noblockcollision    = {get=getNoBlockCollision, set=setNoBlockCollision},
	lightSource         = {get=getNPCLight, set=setNPCLight},
	
	attachedLayerName   = {0x00,  FIELD_STRING},
	attachedLayerObj    = {0x00,  FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
	collidesBlockBottom = {0x0A,  FIELD_WORD, decoder=numToCollidesBlockBool, encoder=collidesBlockBoolToNum},
	collidesBlockLeft   = {0x0C,  FIELD_WORD, decoder=numToCollidesBlockBool, encoder=collidesBlockBoolToNum},
	collidesBlockUp     = {0x0E,  FIELD_WORD, decoder=numToCollidesBlockBool, encoder=collidesBlockBoolToNum},
	collidesBlockRight  = {0x10,  FIELD_WORD, decoder=numToCollidesBlockBool, encoder=collidesBlockBoolToNum},
	underwater          = {0x1C,  FIELD_BOOL},
	invincibleToSword   = {0x26,  FIELD_BOOL},
	drawOnlyMask        = {0x28,  FIELD_BOOL},
	activateEventName   = {0x2C,  FIELD_STRING},
	deathEventName      = {0x30,  FIELD_STRING},
	talkEventName       = {0x34,  FIELD_STRING},
	noMoreObjInLayer    = {0x38,  FIELD_STRING},
	layerName           = {0x3C,  FIELD_STRING},
	layerObj            = {0x3C,  FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
	isHidden            = {0x40,  FIELD_BOOL},
	legacyBoss          = {0x42,  FIELD_BOOL},
	-- activated                 @ 0x44, FIELD_BOOL?
	friendly            = {0x46,  FIELD_BOOL},
	dontMove            = {0x48,  FIELD_BOOL, set=setDontMove}, -- This property also sets 0x4A
	-- dontMove2                 @ 0x4A, FIELD_BOOL?
	msg                 = {0x4C,  FIELD_STRING},
	isGenerator         = {0x64,  FIELD_BOOL},
	generatorInterval   = {0x68,  FIELD_FLOAT},
	generatorTimer      = {0x6C,  FIELD_FLOAT},
	generatorDirection  = {0x70,  FIELD_WORD},
	generatorType       = {0x72,  FIELD_WORD},
	-- offscreenFlag             @ 0x74, FIELD_BOOL?
	x                   = {0x78,  FIELD_DFLOAT},
	y                   = {0x80,  FIELD_DFLOAT},
	height              = {0x88,  FIELD_DFLOAT},
	width               = {0x90,  FIELD_DFLOAT},
	speedX              = {0x98,  FIELD_DFLOAT},
	speedY              = {0xA0,  FIELD_DFLOAT},
	spawnX              = {0xA8,  FIELD_DFLOAT},
	spawnY              = {0xB0,  FIELD_DFLOAT},
	spawnHeight         = {0xB8,  FIELD_DFLOAT},
	spawnWidth          = {0xC0,  FIELD_DFLOAT},
	spawnSpeedX         = {0xC8,  FIELD_DFLOAT},
	spawnSpeedY         = {0xD0,  FIELD_DFLOAT},
	spawnDirection      = {0xD8,  FIELD_FLOAT},
	spawnId             = {0xDC,  FIELD_WORD},
	spawnAi1            = {0xDE,  FIELD_WORD},
	spawnAi2            = {0xE0,  FIELD_WORD},
	id                  = {0xE2,  FIELD_WORD},
	animationFrame      = {0xE4,  FIELD_WORD},
	animationTimer      = {0xE8,  FIELD_FLOAT},
	direction           = {0xEC,  FIELD_FLOAT, set=setDirection}, -- This property speedX to 0 when you set it
	ai1                 = {0xF0,  FIELD_DFLOAT},
	ai2                 = {0xF8,  FIELD_DFLOAT},
	ai3                 = {0x100, FIELD_DFLOAT},
	ai4                 = {0x108, FIELD_DFLOAT},
	ai5                 = {0x110, FIELD_DFLOAT},
	-- direction2                @ 0x118, FIELD_FLOAT?
	-- bounceOffBlock            @ 0x120, FIELD_WORD?
	killFlag            = {0x122, FIELD_WORD},
	-- offscreenFlag2            @ 0x128, FIELD_BOOL?
	despawnTimer        = {0x12A, FIELD_WORD},
	-- grabbingPlayerIndex       @ 0x12C, FIELD_WORD?
	-- grabTimer                 @ 0x12E, FIELD_WORD?
	-- collidesWithNPC           @ 0x136, FIELD_BOOL?
	-- containedWithin           @ 0x138, FIELD_WORD?
	section             = {0x146, FIELD_WORD},
	sectionObj          = {0x146, FIELD_WORD, decoder=sectionToSectionObj, readonly=true},
	-- hitCount                  @ 0x148, FIELD_FLOAT?
	-- pSwitchTransformedBlockID @ 0x14E, FIELD_WORD?
	-- npcCollisionFlag          @ 0x152, FIELD_BOOL?
	-- invincibilityFrames       @ 0x156, FIELD_WORD?

}

-----------------------
-- CLASS DECLARATION --
-----------------------
local NPC = {__type="NPC"}
local NPCMT = ffi_utils.implementClassMT("NPC", NPC, NPCFields, npcGetIsValid)
local NPCCache = {}

-- Constructor
setmetatable(NPC, {__call = function(NPC, idx)
	if NPCCache[idx] then
		return NPCCache[idx]
	end
	
	if (idx < 0) or (idx >= npcGetCount()) then
		error("Invalid NPC index")
	end
	
	local npc = {_idx = idx, _ptr = GM_NPC_ADDR + idx*NPC_STRUCT_SIZE, _uid=npcUidCounter, data = {_basegame = {}, _settings = NPC.makeDefaultSettings(readmem(GM_NPC_ADDR + idx*NPC_STRUCT_SIZE + 0xE2,  FIELD_WORD))}}
	setmetatable(npc, NPCMT)
	NPCCache[idx] = npc
	
	npcUidCounter = npcUidCounter + 1
	
	return npc
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function NPC:mem(offset, dtype, val)
	if not npcGetIsValid(self) then
		error("Invalid NPC object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

-- 'kill' implementation
function NPC:kill(harmType)
	if harmType == nil then
		harmType = 1
	end
	self.killFlag = harmType
	self.isHidden = false
end

-- 'toIce' implementation
function NPC:toIce()
	LegacyNPC(self._idx):toIce()
end

-- 'toCoin' implementation
function NPC:toCoin()
	LegacyNPC(self._idx):toCoin()
end

-- 'harm' implementation
function NPC:harm(harmType, damage, multiplier)
	if (harmType == nil) then harmType = HARM_TYPE_NPC end
	if (multiplier == nil) then multiplier = 0 end
	if damage == nil then
		return Misc._npcHarmCombo(self._idx, harmType, multiplier)
	else
		return Misc._npcHarmComboWithDamage(self._idx, harmType, multiplier, damage)
	end
end

--------------------
-- STATIC METHODS --
--------------------

local getMT = {__pairs = ipairs}

function NPC.count()
	return npcGetCount()
end

-- Iterate/Get function helper to get map from list
local function tablemap(t)
	local t2 = {};
	for _,v in ipairs(t) do
		t2[v] = true;
	end
	return t2;
end

-- Iterator for filtering by map
local function iteratewithfilter(tbl, i)
	local count = npcGetCount()
	while(i < count) do
		if tbl[readmem(GM_NPC_ADDR + 0xE2 + (NPC_STRUCT_SIZE * i), FIELD_WORD)] then
			return i + 1, NPC(i)
		end
		i = i + 1
	end
end

-- Iterator for filtering by id 
local function iteratewithid(id, i)
	local count = npcGetCount()
	while(i < count) do
		if readmem(GM_NPC_ADDR + 0xE2 + (NPC_STRUCT_SIZE * i), FIELD_WORD) == id then
			return i + 1, NPC(i)
		end
		i = i + 1
	end
end
 
 -- Iterator with no filter
local function iterate(_, i)
	local count = npcGetCount()
	if (i < count) then
		return i + 1, NPC(i)
	end
end

function NPC.iterateByFilterMap(filterMap)
	if (type(filterMap) ~= "table") then
		error("Invalid parameters to iterateByFilterMap",2)
	end
	return iteratewithfilter, filterMap, 0
end
ffi_utils.earlyWarnCall(NPC, "NPC", "iterateByFilterMap", NPC.iterateByFilterMap)

function NPC.iterate(args)
	if(args == nil or args == -1) then
		return iterate, nil, 0
	elseif(type(args) == "number" and args ~= -1) then
		return iteratewithid, args, 0
	elseif(type(args) == "table") then
		return iteratewithfilter, tablemap(args), 0
	else
		error("Invalid parameters to iterate", 2)
	end
end
ffi_utils.earlyWarnCall(NPC, "NPC", "iterate", NPC.iterate)

function NPC.get(idFilter, sectionFilter)
	local ret = {}
	
	-- Process table id filter
	local idLookup = nil
	if (type(idFilter) == "table") then
		idLookup = tablemap(idFilter)
		idFilter = nil
	elseif (idFilter ~= nil) and (type(idFilter) ~= "number") then
		error("Invalid parameters to get")
	end
	if idFilter == -1 then
		idFilter = nil
	end
	
	-- Process table section filter
	local sectionLookup = nil
	if (type(sectionFilter) == "table") then
		sectionLookup = tablemap(sectionFilter)
		sectionFilter = nil
	elseif (sectionFilter ~= nil) and (type(sectionFilter) ~= "number") then
		error("Invalid parameters to get")
	end
	if sectionFilter == -1 then
		sectionFilter = nil
	end
	
	local ptr = GM_NPC_ADDR
	for idx=0,npcGetCount()-1 do
		if not (
				((idFilter      ~= nil) and      (idFilter ~= readmem(ptr + 0xE2, FIELD_WORD))) or
				((idLookup      ~= nil) and      not idLookup[readmem(ptr + 0xE2, FIELD_WORD)]) or
				((sectionFilter ~= nil) and (sectionFilter ~= readmem(ptr + 0x146, FIELD_WORD))) or
				((sectionLookup ~= nil) and not sectionLookup[readmem(ptr + 0x146, FIELD_WORD)])
			) then
			ret[#ret+1] = NPC(idx)
		end
		ptr = ptr + NPC_STRUCT_SIZE
	end
	
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(NPC, "NPC", "get", NPC.get)

function NPC.getByFilterMap(filterMap)
	local ret = {}
	
	if (type(filterMap) ~= "table") then
		error("Invalid parameters to getByFilterMap")
	end
	
	local ptr = GM_NPC_ADDR + 0xE2
	for idx=0,npcGetCount()-1 do
		if filterMap[readmem(ptr, FIELD_WORD)] then
			ret[#ret+1] = NPC(idx)
		end
		ptr = ptr + NPC_STRUCT_SIZE
	end
	
	setmetatable(ret, getMT)	
	return ret
end
ffi_utils.earlyWarnCall(NPC, "NPC", "getByFilterMap", NPC.getByFilterMap)

local function iterateintersecting(args, i)
	while i < args[5] do
		local ptr = GM_NPC_ADDR + (NPC_STRUCT_SIZE * i);
		
		local bx = readmem(ptr + 0x78, FIELD_DFLOAT)
		if (args[3] > bx) then
			local by = readmem(ptr + 0x80, FIELD_DFLOAT)
			if (args[4] > by) then
				local bw = readmem(ptr + 0x90, FIELD_DFLOAT)
				if (bx + bw > args[1]) then
					local bh = readmem(ptr + 0x88, FIELD_DFLOAT)
					if (by + bh > args[2]) then
						return i + 1, NPC(i)
					end
				end
			end
		end
		i = i + 1
	end
end

function NPC.iterateIntersecting(x1, y1, x2, y2)
	local npciterator = {x1, y1, x2, y2, npcGetCount()}
	return iterateintersecting, npciterator, 0
end
ffi_utils.earlyWarnCall(NPC, "NPC", "iterateIntersecting", NPC.iterateIntersecting)

function NPC.getIntersecting(x1, y1, x2, y2)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end
	
	local ret = {}
	
	local ptr = GM_NPC_ADDR
	for idx = 0, npcGetCount()-1 do
		local bx = readmem(ptr + 0x78, FIELD_DFLOAT)
		if (x2 > bx) then
			local by = readmem(ptr + 0x80, FIELD_DFLOAT)
			if (y2 > by) then
				local bw = readmem(ptr + 0x90, FIELD_DFLOAT)
				if (bx + bw > x1) then
					local bh = readmem(ptr + 0x88, FIELD_DFLOAT)
					if (by + bh > y1) then
						ret[#ret+1] = NPC(idx)
					end
				end
			end
		end
		ptr = ptr + NPC_STRUCT_SIZE
	end
	
	setmetatable(ret, getMT)	
	return ret
end
ffi_utils.earlyWarnCall(NPC, "NPC", "getIntersecting", NPC.getIntersecting)

local getEditorProps
do
	local editorProps = {}
	local configFileReader
	
	function getEditorProps(npcid)
		if editorProps[npcid] == nil then
			if configFileReader == nil then
				configFileReader = require(getSMBXPath().."\\scripts\\base\\configFileReader.lua")
			end
			local ini = Misc.resolveFile("npc-"..npcid..".ini") or getSMBXPath().."/PGE/configs/SMBX2-Integration/items/npc/npc-"..npcid..".ini"
			if ini == nil then
				editorProps[npcid] = {}
			else
				editorProps[npcid] = configFileReader.rawParse(ini)
			end
		end
		return editorProps[npcid]
	end
	
end

do
	local rng
	-- TODO: Native Lua version
	function NPC.spawn(npcid, x, y, section, respawn, centered)
		if respawn == nil then respawn = false end
		if centered == nil then centered = false end
		if section == nil then
			section = Section.getIdxFromCoords(x, y)
		end
		local npc = LegacyNPC.spawn(npcid, x, y, section, respawn, centered)
		npc = NPC(npc.idx)
		
		local props = getEditorProps(npcid)
		local dir = props["direction-default-value"]
		if dir == nil then
			if rng == nil then
				rng = require(getSMBXPath().."\\scripts\\base\\rng.lua")
			end
			dir = ((rng.randomInt(1) * 2) - 1)
		end
		npc.direction = dir
		
		return npc
	end
	ffi_utils.earlyWarnCall(NPC, "NPC", "spawn", NPC.spawn)
end

function NPC:transform(newID, centered, changeSpawn)
		local x = self.x
		local y = self.y
		if centered == nil then
			centered = true
		end
		
		local cfg = NPC.config[newID]
		
		if centered then
			x = x+self.width*0.5
			if cfg.noblockcollision then
				y = y+self.height*0.5
			else
				y = y+self.height
			end
		end
		self.id = newID
		
		--set the physical width and height
		local w = cfg.width
		local h = cfg.height
		
		--height before width in the struct
		self:mem(0x88, FIELD_DFLOAT, h)
		self:mem(0x90, FIELD_DFLOAT, w)
		
		--offset x coordinate
		if centered then
			x = x-w*0.5
			if cfg.noblockcollision then
				y = y-h*0.5
			else
				y = y-h
			end
		end
		
		self.x = x
		self.y = y
		
		self.ai1 = 0
		self.ai2 = 0
		self.ai3 = 0
		self.ai4 = 0
		self.ai5 = 0
		self.animationFrame = 0
		if cfg.framestyle > 0 and self.direction == 1 then
			self.animationFrame = cfg.frames
		end
		self.animationTimer = 1
		
		--Destroy lights associated with this NPC
		local darkdata = self.data._basegame._darkness
		if darkdata and darkdata[2] then
			darkdata[2]:destroy()
		end
		
		--Reset _basegame table for re-initialisation.
		self.data._basegame = {}
		
		local gsettings = self.data._settings._global
		--Update _settings table with a table of default values
		self.data._settings = NPC.makeDefaultSettings(newID)
		self.data._settings._global = gsettings
		
		if not changeSpawn then return end
		
		--spawn width and height if you so desire!
		local currentSpawnX = self:mem(0xA8, FIELD_DFLOAT)
		local currentSpawnY = self:mem(0xB0, FIELD_DFLOAT)
		local oldSpawnWidth = self:mem(0xC0, FIELD_DFLOAT)
		local oldSpawnHeight = self:mem(0xB8, FIELD_DFLOAT)
		
		self:mem(0xA8, FIELD_DFLOAT, currentSpawnX + 0.5 * oldSpawnWidth - 0.5 * w)
		self:mem(0xB0, FIELD_DFLOAT, currentSpawnY + oldSpawnHeight - h)
		self:mem(0xB8, FIELD_DFLOAT, h)
		self:mem(0xC0, FIELD_DFLOAT, w)
		
		self:mem(0xDC, FIELD_WORD, newID)
		self:mem(0xDE, FIELD_WORD, 0)
		self:mem(0xE0, FIELD_WORD, 0)
		self:mem(0xE4, FIELD_WORD, 0)
	end

----------------------
-- LEGACY FUNCTIONS --
----------------------

-- Global npcs()
function _G.npcs()
	local ret = {}
	local ptr = GM_NPC_ADDR
	for idx=0,npcGetCount()-1 do
		ret[idx] = NPC(idx)
	end
	return ret
end

-- Global findnpcs()
function _G.findnpcs(id, section)
	local ret = {}
	local ptr = GM_NPC_ADDR
	local outidx = 0
	for idx=0,npcGetCount()-1 do
		if (((id == -1) or (readmem(ptr + 0xE2, FIELD_WORD) == id)) and
			((section == -1) or (readmem(ptr + 0x146, FIELD_WORD) == section))) then
			ret[outidx] = NPC(idx)
			outidx = outidx + 1
		end
		ptr = ptr + NPC_STRUCT_SIZE
	end
	return ret
end

-- Global spawnNPC()
_G.spawnNPC = NPC.spawn

------------------------------
-- NPC Persistance Tracking --
------------------------------

local npcPersistanceListener = {}

function npcPersistanceListener.onPostNPCRearrangeInternal(newIdx, oldIdx)
	local killedObj = NPCCache[newIdx]
	if killedObj ~= nil then
		-- Invalidate NPC object
		killedObj._idx = -1
		killedObj._ptr = -1
		NPCCache[newIdx] = nil
	end
	
	-- Move NPC object 
	if (newIdx ~= oldIdx) then
		local npcObj = NPCCache[oldIdx]
		if npcObj ~= nil then
			-- Move cache entry
			NPCCache[oldIdx] = nil
			NPCCache[newIdx] = npcObj
			
			-- Set idx and ptr
			npcObj._idx = newIdx
			npcObj._ptr = GM_NPC_ADDR + newIdx*NPC_STRUCT_SIZE
		end	
	end
end

registerEvent(npcPersistanceListener, "onPostNPCRearrangeInternal", "onPostNPCRearrangeInternal", true)

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.NPC = NPC
return NPC
