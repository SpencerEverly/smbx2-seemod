---
--@script Color

---Constructors.
--@section Constructors

---Create a Color object.
--@function Color
--@tparam number r Red component (0-1).
--@tparam number g Green component (0-1).
--@tparam number b Blue component (0-1).
--@tparam[opt=1] number a Alpha component (0-1).
--@return Color
--@usage local myColor = Color(1,1,1)
--@usage local myColor = Color(1,1,1,0.5)

local color = {}

local max = math.max;
local min = math.min;
local floor = math.floor;
local abs = math.abs;
local clamp = math.clamp;
local lerp = math.lerp;
local stringlower = string.lower;
local stringmatch = string.match;

---
--@type Color

--- Generates an RGB hex value from a Color object.
--@function Color:toHexRGB
--@return number
--@usage local n = myColor:toHexRGB()
local function toRGB(c)
	return floor(c[1]*255)*256*256 + floor(c[2]*255)*256 + floor(c[3]*255);
end

--- Generates an RGBA hex value from a Color object.
--@function Color:toHex
--@return number
--@usage local n = myColor:toHex()

--- Generates an RGBA hex value from a Color object.
--@function Color:toHexRGBA
--@return number
--@usage local n = myColor:toHexRGBA()
local function toRGBA(c)
	return floor(c[1]*255)*256*256*256 + floor(c[2]*255)*256*256 + floor(c[3]*255)*256 + floor(c[4]*255);
end

--- Generates HSV values from a Color object.
--@function Color:toHSV
--@return number,number,number
--@usage local h,s,v = myColor:toHSV()
local function toHSV(c)
	local r,g,b = c[1],c[2],c[3];
	local cmax = max(r,g,b);
	local cmin = min(r,g,b);
	local d = cmax-cmin;
	local h,s = 0,0;
	if(d > 0) then
		if(cmax == r) then
			h = ((g-b)/d)%6;
		elseif(cmax == g) then
			h = ((b-r)/d)+2;
		else--if(cmax == c[3]) then
			h = ((r-g)/d)+4;
		end
	end
	
	if(cmax > 0) then
		s = d/cmax;
	end
	
	return h/6,s,cmax;  -- 6 = 360/60
end

local class_color = {}

local function makecol(r,g,b,a)
	return setmetatable({r,g,b,(a or 1)},class_color);
end

--- Functions.
-- @section Functions

--- Generates a Color object from HSV values.
--@function Color.fromHSV
--@tparam number h Hue.
--@tparam number s Saturation.
--@tparam number v Value.
--@return Color
--@usage local myColor = Color.fromHSV(hue,sat,val)

--- Generates a Color object from HSV values, with alpha.
--@function Color.fromHSV
--@tparam number h Hue.
--@tparam number s Saturation.
--@tparam number v Value.
--@tparam number a Alpha.
--@return Color
--@usage local myColor = Color.fromHSV(hue,sat,val,alpha)
local function fromHSV(h,s,v,a)
	h = h*6;  -- 6 = 360/60
	local c = v*s;
	local x = c*(1-abs(h%2 - 1));
	local r,g,b = 0,0,0;
	
	if(h <= 1) then
		r = c;
		g = x;
	elseif(h <= 2) then
		r = x;
		g = c;
	elseif(h <= 3) then
		g = c;
		b = x;
	elseif(h <= 4) then
		g = x;
		b = c;
	elseif(h <= 5) then
		r = x;
		b = c;
	else
		r = c;
		b = x;
	end
	local m = v - c;
	return makecol(r+m,g+m,b+m,a);
end

color.fromHSV = fromHSV;

