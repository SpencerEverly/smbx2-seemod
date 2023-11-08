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

function Misc.gameOverComplete()
    _gameoverComplete = true
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

local t = 0

local function initDefaultGameOver()
    _G.onDraw = function()
        t = t + 1
        
        Text.print("GAME OVER", (Graphics.getFramebufferSize()[1] / 2) - 90, (Graphics.getFramebufferSize()[2] / 2) - 20)
        
        if t >= 256 then
            Misc.gameOverComplete()
        end
    end
end

function init()
	--Graphics.sprites.Register("hardcoded", "hardcoded-30-5")
	
	local episodeScriptPath = string_gsub(mem(0x00B2C61C, FIELD_STRING), ";", "<") .. "?.lua"
	
	local customContext = require_utils.makeGlobalContext(_G, {})
	local customRequire, customPackage = require_utils.makeRequire(
		episodeScriptPath, -- Path
		customContext,  -- Global table
		{},    -- Loaded table
		true,  -- Share globals
		true)  -- Assign require
	
	if pcall(function() customRequire("gameover") end) then
		_G.onDraw = function()
			local episodeScriptOnDraw = customContext.onDraw
			if (episodeScriptOnDraw ~= nil) then
				episodeScriptOnDraw()
			end
		end
	else
        initDefaultGameOver()
	end
end