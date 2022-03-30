local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local ninjaman = {}
local npcID = NPC_ID

local regularSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 32,
	gfxwidth = 32,
	width = 24,
	height = 24,
	frames = 2,
	framespeed=8,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 0,

	bounces=4,
	bounce1=4.5,
	bounce2=4.5,
	bounce3=6.5,
	bounce4=8.5,
	startbounce = 3,
	wait=65,
}


npcManager.registerHarmTypes(npcID, 	
{
	HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_TAIL,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_SWORD,
	HARM_TYPE_LAVA
}, 
{
	[HARM_TYPE_JUMP]={id=197, speedX=0, speedY=0},
	[HARM_TYPE_FROMBELOW]=197,
	[HARM_TYPE_NPC]=197,
	[HARM_TYPE_HELD]=197,
	[HARM_TYPE_TAIL]=197,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});


npcManager.setNpcSettings(regularSettings)

function ninjaman.onInitAPI()
	npcManager.registerEvent(npcID, ninjaman, "onTickNPC")
	npcManager.registerEvent(npcID, ninjaman, "onDrawNPC")
end

function ninjaman.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	v.animationTimer = 500
	v.animationFrame = 0
	if v.speedY < 0 then
		v.animationFrame = 1
	end
	if v.direction == 1 then v.animationFrame = v.animationFrame + 2 end
end

local function parseJumpHeight(v, cfg)
	local tbl = {}
	for i=1, cfg.bounces do
		if cfg["bounce" .. i] == nil then
			table.insert(tbl, 0)
		else
			table.insert(tbl, math.abs(cfg["bounce" .. i]))
		end
	end
	return tbl
end

function ninjaman.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138,FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 then
		data.jumpTimer = nil
		return
	end

	local cfg = NPC.config[v.id]
	
	if data.jumpTimer == nil then
		data.jumpHeight = parseJumpHeight(v, cfg)
		data.currentHeight = math.clamp(cfg.startbounce, 1, #data.jumpHeight)
		data.jumpTimer = cfg.wait
	end
	
	if v.collidesBlockBottom then
		data.jumpTimer = data.jumpTimer + 1
		
		v.speedX = utils.getLayerSpeed(v)
	end
	
	if data.jumpTimer > cfg.wait then
		data.jumpTimer = 0
		v.speedY = -data.jumpHeight[data.currentHeight]
		data.currentHeight = data.currentHeight%(#data.jumpHeight) + 1
	end
end
	
return ninjaman