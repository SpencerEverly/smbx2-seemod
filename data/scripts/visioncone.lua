--Vision Cone
--BETA 0.1
--By Hoeloe

local vision = {};

local colliders = require("colliders");
local vectr = require("vectr")
local G_VISION = Graphics.loadImage(Misc.multiResolveFile("visioncone_light.png", "graphics\\tweaks\\visioncone_light.png"))

local buffers = {};

local function createmt(x,y,dir,fov,tri)
	local mt = {}	
	
	local top = dir:rotate(fov/2);
	local bottom = dir:rotate(-fov/2);
	
	local c = tri or colliders.Tri(x, y, {0,0},{top.x,top.y},{bottom.x,bottom.y});
	
	mt.__index = function(tbl,key)
		if(key == "x") then
			return x;
		elseif(key == "y") then
			return y;
		elseif(key == "direction") then
			return dir;
		elseif(key == "fov") then
			return fov;
		elseif(key == "collider") then
			return c;
		elseif(key == "static") then
			return tbl.staticObjs ~= nil;
		else
			return rawget(tbl,key);
		end
	end
	
	mt.__newindex = function(tbl,key,val)
		if(key == "x") then
			setmetatable(tbl, createmt(val,tbl.y,tbl.direction,tbl.fov,tbl.collider));
			tbl.collider.x = val;
		elseif(key == "y") then
			setmetatable(tbl, createmt(tbl.x,val,tbl.direction,tbl.fov,tbl.collider));
			tbl.collider.y = val;
		elseif(key == "direction") then
			setmetatable(tbl, createmt(tbl.x,tbl.y,val,tbl.fov));
		elseif(key == "fov") then
			setmetatable(tbl, createmt(tbl.x,tbl.y,tbl.direction,val));
		elseif(key == "static") then
			if(val) then
				if(tbl.staticObjs == nil) then
					tbl.staticObjs = {};
				end
			else
				tbl.staticObjs = nil;
			end
		elseif(key == "collider") then
			error("Attempted to set a read-only value: 'collider'",2)
		else
			rawset(tbl,key,val)
		end
	end
	
	return mt;
end

local function round(x) 
	return x + 0.5 - (x + 0.5) % 1 
end;

function vision.VisionCone(x, y, direction, fov)
	local c = {staticObjs = nil};
	
	c.Rotate = function(obj, angle)
		obj.direction = obj.direction:rotate(angle);
	end
	
	c.Check = vision.CheckCone;
	
	c.AddStatic = function(obj, s)
		if(obj.static) then
			table.insert(obj.staticObjs, s)
		else
			error("Cannot assign a static object to a non-static vision cone.",2)
		end
	end
	
	setmetatable(c,createmt(x,y,direction,fov));
	
	return c;
end

local drawQueue = {};

local function worldToScreen(x,y)
			local c = camera;
			local b = {left = c.x, right = c.x + 800, top = c.y, bottom = c.y+600};
			local x1 = x-b.left;
			local y1 = y-b.top;
			return x1,y1;
end

