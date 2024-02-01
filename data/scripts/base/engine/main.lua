--[[

'##:::::::'##::::'##:'##::: ##::::'###::::'##:::::::'##::::'##::::'###::::
 ##::::::: ##:::: ##: ###:: ##:::'## ##::: ##::::::: ##:::: ##:::'## ##:::
 ##::::::: ##:::: ##: ####: ##::'##:. ##:: ##::::::: ##:::: ##::'##:. ##::
 ##::::::: ##:::: ##: ## ## ##:'##:::. ##: ##::::::: ##:::: ##:'##:::. ##:
 ##::::::: ##:::: ##: ##. ####: #########: ##::::::: ##:::: ##: #########:
 ##::::::: ##:::: ##: ##:. ###: ##.... ##: ##::::::: ##:::: ##: ##.... ##:
 ########:. #######:: ##::. ##: ##:::: ##: ########:. #######:: ##:::: ##:
........:::.......:::..::::..::..:::::..::........:::.......:::..:::::..::
	'########:'##::: ##::'######:::'####:'##::: ##:'########::::
	 ##.....:: ###:: ##:'##... ##::. ##:: ###:: ##: ##.....:::::
	 ##::::::: ####: ##: ##:::..:::: ##:: ####: ##: ##::::::::::
	 ######::: ## ## ##: ##::'####:: ##:: ## ## ##: ######::::::
	 ##...:::: ##. ####: ##::: ##::: ##:: ##. ####: ##...:::::::
	 ##::::::: ##:. ###: ##::: ##::: ##:: ##:. ###: ##::::::::::
	 ########: ##::. ##:. ######:::'####: ##::. ##: ########::::
	........::..::::..:::......::::....::..::::..::........:::::

]]

--LunaLua Version
__LUNALUA = "0.7 SEE Mod"
__isLuaError = false

--SMBX2 Version logic
do
	local function makeVersion(major, subver, minor, beta, preview, patch, hotfix)
		if beta == 0 then
			beta = 255
		else
			beta = beta-1
		end
		
		if preview == 0 then
			preview = 15
		else
			preview = preview-1
		end
		
		return major   * 17592186044416 --[[2^44 (lshift 44) - 8 bits - 0-255 - Major Version (i.e. 2)]]
		     + subver  * 68719476736    --[[2^36 (lshift 36) - 8 bits - 0-255 - Subversion]]
			 + minor   * 268435456      --[[2^28 (lshift 28) - 8 bits - 0-255 - Minor Version]] 
			 + beta    * 1048576        --[[2^20 (lshift 20) - 8 bits - 0-255 - Beta Version  	(0 largest)]]
			 + preview * 65536			--[[2^16 (lshift 16) - 4 bits - 0-15  - Preview Version (0 largest)]]
			 + patch   * 256			--[[2^8  (lshift 8)  - 8 bits - 0-255 - Patch]]
			 + hotfix					--[[                   8 bits - 0-255 - Hotfix]]
	end
	
							
	--With EVERY release, a new version	MUST be added here.
	
	--										#  .#  .# .b# .p#  .#  .#
	_G["VER_BETA1"] 			= 	makeVersion(2,	0,	0,	1,	0,	0,	0)
	_G["VER_BETA2"] 			= 	makeVersion(2,	0,	0,	2,	0,	0,	0)
	_G["VER_BETA3"] 			= 	makeVersion(2,	0,	0,	3,	0,	0,	0)
	_G["VER_MAGLX3"]			= 	makeVersion(2,	0,	0,	4,	1,	0,	0)
	_G["VER_PAL"] 				= 	makeVersion(2,	0,	0,	4,	2,	0,	0)
	_G["VER_PAL_HOTFIX"] 		= 	makeVersion(2,	0,	0,	4,	2,	0,	1)
	_G["VER_BETA4"] 			= 	makeVersion(2,	0,	0,	4,	0,	0,	0)
	_G["VER_BETA4_HOTFIX"] 		= 	makeVersion(2,	0,	0,	4,	0,	0,	1)
	_G["VER_BETA4_PATCH_2"] 	= 	makeVersion(2,	0,	0,	4,	0,	2,	0)
	_G["VER_BETA4_PATCH_2_1"] 	= 	makeVersion(2,	0,	0,	4,	0,	2,	1)
	_G["VER_BETA4_PATCH_3"] 	= 	makeVersion(2,	0,	0,	4,	0,	3,	0)
	_G["VER_BETA4_PATCH_3_1"] 	= 	makeVersion(2,	0,	0,	4,	0,	3,	1)
	_G["VER_BETA4_PATCH_4"] 	= 	makeVersion(2,	0,	0,	4,	0,	4,	0)
	_G["VER_BETA4_PATCH_4_1"] 	= 	makeVersion(2,	0,	0,	4,	0,	4,	1)
	_G["VER_SEE_MOD"]           =   makeVersion(3,	0,	0,	0,	0,	0,	0)
	
	--								e.g.		2  .0  .0 .b4 .p2  .0  .1    = PAL Hotfix
	
	
	--Update this to the latest version 
	_G["SMBX_VERSION"] = VER_SEE_MOD
	
	
	
	
	_G["getSMBXVersionString"] = function(v)
		v = v or SMBX_VERSION
		
		local major 	= 		   math.floor(v / 17592186044416)
		local subver 	= bit.band(math.floor(v / 68719476736), 0xFF)
		local minor 	= bit.band(math.floor(v / 268435456), 	0xFF)
		local beta		= bit.band(math.floor(v / 1048576), 	0xFF)
		local preview	= bit.band(math.floor(v / 65536), 		0xF)
		local patch		= bit.band(math.floor(v / 256), 		0xFF)
		local hotfix	= bit.band(math.floor(v), 				0xFF)
		
		local s = major.."."..subver.."."..minor
		
		beta = beta+1
		if beta > 255 then
			beta = 0
		end
		
		preview = preview+1
		if preview > 15 then
			preview = 0
		end
		
		if beta > 0 then
			s = s..".b"..beta
		end
		
		if preview > 0 then
			s = s..".p"..preview
		end
		
		if patch > 0 or hotfix > 0 then
			s = s.."."..patch
		end
		
		if hotfix > 0 then
			s = s.."."..hotfix
		end
		
		return s
	end
