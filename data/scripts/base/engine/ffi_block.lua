local LegacyBlock = Block
local mem = mem
local ffi_utils = require("ffi_utils")

-----------------------------
-- EXTENDED FIELDS SUPPORT --
-----------------------------

local extendedBlockFieldsArray = nil
do
	ffi.cdef([[
		const char* LunaLuaGetBlockExtendedFieldsStruct();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	-- Define structure
	ffi.cdef(ffi.string(LunaDLL.LunaLuaGetBlockExtendedFieldsStruct()))
	
	ffi.cdef([[
		ExtendedBlockFields* LunaLuaGetBlockExtendedFieldsArray();
	]])
	extendedBlockFieldsArray = LunaDLL.LunaLuaGetBlockExtendedFieldsArray()
end

----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
int LunaLuaBlocksTestCollision(unsigned int plAddr, unsigned int blAddr);
void LunaLuaBlockRemove(unsigned int idx, short playSoundEffect);
void LunaLuaSetSizableRenderFlag(bool val);
]]
local LunaDLL = ffi.load("LunaDll.dll")
local voidPtr
do
	local voidPtr_t = ffi.typeof("void *")
	function voidPtr(val)
		return ffi.cast(voidPtr_t, val)
	end
end

--------------
-- COUNTERS --
--------------

local blockUidCounter = 1

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_BLOCKS_SORTED = 0xB2C894

local GM_BLOCK_ADDR = mem(0xB25A04, FIELD_DWORD)
local GM_BLOCK_COUNT_ADDR = 0xB25956

local GM_SIZABLE_LIST_ADDR = mem(0xB2BED8, FIELD_DWORD)
local GM_SIZABLE_COUNT_ADDR = 0xB2BEE4

local GM_BLOCK_LOOKUP_MIN = mem(0xB25758, FIELD_DWORD)
local GM_BLOCK_LOOKUP_MAX = mem(0xB25774, FIELD_DWORD)
local LOOKUP_MIN = setmetatable({}, {
	__index = function(tbl, idx)
		return readmem(GM_BLOCK_LOOKUP_MIN + 2*idx, FIELD_WORD)
	end,
	__newindex = function(tbl, idx, val)
		writemem(GM_BLOCK_LOOKUP_MIN + 2*idx, FIELD_WORD, val)
	end
})
local LOOKUP_MAX = setmetatable({}, {
	__index = function(tbl, idx)
		return readmem(GM_BLOCK_LOOKUP_MAX + 2*idx, FIELD_WORD)
	end,
	__newindex = function(tbl, idx, val)
		writemem(GM_BLOCK_LOOKUP_MAX + 2*idx, FIELD_WORD, val)
	end
})
local lookupMinMax
do
	local floor = math.floor
	function lookupMinMax(x1, x2)
		return LOOKUP_MIN[floor(x1 / 32) + 8000], LOOKUP_MAX[floor(x2 / 32) + 8001]
	end
end

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function blockGetIdx(block)
	return block._idx
end

local function blockGetIsValid(block)
	return block._ptr ~= -1
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

local function getBlockLight(block)
	local darkdata = block.data._basegame._darkness
	if darkdata and darkdata[2] then
		return darkdata[2]
	end
	return nil
end

local function setBlockLight(block, value)	
	local darkdata = block.data._basegame._darkness
	if darkdata then
		if darkdata[2] and darkdata[2] ~= value then
			darkdata[2]:destroy()
		end
	
		darkdata[2] = value
	else
		block.data._basegame._darkness = { block.id, value }
	end
end

local function getLayerSpeedX(block)
	return extendedBlockFieldsArray[block._idx].layerSpeedX
end

local function getLayerSpeedY(block)
	return extendedBlockFieldsArray[block._idx].layerSpeedY
end

local function getExtraSpeedX(block)
	return extendedBlockFieldsArray[block._idx].extraSpeedX
end

local function getExtraSpeedY(block)
	return extendedBlockFieldsArray[block._idx].extraSpeedY
end

local function setExtraSpeedX(block, value)
	extendedBlockFieldsArray[block._idx].extraSpeedX = value
	block.speedX = extendedBlockFieldsArray[block._idx].layerSpeedX + value
end

local function setExtraSpeedY(block, value)
	extendedBlockFieldsArray[block._idx].extraSpeedY = value
	block.speedY = extendedBlockFieldsArray[block._idx].layerSpeedY + value
end

------------------------
-- FIELD DECLERATIONS --
------------------------
local BlockFields = {
		idx       = {get=blockGetIdx, readonly=true, alwaysValid=true},
		isValid   = {get=blockGetIsValid, readonly=true, alwaysValid=true},
		
		-- pblock compatibility
		uid         = {get=function(block) return block._uid end, readonly=true, alwaysValid=true},
		pid         = {get=function(block) return block._uid end, readonly=true, alwaysValid=true},
		pidIsDirty  = {get=function(block) return false end, readonly=true, alwaysValid=true},
		
		lightSource = {get=getBlockLight, set=setBlockLight},
		
		x         = {0x20, FIELD_DFLOAT},
		y         = {0x28, FIELD_DFLOAT},
		height    = {0x30, FIELD_DFLOAT},
		width     = {0x38, FIELD_DFLOAT},
		speedX    = {0x40, FIELD_DFLOAT},
		speedY    = {0x48, FIELD_DFLOAT},
		id        = {0x1E, FIELD_WORD},
		contentID = {0x50, FIELD_WORD},
		isHidden  = {0x1C, FIELD_BOOL},
		invisible = {0x1C, FIELD_BOOL}, -- Alias
		slippery  = {0x00, FIELD_BOOL},
		layerObj  = {0x18, FIELD_STRING, decoder=layerNameToLayerObj, encoder=layerObjToLayerName},
		layerName = {0x18, FIELD_STRING},
		
		layerSpeedX = {get=getLayerSpeedX, readonly=true},
		layerSpeedY = {get=getLayerSpeedY, readonly=true},
		extraSpeedX = {get=getExtraSpeedX, set=setExtraSpeedX},
		extraSpeedY = {get=getExtraSpeedY, set=setExtraSpeedY},
}

-----------------------
-- CLASS DECLERATION --
-----------------------

local Block = {__type="Block"}
local BlockMT = ffi_utils.implementClassMT("Block", Block, BlockFields, blockGetIsValid)
local BlockCache = {}
local freeIndicies = {}
local freeMap = {}

-- Constructor
setmetatable(Block, {__call=function(Block, idx)
	if BlockCache[idx] then
		return BlockCache[idx]
	end
	
	local block = {_idx=idx, _ptr=GM_BLOCK_ADDR + idx*0x68, _uid=blockUidCounter, data = {_basegame = {}, _settings =  Block.makeDefaultSettings(readmem(GM_BLOCK_ADDR + idx*0x68 + 0x1E, FIELD_WORD))}}
	setmetatable(block, BlockMT)
	BlockCache[idx] = block
	
	blockUidCounter = blockUidCounter + 1
	
	return block
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

local mem = mem
local readmem = readmem

-- 'mem' implementation
function Block:mem(offset, dtype, val)
	if not blockGetIsValid(self) then
		error("Invalid Block object")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

function Block:collidesWith(plyr)
	if (type(plyr) ~= "Player") then
		error("Block:collidesWith requires a player object")
	end
	if not blockGetIsValid(self) then
		error("Invalid Block object")
	end
	
	local plX1 = plyr.x - 0.20
	local plY1 = plyr.y - 0.20
	local plX2 = plyr.x + plyr.width + 0.20
	local plY2 = plyr.y + plyr.height + 0.20
	
	if (plX1 > self.x + self.width) or
		(plX2 < self.x) or
		(plY1 > self.y + self.height) or
		(plY2 < self.y)
	then
		return 0
	end
	
	return LunaDLL.LunaLuaBlocksTestCollision(plyr._ptr, self._ptr)
end

function Block:remove(playSoundEffect)
	if not blockGetIsValid(self) then
		error("Invalid Block object")
	end

	if (playSoundEffect) then
		LegacyBlock(self._idx):remove(true)
	else
		LegacyBlock(self._idx):remove(false)
	end
end

function Block:hit(fromUpSide, plyr, hittingCount)
	if not blockGetIsValid(self) then
		error("Invalid Block object")
	end

	-- Process arguments 
	
	if fromUpSide then
		fromUpSide = -1
	else
		fromUpSide = 0
	end
	
	local playerIdx = 1
	if (plyr ~= nil) then
		playerIdx = plyr._idx
	end
	
	if hittingCount == nil then
		hittingCount = -1
	end
	
	-- Call function
	-- Use a legacy non-ffi function because this may trigger more calls back
	-- into Lua.
	LegacyBlock._rawHitBlock(self._idx, fromUpSide, playerIdx, hittingCount)
end

function Block:delete()
	if not blockGetIsValid(self) then
		error("Invalid Block object")
	end
	
	local idx = self._idx
	
	-- If we're deleting a sizable, handle that
	if Block.SIZEABLE_MAP[self.id] then
		local sizableCount = mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD)
		local foundSizableIdx = nil
		for i=0,sizableCount-1 do
			if (mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD) == idx) then
				foundSizableIdx = i
				break
			end
		end
		if (foundSizableIdx ~= nil) then
			for i=foundSizableIdx,sizableCount-2 do
				mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD, mem(GM_SIZABLE_LIST_ADDR + (i+1)*2, FIELD_WORD))
			end
			mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD, sizableCount - 1)
		end
	end
	
	self.layerName = "Destroyed Blocks"
	self.id = 0
	self.isHidden = true
	extendedBlockFieldsArray[idx].layerSpeedX = 0
	extendedBlockFieldsArray[idx].layerSpeedY = 0
	extendedBlockFieldsArray[idx].extraSpeedX = 0
	extendedBlockFieldsArray[idx].extraSpeedY = 0

	if (freeMap[idx] == nil) then
		self._idx = -1
		self._ptr = -1
		freeIndicies[#freeIndicies + 1] = idx
		freeMap[idx] = #freeIndicies
	end
	BlockCache[idx] = nil
end

local function blockCompare(a, b)
	if a.x < b.x then
		return -1
	elseif a.x > b.x then
		return 1
	elseif a.y < b.y then
		return -1
	elseif a.y > b.y then
		return 1
	else
		return 0
	end
end

function Block:translate(dx, dy)
	if dx == 0 and dy == 0 then
		return self
	end
	self.x = self.x + dx
	self.y = self.y + dy
	

	-- TODO: Consider updating the lookup in a faster less agressive way
	if (readmem(GM_BLOCKS_SORTED, FIELD_BOOL) == true) then
		writemem(GM_BLOCKS_SORTED, FIELD_BOOL, false)
		local count = Block.count()
		for i = 0, 16000 do
			LOOKUP_MIN[i] = 1
			LOOKUP_MAX[i] = count
		end
	end
	
	return self
end

--------------------
-- STATIC METHODS --
--------------------

local function BlockCount()
	return readmem(GM_BLOCK_COUNT_ADDR, FIELD_WORD)
end
Block.count = BlockCount

local function SizableCount()
	return readmem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD)
