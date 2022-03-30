--BGO config to mirror NPC config. Designed to work with betterbgo.lua

local iniparse = require("configFileReader")

local bgoconfig = {}

local bgoClimbableMem
do
	local bgoClimbableAddr = mem(0xB25B54, FIELD_DWORD)
	function bgoClimbableMem(id, val)
		return mem(bgoClimbableAddr + id * 2, FIELD_BOOL, val)
	end
end

bgoconfig.__bgosettings = {};
bgoconfig.__frames = {};
bgoconfig.__framespeed = {};
bgoconfig.__height = {};
bgoconfig.__width = {};
bgoconfig.__priority = {};
bgoconfig.__lightradius = {};
bgoconfig.__lightbrightness = {};
bgoconfig.__lightcolor = {};
bgoconfig.__lightoffsetx = {};
bgoconfig.__lightoffsety = {};
bgoconfig.__lightflicker = {};
local bgodefaults = {};
local config = {};
local autowidth = {};
local autoheight = {};

local function tobool(v)
	return (v ~= false) and (v ~= 0) and (v ~= nil)
end

-- Define metatable for handling
local bgomt = {}

function bgomt.__newindex(tbl, key, val)
	local resetautosize = true
	if(val == nil) then
		if(key == "width") then
			local img = Graphics.sprites.background[tbl._id].img;
			if img ~= nil then
				val = img.width;
			else
				val = 0;
			end
			autowidth[tbl._id] = true
			resetautosize = false
		elseif(key == "height") then
			local img = Graphics.sprites.background[tbl._id].img;
			if img ~= nil then
				val = img.height / bgoconfig.__bgosettings[tbl._id].frames;
			else
				val = 0;
			end
			autoheight[tbl._id] = true
			resetautosize = false
		else
			val = bgodefaults[tbl._id][key];
		end
	end
	
	local ov = bgoconfig.__bgosettings[tbl._id][key]
	bgoconfig.__bgosettings[tbl._id][key] = val;

	if (key == "frames") then
		bgoconfig.__frames[tbl._id] = tonumber(val)
	elseif (key == "framespeed") then
		bgoconfig.__framespeed[tbl._id] = tonumber(val)
	elseif (key == "height") then
		if resetautosize then
			autoheight[tbl._id] = nil
		end
		bgoconfig.__height[tbl._id] = tonumber(val)
	elseif (key == "width") then
		if resetautosize then
			autowidth[tbl._id] = nil
		end
		bgoconfig.__width[tbl._id] = tonumber(val)
	elseif (key == "priority") then
		bgoconfig.__priority[tbl._id] = tonumber(val)
	elseif (key == "climbable") then
		bgoClimbableMem(tbl._id, val)
	elseif (key == "lightradius") then
		bgoconfig.__lightradius[tbl._id] = tonumber(val)
	elseif (key == "lightbrightness") then
		bgoconfig.__lightbrightness[tbl._id] = tonumber(val)
	elseif (key == "lightoffsetx") then
		bgoconfig.__lightoffsetx[tbl._id] = tonumber(val)
	elseif (key == "lightoffsety") then
		bgoconfig.__lightoffsety[tbl._id] = tonumber(val)
	elseif (key == "lightcolor") then
		bgoconfig.__lightcolor[tbl._id] = Color.parse(val)
	elseif (key == "lightflicker") then
		bgoconfig.__lightflicker[tbl._id] = tobool(val)
	end
	
	local v =  bgoconfig.__bgosettings[tbl._id][key]
	if v ~= ov then
		EventManager.callEvent("onBGOConfigChange", tbl._id, key, v, ov)
	end
end

function bgomt.__index(tbl, key)
	return bgoconfig.__bgosettings[tbl._id][key];
end


for k=1,BGO_MAX_ID do
	bgodefaults[k] = {priority = -85, frames = 1, framespeed = 8, climbable = false};
	bgoClimbableMem(k, false)
end

--Set up BGO defaults
do
local BG = -95;
local FG = -20;
local LG = -63; --lineguide

local function set(id,p,f,s,c)
	if (p ~= nil) then
		bgodefaults[id].priority = p
	end
	if (f ~= nil) then
		bgodefaults[id].frames = f
	end
	if (s ~= nil) then
		bgodefaults[id].framespeed = s
	end
	if (c ~= nil) then
		bgodefaults[id].climbable = c
		bgoClimbableMem(id, c)
	end
end

local function setlight(id, x, y, r, b, c, f)
	bgodefaults[id].lightoffsetx = x;
	bgodefaults[id].lightoffsety = y;
	bgodefaults[id].lightradius=r;
	bgodefaults[id].lightbrightness=b;
	bgodefaults[id].lightcolor=c;
	bgodefaults[id].lightflicker=f or false;
end


set(11,BG);
set(12,BG);

set(14,BG);

set(18,nil,4,12);
set(19,nil,4,12);
set(20,nil,4,12);

set(23,FG);
set(24,FG);
set(25,FG);

set(26,nil,8,8);

set(36,FG,4,2);

set(45,FG);
set(46,FG);

set(49,FG);
set(50,FG);
set(51,FG);

set(60,BG);
set(61,BG);

set(65,nil,4,8);
set(66,BG,4,8);