end

-- Implement print based on console:println
do
	local console = console
	local tostring = tostring
	local iparis = ipairs
	local type = type
	function _G.print(...)
		local argList = {...}
		local out = ""
		for i,v in ipairs(argList) do
			if i > 1 then
				out = out .. "\t"
			end
			if type(v) == "userdata" then
				out = out .. "<userdata>"
			else
				out = out .. tostring(v)
			end
		end
		console:println(out)
	end
end

-- Flag to enable/disable the JIT compiler log, saved to logs/jit.log
local enableJitLog = false

collectgarbage("setstepmul", 1) -- 1ms

local string_gsub = string.gsub
local lockdown = dofile(getSMBXPath() .. "/scripts/base/engine/lockdown.lua")
local readFile = lockdown.readFile

do
	local func, err = loadfile(
		getSMBXPath() .. "/scripts/base/engine/require.lua",
		"t",
		_G
	)
	if (func == nil) then
		error("Error: " .. err)
	end
	require_utils = func()
end

-------------------
-- JIT managment --
-------------------
do
	local jit = require('jit')
	
	jit.opt.start(3, "maxtrace=5000", "maxrecord=20000", "maxmcode=8192", "hotloop=3", "hotexit=3")

	if (enableJitLog) then
		local jitContext = require_utils.makeGlobalContext(_G)
		local requireJit = require_utils.makeRequire(
			string_gsub(getSMBXPath(), ";", "<") .. "/scripts/ext/?.lua", -- Path
			jitContext, -- Global table
			{jit = jit, ["jit.util"]=require("jit.util")}, -- Loaded table
			true, -- Share globals
			true) -- Assign require

		local v = requireJit("jit.v")
		
		v.start("logs/jit.log")
	end
end

--------------------
-- Error handling --
--------------------

local function __xpcall (f, ...)
  return xpcall(f,
	function (msg)
	  -- build the error message
	  return debug.traceback("==> " .. msg .. "\n=============", 2)
	end, ...)
end

-----------
-- Utils --
-----------
function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

local function __xpcallCheck(returnData)
	if not returnData[1] then
		Text.windowDebug(returnData[2])
		-- The following line used to cause shutdown of Lua
		-- __isLuaError = true
		-- TODO: See about a mechanism to avoid issues if errors keep happening repeatedly.
		return false
	end
	return true
end

-- Version check
function compareLunaVersion(...)
	local versionNum = {...}
	-- We want to check the version number depending on the depth.
	-- i.e. You use compareVersion(0, 7, 2) then the first 3 version number
	local versionNumCount = #versionNum
	local internalVersionNumCount = #__LUNA_VERSION_TABLE
	if versionNumCount > internalVersionNumCount then
		versionNumCount = internalVersionNumCount
	end
	
	for i = 1, versionNumCount do
		if versionNum[i] > __LUNA_VERSION_TABLE[i] then
			return 1
		end
		if versionNum[i] < __LUNA_VERSION_TABLE[i] then
			return -1
		end
	end
	return 0
end

_G.npcGlobalVariables = {}

function addNPCToGlobalTable(id, value)
    table.insert(npcGlobalVariables, id, value)
end

-------------------------------
-- Low Level Library Loading --
-------------------------------

-- Keep access to FFI local to here
_G.ffi = require("ffi")

-- Function to load low level libraries that require access to FFI
lowLevelLibraryContext = require_utils.makeGlobalContext(_G, {ffi=ffi, _G=_G})
local requireLowLevelLibrary = require_utils.makeRequire(
	string_gsub(getSMBXPath(), ";", "<") .. "/scripts/base/engine/?.lua", -- Path
	lowLevelLibraryContext, -- Global table
	{},    -- Loaded table
	false, -- Share globals
	true)  -- Assign require

---------------------
-- Preload/Loaded cleanup --
---------------------

--package.preload['ffi'] = nil
--package.loaded['ffi'] = nil


-- We want the JIT running, so it's initially loadeded, but disable access to it
package.preload['jit'] = nil
package.loaded['jit'] = nil
	
-------------------
-- Event Manager --
-------------------
local EventManager = requireLowLevelLibrary("main_events")

------------------
-- Sounds table --
------------------

local soundIniData = {}
local soundIniCount = 0

local function testSoundIdx(soundIdx)
	return type(soundIdx) == "number" and math.floor(soundIdx) == soundIdx and soundIdx >= 1
end

