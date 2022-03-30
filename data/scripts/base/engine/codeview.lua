local textplus = require("textplus");

local code = {}

local data;
local linedata;
local linewid = 8;

code.color = {comment = 0x60FF60FF, string = 0xAAAAAAFF, number = 0xFFAD00FF, class = 0x70E0FFFF}

local paths;
local pathTypes = {"Level", "Level", "Episode", "Episode"}
local codeindex = 0;
local scroll = 0;
local totalHeight = 0;

local font = textplus.loadFont("textplus/font/5.ini")

local formats = {};

local keywords = {
					{color = 0x0090FFFF, list = {"and","break","do","else","elseif","end","false","for","function","if","in","local","nil","not","or","repeat","return","then","true","until","while"}},
					{color = 0x70E0FFFF, list = {"_G", "_ENV", "_VERSION", "assert", "collectgarbage", "dofile", "error", "getfenv", "getmetatable", "ipairs", "load", "loadfile", "loadstring", "module", "next", "pairs", "pcall",
					"print", "rawequal", "rawget", "rawlen", "rawset", "require", "select", "setfenv", "setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall", "package", 
					"__index", "__newindex", "__call", "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm", "__concat", "__len", "__eq", "__lt", "__le", "__gc", "__mode"}},
				 }
local classes =  {
					{color_f = 0xAA40FFFF, color_m = 0xAA40FFFF, name = "string", 
							functions = {"byte", "char", "dump", "find", "format", "gmatch", "gsub", "len", "lower", "match", "rep", "reverse", "sub", "upper"}, 
							methods = {"byte", "char", "dump", "find", "format", "gmatch", "gsub", "len", "lower", "match", "rep", "reverse", "sub", "upper"}},
					{color_f = 0xAA40FFFF, color_m = 0x3A90EBFF, name = "table", 
							functions = {"concat", "insert", "pack", "remove", "sort", "unpack"}, 
							methods = {}},
					{color_f = 0xAA40FFFF, color_m = 0x3A90EBFF, name = "math", 
							functions = {"abs", "acos", "asin", "atan", "atan2", "ceil", "cos", "cosh", "deg", "exp", "floor", "fmod", "frexp", "huge", "ldexp", "log", "log10", "max", "min", "modf", "pi", "pow", "rad", "random", "randomseed", "sin", "sinh", "sqrt", "tan", "tanh"}, 
							methods = {}},
					{color_f = 0xAA40FFFF, color_m = 0x3A90EBFF, name = "bit32", 
							functions = {"arshift", "band", "bnot", "bor", "btest", "bxor", "extract", "replace", "lrotate", "lshift", "rrotate", "rshift"}, 
							methods = {}},
					{color_f = 0x0070FFFF, color_m = 0x0070FFFF, name = "io", 
							functions = {"close", "flush", "input", "lines", "open", "output", "popen", "read", "tmpfile", "type", "write"}, 
							methods = {"close", "flush", "lines", "read", "seek", "setvbuf", "write"}},
					{color_f = 0x0070FFFF, color_m = 0x0070FFFF, name = "os", 
							functions = {"clock", "date", "difftime", "execute", "exit", "getenv", "remove", "rename", "setlocale", "time", "tmpname"}, 
							methods = {}},
					{color_f = 0x0070FFFF, color_m = 0x0070FFFF, name = "debug", 
							functions = {"debug","gethook","getinfo","getlocal","getmetatable","getregistry","getupvalue","getuservalue","sethook","setlocal","setmetatable","setupvalue","setuservalue","traceback","upvalueid","upvaluejoin"}, 
							methods = {}},
					{color_f = 0x0070FFFF, color_m = 0x0070FFFF, name = "coroutine", 
							functions = {"create", "resume", "status", "yield", "wrap"}, 
							methods = {}}
				 };
				 
local function removeColours(str)
	return str:gsub("(<color 0x[0123456789abcdefghijklmnopqrstuvwxyzABCDEF]+>)(.-)(</color>)", "%2");
end
	
local function blockComment(str)
	return formats.comment.."--[["..removeColours(str).."]]"..formats.default;
end

local function lineComment(str)
	return formats.comment.."--"..removeColours(str)..formats.default.."\n";
end

local function parseComments(str)
	local commentFormat = formats.comment.."%1"..formats.default;
	str = str:gsub("%-%-([^%[%]]-)\n", lineComment)
	str = str:gsub("%-%-%[%[(.-)%]%]", blockComment);
	return str;
end

local function parseKeywords(str)
	for _,v in ipairs(keywords) do
		local startFormat = "<color 0x"..string.format("%x", v.color)..">";
		for _,k in ipairs(v.list) do
			str = str:gsub("([^%w%.]"..k.."[^%w])("..k..")","%1\1%2");
			str = str:gsub("([^%w%.])("..k..")([^%w])","%1"..startFormat.."%2"..formats.default.."%3");
		end
	end
	return str;
end

local function parseNumbers(str)
	str = str:gsub("(%W)(%d+[%.x]?[%w]*)", "%1"..formats.number.."%2"..formats.default);
	return str;
