local starcoin = {}

local starcoinAI = require("npcs/ai/starcoin")
local npcutils = require("npcs/npcutils")
local npcManager = require("npcManager")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 46,
	gfxheight = 46,
	width = 46,
	height = 46,
	frames = 8,
	framespeed = 8,
	framestyle = 0,
	nohurt = true,
	score = 8,
	nofireball = true,
	noiceball = true,
	noyoshi = false,
	nohurt = true,
	isinteractable = true,
	noblockcollision=true,
	nogravity = true,
	harmlessgrab = true,
	notcointransformable = true,
	luahandlesspeed = true,

	nospecialanimation = false,
	collectedframes = -1
})
npcManager.registerHarmTypes(npcID, {}, {})


local UNCOLLECTED = 0
local SAVED = 1
local COLLECTED = 2
local COLLECTED_WEAK = 3

function starcoin.onStartNPC(coin)
	if coin.ai2 == nil then coin.ai2 = UNCOLLECTED end
	starcoinAI.registerAlive(coin.ai2)
end

--This is called from here to ensure it runs AFTER onStartNPC
function starcoin.onStart()
	starcoinAI.init()
end

function starcoin.onDrawNPC(coin)
	local CoinData = starcoinAI.getTemporaryData()
	if coin.ai2 == nil then coin.ai2 = UNCOLLECTED end
	if CoinData[coin.ai2] == nil then
		CoinData[coin.ai2] = UNCOLLECTED
	end
	starcoinAI.registerAlive(coin.ai2)

	if not config.nospecialanimation then
		local collectedframes = config.collectedframes
		if collectedframes == -1 then collectedframes = math.ceil(config.frames*0.5) end
		local frames = config.frames - collectedframes
		local offset = 0
		local gap = collectedframes
		if CoinData[coin.ai2] and CoinData[coin.ai2] > UNCOLLECTED then
			frames = collectedframes
			offset = config.frames - collectedframes
			gap = 0
		end
			--npcutils.restoreAnimation(coin)
			coin.animationFrame = npcutils.getFrameByFramestyle(coin, { frames = frames, offset = offset, gap = gap })
	end
end

function starcoin.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	v.speedX, v.speedY = npcutils.getLayerSpeed(v)
end

function starcoin.onNPCKill(obj, n, r)
	if n.id == npcID and r == 9 then
		if (npcManager.collected(n, r) or n:mem(0x138, FIELD_WORD) == 5) then
			starcoinAI.collect(n)
		end
	end
end

function starcoin.onInitAPI()
	npcManager.registerEvent(npcID, starcoin, "onStartNPC")
	npcManager.registerEvent(npcID, starcoin, "onDrawNPC")
	npcManager.registerEvent(npcID, starcoin, "onTickEndNPC")
	registerEvent(starcoin, "onNPCKill", "onNPCKill")
	registerEvent(starcoin, "onStart", "onStart", false)
end

return starcoin
