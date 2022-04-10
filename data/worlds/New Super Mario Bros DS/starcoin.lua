--[[
  Cases:
  (I still havent checked to see if the "X" work)
  [Y]FRIENDLY
  [Y]YOSHI
  [x]HIDDEN LAYER
  [X]GENERATOR
  [X]CONTAINERS

  Documentation:
    starcoin:
      id [310] The npc-id of the starcoin
    starcoinNPC.coin.ai2
      index in savedata
    SaveData._basegame.starcoin:
      0: Not collected
      1: Collected and saved with level exit
      2: Collected and saved with checkpoint
	  3: Collected and not saved
	SaveData._basegame.starcoinCounter
]]

local starcoin = {}

local LevelName = Level.filename()
local iconPos = {}

if not SaveData._basegame.starcoin[LevelName] then
  SaveData._basegame.starcoin[LevelName] = {}
end

local UNCOLLECTED = 0
local SAVED = 1
local COLLECTED = 2
local COLLECTED_WEAK = 3

SaveData._basegame.starcoinCounter = SaveData._basegame.starcoinCounter or 0

local CoinData = SaveData._basegame.starcoin[LevelName]

function starcoin.getTemporaryData()
    return CoinData
end

starcoin.sfx_collect = Misc.resolveSoundFile("starcoin-collect")
starcoin.sfx_collectall = Misc.resolveSoundFile("starcoin-collectall")

local checkpoints = require("checkpoints")
local npcManager = require("npcManager")
local HUDOverride = require("HUDOverride")

CoinData.alive = {}
CoinData.maxID = CoinData.maxID or 0

local function validCoin(t, i)
	return t[i] and (not t.alive or t.alive[i])
end

function starcoin.count(name)
	name = name or LevelName
	local t = SaveData._basegame.starcoin[name]
	if not t then return 0 end
	local c = 0
	for i = 1, t.maxID do
		if validCoin(t,i) then
			c = c+1
		end
	end
	return c
end

function starcoin.max()
	return CoinData.maxID
end

function starcoin.getLevelList(name)
	name = name or LevelName
	return SaveData._basegame.starcoin[name]
end

function starcoin.getEpisodeList()
	return SaveData._basegame.starcoin
end

function starcoin.getLevelCollected(name)
	local list = starcoin.getLevelList(name)
	local LtotalNum = 0
	for i = 1,list.maxID do
		if validCoin(list,i) and list[i] ~= 0 then
			LtotalNum = LtotalNum + 1
		end
	end
	return LtotalNum
end

function starcoin.getEpisodeCollected()
	local GtotalNum = 0
	for k in pairs(SaveData._basegame.starcoin) do
		GtotalNum = GtotalNum + starcoin.getLevelCollected(k)
	end
	return GtotalNum
end

function starcoin.registerAlive(id)
	CoinData.alive[id] = true
	if id > CoinData.maxID then
		CoinData.maxID = id
	end
end

--Called from npc-310 to make sure it runs at the right time
function starcoin.init()
	-- Reset states
	local activeCheckpoint = checkpoints.getActive()
	for i = 1,CoinData.maxID do
		if (CoinData[i] == COLLECTED and not activeCheckpoint) or CoinData[i] == COLLECTED_WEAK then
			CoinData[i] = 0
		end
	end
end

function starcoin.collect(coin)
  local coinEffect
  if CoinData[coin.ai2] and CoinData[coin.ai2] > UNCOLLECTED then
    coinEffect = Effect.spawn(233, coin.x + coin.width*0.5, coin.y + coin.height*0.5)
  else
    coinEffect = Effect.spawn(276, coin.x + coin.width*0.5, coin.y + coin.height*0.5)
  end
  coinEffect.x = coinEffect.x - coinEffect.width/2
  coinEffect.y = coinEffect.y - coinEffect.height/2

	if CoinData[coin.ai2] == UNCOLLECTED and starcoin.getLevelCollected() + 1 >= starcoin.count() then
		SFX.play(starcoin.sfx_collectall)
	else
		SFX.play(starcoin.sfx_collect)
	end

	if coin.ai2 > UNCOLLECTED then
		if CoinData[coin.ai2] == UNCOLLECTED then
			CoinData[coin.ai2] = COLLECTED_WEAK
		end
		local HO = HUDOverride.offsets.starcoins
		local currRow = math.floor((coin.ai2 - 1)/HO.grid.width)
		if currRow < HO.grid.offset or currRow > HO.grid.offset + HO.grid.height - 1 then
			HO.grid.offset = currRow
		end
	end

	--mem(0x00B2C8E4, FIELD_DWORD, mem(0x00B2C8E4, FIELD_DWORD) + 4000)

	--local pointEffect = Effect.spawn(79, coin.x + coin.width/2, coin.y, 8)
	--pointEffect.x = pointEffect.x - pointEffect.width/2
	--pointEffect.animationFrame = 7
	Misc.givePoints(NPC.config[coin.id].score, coin, true)
end

function starcoin.reset(name)
  local list = starcoin.getLevelList(name)
  for i = 1, list.maxID do
    list[i] = UNCOLLECTED
  end
end

function starcoin.onCheckpoint()
	for i = 1,CoinData.maxID do
		if CoinData[i] == COLLECTED_WEAK then
			CoinData[i] = COLLECTED
		end
	end
end

function starcoin.onExitLevel(win)
	if win > 0 then
		for i = 1,CoinData.maxID do
			if CoinData[i] and CoinData[i] >= COLLECTED then
				CoinData[i] = SAVED
				SaveData._basegame.starcoinCounter = SaveData._basegame.starcoinCounter + 1
			end
		end
	end
end

function starcoin.onInitAPI()
	registerEvent(starcoin, "onStart", "onStart", false)
	registerEvent(starcoin, "onCheckpoint", "onCheckpoint")
	registerEvent(starcoin, "onExitLevel", "onExitLevel")
end

return starcoin
