-- Written by Saturnyoshi
-- "Inspired" by and some code stolen from Spinda

local npcManager = require("npcManager")

local snifits = {}

local npcID = NPC_ID

function snifits.onInitAPI()
	npcManager.registerEvent(npcID, snifits, "onTickNPC")
	registerEvent(snifits, "onStart", "onStart", false)
end

local NPCHitType = {}
local HIT_TYPE_IGNORE = 0
local HIT_TYPE_HIT = 1
local HIT_TYPE_PROJECTILE = 2

local function setHitTypes(t, hitType)
	for _, v in ipairs(t) do
		NPCHitType[v] = hitType
	end
end

function snifits.onStart()
	setHitTypes(NPC.UNHITTABLE, HIT_TYPE_IGNORE)
	setHitTypes(NPC.MULTIHIT, HIT_TYPE_HIT)
	setHitTypes(NPC.HITTABLE, HIT_TYPE_HIT)
end

local function hitBlocks(v, pID)
	for __, w in ipairs(Block.getIntersecting(v.x - 4 + v.speedX, v.y - 2, v.x + v.width + 4 + v.speedX, v.y + v.height + 2)) do
		if not w.isHidden and Block.SOLID_MAP[w.id] then
			local p = Player(pID)
			local pChar = p.character
			p.character = 1
			w:hit(false, p)
			p.character = pChar
			v:kill()
		end
	end
end

local function hitBullet(bullet, hit)
	local hitType = NPCHitType[hit.id]
	player:mem(0x56, FIELD_WORD, 0)
	if hitType then
		if hitType == HIT_TYPE_HIT then
			hit:harm(HARM_TYPE_NPC)
			bullet:kill()
		elseif hitType == HIT_TYPE_PROJECTILE then
			hit:kill()
			bullet:kill()
		end
	else
		bullet:kill()
	end
end

function snifits.onTickNPC(v)
	if not Defines.levelFreeze and v:mem(0x12A, FIELD_WORD) > 0 and not v.isHidden and v:mem(0x124,FIELD_WORD) ~= 0 then
		if v.data._basegame.playerFired then
			for __, w in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if not w.friendly and w:mem(0x12C, FIELD_WORD) == 0 then
					hitBullet(v, w)
				end
			end
			hitBlocks(v, v.data._basegame.playerFired)
		end
	end
end

return snifits
