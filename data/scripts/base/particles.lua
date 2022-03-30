--- Particle and trail rendering engine.
-- @module particles

--- Functions.
--
--@section Functions

local particles = {}
local rng = require("rng")
local colliders = require("colliders");

--GRADIENTS

local gradResolution = 512;

local function findPrevIndex(t,i)
	local ind = 1;
	for j = 1,#t.keys do
		if(t.keys[j] >= i) then
			break;
		end
		ind = t.keys[j];
	end
	return ind;
end

local function findNextIndex(t,i)
	local ind = 1;
	for j = 1,#t.keys do
		if(t.keys[j] >= i) then
			ind = t.keys[j];
			break;
		end
	end
	return ind;
end

local min = math.min;
local max = math.max;
local floor = math.floor;
local ceil = math.ceil;
local pi = math.pi;
local cos = math.cos;
local sin = math.sin;
local sqrt = math.sqrt;
local abs = math.abs;
local atan2 = math.atan2;
local rad = math.rad;

local tableinsert = table.insert;
local tableremove = table.remove;

local stringmatch = string.match;

local colour = {};

local function clampCol(r,g,b,a)
	return min(r,1), min(g,1), min(b,1), min(a,1);
end

local function fastCol(r,g,b,a)
	local c = {r=min(r, 1),g=min(g, 1),b=min(b, 1),a=min(a or 1, 1)};
	setmetatable(c,colour);
	return c;
end

local function fastColMul(t)
	local r,g,b,a = 1,1,1,1;
	for i=1,#t do
		local v = t[i];
		if(type(v) == "number") then
			r = r * v;
			g = g * v;
			b = b * v;
			a = a * v;
		else
			r = r * v.r;
			g = g * v.g;
			b = b * v.b;
			a = a * v.a;
		end
	end
	return fastCol(r,g,b,a);
end

local colormul = {1,1,1,1}
local function fastColTripleMul(x,y,z)
	if type(x) == "number" then
		for i = 1,4 do
			colormul[i] = x
		end
	else
		colormul[1] = x.r
		colormul[2] = x.g
		colormul[3] = x.b
		colormul[4] = x.a
	end
	
	if type(y) == "number" then
		for i = 1,4 do
			colormul[i] = colormul[i]*y
		end
	else
		colormul[1] = colormul[1]*y.r
		colormul[2] = colormul[2]*y.g
		colormul[3] = colormul[3]*y.b
		colormul[4] = colormul[4]*y.a
	end
	
	if type(z) == "number" then
		for i = 1,4 do
			colormul[i] = colormul[i]*z
		end
	else
		colormul[1] = colormul[1]*z.r
		colormul[2] = colormul[2]*z.g
		colormul[3] = colormul[3]*z.b
		colormul[4] = colormul[4]*z.a
	end
	
	return colormul
end

--[[
local function superfastColMul(v,r,g,b,a)
	if(type(v) == "number") then
		colormul[1] = r*v
		colormul[2] = g*v
		colormul[3] = b*v
		colormul[4] = a*v
		return r * v, g * v, b * v, a * v;
	else
		return r * v.r, g * v.g, b * v.b, a * v.a;
	end
end

local function fastColTripleMul(x,y,z)
	return superfastColMul(z,superfastColMul(y,superfastColMul(x,1,1,1,1)));
end
]]

--colour.__index = colour;
function colour.__mul(a,b)
				if(type(a) == "number") then
					return fastCol(a*b.r,a*b.g,a*b.b,a*b.a);
				elseif(type(b) == "number") then
					return fastCol(a.r*b,a.g*b,a.b*b,a.a*b);
				else
					return fastCol(a.r*b.r,a.g*b.g,a.b*b.b,a.a*b.a);
				end
			end
function colour.__add(a,b)
				if(type(a) == "number") then
					return fastCol((a+b.r),(a+b.g),(a+b.b),(a+b.a));
				elseif(type(b) == "number") then
					return fastCol((a.r+b),(a.g+b),(a.b+b),(a.a+b));
				else
					return fastCol((a.r+b.r),(a.g+b.g),(a.b+b.b),(a.a+b.a));
				end
			end

function particles.Col(r,g,b,a)
	return fastCol(r/255, g/255, b/255, a/255);
end

function particles.ColFromHexRGB(h)
	return particles.Col(floor(h/(256*256)),floor(h/256)%256,h%256,255);
end
function particles.ColFromHexRGBA(h)
	return particles.Col(floor(h/(256*256*256)),floor(h/(256*256))%256,floor(h/256)%256,h%256);
end

local gradient = {};
gradient.__index = gradient;

local function fillGradient(self, x)
	local i1 = findPrevIndex(self,x);
	local i2 = findNextIndex(self,x);
	local t1 = self.vals[i1];
	local t2 = self.vals[i2];
		
	if(t1 == nil and t2 == nil) then 
		t1 = 0; 
		t2 = 0;
		self.vals[x] = 0;
	else
		local a = 0;
		t1 = t1 or t2;
		t2 = t2 or t1;
	
		if(i2 ~= i1) then 
			a = (x-i1)/(i2-i1);
		end
		self.vals[x] = t2*a + t1*(1-a);
	end
end

--- Creates a @{Grad} object.
--@tparam table points A list of the gradient index values. Index value should be between 0 and 1.
--@tparam table vals A list of the values at each index point. Should be the same length as `points`.
--@tparam[opt=512] int resolution The gradient resolution used when generating the cache.
--@return @{Grad}
function particles.Grad(points, vals, res)
	local g = {};
	if(res == nil or res <= 0) then
		res = 512;
	end
	g.resolution = res;
	g.keys = {};
	g.vals = {};
	for i = 1,#points do
		g.vals[floor(points[i]*res)] = vals[i];
		tableinsert(g.keys,floor(points[i]*res))
	end
	
	--Fill gradient buffer - turns out this is just generally better for the compiler than doing it on the fly.
	for i = 1,res do
		fillGradient(g,i);
	end
	
	setmetatable(g,gradient);
	return g;
end

---A Gradient object
--@type Grad

---Gets the value of the gadient at a given index. Equivalent to `myGrad(x)`.
--@function Grad:get
--@tparam number x
function gradient:get(x)
	return self.vals[floor(min(max(x,0),1)*self.resolution)];
end

--[[ --Old gradient get function - JIT really struggled with the first conditional branch.
function gradient.get(self, x)
	x = min(max(floor(x*self.resolution),0),self.resolution);
	if(self.vals[x] == nil) then
		local i1 = findPrevIndex(self,x);
		local i2 = findNextIndex(self,x);
		local t1 = self.vals[i1];
		local t2 = self.vals[i2];
		
		if(t1 == nil and t2 == nil) then 
			t1 = 0; 
			t2 = 0;
			self.vals[x] = 0;
		else
			local a = 0;
			t1 = t1 or t2;
			t2 = t2 or t1;
		
			if(i2 ~= i1) then 
				a = (x-i1)/(i2-i1);
			end
			self.vals[x] = t2*a + t1*(1-a);
		end
	end
	return self.vals[x];
end
]]

gradient.__call = gradient.get;

--FORCEFIELDS

local pointField = {};
pointField.__index = pointField;

local function nullFalloff(x)
	return x*x;
end

---A point source force field.
--@type PointField

---Gets the strength of a point field at a given location, returning both x and y components of the force.
--@function PointField:get
--@tparam number x
--@tparam number y
--@return number,number
function pointField:get(x,y)
	
	local dx = x-self.x;
	local dy = y-self.y;
	local m = sqrt(dx*dx + dy*dy);
	local d = m/self.radius;
	if(d > 1) then
		return 0,0;
	end
	local mag = self.falloff(1-d)*self.strength;
	return -dx*mag/m,-dy*mag/m;
end

local function removeByValue(tbl, value)
	for k, v in ipairs(tbl) do
		if v == value then
			tableremove(tbl, k)
			break
		end
	end
end

local function setForcefieldForEmitter(emitter, field, attract)
	local oldattract = emitter.forcefields[field];
	
	-- Remove from old lists if present
	if (oldattract == false) and (attract ~= false) then
		removeByValue(emitter.forcefieldRepulsors, field);
	end
	if (oldattract == true) and (attract ~= true) then
		removeByValue(emitter.forcefieldAttractors, field);
	end
	
	-- Insert in new lists if applicable
	if (attract == true) and (oldattract ~= true) then
		tableinsert(emitter.forcefieldAttractors, field);
	end
	if (attract == false) and (oldattract ~= false) then
		tableinsert(emitter.forcefieldRepulsors, field);
	end
	
	emitter.forcefields[field] = attract;
end

---Adds an @{Emitter} to the force field, allowing the field to affect the particles produced by it.
--@function PointField:addEmitter
--@tparam Emitter emitter The emitter to add.
--@tparam[opt=true] bool attract Whether this force field should attract or repel these particles.
function pointField:addEmitter(emitter,attract)
	attract = (attract == nil) or attract;
	setForcefieldForEmitter(emitter, self, attract)
end

---Removes an @{Emitter} from the force field, preventing the field from affecting the particles produced by it.
--@function PointField:removeEmitter
--@tparam Emitter emitter The emitter to remove.
function pointField:removeEmitter(emitter)
	setForcefieldForEmitter(emitter, self, nil)
end

--- Functions.
--
--@section Functions

--- Creates a @{PointField} object.
--@tparam number x The x coordinate of the centre of the field.
--@tparam number y The y coordinate of the centre of the field.
--@tparam number radius The radius of the field.
--@tparam[opt=1] number strength A strength multiplier for the field.
--@tparam[opt] function falloff The falloff function for this field, of the form `function(x) return y end`. By default, this is x squared falloff.
--@return @{PointField}
function particles.PointField(x,y,radius,strength,falloff)
	local f = {x=x,y=y,radius=radius,strength=strength or 1,falloff=falloff or nullFalloff}
	setmetatable(f,pointField);
	return f;
end

local lineField = {};
lineField.__index = lineField;

---A line source force field.
--@type LineField

---Gets the strength of a line field at a given location, returning both x and y components of the force.
--@function LineField:get
--@tparam number x
--@tparam number y
--@return number,number
function lineField:get(x,y)
	
	local dx = self.x2-self.x1;
	local dy = self.y2-self.y1;
	local l = dx*dx + dy*dy;
	local xd = 0;
	local yd = 0;
	if(l == 0) then
		xd = x-self.x1;
		yd = y-self.y1;
	else
		local t = ((x-self.x1)*(self.x2-self.x1) + (y-self.y1)*(self.y2-self.y1))/l;
		if(t < 0) then
			xd = x-self.x1;
			yd = y-self.y1;
		elseif(t > 1) then
			xd = x-self.x2;
			yd = y-self.y2;
		else
			local px = self.x1 + t*(self.x2-self.x1);
			local py = self.y1 + t*(self.y2-self.y1);
			xd = x-px;
			yd = y-py;
		end
	end
	local m = sqrt(xd*xd + yd*yd);
	local d = m/self.radius;
	if(d > 1) then
		return 0,0;
	end
	local mag = self.falloff(1-d)*self.strength;
	return -xd*mag/m,-yd*mag/m;
end

---Adds an @{Emitter} to the force field, allowing the field to affect the particles produced by it.
--@function LineField:addEmitter
--@tparam Emitter emitter The emitter to add.
--@tparam[opt=true] bool attract Whether this force field should attract or repel these particles.
function lineField:addEmitter(emitter,attract)
	attract = (attract == nil) or attract;
	setForcefieldForEmitter(emitter, self, attract)
end

---Removes an @{Emitter} from the force field, preventing the field from affecting the particles produced by it.
--@function LineField:removeEmitter
--@tparam Emitter emitter The emitter to remove.
function lineField:removeEmitter(emitter)
	setForcefieldForEmitter(emitter, self, nil)
end

--- Functions.
--
--@section Functions