do
	--Contains ini-read sound data
	
	local tableinsert = table.insert
	
	-- This function creates the "virtual" attributes for the sound table.
	local function makeSoundTable(soundIdx)
		if not testSoundIdx(soundIdx) then
			error("Audio.sounds" .. "[" .. tostring(soundIdx) .. "] does not exist")
		end
		local soundAlias = "sound" .. tostring(soundIdx)
		local spriteMT = {
			__index = function(tbl, key)
				if (key == "sfx") then
					return Audio.__getChunkForAlias(soundAlias)
				end
				if (key == "muted") then
					return Audio.__getMuteForAlias(soundAlias)
				end
				error("Audio.sounds" .. "[" .. tostring(soundIdx) .. "]." .. tostring(key) .. " does not exist")
			end,
			__newindex = function(tbl, key, val)
				if (key == "sfx") then
					val = val or soundIniData[soundIdx]
					Audio.__setOverrideForAlias(soundAlias, val)
					return
				end
				if (key == "muted") then
					Audio.__setMuteForAlias(soundAlias, val)
					return
				end
				error("Audio.sounds" .. "[" .. tostring(soundIdx) .. "]." .. tostring(key) .. " does not exist")
			end
		}
		return setmetatable({}, spriteMT)
	end
	
	local soundsMetatable = {
		__index = function(tbl, soundIdx)
			return makeSoundTable(soundIdx)
		end,
		__newindex = function(tbl, key, val)
			error("Cannot write to Audio.sounds table")
		end
	}
	Audio.sounds = {}
	setmetatable(Audio.sounds, soundsMetatable)
	local getmusvol = Audio._GetMusicVolume
	local setmusvol = Audio.MusicVolume
	
	Audio.MusicVolume = function(volume)
		if(volume == nil) then
			return getmusvol()
		else
			setmusvol(volume)
		end
	end
end

-----------------
-- Music table --
-----------------

_G.AUDIO_MUSIC_SPECIAL = 1
_G.AUDIO_MUSIC_OVERWORLD = 2
_G.AUDIO_MUSIC_LEVEL = 3

local testMusicIdxLimits = {
    [AUDIO_MUSIC_SPECIAL] = 3,
    [AUDIO_MUSIC_OVERWORLD] = 16,
    [AUDIO_MUSIC_LEVEL] = 56,
}

local function testMusicIdx(soundIdx, category)
    return type(soundIdx) == "number" and math.floor(soundIdx) == soundIdx and soundIdx >= 1 and soundIdx <= testMusicIdxLimits[category]
end

local musicIniData = {}
local musicIniCountSpecial = 0
local musicIniCountOverworld = 0
local musicIniCountLevel = 0

musicIniData[AUDIO_MUSIC_SPECIAL] = {}
musicIniData[AUDIO_MUSIC_OVERWORLD] = {}
musicIniData[AUDIO_MUSIC_LEVEL] = {}

local musicSpecialTable = {
    [1] = "smusic",
    [2] = "stmusic",
    [3] = "tmusic",
}

do
    -- This function creates the "virtual" attributes for the music table.
    local function makeMusicTable(musicIdx, musicCategory)
        if not testMusicIdx(musicIdx, musicCategory) then
            error("Audio.music" .. "[" .. tostring(musicCategory) .. "]".."[" .. tostring(musicIdx) .. "] does not exist")
        end
        local soundAlias
        if musicCategory == AUDIO_MUSIC_SPECIAL then
            soundAlias = musicSpecialTable[musicIdx]
        elseif musicCategory == AUDIO_MUSIC_OVERWORLD then
            soundAlias = "wmusic" .. tostring(musicIdx)
        elseif musicCategory == AUDIO_MUSIC_LEVEL then
            soundAlias = "music" .. tostring(musicIdx)
        end
        local spriteMT = {
            __index = function(tbl, key)
                if musicCategory == AUDIO_MUSIC_LEVEL then
                    if musicIdx ~= 24 then
                        if (key == "music") then
                            return Audio.__getMusicForAlias(soundAlias, musicCategory)
                        end
                        error("Audio.music" .. "[" .. tostring(musicCategory) .. "]".."[" .. tostring(musicIdx) .. "] does not exist")
                    end
                elseif musicCategory == AUDIO_MUSIC_LEVEL then
                    if musicIdx == 24 then
                        error("Cannot get the custom music ID with this system. Set the custom music ID with Audio.MusicChange instead.")
                    elseif musicCategory == AUDIO_MUSIC_OVERWORLD and musicIdx ~= 17 then
                        if (key == "music") then
                            return Audio.__getMusicForAlias(soundAlias, musicCategory)
                        end
                        error("Audio.music" .. "[" .. tostring(musicCategory) .. "]".."[" .. tostring(musicIdx) .. "] does not exist")
                    end
                else
                    if (key == "music") then
                        return Audio.__getMusicForAlias(soundAlias, musicCategory)
                    end
                    error("Audio.music" .. "[" .. tostring(musicCategory) .. "]".."[" .. tostring(musicIdx) .. "] does not exist")
                end
            end,
            __newindex = function(tbl, key, val)
                if musicCategory == AUDIO_MUSIC_LEVEL then
                    if musicIdx ~= 24 then
                        if (key == "music") then
                            val = val or musicIniData[musicCategory][musicIdx]
                            Audio.__setOverrideForMusicAlias(soundAlias, val)
                            return
                        end
                    elseif musicIdx == 24 then
                        error("Cannot get the custom music ID with this system. Set the custom music ID with Audio.MusicChange instead.")
                    end
                else
                    if (key == "music") then
                        val = val or musicIniData[musicCategory][musicIdx]
                        Audio.__setOverrideForMusicAlias(soundAlias, val)
                        return
                    end
                end
            end
        }
        return setmetatable({}, spriteMT)
    end
    
    local musicMetatableSpecial = {
        __index = function(tbl, val)
            return makeMusicTable(val, AUDIO_MUSIC_SPECIAL)
        end,
        __newindex = function(tbl, key, val)
            error("Cannot write to Audio.music table")
        end
    }
    local musicMetatableOverworld = {
        __index = function(tbl, val)
            return makeMusicTable(val, AUDIO_MUSIC_OVERWORLD)
        end,
        __newindex = function(tbl, key, val)
            error("Cannot write to Audio.music table")
        end
    }
    local musicMetatableLevel = {
        __index = function(tbl, val)
            return makeMusicTable(val, AUDIO_MUSIC_LEVEL)
        end,
        __newindex = function(tbl, key, val)
            error("Cannot write to Audio.music table")
        end
    }
    --Make the tables
    Audio.music = {}
    Audio.music[AUDIO_MUSIC_SPECIAL] = {} --special music
    Audio.music[AUDIO_MUSIC_OVERWORLD] = {} --overworld music
    Audio.music[AUDIO_MUSIC_LEVEL] = {} --level music
    --Finally add the metatables
    setmetatable(Audio.music[AUDIO_MUSIC_SPECIAL], musicMetatableSpecial)
    setmetatable(Audio.music[AUDIO_MUSIC_OVERWORLD], musicMetatableOverworld)
    setmetatable(Audio.music[AUDIO_MUSIC_LEVEL], musicMetatableLevel)
