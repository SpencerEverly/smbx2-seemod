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
		string_gsub(getSMBXPath(), ";", "<") .. "/scripts/ext/lpeglj/src/?.lua", -- Path
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




_G._enableCoinSpin = true
_G._enableLoadingText = true

_G._bootScreenComplete = false
function Misc.setBootScreenCompleted()
	_G._bootScreenComplete = true
end

function Misc.episodeBootImage()
    return _episodeBootImage
end

function Misc.episodeBootDelaySetting()
    return _episodeDelaySetting
end

function Misc.episodeBootUsingCustomSplash()
    return _useCustomSplash
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
			relBase = _getSMBXPath
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

local bootImage
local coinImage
local loadingImage

local function calculateCameraDimensions(value, isWidthOrHeight)
    if value == nil then
        error("Must have a value")
        return
    else
        if isWidthOrHeight == nil then
            error("Must have a width or height. You must use a string value for this (Or a number), like e.g. \"width\" or \"height\", or 1 or 2.")
            return
        end
        local originalWidth = 800
        local originalHeight = 600
        
        local frameSizeWidth, frameSizeHeight = Graphics.getMainFramebufferSize()
        
        local additionalWidth = frameSizeWidth - originalWidth
        local additionalHeight = frameSizeHeight - originalHeight
        
        local extendedWidth = additionalWidth / 2
        local extendedHeight = additionalHeight / 2
        
        if (isWidthOrHeight == "width" or isWidthOrHeight == 1) then
            return value + extendedWidth
        elseif (isWidthOrHeight == "height" or isWidthOrHeight == 2) then
            return value + extendedHeight
        else
            error("This is not a valid value for isWidthOrHeight. You must use a string value for this (Or a number), like e.g. \"width\" or \"height\", or 1 or 2.")
            return
        end
    end
end

local function initDefaultBootScreen()
    local bootScreenDefaultTime = 200
    local bootScreenDelayTime = Misc.episodeBootDelaySetting()
    local bootScreenTotalTime = bootScreenDefaultTime + bootScreenDelayTime
    
    local opacity = 0
    local fadeInTimer = 40
    local fadeInIncrease = 1 / fadeInTimer

    local LoadCoins = 0
    local LoadCoinT = 0

	_G.onDraw = function()
        bootScreenTotalTime = bootScreenTotalTime - 1

        if opacity < 1 then
            opacity = opacity + fadeInIncrease
        end

        --Fade in
        local frameSizeWidth, frameSizeHeight = Graphics.getMainFramebufferSize()
        Graphics.drawBox{
            x = 0,
            y = 0,
            width = frameSizeWidth,
            height = frameSizeHeight,
            color = {
                [1] = 1,
                [2] = 1,
                [3] = 1,
                [4] = opacity,
            },
        }
        
        --Black overlay
        Graphics.drawBox{
            x = 0,
            y = 0,
            width = frameSizeWidth,
            height = frameSizeHeight,
            color = {
                [1] = 1,
                [2] = 1,
                [3] = 1,
            },
        }

        --Boot image
        Graphics.drawImage(bootImage, calculateCameraDimensions(0, 1), calculateCameraDimensions(0, 2))

        --Coin animation
        LoadCoinT = LoadCoinT + 0.1
        if LoadCoinT > 1 then
            LoadCoins = LoadCoins + 1
        end
        if LoadCoins > 3 then
            LoadCoins = 0
        end
        
        Text.print(tostring(LoadCoins), 100, 100)

        --Coin spin
        if _enableCoinSpin then
            Graphics.drawImage(coinImage, calculateCameraDimensions(560, 1), calculateCameraDimensions(760, 2), 0, 32 * LoadCoins, coinImage.width, coinImage.height / 4)
        end

        --Loading text
        if _enableLoadingText then
            Graphics.drawImage(loadingImage, calculateCameraDimensions(576, 1), calculateCameraDimensions(632, 2), 0, 0, loadingImage.width, loadingImage.height)
        end

        --When it's complete, this is set
        if bootScreenTotalTime <= 0 then
            Misc.setBootScreenCompleted()
        end
	end
end

function init()
    local customImageCheck = Native.getEpisodePath()..Misc.episodeBootImage()
    if (customImageCheck ~= Native.getEpisodePath()) and Misc.episodeBootImage() and (Misc.episodeBootImage() ~= "" or Misc.episodeBootImage() ~= " ") then
        bootImage = Graphics.loadImage(Native.getEpisodePath()..Misc.episodeBootImage())
    else
        bootImage = Graphics.loadImage(getSMBXPath().."\\graphics\\hardcoded\\hardcoded-30-4.png")
    end
    
    coinImage = Graphics.loadImage(getSMBXPath().."\\graphics\\hardcoded\\hardcoded-9.png")
    loadingImage = Graphics.loadImage(getSMBXPath().."\\graphics\\hardcoded\\hardcoded-8.png")
    
    local episodeScriptPath = string_gsub(Native.getEpisodePath(), ";", "<") .. "?.lua"
	
	local customContext = require_utils.makeGlobalContext(_G, {})
	local customRequire, customPackage = require_utils.makeRequire(
		episodeScriptPath, -- Path
		customContext,  -- Global table
		{},    -- Loaded table
		true,  -- Share globals
		true)  -- Assign require
	
	if pcall(function() customRequire("bootscreen") end) then
		_G.onDraw = function()
			local episodeScriptOnDraw = customContext.onDraw
			if (episodeScriptOnDraw ~= nil) then
				episodeScriptOnDraw()
			end
		end
	else
        initDefaultBootScreen()
    end
end
