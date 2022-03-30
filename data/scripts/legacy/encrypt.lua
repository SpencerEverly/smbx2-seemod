local encrypt = {}
local spk = 9955241;

local function createKey(key)
	local tab = {}
	key:gsub(".",function(c) table.insert(tab,c:byte()) end)
	local sum = 0;
	for _,v in pairs(tab) do
		sum = sum + v;
	end
	math.randomseed(sum);
end

local function getKey()
	return math.random(999999);
end

local function getPrefix(key)
	local tab = {};
	key:gsub(".",function(c) table.insert(tab,c:byte()) end)
	local s = "";
	for _,v in pairs(tab) do
		s = s .. v;
	end
	return s;
end

local function getKeyTable(key)
	createKey(key);
	local ks = {}
	local i = 1;
	while i <= 4 do
		local k = getKey();
		local j = 1;
		while j <= i do
			if(ks[j] == k) then
				k = getKey();
				j = 1;
			else
				j = j + 1;
			end
		end
		ks[i] = k;
		i = i + 1;
	end
	return ks;
end

local function hash(k)
	math.randomseed(math.floor(k*0.61803398863));
	local c = 0xFF;
	local i = 0;
	while(c <= 0xFF000000) do
		k = bit.band(bit.bnot(c),k) + bit.lshift(bit.bxor(math.random(0xFF),bit.rshift(bit.band(k,c), i) + math.random(0xFF)), i);
		i = i + 8;
		c = c*256;
	end
	return k;
end

local function calculateHash(v)
	return bit.band(0xFFFFFFFF,bit.bxor(hash(v[1]), bit.bxor(hash(v[2]),hash(v[3]))));
end

local function encode(key, value)
	local l = getKey();
	
	math.randomseed(os.clock());
	local junk = getKey();
	local a1 = getKey();
	local a2 = getKey();
	local a3 = getKey();
	local a4 = getKey();
	
	local v = {};
	v[1] = bit.bxor(a1,spk);
	v[2] = bit.bxor(bit.bxor(value, a2), spk);
	v[3] = bit.bxor(bit.bxor(a1, a2), spk);
	v[4] = calculateHash(v);

	return v;
end

local function decode(key, v)
	local l = getKey();
	if(v[1] == nil or v[2] == nil or v[3] == nil or v[4] == nil) then
		return nil;
	end
	if(calculateHash(v) ~= v[4]) then
		error("Attempted to read data which was invalid", 2);
	end
	
	return bit.bxor(bit.bxor(v[1], bit.bxor(v[2], v[3])),spk);
end

local EData = {}
EData.__index = EData;

function EData:set(key, value)
	local p = "a"..getPrefix(key);
	local ks = getKeyTable(key);
	local vs = encode(key, value);
	--UserData.setValue(p..tostring(ks[1]), vs[1]);
	--UserData.setValue(p..tostring(ks[2]), vs[2]);
	--UserData.setValue(p..tostring(ks[3]), vs[3]);
	--UserData.setValue(p..tostring(ks[4]), vs[4]);
	
	self.data:set(p..tostring(ks[1]), tostring(vs[1]));
	self.data:set(p..tostring(ks[2]), tostring(vs[2]));
	self.data:set(p..tostring(ks[3]), tostring(vs[3]));
	self.data:set(p..tostring(ks[4]), tostring(vs[4]));
end

function EData:get(key)
	local p = "a"..getPrefix(key);
	local ks = getKeyTable(key);
	
	local v = {}
	--if(not UserData.isValueSet(p..tostring(ks[1])) or
	--   not UserData.isValueSet(p..tostring(ks[2])) or
	--   not UserData.isValueSet(p..tostring(ks[3])) or
	--   not UserData.isValueSet(p..tostring(ks[4]))) then
	--   return nil;
	--end
	--v[1] = UserData.getValue(p..tostring(ks[1]));
	--v[2] = UserData.getValue(p..tostring(ks[2]));
	--v[3] = UserData.getValue(p..tostring(ks[3]));
	--v[4] = UserData.getValue(p..tostring(ks[4]));
	v[1] = tonumber(self.data:get(p..tostring(ks[1])));
	v[2] = tonumber(self.data:get(p..tostring(ks[2])));
	v[3] = tonumber(self.data:get(p..tostring(ks[3])));
	v[4] = tonumber(self.data:get(p..tostring(ks[4])));
	
	return decode(key, v);
end

function EData:save()
	self.data:save();
end

function EData.create(d)
	local dat = {}
	setmetatable(dat,EData);
	dat.data = d;
	return dat;
end

function encrypt.Data(datalevel, name, savelocal)
	local data = nil;
	if(savelocal == nil) then
		data = Data(datalevel, name);
	else
		data = Data(datalevel, name, savelocal);
	end
	
	return EData.create(data);
end

return encrypt;