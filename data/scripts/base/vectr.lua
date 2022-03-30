--********************************--
--** _    __          __  ____  **--
--**| |  / /__  _____/ /_/ __ \ **--
--**| | / / _ \/ ___/ __/ /_/ / **--
--**| |/ /  __/ /__/ /_/ _, _/  **--
--**|___/\___/\___/\__/_/ |_|   **--
--**                            **--
--********************************--
------Created by Hoeloe - 2015------
-----Open-Source Vector Library-----
-------For Super Mario Bros X-------
----------------v1.0f---------------

local vectr = {};
local version = "1.0f";

local sin = math.sin;
local cos = math.cos;
local sqrt = math.sqrt;
local log = math.log;

local atan2 = math.atan2
local acos = math.acos
local asin = math.asin
local rad = math.rad
local deg = math.deg

local min = math.min
local abs = math.abs

local type = type
local setmetatable = setmetatable

local v2mt = {};
local v3mt = {};
local v4mt = {};
local quatmt = {}

local function fastv2(x,y)
	return setmetatable({x, y}, v2mt);
end

local function fastv3(x,y,z)
	return setmetatable({x, y, z}, v3mt);
end

local function fastv4(x,y,z,w)
	return setmetatable({x, y, z, w}, v4mt);
end

local function fastquat(w,x,y,z, nrm)
	return setmetatable({w,x,y,z, __nrm = nrm or false}, quatmt);
end

local quatapply;

local mat2_mt = {};
local mat3_mt = {};
local mat4_mt = {};

local fastmat2;
local fastmat3;
local fastmat4;

local function mat2to3(a)
	return fastmat3(a[1],a[3],0,	a[2],a[4],0,	0,0,1)
end
local function mat2to4(a)
	return fastmat4(a[1],a[3],0,0,	a[2],a[4],0,0,	0,0,1,0,	0,0,0,1)
end
local function mat3to2(a)
	return fastmat2(a[1],a[4],	a[2],a[5])
end
local function mat3to4(a)
	return fastmat4(a[1],a[4],a[7],0,	a[2],a[5],a[8],0,	a[3],a[6],a[9],0,	0,0,0,1)
end
local function mat4to3(a)
	return fastmat3(a[1],a[5],a[9],	a[2],a[6],a[10],	a[3],a[7],a[11])
end
local function mat4to2(a)
	return fastmat2(a[1],a[5],	a[2],a[6])
end

local function mat2get(a,i,j)
	return a[j + (i-1)*2];
end
local function mat2set(a,i,j,v)
	a[j + (i-1)*2] = v;
end

local function mat3get(a,i,j)
	return a[j + (i-1)*3];
end
local function mat3set(a,i,j,v)
	a[j + (i-1)*3] = v;
end

local function mat4get(a,i,j)
	return a[j + (i-1)*4];
end
local function mat4set(a,i,j,v)
	a[j + (i-1)*4] = v;
end

function fastmat2(_11, _12, _21, _22)
	return setmetatable({_11,_21,_12,_22, tomat3 = mat2to3, tomat4 = mat2to4, get = mat2get, set = mat2set},mat2_mt)
end

function fastmat3(_11, _12, _13, _21, _22, _23, _31, _32, _33)
	return setmetatable({_11,_21,_31,_12,_22,_32,_13,_23,_33, tomat2 = mat3to2, tomat4 = mat3to4, get = mat3get, set = mat3set},mat3_mt)
end

function fastmat4(_11, _12, _13, _14, _21, _22, _23, _24, _31, _32, _33, _34, _41, _42, _43, _44)
	return setmetatable({_11,_21,_31,_41,_12,_22,_32,_42,_13,_23,_33,_43,_14,_24,_34,_44, tomat2 = mat4to2, tomat3 = mat4to3, get = mat4get, set = mat4set},mat4_mt)
end


local function eq(a,b)
	if #a ~= #b then
		return false;
	end
	
	for i = 1,#a do
		if(b[i] ~= a[i]) then
			return false;
		end
	end
	
	return true;
end