--- Creates a @{LineField} object.
--@tparam number x1 The x coordinate of the start of the field.
--@tparam number y1 The y coordinate of the start of the field.
--@tparam number x2 The x coordinate of the end of the field.
--@tparam number y2 The y coordinate of the end of the field.
--@tparam number radius The radius of the field.
--@tparam[opt=1] number strength A strength multiplier for the field.
--@tparam[opt] function falloff The falloff function for this field, of the form `function(x) return y end`. By default, this is x squared falloff.
--@return @{LineField}
function particles.LineField(x1,y1,x2,y2,radius,strength,falloff)
	local f = {x1=x1,y1=y1,x2=x2,y2=y2,radius=radius,strength=strength or 1,falloff=falloff or nullFalloff}
	setmetatable(f,lineField);
	return f;
end

--EMITTERS

local emitter = {};
function emitter.__index(tbl, k)
	if k == "isValid" then
		return true
	else
		return emitter[k]
	end
end

local parseValue;

local function parseRange(val,stack)
	if(val == nil) then
		return nil;
	elseif(tonumber(val) ~= nil) then
		return tonumber(val),tonumber(val);
	elseif(stack[val] ~= nil) then
		return parseRange(stack[val],stack);
	else
		local m1,m2 = stringmatch(val,"^%s*(.-)%s*:%s*(.-)%s*$");
		m1 = parseValue(m1,stack);
		m2 = parseValue(m2,stack);
		local low = min(m1,m2);
		local high = max(m1,m2);
		return low,high;
	end
end

local function parseGrad(val)
	if(val == nil) then return default;
	elseif (type(val) == "function" or val.get ~= nil) then return val;
	else return nil end
end

local function nullScale()
	return 1;
end

local nullcol = {};
setmetatable(nullcol, {__index = function(tbl,k) return 1; end, __newindex = function(tbl,k,v) end});

local function nullColour()
	return nullcol;
end

local function linScale(x)
	return x;
end

local keywords = {"rate","width","height","limit","xOffset","yOffset","texture","col","rotation","scale","lifetime","speedX","speedY","radSpeed","startFrame","accelX","accelY","speedTime","speedXTime","speedYTime","rotSpeed","scaleTime","framesX","framesY","frameSpeed","rotSpeedTime","boundleft","boundright","boundtop","boundbottom","despawnTime","collision","collisionType","bounceEnergy","speedScale","rotSpeedScale","speedXScale","speedYScale","colTime","blend","space","updateType","targetX","targetY","targetTime","radOffset","maxAngle","colLength","scaleType","ribbonType","scaleLength"}

local function contains(t,val)
	for _,v in ipairs(t) do
		if(v == val) then
			return true;
		end
	end
	return false;
end

local function split(s, x)
	local r = {};
	i = 1;
	for v in string.gmatch(s,"([^"..x.."]+)") do
		r[i] = v;
		i = i + 1;
	end
	return r;
end

local function cloneTable(tbl)
	local c = {}
	for k,v in pairs(tbl) do
		c[k] = v;
	end
	return c;
end

local emitterDefs = {}
local emitterStacks = {}

local function parseList(list,stack)
	local r = split(string.gsub(list, "%s+", ""),",");
	for k,v in ipairs(r) do
		r[k] = parseValue(v,stack);
	end
	return r;
end

local collisionEnum = {none=0,stop=1,bounce=2,kill=3}
local collisionType = {coarse=0,fine=1}
local blendEnum = {alpha=0,additive=1}
local spaceEnum = {world=0}
spaceEnum["local"] = 1;
local updateEnum = {seconds=0,frames=1}

--Ribbon only
local scaleEnum = {center=0,centre=0,top=1,bottom=2}
local ribbonEnum = {disjoint=0,continuous=1}


local collisionEnumList = table.unmap(collisionEnum);
local collisionTypeList = table.unmap(collisionType);
local blendEnumList = table.unmap(blendEnum);
local spaceEnumList = table.unmap(spaceEnum);
local updateEnumList = table.unmap(updateEnum);
local scaleEnumList = table.unmap(scaleEnum);
local ribbonEnumList = table.unmap(ribbonEnum);


local function isEnum(s,elist)
	for _,v in ipairs(elist) do
		if(stringmatch(s,"^%s*"..v.."%s*$")) then
			return true;
		end
	end
	return false;
end

local function trim(s)
	return s:match("^%s*(.-)%s*$");
end

local function parseCol(v,stack)
	if(v ~= nil and v.r ~= nil) then
		return v;
	end
	if(stack[v] ~= nil) then
		return parseCol(stack[v],stack);
	end
	if(type(v) == "number") then
		return particles.ColFromHexRGBA(v);
	end
	local r,g,b,a = stringmatch(v,"^%s*0x([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])%s*$");
	if(a == nil) then
		r,g,b = stringmatch(v,"^%s*0x([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])%s*$");
		a = "FF";
	end
	if(r == nil and tonumber(v) ~= nil) then
		return particles.ColFromHexRGBA(v);
	elseif(r ~= nil) then
		return particles.Col(tonumber("0x"..r),tonumber("0x"..g),tonumber("0x"..b),tonumber("0x"..a))
	end
end

function parseValue(l,stack)
	if(type(l) ~= "string") then --Already parsed
		return l;
	elseif(stringmatch(l,"^%s*0x[0-9a-fA-F]-%s*$")) then --Colour
		return parseCol(l,stack);
	elseif(tonumber(l) ~= nil) then --Basic number
		return tonumber(l);
	elseif(stack[l] ~= nil) then --Variable
		return parseValue(stack[l],stack);
	elseif(stringmatch(l,"^%s*0x[0-9a-fA-F]-%s*:%s*0x[0-9a-fA-F]-%s*$")) then --Colour Range
			local frst,scnd = stringmatch(l, "^%s*(0x[0-9a-fA-F]+)%s*:%s*(0x[0-9a-fA-F]+)%s*$");
			if(frst == nil) then
				frst = l;
			end			
			local a = parseCol(frst,stack);
			if(scnd ~= nil) then
				return {a,parseCol(scnd,stack)};
			else
				return a;
			end
	elseif(stringmatch(l, "^%s*.-%s*:%s*.-%s*$")) then --Numerical Range
		return {parseRange(l,stack)};
	elseif(stringmatch(l,"^%s*{[^}]*}%s*$")) then --List
		local lst = stringmatch(l, "^%s*{(.-)}%s*$")
		if(lst ~= nil) then
			local vs = parseList(lst,stack);
			for k,v in ipairs(vs) do
				vs[k] = parseValue(v,stack)
			end
			vs[0] = true; --Is a discrete list
			return vs;
		else
			error("Syntax Error: Invalid list definition: "..tostring(l));
		end
	elseif(stringmatch(l,"^%s*{.+}%s*,%s*{.+}%s*$")) then --Gradient
		local pts,vals = stringmatch(l,"^%s*{(.+)}%s*,%s*{(.+)}%s*$");
		pts = parseList(pts,stack);
		for k,v in ipairs(pts) do
			pts[k] = tonumber(v);
			if(pts[k] == nil) then
				error("Invalid gradient definition: "..l,2);
			end
		end
		
		vals = parseList(vals,stack);
		
		return parseGrad(particles.Grad(pts,vals));
	elseif(stringmatch(l,"^%s*{.+}%s*,%s*{.+}%s*,%s*%d+%s*$")) then --Gradient with Resolution
		local pts,vals,res = stringmatch(l,"^%s*{(.+)}%s*,%s*{(.+)}%s*,%s*(%d+)%s*$");
		pts = parseList(pts,stack);
		for k,v in ipairs(pts) do
			pts[k] = tonumber(v);
			if(pts[k] == nil) then
				error("Invalid gradient definition: "..l,2);
			end
		end
		
		vals = parseList(vals,stack);
		
		res = tonumber(res);
		if(res == nil) then
			error("Invalid gradient definition: "..l,2);
		end
		
		return parseGrad(particles.Grad(pts,vals,res));
	elseif(stringmatch(l, "^[%w%p%s%c]+%.[%w%p%s%c]+$")) then --Image
		local f = Misc.multiResolveFile(l, "particles/"..l, "graphics/particles/"..l);
		return Graphics.loadImage(f);
	elseif(isEnum(l,collisionEnumList) or isEnum(l,collisionTypeList) or isEnum(l,blendEnumList) or isEnum(l,spaceEnumList) or isEnum(l,updateEnumList) or --[[Ribbon only]] isEnum(l,ribbonEnumList) or isEnum(l,scaleEnumList)) then --Enum
		return l;
	else
		error("Syntax Error: Invalid statement: "..tostring(l),2);
	end
end

local function parseLine(l,stack,r)
	l = stringmatch(l, "^(.-)%-%-.*$") or l;
	if(l == nil) then return end;
	local k,v = stringmatch(l, "^%s*(.-)%s*=%s*(.-)%s*$");
	if(v == nil) then return end;
	if(contains(keywords,k)) then
		r[k] = parseValue(v,stack);
		stack[k] = r[k];
	else
		stack[k] = parseValue(v,stack);
	end
end

---Loads a set of particle properties from a particle descriptor file (usually .ini). Returns two tables, the first containing the parsed values, and the second containing a stack of variables. The first table can be fed into `particles.Emitter` or `particles.Ribbon`.
--@tparam string path The full path to the descriptor file.
--@return table,table
--@see Emitter
--@see Ribbon
function particles.loadEmitterProperties(path)	
	local f;
	
	if(not path:match("^%a:")) then
		if(isOverworld) then
			path = Misc.episodePath()..path;
		else
			path = Level.folderPath()..path;
		end
	end
	
	local lines = io.readFileLines(path)
	if(lines == nil) then
		error("Could not open particle descriptor file "..tostring(path),3);
	else
		local stack = {}
		local result = {};
		for _,l in ipairs(lines) do
			parseLine(l,stack,result);
		end
		return result,stack;
	end
end

local function parseFile(p)
		if(emitterDefs[p] == nil) then
			emitterDefs[p],emitterStacks[p] = particles.loadEmitterProperties(p);
		end
		return cloneTable(emitterDefs[p]),emitterStacks[p];
end

local paramDefaultMaps = {}
do --define Default maps

	local function def_width(p)
			if(p.texture == nil) then
				return 32;
			else
				return p.texture.width/p.framesX;
			end
		end
		
		
	local function def_height(p)
				if(p.texture == nil) then
					return 32;
				else
					return p.texture.height/p.framesY;
				end
		end
		
	local function def_boundleft(p) return (min(p.minX,min(p.minX+((p.minSpeedX-p.maxRadSpeed)*p.maxLife), p.minX+((p.minSpeedX-p.maxRadSpeed)+(p.minAccelX*p.maxLife))*p.maxLife))-p.maxWidth*p.maxScale)-p.maxRadius; end
	local function def_boundright(p) return (max(p.maxX,max(p.maxX+((p.maxSpeedX+p.maxRadSpeed)*p.maxLife), p.maxX+((p.maxSpeedX+p.maxRadSpeed)+(p.maxAccelX*p.maxLife))*p.maxLife))+p.maxWidth*p.maxScale)+p.maxRadius; end;
	local function def_boundtop(p) return (min(p.minY,min(p.minY+((p.minSpeedY-p.maxRadSpeed)*p.maxLife), p.minY+((p.minSpeedY-p.maxRadSpeed)+(p.minAccelY*p.maxLife))*p.maxLife))-p.maxHeight*p.maxScale)-p.maxRadius; end;
	local function def_boundbottom(p) return (max(p.maxY,max(p.maxY+((p.maxSpeedY+p.maxRadSpeed)*p.maxLife), p.maxY+((p.maxSpeedY+p.maxRadSpeed)+(p.maxAccelY*p.maxLife))*p.maxLife))+p.maxHeight*p.maxScale)+p.maxRadius; end;


	paramDefaultMaps["rate"] = 1;
	paramDefaultMaps["xOffset"] = 0;
	paramDefaultMaps["yOffset"] = 0;
	paramDefaultMaps["framesX"] = 1;
	paramDefaultMaps["framesY"] = 1;
	paramDefaultMaps["frameSpeed"] = 8;
	paramDefaultMaps["startFrame"] = 0;
	paramDefaultMaps["collision"] = collisionEnum.none;
	paramDefaultMaps["collisionType"] = collisionType.fine;
	paramDefaultMaps["bounceEnergy"] = 0.5;
	paramDefaultMaps["texture"] = nil;
	paramDefaultMaps["col"] = particles.Col(255,255,255,255);
	paramDefaultMaps["scale"] = 1;
	paramDefaultMaps["lifetime"] = 1;
	paramDefaultMaps["speedX"] = 0;
	paramDefaultMaps["speedY"] = 0;
	paramDefaultMaps["radSpeed"] = 0;
	paramDefaultMaps["accelX"] = 0;
	paramDefaultMaps["accelY"] = 0;
	paramDefaultMaps["rotation"] = 0;
	paramDefaultMaps["rotSpeed"] = 0;
	paramDefaultMaps["limit"] = 500;
	paramDefaultMaps["despawnTime"] = 180;
	paramDefaultMaps["targetX"] = nil;
	paramDefaultMaps["targetY"] = nil;
	paramDefaultMaps["radOffset"] = 0;
	paramDefaultMaps["blend"] = blendEnum.alpha;
	paramDefaultMaps["space"] = spaceEnum.world;
	paramDefaultMaps["updateType"] = updateEnum.seconds;
	paramDefaultMaps["width"] = def_width;
	paramDefaultMaps["height"] = def_height;
	paramDefaultMaps["boundleft"] = def_boundleft;
	paramDefaultMaps["boundright"] = def_boundright;
	paramDefaultMaps["boundtop"] = def_boundtop;
	paramDefaultMaps["boundbottom"] = def_boundbottom;

	--Ribbon only

	paramDefaultMaps["maxAngle"] = 60;
	paramDefaultMaps["scaleType"] = scaleEnum.centre;
	paramDefaultMaps["ribbonType"] = ribbonEnum.continuous;