--- Generates HSL values from a Color object.
--@function Color:toHSL
--@return number,number,number
--@usage local h,s,l = myColor:toHSL()
local function toHSL(c)
	local mx = max(r,g,b)
	local mn = min(r,g,b)
	local l = (mx+mn) * 0.5
	
	if mx == mn then
		return 0,0,l
	else
		local d = mx-mn
		local s
		if l > 0.5 then
			s = d / (2 - mx - mn)
		else
			s = d / (mx + mn)
		end
		
		if mx == r then
			h = (g-b)/d
			if g < b then
				h = h + 6
			end
		elseif mx == g then
			h = (b-r)/d + 2
		else
			h = (r-g)/d + 4
		end
		
		return h/6,s,l
	end
end

local function converthue(p,q,t)
    if t < 0 then 
		t = t + 1
	elseif t > 1 then
		t = t - 1
	end
	if t < 0.1666667 then
		return p + (q - p) * 6 * t
	elseif t < 0.5 then
		return q
	elseif t < 0.6666667 then
		return p + (q - p) * (0.6666667 - t) * 6
	else
		return p
	end
end


--- Generates a Color object from HSL values.
--@function Color.fromHSL
--@tparam number h Hue.
--@tparam number s Saturation.
--@tparam number l Lightness.
--@return Color
--@usage local myColor = Color.fromHSL(hue,sat,light)

--- Generates a Color object from HSL values, with alpha.
--@function Color.fromHSL
--@tparam number h Hue.
--@tparam number s Saturation.
--@tparam number v Value.
--@tparam number l Lightness.
--@return Color
--@usage local myColor = Color.fromHSL(hue,sat,light,alpha)
local function fromHSL(h,s,l,a)
	local r,g,b
	
	if s == 0 then
		return makecol(l,l,l,a)
	else
		local q
		if l < 0.5 then
			q = l * (1 + s)
		else
			q = l + s - l * s
		end
		local p = 2 * l - q
		
		r = converthue(p, q, h + 0.333333)
		g = converthue(p, q, h)
		b = converthue(p, q, h - 0.333333)
		
		return makecol(r,g,b,a)
	end
end

color.fromHSL = fromHSL

do
	local bitand = bit.band;
	local bitrshift = bit.rshift;
	
	local normaliser = 1/0xFF;
	
	--- Generates a Color object from a hexadecimal RGB value.
	--@function Color.fromHexRGB
	--@tparam number hex A 6 digit hexadecimal number.
	--@return Color
	--@usage local myColor = Color.fromHexRGB(0xFFFFFF)
	function color.fromHexRGB(h)
		return makecol(bitand(bitrshift(h, 16), 0xFF)*normaliser, bitand(bitrshift(h, 8), 0xFF)*normaliser, bitand(h, 0xFF)*normaliser, 1);
	end

	--- Generates a Color object from a hexadecimal RGBA value.
	--@function Color.fromHex
	--@tparam number hex An 8 digit hexadecimal number.
	--@return Color
	--@usage local myColor = Color.fromHex(0xFFFFFFFF)
	
	--- Generates a Color object from a hexadecimal RGBA value.
	--@function Color.fromHexRGBA
	--@tparam number hex An 8 digit hexadecimal number.
	--@return Color
	--@usage local myColor = Color.fromHexRGBA(0xFFFFFFFF)
	function color.fromHexRGBA(h)
		return makecol(bitand(bitrshift(h, 24), 0xFF)*normaliser, bitand(bitrshift(h, 16), 0xFF)*normaliser, bitand(bitrshift(h, 8), 0xFF)*normaliser, bitand(h, 0xFF)*normaliser);
	end

end

color.fromHex = color.fromHexRGBA;

--- Linearly interpolates between two Colors using their HSV values.
--@function Color.lerpHSV
--@tparam Color a
--@tparam Color b
--@tparam number t Lerp factor.
--@return Color
--@usage local myColor = Color.lerpHSV(color1,color2,0.5)
local function lerpHSV(c1,c2,t)
	local h1,s1,v1 = toHSV(c1);
	local h2,s2,v2 = toHSV(c2);
	
	do --wrap H properly
		local dh1 = abs(h1-h2);
		local dh2 = abs(h1-(h2+1));
		local dh3 = abs((h1+1)-h2);
		
		if(dh1 > dh2 or dh1 > dh3) then
			if(dh2 > dh3) then
				h1 = h1 + 1;
			else
				h2 = h2 + 1;
			end
		end
	end
		
	
	h1 = lerp(h1,h2,t);
	s1 = lerp(s1,s2,t);
	v1 = lerp(v1,v2,t);
	
	if(h1 > 1) then
		h1 = h1 - 1;
	end
	
	return fromHSV(h1,s1,v1,lerp(c1[4],c2[4],t));