end

---------------
-- Load LPeg --
---------------
do
	local lpegContext = require_utils.makeGlobalContext(_G)
	local requireLPeg = require_utils.makeRequire(
		string_gsub(getSMBXPath(), ";", "<") .. "/scripts/ext/LPegLJ/src/?.lua", -- Path
		lpegContext, -- Global table
		{ffi = ffi}, -- Loaded table
		true, -- Share globals
		true) -- Assign require
		
	local lpeg = requireLPeg("lpeglj")
	package.loaded['lpeg'] = lpeg
	package.loaded['lpeglj'] = lpeg
	lowLevelLibraryContext._G.lpeg = lpeg
	_G.lpeg = lpeg
end

-------------------	
-- Load LunaJSON --
-------------------
do
	local lunaJSONContext = require_utils.makeGlobalContext(_G)
	local requireLunaJSON = require_utils.makeRequire(
		string_gsub(getSMBXPath(), ";", "<") .. "/scripts/ext/?.lua", -- Path
		lunaJSONContext, -- Global table
		{},   -- Loaded table
		true, -- Share globals
		true) -- Assign require

	local json = requireLunaJSON("lunajson")
	lowLevelLibraryContext._G.json = json
	_G.json = json
end

-------------------------------
-- Load load level libraries --
-------------------------------

do
	requireLowLevelLibrary("constants")

	requireLowLevelLibrary("type")
	requireLowLevelLibrary("ffi_mem")
	requireLowLevelLibrary("ffi_misc")
	requireLowLevelLibrary("ffi_graphics")
    requireLowLevelLibrary("ffi_legacyrng")

	requireLowLevelLibrary("ffi_player")
	requireLowLevelLibrary("ffi_camera")


	local populateCustomParams -- Function for populating custom parameters
	if (not isOverworld) then
		requireLowLevelLibrary("ffi_npc")
		requireLowLevelLibrary("ffi_bgo")
		requireLowLevelLibrary("ffi_warp")
		requireLowLevelLibrary("ffi_block")
		requireLowLevelLibrary("ffi_liquid")
		requireLowLevelLibrary("ffi_layer")
		requireLowLevelLibrary("ffi_section")
		requireLowLevelLibrary("ffi_level")
		
		populateCustomParams = requireLowLevelLibrary("ffi_customparams")
	end
	
	-- TEMPORARY SECTION SIZE PATCH
	do
		local patch = {0x0F, 0xBF, 0x51, 0x14, 0x8D, 0x0C, 0xFD, 0x00, 0x00, 0x00, 0x00, 0x0F, 0xBF, 0x44, 0x24, 0x1C, 0x0F, 0xAF, 0xC2, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90}
		for k,v in ipairs(patch) do
			mem(0x95796B + (k-1), FIELD_BYTE, v)
		end
	end
end

------------------------------------------------------------------------------
-- Library (API) Functions                                                  --
--                                                                          --
-- This section governs the implementation of loading libraries in LunaLua. --
------------------------------------------------------------------------------

-- Path string for basegame resources
local basegameLunaPath = (
	string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\?.lua;" ..
	string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\base\\?.lua;" ..
	string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\tweaks\\?.lua;" ..
	string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\legacy\\?.lua"
)

local legacyMap