end
	
local paramRangeMaps = {}
do --define Range maps
	paramRangeMaps["rate"] = {"minRate","maxRate"}
	paramRangeMaps["bounceEnergy"] = {"minBounce", "maxBounce"}
	paramRangeMaps["width"] = {"minWidth", "maxWidth"}
	paramRangeMaps["height"] = {"minHeight", "maxHeight"}
	paramRangeMaps["scale"] = {"minScale", "maxScale"}
	paramRangeMaps["startFrame"] = {"minStartFrame", "maxStartFrame"}
	paramRangeMaps["lifetime"] = {"minLife", "maxLife"}
	paramRangeMaps["speedX"] = {"minSpeedX", "maxSpeedX"}
	paramRangeMaps["speedY"] = {"minSpeedY", "maxSpeedY"}
	paramRangeMaps["radSpeed"] = {"minRadSpeed", "maxRadSpeed"}
	paramRangeMaps["accelX"] = {"minAccelX", "maxAccelX"}
	paramRangeMaps["accelY"] = {"minAccelY", "maxAccelY"}
	paramRangeMaps["rotation"] = {"minRot", "maxRot"}
	paramRangeMaps["rotSpeed"] = {"minRotSpd", "maxRotSpd"}
	paramRangeMaps["frameSpeed"] = {"minFrameSpd", "maxFrameSpd"}
	paramRangeMaps["xOffset"] = {"minX", "maxX"}
	paramRangeMaps["yOffset"] = {"minY", "maxY"}
	paramRangeMaps["targetX"] = {"minTargetX","maxTargetX"}
	paramRangeMaps["targetY"] = {"minTargetY","maxTargetY"}
	paramRangeMaps["radOffset"] = {"minRadius","maxRadius"}
end
local paramGradMaps = {}
do --define Gradient maps
	paramGradMaps["scaleTime"] = nullScale;
	paramGradMaps["speedXTime"] = nullScale;
	paramGradMaps["speedYTime"] = nullScale;
	paramGradMaps["speedTime"] = nullScale;
	paramGradMaps["rotSpeedTime"] = nullScale;
	paramGradMaps["targetTime"] = linScale;
	paramGradMaps["speedScale"] = nullScale;
	paramGradMaps["speedXScale"] = nullScale;
	paramGradMaps["speedYScale"] = nullScale;
	paramGradMaps["rotSpeedScale"] = nullScale;
	paramGradMaps["colTime"] = nullColour;
	paramGradMaps["colScale"] = nullColour;

	--Ribbon only
	paramGradMaps["colLength"] = nullColour;
	paramGradMaps["scaleLength"] = nullScale;
end

local paramColMaps = {}
do --define Colour maps
	paramColMaps["col"] = {"minCol","maxCol"};
end

local paramEnumMaps = {}
do --define Enum maps
	paramEnumMaps["collision"] = collisionEnum;
	paramEnumMaps["collisionType"] = collisionType;
	paramEnumMaps["blend"] = blendEnum;
	paramEnumMaps["space"] = spaceEnum;
	paramEnumMaps["updateType"] = updateEnum;

	--Ribbon only
	paramEnumMaps["scaleType"] = scaleEnum;
	paramEnumMaps["ribbonType"] = ribbonEnum;
end



local nullMeta = {}
function nullMeta.__index(tb,k) 
	if k == "isValid" then
		return false
	end
	error("Cannot access a destroyed particle system.",2) 
end
function nullMeta.__newindex(tb,k,v) error("Cannot access a destroyed particle system.",2) end


local tris = {};
local txs = {};
local cols = {};


local function clearTables(p,i)
	for j=#tris[p],i,-1 do
		tableremove(tris[p],j);
		tableremove(txs[p],j);
		tableremove(cols[p],j*2);
		tableremove(cols[p],(j*2)-1);
	end
end

