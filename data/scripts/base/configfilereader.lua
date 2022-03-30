--configFileReader.lua
--v1.0.0
--Created by Horikawa Otane, 2016

local configFileReader = {}

local find = string.find
local sub = string.sub
local match = string.match
local split = string.split
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local tableinsert = table.insert

local function parseLine(line, enums, allowranges, keephex)
	-- ignore headings and comments
	if match(line, "^%s*%[.*%]%s*$") or match(line, "^%s*[;#].*$") then
		return nil, nil, false
	end

	-- Can't use match to split because match is always greedy
	local splitidx = find(line, "=")
	if splitidx == nil then
		return nil, nil, true
	end
	local key = match(sub(line, 1, splitidx-1), "^%s*(%S+)%s*$")
	local value = match(sub(line, splitidx+1, -1), "^%s*(%S+.-)%s*$")
	
	if key ~= nil and value ~= nil then
		if match(value, "^\".*\"$") or match(value, "^'.*'$") then --string surrounded by ' ' or " "
			value = sub(value, 2, -2)
		elseif allowranges and match(value, "%s*(.-)%s*:%s*(.-)%s*") then --number ranges
			value = split(value, ":", true)
			value[1] = tonumber(value[1])
			value[2] = tonumber(value[2])
		elseif keephex and match(value, "%s*(0x[0-9a-fA-F]+)%s*") then
			value = value;
		elseif tonumber(value) then --numbers/decimals
			value = tonumber(value)
		elseif value == "true" then --booleans
			value = true
		elseif value == "false" then
			value = false
		elseif enums ~= nil then
			for k,v in pairs(enums) do
				if value == k then
					value = v
					break
				end
			end
		else
			-- throw error?
		end
		
		return key, value, false
	else
		-- Error
		return nil, nil, true
	end
end

function configFileReader.parseTxt(objectId)
	return configFileReader.rawParse(Misc.resolveFile(objectId), true)
end

function configFileReader.rawParse(objectPath, keephex)	
	local finalArray = {}
	if objectPath ~= nil then	
	
	local lns = io.readFileLines(objectPath)
	if lns == nil then
		error("Error loading config file "..objectPath, 2)
	end
		for _,line in ipairs(lns) do
			if not match(line, "^%s*$") then
				local key, value, err = parseLine(line, nil, false, keephex);
				if(err) then
					local i = match(objectPath, '^.*()[/\\]');
					Misc.warn("Invalid line was passed to config file "..sub(objectPath,i-#objectPath)..": "..line,2);
				elseif key then
					finalArray[key] = value;
				end
			end
		end
		return finalArray;
	else
		return nil;
	end
end

function configFileReader.parseWithHeaders(path, defaultheaders, enums, allowranges, keephex)
	local data = {};
	local headers = {};
	local index = nil;
	local headerless = {};
	local lns = io.readFileLines(path)
	if lns == nil then
		error("Error loading config file "..path, 2)
	end
	for _,v in ipairs(lns) do
		if(v ~= nil) then
			local header = match(v, "^%s*%[(.+)%]%s*$");
			if(header) then
				if(data[header] == nil and defaultheaders[header] == nil) then
					data[header] = {};
					tableinsert(headers, header);
				end
				if(defaultheaders[header]) then
					index = nil;
				else
					index = header;
				end
			elseif(index ~= nil and data[index] ~= nil) then
				tableinsert(data[index], v);
			else
				tableinsert(headerless, v);
			end
		end
	end
	local layers = {}
	for _,h in ipairs(headers) do
		local l = configFileReader.dataParse(data[h], enums, allowranges, keephex);
		l.name = l.name or h;
		l._header = h;
		tableinsert(layers, l);
	end
	
	return layers, configFileReader.dataParse(headerless, enums, allowranges, keephex);
end

function configFileReader.dataParse(data, enums, allowranges, keephex)
	local finalArray = {}
	local errors = {};
	enumMatches = {};
	if data ~= nil then
		for _,line in ipairs(data) do
			local key, value, err = parseLine(line, enums, allowranges, keephex);
			if(err) then
				tableinsert(errors, line);
			elseif key ~= nil then
				finalArray[key] = value;
			end
		end
		return finalArray, errors
	else
		return nil, errors
	end
end

return configFileReader