set(68,FG,4,2);
set(69,FG);
set(70,nil,4,8);

set(75,BG);
set(76,BG);
set(77,BG);
set(78,BG);

set(82,nil,4,10);

setlight(96, 0,0,64,0.5,Color.pink);

set(100,nil, 4,8);

set(106,FG);

set(125,nil,2,4);
setlight(125, 0,-16,64,1,Color.orange, true);

set(134,nil,4,8);
set(135,nil,4,8);
set(136,nil,4,8);
set(137,FG,4,8);
set(138,FG,4,8);

set(143,FG);

set(145,FG);

set(154,FG);
set(155,FG);
set(156,FG);
set(157,FG);
set(158,BG,4,6);
set(159,BG,8,6);
set(294,BG,4,6);

set(161,nil,4,12);

set(168,nil,8,8);

set(170,nil,4,8);
set(171,nil,4,8);
set(172,BG,4,8);
set(173,nil,2,8);

for i=174,186 do
	set(i,nil,nil,nil,true)
end

set(187,FG,4,6);
set(188,FG,4,6);
set(189,nil,4,6);
set(190,nil,4,6);

set(201,LG,4,8);
set(202,LG,4,8);
set(203,LG);
set(204,LG);
set(205,LG);
set(206,LG);
set(207,LG);
set(208,LG);
set(209,LG);
set(210,LG);
set(211,LG);
set(212,LG);
set(213,LG);
set(214,LG);
set(215,LG);
set(216,LG);
set(217,LG);
set(218,LG);

set(235,nil,4,8);
set(236,FG,4,8);

set(237,FG);
set(238,FG);

set(249,FG);

set(251,FG);
set(252,FG);
set(253,FG);
set(254,FG);
set(255,FG);
set(256,FG);
set(257,FG);

setlight(263, -6,-8,64,1,Color.canary);

set(264,nil,4,8);

set(266,FG);
set(267,FG);
set(268,FG);
set(269,FG);
set(270,FG);

set(278,FG,8,6);
set(279,FG,8,6);

set(297,FG);
set(298,FG);
set(299,FG);
set(300,FG);
end

for id=1,BGO_MAX_ID do
	config[id] = {_id=id};

	local override = iniparse.parseTxt("background-"..id..".txt");
	if(override) then
		for k,v in pairs(override) do
			bgodefaults[id][k] = v;

			if (k == "climbable") then
				bgoClimbableMem(id, v)
			end
		end
	end

	bgoconfig.__bgosettings[id] = table.clone(bgodefaults[id]);	
	
	if bgoconfig.__bgosettings[id].lightcolor then
		bgoconfig.__bgosettings[id].lightcolor = Color.parse(bgoconfig.__bgosettings[id].lightcolor)
	end
	
	bgoconfig.__frames[id] = bgoconfig.__bgosettings[id].frames
	bgoconfig.__framespeed[id] = bgoconfig.__bgosettings[id].framespeed
	bgoconfig.__height[id] = bgoconfig.__bgosettings[id].height
	bgoconfig.__width[id] = bgoconfig.__bgosettings[id].width
	bgoconfig.__priority[id] = bgoconfig.__bgosettings[id].priority
	bgoconfig.__lightradius[id] = bgoconfig.__bgosettings[id].lightradius
	bgoconfig.__lightbrightness[id] = bgoconfig.__bgosettings[id].lightbrightness
	bgoconfig.__lightoffsetx[id] = bgoconfig.__bgosettings[id].lightoffsetx
	bgoconfig.__lightoffsety[id] = bgoconfig.__bgosettings[id].lightoffsety
	bgoconfig.__lightcolor[id] = bgoconfig.__bgosettings[id].lightcolor
	bgoconfig.__lightflicker[id] = bgoconfig.__bgosettings[id].lightflicker
	
	setmetatable(config[id], bgomt);
	
	if(bgodefaults[id].width == nil) then
		config[id].width = nil;
	end
	if(bgodefaults[id].height == nil) then
		config[id].height = nil;
	end
end

function bgoconfig.onInitAPI()
	registerEvent(bgoconfig, "onStart", "onStart", true);
end

function bgoconfig.onStart()
	for id=1,BGO_MAX_ID do
		if(bgodefaults[id].width == nil) then
			config[id].width = nil;
		end
		if(bgodefaults[id].height == nil) then
			config[id].height = nil;
		end
	end
	for _,v in ipairs(BGO.get()) do
		local cfg = config[v.id];
		v.width = cfg.width;
		v.height = cfg.height;
	end
end

function bgoconfig.__updateCache(id)
	if autowidth[id] then
		bgoconfig[id].width = nil
	end
	if autoheight[id] then
		bgoconfig[id].height = nil
	end
end

local cfgmt = {}
function cfgmt.__newindex(tbl, key, value)
	error("Cannot assign directly to Background config. Try assigning to a field instead.", 2)
end
function cfgmt.__index(tbl, key)
	if(type(key) == "number" and key >= 1 and key <= BGO_MAX_ID) then
		return config[key];
	else
		return nil
	end
end

-- Declare the bgoconfig object itself
setmetatable(bgoconfig, cfgmt)

if (BGO ~= nil) then
	BGO.config = bgoconfig;
end

return bgoconfig;
