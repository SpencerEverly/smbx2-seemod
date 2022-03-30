local npcManager = require("npcManager");
local utils = require("npcs/npcutils")
local rng = require("rng");

local boocircle = {};
local circleboo = {}

local idHierarchyMap = {}

local configDefaults = {
	booCount = 10,
	booRadius = 160,
	booSpeed = 1,
	booGaps = 1,
	startAngle = 0
}

function boocircle.registerRing(id, ...)
    idHierarchyMap[id] = {...}
	npcManager.registerEvent(id, boocircle, "onTickNPC");

    for k,v in ipairs(idHierarchyMap[id]) do
        npcManager.registerEvent(v, circleboo, "onDrawNPC");
    end
end

function boocircle.onInitAPI()
	registerEvent(boocircle, "onNPCKill");
end

local function getClosestPlayer(obj, pls)
	if(#pls == 1) then
		return pls[1];
	end
	local bestD = math.huge;
	local best = nil;
	for _,v in ipairs(pls) do
		local dx = v.x-obj.x;
		local dy = v.y-obj.y;
		if(dx*dx + dy*dy < bestD) then
			best = v;
		end
	end
	return best or player;
end

function boocircle:onTickNPC()

	local isSpawning = false;
	
    local sdata = self.data._basegame;
    local settings = self.data._settings;
    local data = NPC.config[self.id]
	
	local spawner = self:mem(0x138, FIELD_WORD);
	local t = self:mem(0x13C, FIELD_DFLOAT);
	
	if(not Defines.levelFreeze) then
		utils.applyLayerMovement(self)
		
		--Spawning from block
		if(spawner == 1 or spawner == 3 or spawner == 4) then
			self.speedX = 0;
			if(sdata.friendly == nil) then
				sdata.friendly = self.friendly;
			end
			self.friendly = true;
			isSpawning = true;
			if(spawner == 1) then
				sdata.spawnoffset = vector.v2(0, data.height*0.5+16);
				t = t/data.height;
			elseif(spawner == 3) then
				sdata.spawnoffset = vector.v2(0, -data.height*0.5-16);
				t = t/32;
				if(self:mem(0x13C, FIELD_DFLOAT) == 31) then
					sdata.spawnoffset.y = sdata.spawnoffset.y+32;
					self.y = self.y-32;
					self:mem(0x138, FIELD_WORD,0)
					self:mem(0x13C, FIELD_DFLOAT,0)
				end
			elseif(spawner == 4) then
				local dir = self:mem(0x144, FIELD_WORD);
				if(dir == 1) then
					t = (t-self.y)/data.height;
					sdata.spawnoffset = vector.v2(16-data.width*0.5, 16-data.height*0.5);
					sdata.startspawnoffset = vector.v2(16-data.width*0.5, -32-data.height);
				elseif(dir == 3) then
					t = 1-(t-self.y)/data.height;
					sdata.spawnoffset = vector.v2(16-data.width*0.5, 16-data.height*0.5);
					sdata.startspawnoffset = vector.v2(16-data.width*0.5, 16+data.height*0.5);
				elseif(dir == 2) then
					t = (t-self.x)/data.width;
					sdata.spawnoffset = vector.v2(16-data.width*0.5, 16-data.height*0.5);
					sdata.startspawnoffset = vector.v2(16-data.width*0.5, 16-data.height*0.5);
				elseif(dir == 4) then
					t = 1-(t-self.x)/data.width;
					sdata.spawnoffset = vector.v2(16-data.width*0.5, 16-data.height*0.5);
					sdata.startspawnoffset = vector.v2(16+data.width*0.5, 16-data.height*0.5);
				end
			end
		elseif(sdata.friendly ~= nil) then
			self.friendly = sdata.friendly;
			sdata.friendly = nil;
		end
	end

	--Extra settings
	if sdata.init == nil then
		for k,d in pairs(configDefaults) do
			if settings[k] == nil then
				settings[k] = d
			end
		end
		sdata.noMoreObjInLayer = sdata.noMoreObjInLayer or self.noMoreObjInLayer
		sdata.deathEventName = sdata.deathEventName or self.deathEventName
		self.noMoreObjInLayer = ""
		self.deathEventName = ""
		sdata.init = true
	end
	
	if(sdata.boos == nil) then
		sdata.boos = {};

		local totalBoos = settings.booCount+settings.booGaps;
		local dangle =360/totalBoos;
		local angle = settings.startAngle;
		local v = vector.v2(0,-settings.booRadius):rotate(angle);

		for i = 1,settings.booCount do
			local n = NPC.spawn(rng.irandomEntry(idHierarchyMap[self.id]), self.x, self.y, self:mem(0x146,FIELD_WORD), true);
			n.direction = self.direction;
			n.layerName = self.layerName
			n.noMoreObjInLayer = sdata.noMoreObjInLayer
			n.deathEventName = sdata.deathEventName
			n.data._basegame = {type = rng.randomInt(0,2), animationTimer = NPC.config[n.id].framespeed, animationFrame = 0, angle = angle};
			n.x = n.x-n.width*0.5;
			n.y = n.y-n.height*0.5;
			n:mem(0xDC,FIELD_WORD,n.id);
			angle = angle + dangle;
			table.insert(sdata.boos, n);
		end
	end
	if(sdata.spawnoffset == nil) then
		sdata.spawnoffset = vector.zero2;
		sdata.startspawnoffset = vector.zero2;
	end
	if(sdata.startspawnoffset == nil) then
		sdata.startspawnoffset = vector.zero2;
	end

	local secs = Section.getActiveIndices()
	local selfsec = self:mem(0x146,FIELD_WORD)
	
	if selfsec == secs[1] or selfsec == secs[2] then
		local c = vector.v2(self.x+self.width*0.5, self.y+self.height*0.5)
		local spawncounter = self:mem(0x12A,FIELD_WORD);
		local pls = Player.get();
		local d = self.direction;
		for i = #sdata.boos,1,-1 do
			local v = sdata.boos[i];
			if(not v.isValid) then
				table.remove(sdata.boos, i);
			else
				local vs = vector.v2(v.width*0.5, v.height*0.5);
				local pos = c - vs + (vector.v2(0,-settings.booRadius):rotate(v.data._basegame.angle)) + sdata.spawnoffset;
				--Graphics.glDraw{vertexCoords = {c.x + sdata.spawnoffset.x,c.y + sdata.spawnoffset.y,pos.x+vs.x,pos.y+vs.y}, primitive = Graphics.GL_LINES, sceneCoords=true} --Debug
				if(isSpawning or t > 0) then
					v.x = math.lerp(c.x-vs.x+sdata.startspawnoffset.x, pos.x, t);
					v.y = math.lerp(c.y-vs.y+sdata.startspawnoffset.y, pos.y, t);
					--v:mem(0x130, FIELD_WORD, 1)
					--v:mem(0x132, FIELD_WORD, 2)
					--v:mem(0x12E, FIELD_WORD, 30)
				else
					v.x = pos.x;
					v.y = pos.y;
					if(not Defines.levelFreeze) then
						v.data._basegame.angle = v.data._basegame.angle + settings.booSpeed*d * (data.defaultSpeed or 1);
					end
				end
				
				v.friendly = self.friendly;
				v.isHidden = self.isHidden;
				
				if(not Defines.levelFreeze) then
					local p = getClosestPlayer(v, pls);
					
					if(p.x + p.width*0.5 < pos.x+vs.x) then
						v.direction = -1;
					else
						v.direction = 1;
					end
				end
				spawncounter = math.max(spawncounter, v:mem(0x12A,FIELD_WORD));
			end
		end
		
		for i = 1,#sdata.boos do
			sdata.boos[i]:mem(0x12A,FIELD_WORD,spawncounter);
		end
		
		self:mem(0x12A,FIELD_WORD,spawncounter);
	end
end

function circleboo:onDrawNPC()
    local sdata = self.data._basegame;
    local data = NPC.config[self.id];
	local t = sdata.type or 0;
	if(sdata.animationTimer == nil) then
		sdata.animationTimer = data.framespeed;
		sdata.animationFrame = 0;
	end
	local diroffset = (data.bootypes or 1)*data.frames*(self.direction+1)*0.5;
	local f = t*data.frames + diroffset;
		
	self.animationTimer = 0;
		
	if(not Defines.levelFreeze) then
		sdata.animationTimer = sdata.animationTimer-1;
		if(sdata.animationTimer == 0) then
			sdata.animationTimer = data.framespeed;
			sdata.animationFrame = (sdata.animationFrame + 1)%data.frames;
		end
	end
		
	self.animationFrame = sdata.animationFrame + f;
end

function boocircle.onNPCKill(eventObj,npc,killReason)
	if(idHierarchyMap[npc.id]) then
		local sdata = npc.data._basegame;
		
		for i = #sdata.boos,1,-1 do
			if(sdata.boos[i].isValid) then
				sdata.boos[i]:kill(killReason);
			end
		end
	end
end

return boocircle;