-- Callback for after a library loads (call onInitAPI, and if it's legacy record a warning)
local function loadLibraryCallback(name, filePath, library, environment)
	if type(library["onInitAPI"]) == "function" then
		library.onInitAPI()
	end
	
	if filePath:find("scripts/legacy") ~= nil then
		if legacyMap == nil then
			legacyMap = {}
			local lns = io.readFileLines(getSMBXPath().."\\scripts\\legacy\\replacement_map.ini")
			assert(lns ~= nil, "Error loading legacy map (replacement_map.ini). Install may be corrupted.")
			for _,line in ipairs(lns) do
				local k,v,t = string.match(line, "^%s*([_%a][_%a%w%.]*)%s*:%s*([_%a%w%.]*)%s*:?%s*([^%s]*)%s*$")
				if k then
					legacyMap[k] = {v,t}
				end
			end
		end
		local p = ""
		if legacyMap[name] then
			local t = legacyMap[name][2]
			if t and t ~= "" then
				p = " Use the "..legacyMap[name][1].." "
				if t == "class" then
					p = p.."class"
				else
					p = p.."library"
				end
			else
				p = " Use "..legacyMap[name][1]
			end
			p = p.." instead."
		end
		Misc.warn(name .. " is deprecated."..p, 3)
	end
end

-- Set up basegame context
local basegameContext = require_utils.makeGlobalContext(_G, {API={}})
local basegameRequire, basegamePackage = require_utils.makeRequire(
	basegameLunaPath, -- Path
	basegameContext,  -- Global table
	{ -- Loaded table for silly workarounds
		["jit.profile"]=require("jit.profile"),
		["ext/lunajson"]=json,
		["ext\\lunajson"]=json,
		["require_utils"]=require_utils
	},
	false, -- Share globals
	true,  -- Assign require
	loadLibraryCallback)
	
basegameContext.API.load = basegameRequire
basegameContext.API.isLoadingShared = function() return true end
basegameContext.API.addHandler = EventManager.addAPIListener
basegameContext.API.remHandler = EventManager.removeAPIListener
basegameContext._G.loadAPI = basegameRequire
basegameContext._G.loadSharedAPI = basegameRequire


local debugstats = basegameRequire("base\\engine\\debugstats")

-- Give low level libraries access to the basegame API namespace and EventManager
lowLevelLibraryContext._G.EventManager = EventManager
lowLevelLibraryContext._G.API = basegameContext.API

-- Set up custom (episode/level) context
local customContext = require_utils.makeGlobalContext(basegameContext, {API={}})
local customRequire, customPackage = require_utils.makeRequire(
	"",             -- Path (initially unset! This gets set later!)
	customContext,  -- Global table
	{},    -- Loaded table
	true,  -- Share globals
	true,  -- Assign require
	loadLibraryCallback,
	basegameRequire,
	nil,
	debugstats.addlib)

customContext.API.load = customRequire
customContext.API.isLoadingShared = function() return true end
customContext.API.addHandler = EventManager.addAPIListener
customContext.API.remHandler = EventManager.removeAPIListener
customContext._G.loadAPI = customRequire
customContext._G.loadSharedAPI = customRequire

-- Make defult env to get the custom context
lockdown.defaultLoadEnv = customContext

-- Function for getting environment
function Misc.getCustomEnvironment()
	return customContext
end

function Misc.getBasegameEnvironment()
	return basegameContext
end

-- Make this globally accessible (is this really needed?)
basegameContext._G.EventManager = EventManager

-- isAPILoaded implementation, based on checking the loaded table
do
	local string_lower = string.lower

	local function basegameIsAPILoaded(api)
		return (basegamePackage.loaded[string_lower(api)] ~= nil)
	end
	basegameContext._G.isAPILoaded = basegameIsAPILoaded
	basegameContext.API.isLoaded = basegameIsAPILoaded
	
	local function customIsAPILoaded(api)
		return (customPackage.loaded[string_lower(api)] ~= nil) or (basegamePackage.loaded[string_lower(api)] ~= nil)
	end
	customContext._G.isAPILoaded = customIsAPILoaded
	customContext.API.isLoaded = customIsAPILoaded
end

-- Register custom event system
function basegameContext._G.registerCustomEvent(obj, eventName)
	local queue = {}
	local mt = getmetatable(obj)
	if(mt == nil) then
		mt = {__index = function(tbl, key) return rawget(tbl, key) end, __newindex = function(tbl, key, val) rawset(tbl, key, val) end}
	end
	local index_f = mt.__index
	local newindex_f = mt.__newindex
	
	mt.__index = function(tbl, key)
		if(key == eventName) then
			return function(...)
				for _, v in ipairs(queue) do
					v(...)
				end
			end
		else
			return index_f(tbl, key)
		end
	end
	
	mt.__newindex = function (tbl, key, val)
		if(key == eventName) then
			table.insert(queue, val)
		else
			newindex_f(tbl, key, val)
		end
	end
	
	setmetatable(obj, mt)
end


------------------------
-- Sounds.ini Parsing --
------------------------

local loadSoundsIni
do
	local tableinsert = table.insert
	local iniparse = basegameRequire("configFileReader")
	function parseSoundsIni(path)
		local data = {}
		local headers = {}
		local index = nil
		local folderpath = path
		path = path.."sounds.ini"
		
		local check=io.open(path, "r")      
	  
		if check == nil then
			return
		else
			check:close()
		end
		
		local inilines = io.readFileLines(path)
		assert(inilines ~= nil, "Error loading sounds.ini")
		for _,v in ipairs(inilines) do
			if v ~= nil then
				local header = v:match("^%s*%[%s*(%S+)%s*%]%s*$")
				if header then
					if data[header] == nil then
						data[header] = {}
						tableinsert(headers, header)
					end
					index = header
				elseif index ~= nil and data[index] ~= nil then
					tableinsert(data[index], v)
				end
			end
		end
		
		local maxId = 0
		for _,h in ipairs(headers) do
			local id = h:lower():match("sound%s*%-%s*(%d+)")
			
			if id ~= nil then
				id = tonumber(id)
				if id ~= nil and testSoundIdx(id) then
					local l = iniparse.dataParse(data[h], enums, allowranges)
					if l.file[1] == "/" or l.file[1] == "\\" then
						l.file = l.file:sub(2,-1)
					end
					local file = Misc.resolveSoundFile(l.file)
					if file then
						soundIniData[id] = file
						maxId = math.max(id, maxId)
					else
						Misc.warn("Could not load sound from sounds.ini: "..l.file)
					end
				else
					Misc.warn("Invalid sound ID "..id.." found in sounds.ini")
				end
			end
		end
		soundIniCount = math.max(soundIniCount, maxId)
	end
	function loadSoundsIni()
		parseSoundsIni(getSMBXPath().."/")
			
		local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD);
		local epidx = mem(0x00B2C628, FIELD_WORD) - 1;
		
		if epidx >= 0 then
			local eppath = tostring(mem(EP_LIST_PTR + (epidx * 0x18) + 0x4, FIELD_STRING))
			parseSoundsIni(eppath)
		
			if not isOverworld then
				local f = Level.filename()
				local i = f:match(".*%.()")
				if i ~= nil then
					parseSoundsIni(eppath..f:sub(1,(i-2)).."/")
				end
			end
		end
		
		--Makes SFX a drop-in replace
		for k = 1,soundIniCount do
			local v = soundIniData[k]
			if v then
				if pcall(function() soundIniData[k] = Audio.SfxOpen(v) end) then
					local d = Audio.sounds[k]
					d.sfx = soundIniData[k]
				else
					Misc.warn("Could not load sound from sounds.ini: "..v)
				end
			end
		end
	end
