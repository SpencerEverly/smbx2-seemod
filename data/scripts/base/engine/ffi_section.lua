local mem = mem
local ffi_utils = require("ffi_utils")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_LVL_BOUNDARIES = mem(0x00B257D4, FIELD_DWORD)
local GM_ORIG_LVL_BOUNDS = mem(0x00B2587C, FIELD_DWORD)
local GM_SEC_MUSIC_TBL = mem(0x00B25828, FIELD_DWORD)
local GM_SEC_ISWARP = mem(0x00B257F0, FIELD_DWORD)
local GM_SEC_OFFSCREEN = mem(0x00B2580C, FIELD_DWORD)
local GM_SEC_BG_ID = mem(0x00B258B8, FIELD_DWORD)
local GM_SEC_ORIG_BG_ID = mem(0x00B25860, FIELD_DWORD)
local GM_SEC_NOTURNBACK = mem(0x00B2C5EC, FIELD_DWORD)
local GM_SEC_ISUNDERWATER = mem(0x00B2C608, FIELD_DWORD)
local GM_SEC_MUSIC_PATH = mem(0xB257B8, FIELD_DWORD)

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------

local function sectionGetIdx(section)
	return section._idx
end

local function sectionGetIsValid(section)
	local idx = section._idx

	if (idx >= 0) and (idx <= 20) then
		return true
	end

	return false
end

local function getBoundary(s)
	local r = {}
	r.left =   readmem(GM_LVL_BOUNDARIES 	+ s.idx*8*6, 	  FIELD_DFLOAT)
	r.top =    readmem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 8,  FIELD_DFLOAT)
	r.bottom = readmem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 16, FIELD_DFLOAT)
	r.right =  readmem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 24, FIELD_DFLOAT)

	return r
end	

local function setBoundary(s, r)
	writemem(GM_LVL_BOUNDARIES 	+ s.idx*8*6, 	  FIELD_DFLOAT,	r.left)
	writemem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 8,  FIELD_DFLOAT,	r.top)
	writemem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 16, FIELD_DFLOAT, r.bottom)
	writemem(GM_LVL_BOUNDARIES 	+ s.idx*8*6 + 24, FIELD_DFLOAT, r.right)
	
	return r
end

local function getOrigBoundary(s)
	local r = {}
	r.left =   readmem(GM_ORIG_LVL_BOUNDS 	+ s.idx*8*6, 	  FIELD_DFLOAT)
	r.top =    readmem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 8,  FIELD_DFLOAT)
	r.bottom = readmem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 16, FIELD_DFLOAT)
	r.right =  readmem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 24, FIELD_DFLOAT)
	
	return r
end	

local function setOrigBoundary(s, r)
	writemem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6, 	  FIELD_DFLOAT,	r.left)
	writemem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 8,  FIELD_DFLOAT,	r.top)
	writemem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 16, FIELD_DFLOAT, r.bottom)
	writemem(GM_ORIG_LVL_BOUNDS  	+ s.idx*8*6 + 24, FIELD_DFLOAT, r.right)
	
	return r
end

local function getMusicPath(s)
	return readmem(GM_SEC_MUSIC_PATH + s.idx*4, FIELD_STRING)
end

local function setMusicPath(s, p)
	if s.musicID == 24 then
		-- If the custom path is currently in use, use Audio.MusicChange
		Audio.MusicChange(s.idx, tostring(p))
	else
		-- Otherwise, just set the custom path
		writemem(GM_SEC_MUSIC_PATH + s.idx*4, FIELD_STRING, p)
	end
end


local function bool(b)
	if b then
		return -1
	else
		return 0
	end
end

local function getMusicID(s)
	return readmem(GM_SEC_MUSIC_TBL + s.idx * 2, FIELD_WORD)
end

local function setMusicID(s, id)
	Audio.MusicChange(s.idx, tonumber(id))
end

local function getMusic(s)
	local musicID = getMusicID(s)
	if musicID == 24 then
		return getMusicPath(s)
	else
		return musicID
	end
	
end

local function setMusic(s, p)
	Audio.MusicChange(s.idx, p)
end

local function getWrapH(s)
	return (readmem(GM_SEC_ISWARP + s.idx * 2, FIELD_WORD) ~= 0)
end

