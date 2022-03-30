local npcManager = require("npcManager")

local checkpoints = {};

local checkpointList = {};
local NPCIDs = {};

local function getLevelPath()
	return tostring(mem(0x00B2C618, FIELD_STRING));
end

local function getCheckpointPath()
	return tostring(mem(0x00B250B0, FIELD_STRING));
end

local function setCheckpointPath(v)
	mem(0x00B250B0, FIELD_STRING, v);
end

GameData.__checkpoints = GameData.__checkpoints or {};

if(not isOverworld) then
	GameData.__checkpoints[Level.filename()] = GameData.__checkpoints[Level.filename()] or {};
end

local function extractCheckpoint()
	local path = getCheckpointPath();
	if(path == nil or GameData.__checkpoints[Level.filename()].current == nil) then
		return nil,nil;
	else
		return path, GameData.__checkpoints[Level.filename()].current;
	end
end

local function getCheckpointState(self)
	if(GameData.__checkpoints[Level.filename()] ~= nil) then
		return GameData.__checkpoints[Level.filename()][tostring(self.id)] == true;
	else
		return false;
	end
end

local function setCheckpointState(self)
	GameData.__checkpoints[Level.filename()][tostring(self.id)] = true;
end

local function resetCheckpointState(self)
	GameData.__checkpoints[Level.filename()][tostring(self.id)] = nil;
end

local function setCheckpoint(obj)
	setCheckpointPath(getLevelPath());
	GameData.__checkpoints[Level.filename()].current = obj.id;
end

local function clearCheckpoint()
	setCheckpointPath("");
	GameData.__checkpoints[Level.filename()].current = nil;
end

local function getActiveCheckpoint()
	local path,id = extractCheckpoint();
	return id;
end

function checkpoints.getActive()
	local id = getActiveCheckpoint();
	if(id) then
		return checkpoints.get(id);
	else
		return nil;
	end
end

function checkpoints.get(id)
	if(id == nil) then
		return table.iclone(checkpointList);
	else
		return checkpointList[id];
	end
end

function checkpoints.reset()
	clearCheckpoint();
	for _,v in ipairs(checkpointList) do
		v:reset();
	end
end

local function argcheck(t, x)
	assert(t[x], "Argument '"..x.."' is required.",3);
end

local powerupTiers = {{[PLAYER_SMALL] = true}, {[PLAYER_BIG] = true}, {[PLAYER_FIREFLOWER] = true,[PLAYER_ICE] = true,[PLAYER_LEAF] = true}, {[PLAYER_TANOOKIE] = true, [PLAYER_HAMMER] = true}}

local function findTier(power)
	for k,v in ipairs(powerupTiers) do
		if(v[power]) then
			return k;
		end
	end
	return nil;
end

local function upgradePowerup(p,v)
	local currentTier = findTier(p.powerup);
	local newTier = findTier(v);
	if(currentTier ~= nil and newTier ~= nil and newTier > currentTier) then
		p.powerup = v;
	end
end

local function Checkpoint_collect(self, plyr)
	if(not self.collected) then
		setCheckpoint(self);
		setCheckpointState(self);
		
		if(self.powerup) then
			if(plyr == nil) then
				for _,v in ipairs(Player.get()) do
					upgradePowerup(v,self.powerup);
				end
			else
				upgradePowerup(plyr, self.powerup);
			end
		end
		if(self.sound) then
			Audio.playSFX(self.sound);
		end
		
		EventManager.callEvent("onCheckpoint", self, plyr)
	end
end

local function Checkpoint_reset(self)
	if(getActiveCheckpoint() == self.id) then
		clearCheckpoint();
	end
	resetCheckpointState(self);
end

local Checkpoint = {};
function Checkpoint.__index(tbl,k)
	if(k == "collect") then
		return Checkpoint_collect;
	elseif(k == "reset") then
		return Checkpoint_reset;
	elseif(k == "collected") then
		return getCheckpointState(tbl);
	elseif(k == "idx") then
		return tbl.id;
	end
end

function Checkpoint.__newindex(tbl,k, v)
	error("Cannot modify the state of a checkpoint directly.",2);
end

Checkpoint.__type = "Checkpoint"

