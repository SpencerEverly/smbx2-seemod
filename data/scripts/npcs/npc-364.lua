local npcManager = require("npcManager")
local rng = require("rng")
local colliders = require("colliders")
local whistle = require("npcs/ai/whistle")
local utils = require("npcs/npcutils")

local turnblock = {}

local npcID = NPC_ID

npcManager.setNpcSettings{
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	jumphurt = true,
	nogravity = true,
	noblockcollision = false,
	npcblocktop = true,
	npcblock = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	spinjumpsafe = true,
	notcointransformable = true,
	
	defaultcontent = 0,
	triggerwidth = 320,
	triggerheight = 500
}

function turnblock.onInitAPI()
	npcManager.registerEvent(npcID, turnblock, "onTickEndNPC")
end

function turnblock.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) ~= 0 then
		return
	end

	if data.spawned and data.spawned.isValid then
		v:mem(0x12A, FIELD_WORD, 0)
		v:mem(0x124, FIELD_WORD, 0)
		return
	else
		data.spawned = nil
	end
	
	if v.ai1 == 0 and v.ai1 ~= NPC.config[v.id].defaultcontent then
		v.ai1 = NPC.config[v.id].defaultcontent
	end
	
	if data.width == nil then
		data.width = NPC.config[v.id].triggerwidth
	end
	if data.height == nil then
		data.height = NPC.config[v.id].triggerheight
	end

	if data.blockCol == nil then
		data.blockCol = colliders.Box(v.x + 0.5 * v.width - 0.5 * data.width, v.y + 0.5 * v.height - 0.5 * data.height, data.width, data.height)
	end
	data.blockCol.x = v.x + 0.5 * v.width - 0.5 * data.width
	data.blockCol.y = v.y + 0.5 * v.height - 0.5 * data.height

	v.speedX,v.speedY = utils.getLayerSpeed(v)
	for k,p in ipairs(Player.get()) do
		if v:mem(0x146, FIELD_WORD) == p.section and (colliders.collide(data.blockCol, p) or whistle.getActive()) then
			if p.holdingNPC ~= nil and p.holdingNPC.ix == v.idx then
				p:mem(0x154, FIELD_WORD, -1)
				return
			end
			v:mem(0x12A, FIELD_WORD, 0)
			v:mem(0x124, FIELD_WORD, 0)
			SFX.play(4)
			local a = Effect.spawn(1, v.x + 0.5 * v.width, v.y + 0.5 * v.height)
			if v.ai1 > 0 then
				local n = NPC.spawn(v.ai1, v.x + 0.5 * v.width, v.y + 0.5 * v.height, p.section, false, true)
				if not NPC.config[n.id].nogravity then
					n.speedY = -3
				end
				n.direction = 1
				if p.x + 0.5 * p.width < v.x + 0.5 * v.width then
					n.direction = -1
				end
				n.layerName = "Spawned NPCs"
				n.friendly = v.friendly
				data.spawned = n
			end
			if not v.data._settings.respawn then
				v:kill(9)
			end
			break
		end
	end
end

return turnblock