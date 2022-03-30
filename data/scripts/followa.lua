--Oh look it's a follower API
--Made by Hoeloe for Bowser
--Fancy that

local vectr = require("vectr");
local colliders = require("colliders");

local followa = {};

local flist = {};

local validitylist = {};

followa.TYPE = { WALK = 0, WALK_JUMP = 1, FLY = 2};

function followa.onInitAPI()
	registerEvent(followa,"onTick","onTick",false);
	registerEvent(followa,"onTickEnd","onTickEnd",false);
	registerEvent(followa,"onNPCKill","onNPCKill",false);
	registerEvent(followa,"onDraw","onDraw",false);
	registerEvent(followa,"onDrawEnd","onDrawEnd",false);
end

function followa.Follow(npc, target, speed, offset, mindistance, maxdistance, behaviour)
	if(behaviour == nil) then
		behaviour = followa.TYPE.WALK_JUMP;
	end

	if(target.__type == "NPC") then
		validitylist[target] = true;
	end
	
	if(offset == nil) then
		offset = vectr.v2(0,0);
	end
	
	if(target.__type == "NPC" or target.__type == "Player") then
		offset = offset+vectr.v2(target.width,target.height)*0.5;
	end
	
	if(mindistance == nil) then mindistance = 0; end
	
	local t = {id = npc.id, target=target, offset=offset, speed=speed, behaviour=behaviour, mindistance = mindistance, maxdistance = maxdistance};
	npc.friendly = true;
	npc.width = npc.width;
	npc.height = npc.height;
	
	flist[npc] = t;
	if(validitylist[target]) then
		validitylist[target] = #flist;
	end
end

function followa.Update(npc, target)
	if(npc.isValid) then
		if(flist[npc] ~= nil) then
			validitylist[flist[npc].target] = nil;
			if(target.__type == "NPC") then
				validitylist[target] = true;
			end
			if(flist[npc].target.__type == "NPC" or flist[npc].target.__type == "Player") then
				flist[npc].offset = flist[npc].offset-vectr.v2(flist[npc].target.width,flist[npc].target.height)*0.5;
			end
			
			if(target.__type == "NPC" or target.__type == "Player") then
				flist[npc].offset = flist[npc].offset+vectr.v2(target.width,target.height)*0.5;
			end
			
			flist[npc].target = target;
		end
	end
end

function followa.StopFollowing(npc, makeUnfriendly)
	if(flist[npc] ~= nil) then
		validitylist[flist[npc].target] = nil;
		flist[npc] = nil;
		if(makeUnfriendly == true) then
			npc.friendly = false;
		end
		npc:mem(0x136,FIELD_WORD,0); 
	end
end

function followa.SetBehaviour(npc, behaviour)
	if(flist[npc] ~= nil) then
		flist[npc].behaviour = behaviour;
	end
end

function followa.onTick()
	for k,v in pairs(flist) do
		if(k.isValid) then
			k:mem(0x136,FIELD_WORD,1); --Stop SMBX overriding movement
			if(validitylist[v.target] == nil or v.target.isValid) then
				local target = vectr.v2(v.target.x,v.target.y) + v.offset;
				local t = target - vectr.v2(k.x+k.width*0.5,k.y+k.height);
				
				if(v.behaviour == followa.TYPE.WALK or v.behaviour == followa.TYPE.WALK_JUMP) then
					local mod = 1;
					if(t.x < 0) then
						mod = -1;
					end
					
					
					if(v.wantToJump) then
						if(k.collidesBlockBottom) then
							k.speedY = - 8;
							wantToJump = false;
						end
					end
					
					v.wantToJump = false;
					
					if(math.abs(t.x) > v.mindistance) then
						k.speedX = mod*v.speed*math.min(1,math.max((math.abs(t.x)-v.mindistance)*0.1,0));
					else
						k.speedX = 0;
					end
					
					if(v.behaviour == followa.TYPE.WALK_JUMP) then
						if(k.collidesBlockLeft or k.collidesBlockRight or t.y < -64) then
							v.wantToJump = true;
							k:mem(0x120,FIELD_WORD,0);
						end
					end
				elseif(v.behaviour == followa.TYPE.FLY) then
					local spd = t:normalise()*v.speed*math.min(1,math.max((t.length-v.mindistance)*0.1,0));
					if(t.length < v.mindistance) then
						k.speedX = 0;
						k.speedY = 0;
					else
						k.speedX = spd.x;
						k.speedY = spd.y;
					end
					
				end
				
				if(v.maxdistance ~= nil and t.length > v.maxdistance) then
					local a = Animation.spawn(10,k.x+k.width*0.5,k.y+k.height*0.5);
					a.x = a.x - a.width*0.5;
					a.y = a.y - a.height*0.5;
					
					k.x = v.target.x-k.width*0.5;
					k.y = v.target.y-k.height;
					
					local b = Animation.spawn(10,k.x+k.width*0.5,k.y+k.height*0.5);
					a.x = a.x - a.width*0.5;
					a.y = a.y - a.height*0.5;
				end
			end
		end
	end
end

function followa.onTickEnd()
end

function followa.onDraw()
end

function followa.onDrawEnd()
end

function followa.onNPCKill(eventobj, npc, reason)
	if(validitylist[n] ~= nil) then 
		flist[validitylist[n]] = nil;
	end
end

return followa;