end
Block.countSizable = SizableCount
Block.countSizeable = SizableCount --alias

local getMT = {__pairs = ipairs}

do
	
	local function iteratewithfilter(tbl, i)
		local count = BlockCount()
		while(i < count) do
			i = i + 1
			if tbl[readmem(GM_BLOCK_ADDR + 0x1E + (0x68 * i), FIELD_WORD)] then
				return i, Block(i)
			end
		end
	 end
	 
	 local function iteratewithid(id, i)
		local count = BlockCount()
		while(i < count) do
			i = i + 1
			if readmem(GM_BLOCK_ADDR + 0x1E + (0x68 * i), FIELD_WORD) == id then
				return i, Block(i)
			end
		end
	 end

	local function iteratesizable(_, i)
		local count = SizableCount()
		while i + 1 < count do
			i = i + 1
			return i, Block(readmem(GM_SIZABLE_LIST_ADDR + (0x2 * i), FIELD_WORD))
		end
	end

	function Block.iterateByFilterMap(filterMap)
		if (type(filterMap) ~= "table") then
			error("Invalid parameters to iterateByFilterMap",2)
		end
		return iteratewithfilter, filterMap, 0
	end
	ffi_utils.earlyWarnCall(Block, "Block", "iterateByFilterMap", Block.iterateByFilterMap)
	
	local function iterate(_, i)
		local count = BlockCount()
		while(i < count) do
			i = i + 1
			return i, Block(i)
		end
	end
	
	local function tablemap(t)
		local t2 = {};
		for _,v in ipairs(t) do
			t2[v] = true;
		end
		return t2;
	end
	
	function Block.iterate(args)
		if(args == nil or args == -1) then
			return iterate, nil, 0
		elseif(type(args) == "number" and args ~= -1) then
			return iteratewithid, args, 0
		elseif(type(args) == "table") then
			return iteratewithfilter, tablemap(args), 0
		else
			error("Invalid parameters to iterate",2)
		end
	end
	ffi_utils.earlyWarnCall(Block, "Block", "iterate", Block.iterate)

	local function iterateintersecting(args, i)
		while i <= args[5] do
			local ptr = GM_BLOCK_ADDR + (0x68 * i);
			
			local bx = readmem(ptr + 0x20, FIELD_DFLOAT)
			if (args[3] > bx) then
				local by = readmem(ptr + 0x28, FIELD_DFLOAT)
				if (args[4] > by) then
					local bw = readmem(ptr + 0x38, FIELD_DFLOAT)
					if (bx + bw > args[1]) then
						local bh = readmem(ptr + 0x30, FIELD_DFLOAT)
						if (by + bh > args[2]) then
							return i + 1, Block(i)
						end
					end
				end
			end
			i = i + 1
		end
	end

	function Block.iterateIntersecting(x1, y1, x2, y2)
		local minIdx, maxIdx = lookupMinMax(x1, x2)
		local blockiterator = {x1, y1, x2, y2, maxIdx}
		return iterateintersecting, blockiterator, minIdx
	end
	ffi_utils.earlyWarnCall(Block, "Block", "iterateIntersecting", Block.iterateIntersecting)

	function Block.iterateSizable()
		-- TODO: ID filtering?
		return iteratesizable, nil, -1
	end
	Block.iterateSizeable = Block.iterateSizable --alias
	ffi_utils.earlyWarnCall(Block, "Block", "iterateSizable", Block.iterateSizable)
	ffi_utils.earlyWarnCall(Block, "Block", "iterateSizeable", Block.iterateSizeable)