local function setWrapH(s, b)
	writemem(GM_SEC_ISWARP + s.idx * 2, FIELD_WORD, bool(b))
end

local function getHasOffscreenExit(s)
	return (readmem(GM_SEC_OFFSCREEN + s.idx * 2, FIELD_WORD) ~= 0)
end

local function setHasOffscreenExit(s, b)
	writemem(GM_SEC_OFFSCREEN + s.idx * 2, FIELD_WORD, bool(b))
end

local background = { get = function() return nil end, set = function() return nil end }

local function getBackground(s)
	return background.get(s.idx)
end

local function setBackground(s, b)
	return background.set(s.idx, b)
end

local function getBackgroundID(s)
	return readmem(GM_SEC_BG_ID + s.idx * 2, FIELD_WORD)
end

local function setBackgroundID(s, id)
	writemem(GM_SEC_BG_ID + s.idx * 2, FIELD_WORD, id)
end

local function getOrigBackgroundID(s)
	return readmem(GM_SEC_ORIG_BG_ID + s.idx * 2, FIELD_WORD)
end

local function setOrigBackgroundID(s, id)
	writemem(GM_SEC_ORIG_BG_ID + s.idx * 2, FIELD_WORD, id)
end

local function getNoTurnBack(s)
	return (readmem(GM_SEC_NOTURNBACK + s.idx * 2, FIELD_WORD) ~= 0)
end

local function setNoTurnBack(s, b)
	writemem(GM_SEC_NOTURNBACK + s.idx * 2, FIELD_WORD, bool(b))
end

local function getIsUnderwater(s)
	return (readmem(GM_SEC_ISUNDERWATER + s.idx * 2, FIELD_WORD) ~= 0)
end

local function setIsUnderwater(s, b)
	writemem(GM_SEC_ISUNDERWATER + s.idx * 2, FIELD_WORD, bool(b))
end


------------------------
--   DARKNESS STUFF   --
------------------------

local darknessTable = {}

local function getDarkness(s)
	return darknessTable[s]
end

local function setDarkness(s, t)
	darknessTable[s] = t
end

-----------------------
--   EFFECTS STUFF   --
-----------------------

local effectTable = {}

local function getEffects(s)
	return effectTable[s]
end

local function setEffects(s, t)
	effectTable[s] = t
end


------------------------
--  SECTION SETTINGS  --
------------------------
local section_settings = {}

for i=0,20 do
	section_settings[i] = {}
end

local function getSettings(s)
	return section_settings[s.idx]
end

local function setSettings(s, d)
	section_settings[s.idx] = d
end

------------------------
-- FIELD DECLARATIONS --
------------------------
local SectionFields = {
	idx         = {get=sectionGetIdx, readonly=true, alwaysValid=true},
	isValid     = {get=sectionGetIsValid, readonly=true, alwaysValid=true},

	boundary    	 = {get=getBoundary, set=setBoundary},
	origBoundary     = {get=getOrigBoundary, set=setOrigBoundary},
	musicID     	 = {get=getMusicID, set=setMusicID},
	musicPath		 = {get=getMusicPath, set=setMusicPath},
	music			 = {get=getMusic, set=setMusic},
	wrapH 	 		 = {get=getWrapH, set=setWrapH},
	hasOffscreenExit = {get=getHasOffscreenExit, set=setHasOffscreenExit},
	backgroundID	 = {get=getBackgroundID, set=setBackgroundID},
	background	 	 = {get=getBackground, setBackground=setBackground},
	origBackgroundID = {get=getOrigBackgroundID, set=setOrigBackgroundID},
	noTurnBack		 = {get=getNoTurnBack, set=setNoTurnBack},
	isUnderwater     = {get=getIsUnderwater, set=setIsUnderwater},
	
	
	settings		 = {get=getSettings, set=setSettings},
	darkness		 = {get=getDarkness, readonly=true},--, set=setDarkness},
	effects			 = {get=getEffects, readonly=true},--, set=setEffects},
	
	
	--Deprecated
	isLevelWarp 	 = {get=getWrapH, set=setWrapH}
}

-----------------------
-- CLASS DECLARATION --
-----------------------
local Section = {}
local SectionMT = ffi_utils.implementClassMT("Section", Section, SectionFields, sectionGetIsValid)
local SectionCache = {}

