--npcManager.lua
--v1.0.5
--Created by Horikawa Otane, 2016
local expandedDefs = require("expandedDefines");
local eventmanager = require("base/game/npcEventManager");
local blockmanager = require("blockmanager");
local colliders = require("colliders");

local npcManager = {}
npcKillArray = {}
npcKillArray[1] = 2
npcKillArray[2] = 9
npcKillArray[3] = 9
npcKillArray[4] = 3
npcKillArray[5] = 9
npcKillArray[6] = 16
npcKillArray[7] = 9
npcKillArray[8] = 36
npcKillArray[10] = 53


function npcManager.onInitAPI()
	if not isOverworld then
		registerEvent(npcManager, "onNPCKill");
		registerEvent(npcManager, "onTickEnd");
	end
end

local deathEffectArray = {}

function npcManager.setNpcSettings(settingsArray)
	local id = settingsArray.id
	for npcCode, npcValue in pairs(settingsArray) do
		npcCode = npcCode:lower();
		if npcCode ~= "id" then
			NPC.config[id]:setDefaultProperty(npcCode, npcValue)
		end
	end
	return NPC.config[id]
end

function npcManager.getNpcSettings(id)
	return NPC.config[id];
end

function npcManager.registerDefines(id, typelist)
	expandedDefs.registerNPC(id, typelist);
end

function npcManager.deregisterDefines(id, typelist)
	expandedDefs.deregisterNPC(id, typelist);
end

function npcManager.registerHarmTypes(id, harmList, deatheffects)
	NPC.config[id].vulnerableharmtypes = harmList;
	deathEffectArray[id] = deatheffects;
end

function npcManager.registerEvent(id, tbl, eventName, libEventName)
	libEventName = libEventName or eventName;
	local en = eventName:match("^(.+)NPC$");
	if(en == nil or expandedDefs.LUNALUA_EVENTS_MAP[en] == nil) then
		error("No event "..eventName.." was found!", 2);
	end
	
	if(type(id) == "table") then
		for _,v in ipairs(id) do
			eventmanager.register(v, tbl, en, libEventName);
		end
	elseif(type(id) == "number") then
		eventmanager.register(id, tbl, en, libEventName);
	else
		error("No matching overload found. Candidates: registerEvent(int id, table apiTable, string eventName), registerEvent(int id, table apiTable, string eventName, string libEventName), registerEvent(table idList, table apiTable, string eventName), registerEvent(table idList, table apiTable, string eventName, string libEventName)")
	end
end
if (NPC ~= nil) then
	NPC.registerEvent = npcManager.registerEvent
end

npcManager.refreshEvents = eventmanager.refreshEvents;

	-- Potentially ugly implementation of onCollideBlock
	
local col_box = Colliders.Box(0,0,1,1)

function npcManager.getNPCHitbox(x, y, wid, hei, swell)		
	col_box.width = wid + swell
	col_box.height = hei + swell
	col_box.x = x - swell * 0.5
	col_box.y = y - swell * 0.5

	return col_box
end

local blockFilter = function(v) return (not v.isHidden) and (not v:mem(0x5A, FIELD_BOOL)) end

function npcManager.onTickEnd()
	-- Blessed, for now. Cheaper than onTickEndNPC. Still needs some cheaper thing in the future though.
	for k,n in ipairs(NPC.get(-1, Section.getActiveIndices())) do
		if (not n.isHidden and (n.collidesBlockBottom or n.collidesBlockUp or n.collidesBlockLeft or n.collidesBlockRight or n:mem(0x120,FIELD_BOOL))) then
			local c = Colliders.getColliding {
				a = npcManager.getNPCHitbox(n.x, n.y, n.width, n.height, 0.3),
				b = Block.COLLIDABLE,
				btype = Colliders.BLOCK,
				filter = blockFilter
			}
			for k,b in ipairs(c) do
				blockmanager.callExternalEvent("onCollide", b, n)
			end
		end
	end
end