end

function Block.get(idFilter)
	local ret = {}
	
	if (idFilter == nil) then
		for idx=1,Block.count() do
			ret[#ret+1] = Block(idx)
		end
	elseif (type(idFilter) == "number") then
		local ptr = GM_BLOCK_ADDR + 0x1E
		for idx=1,Block.count() do
			ptr = ptr + 0x68
			if (mem(ptr, FIELD_WORD) == idFilter) then
				ret[#ret+1] = Block(idx)
			end
		end
	elseif (type(idFilter) == "table") then
		local lookup = {}
		for _,id in ipairs(idFilter) do
			lookup[id] = true
		end
		
		local ptr = GM_BLOCK_ADDR + 0x1E
		for idx=1,Block.count() do
			ptr = ptr + 0x68
			if lookup[mem(ptr, FIELD_WORD)] then
				ret[#ret+1] = Block(idx)
			end
		end
	else
		error("Invalid parameters to get")
	end
	
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Block, "Block", "get", Block.get)

function Block.getByFilterMap(filterMap)
	local ret = {}
	
	if (type(filterMap) ~= "table") then
		error("Invalid parameters to getByFilterMap")
	end
	
	local ptr = GM_BLOCK_ADDR + 0x1E
	for idx=1,Block.count() do
		ptr = ptr + 0x68
		if filterMap[mem(ptr, FIELD_WORD)] then
			ret[#ret+1] = Block(idx)
		end
	end
	
	setmetatable(ret, getMT)	
	return ret
end
ffi_utils.earlyWarnCall(Block, "Block", "getByFilterMap", Block.getByFilterMap)

function Block.getIntersecting(x1, y1, x2, y2)
	if (type(x1) ~= "number") or (type(y1) ~= "number") or (type(x2) ~= "number") or (type(y2) ~= "number") then
		error("Invalid parameters to getIntersecting")
	end
	
	local ret = {}
	local minIdx, maxIdx = lookupMinMax(x1, x2)
	local ptr = GM_BLOCK_ADDR + 0x68 * (minIdx - 1)
	for idx = minIdx, maxIdx do
		ptr = ptr + 0x68
		local bx = mem(ptr + 0x20, FIELD_DFLOAT)
		if (x2 > bx) then
			local by = mem(ptr + 0x28, FIELD_DFLOAT)
			if (y2 > by) then
				local bw = mem(ptr + 0x38, FIELD_DFLOAT)
				if (bx + bw > x1) then
					local bh = mem(ptr + 0x30, FIELD_DFLOAT)
					if (by + bh > y1) then
						ret[#ret+1] = Block(idx)
					end
				end
			end
		end
	end
	setmetatable(ret, getMT)	
	return ret
end
ffi_utils.earlyWarnCall(Block, "Block", "getIntersecting", Block.getIntersecting)

function Block.spawn(blockid, x, y)
	local count = mem(GM_BLOCK_COUNT_ADDR, FIELD_WORD)
	local destIdx = nil
	local b
	local incrementedCount = false
	
	-- If there are free indicies from deleted blocks, reuse them
	while (#freeIndicies > 0) do
		destIdx = freeIndicies[#freeIndicies]
		freeIndicies[#freeIndicies] = nil
		if (destIdx ~= nil) and (destIdx ~= false) then
		    break
		end
	end
	
	-- Do we have a freed index?
	if (destIdx ~= nil) and (destIdx ~= false) then
		-- Clear free index
		freeMap[destIdx] = nil
		
		-- If there was a block object for the destroyed block, invalidate it
		local oldBlockObj = BlockCache[idx]
		if (oldBlockObj ~= nil) then
			oldBlockObj._idx = -1
			oldBlockObj._ptr = -1
			BlockCache[idx] = nil
		end
		
		-- Make new block
		b = Block(destIdx)
	else
		-- Increment block count
		incrementedCount = true
		count = count + 1
		mem(GM_BLOCK_COUNT_ADDR, FIELD_WORD, count)
		destIdx = count
		b = Block(destIdx)
	end

	-- Create block
	b.slippery = false
	b:mem(0x02, FIELD_WORD, 0) -- Unknown
	b:mem(0x04, FIELD_WORD, 0) -- RepeatingHits
	b:mem(0x06, FIELD_WORD, blockid) -- BlockType2
	b:mem(0x08, FIELD_WORD, 0) -- ContentIDRelated
	b:mem(0x0A, FIELD_WORD, 0) -- Unknown
	b:mem(0x0C, FIELD_STRING, "") -- HitEventName
	b:mem(0x10, FIELD_STRING, "") -- DestroyEventName
	b:mem(0x14, FIELD_STRING, "") -- NoMoreObjInLayerEventName
	b.layerName = "Default"
	b.isHidden = false
	b.id = blockid
	b.x = x
	b.y = y
	b.width = Block.config[blockid].width
	b.height = Block.config[blockid].height
	b.speedX = 0.0
	b.speedY = 0.0
	b.contentID = 0
	b:mem(0x52, FIELD_WORD, 0) -- BeingHitStatus1
	b:mem(0x54, FIELD_WORD, 0) -- BeingHitTimer
	b:mem(0x56, FIELD_WORD, 0) -- HitOffset
	b:mem(0x58, FIELD_WORD, 0) -- Unknown
	b:mem(0x5A, FIELD_WORD, 0) -- IsInvisible2
	b:mem(0x5C, FIELD_WORD, 0) -- IsInvisible3
	b:mem(0x5E, FIELD_WORD, 0) -- Unknown
	b:mem(0x60, FIELD_WORD, 0) -- Unknown
	b:mem(0x62, FIELD_WORD, 0) -- Unknown
	b:mem(0x64, FIELD_WORD, 0) -- Unknown
	b:mem(0x66, FIELD_WORD, 0) -- Unknown
	
	-- Set default settings/data properly for block ID
	b.data = {_basegame = {}, _settings =  Block.makeDefaultSettings(blockid)}
	
	-- If we've just spawned a sizable, handle that
	if Block.SIZEABLE_MAP[blockid] then
		local i = mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD)
		mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD, i + 1)
		mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD, destIdx)
	end
	
	-- TODO: Consider updating the lookup in a faster less agressive way
	if (readmem(GM_BLOCKS_SORTED, FIELD_BOOL) == true) or incrementedCount then
		writemem(GM_BLOCKS_SORTED, FIELD_BOOL, false)
		for i = 0, 16000 do
			LOOKUP_MIN[i] = 1
			LOOKUP_MAX[i] = count
		end
	end
	
	return b
end
ffi_utils.earlyWarnCall(Block, "Block", "spawn", Block.spawn)

function Block:transform(newID, centered)
	local x = self.x
	local y = self.y
	if centered == nil then
		centered = true
	end
		
	local cfg = Block.config[newID]
	local siz = cfg.sizable
	
	if not siz and centered then
		x = x+self.width*0.5
		y = y+self.height*0.5
	end
	
	local oldid = self.id
	self.id = newID
	
	if not siz then
		--set the physical width and height
		local w = cfg.width
		local h = cfg.height
		
		if cfg.sizable then
			w = self.width
			h = self.height
		end
		
		if w == 0 then
			w = self.width
		end
		
		if h == 0 then
			h = self.height
		end
			
		--height before width in the struct
		self:mem(0x30, FIELD_DFLOAT, h)
		self:mem(0x38, FIELD_DFLOAT, w)
			
		--offset coordinates
		if centered then
			x = x-w*0.5
			y = y-h*0.5
		end
	
		self.x = x
		self.y = y
		
		--handle turning a sizable into a non-sizable
		if Block.config[oldid].sizable then
			local idx = self._idx
			local sizableCount = mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD)
			local foundSizableIdx = nil
			for i=0,sizableCount-1 do
				if (mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD) == idx) then
					foundSizableIdx = i
					break
				end
			end
			if (foundSizableIdx ~= nil) then
				for i=foundSizableIdx,sizableCount-2 do
					mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD, mem(GM_SIZABLE_LIST_ADDR + (i+1)*2, FIELD_WORD))
				end
				mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD, sizableCount - 1)
			end
		end
		
	elseif not Block.config[oldid].sizable then
		local i = mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD)
		mem(GM_SIZABLE_COUNT_ADDR, FIELD_WORD, i + 1)
		mem(GM_SIZABLE_LIST_ADDR + i*2, FIELD_WORD, self._idx)
	end
	
	--Destroy lights associated with this block
	local darkdata = self.data._basegame._darkness
	if darkdata and darkdata[2] then
		darkdata[2]:destroy()
	end
	
	--Reset _basegame table for re-initialisation.
	self.data._basegame = {}
		
	local gsettings = self.data._settings._global
	--Update _settings table with a table of default values
	self.data._settings = Block.makeDefaultSettings(newID)
	self.data._settings._global = gsettings
end

local bumpableMetatable = {
	__index = function(tbl, id)
		return LegacyBlock._getBumpable(id)
	end,
	__newindex = function(tbl, id, val)
		LegacyBlock._setBumpable(id, val)
	end
}
Block.bumpable = setmetatable({}, bumpableMetatable)

function Block._SetVanillaSizableRenderFlag(val)
	LunaDLL.LunaLuaSetSizableRenderFlag(val)
end

--------------------------------
-- Block Persistance Tracking --
--------------------------------

local blockPersistanceListener = {}

function blockPersistanceListener.onBlockInvalidateForReuseInternal(idx)
	-- If there was a block object for the destroyed block, invalidate it
	local oldBlockObj = BlockCache[idx]
	if (oldBlockObj ~= nil) then
		oldBlockObj._idx = -1
		oldBlockObj._ptr = -1
		BlockCache[idx] = nil
	end
	local freeIdxIdx = freeMap[idx]
	if (freeIdxIdx ~= nil) then
		freeIndicies[freeIdxIdx] = false
		freeMap[idx] = nil
	end
end

registerEvent(blockPersistanceListener, "onBlockInvalidateForReuseInternal", "onBlockInvalidateForReuseInternal", true)

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Block = Block
return Block