end

local function strings(str)
	return formats.string..removeColours(str)..formats.default;
end

local function parseStrings(str)
	return str:gsub("(%b\"\")", strings);
end

local function parseClasses(str)
	for _,v in ipairs(classes) do
		str = str:gsub("([^%w%.]"..v.name.."[^%w])("..v.name..")","%1\1%2");
		str = str:gsub("([^%w%.])("..v.name..")([^%w%.])","%1"..formats.class.."%2"..formats.default.."%3");
		for _,w in ipairs(v.functions) do
			str = str:gsub("(%W)("..v.name.."%."..w..")(%W)","%1<color 0x"..string.format("%x", v.color_f)..">%2"..formats.default.."%3");
		end
		for _,w in ipairs(v.methods) do
			str = str:gsub("(%W.*:)("..w..")(%W)","%1<color 0x"..string.format("%x", v.color_m)..">%2"..formats.default.."%3");
		end
	end
	return str;
end

local nextData;

local function loadData(path)
	local f = io.open(path, "r");
	totalHeight = 0;
	if(f) then
		for k,v in pairs(code.color) do
			formats[k] = "<color 0x"..string.format("%x", v)..">";
		end
		
		formats.default = "</color>"
		
		data = f:read("*all"):gsub("([<>])", function(n) if n == "<" then return "<lt>" else return "<gt>" end end)
		if data[1] == "\n" then
			data = " "..data
		end
		f:close()
		
		data = parseNumbers(data);
		data = parseKeywords(data);
		data = parseClasses(data);
		data = parseStrings(data);
		data = parseComments(data);
		data = data:gsub("([\t\n])",function(n) if n == "\t" then return "    " else return "<br>" end end)
		
		local line = 1;
		linedata = "";
		for _ in data:gmatch("(.-)<br>") do
			line = line+1;
		end
		
		local charlnwid = math.ceil(math.log(line))
		linewid = 8*charlnwid
		
		line = 1;
		for v in data:gmatch("(.-)<br>") do
			linedata = linedata..tostring(line).."<br>"; 
			
			totalHeight = totalHeight + 1;
			
			local wid = textplus.layout(textplus.parse(v, {font = font})).width
			while wid > 800-linewid-8 do
				linedata = linedata.."<br>";
				totalHeight = totalHeight + 1;
				wid = wid-(800-linewid-8)
			end
			line = line+1;
		end
		totalHeight = totalHeight + 1;
		linedata = linedata..tostring(line); 
	else
		if(codeindex ~= 0) then
			nextData();
		else
			data = nil;
		end
	end
	scroll = 0;
end

function nextData()
	codeindex = (codeindex+1)%(#paths+1);
	loadData(paths[codeindex] or "");
end

function code.onKeyboardPress(k)
	if(paths == nil) then
		if(isOverworld) then
			paths = {__episodePath.."\\lunaoverworld.lua", __episodePath.."\\map.lua"};
		else
			paths = {__customFolderPath.."\\lunadll.lua", __customFolderPath.."\\luna.lua", __episodePath.."\\lunaworld.lua", __episodePath.."\\luna.lua"};
		end
	end
	if(k == VK_F2) then
		nextData();
	elseif(k == 0xBB) then --PLUS
		scroll = math.clamp(scroll - 1, math.floor(600/9)-totalHeight-5, 0);
	elseif(k == 0xBD) then --MINUS
		scroll = math.min(scroll + 1,0);
	end
end


function code.onInitAPI()
	registerEvent(code, "onDraw");
	registerEvent(code, "onKeyboardPress");
end

function code.onDraw()
	if(paths == nil or paths[codeindex] == nil) then
		return;
	end	
	
	Text.print(scroll,0,0)
	
	local lh = --[[font.charHeight]]8 + 1;
	local y = lh + 3 + lh*scroll;
	local n = paths[codeindex]:match("^.*()\\");
	if(n) then
		n = paths[codeindex]:sub(n+1);
	else
		n = paths[codeindex];
	end
	local layout = textplus.layout(textplus.parse(pathTypes[codeindex]..": "..n, {font = font}), 800-8)
	textplus.render{layout = layout, x = 8, y = y-3, priority = 9.999}
	local w,h = layout.width,layout.height
	if(data) then
		layout = textplus.layout(textplus.parse(data, {font = font}), 800-linewid-8)
		textplus.render{layout = layout, x = linewid+8, y = y+lh, priority = 9.999}
		w,h = layout.width,layout.height
		textplus.print{text = linedata, x=8, y=y+lh, maxWidth=800, font=font, color = {0.34509803921,0.34509803921,0.34509803921,1}, priority=9.999}
		w = w + linewid;
		h = h + lh*2;
	end
	w = w + 16
	h = h + lh
	Graphics.glDraw{vertexCoords={0,y-lh-3,w,y-lh-3,w,y+h,0,y+h}, color={0,0,0,0.75}, primitive=Graphics.GL_TRIANGLE_FAN, priority=9.99};
end

return code;