local function initCheckpoints()
	if(not isOverworld) then
		for _,v in ipairs(NPC.get(NPCIDs)) do
		
			--Don't make checkpoint objects for friendly checkpoints or generators
			if not v:mem(0x64, FIELD_BOOL) and not v.friendly then
				
				local settings = npcManager.getNpcSettings(v.id)
				
				local data = v.data._settings
				
				local sx = v.x + v.width*0.5 + (settings.spawnoffsetx or 0)
				local sy = v.y + v.height + (settings.spawnoffsety or 0)
				local sec = v:mem(0x146, FIELD_WORD)
				if data.warpID and data.warpID > 0 and data.warpID <= Warp.count() then
					local w = Warp(data.warpID-1)
					if w.isValid and not w.toOtherLevel and w.exitX and w.exitY then
						sx = w.exitX + w.exitWidth*0.5
						sy = w.exitY + w.exitHeight
						sec = w.exitSection
					end
				end
				
				v.data._basegame.checkpoint = checkpoints.create{x = sx, y = sy - 32, section = sec, sound = 58, powerup = PLAYER_BIG}
			end
		end

		if(Misc.inEditor() and getCheckpointPath() == "") then
			checkpoints.reset();
		end
	end
end

--[[
Create a new checkpoint object.

Arguments:

Required:
x,y = spawn coordinates
section = section to spawn to

Optional:
actions = function to run when the player spawns to this checkpoint (runs once for each player, with the blueprint: "checkpoint:actions(player)")
powerup = powerup filter to boost the player up to when they collect this checkpoint
sound = sound effect to play when the player collects this checkpoint. Can be a sound id or path

Methods:
cp:collect(player) = collect the checkpoint with the specified player. Leave the player nil to act as if all players collected the checkpoint
cp:reset() = reset the checkpoint to allow it to be collected again

Fields:
x,y = spawn coordinates
section = section to spawn to
actions = function to run when the player spawns to this checkpoint. nil if not used
powerup = powerup filter to boost the player up to when they collect this checkpoint. nil if not used.
sound = sound effect to play when the player collects this checkpoint. nil if not used
collected (READ-ONLY) = whether or not this checkpoint has been collected

]]--
function checkpoints.create(args)
	argcheck(args,"x");
	argcheck(args,"y");
	argcheck(args,"section");
	
	local c = {x = args.x, y = args.y, section = args.section, actions = args.actions, powerup = args.powerup, sound = args.sound};
	
	table.insert(checkpointList, c);
	c.id = #checkpointList;
	
	setmetatable(c, Checkpoint);
	
	return c;
end

function checkpoints.registerNPC(ids)
	if(type(ids) == "table") then
		for _,v in ipairs(ids) do
			table.insert(NPCIDs, v);
		end
	else
		table.insert(NPCIDs, ids);
	end
end

function checkpoints.onInitAPI()
	if(not isOverworld) then
		registerEvent(checkpoints, "onStart", "onStart", true);
		registerEvent(checkpoints, "onExitLevel", "onExitLevel", false);
	end
end

function checkpoints.onStart()
	initCheckpoints();
	local c = checkpoints.getActive();
	if(c) then
		local cnt = 0;
		local wid = 0;
		local ps = Player.get();
		for _,p in ipairs(ps) do
			local width = p.width;
			p.x = c.x - width*0.5;
			p.y = c.y + 32 - p.height;
			if(width > wid) then
				wid = width;
			end
			cnt = cnt + 1;
			p:mem(0x15A, FIELD_WORD, c.section);
		end
		wid = wid + 2;
		local offset = -math.floor(cnt*0.5)*wid;
		if(cnt%2 == 0) then
			offset = offset + wid*0.5;
		end
		local doffset = wid;
		for _,p in ipairs(ps) do
			p.x = p.x + offset;
			offset = offset + doffset;
			if(c.actions) then
				c:actions(p);
			end
		end
		playMusic(c.section);
		setCheckpointPath(getLevelPath())
	end
end

function checkpoints.onExitLevel()
	if(getCheckpointPath() == "") then
		checkpoints.reset();
	end
end

local global_mt = {}
global_mt.__call = function(c, args) 
					if type(args) == "number" then
						return checkpointList[args]
					else
						return checkpoints.create(args) 
					end
				end

setmetatable(checkpoints, global_mt)

return checkpoints;