-- Constructor
setmetatable(Section, {__call = function(Section, idx)
	if SectionCache[idx] then
		return SectionCache[idx]
	end

	local section = {_idx = idx}
	setmetatable(section, SectionMT)
	SectionCache[idx] = section
	return section
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------


--------------------
-- STATIC METHODS --
--------------------
function Section.count()
	return 21
end

-- Function to get active section indicies.
-- Sections are considered 'active' if there is at least one player in it.
-- 
-- Note that this is not called 'getActive()'  because that name is reserved
-- for a function that returns the section objects instead of indicies.
function Section.getActiveIndices()
	local sectionIdxMap = {}
	local sectionIdxList = {}
		
	for _,v in ipairs(Player.get()) do
		local sectionIdx = v.section
		if not sectionIdxMap[sectionIdx] then
			sectionIdxMap[sectionIdx] = true
			sectionIdxList[#sectionIdxList+1] = sectionIdx
		end
	end
		
	return sectionIdxList
end

-- Function to get active section objects.
-- Sections are considered 'active' if there is at least one player in it.
function Section.getActive()
	local sectionIdxMap = {}
	local sectionList = {}
		
	for _,v in ipairs(Player.get()) do
		local sectionIdx = v.section
		if not sectionIdxMap[sectionIdx] then
			sectionIdxMap[sectionIdx] = true
			sectionList[#sectionList+1] = Section(sectionIdx)
		end
	end
		
	return sectionList
end
ffi_utils.earlyWarnCall(Section, "Section", "getActive", Section.getActive)

local getMT = {__pairs = ipairs}

function Section.get(idx)
	if idx then
		return Section(idx-1)
	end
	
	local ret = {}
	for idx=0,20 do
		ret[#ret+1] = Section(idx)
	end
	setmetatable(ret, getMT)
	return ret
end
ffi_utils.earlyWarnCall(Section, "Section", "get", Section.get)

-- Section get by coords
-- Arguments can be one of:
--     (x, y)
--     (x, y, w, h)
--     (obj)
-- If using obj, it must have the properties x/y/width/height
function Section.getFromCoords(arg1, arg2, arg3, arg4)
	local x, y, w, h
	if (type(arg1) == "number") and (type(arg2) == "number") then
		x, y, w, h = arg1, arg2, arg3, arg4
	elseif (arg1 ~= nil) then
		x = arg1.x
		y = arg1.y
		w = arg1.width
		h = arg1.height
	end
	
	-- Check that we got something valid
	if (type(x) ~= "number") or (type(y) ~= "number") or
			(
				((w ~= nil) or (h ~= nil)) and
				((type(w) ~= "number") or (type(h) ~= "number"))
			) then
		error("Invalid arguments to Section.getFromCoords. Expected (x, y), (x, y, w, h) or (obj)", 1)
	end

	-- Default nil w/h parameters
	if (w == nil) or (h == nil) then
		w, h = 0, 0
	end

	-- Check current boundaries first, and if not found check the original section boundaries.
	-- This matches what built-in 1.3 logic does
	for _,v in ipairs(Section.get()) do
		local b = v.boundary
		if x+w >= b.left and x <= b.right and y+h >= b.top and y <= b.bottom then
			return v
		end
	end
	for _,v in ipairs(Section.get()) do
		local b = v.origBoundary
		if x+w >= b.left and x <= b.right and y+h >= b.top and y <= b.bottom then
			return v
		end
	end
	return nil
end
ffi_utils.earlyWarnCall(Section, "Section", "getFromCoords", Section.getFromCoords)

-- Section get index by coords, defaulting to 0 if no section
-- Arguments can be one of:
--     (x, y)
--     (x, y, w, h)
--     (obj)
-- If using obj, it must have the properties x/y/width/height
function Section.getIdxFromCoords(arg1, arg2, arg3, arg4)
	local sec = Section.getFromCoords(arg1, arg2, arg3, arg4)
	if (sec ~= nil) then
		return sec.idx
	end
	return 0
end
ffi_utils.earlyWarnCall(Section, "Section", "getIdxFromCoords", Section.getIdxFromCoords)

function Section.__initBackground(l)
	background = l
	rawset(Section, "__initBackground", nil)
end

if isOverworld then
	Section.__initBackground = nil
end

---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Section = Section
return Section