do --Emitter Functions

	---Creates a particle @{Emitter}.
	--@function Emitter
	--@tparam number x The x coordinate of the emitter.
	--@tparam number y The y coordinate of the emitter.
	--@tparam string source The path to a particle descriptor file (usually .ini).
	--@tparam[opt=0] number prewarm The amount of time to "prewarm" the emitter for.
	--@return @{Emitter}

	---Creates a particle @{Emitter}.
	--@tparam number x The x coordinate of the emitter.
	--@tparam number y The y coordinate of the emitter.
	--@tparam table source A table containing particle properties.
	--@tparam[opt=0] number prewarm The amount of time to "prewarm" the emitter for.
	--@return @{Emitter}
	function particles.Emitter(x,y,source,prewarm)
		local p;
		local s;
		
		if(type(source) == "table") then
			p = source;
			s = {};
		else
			p,s = parseFile(source);
		end
		setmetatable(p,emitter);
		
		p.x = x;
		p.y = y;
		p.prewarm = prewarm or 0;
		p.prewarm = tonumber(p.prewarm)
		p.initPrewarm = p.prewarm;
		p.hasPrewarmed = false;
		
		p.forcefields = {};
		p.forcefieldAttractors = {};
		p.forcefieldRepulsors = {};
		
		p.enabled = true;
		p:setParam("despawnTime",p.despawnTime,s)
		p.despawnCount = p.despawnTime;
		
		p:setParam("col",p.col,s)
		p:setParam("limit",p.limit,s)
		p:setParam("bounceEnergy",p.bounceEnergy,s);
		p:setParam("rate",p.rate,s);
		p:setParam("xOffset",p.xOffset,s);
		p:setParam("yOffset",p.yOffset,s);
		p:setParam("framesX",p.framesX,s);
		p:setParam("framesY",p.framesY,s);
		p:setParam("startFrame",p.startFrame,s);
		p:setParam("radOffset",p.radOffset,s);
		
		p:setParam("width",p.width,s);
		p:setParam("height",p.height,s);
		p:setParam("scale",p.scale,s);
		
		p:setParam("lifetime",p.lifetime,s);
		
		p:setParam("speedX",p.speedX,s);
		p:setParam("speedY",p.speedY,s);
		
		p:setParam("radSpeed",p.radSpeed,s);
		
		p:setParam("accelX",p.accelX,s);
		p:setParam("accelY",p.accelY,s);
		
		p:setParam("targetX",p.targetX,s);
		p:setParam("targetY",p.targetY,s);
		
		p:setParam("rotation",p.rotation,s);
		
		p:setParam("rotSpeed",p.rotSpeed,s);
		
		p:setParam("frameSpeed",p.frameSpeed,s);
		
		p:setParam("scaleTime",p.scaleTime,s);
		
		p:setParam("speedXTime",p.speedXTime,s);
		p:setParam("speedYTime",p.speedYTime,s);
		p:setParam("speedTime",p.speedTime,s);
		
		if(p.targetX ~= nil) then
			p:setParam("speedTime",nil);
			p:setParam("speedXTime",nil);
			p:setParam("speedX",nil);
			p:setParam("accelX",nil);
		end
		
		if(p.targetY ~= nil) then
			p:setParam("speedTime",nil);
			p:setParam("speedYTime",nil);
			p:setParam("speedY",nil);
			p:setParam("accelY",nil);
		end
		
		
		p:setParam("targetTime",p.targetTime,s);
		
		p:setParam("rotSpeedTime",p.rotSpeedTime,s);
		
		p:setParam("colTime",p.colTime,s);
		p:setParam("colScale",p.colScale,s);
		
		p:setParam("speedScale",p.speedScale,s);
		p:setParam("speedXScale",p.speedXScale,s);
		p:setParam("speedYScale",p.speedYScale,s);
		p:setParam("rotSpeedScale",p.rotSpeedScale,s);
		
		p:setParam("blend",p.blend,s);
		p:setParam("space",p.space,s);
		p:setParam("updateType",p.updateType,s);
		
		p:setParam("boundleft",p.boundleft,s);
		p:setParam("boundright",p.boundright,s);
		p:setParam("boundtop",p.boundtop,s);
		p:setParam("boundbottom",p.boundbottom,s);
		
		p:setParam("collision",p.collision,s);
		p:setParam("collisionType",p.collisionType,s);
		p.particles = {};
		
		tris[p] = {};
		txs[p] = {};
		cols[p] = {};
		
		return p;
	end

	---A particle emitter.
	--@type Emitter
	
	---Get the default value of a given parameter.
	--@function Emitter:getParamDefault
	--@tparam string name The name of the parameter.
	function emitter:getParamDefault(name)
		if(paramDefaultMaps[name] ~= nil) then
			if(type(paramDefaultMaps[name]) == "function") then
				return paramDefaultMaps[name](self);
			else
				return paramDefaultMaps[name];
			end
		elseif(paramGradMaps[name] ~= nil) then
			return paramGradMaps[name];
		else
			return nil;
		end
	end

	---Sets the value of a given parameter.
	--@function Emitter:setParam
	--@tparam string name The name of the parameter.
	--@param value The value to set the parameter to. This can be set directly, or can be passed a string in the format used in a particle descriptor file.
	function emitter:setParam(name,value,stack)
		stack = stack or {};
		if(paramRangeMaps[name] ~= nil) then
			local vals = parseValue(value,stack);
			if(vals == nil) then
				self[name] = self:getParamDefault(name);
				self[paramRangeMaps[name][1]] = self[name];
				self[paramRangeMaps[name][2]] = self[name];
			else
				if(type(vals) == "number") then
					self[name] = vals;
					self[paramRangeMaps[name][1]] = vals;
					self[paramRangeMaps[name][2]] = vals;
				elseif(type(vals) == "table") then
					self[name] = vals[1];
					self[paramRangeMaps[name][1]] = vals[1];
					self[paramRangeMaps[name][2]] = vals[2];
				else
					error("Syntax Error: Invalid numerical range specified: "..tostring(value),2)
				end
				if(name == "frameSpeed") then
					self[name] = floor(self[name]);
					self[paramRangeMaps[name][1]] = self[name];
					self[paramRangeMaps[name][2]] = ceil(self[paramRangeMaps[name][2]]);
				end
			end
		elseif(paramGradMaps[name] ~= nil) then
			self[name] = parseValue(value,stack);
			if(self[name] == nil) then
				self[name] = self:getParamDefault(name);
			end
		elseif(paramColMaps[name] ~= nil) then
			self[name] = parseValue(value,stack);
			self[paramColMaps[name][1]] = self[name];
			self[paramColMaps[name][2]] = self[name];
			if(self[name] == nil) then
				self[name] = self:getParamDefault(name);
				self[paramColMaps[name][1]] = self[name];
				self[paramColMaps[name][2]] = self[name];
			end
			
			if(self[name][0] == nil) then --is not a discrete list
				if(self[name].r == nil) then --is a range list
					self[paramColMaps[name][1]] = self[name][1];
					self[paramColMaps[name][2]] = self[name][2];
					self[name] = self[name][1];
				end
			else
				self[name][0] = nil;
			end
		elseif(paramEnumMaps[name] ~= nil) then
			self[name] = paramEnumMaps[name][value] or self:getParamDefault(name);
		else
			self[name] = tonumber(value) or self:getParamDefault(name);
		end
	end

	---Flips the emitter horizontally.
	--@function Emitter:flipX
	function emitter:FlipX()
		self:setParam("speedX",tostring(-self.maxSpeedX)..":"..tostring(-self.minSpeedX));
		self:setParam("accelX",tostring(-self.maxAccelX)..":"..tostring(-self.minAccelX));
		self:setParam("xOffset",tostring(-self.maxX)..":"..tostring(-self.minX));

		local r = self.boundright;
		
		self:setParam("boundright",-self.boundleft);
		self:setParam("boundleft",-r);
	end
	
	emitter.flipX = emitter.FlipX;

	---Flips the emitter vertically.
	--@function Emitter:flipY
	function emitter:FlipY()
		self:setParam("speedY",tostring(-self.maxSpeedY)..":"..tostring(-self.minSpeedY));
		self:setParam("accelY",tostring(-self.maxAccelY)..":"..tostring(-self.minAccelY));
		self:setParam("yOffset",tostring(-self.maxY)..":"..tostring(-self.minY));
		
		local t = self.boundtop;
		self:setParam("boundtop",-self.boundbottom);
		self:setParam("boundbottom",-t);
	end
	
	emitter.flipY = emitter.FlipY;

	---Attaches the emitter to a given Camera object.
	--@function Emitter:attachToCamera
	--@tparam Camera camera The camera to attach the emitter to.
	--@tparam[opt=true] bool snap Whether the emitter should snap to the centre of the camera, or retain its initial offset.
	function emitter:AttachToCamera(cam, snap)
		if(snap == nil) then snap = true; end
		local ox = 0;
		local oy = 0;
		if(not snap) then
			ox = self.x-(cam.x+cam.width/2)
			oy = self.y-(cam.y+cam.height/2)
		end
		self.parent = {obj = cam, __type = "Camera", offsetX = ox, offsetY = oy};
	end
	
	emitter.attachToCamera = emitter.AttachToCamera;
	
	local validParentTypes = { Block = true, Animation = true, Player = true, NPC = true, table = true, userdata = true }

	---Attaches the emitter to an object.
	--@function Emitter:attach
	--@param object The object to attach the emitter to.
	--@tparam[opt=true] bool snap Whether the emitter should snap to the object, or retain its initial offset.
	--@tparam[opt=false] bool flipDirection If the object can change direction (for example, it is an NPC or Player), this setting will flip the emitter to match the direction of the attached object.
	--@tparam[opt] int startDirection If `flipDirection` is true, this setting can override the emitters initial direction, otherwise it will be assumed to be facing the same direction as the object it is attached to.
	function emitter:Attach(object, snap, flipOnDirectionChange, startDirection)
		
		local typ = type(object);
		
		if typ == "Camera" then
			return self:attachToCamera(object, snap)
		end
		
		if not validParentTypes[typ] then
			error("Emitter could not be attached to object with type "..typ,2);
		end
		
		if typ == "table" or typ == "userdata" then
			if object.subTimer then
				typ = "Animation"
			end
		end
		
		if(snap == nil) then snap = true; end
		local ox = 0;
		local oy = 0;
		if(not snap) then
			ox = self.x-(object.x+object.width/2)
			oy = self.y-(object.y+object.height/2)
		end
		
		if(flipOnDirectionChange == nil) then flipOnDirectionChange = false; end
		if(startDirection == nil) then 
			startDirection = 1; 
			if(typ == "Player") then
				startDirection = object:mem(0x106,FIELD_WORD);
			elseif(typ == "NPC") then
				startDirection = object.direction;	
			end
		end
		
		local lastDir;
		if(flipOnDirectionChange) then
			if(typ == "Player") then
				if(object:mem(0x106,FIELD_WORD) ~= startDirection) then
					self:FlipX();
				end
				lastDir = object:mem(0x106,FIELD_WORD);
			elseif(typ == "NPC") then
				if(object.direction ~= startDirection) then
					self:FlipX();
					ox = -ox;
				end
				lastDir = object.direction;
			end
		end
		
		self.parent = {obj = object, __type = typ, offsetX = ox, offsetY = oy, lastDirection = lastDir, shouldFlip = flipOnDirectionChange}
	end
	
	emitter.attach = emitter.Attach;

	---Gets the offset from an attached object. Returns two values, in the form `x,y`.
	--@function Emitter:getOffset
	--@return number,number
	function emitter:GetOffset()
		if(self.parent == nil) then
			return 0,0;
		else
			return self.parent.offsetX, self.parent.offsetY;
		end
	end
	
	emitter.getOffset = emitter.GetOffset;

	---Sets the offset from an attached object.
	--@function Emitter:setOffset
	--@tparam number x
	--@tparam number y
	function emitter:SetOffset(x,y)
		if(self.parent == nil) then
			return;
		else
			self.parent.offsetX = x;
			self.parent.offsetY = y;
		end
	end
	emitter.setOffset = emitter.SetOffset;

	---Removes the emitter from an attached object.
	--@function Emitter:detach
	function emitter:Detach()
		self.parent = nil;
	end
	
	emitter.detach = emitter.Detach;

	---Instantly destroys all particles spawned by this emitter.
	--@function Emitter:killParticles
	function emitter:KillParticles()
		for k,_ in ipairs(self.particles) do
			self.particles[k] = nil;
		end
	end
	
	emitter.killParticles = emitter.KillParticles;

	---Instantly destroys all particles spawned by this emitter, and prevents more from spawning. This permanently destroys the emitter.
	--@function Emitter:destroy
	function emitter:Destroy()
		for k,_ in pairs(self) do
			self[k] = nil;
		end
		
		tris[self] = nil;
		txs[self] = nil;
		cols[self] = nil;
		
		setmetatable(self,nullMeta);
	end
	
	emitter.destroy = emitter.Destroy;

	---Updates the prewarm state of an emitter, allowing to prewarm effect to be recalculated.
	--@function Emitter:setPrewarm
	--@tparam number time How long to prewarm the emitter for.
	function emitter:setPrewarm(value)
		self.initPrewarm = value;
		self.prewarm = self.initPrewarm;
		self.hasPrewarmed = false;
	end

	---Counts the number of live particles spawned by this emitter.
	--@function Emitter:count
	--@return number
	function emitter:Count()
		return #self.particles;
	end
	
	emitter.count = emitter.Count;

	---Resizes the emitter (only applies to newly spawned particles).
	--@function Emitter:resize
	--@tparam number scale The scale multiplier to resize the emitter by.
	function emitter:Scale(n)
		self:setParam("scale",tostring(self.minScale*n)..":"..tostring(self.maxScale*n));
		self:setParam("speedX",tostring(self.minSpeedX*n)..":"..tostring(self.maxSpeedX*n));
		self:setParam("speedY",tostring(self.minSpeedY*n)..":"..tostring(self.maxSpeedY*n));
		self:setParam("accelX",tostring(self.minAccelX*n)..":"..tostring(self.maxAccelX*n));
		self:setParam("accelY",tostring(self.minAccelY*n)..":"..tostring(self.maxAccelY*n));
		self:setParam("boundleft",self.boundleft*n);
		self:setParam("boundright",self.boundright*n);
		self:setParam("boundtop",self.boundtop*n);
		self:setParam("boundbottom",self.boundbottom*n);
	end
	
	emitter.Resize = emitter.Scale;
	emitter.resize = emitter.Scale;

	---Instantly emits particles from the emitter.
	--@function Emitter:emit
	--@tparam[opt=1] int amount The number of particles to emit.
	function emitter:Emit(n)
		n = n or 1;
			
		local xoff = 0;
		local yoff = 0;
		if(self.space == spaceEnum.world) then
			xoff = self.x;
			yoff = self.y;
		end
		for i = 1,n do
			if(self.limit > 0 and self:Count() >= self.limit) then break end;
			local p = {};
			
			do
				local radoffx = 0;
				local radoffy = 0;
				if(self.minRadius ~= 0 or self.maxRadius ~= 0) then
					local angle = rng.random(-pi,pi);
					local m = rng.random(self.minRadius,self.maxRadius);
					radoffx = m*cos(angle);
					radoffy = m*sin(angle);
				end
				
				p.x = radoffx + xoff + rng.random(self.minX,self.maxX);
				p.y = radoffy + yoff + rng.random(self.minY,self.maxY);
				
			end
			
			if(type(self.col) == "table" and self.col.r == nil) then
				p.col = rng.irandomEntry(self.col);
			else
				local cr = rng.random();
				p.col = fastCol((self.minCol.r*(1-cr) + self.maxCol.r*cr),(self.minCol.g*(1-cr) + self.maxCol.g*cr),(self.minCol.b*(1-cr) + self.maxCol.b*cr),(self.minCol.a*(1-cr) + self.maxCol.a*cr));
			end
			
			p.ttl = rng.random(self.minLife,self.maxLife);
			p.initTtl = p.ttl;
			
			p.scale = rng.random(self.minScale,self.maxScale);
			p.initScale = p.scale;
			p.width = rng.random(self.minWidth,self.maxWidth);
			p.height = rng.random(self.minHeight,self.maxHeight);
			
			local st = (p.scale-self.minScale)/(self.maxScale-self.minScale);
			
			do
				local toffsetx = p.x-self.x;
				local toffsety = p.y-self.y;
				local radspd = rng.random(self.minRadSpeed,self.maxRadSpeed);
				local radsize = 0;
				if(toffsetx ~= 0 or toffsety ~= 0) then
					radsize = 1/sqrt(toffsetx*toffsetx + toffsety*toffsety);
				end
				
				p.speedX = (rng.random(self.minSpeedX,self.maxSpeedX) + radspd*toffsetx*radsize)*self.speedXScale(st)*self.speedScale(st);
				p.speedY = (rng.random(self.minSpeedY,self.maxSpeedY) + radspd*toffsety*radsize)*self.speedYScale(st)*self.speedScale(st);
			end
			
			p.scaleCol = self.colScale(st);
			
			p.initSpeedX = p.speedX;
			p.initSpeedY = p.speedY;
			
			p.accelX = rng.random(self.minAccelX,self.maxAccelX);
			p.accelY = rng.random(self.minAccelY,self.maxAccelY);
			
			p.forceX = 0;
			p.forceY = 0;
			
			if(self.minTargetX ~= nil) then
				p.targetX = xoff + rng.random(self.minTargetX, self.maxTargetX);
				p.initX = p.x;
			end
			if(self.minTargetY ~= nil) then
				p.targetY = yoff + rng.random(self.minTargetY, self.maxTargetY);
				p.initY = p.y;
			end
			
			p.rotation = rng.random(self.minRot,self.maxRot);
			
			p.rotSpeed = rng.random(self.minRotSpd,self.maxRotSpd)*self.rotSpeedScale(st);
			
			p.maxframes = self.framesX*self.framesY;
			p.frame = rng.randomInt(self.minStartFrame, self.maxStartFrame)
			p.frametimer = rng.randomInt(self.minFrameSpd,self.maxFrameSpd);
			p.initFrametimer = p.frametimer;
			
			p.collider = nil;
			if(self.collision ~= collisionEnum.none) then
				p.collider = colliders.Point(p.x,p.y);
				p.bounceEnergy = rng.random(self.minBounce,self.maxBounce);
			end
			
			tableinsert(self.particles,p);
		end
	end
	
	emitter.emit = emitter.Emit;
	
	
	---Updates and draws the particles to the scene. Should be called inside `onDraw` on `onCameraDraw`, and is required for particles to appear in the scene.
	--@function Emitter:draw
	--@param args
	--@tparam[opt] number args.priority The render priority to draw the particles at.
	--@tparam[opt=false] bool args.nocull If true, the particles will still be updated and drawn even if they are offscreen.
	--@tparam[opt] CaptureBuffer args.target The render target to draw the particles to.
	--@tparam[opt=true] bool args.sceneCoords Whether the particles should be drawn in world space or screen space.
	--@tparam[opt=white] Color args.color A global tint for all particles produced by the emitter.
	--@tparam[opt=1] number args.timeScale A multiplier for the speed of time for the emitter.
	--@tparam[opt=false] bool args.updateWhilePaused Whether the emitter should be updated even when the game is paused.
	--@usage myEmitter:draw{color = Color.red, timeScale = 2, priority = -50}

	---Updates and draws the particles to the scene. Should be called inside `onDraw` on `onCameraDraw`, and is required for particles to appear in the scene.
	--@function Emitter:draw
	--@tparam[opt] number priority The render priority to draw the particles at.
	--@tparam[opt=false] bool nocull If true, the particles will still be updated and drawn even if they are offscreen.
	--@tparam[opt] CaptureBuffer target The render target to draw the particles to.
	--@tparam[opt=true] bool sceneCoords Whether the particles should be drawn in world space or screen space.
	--@tparam[opt=white] Color color A global tint for all particles produced by the emitter.
	--@tparam[opt=1] number timeScale A multiplier for the speed of time for the emitter.
	--@tparam[opt=false] bool updateWhilePaused Whether the emitter should be updated even when the game is paused.
	function emitter:Draw(priority, nocull, rt, sceneCoords, color, timeScale, updateWhilePaused)
		
		if(type(priority) == "table") then
			nocull = priority.nocull;
			rt = priority.target;
			sceneCoords = priority.sceneCoords;
			timeScale = priority.timeScale;
			color = priority.color or priority.colour or priority.col;
			updateWhilePaused = priority.updateWhilePaused
			priority = priority.priority;
		end
	
		if(sceneCoords == nil) then
			sceneCoords = true;
		end
		
		priority = priority or 0.5;
		if(self.tte == nil) then 
			self.tte = 1/rng.random(self.minRate,self.maxRate);
		end
		
		if(self.parent ~= nil) then
			if(self.parent.__type == "Camera" or self.parent.__type == "Animation" or self.parent.__type == "Block" or self.parent.__type == "Player" or self.parent.__type == "NPC") then
				if(self.parent.obj == nil or (self.parent.obj.isValid ~= nil and not self.parent.obj.isValid)) then
					self:Detach();
					self.enabled = false;
				else
					self.x = self.parent.obj.x + self.parent.obj.width/2 + self.parent.offsetX;
					self.y = self.parent.obj.y + self.parent.obj.height/2 + self.parent.offsetY;
					if(self.parent.shouldFlip) then
						if(self.parent.__type == "Player") then
							if(self.parent.obj:mem(0x106,FIELD_WORD) ~= self.parent.lastDirection) then
								self:FlipX();
								self.parent.offsetX = -self.parent.offsetX;
							end
							self.parent.lastDirection = self.parent.obj:mem(0x106,FIELD_WORD);
						elseif(self.parent.__type == "NPC") then
							if(self.parent.obj.direction ~= self.parent.lastDirection) then
								self:FlipX();
								self.parent.offsetX = -self.parent.offsetX;
							end
							self.parent.lastDirection = self.parent.obj.direction;
						end
					end
				end
			end
		end
		
		local despawning = false
		do
			local cam = camera;
			local cam2 = camera2;
			despawning = not nocull and ((sceneCoords and (cam.x > self.x+self.boundright or cam.x+cam.width < self.x+self.boundleft or cam.y > self.y+self.boundbottom or cam.y+cam.height < self.y+self.boundtop) and
									 (not cam2.isValid or (cam2.x > self.x+self.boundright or cam2.x+cam2.width < self.x+self.boundleft or cam2.y > self.y+self.boundbottom or cam2.y+cam2.height < self.y+self.boundtop))) or 
									   (not sceneCoords and (0 > self.x+self.boundright or cam.width < self.x+self.boundleft or 0 > self.y+self.boundbottom or cam.height < self.y+self.boundtop) and
									 (not cam2.isValid or (0 > self.x+self.boundright or cam2.width < self.x+self.boundleft or 0 > self.y+self.boundbottom or cam2.height < self.y+self.boundtop))));
		end
		
		if(despawning) then
			self.despawnCount = self.despawnCount-1;
			if(self.despawnCount <= 0) then
				while #self.particles > 0 do
					tableremove(self.particles,1);
				end
				self.hasPrewarmed = false;
				
				if(self.prewarm <= 0) then 
					self.prewarm = self.initPrewarm;
				end
			end
			return;
		end
		
		self.despawnCount=self.despawnTime;
		local delta = 1;
		if(self.updateType == updateEnum.seconds) then
			if updateWhilePaused then
				delta = Routine.pauseDeltaTime
			else
				delta = Routine.deltaTime
			end
			if(delta <= 0) then delta = 0.01538461538; end -- Cap deltaTime so it never gets stuck in an infinite loop. Cap is SMBX native framerate (1/65)
		end
			
		local ispaused = Misc.isPaused();
		
		if not updateWhilePaused and ispaused then
			delta = 0;
		end
		
		timeScale = timeScale or 1;
		delta = delta * timeScale;
		
		local i = 0;
		
		repeat
			if(self.enabled) then
				if(self.tte <= 0) then
					while self.tte <= 0 do
						self:Emit();
						self.tte = self.tte + 1/rng.random(self.minRate,self.maxRate);
					end
					self.tte = 1/rng.random(self.minRate,self.maxRate);
				end
				
				self.tte = self.tte-delta;
			end
			
			do
				local removeQueue = {};
				local hit = self.collision ~= collisionEnum.none and not despawning and #Block.getIntersecting(self.x+self.boundleft,self.y+self.boundtop,self.x+self.boundright,self.y+self.boundbottom) > 0;
				local fw = 1/self.framesX;
				local fh = 1/self.framesY;
				local k = 1;
				local prewarming = not self.hasPrewarmed and self.prewarm > 0;
				
				while(k <= #self.particles) do
					local v = self.particles[k];
					local t = 1 - (v.ttl/v.initTtl);
					v.scale = v.initScale*self.scaleTime(t);
					v.speedX = v.initSpeedX*self.speedXTime(t)*self.speedTime(t);
					v.speedY = v.initSpeedY*self.speedYTime(t)*self.speedTime(t);
					
					
					if(self.space == spaceEnum["local"]) then
						v.x = v.x+self.x;
						v.y = v.y+self.y;
					end
					
					v.forceX = 0;
					v.forceY = 0;
					for _,l in ipairs(self.forcefieldAttractors) do
						local fx,fy = l:get(v.x,v.y);
						v.forceX = v.forceX+fx;
						v.forceY = v.forceY+fy;
					end
					for _,l in ipairs(self.forcefieldRepulsors) do
						local fx,fy = l:get(v.x,v.y);
						v.forceX = v.forceX+fx*-1;
						v.forceY = v.forceY+fy*-1;
					end
					
					do
						if(not prewarming) then
							do
								local p1x = 0
								local p1y = 0
								local p2x = 0
								local p2y = 0
								local p3x = 0
								local p3y = 0
								local p4x = 0
								local p4y = 0
								do
									local ct = cos(v.rotation*0.01745);
									local st = sin(v.rotation*0.01745);
									local w = v.width*0.5*v.scale;
									local h = v.height*0.5*v.scale;
									
									v.rotation = (v.rotation+v.rotSpeed*self.rotSpeedTime(t)*delta)%360;
									
									p1x = (-w*ct) + (h*st);
									p1y = (-w*st) - (h*ct);
									
									p2x = (w*ct) + (h*st);
									p2y = (w*st) - (h*ct);
									
									p3x = (-w*ct) - (h*st);
									p3y = (h*ct) - (w*st);
									
									p4x = (w*ct) - (h*st);
									p4y = (w*st) + (h*ct);
								end
								
								tris[self][i] = v.x + p1x;
								tris[self][i+1] = v.y + p1y;
								
								tris[self][i+2] = v.x + p2x;
								tris[self][i+3] = v.y + p2y;
								
								tris[self][i+4] = v.x + p3x;
								tris[self][i+5] = v.y + p3y;
								
								tris[self][i+6] = v.x + p3x;
								tris[self][i+7] = v.y + p3y;
								
								tris[self][i+8] = v.x + p2x;
								tris[self][i+9] = v.y + p2y;
								
								tris[self][i+10] = v.x + p4x;
								tris[self][i+11] = v.y + p4y;
							
							end
							
							do
								local fx = ((v.frame % self.framesX)/self.framesX);
								local fy = (floor(v.frame/self.framesX)/self.framesY);
								
								txs[self][i] = fx;
								txs[self][i+1] = fy;
								
								txs[self][i+2] = fx+fw;
								txs[self][i+3] = fy;
								
								txs[self][i+4] = fx;
								txs[self][i+5] = fy+fh;
								
								txs[self][i+6] = fx;
								txs[self][i+7] = fy+fh;
								
								txs[self][i+8] = fx+fw;
								txs[self][i+9] = fy;
								
								txs[self][i+10] = fx+fw;
								txs[self][i+11] = fy+fh;
							end
							
							do
								local c = fastColTripleMul(v.col, self.colTime(t), v.scaleCol);
							
								if(self.blend == blendEnum.alpha) then
									c[1] = c[1]*c[4];
									c[2] = c[2]*c[4];
									c[3] = c[3]*c[4];
								end
								
								for j=0,23,4 do
									cols[self][(2*i)+j] = c[1];
									cols[self][(2*i)+j+1] = c[2];
									cols[self][(2*i)+j+2] = c[3];
									cols[self][(2*i)+j+3] = c[4];
								end
							end
							
							i = i+12;
						end
					end
					
					do
						local removed = false;
						
						if(v.collider ~= nil and hit) then
							v.collider.x = v.x;
							v.collider.y = v.y;
							if((self.collisionType == collisionType.coarse and #Block.getIntersecting(v.x,v.y,v.x+1,v.y+1) > 0) or
								(self.collisionType == collisionType.fine and colliders.collideBlock(v.collider,colliders.BLOCK_SOLID..colliders.BLOCK_LAVA..colliders.BLOCK_HURT..colliders.BLOCK_PLAYER))) then
								if(self.collision == collisionEnum.kill) then
									tableremove(self.particles,k);
									removed = true;
								elseif(self.collision == collisionEnum.stop) then
									v.speedX = 0;
									v.speedY = 0;
									v.initSpeedX = 0;
									v.initSpeedY = 0;
								elseif(self.collision == collisionEnum.bounce) then
									if(abs(v.speedX) >= abs(v.speedY)) then
										v.speedX = -v.speedX*v.bounceEnergy;
										v.initSpeedX = -v.initSpeedX*v.bounceEnergy;
									end
									if(abs(v.speedY) >= abs(v.speedX)) then
										v.speedY = -v.speedY*v.bounceEnergy;
										v.initSpeedY = -v.initSpeedY*v.bounceEnergy;
									end
								end
							end
						end
						
						v.ttl = v.ttl-delta;
						if(v.ttl <= 0) then	
							tableremove(self.particles,k);
							removed = true;
						else			
							if(self.space == spaceEnum["local"]) then
								v.x = v.x-self.x;
								v.y = v.y-self.y;
							end
							
							if(v.targetX ~= nil) then
								local tau = self.targetTime(t);
								v.x = v.targetX*tau + v.initX*(1-tau);
							else
								v.x = v.x + v.speedX*delta;
							end
							
							if(v.targetY ~= nil) then
								local tau = self.targetTime(t);
								v.y = v.targetY*tau + v.initY*(1-tau);
							else
								v.y = v.y + v.speedY*delta;
							end
							
							v.speedX = v.speedX+(v.accelX+v.forceX)*delta;
							v.initSpeedX = v.initSpeedX + (v.accelX+v.forceX)*delta;
							v.speedY = v.speedY+(v.accelY+v.forceY)*delta;
							v.initSpeedY = v.initSpeedY + (v.accelY+v.forceY)*delta;
							
							if not ispaused or updateWhilePaused then
								v.frametimer = v.frametimer-1;
							end
							if(v.frametimer == 0) then
								v.frame = (v.frame+1)%v.maxframes;
								v.frametimer = v.initFrametimer;
							end
						end
						if(not removed) then
							k = k+1;
						end
					end
				end
				
				if(prewarming) then
					self.prewarm = self.prewarm-delta;
				end
			end
		until(self.prewarm <= 0 or delta == 0)
		
		self.hasPrewarmed = delta > 0;
		
		if(i > 0) then
			clearTables(self,i); --Remove junk data from previous draw operation
			
			Graphics.glDraw{texture=self.texture, vertexCoords=tris[self], textureCoords=txs[self], vertexColors=cols[self], priority=priority, sceneCoords=sceneCoords, target=rt, color = color}
		end
	end

	emitter.draw = emitter.Draw;

end

local ribbon = {};
function ribbon.__index(tbl, k)
	if k == "isValid" then
		return true
	else
		return ribbon[k]
	end
end

--- Functions.
--
--@section Functions

do --Ribbon Functions

	---Creates a @{Ribbon} emitter.
	--@function Ribbon
	--@tparam number x The x coordinate of the emitter.
	--@tparam number y The y coordinate of the emitter.
	--@tparam string source The path to a particle descriptor file (usually .ini).
	--@return @{Ribbon}

	---Creates a @{Ribbon} emitter.
	--@function Ribbon
	--@tparam number x The x coordinate of the emitter.
	--@tparam number y The y coordinate of the emitter.
	--@tparam table source A table containing particle properties.
	--@return @{Ribbon}
	function particles.Ribbon(x,y,source)
		local p;
		local s;
		
		if(type(source) == "table") then
			p = source;
			s = {};
		else
			p,s = parseFile(source);
		end
		setmetatable(p,ribbon);
		
		p.x = x;
		p.y = y;
		
		p.enabled = true;
		
		p:setParam("col",p.col,s)
		p:setParam("rate",p.rate,s);
		p:setParam("xOffset",p.xOffset,s);
		p:setParam("yOffset",p.yOffset,s);
		p:setParam("framesX",p.framesX,s);
		p:setParam("framesY",p.framesY,s);
		
		p:setParam("maxAngle",p.maxAngle);
		p:setParam("scaleType",p.scaleType);
		p:setParam("ribbonType",p.ribbonType);
		p:setParam("colLength",p.colLength);
		
		p:setParam("width",p.width,s);
		
		p:setParam("lifetime",p.lifetime,s);
		
		p:setParam("speedX",p.speedX,s);
		p:setParam("speedY",p.speedY,s);
		
		p:setParam("accelX",p.accelX,s);
		p:setParam("accelY",p.accelY,s);
		
		p:setParam("targetX",p.targetX,s);
		p:setParam("targetY",p.targetY,s);
		
		p:setParam("frameSpeed",p.frameSpeed,s);
		
		p:setParam("scaleTime",p.scaleTime,s);
		p:setParam("scaleLength",p.scaleLength,s);
		
		p:setParam("speedXTime",p.speedXTime,s);
		p:setParam("speedYTime",p.speedYTime,s);
		p:setParam("speedTime",p.speedTime,s);
		
		if(p.targetX ~= nil) then
			p:setParam("speedTime",nil);
			p:setParam("speedXTime",nil);
			p:setParam("speedX",nil);
			p:setParam("accelX",nil);
		end
		
		if(p.targetY ~= nil) then
			p:setParam("speedTime",nil);
			p:setParam("speedYTime",nil);
			p:setParam("speedY",nil);
			p:setParam("accelY",nil);
		end
		
		p:setParam("targetTime",p.targetTime,s);
		
		p:setParam("rotSpeedTime",p.rotSpeedTime,s);
		
		p:setParam("colTime",p.colTime,s);
		
		p:setParam("blend",p.blend,s);
		p:setParam("updateType",p.updateType,s);
		
		p.segments = {};
		
		tris[p] = {};
		txs[p] = {};
		cols[p] = {};
		
		return p;
	end

	---A ribbon emitter.
	--@type Ribbon
	
	---Get the default value of a given parameter.
	--@function Ribbon:getParamDefault
	--@tparam string name The name of the parameter.
	ribbon.getParamDefault = emitter.getParamDefault;
	
	---Sets the value of a given parameter.
	--@function Ribbon:setParam
	--@tparam string name The name of the parameter.
	--@param value The value to set the parameter to. This can be set directly, or can be passed a string in the format used in a particle descriptor file.
	ribbon.setParam = emitter.setParam;

	---Flips the emitter horizontally.
	--@function Ribbon:flipX
	function ribbon:FlipX()
		self:setParam("speedX",tostring(-self.maxSpeedX)..":"..tostring(-self.minSpeedX));
		self:setParam("accelX",tostring(-self.maxAccelX)..":"..tostring(-self.minAccelX));
	end
	
	ribbon.flipX = ribbon.FlipX;

	---Flips the emitter vertically.
	--@function Ribbon:flipY
	function ribbon:FlipY()
		self:setParam("speedY",tostring(-self.maxSpeedY)..":"..tostring(-self.minSpeedY));
		self:setParam("accelY",tostring(-self.maxAccelY)..":"..tostring(-self.minAccelY));
	end
	
	ribbon.flipY = ribbon.FlipY;

	---Attaches the emitter to a given Camera object.
	--@function Ribbon:attachToCamera
	--@tparam Camera camera The camera to attach the emitter to.
	--@tparam[opt=true] bool snap Whether the emitter should snap to the centre of the camera, or retain its initial offset.
	ribbon.AttachToCamera = emitter.AttachToCamera;
	ribbon.attachToCamera = emitter.AttachToCamera;
	
	---Attaches the emitter to an object.
	--@function Ribbon:attach
	--@param object The object to attach the emitter to.
	--@tparam[opt=true] bool snap Whether the emitter should snap to the object, or retain its initial offset.
	--@tparam[opt=false] bool flipDirection If the object can change direction (for example, it is an NPC or Player), this setting will flip the emitter to match the direction of the attached object.
	--@tparam[opt] int startDirection If `flipDirection` is true, this setting can override the emitters initial direction, otherwise it will be assumed to be facing the same direction as the object it is attached to.
	ribbon.Attach = emitter.Attach;
	ribbon.attach = emitter.Attach;
	
	---Gets the offset from an attached object. Returns two values, in the form `x,y`.
	--@function Ribbon:getOffset
	--@return number,number
	ribbon.GetOffset = emitter.GetOffset;
	ribbon.getOffset = emitter.GetOffset;
	
	---Sets the offset from an attached object.
	--@function Ribbon:setOffset
	--@tparam number x
	--@tparam number y
	ribbon.SetOffset = emitter.SetOffset;
	ribbon.setOffset = emitter.SetOffset;
	
	---Removes the emitter from an attached object.
	--@function Ribbon:detach
	ribbon.Detach = emitter.Detach;
	ribbon.detach = emitter.Detach;

	---Instantly destroys the trail spawned by this emitter.
	--@function Ribbon:killTrail
	function ribbon:KillTrail()
		for k,_ in ipairs(self.segments) do
			self.segments[k] = nil;
		end
	end
	
	ribbon.killTrail = ribbon.KillTrail;

	---Instantly destroys the trail spawned by this emitter, and prevents more from spawning. This permanently destroys the emitter.
	--@function Ribbon:destroy
	function ribbon:Destroy()
		for k,_ in pairs(self) do
			self[k] = nil;
		end
		
		tris[self] = nil;
		txs[self] = nil;
		cols[self] = nil;
		
		setmetatable(self,nullMeta);
	end
	
	ribbon.destroy = ribbon.Destroy;

	---Counts the number of live trail segments spawned by this emitter.
	--@function Ribbon:count
	--@return number
	function ribbon:Count()
		return #self.segments;
	end
	
	ribbon.count = ribbon.Count;

	---Resizes the emitter (only applies to newly spawned trail segments).
	--@function Ribbon:resize
	--@tparam number scale The scale multiplier to resize the emitter by.
	function ribbon:Scale(n)
		self:setParam("width",tostring(self.minWidth*n)..":"..tostring(self.maxWidth*n));
		self:setParam("speedX",tostring(self.minSpeedX*n)..":"..tostring(self.maxSpeedX*n));
		self:setParam("speedY",tostring(self.minSpeedY*n)..":"..tostring(self.maxSpeedY*n));
		self:setParam("accelX",tostring(self.minAccelX*n)..":"..tostring(self.maxAccelX*n));
		self:setParam("accelY",tostring(self.minAccelY*n)..":"..tostring(self.maxAccelY*n));
	end
	
	ribbon.Resize = ribbon.Scale;
	ribbon.resize = ribbon.Scale;

	---Instantly emits trail segments from the emitter.
	--@function Ribbon:emit
	--@tparam[opt=1] int amount The number of segments to emit.
	function ribbon:Emit(n)
		n = n or 1;
			
		for i = 1,n do
			local p = {};
			
			p.xoff = rng.random(self.minX,self.maxX);
			p.yoff = rng.random(self.minY,self.maxY);
			p.x = self.x + p.xoff;
			p.y = self.y + p.yoff;
			
			if(type(self.col) == "table" and self.col.r == nil) then
				p.col = rng.irandomEntry(self.col);
			else
				local cr = rng.random();
				p.col = fastCol((self.minCol.r*(1-cr) + self.maxCol.r*cr),(self.minCol.g*(1-cr) + self.maxCol.g*cr),(self.minCol.b*(1-cr) + self.maxCol.b*cr),(self.minCol.a*(1-cr) + self.maxCol.a*cr));
			end
			
			p.ttl = rng.random(self.minLife,self.maxLife);
			p.initTtl = p.ttl;
			
			p.width = rng.random(self.minWidth,self.maxWidth);
			p.initWidth = p.width;
			
			p.speedX = rng.random(self.minSpeedX,self.maxSpeedX);
			p.speedY = rng.random(self.minSpeedY,self.maxSpeedY);
			
			p.initSpeedX = p.speedX;
			p.initSpeedY = p.speedY;
			
			p.accelX = rng.random(self.minAccelX,self.maxAccelX);
			p.accelY = rng.random(self.minAccelY,self.maxAccelY);
			
			if(self.minTargetX ~= nil) then
				p.targetX = xoff + rng.random(self.minTargetX, self.maxTargetX);
				p.initX = p.x;
			end
			if(self.minTargetY ~= nil) then
				p.targetY = yoff + rng.random(self.minTargetY, self.maxTargetY);
				p.initY = p.y;
			end
			
			p.frame = 0;
			p.maxframes = self.framesX*self.framesY;
			p.frametimer = rng.randomInt(self.minFrameSpd,self.maxFrameSpd);
			p.initFrametimer = p.frametimer;
			
			p.recent = true;
			
			p.colour = fastCol(1,1,1,1);
			
			tableinsert(self.segments,p);
		end
	end
	
	ribbon.emit = ribbon.Emit;

	local function ccw(x1,y1,x2,y2,px,py)
		return (py-y1)*(x2-x1) > (y2-y1)*(px-x1);
	end

	local function intersect(x1,y1,x2,y2,x3,y3,x4,y4)
		return ccw(x1,y1,x3,y3,x4,y4) ~= ccw(x2,y2,x3,y3,x4,y4) and ccw(x1,y1,x2,y2,x3,y3) ~= ccw(x1,y1,x2,y2,x4,y4)
	end

	---Breaks the trail off and starts a new trail on the next emit.
	--@function Ribbon.split
	function ribbon:Break()
		if(#self.segments > 0) then
			self.segments[#self.segments].recent = false;
			self.segments[#self.segments].skipped = true;
		end
	end
	
	ribbon.Split = ribbon.Break;
	ribbon.split = ribbon.Break;
	
	---Updates and draws the trail to the scene. Should be called inside `onDraw` on `onCameraDraw`, and is required for trails to appear in the scene.
	--@function Ribbon:draw
	--@param args
	--@tparam[opt] number args.priority The render priority to draw the trail at.
	--@tparam[opt] CaptureBuffer args.target The render target to draw the trail to.
	--@tparam[opt=true] bool args.sceneCoords Whether the trail should be drawn in world space or screen space.
	--@tparam[opt=white] Color args.color A global tint for all segments produced by the emitter.
	--@tparam[opt=1] number args.timeScale A multiplier for the speed of time for the emitter.
	--@tparam[opt=false] bool args.updateWhilePaused Whether the emitter should be updated even when the game is paused.
	--@usage myRibbon:draw{color = Color.red, timeScale = 2, priority = -50}

	---Updates and draws the trail to the scene. Should be called inside `onDraw` on `onCameraDraw`, and is required for trails to appear in the scene.
	--@function Ribbon:draw
	--@tparam[opt] number priority The render priority to draw the trail at.
	--@tparam[opt] CaptureBuffer target The render target to draw the trail to.
	--@tparam[opt=true] bool sceneCoords Whether the trail should be drawn in world space or screen space.
	--@tparam[opt=white] Color color A global tint for all segments produced by the emitter.
	--@tparam[opt=1] number timeScale A multiplier for the speed of time for the emitter.
	--@tparam[opt=false] bool updateWhilePaused Whether the emitter should be updated even when the game is paused.
	function ribbon:Draw(priority, rt, sceneCoords, color, timeScale, updateWhilePaused)
	
		if(type(priority) == "table") then
			rt = priority.target;
			sceneCoords = priority.sceneCoords;
			timeScale = priority.timeScale;
			color = priority.color or priority.colour or priority.col;
			updateWhilePaused = priority.updateWhilePaused
			priority = priority.priority;
		end
		
		if(sceneCoords == nil) then
			sceneCoords = true;
		end
		priority = priority or 0.5;
		
		if(self.tte == nil) then 
			self.tte = 1/rng.random(self.minRate,self.maxRate);
		end
		
		if(self.parent ~= nil) then
			if(self.parent.__type == "Camera" or self.parent.__type == "Animation" or self.parent.__type == "Block" or self.parent.__type == "Player" or self.parent.__type == "NPC") then
				if(self.parent.obj == nil or (self.parent.obj.isValid ~= nil and not self.parent.obj.isValid)) then
					self:Detach();
					self.enabled = false;
				else
					self.x = self.parent.obj.x + self.parent.obj.width/2 + self.parent.offsetX;
					self.y = self.parent.obj.y + self.parent.obj.height/2 + self.parent.offsetY;
					if(self.parent.shouldFlip) then
						if(self.parent.__type == "Player") then
							if(self.parent.obj:mem(0x106,FIELD_WORD) ~= self.parent.lastDirection) then
								self:FlipX();
								self.parent.offsetX = -self.parent.offsetX;
							end
							self.parent.lastDirection = self.parent.obj:mem(0x106,FIELD_WORD);
						elseif(self.parent.__type == "NPC") then
							if(self.parent.obj.direction ~= self.parent.lastDirection) then
								self:FlipX();
								self.parent.offsetX = -self.parent.offsetX;
							end
							self.parent.lastDirection = self.parent.obj.direction;
						end
					end
				end
			end
		end
		
		local delta = 1;
		if(self.updateType == updateEnum.seconds) then
			if updateWhilePaused then
				delta = Routine.pauseDeltaTime
			else
				delta = Routine.deltaTime
			end
			if(delta <= 0) then delta = 0.01538461538; end -- Cap deltaTime so it never gets stuck in an infinite loop. Cap is SMBX native framerate (1/65)
		end
		
		local ispaused = Misc.isPaused();
	
		if not updateWhilePaused and ispaused then
			delta = 0;
		end
			
		timeScale = timeScale or 1;
		delta = delta * timeScale;
		
		if(self.enabled) then
			if(self.tte <= 0) then
				self:Emit();
				self.tte = 1/rng.random(self.minRate,self.maxRate);
			end
			self.tte = self.tte-delta;
		end
		
		local fw = 1/self.framesX;
		local fh = 1/self.framesY;
		
		local i = 0;
		local k = 1;
		while(k <= #self.segments) do
			local v = self.segments[k];
			local last = self.segments[k-1];
			if(last == nil) then
				last = v;
				v.nolast = true;
			end
			local removed = false;
			local t = 1 - (v.ttl/v.initTtl);
			v.speedX = v.initSpeedX*self.speedXTime(t)*self.speedTime(t);
			v.speedY = v.initSpeedY*self.speedYTime(t)*self.speedTime(t);
			
			
			if(not self.enabled) then
				v.recent = false;
			end
			
			if((v.x == last.x and v.y == last.y) or (v.recent and not last.recent)) then
				v.nolast = true;
			end
			
			local trailend = 1;
			local trailstart = #self.segments;
			for lst = k,1,-1 do
				if(self.segments[lst].nolast or self.segments[lst].skipped) then
					trailend = lst+1;
					break;
				end
			end
			for lst = k,#self.segments,1 do
				if(self.segments[lst].nolast or self.segments[lst].skipped) then
					trailstart = lst-1;
					break;
				end
			end
			
			do
				local leng = 1;
				if(trailstart ~= trailend) then 
					leng = max(0,min(1,1-((k-trailend)/(trailstart-trailend))));
				end
				local ws = self.scaleTime(t)*self.scaleLength(leng);
				v.width = v.initWidth*ws;
			
				do
					local c = fastColTripleMul(v.col, self.colTime(t), self.colLength(leng));
					v.colour.r, v.colour.g, v.colour.b, v.colour.a = c[1],c[2],c[3],c[4]
				end
			end
			
			if(self.blend == blendEnum.alpha) then
				v.colour.r = v.colour.r*v.colour.a;
				v.colour.g = v.colour.g*v.colour.a;
				v.colour.b = v.colour.b*v.colour.a;
			end
			
			v.rot = 1.570796-atan2(v.x-last.x,v.y-last.y);
			
			--[[if(v.x > last.x) then
				p1x = -p1x;
				p1y = -p1y;
				p2x = -p2x;
				p2y = -p2y;
			end]]
			
			if(self.enabled and v.recent and k == #self.segments) then
				v.x = self.x + v.xoff;
				v.y = self.y + v.yoff;
			end
			
			if(abs(v.rot-last.rot) < rad(self.maxAngle) and not v.nolast) then
				do
					local p1x, p1y, p2x, p2y
					
					do
						local wt,wb;
						if(self.scaleType==scaleEnum.centre) then
							wt = v.width*0.5;
							wb = v.width*0.5;
						elseif((self.scaleType==scaleEnum.top and v.x >= last.x) or (self.scaleType==scaleEnum.bottom and v.x < last.x)) then
							wb = v.initWidth*0.5;
							wt = v.width-v.initWidth*0.5;
						elseif((self.scaleType==scaleEnum.bottom and v.x >= last.x) or (self.scaleType==scaleEnum.top and v.x < last.x)) then				
							wb = v.width-v.initWidth*0.5;
							wt = v.initWidth*0.5;
						end
						
						do
							local st = sin(v.rot);
							p1x = wb*st;
							p2x = -wt*st;
						end
						
						do
							local ct = cos(v.rot);
							p1y = -wb*ct;
							p2y = wt*ct;
						end
					end
				
					v.x1 = v.x+p1x;
					v.y1 = v.y+p1y;
					v.x2 = v.x+p2x;
					v.y2 = v.y+p2y;
					
					if(last.x1 == nil or (last.nolast and (last.recent or not v.recent))) then
						last.x1 = last.x+p1x;
						last.y1 = last.y+p1y;
						last.x2 = last.x+p2x;
						last.y2 = last.y+p2y;
					else
						if(intersect(last.x,last.y,last.x1,last.y1,v.x,v.y,v.x1,v.y1)) then
							v.x1 = last.x1;
							v.y1 = last.y1;
						end
						
						if(intersect(last.x,last.y,last.x2,last.y2,v.x,v.y,v.x2,v.y2)) then
							v.x2 = last.x2;
							v.y2 = last.y2;
						end
					end
				end
				
				tris[self][i] = last.x1;
				tris[self][i+1] = last.y1;
					
				tris[self][i+2] = v.x1;
				tris[self][i+3] = v.y1;
					
				tris[self][i+4] = last.x2;
				tris[self][i+5] = last.y2;
					
				tris[self][i+6] = last.x2;
				tris[self][i+7] = last.y2;
					
				tris[self][i+8] = v.x1;
				tris[self][i+9] = v.y1;
					
				tris[self][i+10] = v.x2;
				tris[self][i+11] = v.y2;
				
				do
					local fx = ((v.frame % self.framesX)/self.framesX);
					local fy = (floor(v.frame/self.framesX)/self.framesY);
						
					txs[self][i] = fx;
					txs[self][i+1] = fy;
						
					txs[self][i+2] = fx+fw;
					txs[self][i+3] = fy;
						
					txs[self][i+4] = fx;
					txs[self][i+5] = fy+fh;
						
					txs[self][i+6] = fx;
					txs[self][i+7] = fy+fh;
						
					txs[self][i+8] = fx+fw;
					txs[self][i+9] = fy;
						
					txs[self][i+10] = fx+fw;
					txs[self][i+11] = fy+fh;
				end
					
				for j=0,23,4 do
					if(j == 0 or j==8 or j==12) then
						cols[self][(2*i)+j] = last.colour.r;
						cols[self][(2*i)+j+1] = last.colour.g;
						cols[self][(2*i)+j+2] = last.colour.b;
						cols[self][(2*i)+j+3] = last.colour.a;
					else
						cols[self][(2*i)+j] = v.colour.r;
						cols[self][(2*i)+j+1] = v.colour.g;
						cols[self][(2*i)+j+2] = v.colour.b;
						cols[self][(2*i)+j+3] = v.colour.a;
					end
				end
					
				i = i+12;
			elseif(k>2 and self.ribbonType==ribbonEnum.continuous and (last.recent or not v.recent)) then
				v.x1 = last.x1;
				v.x2 = last.x2;
				v.y1 = last.y1;
				v.y2 = last.y2;
			else
				v.skipped = true;
			end
			
			v.ttl = v.ttl-delta;
			if(v.ttl <= 0) then	
				tableremove(self.segments,k);
				removed = true;
			else
				local tau = 0;
				if(v.targetX ~= nil or v.targetY ~= nil) then
					tau = self.targetTime(t);
				end
				if(v.targetX ~= nil) then
					v.x = v.targetX*tau + v.initX*(1-tau);
				else
					v.x = v.x + v.speedX*delta;
				end
				if(v.targetY ~= nil) then
					local tau = self.targetTime(t);
					v.y = v.targetY*tau + v.initY*(1-tau);
				else
					v.y = v.y + v.speedY*delta;
				end
				v.speedX = v.speedX+(v.accelX)*delta;
				v.initSpeedX = v.initSpeedX + (v.accelX)*delta;
				v.speedY = v.speedY+(v.accelY)*delta;
				v.initSpeedY = v.initSpeedY + (v.accelY)*delta;
				if not ispaused or updateWhilePaused then
					v.frametimer = v.frametimer-1;
				end
				if(v.frametimer == 0) then
					v.frame = (v.frame+1)%v.maxframes;
					v.frametimer = v.initFrametimer;
				end
			end
			if(not removed) then
				k = k+1;
			end
		end
			
		if(i > 0) then
			clearTables(self,i); --Remove junk data from previous draw operation
			
			Graphics.glDraw{texture=self.texture, vertexCoords=tris[self], textureCoords=txs[self], vertexColors=cols[self], priority=priority, sceneCoords=sceneCoords, color = color, target=rt}
		end
		
	end

end

---Particle Descriptor Files.
--Particle descriptior files are .ini files that contain configuration information about a particle or ribbon emitter.
--@section Particle Descriptor Files

--- Types that can be used in particle descriptor files.
-- @field number A decimal number (e.g. `2.5`).
-- @field int An integer number (e.g. `4`).
-- @field number_range Accepts either a single `number` or a pair of numbers of the form `0:0`. Values will be selected at random from between the two given numbers.
-- @field color 6 or 8 digit hexadecimal colour values of the form: `0xFFFFFFFF`. Can also be given as ranges of the form: `0xFFFFFFFF:0xFFFFFFFF`, or as lists of the form `{0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF}`.
-- @field number_grad Gradients of the form `{0,0,0},{0,0,0}`. The first list may contain a list of numbers between 0 and 1, while the second list may contain any `number`s. The lists should be the same length.  
-- @field color_grad Gradients of the form `{0,0,0},{0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF}`. The first list may contain a list of numbers between 0 and 1, while the second list may contain 6 or 8 digit hexadecimal `color` values (but not color ranges or lists). The lists should be the same length.  
-- @field texture The filename of a texture object, including extension. The file should be in the level folder or episode folder, or inside a `particles` or `graphics/particles` subfolder of either of those directories.
-- @field collide_mode Any of the following values: `none`, `stop`, `bounce`, `kill`.
-- @field collide_type Any of the following values: `coarse`, `fine`.
-- @field blend_mode Any of the following values: `alpha`, `additive`.
-- @field space_type Any of the following values: `world`, `local`.
-- @field update_mode Any of the following values: `seconds`, `frames`.
-- @field ribbon_mode Any of the following values: `continuous`, `disjoint`.
-- @field ribbon_scale Any of the following values: `center`, `centre`, `top`, `bottom`.
-- @table Types

--- Fields used for particle emitters.
-- @tfield[opt=1] number_range rate The rate at which particles spawn from the emitter. Set to 0 to manually control emission using the `emit` function.
-- @tfield[opt=1] number_range lifetime The time each particles will exist for before disappearing.
-- @tfield[opt=500] int limit The maximum number of live particles this emitter can manage at any one time. Will prevent more particles from spawning if this limit is reached.
-- @tfield number_range width The width of the particles in pixels. By default this will be the width of a single frame of the given texture, or 0 if no texture is defined.
-- @tfield number_range height The height of the particles in pixels. By default this will be the height of a single frame of the given texture, or 0 if no texture is defined.
-- @tfield[opt=0] number_range xOffset The initial x coordinate of newly spawned particles, relative to the emitter location.
-- @tfield[opt=0] number_range yOffset The initial y coordinate of newly spawned particles, relative to the emitter location.
-- @tfield[opt=0] number_range radOffset The initial distance of newly spawned particles from the emitter location, spawned at random angles.
-- @tfield texture texture The texture to use for particles spawned by this emitter. If none is provided, particles will be flat rectangles.
-- @tfield[opt=white] color col A color to tint every particle produced by the emitter (acts as a multiplier to other color modifiers).
-- @tfield[opt=0] number_range rotation The initial clockwise rotation of newly spawned particles, in degrees.
-- @tfield[opt=1] number_range scale A uniform scale multiplier applied to particles spawned by this emitter.
-- @tfield[opt=0] number_range speedX The initial horizontal speed of newly spawned particles.
-- @tfield[opt=0] number_range speedY The initial vertical speed of newly spawned particles.
-- @tfield[opt=0] number_range rotSpeed The initial clockwise rotational speed of newly spawned particles.
-- @tfield[opt=0] number_range accelX The horizontal acceleration of newly spawned particles.
-- @tfield[opt=0] number_range accelY The vertical acceleration of newly spawned particles.
-- @tfield number_range targetX A relative target x coordinate for particles spawned by this emitter, which particles can move towards. Setting this will override other speed-related values. 
-- @tfield number_range targetY A relative target y coordinate for particles spawned by this emitter, which particles can move towards. Setting this will override other speed-related values. 
-- @tfield[opt=1] number_range startFrame The starting frame of the animation for an individual particle.
-- @tfield[opt=1] int framesX The number of animation columns in the texture. Animation frames will be played one row after the other (horizontal first).
-- @tfield[opt=1] int framesY The number of animation rows in the texture. Animation frames will be played one row after the other (horizontal first).
-- @tfield[opt=8] number_range frameSpeed The delay between frames of animation. Smaller numbers mean faster animation.
-- @tfield[opt=180] int despawnTime The number of frames an off-screen particle system will take to deactivate. Set to `-1` to leave a particle system active at all times.
-- @tfield number_grad speedTime A gradient multiplier defining how both horizontal and vertical speed change over the lifetime of a particle.
-- @tfield number_grad speedXTime A gradient multiplier defining how horizontal speed changes over the lifetime of a particle.
-- @tfield number_grad speedYTime A gradient multiplier defining how vertical speed changes over the lifetime of a particle.
-- @tfield number_grad rotSpeedTime A gradient multiplier defining how rotational speed changes over the lifetime of a particle.
-- @tfield number_grad scaleTime A gradient multiplier defining how uniform size changes over the lifetime of a particle.
-- @tfield color_grad colTime A gradient multiplier defining how color and transparency change over the lifetime of a particle.
-- @tfield number_grad targetTime A gradient defining how position of a particle changes of the lifetime of the particle. Only applies if `targetX` or `targetY` is set.
-- @tfield number_grad speedScale A gradient multiplier defining how both horizontal and vertical speed change with the initial size of a particle.
-- @tfield number_grad speedXScale A gradient multiplier defining how horizontal speed change with the initial size of a particle.
-- @tfield number_grad speedYScale A gradient multiplier defining how vertical speed change with the initial size of a particle.
-- @tfield number_grad rotSpeedScale A gradient multiplier defining how rotational speed change with the initial size of a particle.
-- @tfield[opt=world] space_type space Determines how live particles react when the emitter is moved. If set to `world`, moving the emitter will only affect newly spawned particles. If set to `local`, live particles will move along with the emitter.
-- @tfield[opt=seconds] update_mode updateType Determines how speed, acceleration, and emission are calculated. If set to `seconds`, values are relative to real-world seconds (e.g. `rate=1` means one emit per second). If set to `frames`, values are relative to in-game ticks (e.g. `rate=1` means one emit per frame).
-- @tfield[opt=alpha] blend_mode blend Determines how particles should be rendered to the screen. If set to `alpha`, then particles will be rendered with standard alpha blending. If set to `additive`, particles will be rendered with additive blending. Additive blending should always use `color` values with 0 alpha transparency.
-- @tfield[opt=none] collide_mode collision Determines how particles collide with the environment. If set to `none`, no collision will occur. If set to `stop`, particles will lose all speed on impact. If set to `bounce`, particles will bounce on impact. If set to `kill`, particles will be immediately destroyed on impact.
-- @tfield[opt=fine] collide_type collisionType Determines how detailed collisions should be, if the `collision` parameter is not `none`. If set to `coarse`, particles will treat all objects as rectangles. If set to `fine`, particles will collide more accurately.
-- @tfield[opt=0.5] number_range bounceEnergy A multiplier applied to speed when particles bounce. Only used when `collision` is set to `bounce`.
-- @tfield number boundLeft The horizontal offset defining the left side of the emitter bounding box. This will be automatically calculated if undefined. 
-- @tfield number boundRight The horizontal offset defining the right side of the emitter bounding box. This will be automatically calculated if undefined. 
-- @tfield number boundTop The vertical offset defining the top side of the emitter bounding box. This will be automatically calculated if undefined. 
-- @tfield number boundBottom The vertical offset defining the bottom side of the emitter bounding box. This will be automatically calculated if undefined. 
-- @table @{Emitter}
-- @see Emitter


--- Fields used for ribbon trail emitters.
-- @tfield[opt=1] number_range rate The rate at which trail segments spawn from the emitter. Set to 0 to manually control emission using the `emit` function.
-- @tfield[opt=1] number_range lifetime The time each trail segment will exist for before disappearing.
-- @tfield number_range width The width of the trail in pixels. By default this will be the width of a single frame of the given texture, or 32 if no texture is defined.
-- @tfield[opt=0] number_range xOffset The x coordinate of the trail source, relative to the emitter location.
-- @tfield[opt=0] number_range yOffset The y coordinate of the trail source, relative to the emitter location.
-- @tfield texture texture The texture to use for trails spawned by this emitter. If none is provided, trails will be flat colors. Textures will be repeated along the horizontal axis of the texture. 
-- @tfield[opt=white] color col A color to tint the trail produced by the emitter (acts as a multiplier to other color modifiers).
-- @tfield[opt=0] number_range speedX The initial horizontal speed of newly spawned trail segments.
-- @tfield[opt=0] number_range speedY The initial vertical speed of newly spawned trail segments.
-- @tfield[opt=0] number_range accelX The horizontal acceleration of newly spawned trail segments.
-- @tfield[opt=0] number_range accelY The vertical acceleration of newly spawned trail segments.
-- @tfield number_range targetX A relative target x coordinate for trail segments spawned by this emitter, which segments can move towards. Setting this will override other speed-related values. 
-- @tfield number_range targetY A relative target y coordinate for trail segments spawned by this emitter, which segments can move towards. Setting this will override other speed-related values. 
-- @tfield[opt=1] int framesX The number of animation columns in the texture. Animation frames will be played one row after the other (horizontal first).
-- @tfield[opt=1] int framesY The number of animation rows in the texture. Animation frames will be played one row after the other (horizontal first).
-- @tfield[opt=8] number_range frameSpeed The delay between frames of animation. Smaller numbers mean faster animation.
-- @tfield[opt=60] number maxAngle The maximum change in angle (in degrees) a trail can make before it "breaks" and creates a new trail. If `ribbonType` is set to `continuous`, trails will stay connected.
-- @tfield number_grad speedTime A gradient multiplier defining how both horizontal and vertical speed change over the lifetime of a trail segment.
-- @tfield number_grad speedXTime A gradient multiplier defining how horizontal speed changes over the lifetime of a trail segment.
-- @tfield number_grad speedYTime A gradient multiplier defining how vertical speed changes over the lifetime of a trail segment.
-- @tfield number_grad scaleTime A gradient multiplier defining how uniform size changes over the lifetime of a trail segment.
-- @tfield color_grad colTime A gradient multiplier defining how color and transparency change over the lifetime of a trail segment.
-- @tfield number_grad targetTime A gradient defining how position of a trail segment changes of the lifetime of the segment. Only applies if `targetX` or `targetY` is set.
-- @tfield number_grad scaleLength A gradient multiplier defining how the trail width changes over the length of a trail. `0` maps to the start of a trail, `1` maps to the end of a trail.
-- @tfield number_grad colLength A gradient multiplier defining how the trail color and transparency change over the length of a trail. `0` maps to the start of a trail, `1` maps to the end of a trail.
-- @tfield number_grad speedYScale A gradient multiplier defining how vertical speed change with the initial size of a particle.
-- @tfield[opt=seconds] update_mode updateType Determines how speed, acceleration, and emission are calculated. If set to `seconds`, values are relative to real-world seconds (e.g. `rate=1` means one emit per second). If set to `frames`, values are relative to in-game ticks (e.g. `rate=1` means one emit per frame).
-- @tfield[opt=alpha] blend_mode blend Determines how trails should be rendered to the screen. If set to `alpha`, then trails will be rendered with standard alpha blending. If set to `additive`, trails will be rendered with additive blending. Additive blending should always use `color` values with 0 alpha transparency.
-- @tfield[opt=continuous] ribbon_mode ribbonType Determines how trail segments are connected when "breaks" occur. If this is set to `continuous`, broken trails will be connected together again when they are both stable. If this is set to `disjoint`, broken trails will leave a gap.
-- @tfield[opt=center] ribbon_scale scaleType Determines how trail segments are scaled by `scaleTime`. If set to `center` or `centre`, trails will scale from the middle. If set to `top`, trails will scale from the top edge. If set to `bottom`, trails will scale from the bottom edge.
-- @table @{Ribbon}
-- @see Ribbon
	
return particles;