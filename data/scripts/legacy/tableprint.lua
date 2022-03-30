-- tableprint.lua
-- version 1.0

local tablePrint = {}
tablePrint.indents = 0


function tablePrint.val_to_str ( v, useFormatting )
	if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
			return "'" .. v .. "'"
		end
		if  useFormatting  then
			return '<color 0x99FF99FF>"' .. string.gsub(v,'"', '\\"' ) .. '"<color 0xFFFFFFFF>'
		else
			return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
		end
	elseif  "table" == type( v )  then
		return tablePrint.tostring( v, useFormatting )
	elseif  "boolean" == type( v )  or  "number" == type( v )  then
		return tostring( v )
	else
		return type( v )
	end
end


function tablePrint.key_to_str ( k, useFormatting )
	local returnStr
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		returnStr = k
	else
		returnStr = "[" .. tablePrint.val_to_str( k, useFormatting ) .. "]"
	end
	if  useFormatting  then
		returnStr = "<color 0xFFFF66FF>" .. returnStr .. "<color 0xFFFFFFFF>"
	end
		
	return returnStr
end


function tablePrint.tostring( tbl, useFormatting )
	if  useFormatting == nil  then  useFormatting = false;  end;
	
	tablePrint.indents = tablePrint.indents + 1
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		table.insert( result, tablePrint.val_to_str( v, useFormatting ) )
	done[ k ] = true
	end
	for k, v in pairs( tbl ) do
		if not done[ k ] then
			table.insert( result,
			                      tablePrint.key_to_str( k, useFormatting ) .. "=" .. tablePrint.val_to_str( v, useFormatting ) )
		end
	end
	local indentString = string.rep("   ", tablePrint.indents)
	tablePrint.indents = tablePrint.indents - 1
	
	if  useFormatting  then
		return "\n" .. indentString .. "<color 0xFF9999FF>{<color 0xFFFFFFFF>" .. table.concat( result, ",\n " .. indentString ) .. "\n" .. indentString .. "<color 0xFF9999FF>}<color 0xFFFFFFFF>"
	else
		return "\n" .. indentString .. "{" .. table.concat( result, ",\n " .. indentString ) .. "\n" .. indentString .. "}"
	end
end



return tablePrint;