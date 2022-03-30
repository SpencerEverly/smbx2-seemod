--- Random number generator library.
-- @module rng

local rng = {}


local abs = math.abs
local floor = math.floor
local pow = math.pow

local insert = table.insert

local lshift = bit.lshift
local rshift = bit.rshift
local bxor = bit.bxor
local bor = bit.bor
local band = bit.band
local tobit = bit.tobit

local sbyte = string.byte
local schar = string.char
local sformat = string.format

local function clock()
	--xor with values chosen randomly in order to avoid clusters of 0 bits
	return bxor(floor(Misc.clock() * 379569141) % 0x80000000, 0xF39B3B3293D7C)
	
	--RNG based seeding - commented out for speed and math.random dependency
	--[[
	local s1 = bxor(floor(Misc.clock() * 379569141) % 0x80000000, 0xF39B3B3293D7C)
	math.randomseed(s1)
	for i=1,10000 do
		math.random() -- Throw out early values
	end
	return math.ceil(math.random()*0x80000000)
	]]
end

local function gen(prng)
	--xorshiro52++ with constants 21, 7, 11, and 14. These can and possibly should be tweaked.
	
	--[[
	  --C-style implementation for reference
	  -- ^ = bitwise xor
	  -- << = left shift
	  -- >> = right shift
	  -- | = bitwise or
	
	  const int a = 26;
	  const int b = 9;
	  const int c = 13;
	  const int d = 17;
	  const int BITWIDTH = 26;

	  --"rol" has been inlined for performanced
	  function rol(x, k)
	  {
		return (x << k) | (x >> ((BITWIDTH) - k));
	  }
	  
	  function xorshiro()
	  {
		s[1] ^= s[0];
		s[0] = rol(s[0], a ) ^ s[1] ^ (s[1] << b);
		s[1] = rol(s[1], c);

		return rol(s[0] + s[1], d) + s[0];
	  }
	  
	  --interpolated constants from 32 bit xorshiro and 64 bit xorshiro
	  --23.5625
	  --8.25
	  --12.4375
	  --15.5
	]]
	
	--local a = 18
	--local b = 8
	--local c = 9
	--local r = 24
	--Best found so far: https://gist.github.com/Bluenaxela/ca266eefdcc18f6f5dba808875ae2e89
	
	local x = prng[1]
	local y = prng[2]
	
	y = bxor(y,x)
	x = bxor(bxor(bor(band(lshift(x,18),0x3FFFFFF), rshift(x, 8 --[[26 - a]])), y), band(lshift(y, 8),0x3FFFFFF))
	y = bor(band(lshift(y,9),0x3FFFFFF), rshift(x, 17 --[[26 - c]]))

	prng[1] = band(x, 0x3FFFFFF)
	prng[2] = band(y, 0x3FFFFFF)
	
	return band(bor(band(lshift(band(x+y,0x3FFFFFF),24),0x3FFFFFF), rshift(x+y,2 --[[26 - r]])) + x, 0x3FFFFFF)/0x4000000
	 
	 
	--[[
	--Old XORShift+ 
	--lost accuracy due to changing bitwidth, and the "corrections" caused undefined behaviour due to out of range tobit calls
	
	local x = prng[1]*0x3FFFFFF + 0x3FFFFFF
	local y = prng[2]*0x3FFFFFF + 0x3FFFFFF
	prng[1] = band(y, 0x3FFFFFF)
	x = bxor(x, lshift(x,23))
	x = bxor(x, bxor(y, bxor(rshift(x,17), rshift(y, 26))))
	prng[2] = band(x, 0x3FFFFFF)
	
	return band(x + y, 0x7FFFFFFF)/0x7FFFFFFF
	
	]]
end

--- Generates a random number between 0 and 1, inclusive.
-- @function random
-- @treturn number

--- Generates a random number between 0 and value, inclusive.
-- @function random
-- @tparam number value
-- @treturn number