function npcManager.onNPCKill(eventobj, npc, reason)
	if(not npc.isValid or deathEffectArray[npc.id] == nil) then
		return;
	end
	if npc.id > 293 and npcKillArray[reason] then
		Audio.playSFX(npcKillArray[reason])
	end
	if(deathEffectArray[npc.id] ~= nil and deathEffectArray[npc.id][reason] ~= nil) then
		local aid = deathEffectArray[npc.id][reason];
		local offx,offy = 0.5,0.5;
		local rex,rey = 0.5,0.5;
		local variant = 0;
		local npcID = 0;
		local speedX, speedY
		local drawOnlyMask = false
		if(type(aid) == "table") then
			offx = aid.xoffset or 0.5;
			offy = aid.yoffset or 0.5;
			rex = aid.xoffsetBack or 0.5;
			rey = aid.yoffsetBack or 0.5;
			speedX = aid.speedX
			speedY = aid.speedY
			variant = aid.variant or 0
			npcID = aid.npcID or 0
			drawOnlyMask = aid.drawOnlyMask or false
			aid = aid.id;
		end
		local momentum = {
			x=npc.x+(offx*npc.width),
			y=npc.y+(offy*npc.height),
			speedX = speedX,
			speedY = speedY,
			width = npc.width,
			height = npc.height
		}
		local a = Effect.spawn(aid,momentum, variant, npcID, drawOnlyMask);
		a.x = a.x-((rex)*a.width);
		a.y = a.y-((rey)*a.height);
		a.speedX = speedX or a.speedX
		a.speedY = speedY or a.speedY
		if npc.direction ~= 0 then
			a.direction = npc.direction
		end
	end
end

--Takes an npc and a kill reason and gives the first player that could have collected this, if any;
--TODO: make this closely match vanilla logic
--TODO: Possibly add options for yoshi/sword slashes
function npcManager.collected(npc, reason)
	if(reason == 9 and npc:mem(0x12E, FIELD_WORD) == 0) then
		for _,p in ipairs(Player.get()) do
			--  Just been eaten				   --  Player riding yoshi 			--  Tongue moving back in  --  Tongue not extended (last two only occur after eating something)
			if((npc:mem(0x138,FIELD_WORD) == 5 and p:mem(0x108,FIELD_WORD) == 3 and p:mem(0xB6,FIELD_BOOL) and not p:mem(0x10C,FIELD_BOOL)) --[[Eaten by yoshi]] or colliders.collide(npc, p) or colliders.speedCollide(npc, p) or colliders.slash(p,npc) or colliders.downSlash(p,npc)) then
				return p;
			end
		end
	end
	return nil;
end

local function npcEnvironmentCallback(name, env)
	local id = tonumber(name)
	env.NPC_ID = id
	
	env.NPC = setmetatable({
		registerEvent = function(arg1, arg2, arg3, arg4)
			if (type(arg1) == "number") then
				npcManager.registerEvent(arg1, arg2, arg3, arg4)
			else
				npcManager.registerEvent(id, arg1, arg2, arg3)
			end
		end
	}, {
		__index = NPC,
		__call = function(obj, arg) return NPC(arg) end
	})
end

local doneLoadingNpcCode = false
function npcManager.loadNpcCode()
	-- Be sure to only run once
	if (doneLoadingNpcCode) then
		return
	end
	doneLoadingNpcCode = true
	
	local require_utils = require("require_utils")
	local string_gsub = string.gsub
	
	local relEpisodePath = require_utils.normalizeRelPath(Misc.episodePath())
	
	local basegameNpcPath = string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\npcs\\npc-?.lua;"
	local basegameNpcRequire = require_utils.makeRequire(
		basegameNpcPath, -- Path
		Misc.getBasegameEnvironment(),  -- Global table
		{}, -- Loaded Table
		false, -- Share globals
		false,  -- Assign require
		nil, function() return nil end,
		npcEnvironmentCallback)
	
	local customNpcPath = (
			string_gsub(__customFolderPath, ";", "<") .. "npc-?.lua;" ..
			string_gsub(__episodePath, ";", "<") .. "npc-?.lua"
		)
		
	local customNpcRequire = require_utils.makeRequire(
		customNpcPath, -- Path
		Misc.getCustomEnvironment(),  -- Global table
		{}, -- Loaded Table
		false, -- Share globals
		false,  -- Assign require
		nil, function() return nil end,
		npcEnvironmentCallback,
		nil, true)
	
	-- TODO: more efficiently check what files exist
	for id = 1,NPC_MAX_ID do
		local lib = basegameNpcRequire(tostring(id))
		if (lib ~= nil) and (lib.onInitAPI ~= nil) then
			lib.onInitAPI()
		end
	end
	local debugstats = require("base\\engine\\debugstats")
	for id = 1,NPC_MAX_ID do
		local lib,pth = customNpcRequire(tostring(id))
		if (lib ~= nil) then
			debugstats.add(require_utils.normalizeRelPath(pth, relEpisodePath))
			if (lib.onInitAPI ~= nil) then
				lib.onInitAPI()
			end
		end
	end
end

return npcManager