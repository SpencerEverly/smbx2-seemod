---------------**********************-------------
---------------** EXPANDED DEFINES **-------------
---------------**********************-------------						 
----------Created by Hoeloe and Horikawa (2016)---
--------------Just some block lists---------------
--------------For Super Mario Bros X--------------
----------------------v1.3------------------------

local expandedDefines = {}

--Misc Lists Here

expandedDefines.LUNALUA_EVENTS = Misc.LUNALUA_EVENTS

--**************************************************************--
--** DO NOT TOUCH PAST HERE UNLESS YOU KNOW WHAT YOU'RE DOING **--
--**************************************************************--

local function calculateMaxOfTables(tableName)
	local maxValue = 0
	for _, v in ipairs(tableName) do
		maxValue = math.max(math.max(unpack(v), maxValue));
	end
	return maxValue;
end

expandedDefines.BLOCK_MAX_NUMBER = _G.BLOCK_MAX_ID

expandedDefines.NPC_MAX_NUMBER = _G.NPC_MAX_ID

local function makeTestMap(src)
	local ret = {};
	for _,v in ipairs(src) do
		ret[v] = true;
	end
	return ret
end

local function makelistmtraw(id, basemt)
	local r = {};
	for k, v in pairs(basemt) do
		r[k] = v;
	end
	r.__index = function(tbl, key)
		if(key == "id") then
			return id;
		end
	end
	return r;
end

--IDs are set to powers of two so that concats can store IDs with the bitwise or of the concatenated lists.
--For example, lists with IDs 2,4 and 16 will produce bit patterns of 00010, 00100 and 10000, which produces
--a concatenated bit pattern of 10110, which gives the ID 22, which will be unique for this concatenation pattern.
local function makelistmt(rootid, basemt)
	return makelistmtraw(math.pow(2,rootid), basemt);
end

local indexerror = function(tbl, key, val)
	error("Attempted to assign a value in a read-only table.", 2)
end