do --Serialization

	local serializer = require("ext/serializer")
	
	local numtostring = serializer.convertnumber
	local match = string.match

	local function serialize(v) 
		local t
		for k,w in ipairs(v) do
			if k == 1 then
				t = numtostring(w)
			else
				t = t..":"..numtostring(w)
			end
		end
		return t
	end
														
	local function parsev2(v) 
		local x,y = match(v,"([^:]+):([^:]+)")
		return fastv2(tonumber(x),tonumber(y))
	end												
	local function parsev3(v) 
		local x,y,z = match(v,"([^:]+):([^:]+):([^:]+)")
		return fastv3(tonumber(x),tonumber(y),tonumber(z))
	end										
	local function parsev4(v) 
		local x,y,z,w = match(v,"([^:]+):([^:]+):([^:]+):([^:]+)")
		return fastv4(tonumber(x),tonumber(y),tonumber(z),tonumber(w))
	end			
	
	local function parsemat2(v) 
		local a,c,b,d = match(v,"([^:]+):([^:]+):([^:]+):([^:]+)")
		return fastmat2(tonumber(a),tonumber(b),tonumber(c),tonumber(d))
	end		
	
	local function parsemat3(v) 
		local a,d,g,b,e,h,c,f,i = match(v,"([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
		return fastmat3(tonumber(a),tonumber(b),tonumber(c),tonumber(d),tonumber(e),tonumber(f),tonumber(g),tonumber(h),tonumber(i))
	end		
	
	local function parsemat4(v) 
		local a,e,i,m,b,f,j,n,c,g,k,o,d,h,l,p = match(v,"([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
		return fastmat4(tonumber(a),tonumber(b),tonumber(c),tonumber(d),tonumber(e),tonumber(f),tonumber(g),tonumber(h),tonumber(i),tonumber(j),tonumber(k),tonumber(l),tonumber(m),tonumber(n),tonumber(o),tonumber(p))
	end			

	local function serializequat(v) 
		local t = ""
		for _,w in ipairs(v) do
			t = t..numtostring(w)..":"
		end
		if v.__nrm then
			return t.."t"
		else
			return t.."f"
		end
		return t
	end
	
	local function parsequat(v) 
		local x,y,z,w,n = match(v,"([^:]+):([^:]+):([^:]+):([^:]+):([tf])")
		return fastv4(tonumber(x),tonumber(y),tonumber(z),tonumber(w),n == "t")
	end

	serializer.register("Vector2", serialize, parsev2)
	serializer.register("Vector3", serialize, parsev3)
	serializer.register("Vector4", serialize, parsev4)
	serializer.register("Quaternion", serializequat, parsequat)
	serializer.register("Mat2", serialize, parsemat2)
	serializer.register("Mat3", serialize, parsemat3)
	serializer.register("Mat4", serialize, parsemat4)
end

do --VECTOR

local function proj(a,b)
	local n = b:normalise();
	return (a:dot(n))*n;
end
					
--Construct a vector object from a simple table containing x,y,(z,w) values
function vectr.deserialise(val)
	if(type(val) ~= "table") then return nil end;
	
	local vkeys = {x=false,y=false,z=false,w=false};
	for k,v in pairs(val) do
		if(vkeys[k] ~= nil and type(v) == "number") then
			vkeys[k] = true;
		else
			return nil;
		end
	end
	if(vkeys.x and vkeys.y) then
		if(vkeys.z) then
			if(vkeys.w) then --x,y,z,w
				return fastv4(val.x,val.y,val.z,val.w);
			else --x,y,z
				return fastv3(val.x,val.y,val.z);
			end
		elseif(vkeys.w) then --x,y,w is not a vector
			return nil;
		else --x,y
			return fastv2(val.x, val.y)
		end
	else --all vectors must contain at least x,y
		return nil;
	end
end

do --Vector 2

--CLASS DEF
local vect2 = {};

local function v2mt_typecheck(a)
	local t = type(a)
	if(t == "number" or t == "Vector2") then
		return t;
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

function vect2.normalise(a)
	if(a.sqrlength == 0) then 
		return fastv2(0,0)
	elseif(a.sqrlength == 1) then
		return a;
	else
		local l = a.length;
		return fastv2(a[1]/l,a[2]/l);
	end
end

function vect2.rotate(a,d)
	local r = rad(d);
	local sr = sin(r);
	local cr = cos(r);
	return fastv2(a[1]*cr - a[2]*sr, a[1]*sr + a[2]*cr);
end

function vect2.lookat(a,x1,y1)
	local v;
	local t = v2mt_typecheck(x1);
	if(t == "number") then
		v = fastv2(x1,y1):normalise();
	else
		v = x1:normalise();
	end
	return v*a.length;
end

function vect2.tov3(a)
	return fastv3(a[1],a[2],0);
end

function vect2.tov4(a)
	return fastv3(a[1],a[2],0,0);
end

function vect2.dot(a,b) 
	return a[1]*b[1] + a[2]*b[2]; 
end

vect2.normalize = vect2.normalise;
vect2.project = proj;

--METATABLE

function v2mt.__index(obj,key)
		if(key == "x") then return rawget(obj, 1)
	elseif(key == "y") then return rawget(obj, 2)
	elseif(key == "sqrlength") then
		return obj[1]*obj[1] + obj[2]*obj[2]
	elseif(key == "length") then
		return sqrt(obj[1]*obj[1] + obj[2]*obj[2])
	elseif(key == "_type" or key == "__type") then
		return "Vector2";
	else
		return vect2[key]
	end
end

function v2mt.__newindex(obj,key,val)
		    if(key == "x") then rawset(obj, 1, val);
		elseif(key == "y") then rawset(obj, 2, val);
		elseif(key == "length" or key == "sqrlength") then
			error("Cannot set the length of a vector directly. Try changing the component values.",2)
		elseif(key == "_type" or key == "__type") then
			error("Cannot set the type of an object.",2)
		else
			error("Field "..key.." does not exist in the vector2 data structure.",2);
		end
end
	
function v2mt.__tostring(obj) 
	return "("..tostring(obj[1])..", "..tostring(obj[2])..")" 
end

function v2mt.__add(a,b) 
	local ta = v2mt_typecheck(a);
	local tb = v2mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			return fastv2(a+b[1],a+b[2])
		end
	elseif(type(b) == "number") then
			return fastv2(a[1]+b,a[2]+b)
	else
		return fastv2(a[1]+b[1],a[2]+b[2])
	end
end

function v2mt.__sub(a,b) 
	local ta = v2mt_typecheck(a);
	local tb = v2mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			return fastv2(a-b[1],a-b[2])
		end
	elseif(type(b) == "number") then
			return fastv2(a[1]-b,a[2]-b)
	else
		return fastv2(a[1]-b[1],a[2]-b[2])
	end
end

function v2mt.__unm(a)
	return fastv2(-a[1],-a[2]) 
end

function v2mt.__mul(a,b) 
	local ta = v2mt_typecheck(a);
	local tb = v2mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a*b;
		else
			return fastv2(a*b[1],a*b[2])
		end
	elseif(tb == "number") then
		return fastv2(a[1]*b,a[2]*b)
	else
		return fastv2(a[1]*b[1],a[2]*b[2]) 
	end
end
			   
function v2mt.__div(a,b) 
	local ta = v2mt_typecheck(a);
	local tb = v2mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a/b;
		else
			return fastv2(a/b[1],a/b[2])
		end
	elseif(tb == "number") then
			return fastv2(a[1]/b,a[2]/b)
	else
		return fastv2(a[1]/b[1],a[2]/b[2]) 
	end
end
			   
v2mt.__eq = eq;
v2mt.__type = "Vector2";

function v2mt.__concat(a,b)
	if type(a) ~= "Vector2" or type(b) ~= "Vector2" then
		return tostring(a)..tostring(b)
	else
		return vect2.dot(a,b)
	end
end
v2mt.__mod = proj;

--CONSTRUCTOR
function vectr.v2(x,y)
	if(type(x) == "number") then
		y = y or x;
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector2") then
		y = x[2];
		x = x[1];
	else
		error("Invalid vector definition.",2);
	end
	
	local v = {x, y};
	setmetatable(v, v2mt);
	return v;
end

function vectr.randomOnCircle(radius)
	radius = radius or 1
	local r = RNG.random(0,6.28318530718);
	return fastv2(-radius*sin(r), radius*cos(r));
end

function vectr.randomInCircle(radius)
	radius = radius or 1
	return vectr.randomOnCircle(sqrt(RNG.random())*radius);
end

function vectr.randomDir2()
	return vectr.randomOnCircle()
end

end

do --Vector 3

--CLASS DEF
local vect3 = {}

function v3mt_typecheck(a)
	local t = type(a)
	if(t == "number" or t == "Vector3") then
		return t;
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

function vect3.normalise(a)
	if(a.sqrlength == 0) then 
		return fastv3(0,0,0)
	elseif(a.sqrlength == 1) then
		return a;
	else
		local l = a.length;
		return fastv3(a[1]/l,a[2]/l,a[3]/l);
	end
end

function vect3.rotate(a,roll,pitch,yaw)
	if(type(pitch) == "number") then --euler
		local r_r = rad(roll); --deg2rad
		local p_r = rad(pitch); --deg2rad
		local y_r = rad(yaw); --deg2rad
		
		local cosx = cos(r_r);
		local sinx = sin(r_r);
		local cosy = cos(p_r);
		local siny = sin(p_r);
		local cosz = cos(y_r);
		local sinz = sin(y_r);
							 
		local x = a[1];
		local y = a[2];
		local z = a[3];	
		local t;
			
		--rotz
		t = x*cosz - y*sinz;
		y = x*sinz + y*cosz;
		
		x = t;
		
		--rot y
		t = x*cosy + z*siny;
		z = -x*siny + z*cosy;
		
		x = t;
		
		--rot x
		t = y*cosx - z*sinx
		z = y*sinx + z*cosx;
		
		y = t;
		
		return fastv3(x,y,z);			
	elseif(pitch ~= nil and pitch._type ~= nil and pitch._type == "Vector3") then --angleaxis
		local p = pitch:normalise();
		local x = rad(roll); --deg2rad
		local cosx = cos(x);
		local sinx = sin(x);
		return cosx*a + sinx*(p^a) + (1-cosx)*(p:dot(a))*p;
	elseif(roll ~= nil and roll._type ~= nil and roll._type == "Mat3") then --matrix
		return roll*a;
	else
		error("Invalid rotation format specified.",2)
	end
end

function vect3.lookat(a,x1,y1,z1)
	local v3;
	local t = v3mt_typecheck(x1);
	if(t == "number") then
		v3 = fastv3(x1,y1,z1):normalise();
	else
		v3 = x1:normalise();
	end
	return v3*a.length;
end

function vect3.planeproject(a,b)
	b = b:normalise();
	local n = a%b;
	return a-n;
end

function vect3.tov2(a)
	return fastv2(a[1],a[2]);
end

function vect3.tov4(a)
	return fastv4(a[1],a[2],a[3],0);
end

function vect3.dot(a,b)
	return a[1]*b[1] + a[2]*b[2] + a[3]*b[3];
end

function vect3.cross(a,b)
	return fastv3(a[2]*b[3] - a[3]*b[2], a[3]*b[1] - a[1]*b[3], a[1]*b[2] - a[2]*b[1])
end

vect3.normalize = vect3.normalise;
vect3.project = proj;

--METATABLE

function v3mt.__index(obj,key)
		if(key == "x") then return rawget(obj, 1)
	elseif(key == "y") then return rawget(obj, 2)
	elseif(key == "z") then return rawget(obj, 3)
	elseif(key == "sqrlength") then
		return obj[1]*obj[1] + obj[2]*obj[2] + obj[3]*obj[3]
	elseif(key == "length") then
		return sqrt(obj[1]*obj[1] + obj[2]*obj[2] + obj[3]*obj[3])
	elseif(key == "_type" or key == "__type") then
		return "Vector3";
	else
		return vect3[key]
	end
end

function v3mt.__newindex(obj,key,val)
		    if(key == "x") then rawset(obj, 1, val);
		elseif(key == "y") then rawset(obj, 2, val);
		elseif(key == "z") then rawset(obj, 3, val);
		elseif(key == "length" or key == "sqrlength") then
			error("Cannot set the length of a vector directly. Try changing the component values.",2)
		elseif(key == "_type" or key == "__type") then
			error("Cannot set the type of an object.",2)
		else
			error("Field "..key.." does not exist in the vector3 data structure.",2);
		end
end

function v3mt.__tostring(obj)
	return "("..tostring(obj[1])..", "..tostring(obj[2])..", "..tostring(obj[3])..")" 
end

function v3mt.__add(a,b)
	local ta = v3mt_typecheck(a);
	local tb = v3mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			return fastv3(a+b[1],a+b[2],a+b[3])
		end
	elseif(tb == "number") then
			return fastv3(a[1]+b,a[2]+b,a[3]+b)
	else
		return fastv3(a[1]+b[1],a[2]+b[2],a[3]+b[3]) 
	end
end

function v3mt.__sub(a,b)
	local ta = v3mt_typecheck(a);
	local tb = v3mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			return fastv3(a-b[1],a-b[2],a-b[3])
		end
	elseif(tb == "number") then
			return fastv3(a[1]-b,a[2]-b,a[3]-b)
	else
		return fastv3(a[1]-b[1],a[2]-b[2],a[3]-b[3]) 
	end
end

function v3mt.__unm(a) 
	return fastv3(-a[1],-a[2],-a[3])
end


function v3mt.__mul(a,b)
	local ta = v3mt_typecheck(a);
	local tb = v3mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a*b;
		else
			return fastv3(a*b[1],a*b[2],a*b[3])
		end
	elseif(ta == "Quaternion") then
		return quatapply(a,b)
	elseif(tb == "number") then
		return fastv3(a[1]*b,a[2]*b,a[3]*b)
	elseif(tb == "Quaternion") then
		return quatapply(b,a)
	else
		return fastv3(a[1]*b[1],a[2]*b[2],a[3]*b[3]) 
	end
end

function v3mt.__div(a,b)
	local ta = v3mt_typecheck(a);
	local tb = v3mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a/b;
		else
			return fastv3(a/b[1],a/b[2],a/b[3])
		end
	elseif(tb == "number") then
			return fastv3(a[1]/b,a[2]/b,a[3]/b)
	else
		return fastv3(a[1]/b[1],a[2]/b[2],a[3]/b[3]) 
	end
end

v3mt.__eq = eq;

v3mt.__type = "Vector3";

function v3mt.__concat(a,b)
	if type(a) ~= "Vector3" or type(b) ~= "Vector3" then
		return tostring(a)..tostring(b)
	else
		return vect3.dot(a,b)
	end
end

v3mt.__pow = vect3.cross;
v3mt.__mod = proj;

--CONSTRUCTOR
function vectr.v3(x,y,z)
	local v = {};
	
	if(type(x) == "number") then
		y = y or x;
		z = z or y;
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector2") then
		y = x[2];
		z = 0;
		x = x[1];
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector3") then
		y = x[2];
		z = x[3];
		x = x[1];
	else
		error("Invalid vector definition.",2)
	end
	
	v[1] = x;
	v[2] = y;
	v[3] = z;
	
	
	setmetatable(v,v3mt);
	return v;
end

local function boxmuller()
	local u = RNG.random(0,6.28318530718)
	local s = sqrt(-2*log(RNG.random(0,1)))
	return s*cos(u),s*sin(u)
end

local function singleboxmuller()
	local u = RNG.random(0,6.28318530718)
	local s = sqrt(-2*log(RNG.random(0,1)))
	return s*sin(u)
end

function vectr.randomOnSphere(radius)
	radius = radius or 1;
	
	local x,y = boxmuller()
	local z = singleboxmuller()
	
	local n = radius/sqrt(x*x + y*y + z*z)
	
	return fastv3(x*n,y*n,z*n)
end
   
function vectr.randomInSphere(radius)
	radius = radius or 1
	return vectr.randomOnSphere((RNG.random()^0.3333333333)*radius);
end

function vectr.randomDir3()
	return vectr.randomOnSphere()
end

end

do --Vector 4

--CLASS DEF
local vect4 = {}

local function v4mt_typecheck(a)
	local t = type(a)
	if(t == "number" or t == "Vector4") then
		return t;
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

function vect4.normalise(a)
	if(a.sqrlength == 0) then 
		return fastv4(0,0,0,0)
	elseif(a.sqrlength == 1) then
		return a;
	else
		local l = a.length;
		return fastv4(a[1]/l,a[2]/l,a[3]/l,a[4]/l);
	end
end

function vect4.rotate(a,roll,pitch,yaw)
	if(type(pitch) == "number") then --euler
		local r_r = rad(roll); --deg2rad
		local p_r = rad(pitch); --deg2rad
		local y_r = rad(yaw); --deg2rad
		
		local cosx = cos(r_r);
		local sinx = sin(r_r);
		local cosy = cos(p_r);
		local siny = sin(p_r);
		local cosz = cos(y_r);
		local sinz = sin(y_r);
							 
		local x = a[1];
		local y = a[2];
		local z = a[3];
		local t;
			
		--rotz
		t = x*cosz - y*sinz;
		y = x*sinz + y*cosz;
		
		x = t;
		
		--rot y
		t = x*cosy + z*siny;
		z = -x*siny + z*cosy;
		
		x = t;
		
		--rot x
		t = y*cosx - z*sinx;
		z = y*sinx + z*cosx;
		
		y = t;
		
		return fastv4(x,y,z,a[4]);			
	elseif(pitch ~= nil and pitch._type ~= nil and pitch._type == "Vector3") then --angleaxis
		local p = pitch:normalise();
		local x = rad(roll); --deg2rad
		local cosx = cos(x);
		local sinx = sin(x);
		local a3 = a:tov3();
		a3 = cosx*a3 + sinx*(p^a3) + (1-cosx)*(p:dot(a3))*p;
		return fastv4(a3[1],a3[2],a3[3],a[4]);
	elseif(roll ~= nil and roll._type ~= nil and roll._type == "Mat3") then --3matrix
		local a3 = a:tov3();
		a3 = roll*a3;
		return fastv4(a3[1],a3[2],a3[3],a[4]);
	elseif(roll ~= nil and roll._type ~= nil and roll._type == "Mat4") then --4matrix
		return roll*a;
	else
		error("Invalid rotation format specified.",2)
	end
end

function vect4.lookat(a,x1,y1,z1)
	local v3;
	if(type(x1) == "number") then
		v3 = fastv4(x1,y1,z1,1):normalise();
	elseif(x1 ~= nil and x1._type ~= nil and x1._type == "Vector3") then
		v3 = x1:normalise();
	else
		error("Invalid lookat vector.",2)
	end
	v3 = v3*(a:tov3()).length;
	return fastv4(v3[1],v3[2],v3[3],a[4])
end

function vect4.planeproject(a,b)
	b = b:normalise();
	local n = a%b;
	return a-n;
end

function vect4.dot(a,b)
	return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4];
end

function vect4.tov2(a)
	return fastv2(a[1],a[2]);
end

function vect4.tov3(a)
	return fastv3(a[1],a[2],a[3]);
end

vect4.normalize = vect4.normalise;
vect4.project = proj;

--METATABLE

function v4mt.__index(obj,key)
		if(key == "x") then return rawget(obj, 1)
	elseif(key == "y") then return rawget(obj, 2)
	elseif(key == "z") then return rawget(obj, 3)
	elseif(key == "w") then return rawget(obj, 4)
	elseif(key == "sqrlength") then
		return obj[1]*obj[1] + obj[2]*obj[2] + obj[3]*obj[3] + obj[4]*obj[4]
	elseif(key == "length") then
		return sqrt(obj[1]*obj[1] + obj[2]*obj[2] + obj[3]*obj[3] + obj[4]*obj[4])
	elseif(key == "_type" or key == "__type") then
		return "Vector4";
	else
		return vect4[key]
	end
end

function v4mt.__newindex(obj,key,val)
		    if(key == "x") then rawset(obj, 1, val);
		elseif(key == "y") then rawset(obj, 2, val);
		elseif(key == "z") then rawset(obj, 3, val);
		elseif(key == "w") then rawset(obj, 4, val);
		elseif(key == "length" or key == "sqrlength") then
			error("Cannot set the length of a vector directly. Try changing the component values.",2)
		elseif(key == "_type" or key == "__type") then
			error("Cannot set the type of an object.",2)
		else
			error("Field "..key.." does not exist in the vector3 data structure.",2);
		end
end

function v4mt.__tostring(obj)
	return "("..tostring(obj[1])..", "..tostring(obj[2])..", "..tostring(obj[3])..", "..tostring(obj[4])..")" 
end

function v4mt.__add(a,b)
	local ta = v4mt_typecheck(a);
	local tb = v4mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			return fastv4(a+b[1],a+b[2],a+b[3],a+b[4])
		end
	elseif(tb == "number") then
			return fastv4(a[1]+b,a[2]+b,a[3]+b,a[4]+b)
	else
		return fastv4(a[1]+b[1],a[2]+b[2],a[3]+b[3],a[4]+b[4]) 
	end
end

function v4mt.__sub(a,b)
	local ta = v4mt_typecheck(a);
	local tb = v4mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			return fastv4(a-b[1],a-b[2],a-b[3],a-b[4])
		end
	elseif(tb == "number") then
			return fastv4(a[1]-b,a[2]-b,a[3]-b,a[4]-b)
	else
		return fastv4(a[1]-b[1],a[2]-b[2],a[3]-b[3],a[4]-b[4]) 
	end
end

function v4mt.__unm(a) 
	return fastv4(-a[1],-a[2],-a[3],-a[4])
end

function v4mt.__mul(a,b)
	local ta = v4mt_typecheck(a);
	local tb = v4mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a*b;
		else
			return fastv4(a*b[1],a*b[2],a*b[3],a*b[4])
		end
	elseif(tb == "number") then
			return fastv4(a[1]*b,a[2]*b,a[3]*b,a[4]*b)
	else
		return fastv4(a[1]*b[1],a[2]*b[2],a[3]*b[3],a[4]*b[4]) 
	end
end

function v4mt.__div(a,b)
	local ta = v4mt_typecheck(a);
	local tb = v4mt_typecheck(b);
	if(ta == "number") then
		if(tb == "number") then
			return a/b;
		else
			return fastv4(a/b[1],a/b[2],a/b[3],a/b[4])
		end
	elseif(tb == "number") then
			return fastv4(a[1]/b,a[2]/b,a[3]/b,a[4]/b)
	else
		return fastv4(a[1]/b[1],a[2]/b[2],a[3]/b[3],a[4]/b[4]) 
	end
end

v4mt.__eq = eq;

v4mt.__type = "Vector4";

function v4mt.__concat(a,b)
	if type(a) ~= "Vector4" or type(b) ~= "Vector4" then
		return tostring(a)..tostring(b)
	else
		return vect4.dot(a,b)
	end
end
v4mt.__mod = proj;

--CONSTRUCTOR
function vectr.v4(x,y,z,w)
	local v = {};
	
	if(type(x) == "number") then
		y = y or x;
		z = z or y;
		w = w or 1;
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector2") then
		y = x.y;
		z = 0;
		w = 1;
		x = x.x;
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector3") then
		y = x.y;
		z = x.z;
		w = 1;
		x = x.x;
	elseif(x ~= nil and x._type ~= nil and x._type == "Vector4") then
		y = x.y;
		z = x.z;
		w = x.w;
		x = x.x;
	else
		error("Invalid vector definition.",2)
	end
	
	v[1] = x;
	v[2] = y;
	v[3] = z;
	v[4] = w;
	
	setmetatable(v,v4mt);
	return v;
end

end

end

do --MATRIX

local function trace(a,c)
	local t = 0;
	for i=1,c,1 do
		t = t+a[i + (i-1)*c];
	end
	return t;
end

do --Matrix 2x2

--METATABLE

mat2_mt.__index = function(obj,key)
	if(key == "det") then
		return obj[1]*obj[4] - obj[3]*obj[2];
	elseif(key == "trace") then
		return trace(obj,2);
	elseif(key == "inverse") then
		local d = obj.det;
		if(d == 0) then
			return nil; --Matrix is singular and has no inverse.
		end
		return fastmat2(obj[4]/d, -obj[3]/d, -obj[2]/d, obj[1]/d);
	elseif(key == "transpose") then
		return fastmat2(obj[1],obj[2],obj[3],obj[4]);
	elseif(key == "_type" or key == "__type") then
		return "Mat2";
	else
		return nil;
	end
end

local function mat2_mt_typecheck(a,b)
	local t = type(a)
	if t == "number" or t == "Mat2" or (b and t == "Vector2") then
		return t
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

mat2_mt.__newindex = function(obj,key,val)
	if(key == "det") then
		error("Cannot set the determinant of a matrix.",2)
	elseif(key == "trace") then
		error("Cannot set the trace of a matrix.",2)
	elseif(key == "inverse") then
		error("Cannot set the inverse of a matrix.",2)
	elseif(key == "transpose") then
		error("Cannot set the transpose of a matrix.",2)
	elseif(key == "_type" or key == "__type") then
		error("Cannot set the type of an object.",2)
	else
		error("Field "..key.." does not exist in the mat2 data structure.",2);
	end
end

mat2_mt.__add = function(a,b)
	local ta = mat2_mt_typecheck(a,false);
	local tb = mat2_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			local t = fastmat2(0,0,0,0);
			for i=1,4 do
				t[i] = b[i]+a;
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat2(0,0,0,0);
		for i=1,4 do
			t[i] = a[i]+b;
		end
		return t;
	else
		local t = fastmat2(0,0,0,0);
		for i=1,4 do
			t[i] = a[i]+b[i];
		end
		return t;
	end
end
mat2_mt.__sub = function(a,b)
	local ta = mat2_mt_typecheck(a,false);
	local tb = mat2_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			local t = fastmat2(0,0,0,0);
			for i=1,4 do
				t[i] = a-b[i];
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat2(0,0,0,0);
		for i=1,4 do
			t[i] = a[i]-b;
		end
			return t;
	else
		local t = fastmat2(0,0,0,0);
		for i=1,4 do
			t[i] = a[i]-b[i];
		end
		return t;
	end
end
mat2_mt.__unm = function(a) 
		local t = fastmat2(0,0,0,0);
		for i=1,4 do
			t[i] = -a[i];
		end
		return t;
end
mat2_mt.__mul = 
function(a,b)
	local ta = mat2_mt_typecheck(a,true);
	local tb = mat2_mt_typecheck(b,true);
	if(ta == "number") then
		if(tb == "number" or tb == "Vector2") then
			return a*b;
		else
			local t = fastmat2(0,0,0,0);
			for i=1,4 do
				t[i] = b[i]*a;
			end
			return t;
		end
	elseif(ta == "Vector2") then
		if(tb == "Mat2") then
			error("Invalid matrix multiplication.",2);
		else
			return a*b;
		end
	elseif(ta == "Mat2") then
		if(tb == "number") then
			local t = fastmat2(0,0,0,0);
			for i=1,4 do
				t[i] = a[i]*b;
			end
			return t;
		elseif(tb ==  "Vector2") then
							local t = fastv2(0,0);
							for i=1,2,1 do
								for j=1,2,1 do
									t[i] = t[i] + b[j]*a[i + (j-1)*2];
								end
							end
							return t;
		elseif(b._type ==  "Mat2") then
							local t = fastmat2(0,0,0,0);
							for i=1,2,1 do
								for j=1,2,1 do
									for k=1,2,1 do
										t[i + (j-1)*2] = t[i + (j-1)*2] + a[i + (k-1)*2]*b[k + (j-1)*2]
									end
								end
							end
							return t;
		else
			error("Invalid matrix multiplication.",2);
		end
	else
		error("Invalid matrix multiplication.",2);
	end
end
mat2_mt.__div =
function(a,b)
	local ta = mat2_mt_typecheck(a,true);
	local tb = mat2_mt_typecheck(b,true);
	if(tb == "Mat2") then
		if(ta ~= "Vector2") then
			return a*b.inverse;
		else
			error("Invalid matrix operation.",2);
		end
	elseif(tb == "Vector2") then
		if(ta == "Vector2" or ta == "number") then
			return a/b;
		else
			error("Invalid matrix operation.",2);
		end
	else
		if(ta == "Vector2" or ta == "number") then
			return a/b;
		else
			local t = fastmat2(0,0,0,0);
			for i=1,4 do
				t[i] = a[i]/b;
			end
			return t;
		end
	end
end

mat2_mt.__eq = eq;
mat2_mt.__tostring = function(obj) return "(("..tostring(obj[1])..", "..tostring(obj[3]).."),\n ("..tostring(obj[2])..", "..tostring(obj[4]).."))"; end
mat2_mt.__type = "Mat2";

--1 3
--2 4
--CONSTRUCTOR
function vectr.mat2(row1,row2,c,d)
	local m = {}
	--Flattened argument list
	if(type(d) == "number" and type(c) == "number" and type(row2) == "number" and type(row1) == "number") then
		m[1]=row1;
		m[2]=row2;
		m[3]=c;
		m[4]=d;
	--Other matrix or flattened table
	elseif((row1._type ~= nil and row1._type == "Mat2") or (row1._type == nil and type(row1) == "table" and row2 == nil)) then
		for k,v in ipairs(row1) do
			m[k]=v;
		end
	--Other matrix or vector types are invalid
	elseif(row1._type ~= nil and row1._type ~= "Mat2") then
		error("Invalid matrix definition - invalid arguments.",2)
	--Lists of the wrong length are invalid
	elseif(#row1 ~= 2 or row2 == nil or #row2 ~= 2) then
		error("Invalid matrix definition - wrong number of matrix elements.",2)
	else
		m[1]=row1[1];
		m[2]=row2[1];
		m[3]=row1[2];
		m[4]=row2[2];
	end
	
	
	m.tomat3 = mat2to3;
	m.tomat4 = mat2to4;
	m.get = mat2get;
	m.set = mat2set;
	
	setmetatable(m,mat2_mt)
	return m;
end

end

do --Matrix 3x3

mat3_mt.__index = function(obj,key)
	if(key == "det") then
		return obj[1]*(obj[5]*obj[9] - obj[8]*obj[6]) - obj[4]*(obj[2]*obj[9] - obj[8]*obj[3]) + obj[7]*(obj[2]*obj[6] - obj[5]*obj[3])
	elseif(key == "trace") then
		return trace(obj,3)
	elseif(key == "inverse") then
		local d = obj.det;
		if(d == 0) then
			return nil; --Matrix is singular and has no inverse.
		end
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,3,1 do
			local i2 = (i%3)+1;
			local i3 = (i2%3)+1
			for j=1,3,1 do
				local j2 = (j%3)+1;
				local j3 = (j2%3)+1
				t[i + (j-1)*3] = (obj[j2 + (i2-1)*3]*obj[j3 + (i3-1)*3]) - (obj[j3 + (i2-1)*3]*obj[j2 + (i3-1)*3])
				--t:set(i,j, obj:get(j2,i2)*obj:get(j3,i3) - obj:get(j3,i2)*obj:get(j2,i3));
			end
		end
		return t/d;
	elseif(key == "transpose") then
		return fastmat3(obj[1],obj[2],obj[3],obj[4],obj[5],obj[6],obj[7],obj[8],obj[9]);
	elseif(key == "_type" or key == "__type") then
		return "Mat3";
	else
		return nil;
	end
end

local function mat3_mt_typecheck(a,b)
	local t = type(a)
	if t == "number" or t == "Mat3" or (b and t == "Vector3") then
		return t
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

mat3_mt.__newindex = function(obj,key,val)
	if(key == "det") then
		error("Cannot set the determinant of a matrix.",2)
	elseif(key == "trace") then
		error("Cannot set the trace of a matrix.",2)
	elseif(key == "inverse") then
		error("Cannot set the inverse of a matrix.",2)
	elseif(key == "transpose") then
		error("Cannot set the transpose of a matrix.",2)
	elseif(key == "_type" or key == "__type") then
		error("Cannot set the type of an object.",2)
	else
		error("Field "..key.." does not exist in the mat3 data structure.",2);
	end
end
mat3_mt.__add = function(a,b)
	local ta = mat3_mt_typecheck(a,false);
	local tb = mat3_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			local t = fastmat3(0,0,0,0,0,0,0,0,0);
			for i=1,9 do
				t[i] = b[i]+a;
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,9 do
			t[i] = a[i]+b;
		end
		return t;
	else
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,9 do
			t[i] = a[i]+b[i];
		end
		return t;
	end
end
mat3_mt.__sub = function(a,b)
	local ta = mat3_mt_typecheck(a,false);
	local tb = mat3_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			local t = fastmat3(0,0,0,0,0,0,0,0,0);
			for i=1,9 do
				t[i] = a-b[i];
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,9 do
			t[i] = a[i]-b;
		end
		return t;
	else
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,9 do
			t[i] = a[i]-b[i];
		end
		return t;
	end
end
mat3_mt.__unm = 
function(a) 
		local t = fastmat3(0,0,0,0,0,0,0,0,0);
		for i=1,9 do
			t[i] = -a[i];
		end
		return t;
end

mat3_mt.__mul = function(a,b)
	local ta = mat3_mt_typecheck(a,true);
	local tb = mat3_mt_typecheck(b,true);
	if(ta == "number") then
		if(tb == "number" or tb == "Vector3") then
			return a*b;
		else
			local t = fastmat3(0,0,0,0,0,0,0,0,0);
			for i=1,9 do
				t[i] = b[i]*a;
			end
			return t;
		end
	elseif(ta == "Vector3") then
		if(tb == "Mat3") then
			error("Invalid matrix multiplication.",2);
		else
			return a*b;
		end
	elseif(ta == "Mat3") then
		if(tb == "number") then
			local t = fastmat3(0,0,0,0,0,0,0,0,0);
			for i=1,9 do
				t[i] = a[i]*b;
			end
			return t;
		elseif(tb ==  "Vector3") then
							local t = fastv3(0,0,0);
							for i=1,3,1 do
								for j=1,3,1 do
									t[i] = t[i] + b[j]*a[i + (j-1)*3];
								end
							end
							return t;
		elseif(b._type ==  "Mat3") then
							local t = fastmat3(0,0,0,0,0,0,0,0,0);
							for i=1,3,1 do
								for j=1,3,1 do
									for k=1,3,1 do
										t[i + (j-1)*3] = t[i + (j-1)*3] + a[i + (k-1)*3]*b[k + (j-1)*3];
										--t:set(i,j,t:get(i,j) + a:get(i,k)*b:get(k,j));
									end
								end
							end
							return t;
		else
			error("Invalid matrix multiplication.",2);
		end
	else
		error("Invalid matrix multiplication.",2);
	end
end

mat3_mt.__div =
function(a,b)
	local ta = mat3_mt_typecheck(a,true);
	local tb = mat3_mt_typecheck(b,true);
	if(tb == "Mat3") then
		if(ta ~= "Vector3") then
			return a*b.inverse;
		else
			error("Invalid matrix operation.",2);
		end
	elseif(tb == "Vector3") then
		if(ta == "Vector3" or ta == "number") then
			return a/b;
		else
			error("Invalid matrix operation.",2);
		end
	else
		if(ta == "Vector3" or ta == "number") then
			return a/b;
		else
			local t = fastmat3(0,0,0,0,0,0,0,0,0);
			for i=1,9 do
				t[i] = a[i]/b;
			end
			return t;
		end
	end
end


mat3_mt.__eq = eq;
mat3_mt.__tostring = function(obj) return "(("..tostring(obj[1])..", "..tostring(obj[4])..", "..tostring(obj[7]).."),\n ("..tostring(obj[2])..", "..tostring(obj[5])..", "..tostring(obj[8]).."),\n ("..tostring(obj[3])..", "..tostring(obj[6])..", "..tostring(obj[9]).."))"; end
mat3_mt.__type = "Mat3";

--1 4 7
--2 5 8
--3 6 9
--CONSTRUCTOR
function vectr.mat3(row1,row2,row3,d,e,f,g,h,i)

	local m = {}
	--Flattened argument list
	if(type(i) == "number" and type(h) == "number" and type(g) == "number" 
	and type(f) == "number" and type(e) == "number" and type(d) == "number" 
	and type(row3) == "number" and type(row2) == "number" and type(row1) == "number") then
		m[1]=row1;
		m[2]=row2;
		m[3]=row3;
		m[4]=d;
		m[5]=e;
		m[6]=f;
		m[7]=g;
		m[8]=h;
		m[9]=i;
	--Other matrix or flattened table
	elseif((row1._type ~= nil and row1._type == "Mat3") or (row1._type == nil and type(row1) == "table" and row2 == nil)) then
		for k,v in ipairs(row1) do
			m[k]=v;
		end
	--Other matrix or vector types are invalid
	elseif(row1._type ~= nil and row1._type ~= "Mat3") then
		error("Invalid matrix definition - invalid arguments.",2)
	--Lists of the wrong length are invalid
	elseif(#row1 ~= 3 or row2 == nil or #row2 ~= 3 or row3 == nil or #row3 ~= 3) then
		error("Invalid matrix definition - wrong number of matrix elements.",2)
	else
		m[1]=row1[1];
		m[2]=row2[1];
		m[3]=row3[1];
		m[4]=row1[2];
		m[5]=row2[2];
		m[6]=row3[2];
		m[7]=row1[3];
		m[8]=row2[3];
		m[9]=row3[3];
	end
	
	
	m.tomat2 = mat3to2;
	m.tomat4 = mat3to4;
	m.get = mat3get;
	m.set = mat3set;
	
	setmetatable(m,mat3_mt)
	return m;
end

end

do --Matrix 4x4


--1  5   9 13
--2  6  10 14
--3  7  11 15
--4  8  12 16

--METATABLE

mat4_mt.__index = function(obj,key)
	if(key == "det") then
		return obj[13]*(obj[10]*(obj[7]*obj[4] - obj[3]*obj[8]) + obj[6]*(obj[3]*obj[12] - obj[11]*obj[4]) + obj[2]*(obj[11]*obj[8] - obj[7]*obj[12])) +
			   obj[5]*obj[2]*(obj[15]*obj[12] - obj[11]*obj[16]) + obj[5]*(obj[14]*(obj[11]*obj[4] - obj[3]*obj[12]) + obj[10]*(obj[3]*obj[16] - obj[15]*obj[4])) +
			   obj[9]*(obj[14]*(obj[3]*obj[8]-obj[7]*obj[4]) + obj[6]*(obj[15]*obj[4]-obj[3]*obj[16]) + obj[2]*(obj[7]*obj[16]-obj[15]*obj[8])) +
			   obj[1]*(obj[14]*(obj[7]*obj[12]-obj[11]*obj[8]) + obj[10]*(obj[15]*obj[8]-obj[7]*obj[16]) + obj[6]*(obj[11]*obj[16]-obj[15]*obj[12]))
	elseif(key == "trace") then
		return trace(obj,4);
	elseif(key == "inverse") then
		local d = obj.det;
		if(d == 0) then
			return nil; --Matrix is singular and has no inverse.
		end
		return (1/d)*fastmat4(-obj[8]*(obj[14]*obj[11]-obj[10]*obj[15]) + obj[12]*(obj[14]*obj[7] - obj[6]*obj[15]) - obj[16]*(obj[10]*obj[7] - obj[6]*obj[11]),
									    obj[8]*(obj[13]*obj[11]-obj[9]*obj[15]) - obj[12]*(obj[13]*obj[7] - obj[5]*obj[15]) + obj[16]*(obj[9]*obj[7] - obj[5]*obj[11]),
									   -obj[8]*(obj[13]*obj[10]-obj[9]*obj[14]) + obj[12]*(obj[13]*obj[6] - obj[5]*obj[14]) - obj[16]*(obj[9]*obj[6] - obj[5]*obj[10]),
									    obj[7]*(obj[13]*obj[10]-obj[9]*obj[14]) - obj[11]*(obj[13]*obj[6] - obj[5]*obj[14]) + obj[15]*(obj[9]*obj[6] - obj[5]*obj[10]),
										
									   obj[4]*(obj[14]*obj[11]-obj[10]*obj[15]) - obj[12]*(obj[14]*obj[3] - obj[2]*obj[15]) + obj[16]*(obj[10]*obj[3] - obj[2]*obj[11]),
									   -obj[4]*(obj[13]*obj[11]-obj[9]*obj[15]) + obj[12]*(obj[13]*obj[3] - obj[1]*obj[15]) - obj[16]*(obj[9]*obj[3] - obj[1]*obj[11]),
									    obj[4]*(obj[13]*obj[10]-obj[9]*obj[14]) - obj[12]*(obj[13]*obj[2] - obj[1]*obj[14]) + obj[16]*(obj[9]*obj[2] - obj[1]*obj[10]),
									   -obj[3]*(obj[13]*obj[10]-obj[9]*obj[14]) + obj[11]*(obj[13]*obj[2] - obj[1]*obj[14]) - obj[15]*(obj[9]*obj[2] - obj[1]*obj[10]),
									   
									  -obj[4]*(obj[14]*obj[7]-obj[6]*obj[15]) + obj[8]*(obj[14]*obj[3] - obj[2]*obj[15]) - obj[16]*(obj[6]*obj[3] - obj[2]*obj[7]),
									    obj[4]*(obj[13]*obj[7]-obj[5]*obj[15]) - obj[8]*(obj[13]*obj[3] - obj[1]*obj[15]) + obj[16]*(obj[5]*obj[3] - obj[1]*obj[7]),
									   -obj[4]*(obj[13]*obj[6]-obj[5]*obj[14]) + obj[8]*(obj[13]*obj[2] - obj[1]*obj[14]) - obj[16]*(obj[5]*obj[2] - obj[1]*obj[6]),
									    obj[3]*(obj[13]*obj[6]-obj[5]*obj[14]) - obj[7]*(obj[13]*obj[2] - obj[1]*obj[14]) + obj[15]*(obj[5]*obj[2] - obj[1]*obj[6]),
										
									   obj[4]*(obj[10]*obj[7]-obj[6]*obj[11]) - obj[8]*(obj[10]*obj[3] - obj[2]*obj[11]) + obj[12]*(obj[6]*obj[3] - obj[2]*obj[7]),
									   -obj[4]*(obj[9]*obj[7]-obj[5]*obj[11]) + obj[8]*(obj[9]*obj[3] - obj[1]*obj[11]) - obj[12]*(obj[5]*obj[3] - obj[1]*obj[7]),
									    obj[4]*(obj[9]*obj[6]-obj[5]*obj[10]) - obj[8]*(obj[9]*obj[2] - obj[1]*obj[10]) + obj[12]*(obj[5]*obj[2] - obj[1]*obj[6]),
									   -obj[3]*(obj[9]*obj[6]-obj[5]*obj[10]) + obj[7]*(obj[9]*obj[2] - obj[1]*obj[10]) - obj[11]*(obj[5]*obj[2] - obj[1]*obj[6]));
	elseif(key == "transpose") then
		return fastmat4(obj[1],obj[2],obj[3],obj[4],obj[5],obj[6],obj[7],obj[8],obj[9],obj[10],obj[11],obj[12],obj[13],obj[14],obj[15],obj[16]);
	elseif(key == "_type" or key == "__type") then
		return "Mat4";
	else 
		return nil;
	end
end

local function mat4_mt_typecheck(a,b)
	local t = type(a)
	if t == "number" or t == "Mat4" or (b and t == "Vector4") then
		return t
	else
		error("Calculation cannot be performed on an object of this type: "..t, 2);
	end
end

mat4_mt.__newindex = function(obj,key,val)
	if(key == "det") then
		error("Cannot set the determinant of a matrix.",2)
	elseif(key == "trace") then
		error("Cannot set the trace of a matrix.",2)
	elseif(key == "inverse") then
		error("Cannot set the inverse of a matrix.",2)
	elseif(key == "transpose") then
		error("Cannot set the transpose of a matrix.",2)
	elseif(key == "_type" or key == "__type") then
		error("Cannot set the type of an object.",2)
	else
		error("Field "..key.." does not exist in the mat4 data structure.",2);
	end
end
mat4_mt.__add = function(a,b)
	local ta = mat4_mt_typecheck(a,false);
	local tb = mat4_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a+b;
		else
			local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
			for i=1,16 do
				t[i] = b[i]+a;
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		for i=1,16 do
			t[i] = a[i]+b;
		end
		return t;
	else
		local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		for i=1,16 do
			t[i] = a[i]+b[i];
		end
		return t;
	end
end
												
mat4_mt.__sub = function(a,b)
	local ta = mat4_mt_typecheck(a,false);
	local tb = mat4_mt_typecheck(b,false);
	if(ta == "number") then
		if(tb == "number") then
			return a-b;
		else
			local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
			for i=1,16 do
				t[i] = a-b[i];
			end
			return t;
		end
	elseif(tb == "number") then
		local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		for i=1,16 do
			t[i] = a[i]-b;
		end
		return t;
	else
		local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		for i=1,16 do
			t[i] = a[i]-b[i];
		end
		return t;
	end
end
												
mat4_mt.__unm = function(a)
		local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
		for i=1,16 do
			t[i] = -a[i];
		end
		return t;
end

mat4_mt.__mul = 
function(a,b)
	local ta = mat4_mt_typecheck(a,true);
	local tb = mat4_mt_typecheck(b,true);
	if(ta == "number") then
		if(tb == "number" or tb == "Vector4") then
			return a*b;
		else
			local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
			for i=1,16 do
				t[i] = b[i]*a;
			end
			return t;
		end
	elseif(ta == "Vector4") then
		if(tb == "Mat4") then
			error("Invalid matrix multiplication.",2);
		else
			return a*b;
		end
	elseif(ta == "Mat4") then
		if(tb == "number") then
			local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
			for i=1,16 do
				t[i] = a[i]*b;
			end
			return t;
		elseif(tb ==  "Vector4") then
							local t = fastv4(0,0,0,0);
							for i=1,4,1 do
								for j=1,4,1 do
									t[i] = t[i] + b[j]*a[i + (j-1)*4];
								end
							end
							return t;
		elseif(b._type ==  "Mat4") then
							local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
							for i=1,4,1 do
								for j=1,4,1 do
									for k=1,4,1 do
										t[i + (j-1)*4] = t[i + (j-1)*4] + a[i + (k-1)*4]*b[k + (j-1)*4]
										--t:set(i,j, t:get(i,j) + a:get(i,k)*b:get(k,j))
									end
								end
							end
							return t;
		else
			error("Invalid matrix multiplication.",2);
		end
	else
		error("Invalid matrix multiplication.",2);
	end
end
	
mat4_mt.__div =
function(a,b)
	local ta = mat4_mt_typecheck(a,true);
	local tb = mat4_mt_typecheck(b,true);
	if(tb == "Mat4") then
		if(ta ~= "Vector4") then
			return a*b.inverse;
		else
			error("Invalid matrix operation.",2);
		end
	elseif(tb == "Vector4") then
		if(ta == "Vector4" or ta == "number") then
			return a/b;
		else
			error("Invalid matrix operation.",2);
		end
	else
		if(ta == "Vector4" or ta == "number") then
			return a/b;
		else
			local t = fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
			for i=1,16 do
				t[i] = a[i]/b;
			end
			return t;
		end
	end
end


mat4_mt.__eq = eq;
mat4_mt.__tostring = function(obj) return "(("..tostring(obj[1])..", "..tostring(obj[5])..", "..tostring(obj[9])..", "..tostring(obj[13]).."),\n ("..
												tostring(obj[2])..", "..tostring(obj[6])..", "..tostring(obj[10])..", "..tostring(obj[14]).."),\n ("..
												tostring(obj[3])..", "..tostring(obj[7])..", "..tostring(obj[11])..", "..tostring(obj[15]).."),\n ("..
												tostring(obj[4])..", "..tostring(obj[8])..", "..tostring(obj[12])..", "..tostring(obj[16]).."))"; end
mat4_mt.__type = "Mat4";

	
--1  5   9 13
--2  6  10 14
--3  7  11 15
--4  8  12 16
--CONSTRUCTOR
function vectr.mat4(row1, row2, row3, row4, e, f, g, h, i, j, k, l, n, o, p, q)
	local m = {}
	--Flattened argument list
	if(type(q) == "number" and type(p) == "number" and type(o) == "number" and type(n) == "number"
	and type(l) == "number" and type(k) == "number" and type(j) == "number" and type(i) == "number" 
	and type(h) == "number" and type(g) == "number" and type(f) == "number" and type(e) == "number" 
	and type(row4) == "number" and type(row3) == "number" and type(row2) == "number" and type(row1) == "number") then
		m[1]=row1;
		m[2]=row2;
		m[3]=row3;
		m[4]=row4;
		m[5]=e;
		m[6]=f;
		m[7]=g;
		m[8]=h;
		m[9]=i;
		m[10]=j;
		m[11]=k;
		m[12]=l;
		m[13]=n;
		m[14]=o;
		m[15]=p;
		m[16]=q;
	--Other matrix or flattened table
	elseif((row1._type ~= nil and row1._type == "Mat4") or (row1._type == nil and type(row1) == "table" and row2 == nil)) then
		for k,v in ipairs(row1) do
			m[k]=v;
		end
	--Other matrix or vector types are invalid
	elseif(row1._type ~= nil and row1._type ~= "Mat4") then
		error("Invalid matrix definition - invalid arguments.",2)
	--Lists of the wrong length are invalid
	elseif(#row1 ~= 4 or row2 == nil or #row2 ~= 4 or row3 == nil or #row3 ~= 4 or row4 == nil or #row4 ~= 4) then
		error("Invalid matrix definition - wrong number of matrix elements.",2)
	else
		m[1]=row1[1];
		m[2]=row2[1];
		m[3]=row3[1];
		m[4]=row4[1];
		m[5]=row1[2];
		m[6]=row2[2];
		m[7]=row3[2];
		m[8]=row4[2];
		m[9]=row1[3];
		m[10]=row2[3];
		m[11]=row3[3];
		m[12]=row4[3];
		m[13]=row1[4];
		m[14]=row2[4];
		m[15]=row3[4];
		m[16]=row4[4];
	end
	
	
	m.tomat3 = mat4to3;
	m.tomat2 = mat4to2;
	m.get = mat4get;
	m.set = mat4set;
	
	setmetatable(m,mat4_mt)
	return m;
end

end

end

do --QUATERNION

local pi = math.pi
local huge = math.huge

local function quatsqrnorm(q)
	if q.__nrm then
		return 1
	end
	return q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
end

local function quatnorm(q)
	return sqrt(quatsqrnorm(q))
end

local function quatdot(a,b)
	return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4]
end

local function donrm(q)
	local n = 1/sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	for i,v in ipairs(q) do
		q[i] = v*n
	end
end
	
local function quatinv(q)
	local r = 1/quatsqrnorm(q) --equals one for unit quaternions (i.e. rotation quaternions)
	return fastquat(q[1]*r, -q[2]*r, -q[3]*r, -q[4]*r)
end

local function doquatmult(q1,q2)
	local x = {}
	local sx,sy,sz = -1,-1,-1
	for i = 1,4 do
		local y = i+2
		if y > 4 then
			y = y-4
		end
		x[i] = q1[1]*q2[i] + sx*q1[2]*q2[5-y] + sy*q1[3]*q2[y] + sz*q1[4]*q2[5-i]
		
		sz = -sz*sx
		sy = sx*sy
		sx = -sx
	end
	return x
end

local function doquatdiv(q1,q2)
	local r = 1/quatsqrnorm(q2) --equals one for unit quaternions (i.e. rotation quaternions)

	return doquatmult({q2[1]*r, -q2[2]*r, -q2[3]*r, -q2[4]*r}, q1)
end

quatapply = function(q,v)
	local x = doquatmult(doquatmult(q,{0,v[1],v[2],v[3]}),{q[1],-q[2],-q[3],-q[4]})
	return fastv3(x[2],x[3],x[4])
end

local function quatnormalised(q)
	local r = 1/q.norm
	return fastquat(q[1]*r, q[2]*r, q[3]*r, q[4]*r)
end

local function quatdonormalise(q)
	local r = 1/q.norm
	q[1] = q[1]*r
	q[2] = q[2]*r
	q[3] = q[3]*r
	q[4] = q[4]*r
end

local function quat2mat(q)
	local w = q[1]
	local x = q[2]
	local y = q[3]
	local z = q[4]

	local w2 = w*w
	local x2 = x*x
	local y2 = y*y
	local z2 = z*z
	
	return fastmat3(w2+x2-y2-z2, 2*(x*y-w*z), 2*(x*z+w*y),		2*(x*y+w*z), w2-x2+y2-z2, 2*(y*z-w*x),		2*(x*z-w*y), 2*(y*z+w*x), w2-x2-y2+z2)
end

local function quat2mat4(q)
	local w = q[1]
	local x = q[2]
	local y = q[3]
	local z = q[4]

	local w2 = w*w
	local x2 = x*x
	local y2 = y*y
	local z2 = z*z
	
	return fastmat4(w2+x2-y2-z2, 2*(x*y-w*z), 2*(x*z+w*y), 0,		2*(x*y+w*z), w2-x2+y2-z2, 2*(y*z-w*x), 0,		2*(x*z-w*y), 2*(y*z+w*x), w2-x2-y2+z2, 0,		0,0,0,1)
end

local function quat2euler(q)
	local a = q[1]
	local b = q[2]
	local c = q[3]
	local d = q[4]

	local b2 = b*b
	local c2 = c*c
	local d2 = d*d
	
	local roll = atan2(2*(a*b + c*d), 1-2*(b2 + c2))
	
	local pitch = 2*(a*c - d*b)
	if abs(pitch) >= 1 then
		if pitch < 0 then
			pitch = -pi*0.5
		else
			pitch = pi*0.5
		end
	else
		pitch = asin(pitch)
	end
	
	local yaw = atan2(2*(a*d + b*c), 1-2*(c2 + d2))
	
	return deg(roll),deg(pitch),deg(yaw)
end

local function quatmul(q1,q2)
	local t1 = type(q1)
	local t2 = type(q2)
	
	if t1 == "Quaternion" then
		if t2 == "Quaternion" then
			
			local x = doquatmult(q1,q2)
			
			local nrm = q1.__nrm and q2.__nrm
			if nrm then
				donrm(x)
			end
			
			return fastquat(x[1],x[2],x[3],x[4],nrm)
		elseif t2 == "Vector3" then
			return quatapply(q1,q2)
		elseif t2 == "number" then
			return fastquat(q1[1]*q2, q1[2]*q2, q1[3]*q2, q1[4]*q2,false)
		end
	elseif t1 == "number" and t2 == "Quaternion" then
		return fastquat(q2[1]*q1, q2[2]*q1, q2[3]*q1, q2[4]*q1,false)
	end
end


local function quatdiv(q1,q2)
	local t1 = type(q1)
	local t2 = type(q2)
	
	if t1 == "Quaternion" then
		if t2 == "Quaternion" then
			
			local x = doquatdiv(q1,q2)
			
			local nrm = q1.__nrm and q2.__nrm
			if nrm then
				donrm(x)
			end
			
			return fastquat(x[1],x[2],x[3],x[4])
		elseif t2 == "number" then
			return fastquat(q1[1]/q2, q1[2]/q2, q1[3]/q2, q1[4]/q2,false)
		end
	elseif t1 == "number" and t2 == "Quaternion" then
		local r = 1/quatsqrnorm(q2) --equals one for unit quaternions (i.e. rotation quaternions)
		
		return fastquat(q2[1]*q1*r, -q2[2]*q1*r, -q2[3]*q1*r, -q2[4]*q1*r)
	end
end

local function quatadd(q1,q2)
	local t1 = type(q1)
	local t2 = type(q2)
	
	if t1 == "Quaternion" then
		if t2 == "Quaternion" then
			return fastquat(q1[1]+q2[1], q1[2]+q2[2], q1[3]+q2[3], q1[4]+q2[4], false)
		elseif t2 == "number" then
			return fastquat(q1[1]+q2, q1[2], q1[3], q1[4], false)
		end
	elseif t1 == "number" and t2 == "Quaternion" then
		return fastquat(q2[1]+q1, q2[2], q2[3], q2[4], false)
	end
end

local function quatsub(q1,q2)
	local t1 = type(q1)
	local t2 = type(q2)
	
	if t1 == "Quaternion" then
		if t2 == "Quaternion" then
			return fastquat(q1[1]-q2[1], q1[2]-q2[2], q1[3]-q2[3], q1[4]-q2[4])
		elseif t2 == "number" then
			return fastquat(q1[1]-q2, q1[2], q1[3], q1[4])
		end
	elseif t1 == "number" and t2 == "Quaternion" then
		return fastquat(q1-q2[1], -q2[2], -q2[3], -q2[4])
	end
end

local function quatmin(q)
	return fastquat(-q[1], -q[2], -q[3], -q[4])
end

local function mat3toquat(m)
	local w,x,y,z
	
	local m00 = m[1]
	local m10 = m[2]
	local m20 = m[3]
	local m01 = m[4]
	local m11 = m[5]
	local m21 = m[6]
	local m02 = m[7]
	local m12 = m[8]
	local m22 = m[9]
	local t = 1
	
	if m22 < 0 then
		if m00 > m11 then
			t = 1+m00-m11-m22
			
			x = t
			y = m10+m01
			z = m02+m20
			w = m21-m12
		else
			t = 1-m00+m11-m22
			
			x = m10+m01
			y = t
			z = m21+m12
			w = m02-m20
		end
	elseif m00 < -m11 then
		t = 1-m00-m11+m22
		
		x = m02+m20
		y = m21+m12
		z = t
		w = m10-m01
	else
		local t = 1+m00+m11+m22
		
		x = m21-m12
		y = m02-m20
		z = m10-m01
		w = t
	end
	
	local k = 0.5/sqrt(t)
	w = w*k
	x = x*k
	y = y*k
	z = z*k
	
	local s = 1/sqrt(w*w + x*x + y*y + z*z)
	w = w*s
	x = x*s
	y = y*s
	z = z*s
	
	return w,x,y,z
end

local function dirstoquat(fwd, up)
		fwd = fwd:normalise()
		up = up:normalise()
		
		local rgt = up^fwd
		up = fwd^rgt
		
		return mat3toquat{rgt[1],rgt[2],rgt[3],up[1],up[2],up[3],fwd[1],fwd[2],fwd[3]}
end

local function quatangle(a,b)
	return deg(acos(min(abs(quatdot(a,b)), 1))*2)
end

local function quatrot2(a,b,d)
	d = d or huge
	local n = quatangle(a,b)
	if n == 0 then
		return b
	else
		return vectr.slerp(a,b,min(1, d/n))
	end
end

local function quatfromto(a,b)
	
	a = a:normalise()
	b = b:normalise()
	
	local d = a:dot(b)
	
	if d >= 1 then
		return 1,0,0,0
	elseif d <= -1 then
		return -1,0,0,0
	end
	
	local c = a^b
	
	local n = 1/sqrt((1+d)*(1+d) + c.sqrlength)
	
	return (1+d)*n,c.x*n,c.y*n,c.z*n
end

local function quatdolook(q,a,b)
	b = b or (q*vectr.up3)
	local w,x,y,z = dirstoquat(a,b)
	q[1] = w
	q[2] = x
	q[3] = y
	q[4] = z
end

quatmt.__index = function(tbl,key)
	if key == "inverse" then
		return quatinv(tbl)
	elseif key == "norm" then
		return quatnorm(tbl)
	elseif key == "sqrnorm" then
		return quatsqrnorm(tbl)
	elseif key == "tomat" or key == "tomat3" then
		return quat2mat
	elseif key == "tomat4" then
		return quat2mat4
	elseif key == "toeuler" then
		return quat2euler
	elseif key == "euler" then
		local x,y,z = quat2euler(tbl)
		return vector.v3(x,y,z)
	elseif key == "normalised" or key == "normalized" then
		return quatnormalised(tbl)
	elseif key == "normalise" or key == "normalize" then
		return quatdonormalise
	elseif key == "dot" then
		return quatdot
	elseif key == "rotateTo" then
		return quatrot2
	elseif key == "lookTo" then
		return quatdolook
	end
end

quatmt.__newindex = function(tbl,key,val)
	if key == "inverse" then
		error("Cannot set the inverse of a quaternion directly.",2)
	elseif key == "norm" then
		error("Cannot set the norm of a quaternion directly.",2)
	elseif key == "sqrnorm" then
		error("Cannot set the norm of a quaternion directly.",2)
	else
		error("Field "..key.." does not exist in the quaternion data structure.",2)
	end
end

quatmt.__mul = quatmul
quatmt.__div = quatdiv
quatmt.__add = quatadd
quatmt.__sub = quatsub
quatmt.__unm = quatmin
quatmt.__eq = eq
quatmt.__concat = function(a,b)
	if type(a) ~= "Quaternion" or type(b) ~= "Quaternion" then
		return tostring(a)..tostring(b)
	else
		return quatdot(a,b)
	end
end

quatmt.__type = "Quaternion"

quatmt.__tostring = function(q)
	return "{w: "..q[1]..", x: "..q[2]..", y: "..q[3]..", z: "..q[4].."}"
end

function vectr.quaternion(w,x,y,z)
	local nrm = false
	if z == nil then
		if y == nil then
			if type(w) == "Mat3" then
				w,x,y,z = mat3toquat(w)
				
				nrm = true
			elseif type(w) == "Vector3" then--axis/angle or from/to directions
				if type(x) == "Vector3" then--from/to directions
					--x,y,z,w = dirstoquat(x,y)
					w,x,y,z = quatfromto(w,x)
				else --axis/angle
					x = rad(x)
					local c = cos(x*0.5)
					local s = sin(x*0.5)
					x = w.x * s
					y = w.y * s
					z = w.z * s
					w = c
					nrm = true
				end
			elseif type(w) == "Quaternion" then
				nrm = w.__nrm
				z = w[4]
				y = w[3]
				x = w[2]
				w = w[1]
			elseif w == nil and x == nil then
				return vectr.quatid
			end
		else --roll/pitch/yaw
			w = rad(w)
			x = rad(x)
			y = rad(y)
			local cr = cos(w*0.5)
			local cp = cos(x*0.5)
			local cy = cos(y*0.5)
			local sr = sin(w*0.5)
			local sp = sin(x*0.5)
			local sy = sin(y*0.5)
			
			w = cr*cp*cy + sr*sp*sy
			x = sr*cp*cy - cr*sp*sy
			y = cr*sp*cy + sr*cp*sy
			z = cr*cp*sy - sr*sp*cy
			nrm = true
		end
	end
	
	local t = { w, x, y, z, __nrm = nrm }
	
	setmetatable(t,quatmt)
	return t
end

vectr.quat = vectr.quaternion

end

function vectr.lerp(a,b,t)
	return math.lerp(a,b,t)
end

function vectr.slerp(a,b,t)
	if not a.__nrm then
		a = a.normalised
	end
	
	if not b.__nrm then
		b = b.normalised
	end
	
	local dot = a[1]*b[1]+a[2]*b[2]+a[3]*b[3]+a[4]*b[4]
	if dot > 0.99995 then
		local q = a + t*(b-a)
		q:normalise()
		q.__nrm = true
		return q
	end
	
	local th0 = acos(dot)
	local th = th0*t
	local sth = sin(th)
	local sth0 = sin(th0)
	
	local s0 = cos(th) - (dot * sth/sth0)
	local s1 = sth / sth0
	
	local q = s0*a + s1*b
	q:normalise()
	q.__nrm = true
	return q
end


local vectorNext = {[0]="x", x="y", y="z", z="w"};

local function viter(state,n)
	if(string.sub(state._type,1,6) == "Vector") then
		n = vectorNext[n];
		if(state[n] ~= nil) then
			return n,state[n];
		end
	elseif(string.sub(state._type,1,3) == "Mat") then
		local cnt = tonumber(string.sub(state._type,-1,-1));
		if(n == 0) then
			n = {1,1};
		elseif(n[2] < cnt) then
			n[2] = n[2] + 1;
		elseif(n[1] < cnt) then
			n[1] = n[1] + 1;
			n[2] = 1;
		else
			n = nil;
		end
		if(n ~= nil) then
			return n,state:get(n[1],n[2]);
		end
	end
end

function vectr.pairs(a)
	return viter,a,0;
end

local g_mt = {};
function g_mt.__index(obj,key)
	if(key == "zero2") then
		return fastv2(0,0);
	elseif(key == "up2" or key == "down2") then
		return fastv2(0,1);
	elseif(key == "right2") then
		return fastv2(1,0);
	elseif(key == "one2") then
		return fastv2(1,1);
	elseif(key == "zero3") then
		return fastv3(0,0,0);
	elseif(key == "forward3") then
		return fastv3(0,0,1);
	elseif(key == "up3" or key == "down3") then
		return fastv3(0,1,0);
	elseif(key == "right3") then
		return fastv3(1,0,0);
	elseif(key == "one3") then
		return fastv3(1,1,1);
	elseif(key == "zero4") then
		return fastv4(0,0,0,0);
	elseif(key == "w4") then
		return fastv4(0,0,0,1);
	elseif(key == "forward4") then
		return fastv4(0,0,1,0);
	elseif(key == "up4" or key == "down4") then
		return fastv4(0,1,0,0);
	elseif(key == "right4") then
		return fastv4(1,0,0,0);
	elseif(key == "one4") then
		return fastv4(1,1,1,1);
	elseif(key == "empty2") then
		return fastmat2(0,0,0,0);
	elseif(key == "id2") then
		return fastmat2(1,0,0,1);
	elseif(key == "empty3") then
		return fastmat3(0,0,0,0,0,0,0,0,0);
	elseif(key == "id3") then
		return fastmat3(1,0,0,0,1,0,0,0,1);
	elseif(key == "empty4") then
		return fastmat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
	elseif(key == "id4") then
		return fastmat4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1);
	elseif(key == "quatid") then
		return fastquat(1,0,0,0,true);
	elseif(key == "_ver") then
		return version;
	end
end

function g_mt.__call(t,x,y,z,w)
	if w == nil then
		if z == nil then
			if y == nil then
				if x == nil then
					return fastv2(0,0)
				else
					return fastv2(x,x)
				end
			else
				return fastv2(x,y)
			end
		else
			return fastv3(x,y,z)
		end
	else
		return fastv4(x,y,z,w)
	end
end

function g_mt.__newindex(obj,key,val)
	error("Cannot access a read-only object.",2)
end

setmetatable(vectr,g_mt);

return vectr;