--- Generates a random number between min and max, inclusive.
-- @function random
-- @tparam number min
-- @tparam number max
-- @treturn number
local function gen_float(prng, a, b)
	if b == nil then
		if a == nil then
			return gen(prng)
		else
			return a * gen(prng)
		end
	else
		if a == b then
			return a
		elseif a > b then
			return (a-b)*gen(prng) + b;
		else
			return (b-a)*gen(prng) + a;
		end
	end
end

--- Generates a random integer between 0 and 1,000,000, inclusive.
-- @function randomInt
-- @treturn int

--- Generates a random integer between 0 and value, inclusive.
-- @function randomInt
-- @tparam number value
-- @treturn int

--- Generates a random integer between min and max, inclusive.
-- @function randomInt
-- @tparam number min
-- @tparam number max
-- @treturn int
local function gen_int(prng, a, b)
	if a == nil and b == nil then
		return floor((1000000*gen(prng))+0.5)
	end
	
	a = a or 0
	b = b or 0
	
	if a <= b then
		return floor((b-a+1)*gen(prng) + a)
	else
		return floor((a-b+1)*gen(prng) + b)
	end
end

--- Generates a random boolean.
-- @treturn bool
local function gen_bool(prng)
	return gen(prng) > 0.5
end

--- Selects a random value from a given table.
-- @function randomEntry
-- @tparam table t
-- @treturn object
-- @see randomKey
-- @see irandomEntry
local function gen_tableval(prng, tbl)
	local nt = {}
	for k,v in pairs(tbl) do
		insert(nt,v)
	end
	local n = floor(gen(prng)*(#nt))
	return nt[n+1]
end

--- Selects a random key from a given table.
-- @function randomKey
-- @tparam table t
-- @treturn object
-- @see randomEntry
-- @see irandomKey
local function gen_tablekey(prng, tbl)
	local nk = {}
	for k,v in pairs(tbl) do
		insert(nk,k)
	end
	local n = floor(gen(prng)*(#nt))
	return nk[n+1]
end

--- Selects a random entry from a given list. Faster than randomEntry.
-- @function irandomEntry
-- @tparam table t
-- @treturn object
-- @see irandomKey
-- @see randomEntry
local function gen_arrayval(prng, tbl)
	local n = floor(gen(prng)*(#tbl))
	return tbl[n+1]
end

--- Selects a random index from a given list. Faster than randomKey.
-- @function irandomKey
-- @tparam table t
-- @treturn number
-- @see randomKey
-- @see irandomEntry
local function gen_arrayidx(prng, tbl)
	return floor(gen(prng)*(#tbl))+1
end

--- Generates a random letter between a-z (in either upper or lower case).
-- @function randomChar
-- @treturn string

--- Generates a random letter between a-z, in upper or lower case depending on the given argument.
-- @function randomChar
-- @tparam bool upper If set to true, the generated letter will be upper case. Otherwise, the letter will be lower case.
-- @treturn string

--- Generates a random letter between A and the given letter.
-- @function randomChar
-- @tparam string min
-- @treturn string
-- @usage local a = rng.randomChar("F")

--- Generates a random letter between the given letters, inclusive.
-- @function randomChar
-- @tparam string min
-- @tparam string max
-- @treturn string
-- @usage local a = rng.randomChar("a", "c")
local function gen_char(prng, a, b)
	if b == nil and (a == nil or type(a) == 'boolean') then
		if a == nil then
			if gen_bool(prng) then
				a = "A"
				b = "Z"
			else
				a = "a"
				b = "z"
			end
		elseif a then --Upper case
			a = "A"
			b = "Z"
		else --Lower case
			a = "a"
			b = "z"
		end
	end
	
	local s
	local f
	
	if a == nil then 
		s = sbyte("A",1)
	else 
		s = sbyte(a,1)
	end
	
	if b == nil then 
		f = s
		s = sbyte("A",1)
	else 
		f = sbyte(b,1)
	end
		
	local n = floor((f-s)*gen(prng) + s)
	return schar(n);
end

local function reseed(prng, seed)
	seed = abs(floor(seed))
	
	--seed with 26 most and least significant bits of the seed value as two separate integers
	prng[1] = tobit(floor(seed / 0x4000000))
	prng[2] = tobit(seed % 0x4000000)
end

local functions = {
					random = gen_float, 
					randomInt = gen_int, 
					randomEntry = gen_tableval, 
					randomKey = gen_tablekey,
					irandomEntry = gen_arrayval, 
					irandomKey = gen_arrayidx,
					randomChar = gen_char, 
					randomBool = gen_bool
				  }		  
				  
local rngmt = {}
rngmt.__index = function(tbl, key)
	if key == "seed" then
	
		--combine seed integers to recreate original seed
		return (tbl[1]*0x4000000) + tbl[2]
		
	elseif functions[key] then
		return functions[key]
	end
end

rngmt.__newindex = function(tbl, key, val)
	if key == "seed" then
		reseed(tbl, val or clock())
	else
		error("Cannot assign value to random number generator.", 2)
	end
end

--- Creates a new pseudo-random number generator. An optional seed can be supplied, which will be generated otherwise.
-- @tparam[opt] number seed
-- @treturn Generator
function rng.new(seed)
	local t = {}
	reseed(t, seed or clock())
	
	setmetatable(t, rngmt)
	return t;
end

local global = rng.new()
local globalperlin

local wrappedfunctions = {}
for k,v in pairs(functions) do
	wrappedfunctions[k] = function(a, b) return v(global, a, b) end
end

local globalmt = {}
globalmt.__index = function(tbl, key)
	if key == "seed" then
		return global.seed
	elseif key == "Perlin" then
		return globalperlin
	elseif wrappedfunctions[key] then
		return wrappedfunctions[key]
	end
end

globalmt.__newindex = function(tbl, key, val)
	if key == "seed" then
		reseed(global, val or clock())
	else
		error("Cannot assign value to random number generator.", 2)
	end
end

do --perlin

	local pi = math.pi
	local sin = math.sin
	local cos = math.cos
	local ceil = math.ceil

	local function interp(a, b, t)
		local f = (1-cos(t*pi))*0.5
		return a*(1-f) + b*f
	end
	
	local function quinterp(a,b,t)
		t = t*t*t*(t*(t*6 - 15) + 10)
		return b*t + a*(1-t)
	end
	
	--Used to map all integers to positive, non-zero values uniquely
	local function posmap(x)
		if x >= 0 then
			return 2*x+1
		else
			return -2*x
		end
	end

	local function preseed(rng, seed, val)
	
		--old seed system, newer one is faster
		--rng.seed = posmap(val)
		--rng.seed = ceil(rng:random((seed+17216)*(seed+416231)))
		
		rng[1] = posmap(floor(val))%0x3FFFFFF
		rng[2] = floor(abs(seed))%0x3FFFFFF
	end

	local function perlinget(rng, seed, x, wl, amp)
		local x0 = floor(x/wl)*wl
		local x1 = ceil(x/wl)*wl
		
		if x0 == x1 then
			preseed(rng,seed,x0)
			return gen(rng)*amp
		else
			preseed(rng,seed,x0)
			local a = gen(rng)*amp
			preseed(rng,seed,x1)
			local b = gen(rng)*amp
			
			return interp(a, b, (x%wl)/wl)
		end
	end

	local function octaveget(pgen, x)
		local wl = pgen.wl
		local amp = pgen.amp
		local mv = 0
		local t = 0
		local seed = pgen.seed
		for i=1,pgen.oct do
			mv = mv + amp
			t = t + perlinget(pgen.rng, seed, x, wl, amp)
			wl = wl*pgen.mod
			amp = amp*pgen.per
			
			--scramble seed for successive octaves
			seed = abs(floor(seed*1.707) - 874877321)
		end
		return t*pgen.amp/mv
	end

	local function preseed2(rng, seed, val1, val2)
		--old seed system caused issues: TODO: look into this
		--rng[1] = posmap(floor((val1+31762)*(val2+19031)))
		--rng[2] = posmap(floor(seed))
		
		val1 = posmap(val1+19031)
		val2 = posmap(val2+19031)
		
		--Seed using polar coordinates to avoid artefacts
		local r = val1*val1 + val2*val2
		
		--actual atan2 for polar coordinates
		--local t = atan2(val2,val1)
		
		--approximate atan for approximating polar coordinates at higher speed (note that val2 and val1 are both positive and non-zero here)
		local t = val2/val1
		t = t*(0.9724 - 0.1919*t*t)
		
		local s = abs(seed)
		
		rng[1] = floor(s*r)%0x3FFFFFF --s and r are guaranteed positive
		rng[2] = floor(abs(s*t))%0x3FFFFFF --s is guaranteed positive, t should be positive *in most cases*, so abs just to be certain
	end
	
	local corners = { {0.70710678118, 0.70710678118}, {-0.70710678118, 0.70710678118}, {0.70710678118, -0.70710678118}, {-0.70710678118,-0.70710678118} }

	local function getdot(rng, seed, x0, y0, x, y)
		preseed2(rng, seed, x0, y0)
		
		--fully random gradients unnecessary in practice
		--local r = rng:random(-pi,pi)
		--local gx, gy = -sin(r), cos(r)
		
		local g = corners[floor(gen(rng)*4)+1]
		
		local dx = (x-x0)
		local dy = (y-y0)
		
		--return dx*gx + dy*gy
		
		return dx*g[1] + dy*g[2]
	end

	local function perlin2dget(rng, seed, x, y, wl, amp)
		local f = 1/wl
		local x0 = floor(x*f)*wl
		local x1 = x0+wl
		local y0 = floor(y*f)*wl
		local y1 = y0+wl
		
		local dx = (x - x0)*f
		local dy = (y - y0)*f
		
		--Generate dot products
		local d00 = getdot(rng, seed, x0, y0, x, y)
		local d01 = getdot(rng, seed, x0, y1, x, y)
		local d10 = getdot(rng, seed, x1, y0, x, y)
		local d11 = getdot(rng, seed, x1, y1, x, y)
			
		return (quinterp(quinterp(d00, d10, dx), quinterp(d01, d11, dx), dy)*f + 1) * 0.5 * amp
	end

	local function octave2get(pgen, x, y)
		local wl = pgen.wl
		local amp = pgen.amp
		local mv = 0
		local t = 0
		local seed = pgen.seed
		for i=1,pgen.oct do
			mv = mv+amp
			t = t + perlin2dget(pgen.rng, seed, x, y, wl, amp)
			wl = wl*pgen.mod
			amp = amp*pgen.per

			--scramble seed for successive octaves
			seed = abs(floor(seed*1.707) - 874877321)
		end
		return t*pgen.amp/mv
	end
	
	local perlinmt = {}
	
	perlinmt.__index = function(tbl, key)
		if key == "get" then
			return octaveget
		elseif key == "get2d" then
			return octave2get
		end
	end
	
	perlinmt.__newindex = function(tbl, key)
		error("Cannot assign value to perlin generator.", 2)
	end
	
	--- Creates a new pseudo-random perlin noise generator. An optional seed can be supplied, which will be generated otherwise.
	-- @tparam table args The argument table.
	-- @tparam[opt=1] number args.amp The amplitude of the generated noise.
	-- @tparam[opt=100] number args.wl The wavelength of the generated noise.
	-- @tparam[opt=10] number args.oct The number of generated octaves (higher is more expensive, but gives finer detailed noise).
	-- @tparam[opt] number args.seed The random seed for this set of noise. A seed will be generated if none is given.
	-- @treturn Perlin
	function rng.perlin(args)
		local t = {rng = rng.new(), amp = args.amp or args.amplitude or 1, wl = args.wl or args.wavelength or 100, oct = args.oct or args.octaves or 10, per = args.per or args.persistence or 0.5, mod = args.mod or args.modulation or 0.5, seed = args.seed or clock()*13417}
		
		setmetatable(t, perlinmt)
		
		return t
	end

end

globalperlin = rng.perlin{}

setmetatable(rng, globalmt)

return rng;