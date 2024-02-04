do
	-- Blank namespaces
	_G.Graphics = {}
	_G.Text = {}
	_G.Misc = {}
	
	-- Implement getSMBXPath
	local smbxPath = _smbxPath
	local episodePath = _episodePath
	_G.Native = {}
	function Native.getSMBXPath()
		return smbxPath
	end
	function Native.getEpisodePath()
		return episodePath
	end
	_G.getSMBXPath = Native.getSMBXPath
end

local lockdown = dofile(getSMBXPath() .. "/scripts/base/engine/lockdown.lua")

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

-- Keep access to FFI local to here
local ffi = require("ffi")
local string_gsub = string.gsub

-- Function to load low level libraries that require access to FFI
lowLevelLibraryContext = require_utils.makeGlobalContext(_G, {ffi=ffi, _G=_G})
local requireLowLevelLibrary = require_utils.makeRequire(
	string_gsub(getSMBXPath(), ";", "<") .. "/scripts/base/engine/?.lua", -- Path
	lowLevelLibraryContext, -- Global table
	{},    -- Loaded table
	false, -- Share globals
	true)  -- Assign require
package.preload['ffi'] = nil
package.loaded['ffi'] = nil

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

do
	requireLowLevelLibrary("type")
	requireLowLevelLibrary("ffi_mem")
	requireLowLevelLibrary("ffi_utils")
	requireLowLevelLibrary("ffi_graphics")
	requireLowLevelLibrary("ffi_misc")
end

-- Function for setting load screen timeout
function Misc.setLoadScreenTimeout(t)
	_G._loadScreenTimeout = t
end

-- Function for getting if the load screen is done loading
function Misc.getLoadingFinished()
	return _G._loadingFinished
end

-- Utility code to generate a normalized relative path
-- TODO: Move to common file
local normalizeRelPath
do
	local string_gsub = string.gsub
	local string_sub = string.sub
	local string_len = string.len
	local string_lower = string.lower
	local string_byte = string.byte
	local _getSMBXPath = getSMBXPath
	function normalizeRelPath(path, relBase)
		if (relBase == nil) then
			relBase = _getSMBXPath()
		end
		path = string_gsub(path, [[[\/]+]], [[/]])
		relBase = string_gsub(relBase, [[[\/]+]], [[/]])
		local relBaseLen = string_len(relBase)
		if (string_byte(relBase, relBaseLen) ~= string_byte([[/]], 1)) then
			relBase = relBase .. [[/]]
			relBaseLen = relBaseLen + 1
		end
		local pathStart = string_sub(path, 1, relBaseLen)
		if (string_lower(pathStart) == string_lower(relBase)) then
			path = string_sub(path, relBaseLen + 1)
		end
		return path
	end
end

local function initDefaultLoadScreen(showSplash)
	local cnt = 0
	local loaderDelay = 12
	local fadeTime = 42
	local animSpd = 8
	
	_G.onDraw = function()
		if (showSplash) then
			Graphics.drawImage(Graphics.sprites.hardcoded["30-4"].img, 0, 0)
		end
		if(cnt > loaderDelay) then
			local f = math.floor(((cnt - loaderDelay) / animSpd)) % 7
			local t1,t2 = f / 7, (f+1) / 7
			local alpha = math.min(1.0, (cnt - loaderDelay) / fadeTime)
			
			local img = Graphics.sprites.hardcoded["30-5"].img
			local imgw = img.width
			local imgh = img.height/7
			
			Graphics.glDraw{vertexCoords={800-imgw,600-imgh,800,600-imgh,800-imgw,600,800,600}, texture=img, textureCoords={0,t1,1,t1,0,t2,1,t2},
				primitive=Graphics.GL_TRIANGLE_STRIP, color={1.0, 1.0, 1.0, alpha}}
		end
		cnt = cnt + 1
	end
end

function init()
	Graphics.sprites.Register("hardcoded", "hardcoded-30-5")
	
	local episodeScriptPath = string_gsub(mem(0x00B2C61C, FIELD_STRING), ";", "<") .. "?.lua"
	
	local customContext = require_utils.makeGlobalContext(_G, {})
	local customRequire, customPackage = require_utils.makeRequire(
		episodeScriptPath, -- Path
		customContext,  -- Global table
		{},    -- Loaded table
		true,  -- Share globals
		true)  -- Assign require
	
	if pcall(function() customRequire("loadscreen") end) then
		_G.onDraw = function()
			local episodeScriptOnDraw = customContext.onDraw
			if (episodeScriptOnDraw ~= nil) then
				episodeScriptOnDraw()
			end
		end
	else
		-- TODO: Is there a nice way to only show the splash screen initially? When launching into
		--       a level this will be called twice. For the heck of it I'm leaving this just always
		--       true for right this moment --A quick moment, indeed ~Emral
		initDefaultLoadScreen(false)
	end
end