function vision.onDraw()
	local vs = {};
	local ts = {};
	
	--Amalgamate tables into single draw call.
	for _,v in ipairs(drawQueue) do
		for k,v2 in pairs(v[1]) do
			table.insert(vs,v2);
			table.insert(ts,v[2][k]);
		end
	end
	
	if (#vs > 0) then
		Graphics.glDraw{vertexCoords=vs,textureCoords=ts,sceneCoords=true,texture=G_VISION,primitive=Graphics.GL_TRIANGLES,priority = -60};
	end
	drawQueue = {};
end

function vision.onInitAPI()
	registerEvent(vision, "onHUDDraw", "onDraw", false);
end

local function containsStatic(tbl,val)
	for _,v in ipairs(tbl) do
		if(v == val or v == tostring(val.layerName)) then
			return true;
		end
	end
	return false;
end

local function GetConeColliderBlocks(cone, idsMap, getStatic)
	local cone_aabb = colliders.getAABB(cone.collider)
	local cx1 = cone_aabb.x
	local cy1 = cone_aabb.y
	local cx2 = cx1+cone_aabb.width
	local cy2 = cy1+cone_aabb.height
	local blocks = Block.getIntersecting(cx1, cy1, cx2, cy2)
	local j = 1;
	local newblocks = {}
	
	for i=1,#blocks do
		if(idsMap[blocks[i].id] and (not blocks[i].isHidden) and (getStatic == (cone.static and containsStatic(cone.staticObjs, blocks[i])))) then
			newblocks[j] = colliders.getHitbox(blocks[i])
			j = j + 1
		end
	end
	return newblocks
end

local function RefreshBuffer(cone, res, idsMap, section)
	buffers[cone] = {};
	blocks = GetConeColliderBlocks(cone, idsMap, true)
	
	local c = vectr.v2(cone.x,cone.y);
	
	local delta = cone.fov/(res);
	local direction = cone.direction:normalise();
	
	for i=-res/2,res/2,1 do
		local dir = direction:rotate(i*delta);
		
		local b,p;
		if(#blocks == 0) then
			b = false;
		else
			b,p,_,o = colliders.raycast(c,dir*cone.direction.length,blocks);
		end
		if(b) then
			buffers[cone][i+(res/2)+1] = {d = (p-c).length, b = false};
		else
			buffers[cone][i+(res/2)+1] = {d = cone.direction.length, b = false};
		end
	end
end

function vision.CheckCone(cone, obj, res, ids, dbg)
	if(cone == nil) then return false; end
	if(dbg == nil) then
		dbg = false;
	end
	
	-- Convert target object to hitbox
	obj = colliders.getHitbox(obj)
	
	-- Get a map for fast ID lookup
	if (ids ~= nil) then
		idsMap = {}
		for i=1,638 do
			idsMap[i] = false
		end
		for i=1,#ids do
			idsMap[ids[i]] = true
		end
	else
		idsMap = colliders.BLOCK_SOLID_MAP
	end
	
	res = res or cone.fov/10;
	res = round(res);
	
	local cam = camera
	if(not colliders.collide(cone.collider,colliders.Box(cam.x,cam.y,800,600))) then
		return false;
	end

	--player is not in the vision cone at all, so don't bother searching.
	if(not dbg and not colliders.collide(cone.collider,obj)) then
		return false;
	end
	
	if(cone.static and buffers[cone] == nil) then
		RefreshBuffer(cone,res,idsMap,obj.section);
	end
	
	--get a list of blocks in the vision cone and add the player
	local blocks = GetConeColliderBlocks(cone, idsMap, false)
	table.insert(blocks, obj)
	
	--create depth buffer
	local buffer = {};
	if(cone.static) then
	
		for k,v in pairs(buffers[cone]) do
			buffer[k] = v;
		end
	end
	local c = vectr.v2(cone.x,cone.y);
	
	local delta = cone.fov/(res*1.0);
	local direction = cone.direction:normalise();
	
	local count = 0;
	
	for i=-res/2,res/2,1 do
		local dir = direction:rotate(i*delta);
		
		count = count + 1;
		
		local b,p;
		if(#blocks == 0) then
			b = false;
		else
			b,p,_,o = colliders.raycast(c,dir*cone.direction.length,blocks);
		end
		if(b) then
			local test;
			if not pcall(function() test = o==obj; end) then
			    test = false;
			end
			local pos = p-c;
			if(buffer[i+(res/2)+1] == nil or buffer[i+(res/2)+1].d > pos.length) then
				buffer[i+(res/2)+1] = {d = pos.length, b = test};
			end
			if(not dbg and test) then
				return true;
			end
		elseif(buffer[i+(res/2)+1] == nil) then
			buffer[i+(res/2)+1] = {d = cone.direction.length, b = false};
		end
	end
	
	--[[local eyedist = 800/math.tan(cone.fov*math.pi/360);
	local theta = math.atan2(direction.y, direction.x);
	Text.print(theta,0,0)
	local ct = math.cos(-theta);
	local st = math.sin(-theta)
	
	local rmat = vectr.mat2({ct,-st},{st,ct});
	
	
	for k,v in ipairs(blocks) do
		local box = colliders.getHitbox(v);
		box:Draw();
		local ps = {};
		if(box.TYPE == 5) then --is Box
			ps[1] = vectr.v2(box.x,box.y);
			ps[2] = vectr.v2(box.x+box.width, box.y);
			ps[3] = vectr.v2(box.x+box.width, box.y+box.height);
			ps[4] = vectr.v2(box.x, box.y+box.height);
		elseif(box.TYPE == 9) then --is Tri
			local pt = box:Get(1);
			ps[1] = vectr.v2(pt[1],pt[2]);
			pt = box:Get(2);
			ps[2] = vectr.v2(pt[1],pt[2]);
			pt = box:Get(3);
			ps[3] = vectr.v2(pt[1],pt[2]);
		end
		
		local queue = {};
		for _,p in ipairs(ps) do
			local cp = rmat*(p-c);
			local z = cp..direction;
			table.insert(queue,{p = cp.y*eyedist/z, d = cp.length})
		end
	
		for i=1,#queue,1 do
			local n = i+1;
			if(n > #queue) then n = 1; end
			local p1 = queue[i].p;
			local p2 = queue[n].p;
			local d1 = queue[i].d;
			local d2 = queue[n].d;
			local ifirst = true;
			
			if(p1 > p2) then
				local tempp = p1;
				local tempd = d1;
				p1 = p2;
				d1 = d2;
				p2 = tempp;
				d2 = tempd;
				ifirst = false;
			end
			
			p1 = round(p1);
			p2 = round(p2);
			
			for j=p1,p2,1 do
				local t;

				if(p1 == p2) then
					t = 0;
				else					
					t = (j-p1)/(p2-p1);
				end
				local depth = vectr.lerp(d1,d2,t);
				if(buffer[j] == nil or buffer[j].d > depth) then
					buffer[j] = {d = depth, b = false};
				end
			end
		end
	end
	
	local bh = 32;
	for i = 1,res+1,1 do
			local y = ((res+1)-i-1)*bh;
			local col = 0x000000FF;
			if(buffer[i] ~= nil) then
				local v = 0xFF-math.max(0,math.min(math.floor(0xFF*buffer[i].d/(cone.direction.length),0xFF)));
				col = 0xFF + (v*0x100) + (v*0x10000) + (v*0x1000000);
			end
			
			Graphics.glSetTextureRGBA(nil, col);
			local pts = {};
			pts[0] = 0; pts[1] = y;
			pts[2] = 32; pts[3] = y;
			pts[4] = 0; pts[5] = y+bh;
			pts[6] = 32; pts[7] = y;
			pts[8] = 32; pts[9] = y+bh;
			pts[10] = 0; pts[11] = y+bh;
		
		Graphics.glDrawTriangles(pts, {}, 6);
			
	end]]
	--[[
	for k,v in ipairs(blocks) do
		local box = colliders.getHitbox(v);
		box:Draw();
		local ps = {};
		if(box.TYPE == 5) then --is Box
			ps[1] = vectr.v2(box.x,box.y);
			ps[2] = vectr.v2(box.x+box.width, box.y);
			ps[3] = vectr.v2(box.x+box.width, box.y+box.height);
			ps[4] = vectr.v2(box.x, box.y+box.height);
		elseif(box.TYPE == 9) then --is Tri
			local pt = box:Get(1);
			ps[1] = vectr.v2(pt[1],pt[2]);
			pt = box:Get(2);
			ps[2] = vectr.v2(pt[1],pt[2]);
			pt = box:Get(3);
			ps[3] = vectr.v2(pt[1],pt[2]);
		end
		
		
		local queue = {};
		local updir = (direction:tov3()^vectr.forward3):tov2();
		for _,p in ipairs(ps) do
			local xy = (p-c);
			local dist = (xy..direction)*direction;
			local dy = xy-dist; --Vector from screen centre to point (unprojected).
			local ddir = dy:normalise();
			local scale = (res*0.5)*dy.length/(dist.length*math.tan(cone.fov*0.00872664625));
			if (((ddir.x <= 0 and updir.x <= 0) or (ddir.x >= 0 and updir.x >= 0)) and ((ddir.y <= 0 and updir.y <= 0) or (ddir.y >=0 and updir.y >= 0))) then 
				scale = -scale;
			end; --is this point above or below the centre of the cone?
			
			table.insert(queue,{p = (res/2)+scale+1, d = xy.length})
		end
		
		for i=1,#queue,1 do
			local n = i+1;
			if(n > #queue) then n = 1; end
			local p1 = queue[i].p;
			local p2 = queue[n].p;
			local d1 = queue[i].d;
			local d2 = queue[n].d;
			local ifirst = true;
			
			if(p1 > p2) then
				local tempp = p1;
				local tempd = d1;
				p1 = p2;
				d1 = d2;
				p2 = tempp;
				d2 = tempd;
				ifirst = false;
			end
			
			p1 = round(p1);
			p2 = round(p2);
			
			for j=p1,p2,1 do
				local t;

				if(p1 == p2) then
					t = 0;
				else					
					t = (j-p1)/(p2-p1);
				end
				local depth = vectr.lerp(d1,d2,t);
				if(buffer[j] == nil or buffer[j].d > depth) then
					buffer[j] = {d = depth, b = false};
				end
			end
		end
		
	end
	
	local bh = 2;
	for i = 1,res+1,1 do
			local y = ((res+1)-i-1)*bh;
			local col = 0x000000FF;
			if(buffer[i] ~= nil) then
				local v = 0xFF-math.max(0,math.min(math.floor(0xFF*buffer[i].d/(cone.direction.length),0xFF)));
				col = 0xFF + (v*0x100) + (v*0x10000) + (v*0x1000000);
			end
			
			Graphics.glSetTextureRGBA(nil, col);
			local pts = {};
			pts[0] = 0; pts[1] = y;
			pts[2] = 32; pts[3] = y;
			pts[4] = 0; pts[5] = y+bh;
			pts[6] = 32; pts[7] = y;
			pts[8] = 32; pts[9] = y+bh;
			pts[10] = 0; pts[11] = y+bh;
		
		Graphics.glDrawTriangles(pts, {}, 6);
			
	end]]
	
		
	if(dbg) then
		local tris = {};
		local texs = {};
		local t_i = 0;
		local found;
		local prev = direction:rotate(((res+1)/2.0)*delta);
			
		for i=-res/2,res/2,1 do
			
			local dir = direction:rotate((i)*delta);
			local tb = buffer[i+(res/2)+1];
			if(tb == nil) then tb = {d=cone.direction.length,b=false}; end
			local pos = dir*tb.d;
			if(prev ~= nil) then
				tris[t_i] = c.x;
				tris[t_i+1] = c.y;
				tris[t_i+2] = c.x+prev.x;
				tris[t_i+3] = c.y+prev.y;
				tris[t_i+4] = c.x+pos.x;
				tris[t_i+5] = c.y+pos.y;
				texs[t_i] = 1;
				texs[t_i+1] = 0.5;
				texs[t_i+2] = 0;
				texs[t_i+3] = 0;
				texs[t_i+4] = 0;
				texs[t_i+5] = 0;
				t_i = t_i + 6;
			end
			if(tb.b) then
				found = true;
			end
				
			prev = pos;
			
		end
		
		table.insert(drawQueue,{tris,texs});
		return found;
		
	else
		return false;
	end
end

return vision;