end


--- Linearly interpolates between two Colors using their RGB values.
--@function Color.lerp
--@tparam Color a
--@tparam Color b
--@tparam number t Lerp factor.
--@return Color
--@usage local myColor = Color.lerp(color1,color2,0.5)

color.lerp = lerp

---
--@type Color

--- Linearly interpolates towards another Color using HSV values.
--@function Color:lerpHSV
--@tparam Color a
--@tparam number t Lerp factor.
--@return Color
--@usage local myColor = color1:lerpHSV(color2,0.5)

--- Linearly interpolates towards another Color using RGB values.
--@function Color:lerp
--@tparam Color a
--@tparam number t Lerp factor.
--@return Color
--@usage local myColor = color1:lerp(color2,0.5)

--- Functions.
-- @section Functions

color.lerpHSV = lerpHSV;

--- Converts a string value to a Color.
--Can accept strings of the form `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `0xRRGGBB`, `0xRRGGBBAA`, or any color constant.
--@function Color.parse
--@tparam string str
--@return Color
--@usage local myColor = Color.parse("#FFFFFF")
--@usage local myColor = Color.parse("0xFFFFFFFF")
--@usage local myColor = Color.parse("white")
local function parseHex(st)
	if(type(st) == "Color") then
		return st;
	end
	local s = stringlower(st);
	if(Color[s] and type(Color[s]) == "Color") then
		return Color[s];
	else 
		--#RGB
		local r,g,b,a = stringmatch(s, "%s*#([0-9a-f])([0-9a-f])([0-9a-f])%s*$");
		if(r and g and b) then
			r = tonumber("0x"..r)/15;
			g = tonumber("0x"..g)/15;
			b = tonumber("0x"..b)/15;
			return Color(r,g,b);
		else
			--#RRGGBB
			r,g,b = stringmatch(s, "%s*#([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])%s*$"); 
			a = "ff";
			if(r == nil) then 
				--#RRGGBBAA
				r,g,b,a = stringmatch(s, "%s*#([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])%s*$");
				
				if(r == nil) then 
					--0xRRGGBBAA
					r,g,b,a = stringmatch(s, "%s*0x([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])%s*$");
					
					if(r == nil) then 
						--0xRRGGBB			
						r,g,b = stringmatch(s, "%s*0x([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])%s*$");
						a = "ff";
					end
				end
			end
			if(r and g and b) then
				r = tonumber("0x"..r)/255;
				g = tonumber("0x"..g)/255;
				b = tonumber("0x"..b)/255;
				a = tonumber("0x"..a)/255;
				return Color(r,g,b,a);
			else
				error("Invalid Color format: "..st,2);
			end
		end
	end
	return s;
end

color.parse = parseHex;

---
--@type Color


---
-- @tparam number r The red component of the Color.
-- @tparam number g The green component of the Color.
-- @tparam number b The blue component of the Color.
-- @tparam number a The alpha component of the Color.
-- @table _


function class_color.__index(c,k)
	if(k == "r") then
		return c[1];
	elseif(k == "g") then
		return c[2];
	elseif(k == "b") then
		return c[3];
	elseif(k == "a") then
		return c[4];
	elseif(k == "toHexRGB") then
		return toRGB;
	elseif(k == "toHexRGBA" or k == "toHex") then
		return toRGBA;
	elseif(k == "toHSV") then
		return toHSV;
	elseif(k == "toHSL") then
		return toHSL;
	elseif(k == "lerp") then
		return lerp;
	elseif(k == "lerpHSV") then
		return lerpHSV;
	elseif(k == "parse") then
		return parseHex;
	elseif(k == "__type") then
		return "Color";
	end
end

function class_color.__newindex(c,k,v)
		if(k == "r") then 	rawset(c,1,v);
	elseif(k == "g") then	rawset(c,2,v);
	elseif(k == "b") then	rawset(c,3,v);
	elseif(k == "a") then	rawset(c,4,v);
	else
		error("Field "..k.." does not exist in the Color data structure.",2);
	end
end

function class_color.__add(a,b)
	local ta = type(a); 
	if(ta == "number") then
		return makecol(clamp(a+b[1]),clamp(a+b[2]),clamp(a+b[3]),clamp(a+b[4]));
	elseif(ta == "Color") then
		local tb = type(b);
		if(tb == "number") then
			return makecol(clamp(a[1]+b),clamp(a[2]+b),clamp(a[3]+b),clamp(a[4]+b));
		elseif(tb == "Color") then
			return makecol(clamp(a[1]+b[1]),clamp(a[2]+b[2]),clamp(a[3]+b[3]),clamp(a[4]+b[4]));
		end
	end
	
	return nil;
end

function class_color.__sub(a,b)
	local ta = type(a); 
	if(ta == "number") then
		return makecol(clamp(a-b[1]),clamp(a-b[2]),clamp(a-b[3]),clamp(a-b[4]));
	elseif(ta == "Color") then
		local tb = type(b);
		if(tb == "number") then
			return makecol(clamp(a[1]-b),clamp(a[2]-b),clamp(a[3]-b),clamp(a[4]-b));
		elseif(tb == "Color") then
			return makecol(clamp(a[1]-b[1]),clamp(a[2]-b[2]),clamp(a[3]-b[3]),clamp(a[4]-b[4]));
		end
	end
	
	return nil;
end

function class_color.__mul(a,b)
	local ta = type(a); 
	if(ta == "number") then
		return makecol(clamp(a*b[1]), clamp(a*b[2]), clamp(a*b[3]), clamp(a*b[4]));
	elseif(ta == "Color") then
		local tb = type(b); 
		if(tb == "number") then
			return makecol(clamp(a[1]*b), clamp(a[2]*b), clamp(a[3]*b), clamp(a[4]*b));
		elseif(tb == "Color") then
			return makecol(clamp(a[1]*b[1]),clamp(a[2]*b[2]),clamp(a[3]*b[3]),clamp(a[4]*b[4]));
		end
	end
	
	return nil;
end

function class_color.__div(a,b)
	local ta = type(a); 
	if(ta == "number") then
		return makecol(clamp(a/b[1]), clamp(a/b[2]), clamp(a/b[3]), clamp(a/b[4]));
	elseif(ta == "Color") then
		local tb = type(b); 
		if(tb == "number") then
			return makecol(clamp(a[1]/b), clamp(a[2]/b), clamp(a[3]/b), clamp(a[4]/b));
		elseif(tb == "Color") then
			return makecol(clamp(a[1]/b[1]),clamp(a[2]/b[2]),clamp(a[3]/b[3]),clamp(a[4]/b[4]));
		end
	end
	
	return nil;
end

function class_color.__eq(a,b)
	if(type(a) ~= "Color" or type(b) ~= "Color") then
		return false;
	else
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4];
	end
end

function class_color.__concat(a,b)
	if(type(a) ~= "Color" or type(b) ~= "number") then
		error("Types of concat must be Color and number.",2);
	else
		return makecol(a[1], a[2], a[3], b);
	end
end

do
	local stringformat = string.format;
	local stringupper = string.upper;
	local stringrep = string.rep;
	function class_color.__tostring(c)
		local t = stringupper(stringformat("%x", toRGBA(c)));
		return "#"..stringrep('0', 8 - #t) .. t;
	end
end

class_color.__type = "Color";

local cols = {};

local namespace_mt = {};
namespace_mt.__call = function(tbl,r,g,b,a)
	return makecol(r,g,b,a)
end

function namespace_mt.__index(t,k)
	if(cols[k]) then
		return makecol(cols[k][1], cols[k][2], cols[k][3], cols[k][4]);
	end
end

function namespace_mt.__newindex(t,k,v)
	if(cols[k]) then
		error("Cannot re-define the color constant "..k..".", 2);
	else
		rawset(t,k,v);
	end
end

setmetatable(color,namespace_mt)


--- Constants.
--
-- @section Constants


--- Built-in Color constants, which can be used in place of Color objects.
-- @field white 0xFFFFFFFF
-- @field black 0x000000FF
-- @field red 0xFF0000FF
-- @field green 0x00FF00FF
-- @field blue 0x0000FFFF
-- @field alphawhite 0xFFFFFF00
-- @field alphablack 0x00000000
-- @field transparent 0x00000000
-- @field grey 0x808080FF
-- @field gray 0x808080FF
-- @field cyan 0x00FFFFFF
-- @field magenta 0xFF00FFFF
-- @field yellow 0xFFFF00FF
-- @field pink 0xFF73ABFF
-- @field canary 0xFFF266FF
-- @field purple 0xAB66ABFF
-- @field orange 0xFF8C54FF
-- @field teal 0x00AB99FF
-- @field maroon 0x730000FF
-- @field brown 0x804D00FF
-- @field lightgrey 0xBFBFBFFF
-- @field lightgray 0xBFBFBFFF
-- @field lightblue 0x33CCFFFF
-- @field lightgreen 0x80CC99FF
-- @field lightbrown 0xBF9966FF
-- @field lightred 0xFF8080FF
-- @field darkgrey 0x404040FF
-- @field darkgray 0x404040FF
-- @field darkblue 0x003373FF
-- @field darkgreen 0x005926FF
-- @field darkbrown 0x4D4040FF
-- @field darkred 0x800000FF
-- @table Colors

do --constants

cols.white = makecol(1,1,1);
cols.black = makecol(0,0,0);
cols.red = makecol(1,0,0);
cols.green = makecol(0,1,0);
cols.blue = makecol(0,0,1);
cols.alphawhite = makecol(1,1,1,0);
cols.alphablack = makecol(0,0,0,0);
cols.transparent = cols.alphablack;

cols.grey = makecol(0.5,0.5,0.5);
cols.gray = cols.grey;
cols.cyan =  makecol(0, 1, 1);
cols.magenta = makecol(1, 0, 1);
cols.yellow = makecol(1, 1, 0);
cols.pink = makecol(1,0.45,0.67);
cols.canary = makecol(1,0.95,0.4);
cols.purple = makecol(0.67,0.4,0.67);
cols.orange = makecol(1,0.55,0.33);
cols.teal = makecol(0,0.67,0.6);
cols.maroon = makecol(0.45,0,0);
cols.brown = makecol(0.5,0.3,0);

cols.lightgrey = makecol(0.75,0.75,0.75);
cols.lightgray = cols.lightgrey;
cols.lightblue = makecol(0.2,0.8,1);
cols.lightgreen = makecol(0.5,0.8,0.6);
cols.lightbrown = makecol(0.75,0.6,0.4);
cols.lightred = makecol(1, 0.5, 0.5);

cols.darkgrey = makecol(0.25,0.25,0.25);
cols.darkgray = cols.darkgrey;
cols.darkblue = makecol(0,0.2,0.45);
cols.darkgreen = makecol(0,0.35,0.15);
cols.darkbrown = makecol(0.3,0.25,0.25);
cols.darkred = makecol(0.5, 0, 0);

end

do --Serialization

	local serializer = require("ext/serializer")
	
	serializer.register("Color", class_color.__tostring, parseHex)
end

return color;