local function makeConcat(cacheList, basemt)
	return  function(a, b)
				if(cacheList[bit.bor(a.id,b.id)] ~= nil) then
					return cacheList[bit.bor(a.id,b.id)];
				end
				local r = {};
				for k, v in ipairs(a) do
					r[k] = v;
				end
				for k, v in ipairs(b) do
					r[#a+k] = v;
				end
				setmetatable(r, makelistmtraw(bit.bor(a.id,b.id), basemt));
				cacheList[bit.bor(a.id,b.id)] = r;
				return r;
			end
end

local blockscache = {};
local blockmt = {}
blockmt.__concat = makeConcat(blockscache, blockmt)
blockmt.__newindex = indexerror;

local npcscache = {};
local npcmt = {}
npcmt.__concat = makeConcat(npcscache, npcmt)
npcmt.__newindex = indexerror;

local function contains(a, b)
	if(type(a) == 'number') then return a == b; end
	for _, v in ipairs(a) do
		if(v == b) then
			return true;
		end
	end
	return false;
end

local npcListNames = {};
local blockListNames = {};

local function register(id, typeList, listNames, obj, maxid, cacheList)
	if true then return end
	for _,v in ipairs(typeList) do
		for _,k in ipairs(listNames) do
			if(obj[k] == v) then
				table.insert(v, id);
				obj[k.."_MAP"][id] = true;
				break;
			end
		end
		--Caches are no longer valid
		for i = 1,maxid do
			cacheList[bit.bor(v.id,math.pow(2,i-1))] = nil;
		end
	end
end

local function deregister(id, typeList, listNames, obj, maxid, cacheList)
	for _,v in ipairs(typeList) do
		for _,k in ipairs(listNames) do
			if(obj[k] == v) then
				for i = #v,1,-1 do
					if(v[i] == id) then
						table.remove(v,i);
					end
				end
				obj[k.."_MAP"][id] = nil;
				break;
			end
		end
		
		--Caches are no longer valid
		for i = 1,maxid do
			cacheList[bit.bor(v.id,math.pow(2,i-1))] = nil;
		end
	end
end

function expandedDefines.registerNPC(id, typeList)
	register(id, typeList, npcListNames, NPC, maxNPCID, npcscache);
end

function expandedDefines.deregisterNPC(id, typeList)
	deregister(id, typeList, npcListNames, NPC, maxNPCID, npcscache);
end

function expandedDefines.registerBlock(id, typeList)
	register(id, typeList, blockListNames, Block, maxBlockID, blockscache);
end

function expandedDefines.deregisterBlock(id, typeList)
	deregister(id, typeList, blockListNames, Block, maxBlockID, blockscache);
end

local function makeIterator(data)

	local nextTbl = {}
	local last = nil
	for k,_ in pairs(data) do
		if last ~= nil then
			nextTbl[last] = k
		end
		last = k
	end
	setmetatable(data,  { 
							__pairs = function(tbl, k)
								k = nextTbl[k]
								if k then return k,tbl[k] end
							end
						})
end

--[[
expandedDefines.BLOCK_SOLID_MAP = makeTestMap(expandedDefines.BLOCK_SOLID)
expandedDefines.BLOCK_SEMISOLID_MAP = makeTestMap(expandedDefines.BLOCK_SEMISOLID)
expandedDefines.BLOCK_NONSOLID_MAP = makeTestMap(expandedDefines.BLOCK_NONSOLID)
expandedDefines.BLOCK_LAVA_MAP = makeTestMap(expandedDefines.BLOCK_LAVA)
expandedDefines.BLOCK_HURT_MAP = makeTestMap(expandedDefines.BLOCK_HURT)
expandedDefines.BLOCK_PLAYER_MAP = makeTestMap(expandedDefines.BLOCK_PLAYER)
expandedDefines.BLOCK_SIZEABLE_MAP = makeTestMap(expandedDefines.BLOCK_SIZEABLE)

expandedDefines.NPC_POWERUP_MAP = makeTestMap(expandedDefines.NPC_POWERUP)
expandedDefines.NPC_UNHITTABLE_MAP = makeTestMap(expandedDefines.NPC_UNHITTABLE)
expandedDefines.NPC_MULTIHIT_MAP = makeTestMap(expandedDefines.NPC_MULTIHIT)
expandedDefines.NPC_HITTABLE_MAP = makeTestMap(expandedDefines.NPC_HITTABLE)
expandedDefines.NPC_SHELL_MAP = makeTestMap(expandedDefines.NPC_SHELL)

expandedDefines.LUNALUA_EVENTS_MAP = makeTestMap(expandedDefines.LUNALUA_EVENTS)
]]

local tableinsert = table.insert
local tableremove = table.remove

local blockTableToFuncMap = {
	SOLID = function(v) return not (v.passthrough or v.semisolid or v.sizable) and (v.playerfilter == 0) and (v.npcfilter == 0) end,
	NONSOLID = function(v) return v.passthrough end, -- TODO: This name seems misleading. I would tend to expect "NONSOLID" to mean all blocks not in the list "SOLID". That's not at all what it actually is though.
	SEMISOLID = function(v) return (not v.passthrough) and (v.semisolid or v.sizable) end,
	SIZEABLE = function(v) return v.sizable end,
	HURT = function(v) return v.customhurt end,
	LAVA = function(v) return v.lava end,
	PLAYER = function(v) return v.playerfilter ~= 0 end,
	PLAYERSOLID = function(v) return (v.npcfilter == -1) and (v.playerfilter == 0) and not (v.passthrough or v.semisolid or v.sizable) end, -- TODO: Is this really a good name? Currently this means "blocks that are only solid for players", but the name "PLAYERSOLID" makes me think "blocks are are solid for players, including ones also solid for NPCs". I really think this is a misnomer for that reason.
	MEGA_SMASH = function(v) return v.smashable == 3 end,
	MEGA_HIT = function(v) return v.smashable == 2 end,
	MEGA_STURDY = function(v) return v.smashable == 1 end,
	SLOPE_LR_FLOOR = function(v) return v.floorslope == -1 end,
	SLOPE_RL_FLOOR = function(v) return v.floorslope == 1 end,
	SLOPE_LR_CEIL = function(v) return v.ceilingslope == -1 end,
	SLOPE_RL_CEIL = function(v) return v.ceilingslope == 1 end,
	SLOPE = function(v) return v.floorslope ~= 0 or v.ceilingslope ~= 0 end,
	COLLIDABLE = function(v) return v._cancollide end,
	EDIBLEBYVINE = function(v) return v.ediblebyvine or (v.semisolid and not v.sizable) end, -- Edible by mutant vines
}

expandedDefines.BLOCK_LISTS = {}

for k,_ in pairs(blockTableToFuncMap) do
	expandedDefines["BLOCK_" .. k] = {}
	expandedDefines["BLOCK_" .. k .. "_MAP"] = {}
	tableinsert(expandedDefines.BLOCK_LISTS, expandedDefines["BLOCK_" .. k])
end



local blockFieldInfluenceMap = {
	passthrough = {"SOLID", "SEMISOLID", "NONSOLID", "PLAYERSOLID"},
	semisolid = {"SOLID", "SEMISOLID", "PLAYERSOLID", "EDIBLEBYVINE"},
	sizable = {"SOLID", "SEMISOLID", "SIZEABLE", "PLAYERSOLID", "EDIBLEBYVINE"},
	customhurt = {"HURT"},
	playerfilter = {"PLAYER", "SOLID", "PLAYERSOLID"},
	npcfilter = {"SOLID", "PLAYERSOLID"},
	lava = {"LAVA"},
	smashable = {"MEGA_HIT", "MEGA_STURDY", "MEGA_SMASH"},
	floorslope = {"SLOPE", "SLOPE_LR_FLOOR", "SLOPE_RL_FLOOR"},
	ceilingslope = {"SLOPE", "SLOPE_LR_CEIL", "SLOPE_RL_CEIL"},
	_cancollide = {"COLLIDABLE"},
	ediblebyvine = {"EDIBLEBYVINE"},
}

--MAY be a bit faster? Creates a pairs ordering so future pairs calls can use ipairs (but stops new things from being added to the table properly)
--makeIterator(blockFieldInfluenceMap)

function expandedDefines.setBlockProperty(tbl, k, v)
	if not blockFieldInfluenceMap[k] then return end
	for _, idx in ipairs(blockFieldInfluenceMap[k]) do
		if blockTableToFuncMap[idx](tbl) then
			if (not expandedDefines["BLOCK_" .. idx .. "_MAP"][tbl.id]) then
				tableinsert(expandedDefines["BLOCK_" .. idx], tbl.id)
				expandedDefines["BLOCK_" .. idx .. "_MAP"][tbl.id] = true
			end
		elseif (expandedDefines["BLOCK_" .. idx .. "_MAP"]) then
			for i, n in ipairs(expandedDefines["BLOCK_" .. idx]) do
				if n == tbl.id then
					tableremove(expandedDefines["BLOCK_" .. idx], i)
					expandedDefines["BLOCK_" .. idx .. "_MAP"][tbl.id] = nil
					break
				end
			end
		end
	end
end

local npcTableToFuncMap = {
	POWERUP = function(v) return v.powerup end,
	COLLECTIBLE = function(v) return v.isinteractable end,
	MULTIHIT = function(v) return v.health and v.health > 1 end,
	HITTABLE = function(v)
		for k,ht in ipairs(v.vulnerableharmtypes) do
			if ht ~= 6 and ht ~= 9 then return true end
		end
		return false
	end,
	UNHITTABLE = function(v)
		for k,ht in ipairs(v.vulnerableharmtypes) do
			if ht ~= 6 and ht ~= 9 then return false end
		end
		return true
	end,
	SHELL = function(v) return v.isshell end,
	MOUNT = function(v) return v.isshoe or v.isyoshi --[[or v.isclowncar?]] end,
	SWITCH = function(v) return v.iscustomswitch end,
	PLAYERSOLID = function(v) return v.playerblock end,
	VINE = function(v) return v.isvine end,
	VEGETABLE = function(v) return v.isvegetable end,
	HOT = function(v) return v.ishot end,
	COLD = function(v) return v.iscold end,
}

expandedDefines.NPC_LISTS = {}

-- Can't have these automated yet cause vulnerableharmtypes
expandedDefines.NPC_UNHITTABLE = {9, 10, 11, 13, 14, 16, 21, 22, 26, 30, 31, 32, 33, 34, 35, 40, 41, 45, 46, 56, 57, 58, 60, 62, 64, 66, 67, 68, 69, 70, 75, 78, 79, 80, 81, 82, 83, 84, 85, 87, 88, 90, 91, 92, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 133, 134, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 169, 170, 171, 178, 179, 181, 182, 183, 184, 185, 186, 187, 188, 190, 191, 192, 193, 196, 197, 198, 202, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 237, 238, 239, 240, 241, 246, 248, 249, 250, 251, 252, 253, 254, 255, 258, 259, 260, 264, 265, 266, 269, 273, 274, 276, 277, 278, 279, 282, 283, 287, 288, 289, 290, 291, 292}
expandedDefines.NPC_HITTABLE = {1, 2, 3, 4, 5, 6, 7, 8, 12, 15, 17, 18, 19, 20, 23, 24, 25, 27, 28, 29, 36, 37, 38, 39, 42, 43, 44, 47, 48, 49, 50, 51, 52, 53, 54, 55, 59, 61, 63, 65, 71, 72, 73, 74, 76, 77, 86, 89, 93, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 135, 136, 137, 161, 162, 163, 164, 165, 166, 167, 168, 172, 173, 174, 175, 176, 177, 180, 189, 194, 195, 199, 200, 201, 203, 204, 205, 206, 207, 208, 209, 210, 229, 230, 231, 232, 233, 234, 235, 236, 242, 243, 244, 245, 247, 256, 257, 261, 262, 263, 267, 268, 270, 271, 272, 275, 280, 281, 284, 285, 286}

for k,_ in pairs(npcTableToFuncMap) do
	expandedDefines["NPC_" .. k] = expandedDefines["NPC_" .. k] or {}
	expandedDefines["NPC_" .. k .. "_MAP"] = {}
	tableinsert(expandedDefines.NPC_LISTS, expandedDefines["NPC_" .. k])
end

local npcFieldInfluenceMap = {
	isshell = {"SHELL"},
	vulnerableharmtypes = {"HITTABLE", "UNHITTABLE"},
	health = {"MULTIHIT"},
	isinteractable = {"COLLECTIBLE"},
	isyoshi = {"MOUNT"},
	isshoe = {"MOUNT"},
	iscustomswitch = {"SWITCH"},
	powerup = {"POWERUP"},
	playerblock = {"PLAYERSOLID"},
	isvine = {"VINE"},
	isvegetable = {"VEGETABLE"},
	ishot = {"HOT"},
	iscold = {"COLD"},
}

--MAY be a bit faster? Creates a pairs ordering so future pairs calls can use ipairs (but stops new things from being added to the table properly)
--makeIterator(npcFieldInfluenceMap)

function expandedDefines.setNPCProperty(tbl, k, v)
	if not npcFieldInfluenceMap[k] then return end
	for _, idx in ipairs(npcFieldInfluenceMap[k]) do
		if npcTableToFuncMap[idx](tbl) then
			if (not expandedDefines["NPC_" .. idx .. "_MAP"][tbl.id]) then
				tableinsert(expandedDefines["NPC_" .. idx], tbl.id)
				expandedDefines["NPC_" .. idx .. "_MAP"][tbl.id] = true
			end
		elseif (expandedDefines["NPC_" .. idx .. "_MAP"]) then
			for i, n in ipairs(expandedDefines["NPC_" .. idx]) do
				if n == tbl.id then
					tableremove(expandedDefines["NPC_" .. idx], i)
					expandedDefines["NPC_" .. idx .. "_MAP"][tbl.id] = nil
					break
				end
			end
		end
	end
end

function expandedDefines.initializeLists()
	for i=1, BLOCK_MAX_ID do
		for k,idx in pairs(blockFieldInfluenceMap) do
			for _, v in ipairs(idx) do
				if blockTableToFuncMap[v] and blockTableToFuncMap[v](Block.config[i]) then
					if (not expandedDefines["BLOCK_" .. v .. "_MAP"][i]) then
						tableinsert(expandedDefines["BLOCK_" .. v], i)
						expandedDefines["BLOCK_" .. v .. "_MAP"][i] = true
					end
				end
			end
		end
	end
	for i=1, NPC_MAX_ID do
		for k,idx in pairs(npcFieldInfluenceMap) do
			for _, v in ipairs(idx) do
				if npcTableToFuncMap[v] and npcTableToFuncMap[v](NPC.config[i]) then
					if (not expandedDefines["NPC_" .. v .. "_MAP"][i]) then
						tableinsert(expandedDefines["NPC_" .. v], i)
						expandedDefines["NPC_" .. v .. "_MAP"][i] = true
					end
				end
			end
		end
	end
end

for k,v in pairs(expandedDefines) do
	if(type(v) == "table" and (type(v[1]) == "number" or type(v[1] == "string")) and not k:match("_MAP$") and not k:match("_LISTS$") and (k:match("^BLOCK_.*") or k:match("^NPC_.*") or k:match("^LUNALUA_EVENTS$"))) then
		expandedDefines[k.."_MAP"] = table.map(v);
		
		local n = k:match("^BLOCK_(.+)$");
		if(n) then
			table.insert(blockListNames, n);
		else
			n = k:match("^NPC_(.+)$");
			if(n) then
				table.insert(npcListNames, n);
			end
		end
	end
end

expandedDefines.BLOCK_ALL = {}
for i=1,expandedDefines.BLOCK_MAX_NUMBER do
	table.insert(expandedDefines.BLOCK_ALL, i);
end

local maxBlockID = 0;
--Set the IDs of the block lists for caching of concatenated lists.
for k,v in ipairs(expandedDefines.BLOCK_LISTS) do
	setmetatable(v, makelistmt(k-1,blockmt));
	maxBlockID = k;
end
--Set ID of the "all" list to be the same as all lists concatenated.
setmetatable(expandedDefines.BLOCK_ALL, makelistmtraw(math.pow(2,maxBlockID)-1,blockmt));

expandedDefines.NPC_ALL = {}
for i=1,expandedDefines.NPC_MAX_NUMBER do
	table.insert(expandedDefines.NPC_ALL, i);
end

local maxNPCID = 0;
--Set the IDs of the NPC lists for caching of concatenated lists.
for k,v in ipairs(expandedDefines.NPC_LISTS) do
	setmetatable(v, makelistmt(k-1,npcmt));
	maxNPCID = k;
end
--Set ID of the "all" list to be the same as all lists concatenated.
setmetatable(expandedDefines.NPC_ALL, makelistmtraw(math.pow(2,maxNPCID)-1,npcmt));

if (not isOverworld) then
	for k,v in pairs(expandedDefines) do
		if(type(v) == "table") then
			local n = k:match("^BLOCK_(.+)$");
			if(n) then
				Block[n] = v;
			else
				n = k:match("^NPC_(.+)$");
				if(n) then
					NPC[n] = v;
				end
			end
		end
	end
end

return expandedDefines;