end

-----------------------
-- Music.ini Parsing --
-----------------------

local loadMusicIni

do
    local tableinsert = table.insert
    local iniparse = basegameRequire("configFileReader")
    function parseMusicIni(path)
        local data = {}
        local headers = {}
        local index = nil
        local folderpath = path
        path = path.."music.ini"
        
        local check=io.open(path, "r")      
      
        if check == nil then
            return
        else
            check:close()
        end
        
        local maxId = {}
        maxId[1] = 0
        maxId[2] = 0
        maxId[3] = 0
        
        local finalId = {}
        finalId[1] = 0
        finalId[2] = 0
        finalId[3] = 0
        
        local id1
        local id2
        local id3
        
        local inilines = io.readFileLines(path)
        assert(inilines ~= nil, "Error loading music.ini")
        for _,v in ipairs(inilines) do
            if v ~= nil then
                local header = v:match("^%s*%[%s*(%S+)%s*%]%s*$")
                if header then
                    if data[header] == nil then
                        data[header] = {}
                        tableinsert(headers, header)
                    end
                    index = header
                elseif index ~= nil and data[index] ~= nil then
                    tableinsert(data[index], v)
                end
            end
        end
        
        for idxNum,h in ipairs(headers) do
            id1 = h:lower():match("special%s*%-%s*music%s*%-%s*(%d+)")

            --special
            if id1 ~= nil then
                id1 = tonumber(id1)
                if id1 ~= nil and testMusicIdx(id1, AUDIO_MUSIC_SPECIAL) then
                    local l = iniparse.dataParse(data[h], enums, allowranges)
                    if l.file[1] == "/" or l.file[1] == "\\" then
                        l.file = l.file:sub(2,-1)
                    end
                    local file = Misc.resolveMusicFile(l.file)
                    if file then
                        --really dumb fix for special music
                        Audio.__setOverrideForMusicAlias(musicSpecialTable[id1], file)
                        musicIniData[AUDIO_MUSIC_SPECIAL][id1] = file
                        maxId[1] = math.max(id1, maxId[1])
                    else
                        Misc.warn("Could not load special song from music.ini: "..l.file)
                    end
                else
                    Misc.warn("Invalid music ID "..id1.." found in music.ini (Special music)")
                end
            end

            --overworld
            id2 = h:lower():match("world%s*%-%s*music%s*%-%s*(%d+)")
            
            if id2 ~= nil then
                id2 = tonumber(id2)
                if id2 ~= 17 then
                    if testMusicIdx(id2, AUDIO_MUSIC_OVERWORLD) then
                        local l = iniparse.dataParse(data[h], enums, allowranges)
                        if l.file[1] == "/" or l.file[1] == "\\" then
                            l.file = l.file:sub(2,-1)
                        end
                        local file = Misc.resolveMusicFile(l.file)
                        if file then
                            musicIniData[AUDIO_MUSIC_OVERWORLD][id2] = file
                            maxId[2] = math.max(id2, maxId[2])
                        else
                            Misc.warn("Could not load overworld song from music.ini: "..l.file)
                        end
                    else
                        Misc.warn("Invalid music ID "..id2.." found in music.ini (World music)")
                    end
                end
            end

            --level
            id3 = h:lower():match("level%s*%-%s*music%s*%-%s*(%d+)")
            
            if id3 ~= nil then
                id3 = tonumber(id3)
                if id3 ~= 24 then
                    if testMusicIdx(id3, AUDIO_MUSIC_LEVEL) then
                        local l = iniparse.dataParse(data[h], enums, allowranges)
                        if l.file[1] == "/" or l.file[1] == "\\" then
                            l.file = l.file:sub(2,-1)
                        end
                        local file = Misc.resolveMusicFile(l.file)
                        if file then
                            musicIniData[AUDIO_MUSIC_LEVEL][id3] = file
                            maxId[3] = math.max(id3, maxId[3])
                        else
                            Misc.warn("Could not load level song from music.ini: "..l.file)
                        end
                    else
                        Misc.warn("Invalid music ID "..id3.." found in music.ini (Level music)")
                    end
                end
            end
        end
        musicIniCountSpecial = math.max(musicIniCountSpecial, maxId[1])
        musicIniCountOverworld = math.max(musicIniCountOverworld, maxId[2])
        musicIniCountLevel = math.max(musicIniCountLevel, maxId[3])
    end
    function loadMusicIni()
        parseMusicIni(getSMBXPath().."/")
            
        local EP_LIST_PTR = mem(0x00B250FC, FIELD_DWORD);
        local epidx = mem(0x00B2C628, FIELD_WORD) - 1;
        
        if epidx >= 0 then
            local eppath = tostring(mem(EP_LIST_PTR + (epidx * 0x18) + 0x4, FIELD_STRING))
            parseMusicIni(eppath)
        
            if not isOverworld then
                local f = Level.filename()
                local i = f:match(".*%.()")
                if i ~= nil then
                    parseMusicIni(eppath..f:sub(1,(i-2)).."/")
                end
            end
        end
        
        --Makes music a drop-in replace

        --Special
        for k = 1,musicIniCountSpecial do
            local v = musicIniData[AUDIO_MUSIC_SPECIAL][k]
            if v then
                if pcall(function() musicIniData[AUDIO_MUSIC_SPECIAL][k] = Audio.MusicOpen(v) end) then
                    local d = Audio.music[AUDIO_MUSIC_SPECIAL][k]
                    d.sfx = musicIniData[AUDIO_MUSIC_SPECIAL][k]
                else
                    Misc.warn("Could not load special song from music.ini: "..v)
                end
            end
        end
        --Overworld
        for k = 1,musicIniCountOverworld do
            local v = musicIniData[AUDIO_MUSIC_OVERWORLD][k]
            if v then
                if pcall(function() musicIniData[AUDIO_MUSIC_OVERWORLD][k] = Audio.MusicOpen(v) end) then
                    local d = Audio.music[AUDIO_MUSIC_OVERWORLD][k]
                    d.sfx = musicIniData[AUDIO_MUSIC_OVERWORLD][k]
                else
                    Misc.warn("Could not load overworld song from music.ini: "..v)
                end
            end
        end
        --Level
        for k = 1,musicIniCountLevel do
            local v = musicIniData[AUDIO_MUSIC_LEVEL][k]
            if v then
                if pcall(function() musicIniData[AUDIO_MUSIC_LEVEL][k] = Audio.MusicOpen(v) end) then
                    local d = Audio.music[AUDIO_MUSIC_LEVEL][k]
                    d.sfx = musicIniData[AUDIO_MUSIC_LEVEL][k]
                else
                    Misc.warn("Could not load level song from music.ini: "..v)
                end
            end
        end
    end
