local eBlocks = {}

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local idMap = {}
local ids = {}
local relevantNPCIDs = {}
local relevantNPCIDMap = {}
local keywords = {}

function eBlocks.register(id, configString)
	idMap[id] = configString
	table.insert(ids, id)
	--blockmanager.registerEvent(id, eBlocks, "onCollideBlock")
	blockmanager.registerEvent(id, eBlocks, "onTickEndBlock")
	if not keywords[configString] then
		keywords[configString] = true
		for i=1, NPC_MAX_ID do
			if not relevantNPCIDMap[i] then
				if NPC.config[i][configString] then
					table.insert(relevantNPCIDs, i)
					relevantNPCIDMap[i] = true
				end
			end
		end
	end
end

local function meltIce(v)	
	Animation.spawn(10,v.x,v.y)
	
	blockutils.spawnNPC(v)
	
	v:remove()
	SFX.play(3)
end

function eBlocks.onInitAPI()
	registerEvent(eBlocks, "onNPCKill")
end

local function npcfilter(v)
	return relevantNPCIDMap[v.id] and v:mem(0x12A, FIELD_WORD) > 0 and not v.isHidden and v:mem(0x64, FIELD_BOOL) == false and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0
end

local function blockfilter(w)
	return idMap[w.id] and blockutils.hiddenFilter(w)
end

--[[ insufficient, as i need to detect overlaps
function eBlocks.onCollideBlock(v, o)
	if o.__type ~= "NPC" then return end
	if NPC.config[o.id][idMap[v.id] then
		if v:mem(0x12A, FIELD_WORD) > 0 and not v.isHidden and v:mem(0x64, FIELD_BOOL) == false and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			meltIce(v)
			local durability = NPC.config[o.id].durability
			if durability >= 0 then
				o.data._basegame._durability = (o.data._basegame._durability or durability) - 1
				if durability <= 0 then
					o:kill(3)
				end
			end
		end
	end
end
]]

function eBlocks:onTickEndBlock()
	if blockutils.hiddenFilter(self) and  blockutils.isInActiveSection(self) and blockutils.isOnScreen(self, 800) then
		local c = Colliders.getColliding{a = blockutils.getHitbox(self, 8), btype = Colliders.NPC, filter = npcfilter }
		for _,v in ipairs(c) do
			local cfg = NPC.config[v.id]
			if cfg[idMap[self.id]] then
				meltIce(self)
				local durability = cfg.durability or 0
				if durability >= 0 then
					v.data._basegame._durability = (v.data._basegame._durability or durability) - 1
					if v.data._basegame._durability <= 0 then
						v:kill(3)
					end
				end
			end
		end
	end
end

function eBlocks.onNPCKill(_, v, rsn)
	if rsn ~= 4 and rsn ~= 3 then return end
	
	local doCollideCheck = false
	local cfg = NPC.config[v.id]
	for k,i in ipairs(ids) do
		if cfg[idMap[i]] then
			doCollideCheck = true
			break
		end
	end
	
	if doCollideCheck then
		for _,w in ipairs(blockutils.checkNPCCollisions(v, blockfilter)) do
			if cfg[idMap[w.id]] then
				meltIce(w)
			end
		end
	end
end

return eBlocks