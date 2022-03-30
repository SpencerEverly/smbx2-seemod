--[[
   Save Table to File
   Load Table from File
   v 1.0
   
   Modified for SMBX2 by Hoeloe
   Licensed under the same terms as Lua itself.
]]--

local serializer = {}

--Required for ltcn based serializer
--local ltcn = require("ext/ltcn")

local stringformat = string.format
local stringmatch = string.match
local tableinsert = table.insert
local tostring = tostring
local ipairs = ipairs
local pairs = pairs

local function exportstring( s )
	return stringformat("%q", s)
end

--More accurate tostring method
local function numtostring(n)
	return stringformat("%0.16g",n)
end

serializer.convertnumber = numtostring

local typeregister = {}

--Register function for classes
function serializer.register(typ, serialize, deserialize)
	if typeregister[typ] ~= nil then
		error(typ.." is already registered for serialization.",2)
	else
		typeregister[typ] = {serialize = serialize, deserialize = deserialize}
	end
end

--Value parser
local function parseval(tables, lookup, v)
	local stype = type( v )
	if stype == "table" then
		if not lookup[v] then
			tableinsert( tables, v )
			lookup[v] = #tables
		end
		return "{"..lookup[v].."}"
	elseif stype == "string" then
		return exportstring( v )
	elseif stype == "number" then
		return numtostring( v )
	elseif stype == "boolean" then
		return tostring( v )
	elseif typeregister[stype] then
		if not lookup[v] then
			tableinsert( tables, {typeregister[stype].serialize(v)} )
			lookup[v] = #tables
		end
		return "{\""..stype.."\", "..lookup[v].."}"
	else
		error(tostring(v).." is not a serializable type ("..type(v)..").",3)
	end
end

--Serialize (write) function
function serializer.serialize(tbl)
	local charS,charE = "   ","\n"
	local strval = ""

	-- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
	strval = strval.."{"..charE

	for idx,t in ipairs( tables ) do
		strval = strval.."--["..idx.."]--"..charE
		strval = strval.."{"..charE
		local thandled = {}

		local prepwrite
		for i,v in ipairs( t ) do
			thandled[i] = true
			-- only handle value

			local ech
			if i == #t then
				ech = ""
				prepwrite = ","..charE
			else
				ech = ","..charE
			end

			strval = strval..charS..parseval(tables, lookup, v)..ech
		end

		for i,v in pairs( t ) do
			-- escape handled values
			if (not thandled[i]) then

				if prepwrite then
					strval = strval..prepwrite
					prepwrite = nil
				end

				local str = ""
				
				-- handle index
				str = charS.."["..parseval(tables, lookup, i).."]="

				if str ~= "" then
					-- handle value
					strval = strval..str..parseval(tables, lookup, v)
					prepwrite = ","..charE
				end
			end
		end

		if idx == #tables then
			strval = strval..charE.."}"..charE
		else
			strval = strval..charE.."},"..charE
		end
	end
	strval = strval.."}"
	return strval
end
   
local function doparse(tables, tolinki, deserialized, v)
	if type( v ) == "table" then
		if type(v[1]) == "string" then
			if deserialized[v[2]] == nil then
				deserialized[v[2]] = typeregister[v[1]].deserialize(doparse(tables, tolinki, deserialized, tables[v[2]][1]))
			end
			return deserialized[v[2]]
		else
			return tables[v[1]]
		end
	else
		return v
	end
end

local function parseError(err)
	local msg = string.match(err, "^%b[]:(.*)$")
	if msg then
		msg = "\n\n"..msg
	else
		msg = ""
	end
	return msg
end

--Deserialize (read) function
function serializer.deserialize(str, filename)
	filename = filename or ""
	if stringmatch(str, "^%b{}$") then
	
		--LTCN based parser
		--local tables = ltcn.parse(str, "") 
		local ftables,err = load("return "..str, nil, "t", {inf = math.huge, nan = 0/0})
		if err then
			
			error("Deserialization failed: Malformed data in "..filename.."."..parseError(err), 2) 
		end
		
		local deserialized = {}
		local succ,tables = pcall(ftables)
		if not succ then
			error("Deserialization failed: Malformed data in "..filename.."."..parseError(tables), 2)
		end
		for idx = 1,#tables do
			local tolinki = {}
			for i,v in pairs( tables[idx] ) do
				tables[idx][i] = doparse(tables, tolinki, deserialized, v)
				if type( i ) == "table" and tables[i[1]] then
					tableinsert( tolinki,{ i,tables[i[1]] } )
				end
			end
			-- link indices
			for _,v in ipairs( tolinki ) do
				tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
			end
		end
		return tables[1]
	else
		error("Deserialization failed: Malformed data in "..filename..".\n\nFile is not in expected format.", 2)
	end
end


return serializer