end


---------------------------------------------------------------------------
-- Main User Code Manager                                                --
--                                                                       --
-- This section of code is responsible for mananging loading non-library --
-- code that are automatically loaded based upon their filename and      --
-- path.                                                                 --
---------------------------------------------------------------------------

local function loadCodeFile(codeFileName, codeFilePath, episodeContext)
	-- Get relative path
	local relPath = require_utils.normalizeRelPath(codeFilePath)

	-- Get environment
	local env
	if (episodeContext) then
		-- Produce a proxy environment for top level shared 
		local handlers = {}
		local eventHandlerFilterMT = {
			__index = function(tbl, key)
				if (Misc.LUNALUA_EVENTS_TBL[key]) then
					return handlers[key]
				end
				
				return customContext[key]
			end,
			__newindex = function(tbl, key, val)
				if (Misc.LUNALUA_EVENTS_TBL[key]) then
					if handlers[key] then
						Misc.warn("Overwritten handler '" .. key .. "' in " .. relPath)
					end
					handlers[key] = val
				else
					customContext[key] = val
				end
			end
		}
		
		env = setmetatable( {} , eventHandlerFilterMT )
	else
		env = require_utils.makeEnvironment(basegameContext)
	end
	
	-- Load file
	local codeString = readFile(codeFilePath)
	if (codeString == nil) then
		-- File not found
		return false
	end
	
	-- 4. Load the code file and add environment
	local codeFile, err = load(codeString, "@" .. relPath, "t", env)
	if codeFile then
		-- 4.1 Execute file for initial run.
		codeFile()
	else
		-- 4.2 Throw error
		Text.windowDebugSimple("Error: " .. err)
		return false
	end
	
	-- 5. Notify usercode file that loading has finished via "onLoad".
	if type(env.onLoad) == "function" then
		env.onLoad()
	end

	-- 6. Now add the code file to the usercode table
	-- UserCodeManager.addCodeFile(codeFileName, env, loadedAPIsTable)
	
	-- 7. Subscript to all events
	EventManager.addUserListener(env)
	
	return true
end

-- ===== FUNCTION USED BY LUNALUA ===== --
-- usage for luabind, always do with event-object

--[[
	The new core uses three functions:
		* __callEvent(...)
			- This function is called when LunaLua grabs a new event. This event is then futher processed and queued if possible.
			  The first argument is always an event object by LunaLua core.
			  The function which process it is called 'EventManager.manageEventObj'.
		* __doEventQueue()
			- This function is called when LunaLua should process the queued events.
			  The function which process it is called 'EventManager.doQueue'.
		* __onInit(episodePath, lvlName)
			- This function is doing the initializing.
 
]]
function __callEvent(...)
	local pcallReturns = {__xpcall(EventManager.manageEventObj, {...})}
	__xpcallCheck(pcallReturns)
end

function __doEventQueue()
	local pcallReturns = {__xpcall(EventManager.doQueue)}
	__xpcallCheck(pcallReturns)
end

