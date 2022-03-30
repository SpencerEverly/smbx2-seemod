local serializer = require("ext/serializer")

local savedata = {}

local savedataProxy = {}
local gamedataProxy = {}

--Saveable data
local data_save = {}

--Volatile data
local data_game = {}

-- Management for volatile data
local SetRawGameData = Misc.SetRawGameData
local GetRawGameData = Misc.GetRawGameData
Misc.SetRawGameData = nil
Misc.GetRawGameData = nil

_G.SaveData = savedataProxy
_G.GameData = gamedataProxy

local EPISODEPATH = Misc.episodePath():gsub([[[\/]+]], [[/]])
local SMBXPATH = (Native.getSMBXPath() .. "/"):gsub([[[\/]+]], [[/]])
local noGoodEpisodeFolder = (EPISODEPATH == SMBXPATH)

local function write(filename, data)
	if noGoodEpisodeFolder then return end
	local f = io.open(EPISODEPATH..filename, "w")
	if f then
		local dat = serializer.serialize(data)
		f:write(dat)
		f:flush()
		f:close()
	end
end

local function tryDeserialize(content, filename)
	if content ~= "" then
		local s,e = pcall(serializer.deserialize, content, filename)
		if s then
			return e
		else
			pcall(Misc.dialog, "Error loading save data. Your save file may be corrupted. Please seek assistance in repairing your save data, or start a new game.\n\n=============\n"..e)
		end
	end
	
	return {}
end

local function read(filename)
	if noGoodEpisodeFolder then return {} end
	
	local f = io.open(EPISODEPATH..filename, "r")
	if f then
		local content = f:read("*all")
		f:close()
		return tryDeserialize(content, filename)
	end
	
	return {}
end

local function flush()
	if noGoodEpisodeFolder then return end
	
	if not Defines.player_hasCheated then
		write("save"..mem(0x00B2C62A, FIELD_WORD).."-ext.dat",data_save)
	end
end

local function clear()
	data_save = {}
end

local function clearGame()
	data_game = {}
end

local function flushTemp()
	if noGoodEpisodeFolder then return end
	
	data_game.__TEMP_SAVE_DATA = data_save
	SetRawGameData(serializer.serialize(data_game))
end

local function loadTemp()
	if noGoodEpisodeFolder then return end
	
	data_game = tryDeserialize(GetRawGameData())
end

local function loadData()
	if noGoodEpisodeFolder then return end
	
	loadTemp()
	if data_game.__TEMP_SAVE_DATA == nil then
		data_save = read("save"..mem(0x00B2C62A, FIELD_WORD).."-ext.dat")
	else
		data_save = data_game.__TEMP_SAVE_DATA
		data_game.__TEMP_SAVE_DATA = nil
	end
end

loadData()

function savedata.onInitAPI()
	registerEvent(savedata, "onExit", "onExit", false)
	registerEvent(savedata, "onSaveGame", "onSaveGame", false)
end

local lives = 0
local pauseMenuIndex = 0

function savedata.onSaveGame()
	flush()
end

function savedata.onExit()
	flushTemp()
end

local function iiterate(tbl)
	return  function(t,b)
				return ipairs(tbl)
			end
end

local function iterate(tbl)
	return  function(t)
				return next, tbl, nil
			end
end

local savedata_mt = {}
function savedata_mt.__index(tbl, key)
	if key == "flush" then
		return flush
	elseif key == "clear" then
		return clear
	else
		return data_save[key]
	end
end

function savedata_mt.__newindex(tbl, key, val)
	if key == "flush" or key == "clear" then
		error("Cannot overwrite built-in function "..key.." in SaveData",2)
	else
		data_save[key] = val
	end
end
	
savedata_mt.__ipairs = iiterate(data_save)
savedata_mt.__pairs = iterate(data_save)

setmetatable(savedataProxy, savedata_mt)



local gamedata_mt = {}
function gamedata_mt.__index(tbl, key)
	if key == "clear" then
		return clearGame
	else
		return data_game[key]
	end
end

function gamedata_mt.__newindex(tbl, key, val)
	if key == "clear" then
		error("Cannot overwrite built-in function "..key.." in GameData",2)
	else
		data_game[key] = val
	end
end

gamedata_mt.__ipairs = iiterate(data_game)
gamedata_mt.__pairs = iterate(data_game)

setmetatable(gamedataProxy, gamedata_mt)

return savedata;