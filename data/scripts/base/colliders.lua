--*********************************************--
--**   _____	  _ _  	    _				 **--
--**  / ____|	 | | (_)   | |			     **--
--** | |	 ___ | | |_  __| | ___ _ __ ___  **--
--** | |	/ _ \| | | |/ _` |/ _ \ '__/ __| **--
--** | |___| (_) | | | | (_| |  __/ |  \__ \ **--
--**  \_____\___/|_|_|_|\__,_|\___|_|  |___/ **--
--**										 **--
--*********************************************--	
--------------------Colliders--------------------								   
-------------Created by Hoeloe - 2015------------
-----Open-Source Collision Detection Library-----
--------------For Super Mario Bros X-------------
---------------------v2.1.6o---------------------
---------------REQUIRES VECTR.lua----------------
-----------REQUIRES EXPANDEDDEFINES.lua----------

local colliders = {}
local vect = require("vectr");
local blockdef = require("expandedDefines");

local TYPE_PLAYER = 1;
local TYPE_NPC = 2;
local TYPE_BLOCK = 3;
local TYPE_ANIM = 4;
local TYPE_BGO = 5;
local TYPE_BOX = 10;
local TYPE_CIRCLE = 11;
local TYPE_POINT = 12;
local TYPE_POLY = 13;
local TYPE_TRI = 14;
local TYPE_RECT = 15;
local COLLIDERS_TYPES = {
	TYPE_PLAYER, TYPE_NPC, TYPE_BLOCK, TYPE_ANIM, TYPE_BGO,
	TYPE_BOX, TYPE_RECT, TYPE_CIRCLE, TYPE_POINT, TYPE_POLY, TYPE_TRI
};
local COLLIDER_OBJ_TYPES = {
	[TYPE_PLAYER] = true, 
	[TYPE_NPC] = true, 
	[TYPE_BLOCK] = true, 
	[TYPE_ANIM] = true, 
	[TYPE_BGO] = true
};
local TYPE_NAME_MAP = {
	[TYPE_BOX] = "Box",
	[TYPE_RECT] = "Rect",
	[TYPE_CIRCLE] = "Circle",
	[TYPE_POINT] = "Point",
	[TYPE_POLY] = "Poly",
	[TYPE_TRI] = "Tri"
};

local tableinsert = table.insert;
local tableremove = table.remove;
local mathfloor = math.floor;
local mathceil = math.ceil;
local mathsin = math.sin;
local mathcos = math.cos;
local mathmin = math.min;
local mathmax = math.max;
local mathabs = math.abs;
local mathsqrt = math.sqrt;

local mathhuge = math.huge;
local mathpi = math.pi;
local deg2rad = mathpi/180;
local halfpi = mathpi/2;


colliders.debug = false;

function colliders.onInitAPI()

	colliders.BLOCK_SOLID = blockdef.BLOCK_SOLID;
	colliders.BLOCK_SEMISOLID = blockdef.BLOCK_SEMISOLID;
	colliders.BLOCK_NONSOLID = blockdef.BLOCK_NONSOLID;
	colliders.BLOCK_LAVA = blockdef.BLOCK_LAVA;
	colliders.BLOCK_HURT = blockdef.BLOCK_HURT;
	colliders.BLOCK_PLAYER = blockdef.BLOCK_PLAYER;
	
	colliders.BLOCK_SOLID_MAP = blockdef.BLOCK_SOLID_MAP;
	colliders.BLOCK_SEMISOLID_MAP = blockdef.BLOCK_SEMISOLID_MAP;
	colliders.BLOCK_NONSOLID_MAP = blockdef.BLOCK_NONSOLID_MAP;
	colliders.BLOCK_LAVA_MAP = blockdef.BLOCK_LAVA_MAP;
	colliders.BLOCK_HURT_MAP = blockdef.BLOCK_HURT_MAP;
	colliders.BLOCK_PLAYER_MAP = blockdef.BLOCK_PLAYER_MAP;

	registerEvent(colliders, "onDraw")
end

local colliderList = {};

local debugList = {};

local function colliderSetDebug(object, bool)
	if(debugList[object] ~= nil and not bool) then
		debugList[object] = nil;
	elseif(debugList[object] == nil and bool) then
		debugList[object] = object;
	end
end

local collidersTypeMetatables = {};
for _,t in ipairs(COLLIDERS_TYPES) do
	local mt = {};
	mt.__index = {
		TYPE = t,
		Debug = colliderSetDebug,
		debug = colliderSetDebug
	};
	if TYPE_NAME_MAP[t] then
		mt.__type = TYPE_NAME_MAP[t].."Collider";
	end
	collidersTypeMetatables[t] = mt;
end

do -- Declare Box methods
	local boxColor = Color.fromHexRGBA(0xFF000099);
	collidersTypeMetatables[TYPE_BOX].__index.Draw = function(obj, c)
		c = c or boxColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		Graphics.glDraw{
		vertexCoords = {
							obj.x,				obj.y,
							obj.x+obj.width,	obj.y,
							obj.x+obj.width,	obj.y+obj.height,
							obj.x,				obj.y+obj.height
					   }, 
		color = c, sceneCoords = true, primitive=Graphics.GL_TRIANGLE_FAN};
	end
	
	collidersTypeMetatables[TYPE_BOX].__index.draw = collidersTypeMetatables[TYPE_BOX].__index.Draw;
end
function colliders.Box(x,y,width,height)
	local b = { x = x, y = y, width = width, height = height };
	setmetatable(b,collidersTypeMetatables[TYPE_BOX]);
	return b;
end

do -- Declare Rect methods
	
	collidersTypeMetatables[TYPE_RECT].__index.Rotate = function(obj, angle)
		obj.rotation = obj.rotation + angle
	end
	collidersTypeMetatables[TYPE_RECT].__index.rotate = collidersTypeMetatables[TYPE_RECT].__index.Rotate;
	
	local rectColor = Color.fromHexRGBA(0xFFFF0099);
	collidersTypeMetatables[TYPE_RECT].__index.Draw = function(obj, c)
		c = c or rectColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		local w = obj.width*0.5
		local h = obj.height*0.5
		
		local r = deg2rad*obj.rotation;
		local sr = mathsin(r);
		local cr = mathcos(r);
		
		local x1,y1 = w*cr - h*sr, w*sr + h*cr;
		local x2,y2 = h*sr + w*cr, w*sr - h*cr;
		
		Graphics.glDraw{
		vertexCoords = {
							obj.x-x1,			obj.y-y1,
							obj.x-x2,			obj.y-y2,
							obj.x+x1,			obj.y+y1,
							obj.x+x2,			obj.y+y2
					   }, 
		color = c, sceneCoords = true, primitive=Graphics.GL_TRIANGLE_FAN};
	end
	
	collidersTypeMetatables[TYPE_RECT].__index.draw = collidersTypeMetatables[TYPE_RECT].__index.Draw;
end
function colliders.Rect(x,y,width,height,rotation)
	local b = { x = x, y = y, width = width, height = height, rotation = rotation or 0 };
	setmetatable(b,collidersTypeMetatables[TYPE_RECT]);
	return b;
end

local function circleToTris(obj)
		local x1 = obj.x;
		local y1 = obj.y;
		local pts = {};
		local m = mathceil(mathsqrt(obj.radius));
		if(m < 1) then m = 1; end
		local s = (halfpi)/m;
		local ind = 1;
		local xmult = 1;
		local ymult = -1;
		for n=1,4 do
			local lx = 0;
			local ly = 1;
			for i=1,m do
				local xs = mathcos((halfpi)-s*i);
				local ys = mathsin((halfpi)-s*i);
				pts[ind] = x1;
				pts[ind+1] = y1;
				pts[ind+2] = x1+xmult*obj.radius*lx;
				pts[ind+3] = y1+ymult*obj.radius*ly;
				pts[ind+4] = x1+xmult*obj.radius*xs;
				pts[ind+5] = y1+ymult*obj.radius*ys;
				ind = ind+6;
				lx = xs;
				ly = ys;
			end
			if xmult == 1 then
				if ymult == -1 then
					ymult = 1;
				elseif ymult == 1 then
					xmult = -1;
				end
			elseif xmult == -1 then
				if ymult == -1 then
					xmult = 1;
				elseif ymult == 1 then
					ymult = -1;
				end
			end
		end
		return pts;
end

do -- Declare Circle methods
	local circleColor = Color.fromHexRGBA(0xFF00FF99);
	collidersTypeMetatables[TYPE_CIRCLE].__index.Draw = function(obj, c)
		c = c or circleColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		Graphics.glDraw{vertexCoords = circleToTris(obj), color = c, sceneCoords = true};
	end
	
	collidersTypeMetatables[TYPE_CIRCLE].__index.draw = collidersTypeMetatables[TYPE_CIRCLE].__index.Draw;
end
function colliders.Circle(x,y,radius)
	local c = { x = x, y = y, radius = radius };
	setmetatable(c,collidersTypeMetatables[TYPE_CIRCLE]);
	return c;
end

do -- Declare Point methods
	local pointColor = Color.fromHexRGBA(0x0099FF99);
	collidersTypeMetatables[TYPE_POINT].__index.Draw = function(obj, c)
		c = c or pointColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		local x1,x2 = mathfloor(obj.x-0.5),mathceil(obj.x+0.5);
		local y1,y2 = mathfloor(obj.y-0.5),mathceil(obj.y+0.5);
		Graphics.glDraw{
		vertexCoords={
						x1,	y1,
						x2,	y1,
						x2,	y2,
						x1,	y2
					 },
		color = c, sceneCoords = true, primitive = Graphics.GL_TRIANGLE_FAN}
	end
	collidersTypeMetatables[TYPE_POINT].__index.draw = collidersTypeMetatables[TYPE_POINT].__index.Draw;
end
function colliders.Point(x,y)
	local p = { x = x, y = y };
	setmetatable(p,collidersTypeMetatables[TYPE_POINT]);
	return p;
end

do -- Declare Tri methods
	local triColor = Color.fromHexRGBA(0x00FF0099);
	collidersTypeMetatables[TYPE_TRI].__index.Get = function(obj, index)
		if(index < 1 or index >= 4) then
			error("Invalid triangle index.", 2);
		end
		return { obj.v[index][1]+obj.x, obj.v[index][2]+obj.y };
	end
	collidersTypeMetatables[TYPE_TRI].__index.get = collidersTypeMetatables[TYPE_TRI].__index.Get;
	
	collidersTypeMetatables[TYPE_TRI].__index.Rotate = function(obj, angle)
		local s = mathsin(deg2rad*angle);
		local c = mathcos(deg2rad*angle);
		
		local t = colliders.Tri(obj.x, obj.y, 
		{obj.v[1][1]*c - obj.v[1][2]*s, obj.v[1][1]*s + obj.v[1][2]*c},
		{obj.v[2][1]*c - obj.v[2][2]*s, obj.v[2][1]*s + obj.v[2][2]*c},
		{obj.v[3][1]*c - obj.v[3][2]*s, obj.v[3][1]*s + obj.v[3][2]*c});
		
		obj.v = t.v;
		obj.minX = t.minX;
		obj.maxX = t.maxX;
		obj.minY = t.minY;
		obj.maxY = t.maxY;
	end
	collidersTypeMetatables[TYPE_TRI].__index.rotate = collidersTypeMetatables[TYPE_TRI].__index.Rotate;
	
	collidersTypeMetatables[TYPE_TRI].__index.Translate = function(obj, x, y)
		for i=1,3 do
			obj.v[i] = {obj.v[i][1]+x, obj.v[i][2]+y};
		end
		obj.minX = obj.minX + x;
		obj.maxX = obj.maxX + x;
		obj.minY = obj.minY + y;
		obj.maxY = obj.maxY + y;
	end
	collidersTypeMetatables[TYPE_TRI].__index.translate = collidersTypeMetatables[TYPE_TRI].__index.Translate;
	
	collidersTypeMetatables[TYPE_TRI].__index.Scale = function(obj, x, y)
		y = y or x;
		for i=1,3 do
			obj.v[i] = {obj.v[i][1]*x, obj.v[i][2]*y};
		end
		
		--Reverse winding order if flipping
		if(x*y < 0) then
			local v3 = obj.v[3];
			obj.v[3] = obj.v[1];
			obj.v[1] = v3;
		end
		
		obj.minX = obj.minX*x;
		obj.maxX = obj.maxX*x;
		obj.minY = obj.minY*y;
		obj.maxY = obj.maxY*y;
		
		if(obj.minY > obj.maxY) then
			local m = obj.maxY;
			obj.maxY = obj.minY;
			obj.minY = m;
		end
		if(obj.minX > obj.maxX) then
			local m = obj.maxX;
			obj.maxX = obj.minX;
			obj.minX = m;
		end
	end
	collidersTypeMetatables[TYPE_TRI].__index.scale = collidersTypeMetatables[TYPE_TRI].__index.Scale;
	
	collidersTypeMetatables[TYPE_TRI].__index.Draw = function(obj, c)
		c = c or triColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		Graphics.glDraw{
		vertexCoords={
						obj.x+obj.v[1][1], obj.y+obj.v[1][2],
						obj.x+obj.v[2][1], obj.y+obj.v[2][2],
						obj.x+obj.v[3][1], obj.y+obj.v[3][2]
					 },
		color = c, sceneCoords = true}
	end
	collidersTypeMetatables[TYPE_TRI].__index.draw = collidersTypeMetatables[TYPE_TRI].__index.Draw;
end

--Creates a tri collider without winding order check
local function createTriFast(x,y,p1,p2,p3)
	local p = { x=x, y=y, v={p1,p2,p3} };
	
	p.minX = mathhuge;
	p.maxX = -mathhuge;
	p.minY = mathhuge;
	p.maxY = -mathhuge;
	
	for _,v in ipairs(p.v) do
		p.minX = mathmin(p.minX, v[1]);
		p.maxX = mathmax(p.maxX, v[1]);
		p.minY = mathmin(p.minY, v[2]);
		p.maxY = mathmax(p.maxY, v[2]);
	end
	
	setmetatable(p,collidersTypeMetatables[TYPE_TRI]);
	return p;
end

function colliders.Tri(x,y,p1,p2,p3)
	local p = { x=x, y=y, v={p1,p2,p3} };
	
	local winding = 0;
	for k,v in ipairs(p.v) do
		if(v[1] == nil or v[2] == nil) then
			error("Invalid polygon definition.", 2);
		end
		
		--Calculate winding order.
		local n = k+1;
		local pr = k-1;
		if(n > 3) then n = 1; end
		if(pr <= 0) then pr = 3; end
		winding = winding + (v[1]+p.v[n][1])*(v[2]-p.v[n][2]);
		
		if(p.minX == nil or v[1] < p.minX) then
			p.minX = v[1];
		end
		if(p.maxX == nil or v[1] > p.maxX) then
			p.maxX = v[1];
		end
		if(p.minY == nil or v[2] < p.minY) then
			p.minY = v[2];
		end
		if(p.maxY == nil or v[2] > p.maxY) then
			p.maxY = v[2];
		end
	end
	
	--If winding order is anticlockwise, triangulation will fail, so reverse vertex list in that case.
	if(winding > 0) then
		local pv = p.v[1];
		p.v[1] = p.v[3];
		p.v[3] = pv;
	end
	
	setmetatable(p,collidersTypeMetatables[TYPE_TRI]);
	return p;
end

local __typeStringMap = {Player=TYPE_PLAYER, Block=TYPE_BLOCK, Animation=TYPE_ANIM, NPC=TYPE_NPC, BGO=TYPE_BGO, Vector2=TYPE_POINT}
local function getType(obj)
	if(obj.TYPE ~= nil) then
		return obj.TYPE;
	end
	local t1 = obj.__type or type(obj)
	if (t1 ~= nil) then
		local t2 = __typeStringMap[t1]
		if (t2 ~= nil) then
			return t2
		end
	end
	error("Unknown collider type.", 2);
end

local function convertPoints(p)
	local a;
	local b;
	local c;
	if(p.x == nil) then
		a = p;
		b = colliders.Point(p[1],p[2]);
		c = vect.v2(p[1],p[2]);
	elseif(p._type == nil) then
		a = {p.x, p.y};
		b = p;
		c = vect.v2(p.x,p.y);
	else
		a = {p.x, p.y};
		b = colliders.Point(p.x,p.y);
		c = p;
	end
	return a,b,c;
end

local function sign(a)
	if(a == 0) then return 0;
	elseif(a > 0) then return 1;
	else return -1 end;
end

local function isLeft_internal(ax, ay, p0x, p0y, p1x, p1y)
	return ((p0x - ax) * (p1y - ay) - (p1x - ax) * (p0y - ay))
end

local function isLeft(a, p0, p1)
	return ((p0[1] - a[1]) * (p1[2] - a[2]) - (p1[1] - a[1]) * (p0[2] - a[2]));
end

local function intersect_internal(a1x, a1y, a2x, a2y, b1x, b1y, b2x, b2y)
	local l1 = isLeft_internal(b1x,b1y, b2x,b2y, a1x,a1y);
	local l2 = isLeft_internal(b1x,b1y, b2x,b2y, a2x,a2y);
	local l3 = isLeft_internal(a1x,a1y, a2x,a2y, b1x,b1y);
	local l4 = isLeft_internal(a1x,a1y, a2x,a2y, b2x,b2y);
	
	return (sign(l1) ~= sign(l2) and sign(l3) ~= sign(l4));
	
end

local function intersect(a1, a2, b1, b2)
	local l1 = isLeft(b1,b2,a1);
	local l2 = isLeft(b1,b2,a2);
	local l3 = isLeft(a1,a2,b1);
	local l4 = isLeft(a1,a2,b2);
	
	return (sign(l1) ~= sign(l2) and sign(l3) ~= sign(l4));
	
end

local function testBoxBox_internal(ax,ay,aw,ah,bx,by,bw,bh)
	return (ax < bx+bw and ax+aw > bx and ay < by+bh and ay + ah > by)
end

local function testBoxBox(a,b)
	return testBoxBox_internal(a.x,a.y,a.width,a.height,b.x,b.y,b.width,b.height);
	--return (a.x < b.x+b.width and a.x+a.width > b.x and a.y < b.y+b.height and a.y + a.height > b.y)
end

local function testBoxCircle(ta,tb)
			--local aabb = colliders.Box(tb.x-tb.radius, tb.y-tb.radius, tb.radius*2, tb.radius*2);
			
			--if(not colliders.collide(ta,aabb)) then
			if(not testBoxBox_internal(ta.x,ta.y,ta.width,ta.height,tb.x-tb.radius, tb.y-tb.radius, tb.radius*2, tb.radius*2)) then
				return false;
			end
			
			if(tb.x > ta.x and tb.x < ta.x+ta.width and tb.y > ta.y and tb.y < ta.y+ta.height) then return true; end;
			
			local vs = { vect.v2(ta.x - tb.x,ta.y - tb.y), 
						 vect.v2(ta.x+ta.width - tb.x,ta.y - tb.y),
						 vect.v2(ta.x - tb.x,ta.y+ta.height - tb.y),
						 vect.v2(ta.x+ta.width - tb.x,ta.y+ta.height - tb.y) };
						 
						 
			local rs = tb.radius*tb.radius;
			for _,v in ipairs(vs) do
				if(v.sqrlength < rs) then
					return true;
				end
			end
			
			
			return (tb.y > ta.y and tb.y < ta.y+ta.height and (mathabs(tb.x - (ta.x+ta.width)) < tb.radius or mathabs(tb.x - ta.x) < tb.radius)) or 
					(tb.x > ta.x and tb.x < ta.x+ta.width and (mathabs(tb.y - (ta.y+ta.height)) < tb.radius or mathabs(tb.y - ta.y) < tb.radius));
end


local function testBoxPoint_internal(ax,ay,aw,ah,bx,by)
			return (bx > ax and bx < ax+aw and by > ay and by < ay+ah);
end

local function testBoxPoint(a,b)
			local _,p = convertPoints(b);
			return testBoxPoint_internal(a.x,a.y,a.width,a.height,p.x,p.y);
			--return (p.x > a.x and p.x < a.x+a.width and p.y > a.y and p.y < a.y+a.height);
end

local function testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,bx,by)			
			
			local b1 = isLeft_internal(x1,y1, x2,y2, bx,by) < 0
			local b2 = isLeft_internal(x2,y2, x3,y3, bx,by) < 0
			local b3 = isLeft_internal(x3,y3, x4,y4, bx,by) < 0
			local b4 = isLeft_internal(x4,y4, x1,y1, bx,by) < 0
			
			return b1 == b2 and b2 == b3 and b3 == b4
end

local function testRectPoint(a,b)
			local _,p = convertPoints(b);
			
			local w,h = a.width*0.5, a.height*0.5
			
			local r = deg2rad*a.rotation;
			local sr = mathsin(r);
			local cr = mathcos(r);
			
			local x1,y1 = w*cr - h*sr, w*sr + h*cr;
			local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
			w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
			if(not testBoxPoint_internal(a.x-w,a.y-h,2*w, 2*h, p.x, p.y)) then
				return false;
			end
			
			local x3,y3 = a.x+x1, a.y+y1
			local x4,y4 = a.x+x2, a.y+y2
			x1,y1 = a.x-x1, a.y-y1
			x2,y2 = a.x-x2, a.y-y2
			
			return testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p.x,p.y);
end


local function testRectBox(a,b)
	local w,h = a.width*0.5, a.height*0.5
			
	local r = deg2rad*a.rotation;
	local sr = mathsin(r);
	local cr = mathcos(r);
			
	local x1,y1 = w*cr - h*sr, w*sr + h*cr;
	local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
	w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
	if(not testBoxBox_internal(a.x-w,a.y-h,2*w, 2*h, b.x, b.y, b.width, b.height)) then
		return false;
	end
	
	local x3,y3 = a.x+x1, a.y+y1
	local x4,y4 = a.x+x2, a.y+y2
	x1,y1 = a.x-x1, a.y-y1
	x2,y2 = a.x-x2, a.y-y2
	
	if (testBoxPoint_internal(b.x,b.y,b.width,b.height,x1,y1) or 
		testBoxPoint_internal(b.x,b.y,b.width,b.height,x2,y2) or 
		testBoxPoint_internal(b.x,b.y,b.width,b.height,x3,y3) or 
		testBoxPoint_internal(b.x,b.y,b.width,b.height,x4,y4)) then
		return true;
	end
	
	local p1x,p1y, p2x,p2y, p3x,p3y, p4x,p4y = b.x,b.y, b.x+b.width,b.y, b.x+b.width,b.y+b.height, b.x,b.y+b.height;
	
	if (testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p1x,p1y) or 
	    testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p2x,p2y) or 
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p3x,p3y) or 
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p4x,p4y)) then
		return true;
	end
	
	return intersect_internal(x1,y1, x2,y2, p1x,p1y, p2x,p2y) or intersect_internal(x1,y1, x2,y2, p2x,p2y, p3x,p3y) or intersect_internal(x1,y1, x2,y2, p3x,p3y, p4x,p4y) or intersect_internal(x1,y1, x2,y2, p4x,p4y, p1x,p1y) or
		   intersect_internal(x2,y2, x3,y3, p1x,p1y, p2x,p2y) or intersect_internal(x2,y2, x3,y3, p2x,p2y, p3x,p3y) or intersect_internal(x2,y2, x3,y3, p3x,p3y, p4x,p4y) or intersect_internal(x2,y2, x3,y3, p4x,p4y, p1x,p1y) or
		   intersect_internal(x3,y3, x4,y4, p1x,p1y, p2x,p2y) or intersect_internal(x3,y3, x4,y4, p2x,p2y, p3x,p3y) or intersect_internal(x3,y3, x4,y4, p3x,p3y, p4x,p4y) or intersect_internal(x3,y3, x4,y4, p4x,p4y, p1x,p1y) or
		   intersect_internal(x4,y4, x1,y1, p1x,p1y, p2x,p2y) or intersect_internal(x4,y4, x1,y1, p2x,p2y, p3x,p3y) or intersect_internal(x4,y4, x1,y1, p3x,p3y, p4x,p4y) or intersect_internal(x4,y4, x1,y1, p4x,p4y, p1x,p1y)
end


local function testCirclePoint(a,b)
			local _,p = convertPoints(b);
			return (vect.v2(a.x-p.x,a.y-p.y).length < a.radius);
end

local function testTriPoint_internal(a,p)
	if(not testBoxPoint_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, p[1], p[2])) then
		return false;
	end
	
	local p1,p2,p3 = a:Get(1), a:Get(2), a:Get(3);
	
	local b1 = (isLeft(p1, p2, p) < 0);
	local b2 = (isLeft(p2, p3, p) < 0);
	local b3 = (isLeft(p3, p1, p) < 0);
	
	--Point is on the same side of all lines
	return b1 == b2 and b1 == b3;
end

local function testTriPoint(a,b)
	--local aabb = colliders.Box(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY);
	
	local p = convertPoints(b);
	
	return testTriPoint_internal(a,p);
	
	--[[
	if(not testBoxPoint_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, c.x, c.y)) then
		return false;
	end
	
	local p1,p2,p3 = a:Get(1), a:Get(2), a:Get(3);
	
	local b1 = (isLeft(p1, p2, p) < 0);
	local b2 = (isLeft(p2, p3, p) < 0);
	local b3 = (isLeft(p3, p1, p) < 0);
	
	--Point is on the same side of all lines
	return b1 == b2 and b1 == b3;
	]]
end

local function testTriBox(a,b)
	--local aabb = colliders.Box(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY);
	
	--if(not colliders.collide(aabb,b)) then
	if(not testBoxBox_internal(b.x,b.y,b.width,b.height,a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY)) then
		return false;
	end
		
	local a1,a2,a3 = a:Get(1), a:Get(2), a:Get(3);
	
	if(testBoxPoint_internal(b.x,b.y,b.width,b.height,a1[1],a1[2]) or testBoxPoint_internal(b.x,b.y,b.width,b.height,a2[1],a2[2]) or testBoxPoint_internal(b.x,b.y,b.width,b.height,a3[1],a3[2])) then
		return true;
	end
	
	local p1,p2,p3,p4 = {b.x,b.y}, {b.x+b.width,b.y}, {b.x+b.width,b.y+b.height}, {b.x,b.y+b.height};
	
	if(testTriPoint_internal(a,p1) or testTriPoint_internal(a,p2)  or testTriPoint_internal(a,p3) or testTriPoint_internal(a,p4)) then
		return true;
	end
	
	
	return intersect(a1,a2,p1,p2) or intersect(a1,a2,p2,p3) or intersect(a1,a2,p3,p4) or intersect(a1,a2,p4,p1) or
		   intersect(a2,a3,p1,p2) or intersect(a2,a3,p2,p3) or intersect(a2,a3,p3,p4) or intersect(a2,a3,p4,p1) or
		   intersect(a3,a1,p1,p2) or intersect(a3,a1,p2,p3) or intersect(a3,a1,p3,p4) or intersect(a3,a1,p4,p1);
	
	--[[
	if(colliders.linecast(a:Get(1),a:Get(2), b) or colliders.linecast(a:Get(2), a:Get(3), b) or colliders.linecast(a:Get(3), a:Get(1), b)) then
		return true;
	else
		return false;
	end
	]]
end

local function testRectTri_internal(x1,y1,x2,y2,x3,y3,x4,y4,b)
	if (testTriPoint_internal(b, {x1,y1}) or 
		testTriPoint_internal(b, {x2,y2}) or 
		testTriPoint_internal(b, {x3,y3}) or 
		testTriPoint_internal(b, {x4,y4})) then
		return true;
	end
	
	local p1,p2,p3 = b:Get(1), b:Get(2), b:Get(3);
	
	if (testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p1[1],p1[2]) or 
	    testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p2[1],p2[2]) or 
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4,p3[1],p3[2])) then
		return true;
	end
	
	return intersect_internal(x1,y1, x2,y2, p1[1],p1[2], p2[1],p2[2]) or intersect_internal(x1,y1, x2,y2, p2[1],p2[2], p3[1],p3[2]) or intersect_internal(x1,y1, x2,y2, p3[1],p3[2], p1[1],p1[2]) or
		   intersect_internal(x2,y2, x3,y3, p1[1],p1[2], p2[1],p2[2]) or intersect_internal(x2,y2, x3,y3, p2[1],p2[2], p3[1],p3[2]) or intersect_internal(x2,y2, x3,y3, p2[1],p2[2], p3[1],p3[2]) or
		   intersect_internal(x3,y3, x4,y4, p1[1],p1[2], p2[1],p2[2]) or intersect_internal(x3,y3, x4,y4, p2[1],p2[2], p3[1],p3[2]) or intersect_internal(x3,y3, x4,y4, p2[1],p2[2], p3[1],p3[2]) or
		   intersect_internal(x4,y4, x1,y1, p1[1],p1[2], p2[1],p2[2]) or intersect_internal(x4,y4, x1,y1, p2[1],p2[2], p3[1],p3[2]) or intersect_internal(x4,y4, x1,y1, p2[1],p2[2], p3[1],p3[2])
end

local function testRectTri(a,b)
	local w,h = a.width*0.5, a.height*0.5
			
	local r = deg2rad*a.rotation;
	local sr = mathsin(r);
	local cr = mathcos(r);
			
	local x1,y1 = w*cr - h*sr, w*sr + h*cr;
	local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
	w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
	if(not testBoxBox_internal(a.x-w,a.y-h,2*w, 2*h, b.x, b.y, b.width, b.height)) then
		return false;
	end
	
	local x3,y3 = a.x+x1, a.y+y1
	local x4,y4 = a.x+x2, a.y+y2
	x1,y1 = a.x-x1, a.y-y1
	x2,y2 = a.x-x2, a.y-y2
	
	return testRectTri_internal(x1,y1,x2,y2,x3,y3,x4,y4,b)
end

local function testRectPoly(a,b)
	local w,h = a.width*0.5, a.height*0.5
			
	local r = deg2rad*a.rotation;
	local sr = mathsin(r);
	local cr = mathcos(r);
			
	local x1,y1 = w*cr - h*sr, w*sr + h*cr;
	local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
	w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
	if(not testBoxBox_internal(a.x-w,a.y-h,2*w, 2*h, b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY)) then
		return false;
	end
	
	local x3,y3 = a.x+x1, a.y+y1
	local x4,y4 = a.x+x2, a.y+y2
	x1,y1 = a.x-x1, a.y-y1
	x2,y2 = a.x-x2, a.y-y2
	
	for k,v in ipairs(b.tris) do
		v.x = b.x;
		v.y = b.y;
		if(testRectTri_internal(x1,y1,x2,y2,x3,y3,x4,y4,v)) then
			return true;
		end
	end
	return false;
end


local function testRectRect(a,b)
	local w,h = a.width*0.5, a.height*0.5
			
	local r = deg2rad*a.rotation;
	local sr = mathsin(r);
	local cr = mathcos(r);
			
	local x1,y1 = w*cr - h*sr, w*sr + h*cr;
	local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
	w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
	
	local w2,h2 = b.width*0.5, b.height*0.5
			
	r = deg2rad*b.rotation;
	sr = mathsin(r);
	cr = mathcos(r);
			
	local x12,y12 = w2*cr - h2*sr, w2*sr + h2*cr;
	local x22,y22 = h2*sr + w2*cr, w2*sr - h2*cr;
			
	w2,h2 = mathmax(mathabs(x12),mathabs(x22)), mathmax(mathabs(y12),mathabs(y22))
	if(not testBoxBox_internal(a.x-w,a.y-h,2*w, 2*h, b.x-w2,b.y-h2,2*w2, 2*h2)) then
		return false;
	end
	
	local x3,y3 = a.x+x1, a.y+y1
	local x4,y4 = a.x+x2, a.y+y2
	x1,y1 = a.x-x1, a.y-y1
	x2,y2 = a.x-x2, a.y-y2
	
	local x32,y32 = b.x+x12, b.y+y12
	local x42,y42 = b.x+x22, b.y+y22
	x12,y12 = b.x-x12, b.y-y12
	x22,y22 = b.x-x22, b.y-y22
	
	if (testRectPoint_internal(x12,y12,x22,y22,x32,y32,x42,y42, x1,y1) or 
		testRectPoint_internal(x12,y12,x22,y22,x32,y32,x42,y42, x2,y2) or 
		testRectPoint_internal(x12,y12,x22,y22,x32,y32,x42,y42, x3,y3) or 
		testRectPoint_internal(x12,y12,x22,y22,x32,y32,x42,y42, x4,y4) or
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4, x12,y12) or
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4, x22,y22) or
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4, x32,y32) or
		testRectPoint_internal(x1,y1,x2,y2,x3,y3,x4,y4, x42,y42)) then
		return true;
	end
	
	return intersect_internal(x1,y1, x2,y2, x12,y12, x22,y22) or intersect_internal(x1,y1, x2,y2, x22,y22, x32,y32) or intersect_internal(x1,y1, x2,y2, x32,y32, x42,y42) or intersect_internal(x1,y1, x2,y2, x42,y42, x12,y12) or
		   intersect_internal(x2,y2, x3,y3, x12,y12, x22,y22) or intersect_internal(x2,y2, x3,y3, x22,y22, x32,y32) or intersect_internal(x2,y2, x3,y3, x32,y32, x42,y42) or intersect_internal(x2,y2, x3,y3, x42,y42, x12,y12) or
		   intersect_internal(x3,y3, x4,y4, x12,y12, x22,y22) or intersect_internal(x3,y3, x4,y4, x22,y22, x32,y32) or intersect_internal(x3,y3, x4,y4, x32,y32, x42,y42) or intersect_internal(x3,y3, x4,y4, x42,y42, x12,y12) or
		   intersect_internal(x4,y4, x1,y1, x12,y12, x22,y22) or intersect_internal(x4,y4, x1,y1, x22,y22, x32,y32) or intersect_internal(x4,y4, x1,y1, x32,y32, x42,y42) or intersect_internal(x4,y4, x1,y1, x42,y42, x12,y12)
end

local function testRectCircle(a,b)
	local w,h = a.width*0.5, a.height*0.5
			
	local r = deg2rad*a.rotation;
	local sr = mathsin(r);
	local cr = mathcos(r);
			
	local x1,y1 = w*cr - h*sr, w*sr + h*cr;
	local x2,y2 = h*sr + w*cr, w*sr - h*cr;
			
	w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
	if(not testBoxBox_internal(a.x-w,a.y-h,2*w, 2*h, b.x-b.radius, b.y-b.radius, b.radius*2, b.radius*2)) then
		return false;
	end
	
	local x3,y3 = a.x+x1, a.y+y1
	local x4,y4 = a.x+x2, a.y+y2
	x1,y1 = a.x-x1, a.y-y1
	x2,y2 = a.x-x2, a.y-y2

	local vs = circleToTris(b);
	
	for i=1,#vs,6 do
		if(testRectTri_internal(x1,y1,x2,y2,x3,y3,x4,y4,createTriFast(0,0,{vs[i], vs[i+1]}, {vs[i+2], vs[i+3]}, {vs[i+4],vs[i+5]}))) then return true; end;
	end
	return false;
end


local function testTriTri(a,b)
	--local aabb1 = colliders.Box(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY);
	--local aabb2 = colliders.Box(b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY);
	
	--if(not testBoxBox(aabb1,aabb2)) then
	if(not testBoxBox_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY)) then
		return false;
	end
	
	local a1,a2,a3 = a:Get(1), a:Get(2), a:Get(3);
	local b1,b2,b3 = b:Get(1), b:Get(2), b:Get(3);
		
	if(testTriPoint_internal(b,a1) or testTriPoint_internal(b,a2) or testTriPoint_internal(b,a3) or
	   testTriPoint_internal(a,b1) or testTriPoint_internal(a,b2) or testTriPoint_internal(a,b3)) then
		return true;
	end
	
	return intersect(a1,a2,b1,b2) or intersect(a1,a2,b2,b3) or intersect(a1,a1,b3,b1) or
	   intersect(a2,a3,b1,b2) or intersect(a2,a3,b2,b3) or intersect(a2,a3,b3,b1) or
	   intersect(a3,a1,b1,b2) or intersect(a3,a1,b2,b3) or intersect(a3,a1,b3,b1);
		
	--[[
	if(colliders.linecast(a:Get(1),a:Get(2), b) or colliders.linecast(a:Get(2), a:Get(3), b) or colliders.linecast(a:Get(3), a:Get(1), b)) then
		return true;
	else
		return false;
	end
	]]
end

local function testTriCircle(a,b)

	if(not testBoxBox_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, b.x-b.radius, b.y-b.radius, b.radius*2, b.radius*2)) then
		return false;
	end

	local vs = circleToTris(b);
	
	for i=1,#vs,6 do
		if(testTriTri(createTriFast(0,0,{vs[i], vs[i+1]}, {vs[i+2], vs[i+3]}, {vs[i+4],vs[i+5]}), a)) then return true; end;
	end
	return false;
end

local function testTriPoly(a,b)
	--local aabb1 = colliders.Box(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY);
	--local aabb2 = colliders.Box(b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY);
	
	--if(not colliders.collide(aabb1,aabb2)) then
	if(not testBoxBox_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY)) then
		return false;
	end
	
	for k,v in ipairs(b.tris) do
		v.x = b.x;
		v.y = b.y;
		if(testTriTri(a,v)) then
			return true;
		end
	end
	return false;
end

do -- Declare Poly methods
	local polyColor = Color.fromHexRGBA(0x0000FF99);
	collidersTypeMetatables[TYPE_POLY].__index.Rotate = function(obj, angle)
		for k,v in ipairs(obj.tris) do
			v:Rotate(angle);
			if(v.minX < obj.minX) then obj.minX = v.minX; end
			if(v.maxX > obj.maxX) then obj.maxX = v.maxX; end
			if(v.minY < obj.minY) then obj.minY = v.minY; end
			if(v.maxY > obj.maxY) then obj.maxY = v.maxY; end
		end
	end
	collidersTypeMetatables[TYPE_POLY].__index.rotate = collidersTypeMetatables[TYPE_POLY].__index.Rotate;
	
	collidersTypeMetatables[TYPE_POLY].__index.Translate = function(obj, x, y)
		for k,v in ipairs(obj.tris) do
			v:Translate(x,y);
		end
		obj.minX = obj.minX + x;
		obj.maxX = obj.maxX + x;
		obj.minY = obj.minY + y;
		obj.maxY = obj.maxY + y;
	end
	collidersTypeMetatables[TYPE_POLY].__index.translate = collidersTypeMetatables[TYPE_POLY].__index.Translate;
	
	collidersTypeMetatables[TYPE_POLY].__index.Scale = function(obj, x, y)
		y = y or x;
		for k,v in ipairs(obj.tris) do
			v:Scale(x,y);
		end
		obj.minX = obj.minX*x;
		obj.maxX = obj.maxX*x;
		obj.minY = obj.minY*y;
		obj.maxY = obj.maxY*y;
		
		if(obj.minY > obj.maxY) then
			local m = obj.maxY;
			obj.maxY = obj.minY;
			obj.minY = m;
		end
		if(obj.minX > obj.maxX) then
			local m = obj.maxX;
			obj.maxX = obj.minX;
			obj.minX = m;
		end
	end
	collidersTypeMetatables[TYPE_POLY].__index.scale = collidersTypeMetatables[TYPE_POLY].__index.Scale;
	
	collidersTypeMetatables[TYPE_POLY].__index.Draw = function(obj, c)
		c = c or polyColor;
		if(type(c) == "number") then
			c = Color.fromHexRGBA(c);
		end
		
		for _,v in ipairs(obj.tris) do
			v.x = obj.x;
			v.y = obj.y;
			v:Draw(c);
		end
	end
	collidersTypeMetatables[TYPE_POLY].__index.draw = collidersTypeMetatables[TYPE_POLY].__index.Draw;
end
function colliders.Poly(x,y,...)
	local arg = {...};
	
	local p = {x=x, y=y};
	local ts = {};
	
	for _,v in ipairs(arg) do
		if(v[1] == nil or v[2] == nil) then
			error("Invalid polygon definition.", 2);
		end
		if(p.minX == nil or v[1] < p.minX) then
			p.minX = v[1];
		end
		if(p.maxX == nil or v[1] > p.maxX) then
			p.maxX = v[1];
		end
		if(p.minY == nil or v[2] < p.minY) then
			p.minY = v[2];
		end
		if(p.maxY == nil or v[2] > p.maxY) then
			p.maxY = v[2];
		end
	end
	
	local vlist;
	local winding = 0;
	
	--Calculate winding order.
	for k,v in ipairs(arg) do
		local n = k+1;
		local pr = k-1;
		if(n > #arg) then n = 1; end
		if(pr <= 0) then pr = #arg; end
		winding = winding + (v[1]+arg[n][1])*(v[2]-arg[n][2]);
	end
	
	--If winding order is anticlockwise, triangulation will fail, so reverse vertex list in that case.
	if(winding > 0) then
		vlist = {};
		local argn = #arg;
		for k,v in ipairs(arg) do
			vlist[argn - k + 1] = v;
		end
	else 
		vlist = arg;
	end
	
	local trilist = {};
	
	--Repeatedly search for and remove convex triangles (ears) from the polygon (as long as they have no other vertices inside them). When the polygon has only 3 vertices left, stop.
	while(#vlist > 3) do
		local count = #vlist;
		for k,v  in ipairs(vlist) do
			local n = k+1;
			local pr = k-1;
			if(n > #vlist) then n = 1; end
			if(pr <= 0) then pr = #vlist; end
			local lr = v[1] > vlist[pr][1] or v[2] > vlist[pr][2];
			if lr then
				lr = 1;
			else
				lr = -1;
			end
			local left = isLeft(vlist[n], vlist[pr], v);
			if(left > 0) then
				local t = colliders.Tri(0,0,vlist[pr],v,vlist[n]);
				local pointin = false;
				for k2,v2 in ipairs(vlist) do
					if(k2 ~= k and k2 ~= n and k2 ~= pr and testTriPoint(t,v2)) then
						pointin = true;
						break;
					end
				end
				if(not pointin) then
					tableinsert(trilist, t);
					tableremove(vlist,k);
					break;
				end
			elseif(left == 0) then
				tableremove(vlist,k);
				break;
			end
		end
		if(#vlist == count) then
			error("Polygon is not simple. Please remove any edges that cross over.",2);
		end
	end
	
	--Insert the final triangle to the triangle list.
	tableinsert(trilist, colliders.Tri(0,0,vlist[1],vlist[2],vlist[3]));
	
	for k,v in ipairs(trilist) do
		v.x = p.x;
		v.y = p.y;
	end
	
	p.tris = trilist;
	
	setmetatable(p,collidersTypeMetatables[TYPE_POLY])
	
	return p;
end


local function testPolyPoint(a,b)
	local _,p = convertPoints(b);
	if(p.x < a.x+a.minX or p.x > a.x+a.maxX or p.y < a.y+a.minY or p.y > a.y+a.maxY) then return false end;
	
	for k,v in ipairs(a.tris) do
		v.x = a.x;
		v.y = a.y;
		if(testTriPoint(v,b)) then
			return true;
		end
	end
	return false;
end

--Determines whether two line segments are intersecting, and returns the intersection point as a second argument.
local function intersectpoint(a1, a2, b1, b2)

	if(not intersect(a1,a2,b1,b2)) then
		return false, nil;
	end

	local div = 1/((a1[1]-a2[1])*(b1[2]-b2[2]) - (a1[2]-a2[2])*(b1[1]-b2[1]))
	local ma = a1[1]*a2[2] - a1[2]*a2[1];
	local mb = b1[1]*b2[2] - b1[2]*b2[1];
	
	local px = (ma*(b1[1]-b2[1]) - mb*(a1[1]-a2[1]))*div;
	local py = (ma*(b1[2]-b2[2]) - mb*(a1[2]-a2[2]))*div;
	
	--[[local maxxa = math.max(a1[1],a2[1]);
	local maxya = math.max(a1[2],a2[2]);
	local minxa = math.min(a1[1],a2[1]);
	local minya = math.min(a1[2],a2[2]);
	local maxxb = math.max(b1[1],b2[1]);
	local maxyb = math.max(b1[2],b2[2]);
	local minxb = math.min(b1[1],b2[1]);
	local minyb = math.min(b1[2],b2[2]);
	
	if(px > maxxa or px < minxxa or py > maxya or py < minya or
	   px > maxxb or px < minxxb or py > maxyb or py < minyb) then
		return false, vectr.zero2;
	end]]
	
	return true, vect.v2(px,py);

end

local function testPolyPoly(a,b)
	local bba = colliders.Box(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY);
	local bbb = colliders.Box(b.minX+b.x, b.minY+b.y, b.maxX-b.minX, b.maxY-b.minY);
	if(not colliders.collide(bba,bbb)) then return false; end;
	
	for k,v in ipairs(a.tris) do
		v.x = a.x;
		v.y = a.y;
		for k2,v2 in ipairs(b.tris) do
			v2.x = b.x;
			v2.y = b.y;
			if(testTriTri(v,v2)) then
				return true;
			end
		end
	end
	return false;
	
end

local function testPolyBox(a,b)
	return testTriPoly(createTriFast(b.x,b.y,{0,0},{b.width,0},{0,b.height}), a) or testTriPoly(createTriFast(b.x,b.y,{0,b.height},{b.width,0},{b.width,b.height}), a);
end

local function testPolyCircle(a,b)

	if(not testBoxBox_internal(a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY, b.x-b.radius, b.y-b.radius, b.radius*2, b.radius*2)) then
		return false;
	end

	local vs = circleToTris(b);
	
	for i=1,#vs,6 do
		if(testTriPoly(createTriFast(0,0,{vs[i], vs[i+1]}, {vs[i+2], vs[i+3]}, {vs[i+4],vs[i+5]}), a)) then return true; end;
	end
	
	return false;
end


local function linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,collider,maxSqrDist)
	if(collider[1] ~= nil) then	
		local hit;
		local norm;
		local col;
		for _,v in ipairs(collider) do
			local bl,pt,nm,_,sqrDist = linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,v,maxSqrDist);
			if(bl) then
				if (sqrDist == nil) then
					sqrDist = (pt-v1).sqrlength;
				end
				if(sqrDist < maxSqrDist) then
					maxSqrDist = sqrDist;
					hit = pt;
					norm = nm;
					col = v;
				end
			end
		end
		if(hit ~= nil) then
			return true, hit, norm, col;
		else
			return false, nil, nil, nil;
		end
	end
	
	local c = colliders.getHitbox(collider);
	
	
	local cbb = colliders.getAABB(collider);
	
	if(not colliders.collide(aabb,cbb)) then
		return false, nil, nil, nil;
	end
	
	if(sp.x == ep.x and sp.y == ep.y) then
		local b = colliders.collide(sp,c);
		if(b) then
			return true, v1, vect.zero2, collider;
		else
			return false, nil, nil, nil;
		end
	end
	
	if(colliders.collide(sp,c) and --[[or]] colliders.collide(ep,c)) then
		return true,v1,vect.zero2, collider;
	end
	
	local t = getType(c);
	--NOTE: t CANNOT be a non-primitive collider here, because getHitbox always returns a primitive collider.

	if(t == TYPE_BOX) then
		--[[return (intersect(a,b,{c.x,c.y},{c.x+c.width,c.y})
			or intersect(a,b,{c.x+c.width,c.y},{c.x+c.width,c.y+c.height})
			or intersect(a,b,{c.x+c.width,c.y+c.height},{c.x,c.y+c.height})
			or intersect(a,b,{c.x,c.y+c.height},{c.x,c.y}));--]]
			
		local hit,nm,col,p;
		local top = c.y
		local right = c.x + c.width
		local bottom = c.y + c.height
		local left = c.x
		if (dy > 0) and ((top - a[2])*(top - a[2]) < maxSqrDist) then
			col,p = intersectpoint(a,b,{left,top},{right,top}); -- Top
			if(col) then
				local sqrDist = (p-v1).sqrlength
				if (hit == nil) or (sqrDist < maxSqrDist) then
					maxSqrDist = sqrDist;
					hit = p;
					nm = -vect.up2;
				end
			end
		end
		if (dx < 0) and ((right - a[1])*(right - a[1]) < maxSqrDist) then
			col,p = intersectpoint(a,b,{right,top},{right,bottom}) -- Right
			if(col) then
				local sqrDist = (p-v1).sqrlength
				if (hit == nil) or (sqrDist < maxSqrDist) then
					maxSqrDist = sqrDist;
					hit = p;
					nm = vect.right2;
				end
			end
		end
		if (dy < 0) and ((bottom - a[2])*(bottom - a[2]) < maxSqrDist) then
			col,p = intersectpoint(a,b,{left,bottom},{right,bottom}) -- Bottom
			if(col) then
				local sqrDist = (p-v1).sqrlength
				if (hit == nil) or (sqrDist < maxSqrDist) then
					maxSqrDist = sqrDist;
					hit = p;
					nm = vect.up2;
				end
			end
		end
		if (dx > 0) and ((left - a[1])*(left - a[1]) < maxSqrDist) then
			col,p = intersectpoint(a,b,{left,top},{left,bottom}) -- Left
			if(col) then
				local sqrDist = (p-v1).sqrlength
				if (hit == nil) or (sqrDist < maxSqrDist) then
					maxSqrDist = sqrDist;
					hit = p;
					nm = -vect.right2;
				end
			end
		end
		if(hit ~= nil) then
			return true, hit, nm, collider, maxSqrDist;
		else
			return false, nil, nil, nil, nil;
		end
	elseif(t == TYPE_RECT) then
			
			local w,h = c.width*0.5, c.height*0.5
			
			local r = deg2rad*c.rotation;
			local sr = mathsin(r);
			local cr = mathcos(r);
			
			local pts = {{},{},{},{}}
			pts[1][1], pts[1][2] = w*cr - h*sr, w*sr + h*cr;
			pts[2][1], pts[2][2] = h*sr + w*cr, w*sr - h*cr;
					
			w,h = mathmax(mathabs(pts[1][1]),mathabs(pts[2][1])), mathmax(mathabs(pts[1][2]),mathabs(pts[2][2]))
			if(not testBoxBox_internal(c.x-w,c.y-h,2*w, 2*h, aabb.x, aabb.y, aabb.width, aabb.height)) then
				return false, nil, nil, nil;
			end
			
			pts[3][1],pts[3][2] = c.x+pts[1][1], c.y+pts[1][2]
			pts[4][1],pts[4][2] = c.x+pts[2][1], c.y+pts[2][2]
			pts[1][1],pts[1][2] = c.x-pts[1][1], c.y-pts[1][2]
			pts[2][1],pts[2][2] = c.x-pts[2][1], c.y-pts[2][2]
			
			local hit;
			local dir;
			
			for i=1,4,1 do
				local j = i+1;
				if(j > 4) then j = 1; end
				local col,pt = intersectpoint(a,b,pts[i],pts[j]);
				if(col and (hit == nil or (pt-v1).sqrlength < (hit-v1).sqrlength)) then
					hit = pt;
					dir = vect.v2(pts[j][1]-pts[i][1],pts[j][2]-pts[i][2]);
				end
			end
			
			if(hit ~= nil) then
				return true,hit,(dir:tov3()^vect.v3(0,0,-1)):tov2():normalise(), collider;
			else
				return false, nil, nil, nil;
			end
	elseif(t == TYPE_CIRCLE) then
		local centre = vect.v2(c.x,c.y);
		local t1 = v1-centre;
		local t2 = v2-centre;
		local drsqr = dx*dx + dy*dy;
		local D = t1.x*t2.y - t2.x*t1.y;
		local delta = c.radius*c.radius*drsqr - D*D;
		if(delta < 0) then
			return false, nil, nil, nil;
		else
			local sdy;
			if(dy < 0) then sdy=-1; else sdy = 1; end
			local rt = mathsqrt(delta);
			local qx = sdy*dx*rt;
			local qy = mathabs(dy)*rt;
			local px1 = (D*dy + qx)/drsqr;
			local px2 = (D*dy - qx)/drsqr;
			local py1 = (-D*dx + qy)/drsqr;
			local py2 = (-D*dx - qy)/drsqr;
			local p1 = vect.v2(px1,py1);
			local p2 = vect.v2(px2,py2);
			if((p2-t1).sqrlength < (p1-t1).sqrlength) then
				return true, p2+centre, (p2):normalise(), collider;
			else
				return true, p1+centre, (p1):normalise(), collider;
			end
		end
		--[[local l2 = (ep.x-sp.x)*(ep.x-sp.x) + (ep.y-sp.y)*(ep.y-sp.y);
		local p = vect.v2(c.x,c.y);
		local t = ((p-v1)..(v2-v1))/l2;
		if(t < 0) then return colliders.collide(c,sp);
		elseif(t > 1) then return colliders.collide(c,ep);
		else
			local pr = v1+((v2-v1)*t);
			return (p-pr).length <= c.radius;
		end]]
		
	elseif(t == TYPE_POINT) then
		local p = vect.v2(c.x,c.y);
		return mathabs((v2-p).length + (v1-p).length - (v2-v1).length) < 0.001, p, (v2-v1):normalise(), collider;
	elseif(t == TYPE_POLY) then
		--[[	local bb = colliders.Box(c.minX+c.x, c.minY+c.y, c.maxX-c.minX, c.maxY-c.minY);
			if(not colliders.linecast(startPoint, endPoint, bb)) then return false,nil,nil; end
			
			for k,v in ipairs(c.v) do
			local n = c.v[k+1];
			if(n == nil) then
				n = c.v[1];
			end
			n = {n[1]+c.x,n[2]+c.y};
			local m = {v[1]+c.x,v[2]+c.y};
			
			local inter,point = intersectpoint(m,n,a,b)			
			if(inter) then 
				local ray = v2-v1;
				local ln = vect.v2(n[1]-m[1],n[2]-m[2]);
				local norm = (ray:tov3()^ln:tov3()):tov2();
				return true,point,norm; 
			end
		end
		return false;]]
		local bb = colliders.Box(c.minX+c.x, c.minY+c.y, c.maxX-c.minX, c.maxY-c.minY);
		--Not valid to linecast against the AABB - will fail if we are inside the AABB but outside the actual hitbox
		if(not testBoxBox(aabb,bb)--[[not linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,bb,maxSqrDist)]]) then return false,nil,nil,nil; end
		
		local hit;
		local norm;
		
		for k,v in ipairs(c.tris) do
			local ht,pt,nm = linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,v,maxSqrDist);
			if(ht and (hit == nil or (pt-v1).sqrlength < (hit-v1).sqrlength)) then
				hit = pt;
				norm = nm;
			end
		end
		
		if(hit ~= nil) then
			return true,hit,norm, collider;
		else
			return false, nil, nil, nil;
		end
		
	elseif(t == TYPE_TRI) then
			local bb = colliders.Box(c.minX+c.x, c.minY+c.y, c.maxX-c.minX, c.maxY-c.minY);
			--Not valid to linecast against the AABB - will fail if we are inside the AABB but outside the actual hitbox
			if(not testBoxBox(aabb,bb)--[[not linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,bb,maxSqrDist)]]) then return false,nil,nil,nil; end
			
			local hit;
			local dir;
			
			for i=1,3,1 do
				local j = i+1;
				if(j > 3) then j = 1; end
				local col,pt = intersectpoint(a,b,c:Get(i),c:Get(j));
				if(col and (hit == nil or (pt-v1).sqrlength < (hit-v1).sqrlength)) then
					hit = pt;
					dir = vect.v2(c:Get(j)[1]-c:Get(i)[1],c:Get(j)[2]-c:Get(i)[2]);
				end
			end
			
			if(hit ~= nil) then
				return true,hit,(dir:tov3()^vect.v3(0,0,1)):tov2():normalise(), collider;
			else
				return false, nil, nil, nil;
			end
	else 
		return false,nil,nil, nil;
	end
end

function colliders.linecast(startPoint,endPoint,collider,dbg)
	local a,sp,v1 = convertPoints(startPoint);
	local b,ep,v2 = convertPoints(endPoint);
	local aabb = colliders.Box(mathmin(v1.x,v2.x),mathmin(v1.y,v2.y),mathabs(v2.x-v1.x),mathabs(v2.y-v1.y));
	local dx = b[1] - a[1];
	local dy = b[2] - a[2];
	if((dbg == nil or not dbg) and not colliders.debug) then
		return linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,collider,dx*dx+dy*dy);
	else
		local b,p,n,o = linecast_internal(a,sp,v1,b,ep,v2,dx,dy,aabb,collider,dx*dx+dy*dy);
		local ve = p or v2;
		local r,g;
		if(b) then
			r,g = 0,1;
		else
			r,g = 1,0;
		end
		Graphics.glDraw{vertexCoords = {v1.x,v1.y,ve.x,ve.y}, color={r,g,0,1}, sceneCoords = true, primitive = Graphics.GL_LINES}
		if(n) then
			Graphics.glDraw{vertexCoords = {ve.x,ve.y,(ve+32*n).x,(ve+32*n).y}, color={g,r,0,1}, sceneCoords = true, primitive = Graphics.GL_LINES}
		end
		return b,p,n,o;
	end
end

function colliders.raycast(startPoint,direction,collider,dbg)
	local _,_,sp = convertPoints(startPoint);
	local _,_,dir = convertPoints(direction);
	return colliders.linecast(sp,sp+dir,collider,dbg);
end

--[[
--	 /|
--	/_|
--Slope bottomleft to topright floor
local getBlockHitbox_lrslope_floor = {452,321,365,316,357,358,306,305,302,616,299,340,341,472,480,636,635,326,324,604,600,332}; 

--	|\
--	|_\
--Slope topleft to bottomright floor
local getBlockHitbox_rlslope_floor = {451,319,366,315,359,360,308,307,301,617,300,343,342,474,482,638,637,327,325,601,605,333}; 

--	|-/
--	|/
--Slope bottomleft to topright ceil	
local getBlockHitbox_lrslope_ceil = {318,367,363,364,314,313,310,479,485,328,614,613,334};
	
--	\-|
--	 \|
--Slope topleft to bottomright ceil			
local getBlockHitbox_rlslope_ceil = {317,368,361,362,312,311,309,476,486,329,77,78,335}; 
]]

--	[][]
--
--Vertical half block
local getBlockHitbox_uphalf = {289,168,69};
local getBlockHitbox_uphalf_map = table.map(getBlockHitbox_uphalf);


local function getBlockHitboxData(id, wid, hei)
	if blockdef.BLOCK_SLOPE_LR_FLOOR_MAP[id] then --Slope bottomleft to topright floor
		return 0,hei,wid,0,wid,hei
	elseif blockdef.BLOCK_SLOPE_RL_FLOOR_MAP[id] then --Slope topleft to bottomright floor
		return 0,0,wid,hei,0,hei
	elseif blockdef.BLOCK_SLOPE_LR_CEIL_MAP[id] then --Slope bottomleft to topright ceil
		return 0,0,wid,0,0,hei
	elseif blockdef.BLOCK_SLOPE_RL_CEIL_MAP[id] then --Slope topleft to bottomright ceil
		return 0,0,wid,0,wid,hei
	elseif getBlockHitbox_uphalf_map[id] then --Vertical half block
		return wid,hei/2
	else
		return wid,hei
	end
end

local function getBlockHitbox(id, x, y, wid, hei)
	local d1,d2,d3,d4,d5,d6 = getBlockHitboxData(id, wid, hei)
	if d3 then
		return colliders.Tri(x,y,{d1,d2},{d3,d4},{d5,d6})
	else
		return colliders.Box(x,y,d1,d2)
	end
end

local function getAABBData(a)
	if a.TYPE == TYPE_BOX then
		return a.x, a.y, a.width, a.height
	elseif a.TYPE == TYPE_RECT then
		
		local r = deg2rad*a.rotation;
		local sr = mathsin(r);
		local cr = mathcos(r);
		local w,h = a.width*0.5, a.height*0.5
		local x1,y1 = w*cr - h*sr, w*sr + h*cr;
		local x2,y2 = h*sr + w*cr, w*sr - h*cr;
		w,h = mathmax(mathabs(x1),mathabs(x2)), mathmax(mathabs(y1),mathabs(y2))
		return a.x-w, a.y-h, 2*w, 2*h
	elseif a.TYPE == TYPE_CIRCLE then
		return a.x - a.radius, a.y - a.radius, 2*a.radius, 2*a.radius
	elseif a.TYPE == TYPE_POINT then
		return a.x-0.5, a.y-0.5, 1, 1
	elseif a.TYPE == TYPE_TRI or a.TYPE == TYPE_POLY then
		return a.minX+a.x, a.minY+a.y, a.maxX-a.minX, a.maxY-a.minY
	end
	
	local ta = getType(a)
	
	if ta == TYPE_BLOCK then
			local d1,d2,d3,d4,d5,d6 = getBlockHitboxData(a.id, a.width, a.height)
			if d3 then
				return a.x, a.y, d3, d6
			else
				return a.x, a.y, d1, d2
			end
	elseif ta == TYPE_PLAYER then
		return a.x, a.y, a.width, a.height
	elseif ta == TYPE_NPC then
		if a:mem (0x12A, FIELD_WORD) <= 0 then
			return nil
		else
			return a.x, a.y, a.width, a.height
		end
	elseif ta == TYPE_ANIM or ta == TYPE_BGO or (a.x ~= nil and a.y ~= nil and a.width ~= nil and a.height ~= nil) then
		return a.x, a.y, a.width, a.height
	end
end

function colliders.getAABB(a)
	if a.TYPE == TYPE_BOX then
		return a
	end

	local x,y,w,h = getAABBData(a)
	if x then
		return colliders.Box(x,y,w,h)
	end
end

function colliders.getHitbox(a)
	if(a.TYPE ~= nil) then
		return a;
	end
	
	local ta = getType(a);
	
	if(ta == TYPE_BLOCK) then
		return getBlockHitbox(a.id, a.x, a.y, a.width, a.height);
	elseif(ta == TYPE_PLAYER) then
		return colliders.Box(a.x, a.y, a.width, a.height);
	elseif(ta == TYPE_NPC) then
		if(a:mem (0x12A, FIELD_WORD) <= 0) then
			return nil;
		else
			return colliders.Box(a.x, a.y, a.width, a.height);
		end
	elseif(ta == TYPE_ANIM or ta == TYPE_BGO or (a.x ~= nil and a.y ~= nil and a.width ~= nil and a.height ~= nil)) then
		return colliders.Box(a.x, a.y, a.width, a.height);
	end
end

function colliders.getSpeedHitbox(a)
	local ta = getType(a);
	
	if(a.TYPE ~= nil) then
		return a;
	end
		
	local ca = colliders.getHitbox(a);
	
	if(ca == nil) then return ca; end;
	
	if(COLLIDER_OBJ_TYPES[ta] ~= nil) then
		ca.x = ca.x + a.speedX;
		ca.y = ca.y + a.speedY;
	end
	
	return ca;
end

function colliders.bounce(a,b)
	local ta = getType(a);
	
	if(a.TYPE ~= nil) then
		error("Cannot check if an unmoving collider type (Point, Box, Circle, Tri or Poly) is bouncing!",2);
	end
	
	local ba = colliders.getHitbox(a);
	local bb = colliders.getHitbox(b);
	
	if(ba == nil or bb == nil) then return false, ta == TYPE_PLAYER and a:mem(0x50, FIELD_BOOL); end
	
	return (a.speedY >= 0 and ba.y+ba.height/2 < bb.y and (colliders.speedCollide(a,b) or colliders.collide(a,b))), ta == TYPE_PLAYER and a:mem(0x50, FIELD_BOOL);
end

function colliders.slash(a,b)
	local ta = getType(a);
	
	if(ta ~= TYPE_PLAYER) then
		error("Cannot check if a non-player is slashing!",2);
	end
	
	if(a:mem(0xF0, FIELD_WORD) ~= 5) then --player must be Link
		return false;
	end
	
	local slash = a:mem(0x14,FIELD_WORD) > 0;
	local hb = colliders.getHitbox(a);
	if(not slash or hb == nil) then return false; end;
	hb.x = hb.x + hb.width*2*a:mem(0x106,FIELD_WORD);
	hb.height = 16;
	hb.width = hb.width - 4;
	hb.y = hb.y + 8;
	
	if(a:mem(0x12E, FIELD_WORD) == -1) then
		hb.y = hb.y + 8;
	end
	
	return colliders.collide(hb,b);
end

function colliders.downSlash(a,b)
	local ta = getType(a);
	
	if(ta ~= TYPE_PLAYER) then
		error("Cannot check if a non-player is down slashing!",2);
	end
	
	if(a:mem(0xF0, FIELD_WORD) ~= 5) then --player must be Link
		return false;
	end
	
	local downslash = a:mem(0x114, FIELD_WORD) == 9; --player sprite index is down slash
	local hb = colliders.getHitbox(a);
	if(not downslash or hb == nil) then return false; end;
	hb.x = hb.x + 4
	hb.height = 20;
	hb.width = hb.width - 4;
	hb.y = hb.y + 48;
	
	return colliders.collide(hb,b);
end

function colliders.tail(a,b)
	local ta = getType(a);
	
	if(ta ~= TYPE_PLAYER) then
		error("Cannot check if a non-player is using the tanooki tail!",2);
	end
	
	local tail = a:mem(0x164,FIELD_WORD) > 0
	local hb = colliders.getHitbox(a);
	if(not tail or hb == nil) then return false; end;
	hb.x = hb.x + (hb.width-4)*a:mem(0x106,FIELD_WORD)+4;
	hb.width = 16;
	hb.y = hb.y+hb.height-20;
	hb.height = 16;
	
	return colliders.collide(hb,b);
end

function colliders.tongue(a,b)
	local ta = getType(a);
	
	if(ta ~= TYPE_PLAYER) then
		error("Cannot check if a non-player is using Yoshi's tongue!",2);
	end
	
	if(a:mem(0x108, FIELD_WORD) ~= 3) then
		return false;
	end
	
	local tongue = a:mem(0x10C,FIELD_WORD) == 1
	local tOut = a:mem(0xB6,FIELD_WORD) ~= -1
	local hb = colliders.getHitbox(a);
	if(not tongue or hb == nil) then return false; end;
	hb.x = a:mem(0xB0,FIELD_FLOAT) + ((a:mem(0xB4,FIELD_WORD) + 8) * a:mem(0x106,FIELD_WORD)) - 8;
	hb.width = 16;
	hb.height = 16;
	hb.y = hb.y + 34;
	
	if(a:mem(0x12E, FIELD_WORD) == -1) then
		hb.y = hb.y - 26;
	end
	
	return tongue and colliders.collide(hb,b);
end

function colliders.bounceResponse(a, height, playFX)
	if(height ~= nil and playFX == nil and type(height) == "boolean") then
		playFX = height;
		height = nil;
	end
	height = height or jumpheightBounce();
	height = height/1.001;
	if(playFX == nil) then playFX = true end
	local t = getType(a);
	local s = a.speedY;
	if(t == TYPE_PLAYER) then
		if(a:mem(0x50, FIELD_WORD) == -1) then --Spinjumping
			height = height / 1.2;
		end
		if(a:mem(0x50, FIELD_WORD) ~= -1 and a:mem(0x11E, FIELD_WORD) == 0) then --Not spinjumping and holding JUMP
			height = height * 1.2;
			a:mem(0x11C, FIELD_WORD, height);
		elseif(a:mem(0x50, FIELD_WORD) == -1 and a:mem(0x120, FIELD_WORD) == 0) then --Spinjumping and holding SPINJUMP
			height = height
			a:mem(0x11C, FIELD_WORD, height);
		else
			a.speedY = -20/3;
		end
	else
		a.speedY = -height;
	end
	if playFX then
		runAnimation(75, a.x, a.y+s*2, 1);
		playSFX(2);
	end
end


local function isPrimitive(ta)
	return ta == TYPE_BOX or ta == TYPE_RECT or ta == TYPE_CIRCLE or ta == TYPE_POINT or ta == TYPE_TRI or ta == TYPE_POLY;
end

function colliders.collide(a,b)
	local ta = getType(a);
	local tb = getType(b);

	if(isPrimitive(ta) and isPrimitive(tb)) then
		if(colliders.debug) then
			if a.Draw then
				a:Draw();
			end
			if b.Draw then
				b:Draw();
			end
		end
		if(ta == TYPE_BOX) then
			if(tb == TYPE_BOX) then --Check each side of both boxes
				return testBoxBox(a,b);
			elseif(tb == TYPE_RECT) then --Check rect with box
				return testRectBox(b,a);
			elseif(tb == TYPE_CIRCLE) then --Check each corner of the box with the circle
				return testBoxCircle(a,b);
			elseif(tb == TYPE_POINT) then --Check if the point is inside the box
				return testBoxPoint(a,b);
			elseif(tb == TYPE_POLY) then --Check poly with box
				return testPolyBox(b,a);
			elseif(tb == TYPE_TRI) then
				return testTriBox(b,a);
			end
		elseif(ta == TYPE_RECT) then
			if(tb == TYPE_BOX) then
				return testRectBox(a,b);
			elseif(tb == TYPE_RECT) then
				return testRectRect(a,b);
			elseif(tb == TYPE_CIRCLE) then
				return testRectCircle(a,b);
			elseif(tb == TYPE_POINT) then
				return testRectPoint(a,b);
			elseif(tb == TYPE_POLY) then
				return testRectPoly(a,b);
			elseif(tb == TYPE_TRI) then
				return testRectTri(a,b);
			end
		elseif(ta == TYPE_CIRCLE) then
			if(tb == TYPE_BOX) then --Check each corner of the box with the circle
				return testBoxCircle(b,a);
			elseif(tb == TYPE_RECT) then
				return testRectCircle(b,a);
			elseif(tb == TYPE_CIRCLE) then --Check the distance between both circles
				return (((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y)) < (a.radius + b.radius)*(a.radius + b.radius));
			elseif(tb == TYPE_POINT) then --Check if the point is inside the circle
				return testCirclePoint(a,b);
			elseif(tb == TYPE_POLY) then --Check poly with sampled circle
				return testPolyCircle(b,a);
			elseif(tb == TYPE_TRI) then
				return testTriCircle(b,a);
			end
		elseif(ta == TYPE_POINT) then
			if(tb == TYPE_BOX) then --Check each side of the box with the point
				return testBoxPoint(b,a);
			elseif(tb == TYPE_RECT) then --Check if the point is inside the rect
				return testRectPoint(b,a);
			elseif(tb == TYPE_CIRCLE) then --Check the point with the circle
				return testCirclePoint(b,a);
			elseif(tb == TYPE_POINT) then --Check if the points are the same
				return a.x == b.x and a.y == b.y;
			elseif(tb == TYPE_POLY) then --Check if the point is inside the poly
				return testPolyPoint(b,a);
			elseif(tb == TYPE_TRI) then
				return testTriPoint(b,a);
			end
		elseif(ta == TYPE_POLY) then
			if(tb == TYPE_BOX) then --Check poly with box
				return testPolyBox(a,b);
			elseif(tb == TYPE_RECT) then
				return testRectPoly(b,a);
			elseif(tb == TYPE_CIRCLE) then --Check poly with sampled circle
				return testPolyCircle(a,b);
			elseif(tb == TYPE_POINT) then --Check if the point is inside the poly
				return testPolyPoint(a,b);
			elseif(tb == TYPE_POLY) then --Check if both polys are intersecting
				return testPolyPoly(a,b);
			elseif(tb == TYPE_TRI) then
				return testTriPoly(b,a);
			end
		elseif(ta == TYPE_TRI) then
			if(tb == TYPE_BOX) then
				return testTriBox(a,b);
			elseif(tb == TYPE_RECT) then
				return testRectTri(b,a);
			elseif(tb == TYPE_CIRCLE) then
				return testTriCircle(a,b);
			elseif(tb == TYPE_POINT) then
				return testTriPoint(a,b);
			elseif(tb == TYPE_POLY) then
				return testTriPoly(a,b);
			elseif(tb == TYPE_TRI) then
				return testTriTri(a,b);
			end
		end
	else
		if(((ta == TYPE_NPC or ta == TYPE_PLAYER) and not a.isValid) or ((tb == TYPE_NPC or tb == TYPE_PLAYER) and not b.isValid)) then
			return false;
		end
		
		local ca = colliders.getHitbox(a);
		local cb = colliders.getHitbox(b);
		if(ca == nil or cb == nil) then return false; end;
		return colliders.collide(ca,cb);
	end
end

function colliders.speedCollide(a,b)
	local ta = getType(a);
	local tb = getType(b);
	
	if((a.TYPE ~= nil) and (b.TYPE ~= nil)) then
		return colliders.collide(a,b);
	end
	
	if(((ta == TYPE_NPC or ta == TYPE_PLAYER) and not a.isValid) or ((tb == TYPE_NPC or tb == TYPE_PLAYER) and not b.isValid)) then
		return false;
	end
		
	local ca = colliders.getSpeedHitbox(a);
	local cb = colliders.getSpeedHitbox(b);
	if(ca == nil or cb == nil) then return false; end;
	
	return colliders.collide(ca,cb);
end

local function nilfilter()
	return true;
end

local function safeMap(b)
	if(type(b) == "table") then
		local t = {};
		for i = 1,#b do
			t[b[i]] = true;
		end
		return t;
	else
		return {[b] = true};
	end
end

local function isdupe_npc(a,b)
	return getType(a) == TYPE_NPC and getType(b) == TYPE_NPC and a.id == b.id and a == b
end

local function getObjHitboxFast(a, box, tri)
	if a.TYPE ~= nil then
		return a
	end
	
	local ta = getType(a)
	
	if ta == TYPE_BLOCK then
			local d1,d2,d3,d4,d5,d6 = getBlockHitboxData(a.id, a.width, a.height)
			if d3 then
				tri.x, tri.y = a.x, a.y
				tri.v[1][1], tri.v[1][2] = d1, d2
				tri.v[2][1], tri.v[2][2] = d3, d4
				tri.v[3][1], tri.v[3][2] = d5, d6
				tri.minX = 0
				tri.maxX = a.width
				tri.minY = 0
				tri.maxY = a.height
				return tri
			else
				box.x, box.y, box.width, box.height = a.x, a.y, d1, d2
				return box
			end
	elseif ta == TYPE_PLAYER then
		box.x, box.y, box.width, box.height = a.x, a.y, a.width, a.height
		return box
	elseif ta == TYPE_NPC then
		if a:mem (0x12A, FIELD_WORD) <= 0 then
			return nil
		else
			box.x, box.y, box.width, box.height = a.x, a.y, a.width, a.height
			return box
		end
	elseif ta == TYPE_ANIM or ta == TYPE_BGO or (a.x ~= nil and a.y ~= nil and a.width ~= nil and a.height ~= nil) then
		box.x, box.y, box.width, box.height = a.x, a.y, a.width, a.height;
		return box
	end
end

local function getAABBFast(a, box)
	local x,y,w,h = getAABBData(a)
	if x then
		box.x,box.y,box.width,box.height = x,y,w,h
		return box
	end
end


local int_box1 = colliders.Box(0,0,0,0)
local int_box2 = colliders.Box(0,0,0,0)
local int_tri1 = colliders.Tri(0,0,{0,0},{1,0},{1,1})
local int_tri2 = colliders.Tri(0,0,{0,0},{1,0},{1,1})

local function fastObjCollide(a,b)
	local v1 = getObjHitboxFast(a, int_box1, int_tri1)
	local v2 = getObjHitboxFast(b, int_box2, int_tri2)
	if v1 and v2 then
		return colliders.collide(v1,v2)
	else
		return false
	end
end
	
local function _collideNPCInternal(a,b,sec,filter)
	local npcA = type(a) == 'number' or (a[1] ~= nil and type(a[1]) == 'number');
	local npcB = type(b) == 'number' or (b[1] ~= nil and type(b[1]) == 'number');
	local cpairs = {};
	if(filter == nil and type(sec) == "function") then 
		filter = sec;
		sec = nil;
	end
	filter = filter or nilfilter
	sec = sec or -1
	
	local aabb = colliders.Box(0,0,0,0)
	
	if(npcA and npcB) then
		local bmap = safeMap(b)
		for _,v in ipairs(NPC.get(a,sec)) do
			local hb = getAABBFast(v,aabb)
			if(hb ~= nil) then
				for _,v2 in NPC.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
					if(bmap[v2.id] and filter(v,v2) and not isdupe_npc(v,v2) and fastObjCollide(v,v2)) then
						tableinsert(cpairs,{v,v2});
					end
				end
			end
		end
	elseif(npcA and not npcB) then
		local hb = getAABBFast(b,aabb)
		local amap = safeMap(a)
		if(hb ~= nil) then
			for _,v in NPC.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
				if(amap[v.id] and filter(v) and not isdupe_npc(v,b) and fastObjCollide(v,b)) then
					tableinsert(cpairs,v)
				end
			end
		end
	elseif(not npcA and npcB) then
		local hb = getAABBFast(a,aabb)
		local bmap = safeMap(b)
		if(hb ~= nil) then
			for _,v in NPC.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
				if(bmap[v.id] and filter(v) and not isdupe_npc(v,a) and fastObjCollide(v,a)) then
					tableinsert(cpairs,v);
				end
			end
		end
	else
		cpairs = filter(a,b) and colliders.collide(a,b)
	end
	
	return cpairs;
end

local function _collideBlockInternal(a,b,sec,filter)
	local npcA = type(a) == 'number' or (a[1] ~= nil and type(a[1]) == 'number');
	local npcB = type(b) == 'number' or (b[1] ~= nil and type(b[1]) == 'number');
	local cpairs = {};
	if(filter == nil and type(sec) == "function") then 
		filter = sec;
		sec = nil;
	end
	filter = filter or nilfilter;
	sec = sec or -1;
	
	local aabb = colliders.Box(0,0,0,0)
	
	if(npcA and npcB) then
		local bmap = safeMap(b)
		for _,v in ipairs(Block.get(a,sec)) do
			local hb = getAABBFast(v,aabb)
			if(hb ~= nil) then
				for _,v2 in Block.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
					if(bmap[v2.id] and filter(v,v2) and fastObjCollide(v,v2)) then
						tableinsert(cpairs,{v,v2});
					end
				end
			end
		end
	elseif(npcA and not npcB) then
		local hb = getAABBFast(b,aabb)
		local amap = safeMap(a)
		if(hb ~= nil) then
			for _,v in Block.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
				if(amap[v.id] and filter(v) and fastObjCollide(v,b)) then
					tableinsert(cpairs,v)
				end
			end
		end
	elseif(not npcA and npcB) then
		local hb = getAABBFast(a,aabb)
		local bmap = safeMap(b);
		if(hb ~= nil) then
			for _,v in Block.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
				if(bmap[v.id] and filter(v) and fastObjCollide(v,a)) then
					tableinsert(cpairs,v)
				end
			end
		end
	else
		cpairs = filter(a,b) and colliders.collide(a,b)
	end
	
	return cpairs;
end

local function _collideNPCBlockInternal(a,b,sec,filter,swapargs)
	local idA = type(a) == 'number' or (a[1] ~= nil and type(a[1]) == 'number');
	local idB = type(b) == 'number' or (b[1] ~= nil and type(b[1]) == 'number');
	local cpairs = {};
	if(filter == nil and type(sec) == "function") then 
		filter = sec;
		sec = nil;
	end
	filter = filter or nilfilter;
	sec = sec or -1;
	
	local aabb = colliders.Box(0,0,0,0)
	
	if(idA and idB) then
		local bmap = safeMap(b)
		for _,v in ipairs(NPC.get(a,sec)) do
			local hb = getAABBFast(v,aabb)
			if(hb ~= nil) then
				for _,v2 in Block.iterateIntersecting(hb.x,hb.y,hb.x+hb.width,hb.y+hb.height) do
					local arg1,arg2 = v,v2;
					if(swapargs) then
						arg1 = v2;
						arg2 = v;
					end
					if(bmap[v2.id] and filter(arg1,arg2) and fastObjCollide(v,v2)) then
						tableinsert(cpairs,{arg1,arg2});
					end
				end
			end
		end
	elseif(idA and not idB) then
		cpairs = _collideNPCInternal(b,a,sec,filter);
	elseif(not idA and idB) then
		cpairs = _collideBlockInternal(a,b,sec,filter);
	else
		cpairs = filter(a,b) and colliders.collide(a,b)
	end
	
	return cpairs;
end

function colliders.collideNPCBlock(a,b,sec,filter)
	local c = _collideNPCBlockInternal(a,b,sec,filter,false);
	
	if(type(c) == "table") then
		return ((#c)>0),(#c),c;
	else
		local d;
		if c then
			d = 1;
		else
			d = 0;
		end
		return c,d,{};
	end
end

function colliders.collideBlock(a,b,sec,filter)
	local c = _collideBlockInternal(a,b,sec,filter);
	
	if(type(c) == "table") then
		return ((#c)>0),(#c),c;
	else
		local d;
		if c then
			d = 1;
		else
			d = 0;
		end
		return c,d,{};
	end
end

function colliders.collideNPC(a,b,sec,filter)
	local c = _collideNPCInternal(a,b,sec,filter);
	
	if(type(c) == "table") then
		return ((#c)>0),(#c),c;
	else
		local d;
		if c then
			d = 1;
		else
			d = 0;
		end
		return c,d,{};
	end
end

colliders.COLLIDER = -1;
colliders.NPC = -2;
colliders.BLOCK = -3;

local function getDefaults(t)
		if(t == colliders.COLLIDER) then
			error("Must provide a type or collider.",3);
		elseif(t == colliders.NPC) then
			return blockdef.NPC_ALL;
		elseif(t == colliders.BLOCK) then
			return blockdef.BLOCK_ALL;
		else
			error("Invalid type supplied without a supporting object list.",3)
		end
end

--0x5A = invisible (but hittable) block
colliders.FILTER_COL_NPC_DEF = function(v) return not v:mem(0x64, FIELD_BOOL) and not v.isHidden and not v.friendly; end
colliders.FILTER_COL_BLOCK_DEF = function(v) return not v.isHidden and not v:mem(0x5A, FIELD_BOOL); end

colliders.FILTER_NPC_NPC_DEF = function(v1,v2) return not v1:mem(0x64, FIELD_BOOL) and not v1.isHidden and not v1.friendly and not v2:mem(0x64, FIELD_BOOL) and not v2.isHidden and not v2.friendly; end
colliders.FILTER_NPC_BLOCK_DEF = function(v,b) return not v:mem(0x64, FIELD_BOOL) and not v.isHidden and not v.friendly and not b.isHidden and not b:mem(0x5A, FIELD_BOOL); end
colliders.FILTER_BLOCK_BLOCK_DEF = function(b1,b2) return not b1.isHidden and not b1:mem(0x5A, FIELD_BOOL) and not b2.isHidden and not b2:mem(0x5A, FIELD_BOOL); end

function colliders.getColliding(args)
	local typea = args.atype or colliders.COLLIDER;
	local typeb = args.btype or colliders.COLLIDER;
	local a = args.a;
	if(a == nil) then
		a = getDefaults(typea);
	end
	local b = args.b;
	if(b == nil) then
		b = getDefaults(typeb);
	end
	local section = args.section or -1;
	local filter = args.filter;
	
	local swapped = false;
	--Swap args to reduce duplicate code
	if(typeb == colliders.COLLIDER and typea ~= colliders.COLLIDER) then
		local swap = b;
		b = a;
		typeb = typea;
		a = swap;
		typea = colliders.COLLIDER;
		swapped = true;
	elseif(typeb == colliders.NPC and typea == colliders.BLOCK) then
		local swap = b;
		b = a;
		typeb = colliders.BLOCK;
		a = swap;
		typea = colliders.NPC;
		swapped = true;
	end
	
	if(typea == colliders.COLLIDER) then
		if(typeb == colliders.COLLIDER) then
			if(filter == nil or filter(a,b)) then
				return colliders.collide(a,b);
			else
				return false;
			end
		elseif(typeb == colliders.NPC) then
			filter = filter or colliders.FILTER_COL_NPC_DEF;
			return _collideNPCInternal(a,b,section,filter);
		elseif(typeb == colliders.BLOCK) then
			filter = filter or colliders.FILTER_COL_BLOCK_DEF;
	
			return _collideBlockInternal(a,b,section,filter);
		else
			error("Unsupported collider type b.",2);
		end
	elseif(typea == colliders.NPC) then
		if(typeb == colliders.NPC) then
			filter = filter or colliders.FILTER_NPC_NPC_DEF;
			return _collideNPCInternal(a,b,section,filter);
		elseif(typeb == colliders.BLOCK) then
			local shouldswap = false;
			if(filter ~= nil and swapped) then
				shouldswap = true;
			end
			filter = filter or colliders.FILTER_NPC_BLOCK_DEF;
			return _collideNPCBlockInternal(a,b,section,filter,shouldswap);
		else
			error("Unsupported collider type b.",2);
		end
	elseif(typea == colliders.BLOCK) then
		if(typeb == colliders.BLOCK) then
			filter = filter or colliders.FILTER_BLOCK_BLOCK_DEF;
			return _collideBlockInternal(a,b,section,filter);
		else
			error("Unsupported collider type b.",2);
		end
	else
			error("Unsupported collider type a.",2);
	end
end

function colliders.onDraw()
	for _,v in pairs(debugList) do
		v:Draw();
	end
end

do
	local function localGetColliding(args)
		args.b = self;
		args.btype = Colliders.COLLIDER;
		return Colliders.getColliding(args);
	end
	
	for _,t in ipairs(COLLIDERS_TYPES) do
		collidersTypeMetatables[t].__index.collide = colliders.collide;
		collidersTypeMetatables[t].__index.getColliding = localGetColliding;
	end

	if(not isOverworld) then
		Player.collide = colliders.collide;
		Player.getColliding = localGetColliding;
		
		Block.collide = colliders.collide;
		Block.getColliding = localGetColliding;
		
		NPC.collide = colliders.collide;
		NPC.getColliding = localGetColliding;
		
		Animation.collide = colliders.collide;
		Animation.getColliding = localGetColliding;
	end
end

return colliders;