--Loadeding function
--This code segment won't post any errors!
function __onInit(episodePath, lvlName)
	local pcallReturns = {__xpcall(function()
		local i = lvlName:match(".*%.()")
		if i ~= nil then
			lvlName = lvlName:sub(1,(i-2))
		end
		local customFolderPath = episodePath .. lvlName .. "\\"
        local rootPath = getSMBXPath()
		
		basegameContext._G.__episodePath = episodePath
		basegameContext._G.__customFolderPath = customFolderPath
        basegameContext._G.__rootPath = rootPath
	
		-- Set path for custom resource loading
		customPackage.path = (
			string_gsub(customFolderPath, ";", "<") .. "?.lua;" ..
			string_gsub(episodePath, ";", "<") .. "?.lua"
		)
	
		--SEGMENT TO ADD GLOBAL PRELOADED APIS START
		basegameContext._G.Defines = basegameRequire("base\\engine\\defines")
		lowLevelLibraryContext._G.Defines = basegameContext._G.Defines
		--Apparently this alias existed during Beta 3, so we'll keep it
		basegameContext._G.defines = basegameContext._G.Defines
		lowLevelLibraryContext._G.defines = basegameContext._G.Defines
		basegameRequire("base\\engine\\uservar")
		basegameContext._G.LunaTime = basegameRequire("base\\engine\\lunatime")
		basegameContext._G.lunatime = basegameContext._G.LunaTime
		lowLevelLibraryContext._G.lunatime = basegameContext._G.LunaTime
		basegameContext._G.RNG = basegameRequire("base\\rng")
		basegameRequire("base\\engine\\debugtools")
		--basegameContext._G.CodeView = basegameRequire("base\\engine\\codeview")
		basegameRequire("base\\engine\\classExpander")
		basegameRequire("base\\engine\\pAnim")
		basegameContext._G.Color = basegameRequire("base\\engine\\color")
		basegameContext._G.vector = basegameRequire("base\\vectr")
		basegameContext._G.Transform = basegameRequire("base\\transform")
		basegameContext._G.Sprite = basegameRequire("base\\sprite")
		basegameContext._G.Colliders = basegameRequire("base\\colliders")
		basegameContext._G.Particles = basegameRequire("base\\particles")
		basegameContext._G.Routine = basegameRequire("base\\routine")
		basegameContext._G.Explosion = basegameRequire("base\\engine\\explosion")
		basegameContext._G.Timer = basegameRequire("base\\timer")
		
		basegameRequire("base/game/savedata")
		
		basegameContext._G.Checkpoint = basegameRequire("base\\checkpoints")
		debugstats.init()
		
		
		-- Copy to Low Level Context where required
		do
			lowLevelLibraryContext._G.Color = basegameContext._G.Color
			lowLevelLibraryContext._G.vector = basegameContext._G.vector
		end
		
		-- Parse and load sounds.ini and music.ini files (this can throw warnings, which is why we need it here)
		loadSoundsIni()
        loadMusicIni()
		
		-- Core libraries
		-- Libraries which provide core functionality, but do not affect the global
		-- Lua environment, nor are meant to be directly interacted with from other
		-- code.
		-- Unlike low level libraries which help set up the Lua environment, these
		-- may call out to other regular libraries.
		do
			-- Set up custom (episode/level) context
			local coreContext = require_utils.makeGlobalContext(basegameContext, {ffi=ffi})
			local coreRequire, corePackage = require_utils.makeRequire(
				string_gsub(getSMBXPath(), ";", "<") .. "/scripts/base/engine/?.lua", -- Path
				coreContext,    -- Global table
				{},    -- Loaded table
				false,  -- Share globals
				true,  -- Assign require
				loadLibraryCallback,
				basegameRequire)
			
			-- Test mode menu
			if mem(0x00B2C62A, FIELD_WORD) == 0 and not isOverworld then
				basegamePackage.loaded["engine/testmodemenu"] = coreRequire("testmodemenu")
			end
			coreRequire("dbg")
			local classicEvents = coreRequire("classicevents")
			EventManager.registerClassicEventHandler(classicEvents.doEvents)
			coreRequire("profiler")
		end

		
		--SEGMENT TO ADD GLOBAL PRELOADED APIS END
        
		-- Load core-npcconfig as shared (not exposed to global namespace by
		-- default, but we want to load anyway)
		basegameRequire("base\\engine\\npcconfig_core")
		basegameRequire("base\\engine\\blockconfig_core")
		
		local noFileLoaded = true
		if(loadCodeFile("lunabase", string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\base\\game\\lunabase.lua", false)) then noFileLoaded = false end
		if not isOverworld then
			-- Modern
			if(loadCodeFile("luna-episode", episodePath .. "luna.lua", true)) then 
				noFileLoaded = false 
				debugstats.add("luna")
			end
			if(loadCodeFile("luna-level", customFolderPath .. "luna.lua", true)) then
				noFileLoaded = false 
				debugstats.add(lvlName.."/luna")
			end
			-- Deprecated
			if(loadCodeFile("lunadll", customFolderPath .. "lunadll.lua", true)) then 
				noFileLoaded = false 
				debugstats.add(lvlName.."/lunadll")
			end
			if(loadCodeFile("lunaworld", episodePath .. "lunaworld.lua", true)) then 
				noFileLoaded = false 
				debugstats.add("lunaworld")
			end
		else
			-- Modern
			if(loadCodeFile("luna-map", episodePath .. "map.lua", true)) then 
				noFileLoaded = false 
				debugstats.add("map")
			end
			-- Deprecated
			if(loadCodeFile("lunaoverworld", episodePath .. "lunaoverworld.lua", true)) then 
				noFileLoaded = false 
				debugstats.add("lunaoverworld")
			end
		end
		
		if noFileLoaded then
			__isLuaError = true
			return
		end
	end)}
	__xpcallCheck(pcallReturns)
end

--[[do
    customPackage.loaded["socket.ftp"] = require("socket.ftp")
    customPackage.loaded["socket.smtp"] = require("socket.smtp")
    customPackage.loaded["socket.url"] = require("socket.url")

    socket.sourcet = {}
    socket.sinkt = {}

    customPackage.loaded["socket.http"] = require("socket.http")
    customPackage.loaded["ltn12"] = require("ltn12")
end]]