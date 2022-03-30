--***************************************************************************************
--                                                                                      *
-- 	textblox.lua                                                                        *
--  v0.4.9                                                                              *
--  Documentation: http://wohlsoft.ru/pgewiki/Textblox.lua                              *
--                                                                                      *
--***************************************************************************************

local textblox = {} --Package table
textblox.version = "0.4.8"

local graphX = require("graphX")
local graphX2 = require("graphX2")
local mathX = require("mathematX")
local libError = {}

local graphXActive = false;
local graphX2Active = true;
local mathXActive = true;
local pnpcActive = true;
local inputs = require("inputs2");
local rng = require("rng");

local checkedInEpisode = false;


local firstFrameYet = false
local queuedPause = false



function textblox.onInitAPI() --Is called when the api is loaded by loadAPI.
	--register event handler
	--registerEvent(string apiName, string internalEventName, string functionToCall, boolean callBeforeMain)
	
	registerEvent(textblox, "onKeyboardPress", "onKeyboardPress", true)
	registerEvent(textblox, "onHUDDraw", "update", true) --Register the loop event
	registerEvent(textblox, "onMessageBox", "onMessageBox", true) --Register the loop event
	registerEvent(textblox, "onEvent", "onEvent", true) --Register the loop event
end



-- Misc control vars
textblox.textBlockRegister = {}
--textblox.resourcePath = "..\\..\\..\\scripts\\textblox\\"
--textblox.resourcePathOver = "..\\..\\scripts\\textblox\\"

textblox.currentMessage = nil

textblox.currentTrackingTarget = nil
textblox.icons = {}
	
local drawCall_points = {}
local drawCall_uvs = {}
local drawCall_colors = {}

local drawCall_currColor = {}
local drawCall_multiColored = false
local drawCall_currColorHex = 0xFFFFFFFF

local precalcU = {}
local precalcV = {}

for  i=1, 129  do
	local character = string.char(i + 32)
	precalcU [character] = ((i-1)%16)/16
	precalcV [character] = math.floor((i-1)/16)/8
end

local colorCache = {}




--[[ TO-DO

  - Improve accuracy of detecting the source of a text block (waiting on the extra parameter for onMessageBox, use onKeyboardPress in the meantime)
  - Fix the freeze (look into bounding box detection)
  - Optimize the wrapping function
V - Scale property in printExt
V - Monospace property in printExt
  - Possibly implement some/all of the options here (https://xkcd.com/1676/)


  - Replace graphx2 menubox draw calls with imagic
  -- Generate the points, uvs, etc. for the menubox poly
  -- Cache them in the text block instance with an isDirty flag like the formatted text
  -- Draw based on the cached data
  - Remove deepcopy from textblox
  - Optimize insertTiming (replace gsub with something less costly if possible)
V - Fix defaultChain
  - Redo a good chunk of the library to use tokenized data instead of strings
]]





--***************************************************************************************************
--                                                                                                  *
--              ENUMS                                                                               *
--                                                                                                  *
--***************************************************************************************************
-- Tokens
local TOKEN = {TEXT=1, CMD=2, INSERT=3, FORMAT=4, VISUAL=5, CUE=6}
local cmdINSERT = {gt=1, lt=2, butt=3}
local cmdFORMAT = {br=1, nowrap=2, notiming=3}
local cmdVISUAL = {b=1, i=2, tremble=3, wave=4, color=5, img=6}
local cmdCUE    = {pause=1, speed=2, sound=3, shake=4, funct=5}



do
	-- Font types
	textblox.FONTTYPE_DEFAULT = 0
	textblox.FONTTYPE_SPRITE = 1
	textblox.FONTTYPE_TTF = 2   --NOT SUPPORTED YET

	-- Override mode
	textblox.OVERRIDE_VANILLA = 0
	textblox.OVERRIDE_BASIC = 1
	textblox.OVERRIDE_TAILORED = 2

	-- Presets
	textblox.PRESET_SYSTEM = 1
	textblox.PRESET_BUBBLE = 2
	textblox.PRESET_SIGN = 3
	
	-- Boxtypes
	textblox.BOXTYPE_NONE = 1
	textblox.BOXTYPE_MENU = 2
	textblox.BOXTYPE_WORDBUBBLE = 3
	textblox.BOXTYPE_SIGN = 4
	textblox.BOXTYPE_CUSTOM = 99
	
	-- Bind mode
	textblox.BIND_SCREEN = 1
	textblox.BIND_LEVEL = 2

	-- Scale mode
	textblox.SCALE_FIXED = 1
	textblox.SCALE_AUTO = 2
	
	-- Alignment
	textblox.ALIGN_LEFT = 1
	textblox.ALIGN_RIGHT = 2
	textblox.ALIGN_TOP = 3
	textblox.ALIGN_BOTTOM = 4
	textblox.ALIGN_MID = 5
	
	textblox.HALIGN_LEFT = 1
	textblox.HALIGN_MID = 5
	textblox.HALIGN_RIGHT = 2
	
	textblox.VALIGN_TOP = 3
	textblox.VALIGN_MID = 5
	textblox.VALIGN_BOTTOM = 4
end	


-- Config vars
textblox.useGlForFonts = false

textblox.overrideMessageBox = false
textblox.overrideMode = textblox.OVERRIDE_VANILLA
	


--***************************************************************************************************
--                                                                                                  *
--              DEBUG STUFF                                                                         *
--                                                                                                  *
--***************************************************************************************************
textblox.debug = false

local bm_time

local hasDipped = false
local bm_clock = Misc.clock
local bm_vals = {
                    [0]=0,
                    [2]=math.huge, [3]=-math.huge,
                    [4]=math.huge, [5]=-math.huge,
                    [6]=math.huge, [7]=-math.huge,
                    [8]=math.huge, [9]=-math.huge,
                    [10]=math.huge, [11]=-math.huge,
                    [12]=math.huge, [13]=-math.huge,
                    [14]=0,[15]=0}

					
local function benchmark_start ()
	return bm_clock()
end

local function benchmark_end (startVal, minIndex, maxIndex)
	local bm_time = bm_clock() - startVal
	
	if  textblox.debug  then
		bm_vals[minIndex] = math.min(bm_time, bm_vals[minIndex])
		bm_vals[maxIndex] = math.max(bm_time, bm_vals[maxIndex])
	end
end
					
--[[
1 = num textblocks

[PrintExt]
2 = min time to process any chunk
3 = max time to process any chunk
4 = min time to display any chunk
5 = max time to display any chunk
]]

--***************************************************************************************************
--                                                                                                  *
--              MISCELLANEOUS FUNCTIONS													    		*
--                                                                                                  *
--***************************************************************************************************
	local randS_Chars = {}
	for randS_Loop = 0, 255 do
		randS_Chars[randS_Loop+1] = string.char(randS_Loop)
	end
	local randS_String = table.concat(randS_Chars)

	local randS_Built = {['.'] = randS_Chars}

	local randS_AddLookup = function(CharSet)
		local Substitute = string.gsub(randS_String, '[^'..CharSet..']', '')
		local Lookup = {}
		for randS_Loop = 1, string.len(Substitute) do
			Lookup[randS_Loop] = string.sub(Substitute, randS_Loop, randS_Loop)
		end
		randS_Built[CharSet] = Lookup

		return Lookup
	end
	
	function string.random(Length, CharSet)
		-- Length (number)
		-- CharSet (string, optional); e.g. %l%d for lower case letters and digits

		local CharSet = CharSet or '.'

		if CharSet == '' then
			return ''
		else
			local Result = {}
			local Lookup = randS_Built[CharSet] or randS_AddLookup(CharSet)
			local Range = #Lookup

			for randS_Loop = 1,Length do
				Result[randS_Loop] = Lookup[math.random(1, Range)]
			end

			return table.concat(Result)
		end
	end
	
	
	local function typeof (var)
		local typeval = type(var)
		
		if  typeval == "table"  then
			if var.fontType ~= nil  then  typeval = "font";
			elseif var.boxType ~= nil  then  typeval = "textblock";  end;
		end
		
		return typeval
	end
			
	local function offsetRect (rect, x, y)
		newRect = newRECTd()
		
		newRect.left = rect.left + x
		newRect.right = rect.right + x
		newRect.top = rect.top + y
		newRect.bottom = rect.bottom + y
		
		return newRect
	end

	local function getScreenBounds (camNumber)
		if  camNumber == nil  then
			camNumber = 1
		end
		
		local cam = Camera.get ()[camNumber]
		local b =  {left = cam.x, 
		            right = cam.x + cam.width,
		            top = cam.y,
		            bottom = cam.y + cam.height}
		
		return b;	
	end

	local function sign (number)
		if  number > 0  then
			return 1;
		elseif  number < 0  then
			return -1;
		else
			return 0;
		end
	end
	
	local function worldToScreen (x,y)
		local b = getScreenBounds ();
		local x1 = x-b.left;
		local y1 = y-b.top;
		return x1,y1;
	end

	local function coordsToPoints(x1,y1,x2,y2)
		local pts = {};
		pts[1] = x1;    pts[2] = y1;
		pts[3] = x2;    pts[4] = y1;
		pts[5] = x1;    pts[6] = y2;
		
		pts[7] = x1;    pts[8] = y2;
		pts[9] = x2;    pts[10] = y2;
		pts[11] = x2;   pts[12] = y1;
		
		return pts;
	end

	local function getCachedTableColor (hexcol)
		if  colorCache[hexcol] == nil  then
			colorCache[hexcol] = mathX.hexColorToTable (hexcol)
		end
		return colorCache[hexcol]
	end
	
	
	local function hsl_to_rgb(h, s, L)
		h = h/360
		local m1, m2
		if L<=0.5 then 
			m2 = L*(s+1)
		else 
			m2 = L+s-L*s
		end
		m1 = L*2-m2

		local function _h2rgb(m1, m2, h)
			if h<0 then h = h+1 end
			if h>1 then h = h-1 end
			if h*6<1 then 
				return m1+(m2-m1)*h*6
			elseif h*2<1 then 
				return m2 
			elseif h*3<2 then 
				return m1+(m2-m1)*(2/3-h)*6
			else
				return m1
			end
		end

		return _h2rgb(m1, m2, h+1/3), _h2rgb(m1, m2, h), _h2rgb(m1, m2, h-1/3)
	end
	
	
	local function HSLToRGBAHex (hue, saturation, lightness, alpha)
		
		local r,g,b = hsl_to_rgb(hue, saturation, lightness)
		
		local hexStr = string.format("%x%x%x%x",math.ceil(256*r)-1, math.ceil(256*g)-1, math.ceil(256*b)-1, math.ceil(256*alpha)-1)
		--local hexStr = string.format("%x%x%x%x",math.ceil(256*(r+m))-1, math.ceil(256*(g+m))-1, math.ceil(256*(b+m))-1, math.ceil(256*alpha-1))
		return tonumber(hexStr, 16)
	end
	
	
	-- Default value stuff
	local function defaultChain (args)
		local returnval
		
		i = 1;
		while  i <= args[1]  do
			if  args[i+1] ~= nil  then
				returnval = args[i+1]
				break;
			else
				i = i+1
			end
		end
		
		return returnval, i;
	end
	
	
	--[[
	local function defaultChainCombo (keys, tables)
		local returnTable = {}
		
		-- Go through all the keys
		for  k,v  in pairs (keys)  do			
			
			-- Go through each table and copy the first non-nil value under the current key
			i = 1;
			while i <= #tables  do
				
				-- Try to get the value from the current set of arguments;  if successful, break, otherwise move on to the next
				local argSet = tables[i]
				if  argSet[v] ~= nil  then
					returnTable[v] = argSet[v]
					break;
				else
					i = i+1
				end
			end			
		end
		
		-- Return the composite table
		return returnval;
	end
	]]
	
	
	-- Table printing
	local tablePrint = {}
	tablePrint.indents = 0
	
	function tablePrint.val_to_str ( v )
	  if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
		  return "'" .. v .. "'"
		end
		return '<color 0x99FF99FF>"' .. string.gsub(v,'"', '\\"' ) .. '"<color 0xFFFFFFFF>'
	  else
		return "table" == type( v ) and tablePrint.tostring( v )  or  tostring( v )
	  end
	end

	function tablePrint.key_to_str ( k )
	  local returnStr
	  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		returnStr = k
	  else
		returnStr = "[" .. tablePrint.val_to_str( k ) .. "]"
	  end
	  returnStr = "<color 0xFFFF66FF>" .. returnStr .. "<color 0xFFFFFFFF>"
	  
	  return returnStr
	end

	function tablePrint.tostring( tbl )
	  tablePrint.indents = tablePrint.indents + 1
	  local result, done = {}, {}
	  for k, v in ipairs( tbl ) do
		table.insert( result, tablePrint.val_to_str( v ) )
		done[ k ] = true
	  end
	  for k, v in pairs( tbl ) do
		if not done[ k ] then
		  table.insert( result,
			tablePrint.key_to_str( k ) .. "=" .. tablePrint.val_to_str( v ) )
		end
	  end
	  local indentString = string.rep("   ", tablePrint.indents)
	  tablePrint.indents = tablePrint.indents - 1
	  return "\n" .. indentString .. "<color 0xFF9999FF>{<color 0xFFFFFFFF>" .. table.concat( result, ",\n " .. indentString ) .. "\n" .. indentString .. "<color 0xFF9999FF>}<color 0xFFFFFFFF>"
	end
		
		
	-- Deep copy
	local function deepcopy (orig)
		local orig_type = typeof(orig)
		local copy		
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			setmetatable(copy, deepcopy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end

	local function deepCopyWithCheck (orig)
		local orig_type = typeof(orig)
		local copy
		
		-- If type is table and has not already been copied...
		if orig_type == 'table' then
			if  orig.ALREADY_COPIED == nil  and  #orig > 0  then
				-- ...create a new table and copy over each index
				copy = {}
				for orig_key, orig_value in next, orig, nil do
					copy[deepcopy(orig_key)] = deepcopy(orig_value)
				end
				setmetatable(copy, deepcopy(getmetatable(orig)))
			else
				copy = orig
			end
			orig.ALREADY_COPIED = true
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end
		

	-- Get specific indexes of a substring
	local function lastIndexOf(str, substr, upperlimit)
		if  upperlimit == nil  then  upperlimit = -1;  end
		local currentPos, startPos
		local endPos = 0
		repeat
			currentPos = startPos
			startPos, endPos = string.find(str, substr, endPos + 1, true)
		until startPos == nil  or  (upperlimit ~= -1  and  startPos > upperlimit)

		return currentPos
	end
	
	
	-- Load proportional spacing from ini file
	local function loadSpacing (path)
		local spacing = {}
		
		local file = io.open(path, "r");
		for t in file:lines() do
			
			-- Ignore line breaks and comments
			if t ~= ""  then
				if string.sub(t, 1, 1) ~= ";"  then
			
					-- Get divider position
					local divPos = lastIndexOf (t,"=")
					
					-- Get character and value
					local key = string.sub(t, 1, divPos-1)
					local val = tonumber(string.sub(t, divPos+1))
					
					-- Add to the table
					spacing[key] = val
				end
			end
		end
		
		return spacing
	end

	-- Split by pattern
	local function splitStringByPattern (inputstr, sep)
		if sep == nil then
            sep = "%s"
        end
		
        local t = {}
        for str in string.gmatch(inputstr, "(.-)("..sep..")") do
            table.insert(t,str)
        end
        return t
	end
	
	-- Split at point
	local function splitStringAtPoint (str, pos, gap)
		
		-- Default to gap of 0
		gap = gap or 0

		-- If splitting at the beginning or past the end, no splitting necessary
		if  pos+gap <= 1  then  return "", str;  end
		if  pos+gap > string.len(str)  then  return str, "";  end
		
		-- Perform the split
		local head = string.sub(str, 1, pos);		
		pos = pos+gap
		local tail = string.sub(str, pos+1, -1);

		-- Return result
		return head, tail;
	end
	

	function textblox.formatTextForWrapping (text, font, wrapWidth, addSlashN, monospace, scale)
		
		-- If given an unusable width, just return the unformatted text
		if  wrapWidth < font.charWidth  or  wrapWidth == math.huge  then
			return text;
		end
		
		
		-- Setup
		local newString = ""
		local currentLineWidth = 0
		local iconMode = false
		local noWrapMode = false
		
		
		-- Process commands and plaintext in chunks
		for textChunk in string.gmatch(text, "<*[^<>]+>*")	do
			
			local bm_start = benchmark_start ()
			--windowDebug ("Full string = "..newString.."\n\nCurrent text chunk = "..textChunk.."\n\nWrap width = "..tostring(wrapWidth))
			
			-- Is a command			
			if  string.find(textChunk, "<.*>") ~= nil  then
			
				local checkForWrap = false
				local shouldBreak = false
				local replaceString = nil
				local addWidth = 0

				-- Get the command and parameters
				local commandStr, amountStr = string.match (textChunk, "([^<>%s]+) ([^<>%s]+)")
				if  commandStr == nil  then
					commandStr = string.match (textChunk, "[^<>%s]+")
				end
								
				-- Line break
				if  commandStr == "br"  then
					currentLineWidth = 0
				end
				
				-- No wrap
				if  commandStr == "nowrap"  then
					noWrapMode = true
				end
				if  commandStr == "/nowrap"  then
					noWrapMode = false
				end
				
				
				-- Icon
				if	commandStr == "img"  then
					addWidth = font.charWidth
					checkForWrap = true
				end
				
				
				-- Greater than
				if  commandStr == "gt"  then
					replaceString = ">"
					checkForWrap = true
				end
				
				-- Greater than
				if  commandStr == "lt"  then
					replaceString = "<"
					processPlaintext = true
				end
				
				-- BUTT
				if  commandStr == "butt"  then
					replaceString = "rockythechao"
					processPlaintext = true
				end
			
			
				-- Wrap the command to the next line if necessary
				if  checkForWrap  then
					if  replaceString ~= nil  then  addWidth = font:getStringWidth (replaceString, monospace, scale);  end;
					if  currentLineWidth + addWidth > wrapWidth  then
						newString = newString.."<br>"
						currentLineWidth = addWidth
					end
				end
				
				-- Finally, append the character
				newString = newString..textChunk

				
			-- Is plaintext
			else			
			
				-- Add the words and whitespaces to a single table
				local words = {}
				local areWhitespace = {}
				--windowDebug (textChunk)
				
				for  beforeSpace, word, afterSpace  in  textChunk:gmatch("(%s*)(%S+)(%s*)")  do
					
					if  beforeSpace ~= ""  and  beforeSpace ~= nil  then
						table.insert (words, beforeSpace)
						table.insert (areWhitespace, true)
					end
					if  word ~= ""  and  word ~= nil  then
						table.insert (words, word)				
						table.insert (areWhitespace, false)
					end
					if  afterSpace ~= ""  and  afterSpace ~= nil  then
						table.insert (words, afterSpace)				
						table.insert (areWhitespace, true)
					end
				end
				
				
				-- Iterate through the table
				local newTextChunk = ""
				local i = 1
				
				--windowDebug (tostring(#words))
				
				while (i <= #words) do
				
					-- Start processing current word
					local word = words[i]
					local overflowPos = font:getStringWrapPoint (word, math.max(0, wrapWidth-currentLineWidth), monospace, scale)
					
					-- If not overflowing, just append and move on
					if overflowPos == nil  then
						newTextChunk = newTextChunk..word
						currentLineWidth = currentLineWidth + font:getStringWidth (word, monospace, scale)
					
					-- Otherwise...
					else
						-- Begin wrapping the word if necessary
						local overflowPos = font:getStringWrapPoint (word, math.max(0, wrapWidth-currentLineWidth), monospace, scale)
						local timesSplit = 0
						local wordWidth = font:getStringWidth (word, monospace, scale)
						local isWhitespace = areWhitespace[i]
						
						-- If the word can fit on the current line, place it there 
						if  overflowPos == nil  or  noWrapMode  then
							--windowDebug ("NO OVERFLOW:\n\n"..textblox.debugLineBreaks (newString..newTextChunk).."\n\n"..word.."\n\nWord width = "..tostring(wordWidth).."\ncurrent line width = "..tostring(currentLineWidth).."\nallotted space = "..tostring(wrapWidth))
							newTextChunk = newTextChunk..word
						
						
						-- Otherwise, if it's whitespace then split it accordingly
						elseif  isWhitespace  then
							--windowDebug ("SPACE BREAKUP:\n\n"..textblox.debugLineBreaks (newString..newTextChunk).."\n\n'"..word.."'\n\nWord width = "..tostring(wordWidth).."\ncurrent line width = "..tostring(currentLineWidth).."\nallotted space = "..tostring(wrapWidth))							
							local firstStr, secondStr
							if  word == " "  then  
								firstStr = ""
								secondStr = ""
								newTextChunk = newTextChunk.."<br>"
								wordWidth = font:getStringWidth (secondStr, monospace, scale)
							else
								firstStr, secondStr = splitStringAtPoint (word, overflowPos, 1)
								newTextChunk = newTextChunk..firstStr.."<br>"..secondStr
								wordWidth = font:getStringWidth (secondStr, monospace, scale)
							end
							currentLineWidth = 0
							
						
						-- Otherwise, if the word can fit on a single line then move it to the next one 
						elseif  wordWidth < wrapWidth  then
							--windowDebug ("OVERFLOW:\n\n"..textblox.debugLineBreaks (newString..newTextChunk).."\n\n"..word.."\n\nWord width = "..tostring(wordWidth).."\ncurrent line width = "..tostring(currentLineWidth).."\nallotted space = "..tostring(wrapWidth))
							newTextChunk = newTextChunk.."<br>"..word
							currentLineWidth = 0
						
						
						-- Otherwise, begin the hypenating loop
						else	
							local attempts = 0
							while (overflowPos ~= nil)  do
							
								-- Management vars
								local addADash = true;
								local finalWrapPos = overflowPos-1;
														
								-- Use an existing dash if possible
								local lastDashPos = lastIndexOf (word, "-", overflowPos);
								if  lastDashPos ~= nil  then
									finalWrapPos = lastDashPos;
									addADash = false;
								end						
							
								-- Split the string at that position
								local lineStr, remainder = splitStringAtPoint (word, finalWrapPos)
								if  addADash  then  lineStr = lineStr.."-";  end;
								newTextChunk = newTextChunk..lineStr.."<br>"
								word = remainder;
								currentLineWidth = 0;
								
								--windowDebug ("HYPHEN:\n\n"..textblox.debugLineBreaks (newString..newTextChunk).."\n\n"..word.."\n\nWord width = "..tostring(wordWidth).."\ncurrent line width = "..tostring(currentLineWidth).."\nallotted space = "..tostring(wrapWidth))

								
								-- Refresh the overflow position
								overflowPos = font:getStringWrapPoint (word, wrapWidth, monospace, scale)

								--windowDebug ("attempt "..tostring(attempts))
								
								-- Break from an infinite loop if necessary
								attempts = attempts+1
								if  attempts > 5  then
									windowDebug ("Too many attempts to hyphenate, breaking the loop.\nIf you got this error then either there's an issue with this loop or you're doing something horribly, horribly wrong.")
									break;
								end
							end
							
							-- Append the remainder
							newTextChunk = newTextChunk..word
							wordWidth = font:getStringWidth (word, monospace, scale)
						end

						-- Add the word's width to the line
						currentLineWidth = currentLineWidth + wordWidth;
						firstWord = false;
					end

					-- Move on to the next
					i = i+1					
				end
				
				-- Append the new text chunk
				newString = newString..newTextChunk
			end
			
			
			benchmark_end (bm_start, 6, 7)
		end
		
		--windowDebug (newString)		
		return newString
	end
	
	
	
	
	function textblox.formatTextForWrappingOld (text, wrapChars, addSlashN)
		
		-- Setup
		local newString = text
		local strLength = text:len()
		local currentLineWidth = 0
		local markupMode = 0
		
		local oldPos = 1
		local newOffset = 0
		local newOffsetDebug = 0
		
		local lineStart = 1
		local charsOnLine = 0
		local totalShownChars = 0
		
		local currentSpace = 1
		local prevSpace = 1
		local currentSpaceVisChars  = 0
		local prevSpaceVisChars  = 0
		
		local currentDash = 1
		local prevDash = 1
		local currentDashVisChars  = 0
		local prevDashVisChars  = 0
		
		
		while (oldPos <= strLength) do
		
			-- Get character
			local lastNum = math.max(1, oldPos-1)
			
			local lastChar = text:sub(lastNum, lastNum)
			local thisChar = text:sub(oldPos,oldPos)
			local nextChar = text:sub(oldPos+1, oldPos+1)
			local continue = false
								
			
			-- Wrap words when necessary
			if  charsOnLine > wrapChars  then
			
				
				local firstHalf = nil
				local secondHalf = nil
				local breakPoint = nil
			
			
				-- Add a break command + \n for debugging purposes
				local breakStr = "<br>"
				if  addSlashN == true  then
					breakStr = 	"_\n" 
					            .. tostring(prevSpace-lineStart) .. "," .. tostring(currentSpace-lineStart) .. ", " .. tostring(oldPos-lineStart) 
					            .. "   " .. tostring(newOffsetDebug) .. ", " .. tostring(oldPos+newOffsetDebug) .. ", " .. tostring(oldPos+newOffsetDebug-lineStart)
					            .. "   " .. tostring(prevSpaceVisChars) .. "/" .. tostring(currentSpaceVisChars) .. ", " .. tostring(charsOnLine).. "\n\n"
				end
				
			
				-- If a line break can be inserted between words, do so
				if  currentSpace ~= lineStart  then
					breakPoint = currentSpace
					
					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)
				
					newString = firstHalf .. breakStr .. secondHalf
					newOffset = newOffset + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4 - 1
				
				
				-- Otherwise, if the word already has a dash, break the line there
				elseif  currentDash ~= lineStart  then
					breakPoint = currentDash

					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)					
					
					newString = firstHalf .. breakStr .. secondHalf
					newOffset = newOffset + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4
				
				
				-- Otherwise, insert a dash and a break
				else
					breakPoint = oldPos - 3
					
					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)
					
					newString = firstHalf .. "-" .. breakStr .. secondHalf
					newOffset = newOffset + 1 + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4 + 1			
				end
				
				
				-- Set up new line
				local newLineString = text:sub(breakPoint, oldPos)
				newLineString = newLineString:gsub ('<.*>', '')
				
				newLineChars = newLineString:len()
				
				charsOnLine = newLineChars
				lineStart = oldPos
				
				currentSpace = oldPos
				prevSpace = oldPos
				currentDash = oldPos
				prevDash = oldPos

				currentSpaceVisChars = 0
				prevSpaceVisChars = 0
				currentDashVisChars = 0
				prevDashVisChars = 0
			end

			
			-- Store space position
			if  thisChar == ' '  and  markupMode <= 0   then
				prevSpace = currentSpace
				currentSpace = oldPos
				prevSpaceVisChars = currentSpaceVisChars
				currentSpaceVisChars = charsOnLine
				
			
			-- Store dash position
			elseif  thisChar == '-'  and  markupMode <= 0   then
				prevDash = currentDash
				currentDash = oldPos
				prevSpaceVisChars = currentDashVisChars
				currentDashVisChars = charsOnLine
			
			-- Skip tags
			elseif  thisChar == '<'		then		
				markupMode = markupMode + 1
				continue = true
				
				-- But catch pre-existing breaks
				if  text:sub (oldPos, oldPos+3) == '<br>'  then
					charsOnLine = 0
					lineStart = oldPos
					
					currentSpace = oldPos
					prevSpace = oldPos
					currentDash = oldPos
					prevDash = oldPos
				end
				
			elseif  thisChar == ">"  	then
				markupMode = markupMode - 1
				continue = true
			end
			
			
			
			
			-- Count the current character				
			if  continue == false  and  markupMode <= 0  then			
				charsOnLine = charsOnLine + 1
				totalShownChars = totalShownChars + 1
			end
			
			
			-- Increment i
			oldPos = oldPos+1
		end
		
		return newString
	end
		
		
	


--***************************************************************************************************
--                                                                                                  *
--              SCANNING EVENTS FOR MESSAGE STRINGS										    		*
--                                                                                                  *
--***************************************************************************************************

	local eventTriggersMessage = {}
	
	local function getEventProperties ()
		
		-- loop through the event array
		local GM_EVENTS_PTR = mem (0x00B2C6CC, FIELD_DWORD)
		
		local allEventsString = ""
		for  i=0, 100  do
			local ptr           = GM_EVENTS_PTR + 0x588*i
			local namePtr       = ptr + 0x04
			local nameString    = tostring(mem (namePtr, FIELD_STRING))
			local messagePtr    = ptr + 0x08
			local messageString = tostring(mem (messagePtr, FIELD_STRING))
			
			---[[
			if  string.len (nameString) == 0  and  i > 0  then
				break;
			
			-- Get whether the event triggers a message box
			else
				eventTriggersMessage[nameString] = false
				if   string.len (messageString) ~= 0  then
					eventTriggersMessage[nameString] = true
				end
			end
		end		
	end
	
	
--***************************************************************************************************
--                                                                                                  *
--              FILE MANAGEMENT															    		*
--                                                                                                  *
--***************************************************************************************************

	function textblox.getPath (filename)
		local path = Misc.multiResolveFile(filename, "legacy\\textblox\\" .. filename, "legacy\\textblox\\font\\" .. filename, "scripts\\legacy\\textblox\\" .. filename, "scripts\\legacy\\textblox\\font\\" .. filename)
		--windowDebug (filename.."\n\n"..tostring(path))
		return path
		
		--[[
		local localPath = Misc.resolveFile (filename)  
						
		if  localPath  ~=  nil  then
			return localPath
		end
		
		if isOverworld == true  then
			return Misc.resolveFile (textblox.resourcePathOver..filename)
		else
			return Misc.resolveFile (textblox.resourcePath..filename)
		end
		]]		
	end





--***************************************************************************************************
--                                                                                                  *
--              TOKENIZATION															    		*
--                                                                                                  *
--***************************************************************************************************



local function tokenizeString (input, props)
	
	-- Copy parameters to local vars
	local font = props.font  or  textblox.FONT_DEFAULT
	
	local monospace = props.monospace
	if  monospace == nil  then  monospace = false;  end;
	
	local replaceNow = props.replaceNow
	if  replaceNow == nil  then  replaceNow = false;  end;
	
	
	-- Create the token table, current token and control vars
	local parsed = {}
	local token = {}
	
	local i = 0
	local tokenStart = 1
	local tokenEnd = 1
	local tokenType = nil
	
	local dividers = {}

	
	-- Loop through each character to parse the plaintext and command tokens
	string.gsub (textChunk, ".", function(c)
			
			-- First character, decide the token type
			if  tokenType == nil  then
				if  c == "<"  then
					token.type = TOKEN.CMD
				else
					token.type = TOKEN.TEXT
					token.params = {length=1}
				end
			end
			
			
			-- Iterate
			i = i+1
			local endThisToken = false
			local nextTokenType = TOKEN.TEXT
			
			
			-- Plaintext parsing
			if  token.type == TOKEN.TEXT  then
				nextTokenType = TOKEN.CMD
				
				-- End of plaintext token, start of command token
				if  c == "<"  then
					token.text = string.sub (tokenStart, i-1)
					token.length = i - tokenStart
					
					-- Toggle the insert token flag
					endThisToken = true
				
				-- Otherwise, add to the line width
				else
					token.width = token.width + font.kerning + font:getCharWidth (c, monospace)
				end

			
			-- Command parsing
			elseif  token.type == TOKEN.CMD  then
			
				-- Dividing space
				if  c == " "  then
					dividers[#dividers+1] = i
				end
				
				
				-- End of command token, start of plaintext token
				if  c == ">"  then
					
					-- Parse the command and parameters
					local commandStr
					if  #dividers == 0  then
						commandStr = string.sub (tokenStart,i)
					else
						commandStr = string.sub (tokenStart, dividers[1]-1)
						dividers[#dividers+1] = i
						for  k=1,#dividers-1  do
							token.params[#token.params+1] = string.sub (dividers[k]+1, dividers[k+1]-1)
						end
					end
					
					-- For insert commands...
					if cmdINSERT[commandStr] ~= nil  then
				
						-- If configured to do so, convert to plaintext immediately
						if  replaceNow  then
							local index = cmdINSERT[commandStr]
							token.type = TOKEN.TEXT
							local t = {">", "<", "rockythechao"}
							token.val = t[index]
						
						-- Otherwise, just store the command info
						else
							token.type = TOKEN.INSERT
							token.cmd = cmdINSERT[commandStr]
						end
						
						
					-- Just store the command info for the other command types
					else
						token.params = {val=amountStr}
						if cmdFORMAT[commandStr] ~= nil  then  token.type = TOKEN.FORMAT;  token.cmd = cmdFORMAT[commandStr];  end;
						if cmdVISUAL[commandStr] ~= nil  then  token.type = TOKEN.VISUAL;  token.cmd = cmdVISUAL[commandStr];  end;
						if cmdCUE[commandStr] ~= nil     then  token.type = TOKEN.CUE;     token.cmd = cmdCUE[commandStr];  end;
					end
					
					-- Toggle the insert token flag
					endThisToken = true
				end
			end
			
			
			-- Compile token
			if  endThisToken  then
				parsed[#parsed+1] = token
				token = {}
				token.type = nextTokenType
			end

			return c
		end)
		
	return parsed
end

	


--***************************************************************************************************
--                                                                                                  *
--              FONT CLASS																    		*
--                                                                                                  *
--***************************************************************************************************

local Font = {}
local FontMeta = {}
Font.__index = Font
	
do

	function Font.create (fontType, properties)
		local thisFont = {}
		setmetatable (thisFont, Font)
		
		-- Properties
		thisFont.fontType = fontType
		
		thisFont.imagePath = ""
		thisFont.imageRef = nil
			
		thisFont.charWidth = 16
		thisFont.spacing = {}
		thisFont.charHeight = 16
		thisFont.kerning = 0
		thisFont.leading = 0
		thisFont.scale = 1
		thisFont.scaleX = 1
		thisFont.scaleY = 1
		
		thisFont.fontIndex = 4
		
		
		-- Load ini if defined
		if  type(properties) == "table"  then
			local typeOfIniPath = type (properties.ini)
			if  typeOfIniPath == "string"  then
				local iniFile = textblox.getPath (properties.ini)
				properties = textblox.loadFontProps (iniFile, properties)
				thisFont.spacing = properties.spacing
			elseif  typeOfIniPath ~= "nil"  then
				error ("Type of ini property is "..typeOfIniPath..", should be file path string.")
			end
		end
		
		
		-- Default font
		if  fontType == textblox.FONTTYPE_DEFAULT	then
			thisFont.fontIndex = properties
			if      thisFont.fontIndex == 1  then
				
			elseif  thisFont.fontIndex == 2  then 
			
			elseif  thisFont.fontIndex == 3  then 
			
			elseif  thisFont.fontIndex == 4  then 
			
			end
		end
		
		-- Sprite font
		if  fontType == textblox.FONTTYPE_SPRITE  then		
			if  properties.image ~= nil  then
				thisFont.imageRef = properties.image
			else
				thisFont.imagePath = properties.imagePath  or  ""
				thisFont.imageRef = Graphics.loadImage (textblox.getPath(thisFont.imagePath))
			end
			
			local pathStr = properties.spacing  or  ""
			local fullpath
			if  type(pathStr) == "string"  and  properties.iniLoaded ~= true  then
				fullpath = textblox.getPath (pathStr)
			end
			if  fullpath ~= nil  then  thisFont.spacing = loadSpacing (fullpath);  end
			
			thisFont.scale = properties.scale  or  1
			thisFont.scaleX = properties.scaleX  or  thisFont.scale
			thisFont.scaleY = properties.scaleY  or  thisFont.scale
			thisFont.charWidth = properties.charWidth  or  16
			thisFont.charHeight = properties.charHeight  or  16
			thisFont.kerning = (properties.kerning  or  1) * thisFont.scaleX
			thisFont.leading = (properties.leading  or  1) * thisFont.scaleY
		end
		
		return thisFont
	end	

	------ Metatable stuff --------------------------------------------------------------------------------------	
	--[[
	function Font.__index(obj,key)
		if    (key == "fontType") then return rawget(obj, "fontType")
		elseif(key == "fontIndex") then return rawget(obj, "fontIndex")
		elseif(key == "imagePath") then return rawget(obj, "imagePath")
		elseif(key == "imageRef") then return rawget(obj, "imageRef")

		elseif(key == "charWidth") then return rawget(obj, "charWidth")
		elseif(key == "charHeight") then return rawget(obj, "charHeight")
		elseif(key == "spacing") then return rawget(obj, "spacing")
		
		elseif(key == "kerning") then return rawget(obj, "kerning")
		elseif(key == "leading") then return rawget(obj, "leading")
		
		elseif(key == "scale") then return rawget(obj, "scale")		
		elseif(key == "scaleX") then return rawget(obj, "scaleX")
		elseif(key == "scaleY") then return rawget(obj, "scaleY")
		
		elseif(key == "_type"  or  "__type") then
			return "font";
		else
			return rawget(obj, key)
			--return Font[key]
		end
	end

	function Font.__newindex(obj,key,val)
		if    (key == "fontType") then rawset(obj, "fontType", val)
		elseif(key == "fontIndex") then rawset(obj, "fontIndex", val)
		elseif(key == "imagePath") then rawset(obj, "imagePath", val)
		elseif(key == "imageRef") then rawset(obj, "imageRef", val)

		elseif(key == "charWidth") then rawset(obj, "charWidth", val)
		elseif(key == "charHeight") then rawset(obj, "charHeight", val)
		elseif(key == "spacing") then rawset(obj, "spacing", val)
		
		elseif(key == "kerning") then rawset(obj, "kerning", val)
		elseif(key == "leading") then rawset(obj, "leading", val)
		
		elseif(key == "scale") then rawset(obj, "scale", val)		
		elseif(key == "scaleX") then rawset(obj, "scaleX", val)
		elseif(key == "scaleY") then rawset(obj, "scaleY", val)
		
		elseif(key == "_type"  or  key == "__type") then
			error ("Cannot set the type of an object.", 2);
		else
			error("Field "..key.." cannot be changed or does not exist in the Font data structure.",2);
		end	
	end
	--]]
	
	function Font.__tostring (obj)
		if  obj.fontType == textblox.FONTTYPE_DEFAULT  then
			return "textblox font (Default "..tostring(obj.fontIndex)..")"
		
		elseif  obj.fontType == textblox.FONTTYPE_SPRITE  then
			return "textblox font (Sprite "..obj.imagePath..")"
		
		elseif  obj.fontType == textblox.FONTTYPE_TTF  then
			return "textblox font (TTF)"
		
		else
			return "textblox font (unknown type)"
		end
	end
	--]]
	
	
	
	------ Load properties from ini ----------------------------------------------------------------------------
	function textblox.loadFontProps (path, props)
		
		local defProps = {
		                  fontType = textblox.FONTTYPE_SPRITE,
		                  imagePath = "",
		                  charWidth = 16,
		                  charHeight = 16,
		                  kerning = 0,
		                  leading = 0,
		                  scale = 1,
		                  scaleX = 1,
		                  scaleY = 1,
		                  fontIndex = 4
		                 }
		
		
		-- Set the defaults
		if  props == nil  then
			props = defProps
		end
		
		props.spacing = {}

		
		-- Load the file
		local file = io.open(path, "r");
		for t in file:lines() do
			
			-- Ignore line breaks and comments
			if t ~= ""  then
				if string.sub(t, 1, 1) ~= ";"  then
			
					-- Get divider position
					local divPos = lastIndexOf (t,"=")
					
					-- Get character and value
					local key = string.sub(t, 1, divPos-1)
					local val = tonumber(string.sub(t, divPos+1))					
					
					-- Add to the table
					if  defProps[key] ~= nil  then
						props[key] = val
					else
						props.spacing[key] = val
					end
				end
			end
		end
		props.iniLoaded = true
		
		return props
	end

	
	------ Constructor wrapper functions -----------------------------------------------------------------------
	
	function textblox.Font (fontType, properties)
		return Font.create (fontType, properties)
	end
	function textblox.createFont (fontType, properties)
		return Font.create (fontType, properties)
	end
		
	
	------ Methods ---------------------------------------------------------------------------------------------
	function Font:getStringWidth (text, isMonospace, scale)
		if  scale == nil  then  scale = 1;  end;
		
		local totalWidth = 0
		if  text == nil  or  text == ""  then  return totalWidth;  end
		
		-- Loop through each character
		for character  in  string.gmatch(text, ".")	do
			totalWidth = totalWidth + self:getCharWidth (character, isMonospace, scale) + self.kerning*scale
		end
		
		-- Remove last instance of kearning
		totalWidth = totalWidth - self.kerning
		
		-- Return
		return totalWidth
	end
	
	
		
	function Font:getCharWidth (character, isMonospace, scale)
		if  scale == nil  then  scale = 1;  end;
	
		local w = self.spacing[character]  or  self.charWidth
		if  isMonospace == true  then  w = self.charWidth;  end;		
		return  w*self.scaleX*scale
	end
	
	function Font:getHeight (scale)
		if  scale == nil  then  scale = 1;  end;
		return self.charHeight*self.scaleY*scale
	end
	
	
	function Font:getStringWrapPoint (text, width, isMonospace, scale)
		if  scale == nil  then  scale = 1;  end;
		
		local totalWidth = 0		
		local currentPos = 0
		local currentChar = ""
		local prevChar = ""
		
		-- Edge cases
		if  text == nil  or  text == ""  or  width == math.huge  then  return nil, nil, nil;  end
		if  self:getStringWidth (text, isMonospace, scale) < width  then  return nil, nil, nil;  end
		
		-- Loop through each character
		for character  in  string.gmatch(text, ".")	do
			prevChar = currentChar
			currentChar = character
			totalWidth = totalWidth + self:getCharWidth (character, isMonospace, scale) + self.kerning*scale
			currentPos = currentPos + 1
			if  math.max(0, totalWidth-self.kerning) > width  then
				break;
			end
		end

		
		-- Return the index
		--windowDebug ("WRAP POINT:\n\ntext = "..text.."\ncurrentPos = "..tostring(currentChar))
		return currentPos, currentChar, prevChar
	end
	
	
	function Font:drawCharImage (character, props) --x,y, w,h, italic,bold, opacity,color, z)
		
		-- Load properties
		local color = props.color    or  0xFFFFFFFF
		local priority = props.z     or  props.priority  or  3.495
		local alpha = props.opacity  or  props.alpha     or  1.00
		local italic = props.italic
		local bold = props.bold
		local icon = props.icon
		local scaleMult = props.scale or 1
		local scaleMultX = props.scaleX or scaleMult or 1
		local scaleMultY = props.scaleY or scaleMult or 1
		
		-- Derived size/position vars
		local index = string.byte(character,1)-33
		local x = props.x
		local y = props.y
		local w = self.charWidth
		local h = self.charHeight
		local sourceX = (index%16) * w
		local sourceY = math.floor(index/16) * h

		local skewX = math.max(1, 0.2*w)
		if  italic == false  then
			skewX = 0
		end
		local scaleX = 1.4
		local scaleY = 1.2
		
		if  bold == false  then
			scaleX = 1
			scaleY = 1
		end
		
		scaleX = scaleX * self.scaleX * scaleMultX
		scaleY = scaleY * self.scaleY * scaleMultY

		-- Update cached color if necessary
		if  drawCall_currColorHex ~= color  then
			drawCall_currColorHex = color
			drawCall_currColor = getCachedTableColor(color)
		end
		
		-- Draw character based on font type
		if  self.fontType == textblox.FONTTYPE_DEFAULT  then		
			Text.printWP(character, self.fontIndex, x, y, priority)
		elseif  self.fontType == textblox.FONTTYPE_SPRITE  then	
			
			-- Draw via graphx2
			if  graphX2Active  then
				
				-- Draw icons as their own images due to unique textures
				if  icon ~= nil  then
					graphX2.image {img=icon, x=x+0.5*w,y=y+0.5*h, z=priority, scale=self.scale*scaleMult, 
					               skewX=skewX, scaleX=scaleX, scaleY=scaleY, color=color}
				
				-- Queue calls of the same font
				else
				
				
					-- Determine the points and UVs
					local u1,v1 = precalcU[character],precalcV[character]
					if(u1 == nil or v1 == nil) then
						return;
					end
					
					local x1,y1,x2,y2 = x,y,x+(w*scaleMultX),y+(h*scaleMultY)
					local u2,v2 = u1+(1/16),v1+(1/8)
					
					local pIndex = #drawCall_points
					local uIndex = #drawCall_uvs
					
					drawCall_points[pIndex+1], drawCall_points[pIndex+2]  = x1,y1
					drawCall_points[pIndex+3], drawCall_points[pIndex+4]  = x2,y1
					drawCall_points[pIndex+5], drawCall_points[pIndex+6]  = x1,y2
					drawCall_points[pIndex+7], drawCall_points[pIndex+8]  = x1,y2
					drawCall_points[pIndex+9], drawCall_points[pIndex+10] = x2,y2
					drawCall_points[pIndex+11],drawCall_points[pIndex+12] = x2,y1

					drawCall_uvs[pIndex+1], drawCall_uvs[pIndex+2]  = u1,v1
					drawCall_uvs[pIndex+3], drawCall_uvs[pIndex+4]  = u2,v1
					drawCall_uvs[pIndex+5], drawCall_uvs[pIndex+6]  = u1,v2
					drawCall_uvs[pIndex+7], drawCall_uvs[pIndex+8]  = u1,v2
					drawCall_uvs[pIndex+9], drawCall_uvs[pIndex+10] = u2,v2
					drawCall_uvs[pIndex+11],drawCall_uvs[pIndex+12] = u2,v1
					
					--local d_points = {x1,y1, x2,y1, x1,y2, x1,y2, x2,y2, x2,y1} --coordsToPoints (x1,y1,x2,y2)
					--local d_uvs = {u1,v1, u2,v1, u1,v2, u1,v2, u2,v2, u2,v1} --coordsToPoints (u1,v1,u2,v2)
					
					
					
					--local d_points, d_uvs, d_vcols = graphX2.image {img=self.imageRef, x=x+0.5*w,y=y+0.5*h, z=priority, rows=8, columns=16, scale=self.scale, row=sourceY/h+1, column=sourceX/w+1, 
					--											    skewX=skewX, scaleX=scaleX, scaleY=scaleY, vcols={color}, getTables=true}
					
					-- Copy them to the tables
					--[[
					for  i=1,12  do
						table.insert (drawCall_points, d_points[i])
						table.insert (drawCall_uvs, d_uvs[i])						
					end
					--]]
					
					-- Generate the vertex colors if multicolored
					if  drawCall_multiColored  then
						local cIndex = #drawCall_colors

						-- default to solid white (hacky fix)
						if  drawCall_currColor == nil  then  drawCall_currColor = {1,1,1,1};  end;

						for  i=1,6  do
							drawCall_colors[cIndex+4*(i-1)+1] = drawCall_currColor[1]
							drawCall_colors[cIndex+4*(i-1)+2] = drawCall_currColor[2]
							drawCall_colors[cIndex+4*(i-1)+3] = drawCall_currColor[3]
							drawCall_colors[cIndex+4*(i-1)+4] = drawCall_currColor[4]
						end
					end
					--]]
				end
			
			-- Draw via graphx
			elseif  graphXActive  then
				Graphics.drawImageWP (self.imageRef, x, y, sourceX, sourceY, w, h, alpha, priority)
			end
		end		
	end
end







--***************************************************************************************************
--                                                                                                  *
--              DEFAULT FONTS AND RESOURCES												    		*
--                                                                                                  *
--***************************************************************************************************

--[[
PRESET FONT CREDITS:
1: ATASCII (I think), formatted for textblox by rockythechao
2: font 1 with a drop shadow
3: font 1 with an outline
4: Tweaked version of a font I forgot
5: Original font by rockythechao
6: I _think_ a tweaked version of this font: http://gasara.deviantart.com/art/go-ahead-Pixel-Font-370026971 
7: SMB1/2 font, ripped/edited by BMATSANTOS, formatted for textblox by rockythechao
8: SMB3 font, ripped/edited by BMATSANTOS, formatted for textblox by rockythechao
9: SMW font, ripped/edited by BMATSANTOS, formatted for textblox by rockythechao
10: Pokemon GBA font (Emerald smaller variant), formatted for textblox by Enjl
--]]



function textblox.defineDefaultFont (filename, props)
	local imgName = textblox.getPath (filename)
	local imgRef = Graphics.loadImage (imgName)
	props.image = imgRef
	local fontRef = textblox.Font (textblox.FONTTYPE_SPRITE, props)
	return fontRef
end

do 
	textblox.FONT_DEFAULT = textblox.Font (textblox.FONTTYPE_DEFAULT, 4)  

	--[[
	textblox.IMGNAME_DEFAULTSPRITEFONT 		= textblox.getPath ("font_default.png")
	textblox.IMGNAME_DEFAULTSPRITEFONTX2 	= textblox.getPath ("font_default_x2.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT2 	= textblox.getPath ("font_default2.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT2X2 	= textblox.getPath ("font_default2_x2.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT3 	= textblox.getPath ("font_default3.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT3X2 	= textblox.getPath ("font_default3_x2.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT4 	= textblox.getPath ("font_default4.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT4X2 	= textblox.getPath ("font_default4_x2.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT5 	= textblox.getPath ("font_default5.png")
	textblox.IMGNAME_DEFAULTSPRITEFONT5X2 	= textblox.getPath ("font_default5_x2.png")
	--]]

	textblox.IMGNAME_BUBBLE_FILL 			= textblox.getPath ("bubbleFill.png")
	textblox.IMGNAME_BUBBLE_TAIL			= textblox.getPath ("bubbleTail.png")
	textblox.IMGNAME_BUBBLE_BORDER_U 		= textblox.getPath ("bubbleBorderU.png")
	textblox.IMGNAME_BUBBLE_BORDER_D 		= textblox.getPath ("bubbleBorderD.png")
	textblox.IMGNAME_BUBBLE_BORDER_L 		= textblox.getPath ("bubbleBorderL.png")
	textblox.IMGNAME_BUBBLE_BORDER_R 		= textblox.getPath ("bubbleBorderR.png")
	textblox.IMGNAME_BUBBLE_BORDER_UL 		= textblox.getPath ("bubbleBorderUL.png")
	textblox.IMGNAME_BUBBLE_BORDER_UR 		= textblox.getPath ("bubbleBorderUR.png")
	textblox.IMGNAME_BUBBLE_BORDER_DL 		= textblox.getPath ("bubbleBorderDL.png")
	textblox.IMGNAME_BUBBLE_BORDER_DR 		= textblox.getPath ("bubbleBorderDR.png")

	textblox.IMGNAME_NEXTICON 				= textblox.getPath ("nextIcon.png")
		
	textblox.IMGREF_BUBBLE_TAIL				= Graphics.loadImage (textblox.IMGNAME_BUBBLE_TAIL)
	textblox.IMGREF_BUBBLE_FILL		 		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_FILL)
	textblox.IMGREF_BUBBLE_BORDER_U  		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_U)
	textblox.IMGREF_BUBBLE_BORDER_D 		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_D)
	textblox.IMGREF_BUBBLE_BORDER_L 		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_L)
	textblox.IMGREF_BUBBLE_BORDER_R		 	= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_R)
	textblox.IMGREF_BUBBLE_BORDER_UL 		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_UL)
	textblox.IMGREF_BUBBLE_BORDER_UR	 	= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_UR)
	textblox.IMGREF_BUBBLE_BORDER_DL 		= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_DL)
	textblox.IMGREF_BUBBLE_BORDER_DR	 	= Graphics.loadImage (textblox.IMGNAME_BUBBLE_BORDER_DR)

	textblox.IMGREF_NEXTICON 				= Graphics.loadImage (textblox.IMGNAME_NEXTICON)
	
	
	-- Default sprite fonts
	textblox.defaultSpritefont = {}
	
	-- Originals
	for i= 1,6  do
		textblox.defaultSpritefont[i] = {}
		textblox.defaultSpritefont[i][1] = textblox.defineDefaultFont ("font\\"..tostring(i)..".png",   {ini = "font\\"..tostring(i)..".ini"})
		textblox.defaultSpritefont[i][2] = textblox.defineDefaultFont ("font\\"..tostring(i)..".png",   {ini = "font\\"..tostring(i).."x2.ini"})
		
		textblox["FONT_SPRITEDEFAULT"..tostring(i)] = textblox.defaultSpritefont[i][1]
		textblox["FONT_SPRITEDEFAULT"..tostring(i).."X2"] = textblox.defaultSpritefont[i][2]
	end
	
	-- SMB 1-3 titles
	for i= 7,8  do
		textblox.defaultSpritefont[i] = {}
		textblox.defaultSpritefont[i][1] = textblox.defineDefaultFont ("font\\"..tostring(i)..".png",   {ini = "font\\"..tostring(i)..".ini"})
		textblox.defaultSpritefont[i][2] = textblox.defineDefaultFont ("font\\"..tostring(i).."x2.png", {ini = "font\\"..tostring(i)..".ini"})
		textblox.defaultSpritefont[i][3] = textblox.defineDefaultFont ("font\\"..tostring(i).."x3.png", {ini = "font\\"..tostring(i)..".ini"})
	end
	
	-- SMW title
	textblox.defaultSpritefont[9] = {}
	textblox.defaultSpritefont[9][1] = textblox.defineDefaultFont ("font\\9.png",   {ini = "font\\9.ini"})
	textblox.defaultSpritefont[9][2] = textblox.defineDefaultFont ("font\\9x2.png", {ini = "font\\9.ini"})
	
	-- Pokermans
	textblox.defaultSpritefont[10] = {}
	textblox.defaultSpritefont[10][1] = textblox.defineDefaultFont ("font\\10.png", {ini = "font\\10.ini"})
	
	-- Courier New
	textblox.defaultSpritefont[12] = {}
	textblox.defaultSpritefont[12][1] = textblox.defineDefaultFont ("font\\12.png", {ini = "font\\12.ini"})
	textblox.FONT_SPRITEDEFAULT12 = textblox.defaultSpritefont[12][1]
	
	
	textblox.FONT_SPRITEDEFAULT     = textblox.FONT_SPRITEDEFAULT1
	textblox.FONT_SPRITEDEFAULTX2   = textblox.FONT_SPRITEDEFAULT1X2
end


	


--***************************************************************************************************
--                                                                                                  *
--              PRINT FUNCTIONS																	    *
--                                                                                                  *
--***************************************************************************************************

do
	function textblox.registerIcon (key, img)
		if  key == nil  or  img == nil  then
			error ("ICON NOT REGISTERED CORRECTLY.  Please provide a valid key string and LuaImageResource.")
		end
		textblox.icons[key] = img
	end
	

	function textblox.replaceLineBreaks (text)
		local newtext = string.gsub(text, "\\n", "<br>")
		newtext = string.gsub(newtext, "\n", "<br>")
		return newtext
	end
	
	function textblox.debugLineBreaks (text)
		local newtext = string.gsub(text, "<br>", "<br>\n")
		return newtext
	end
	
	function textblox.plaintext (text)
		local newtext = string.gsub(text, "<br[^<>]*>", " ")
		newtext = string.gsub(newtext, "<+[^<>]+>*", "")
		--windowDebug (text)
		--windowDebug (newtext)
		return newtext
	end
	
	function textblox.getStringWidth (text, font, monospace, scale)
		return font:getStringWidth (text, monospace, scale)
		
		--local strLen = text:len() 
		--return  (strLen * font.charWidth) + (math.max(0, strLen-1) * font.kerning)
	end
	
	
	function textblox.print (text, xPos,yPos, fontObj, t_halign, t_valign, w, alpha)
		return textblox.printExt (text, {x=xPos, y=yPos, font=fontObj, halign=t_halign, valign=t_valign, width, opacity=alpha})
	end
	

	function textblox.printExt (text, properties)
		
		-- Setup		
		local x = properties.x or 400
		local y = properties.y or 300
		local z = properties.z or properties.priority or 0
		
		local bind = properties.bind or textblox.BIND_SCREEN
		
		if  bind == textblox.BIND_LEVEL  then
			--x,y = worldToScreen(x,y)
		end
		
		local t_halign = properties.halign or textblox.ALIGN_LEFT
		local t_valign = properties.valign or textblox.ALIGN_TOP
		local alpha = properties.opacity or properties.alpha or 1.00
		
		local fullScale = properties.scale or 1
		local fullScaleX = properties.scaleX or fullScale or 1
		local fullScaleY = properties.scaleY or fullScale or 1
		
		local font = properties.font or textblox.FONT_DEFAULT
		local width = properties.width or math.huge
		local prewrapped = properties.prewrapped
		
		local monospace = properties.monospace
		if  monospace == nil  then  monospace = false;  end;
		
		local ignoreTags = properties.ignoreTags
		if  ignoreTags == nil  then
			ignoreTags = {}
		end
		local ignoreTagsCache = {}
		
		
		local lineBreaks = 0
		local charsOnLine = 0
		local totalShownChars = 0
		local currentLineWidth = 0
		
			
		local totalWidth = 1
		local totalHeight = 1
		
		
		local startOfLine = 1
		local fullLineWidth = 0
		local charEndWidth = 0
		local markupCount = 0
		local i = 1
				
		local topmostY = 10000
		local leftmostX = 10000
		
		
		-- Effects
		local iconImg = nil
		local iconMode = false
		local italicMode = false
		local boldMode = false
		local shakeMode = false
		local garbageMode = false
		local shakeStrength = 1
		local waveMode = false
		local waveStrength = 1
		local startColor = properties.color  or  0xFFFFFFFF
		local currentColor = startColor
		local rainbowMode = false

		
		-- Determine line widths
		--local averageLineWidth = font:getStringWidth ()		
		local mostCharsLine = 0
		local widestLineWidth = 0
		
		
		-- Overflow fix
		local heightEst = properties.heightEst
		
		--Format for wrapping if limited to a given width
		if  (width ~= math.huge  and  prewrapped ~= true)  then
			text = textblox.formatTextForWrapping (text, font, width, false, fullScaleX)
		end
		
		-- Start the polygon if necessary
		if  font.fontType == textblox.FONTTYPE_SPRITE  and  alpha > 0  then
			drawCall_points = {}
			drawCall_uvs = {}
			drawCall_colors = nil
			drawCall_currColorHex = color
			drawCall_startColor = getCachedTableColor(currentColor)
			drawCall_currColor = drawCall_startColor
			drawCall_multiColored = false
		end
		
		-- Positioning loop
		local lineWidths = {}
		local totalLineBreaks = 0
					
		for textChunk in string.gmatch(text, "<*[^<>]+>*")	do		
			local bm_start = benchmark_start()
			local processPlaintext  = false
		
			-- Is a command
			if  string.find(textChunk, "<.*>") ~= nil  then
			
				local commandStr, amountStr = string.match (textChunk, "([^<>%s]+) ([^<>%s]+)")
				if  commandStr == nil  then
					commandStr = string.match (textChunk, "[^<>%s]+")
				end


				-- Check if the command string is one of the ignored tags
				if  ignoreTagsCache[commandStr] == nil  then
					ignoreTagsCache[commandStr] = false
					for _,v in pairs (ignoreTags) do
						if v == commandStr then
							ignoreTagsCache[commandStr] = true
							break;
						end
					end
				end
				
				-- If the command string is not one of the ignored tags
				if  ignoreTagsCache[commandStr] == false  then
				
					-- Line break
					if  commandStr == "br"  then
						local numBreaks = 1
						if  amountStr ~= nil  then
							numBreaks = tonumber (amountStr)
						end
						
						for it=1, numBreaks  do
							lineWidths [lineBreaks] = math.max(0, currentLineWidth-font.kerning) --charsOnLine*font.charWidth + math.max(0, charsOnLine-1)*font.kerning
							lineBreaks = lineBreaks + 1
							totalLineBreaks = totalLineBreaks + 1
							charsOnLine = 0
							currentLineWidth = 0
						end
					end
					
					if  commandStr == "garbage"  or  commandStr == "binary"  then
						local numchars = tonumber(amountStr)  or  1
						textChunk = string.rep(" ", numchars)
						garbageMode = true
						processPlaintext = true
					end
					
					if  commandStr == "img"  then
						textChunk = " "
						iconMode = true
						processPlaintext = true
					end
					
					if  commandStr == "gt"  then
						textChunk = ">"
						processPlaintext = true
					end		
					
					if  commandStr == "lt"  then
						textChunk = "<"
						processPlaintext = true

					end
					
					if  commandStr == "butt"  then
						textChunk = "rockythechao"
						processPlaintext = true
					end
					
					if  commandStr == "color"  then
						drawCall_multiColored = true
						if  drawCall_colors == nil  then
							drawCall_colors = {}
						end
					end
				end
				
			-- Is plaintext
			else
				processPlaintext = true
			end
				

			-- PROCESS PLAINTEXT
			if  processPlaintext == true  then
				string.gsub (textChunk, ".", function(c)
					
					-- Get widest line
					if  mostCharsLine < charsOnLine then
						mostCharsLine = charsOnLine
					end
					
					-- Add to the current line width
					if  iconMode  or  garbageMode  then
						currentLineWidth = currentLineWidth + font.charWidth + font.kerning
						iconMode = false
					else
						currentLineWidth = currentLineWidth + font:getCharWidth(c,monospace) + font.kerning
					end
					
					if  widestLineWidth < math.max(0, currentLineWidth-font.kerning)  then
						widestLineWidth = math.max(0, currentLineWidth-font.kerning)
					end
					
					return c
				end)
				garbageMode = false
			end
			
			benchmark_end (bm_start, 2, 3)
			
		end
		lineWidths[lineBreaks] = math.max(0, currentLineWidth-font.kerning)--(charsOnLine)*font.charWidth + math.max(0, charsOnLine-1)*font.kerning

		
		-- fix spacing issue on single-line prints
		--if  totalLineBreaks == 0  then
			mostCharsLine = mostCharsLine + 1
			--lineWidths[0] = lineWidths[0] + font.charWidth + font.kerning
		--end
		
		
		-- Display loop
		lineBreaks = 0
		charsOnLine = 0
		currentLineWidth = 0
		
		for textChunk in string.gmatch(text, "<*[^<>]+>*")	do
			local bm_start = benchmark_start()
			
			
			-- Is a command
			local processPlaintext = false
			
			if  string.find(textChunk, "<.*>") ~= nil  then
				local commandStr, amountStr = string.match (textChunk, "([^<>%s]+) ([^<>%s]+)")
				if  commandStr == nil  then
					commandStr = string.match (textChunk, "[^<>%s]+")
				end
				
				
				-- If the command string is not one of the ignored tags
				if  ignoreTagsCache[commandStr] == false  then
				
					--[[
					if  commandStr ~= nil  then
						if  amountStr ~= nil then
							Text.windowDebug (commandStr..", "..tostring(amountStr))
						else
							Text.windowDebug (commandStr)
						end
					end
					]]
					
					-- Line break
					if  commandStr == "br"  then
						local numBreaks = 1
						if  amountStr ~= nil  then
							numBreaks = tonumber (amountStr)
						end
						
						for it=1, numBreaks  do
							lineBreaks = lineBreaks + 1
							currentLineWidth = 0
							charsOnLine = 0
						end
					end

					
					-- Icon
					if	commandStr == "img"  then
						if  amountStr ~= nil  then
							iconImg = textblox.icon [amountStr]
						end
						textChunk = " "
						iconMode = true
						processPlaintext = true
					end
					
					
					-- Binary text
					if  commandStr == "binary"  then
						local numchars = tonumber(amountStr)  or  1
						textChunk = string.random(numchars, "01")
						garbageMode = true
						processPlaintext = true
					end
					
					-- Garbage text
					if  commandStr == "garbage"  then
						local numchars = tonumber(amountStr)  or  1
						textChunk = string.random(numchars, "%a%d%p")
						garbageMode = true
						processPlaintext = true
					end
					
					-- Greater than
					if  commandStr == "gt"  then
						textChunk = ">"
						processPlaintext = true
					end
					
					-- Less than
					if  commandStr == "lt"  then
						textChunk = "<"
						processPlaintext = true
					end
					
					-- BUTT
					if  commandStr == "butt"  then
						textChunk = "rockythechao"
						processPlaintext = true
					end
		


					-- Bold text
					if  commandStr == "b"  then
						boldMode = true
					end
					if  commandStr == "/b"  then
						boldMode = false
					end
		
					-- Italic text
					if  commandStr == "i"  then
						italicMode = true
					end
					if  commandStr == "/i"  then
						italicMode = false
					end
		
					-- Shake text
					if  commandStr == "tremble"  then
						shakeStrength = 1
						if  amountStr ~= nil  then
							shakeStrength = tonumber (amountStr)
						end
						
						if  shakeStrength > 0  then
							shakeMode = true
						else
							shakeMode = false
						end
					end
					if  commandStr == "/tremble"  then
						shakeMode = false
					end
					
					-- Wave text
					if  commandStr == "wave"  then
						waveStrength = 1
						if  amountStr ~= nil  then
							waveStrength = tonumber (amountStr)
						end
						
						if  waveStrength > 0  then
							waveMode = true
						else
							waveMode = false
						end
					end
					if  commandStr == "/wave"  then
						waveMode = false
					end
				
					-- Colored text
					if  commandStr == "color"  then
						rainbowMode = false
						
						if  amountStr == "default"  then
							currentColor = startColor
						
						elseif  amountStr == "white"  then
							currentColor = 0xFFFFFFFF
						elseif  amountStr == "gray"  then
							currentColor = 0x888888FF
						elseif  amountStr == "ltgray"  then
							currentColor = 0xCCCCCCFF
						elseif  amountStr == "dkgray"  then
							currentColor = 0x333333FF
						elseif  amountStr == "black"  then
							currentColor = 0x000000FF
						elseif  amountStr == "red"  then
							currentColor = 0xDD0000FF
						elseif  amountStr == "magenta"  then
							currentColor = 0xDD00DDFF
						elseif  amountStr == "pink"  then
							currentColor = 0xFFAAAAFF
						elseif  amountStr == "purple"  then
							currentColor = 0xAA00DDFF
						elseif  amountStr == "blue"  then
							currentColor = 0x0000DDFF
						elseif  amountStr == "cyan"  then
							currentColor = 0x00DDDDFF
						elseif  amountStr == "green"  then
							currentColor = 0x00DD00FF
						elseif  amountStr == "yellow"  then
							currentColor = 0xDDDD00FF
						elseif  amountStr == "orange"  then
							currentColor = 0xFF8000FF
						elseif  amountStr == "brown"  then
							currentColor = 0xBC7642FF
						elseif  amountStr == "beige"  then
							currentColor = 0xF5F5DCFF
							
						elseif  amountStr == "rainbow"  then
							rainbowMode = true
							
						else
							currentColor = tonumber(amountStr)
						end
					end
				end
				
			-- Is plaintext
			else
				processPlaintext = true
			end
			
			
			-- Process the plaintext
			if  processPlaintext == true  then
				string.gsub (textChunk, ".", function(c)
					
					-- Increment position counters
					charsOnLine = charsOnLine + 1
					totalShownChars = totalShownChars + 1

					
					if  math.max(0, currentLineWidth-font.kerning) > widestLineWidth + font.kerning  then
						lineBreaks = lineBreaks + 1
						charsOnLine = 0
						currentLineWidth = 0
					end
					
					-- Get widest line
					if  mostCharsLine < charsOnLine then
						mostCharsLine = charsOnLine
					end

					-- Ignore spaces
					local widthToAdd = font:getCharWidth(c, monospace)
					if  garbageMode  then
						widthToAdd = font:getCharWidth(c, true)
					end
					if  c ~= " "  or  iconMode  or  garbageMode  then

						-- Determine position
						--currentLineWidth = math.max(0, charsOnLine-1) * font.charWidth    +   math.max(0, charsOnLine-2) * font.kerning
						local xPos = x + currentLineWidth * fullScaleX
						local yPos = y + ((font:getHeight() + font.leading)*(lineBreaks) - font.leading) * fullScaleY -- (0.5*font.charHeight)
						
						
						-- if different alignments, change those values
						if	t_halign == textblox.HALIGN_RIGHT  then
							xPos = x - lineWidths[lineBreaks]*fullScaleX + currentLineWidth*fullScaleX

						elseif	t_halign == textblox.HALIGN_MID  then
							xPos = x - 0.5*(lineWidths[lineBreaks])*fullScaleX + currentLineWidth*fullScaleX
						end


						if	t_valign == textblox.VALIGN_BOTTOM  then
							yPos = y + ((lineBreaks - totalLineBreaks - 1)*font:getHeight ()) * fullScaleY

						elseif t_valign == textblox.VALIGN_MID  then
							yPos = y + ((lineBreaks*font:getHeight()) - ((totalLineBreaks+1) * font:getHeight()*0.5)) * fullScaleY
						end

						
						-- Process visual effects
						local xAffected = xPos
						local yAffected = yPos
						local wAffected = 1
						local hAffected = 1
											
						if  waveMode == true  then
							yAffected = yAffected + math.cos(totalShownChars*0.5 + textblox.waveModeCycle)*waveStrength
						end
						
						if  rainbowMode == true  then
							currentColor = HSLToRGBAHex ((20*textblox.waveModeCycle + 30*totalShownChars)%360, 0.5, 0.5, 1)
						end
						
						if  shakeMode == true  then
							local shakeX = math.max(0.5, font.charWidth*font.scaleX * 0.125)*shakeStrength * fullScaleX
							local shakeY = math.max(0.5, font:getHeight() * 0.125)*shakeStrength * fullScaleY
							
							xAffected = xAffected + rng.randomInt(-1*shakeX, shakeX)
							yAffected = yAffected + rng.randomInt(-1*shakeY, shakeY)
						end
						
						-- Finally, draw the image
						font:drawCharImage (c, {x=xAffected, y=yAffected, w=wAffected, h=hAffected, italic=italicMode, bold=boldMode, opacity=alpha, color=currentColor, z=z, icon=iconImg, scale=fullScale, scaleX=fullScaleX, scaleY=fullScaleY})
						
						if  iconMode  then
							widthToAdd = font.charWidth
							iconMode = false
							iconImg = nil
						end
					end
					
					-- Add to the current line width
					currentLineWidth = currentLineWidth + widthToAdd + font.kerning
					
					return c
				end)
				garbageMode = false
			end
			benchmark_end (bm_start, 4, 5)
			--windowDebug (textChunk)
		end
		
		-- Draw the combined polygon
		if  alpha > 0  and  font.fontType == textblox.FONTTYPE_SPRITE  then
			Graphics.glDraw {vertexCoords=drawCall_points, sceneCoords=(bind==textblox.BIND_LEVEL), textureCoords=drawCall_uvs, vertexColors=drawCall_colors, texture=font.imageRef, priority=z, color=drawCall_startColor}
			
			--graphX2.poly   {points=drawCall_points, uvs=drawCall_uvs, z=z, tex=font.imageRef, vcols=drawCall_colors, color=0xFFFFFF00 + 0x000000FF*alpha}
		end
		
		-- Calculate the returned width and height
		totalWidth = widestLineWidth --mostCharsLine * (font.kerning + font.charWidth) - font.kerning
		totalHeight = (font.charHeight*font.scaleY + font.leading) * (totalLineBreaks) - font.leading
		
		return totalWidth*fullScaleX, totalHeight*fullScaleY, lineBreaks, lineWidths
	end


	-- EXPERIMENTAL/INCOMPLETE FUNCTIONS!!!
	
	--[[Lists/grids of strings
	function textblox.printList (items, itemProperties, listProperties)
		-- Get copies of properties
		local listProps = deepCopyWithCheck (listProps)
		local itemProps = deepCopyWithCheck (itemProperties)
		
		listProps.direction = listProps.direction  or  textblox.ALIGN_TOP
		
		
		-- Draw them
		local i = 1
		local x = itemProps.x
		local y = 
		
		while  i <= #items  do
			
		end
	end
	--]]
	
	function textblox.printTable (tableRef, properties)
		local tableStr = tablePrint.tostring (tableRef)
		
		if tableStr ~= nil  then
			tableStr = textblox.replaceLineBreaks (tableStr)
			textblox.printExt (tableStr, properties)
		end
	end
end


	


--***************************************************************************************************
--                                                                                                  *
--              TEXT BLOCK CLASS																    *
--                                                                                                  *
--***************************************************************************************************


local TextBlock = {}
local TextBlockMeta = {}
TextBlock.__index = TextBlock

do
	textblox.defaultNewProps = {

		-- Box appearance
		boxType = textblox.BOXTYPE_MENU,
		boxColor = 0x999999FF,
		boxTex = textblox.IMGREF_BUBBLE_FILL,
		borderTable = {},
		font = textblox.FONT_DEFAULT,
		xMargin = 0,
		yMargin = 0,
		hasTail = false,
		tailTex = textblox.IMGREF_BUBBLE_TAIL,
		tailScale = 2,
		
		-- Scaling
		scaleMode = textblox.SCALE_FIXED,
		width = 200,
		height = 200,
		autosizeRatio = 4/3,
		
		-- Positioning
		z = 4,
		bind = textblox.BIND_SCREEN,
		boxAnchorX = textblox.ALIGN_LEFT,
		boxAnchorY = textblox.ALIGN_TOP,
		
		-- Object tracking
		trackTarget = "__NIL__",
		trackXAdd = 0,
		trackYAdd = 0,
		trackAutoOffset = true,
		offscreenDist = 64,
		stayOnscreen = true,
		
		autoTail = "__NIL__",
		tailSide = "__NIL__",
		tailX = "__NIL__",
		tailY = "__NIL__",
		
		-- Text properties
		textAnchorX = textblox.ALIGN_LEFT,
		textAnchorY = textblox.ALIGN_TOP,
		textColor = 0xFFFFFFFF,
		textScale = 1,
		textMono = "__NIL__",
		textOffX = 0,
		textOffY = 0,		
		textAlpha = 1,
		mappedWordFilters = {},
		replaceWords = {},
		madlibWords = {},		
		
		-- Next icon
		showNextIcon = true,
		nextIconTex = textblox.IMGREF_NEXTICON,
		nextIconHalign = textblox.ALIGN_RIGHT,
		nextIconValign = textblox.ALIGN_BOTTOM,
		nextIconX = 4,
		nextIconY = 4,
		nextIconScale = 2,
		
		-- Timing
		autoClose = false,
		instant = false,
		speed = 0.5,
		autoTime = false,
		endMarkDelay = 8,
		midMarkDelay = 4,
		finishDelay = 10,
		
		-- Interaction
		inputClose = false,
		inputProgress = false,
		pauseGame = false,
		
		-- Audio
		typeSounds = {},
		startSound = "",
		finishSound = "",
		closeSound = "",
		
		-- Visible
		visible = true
	}
end

do		
	function TextBlock.create(x,y, textStr, properties, template)		

		local thisTextBlock = {}							-- Object
		setmetatable (thisTextBlock, TextBlock)				-- make TextBlock handle lookup

	
		--------- Properties -----------------------------------------------------------------		
		
		if  template == nil  then  template = {};  end;
	
		local boxType = defaultChain {3, properties.boxType, template.boxType, textblox.BOXTYPE_MENU}		
		local boxTypeProps = {}
		
		
		-- Default boxtype border table
		boxTypeProps.borderTable =  {
		                             ulImg   = textblox.IMGREF_BUBBLE_BORDER_UL,
		                             uImg    = textblox.IMGREF_BUBBLE_BORDER_U,
		                             urImg   = textblox.IMGREF_BUBBLE_BORDER_UR,
		                             rImg    = textblox.IMGREF_BUBBLE_BORDER_R,
		                             drImg   = textblox.IMGREF_BUBBLE_BORDER_DR,
		                             dImg    = textblox.IMGREF_BUBBLE_BORDER_D,
		                             dlImg   = textblox.IMGREF_BUBBLE_BORDER_DL,
		                             lImg    = textblox.IMGREF_BUBBLE_BORDER_L,
		
		                             thick = 8,
		                             col = defaultChain {2, properties.boxColor, 0xFFFFFFFF}
		                            }
	
		-- Menu box
		if      boxType == textblox.BOXTYPE_MENU  then
			boxTypeProps.boxColor = 0x00AA00FF
			boxTypeProps.boxTex = textblox.IMGREF_BUBBLE_FILL
			boxTypeProps.textColor = 0xFFFFFFFF
			boxTypeProps.font = textblox.FONT_SPRITEDEFAULTX2
			
			if  graphXActive  then
				boxTypeProps.borderTable = graphX.getDefBorderTable ()
			end
			
			boxTypeProps.borderTable.thick = 8
			boxTypeProps.borderTable.col = 0xFFFFFFFF
		
		
		-- Word bubble
		elseif  boxType == textblox.BOXTYPE_WORDBUBBLE  then
			boxTypeProps.boxColor = 0xFFFFFFFF
			boxTypeProps.boxTex = textblox.IMGREF_BUBBLE_FILL
			boxTypeProps.textColor = 0x000000FF
			boxTypeProps.font = textblox.FONT_SPRITEDEFAULT4X2

			boxTypeProps.yMargin = 16
			boxTypeProps.hasTail = true
			boxTypeProps.tailTex = textblox.IMGREF_BUBBLE_TAIL
			boxTypeProps.borderTable.col = defaultChain {2, properties.boxColor, boxTypeProps.boxColor}
						
		-- Sign
		elseif  boxType == textblox.BOXTYPE_SIGN  then
			boxTypeProps.boxColor = 0xFFFFFFFF
			boxTypeProps.boxTex = textblox.IMGREF_BUBBLE_FILL
			boxTypeProps.textColor = 0x000000FF
			boxTypeProps.font = textblox.FONT_SPRITEDEFAULT5X2

			boxTypeProps.yMargin = 16
			boxTypeProps.hasTail = false
			
			boxTypeProps.borderTable.col = 0xc68c53FF
			
		-- No box
		elseif  boxType == textblox.BOXTYPE_NONE  then
			boxTypeProps.boxColor = 0x00000000
			boxTypeProps.hasTail = false
			boxTypeProps.borderTable =  {thick = 0}
		end

		
		-- Default values
		local defaultProps = textblox.defaultNewProps
		
		
		-- Load through default chain
		local sourceString = ""
		for  k,v in pairs (defaultProps)  do			
			
			if  v == "__NIL__"  then  v = nil;  end;
			local steps, newV
			newV, steps = defaultChain {4, properties[k], template[k], boxTypeProps[k], v}
			thisTextBlock [k] = newV
			
			-- Debug: source tracking for each property
			if  textblox.debug  then
				sourceString = sourceString .. k .. ": "
				
				if  typeof(newV) == "userdata"  then
					sourceString = sourceString .. " type = userdata; "
				else
					sourceString = sourceString .. " type = " .. tostring(newV) .. "; "
				end

				if  steps == 1  then  sourceString = sourceString .. " from properties\n";  end;
				if  steps == 2  then  sourceString = sourceString .. " from template\n";  end;
				if  steps == 3  then  sourceString = sourceString .. " from box type\n";  end;
				if  steps == 4  then  sourceString = sourceString .. " from absolute defaults\n";  end;
			end
		end
		
		-- Display source info
		if  textblox.debug  then
			windowDebug (sourceString)
		end
		
		thisTextBlock.x = x  or  400
		thisTextBlock.y = y  or  300
		
		
		-- Load the pages
		thisTextBlock.pages = {}
		if  type(textStr) == "table"  then
			thisTextBlock.pages = textStr
		
		-- Split the string into multiple if necessary
		elseif type(textStr) == "string"  then
			if  string.find (textStr, "<page>") ~= nil  then
				thisTextBlock.pages = splitStringByPattern (textStr.."<page>", "<page>")
			else
				thisTextBlock.pages[1] = textStr
			end
	
		-- Invalid type
		else
			error ("Invalid type for textStr (string or table of strings expected)")
		end		
		
		thisTextBlock.currentPage = 1
		thisTextBlock.latestPage = 1
		thisTextBlock.text = thisTextBlock.pages[1]
		
		--[[
		-- Sorting depth
		thisTextBlock.z = defaultChain {props.z, template.z, 4}
		
		
		-- Box appearance
		thisTextBlock.boxTex = defaultChain {props.boxTex, template.boxTex}
		thisTextBlock.borderTable = defaultChain {props.borderTable, template.borderTable}
		thisTextBlock.font = defaultChain {props.font, template.font, textblox.FONT_DEFAULT}
		thisTextBlock.xMargin = defaultChain {props.xMargin, template.xMargin, 4}
		thisTextBlock.yMargin = defaultChain {props.yMargin, template.yMargin, 4}
		thisTextBlock.hasTail = defaultChain {props.hasTail, template.hasTail, false}
		thisTextBlock.tailTex = defaultChain {props.tailTex, template.tailTex, textblox.IMGREF_BUBBLE_TAIL}
		thisTextBlock.tailScale = defaultChain {props.tailScale, template.tailScale, 2}

		
			
		-- Scaling
		thisTextBlock.scaleMode = props.scaleMode
		if  thisTextBlock.scaleMode == nil  then
			thisTextBlock.scaleMode = textblox.SCALE_FIXED
		end
		
		thisTextBlock.width = props.width or 200
		thisTextBlock.height = props.height or 200
		thisTextBlock.autosizeRatio = props.autosizeRatio or 4/3
		
		
		-- Positioning
		if  props.isSceneCoords == true  then
			thisTextBlock.bind = textblox.BIND_LEVEL
		end
		thisTextBlock.bind = thisTextBlock.bind  or  props.bind  or  textblox.BIND_SCREEN
		
		thisTextBlock.boxAnchorX = props.boxAnchorX or textblox.ALIGN_LEFT
		thisTextBlock.boxAnchorY = props.boxAnchorY or textblox.ALIGN_TOP

		
		-- Object tracking
		thisTextBlock.trackMouse = false
		thisTextBlock.trackTarget = props.trackTarget
		thisTextBlock.trackXAdd = props.trackXAdd  or  0
		thisTextBlock.trackYAdd = props.trackYAdd  or  0
		thisTextBlock.trackAutoOffset = defaultChain {props.trackAutoOffset, true}
		thisTextBlock.offscreenDist = props.offscreenDist  or  64
		
		thisTextBlock.stayOnscreen = defaultChain {props.stayOnscreen, false}
		
		thisTextBlock.autoTail = props.autoTail
		thisTextBlock.tailSide = props.tailSide
		thisTextBlock.tailX = props.tailX
		thisTextBlock.tailY = props.tailY
		
		
		-- Text properties
		thisTextBlock.textAnchorX = props.textAnchorX or textblox.ALIGN_LEFT
		thisTextBlock.textAnchorY = props.textAnchorY or textblox.ALIGN_TOP
		
		thisTextBlock.textOffX = props.textOffX or 0
		thisTextBlock.textOffY = props.textOffY or 0
		
		thisTextBlock.textAlpha = props.textAlpha or 1

		thisTextBlock.mappedFilters = props.mappedWordFilters or {}
		thisTextBlock.unmappedReplacements = props.replaceWords or {}
		thisTextBlock.madlibsWords = props.madlibWords or {}

		
		
		-- Timing
		thisTextBlock.autoClose = defaultChain {props.autoClose, false}		
		thisTextBlock.instant = defaultChain {props.instant, false}
		
		thisTextBlock.speed = props.speed or 0.5
		thisTextBlock.defaultSpeed = thisTextBlock.speed
		
		thisTextBlock.autoTime = defaultChain {props.autoTime, false}
		
		thisTextBlock.endMarkDelay = props.endMarkDelay or 8
		thisTextBlock.midMarkDelay = props.midMarkDelay or 4
		
		thisTextBlock.finishDelay = props.finishDelay or 10
		
		
		-- Interaction
		thisTextBlock.inputClose = defaultChain {props.inputClose, false}
		thisTextBlock.pauseGame = defaultChain {props.pauseGame, false}
	
		
		-- Audio
		thisTextBlock.typeSounds = props.typeSounds or {}
		thisTextBlock.startSound = props.startSound or ""
		thisTextBlock.finishSound = props.finishSound or ""
		thisTextBlock.closeSound = props.closeSound or ""
		--]]

		
		------------ Control vars ------------------------------------------------------
		thisTextBlock.pauseFrames = 0
		thisTextBlock.shakeFrames = 0

		thisTextBlock.idealWidth = 0
		thisTextBlock.autoWidth = 1
		thisTextBlock.autoHeight = 1
		thisTextBlock.autoWidthFull = 0
		thisTextBlock.autoHeightFull = 0
		thisTextBlock.autosizeDirty = true

		thisTextBlock.displayFixX = 0
		thisTextBlock.displayFixY = 0

		thisTextBlock.defaultSpeed = thisTextBlock.speed
		
		thisTextBlock.updatingChars = true
		thisTextBlock.finished = false
		thisTextBlock.finishSoundPlayed = false
		thisTextBlock.deleteMe = false
		thisTextBlock.index = -1
		
		if  (thisTextBlock.autoTime == true)  then
			thisTextBlock:insertTiming ()
		end
		
		-- Text processing
		thisTextBlock.textDirty = true
		thisTextBlock.wrappedTextWidth = 1
		thisTextBlock.filteredText = ""
		thisTextBlock.wrappedText = ""
		thisTextBlock.wrappedTextWithN = ""
		thisTextBlock.length = string.len(textStr)
		
		thisTextBlock.lastCharCounted = nil
		thisTextBlock.charsShown = 0
		if (thisTextBlock.speed <= 0) then
			thisTextBlock.charsShown = thisTextBlock:getLength()
		end
		
		
		-- Audio		
		thisTextBlock.typeSoundChunks = {}
		if  #thisTextBlock.typeSounds > 0  then
			for  k,v in pairs (thisTextBlock.typeSounds)  do
				thisTextBlock.typeSoundChunks[k] = Audio.SfxOpen (textblox.getPath (v))
			end
		end
		--thisTextBlock.typeUsedChannel = 12

		
		-------- Create behaviors ------------------------------------------------------
		if  (thisTextBlock.startSound ~= "")  then
			Audio.playSFX (textblox.getPath (thisTextBlock.startSound))
		end
		
		if  (thisTextBlock.pauseGame == true)  then
			if  firstFrameYet == false  then
				queuedPause = true
			else
				Misc.pause ()
			end
		end

		
		-------- Index and return ------------------------------------------------------
		table.insert(textblox.textBlockRegister, thisTextBlock)
				
		return thisTextBlock
	end

	
	------ Metatable stuff --------------------------------------------------------------------------------------	
	--[[
	function TextBlock.__index(obj,key)
		if    (key == "exampleProperty") then return rawget(obj, "exampleProperty")
		elseif(key == "otherExample") then return rawget(obj, "otherExample")
		
		elseif(key == "_type"  or  key == "__type") then
			return "textblock";
		else
			return rawget (obj, key);
		end
		
	end

	function TextBlock.__newindex(obj,key,val)
		if    (key == "exampleProperty") then rawset(obj, "exampleProperty", val)
		elseif(key == "otherExample") then rawset(obj, "otherExample", val)
		
		elseif(key == "_type"  or  key == "__type") then
			error ("Cannot set the type of an object.", 2);
		else
			rawset(obj, key, value)
			--windowDebug("Field "..key.." cannot be changed, does not exist in the TextBlock data structure, or is simply nil (still working this stuff out)");
		end
	end
	--]]

	--[[
	function TextBlock.__tostring (obj)
		return "TextBlock: "..obj.text
	end
	--]]
	
	------ Constructor wrapper functions -----------------------------------------------------------------------
	
	function textblox.Block (x,y, textStr, properties)
		return TextBlock.create (x,y, textStr, properties)
	end
	function textblox.createBlock (x,y, textStr, properties)
		return TextBlock.create (x,y, textStr, properties)
	end
	
	
	------ Methods ---------------------------------------------------------------------------------------------	
	function TextBlock:convertCoords (x,y, coordType)
		-- If same bind types, no need to convert
		if  coordType == self.bind  then
			return x,y
		end
		
		
		-- Otherwise...
		local bounds = getScreenBounds ()
			
		-- Level to screen
		if  coordType == textblox.BIND_LEVEL  then
			return x-bounds.left, y-bounds.top
		end
		
		-- Screen to level
		if  coordType == textblox.BIND_SCREEN  then
			return x+bounds.left, y+bounds.top
		end		
	end
	
	
	function TextBlock:setBind (coordType)
		-- If same bind types, no need to convert
		if  coordType == self.bind  then
			return
		end
		
		
		-- Otherwise...
		local bounds = getScreenBounds ()
			
		-- Screen to level
		if  coordType == textblox.BIND_LEVEL  then
			x = x+bounds.left
			y = y+bounds.top
		end
		
		-- Level to screen
		if  coordType == textblox.BIND_SCREEN  then
			x = x-bounds.left
			y = y-bounds.top
		end
		
		-- Change
		self.bind = coordType
	end
	

	function TextBlock:getRect (margins)
		-- Default margins to false
		if margins == nil  then  margins = false;  end
		
		-- Get rectangle
		local myRect = newRECTd()
		
		myRect.left = self.x
		myRect.top = self.y
		
		-- Adjust based on anchors
		if  self.boxAnchorX == textblox.ALIGN_MID     then
			myRect.left = self.x - 0.5*self.autoWidthFull
		end
		if  self.boxAnchorX == textblox.ALIGN_LEFT    then
			myRect.left = self.x - self.autoWidthFull
		end

		if  self.boxAnchorY == textblox.ALIGN_MID     then
			myRect.top  = self.y - 0.5*self.autoHeightFull
		end
		if  self.boxAnchorY == textblox.ALIGN_TOP     then
			myRect.top  = self.y - self.autoHeightFull
		end
		
		myRect.right  = myRect.left + self.autoWidthFull 
		myRect.bottom = myRect.top + self.autoHeightFull
		
		
		-- Add margins
		if  margins  then
			myRect.left = myRect.left - self.xMargin
			myRect.right = myRect.right + self.xMargin
			myRect.top = myRect.top - self.yMargin
			myRect.bottom = myRect.bottom + self.yMargin
		end
		
		return myRect;
	end
		
	function TextBlock:getScreenRect (margins)
		local myRect = self:getRect (margins)
				
		if  self.bind == textblox.BIND_LEVEL  then
			myRect.left,myRect.top = worldToScreen (myRect.left,myRect.top)
			myRect.right,myRect.bottom = worldToScreen (myRect.right,myRect.bottom)
		end
		
		return myRect;
	end
	
	function TextBlock:getLevelRect (margins)
		local myRect = self:getRect (margins)
		local bounds = getScreenBounds ()
		
		if  self.bind == textblox.BIND_SCREEN  then
			myRect.left = bounds.left + myRect.left
			myRect.top = bounds.top + myRect.top
			myRect.right = bounds.left + myRect.right
			myRect.bottom = bounds.top + myRect.bottom
		end
		
		return myRect;
	end
	
	
	function TextBlock:updateIdealWidth (ratio)
		if  self.autosizeDirty  then
			
			-- gdi rocky you friggin moron why didn't you have this check here in the first place
			if  self.scaleMode == textblox.SCALE_FIXED  then
				self.idealWidth = self.width
			else
				
				-- Setup
				local fullTextWidth = self.font:getStringWidth (self.text, self.textMono, self.textScale)
				local minWidth = self.font:getStringWidth ("WWWWWWWWWWWWWWWWWW", self.textMono, self.textScale)
				--local singleLineHeight = self.font.charHeight
			
				-- If the string is longer than 20 characters
				if  (fullTextWidth) > minWidth  then
				
					local currentWidth = fullTextWidth
					local currentHeight = self.font.charHeight
					local prevWidth = 0
					local numDivs = 0
					
					-- Calculate rough average dimensions that're close to the ideal ratio
					while (currentWidth/currentHeight > ratio)  do
						numDivs = numDivs + 1
						prevWidth = currentWidth
						currentWidth = fullTextWidth/numDivs
						currentHeight = numDivs*(self.font.charHeight*self.font.scaleY + self.font.leading) - self.font.leading
						--windowDebug ("num divs: "..tostring(numDivs))
					end
					
					-- Cache the resulting width
					self.idealWidth = currentWidth
					if  numDivs > 0  then  self.idealWidth = prevWidth;  end			
					self.idealWidth = math.max (self.idealWidth, minWidth)
					
				else
					idealWidth = fullTextWidth			
				end
			end
			
			self.autosizeDirty = false
		end
	end
	
	function TextBlock:getCharsPerLine ()
		local numCharsPerLine = math.floor((self.width)/(self.font.charWidth + self.font.kerning))
		return numCharsPerLine
	end
	
	function TextBlock:updateFormattedText ()
		if  self.textDirty  then
			self.autosizeDirty = true
			self:updateIdealWidth (self.autosizeRatio)
			self.wrappedText = textblox.formatTextForWrapping (self.text, self.font, self.idealWidth, false, self.textMono, self.textScale)
			self.filteredText = textblox.plaintext (self.text)
			self.textDirty = false
		end
	end
	
	function TextBlock:getTextFiltered ()
		self:updateFormattedText ()
		return self.wrappedText
	end
	
	function TextBlock:getTextWrapped ()
		self:updateFormattedText ()		
		return self.wrappedText
	end
	
	
	function TextBlock:draw ()
		local bm_start = benchmark_start()
		--windowDebug ("TEST")
		
		-- Get width and height
		local textForWidth = self:getTextWrapped ()
				
		self.autoWidthFull, self.autoHeightFull = textblox.printExt (textForWidth, {x = 9999, y = 9999,
																					font = self.font,
																					scale = self.textScale,
																					halign = self.textAnchorX,
																					valign = self.textAnchorY,
																					opacity = 0.0})
															
		-- Get shake offset
		local shakeX = rng.randomInt (-12, 12) * (self.shakeFrames/8)
		local shakeY = rng.randomInt (-12, 12) * (self.shakeFrames/8)
		
		
		-- Get alignment and width based on scale mode
		local boxAlignX = self.boxAnchorX
		local boxAlignY = self.boxAnchorY
		local boxWidth = self.width
		local boxHeight = self.height 
		
		if  self.scaleMode == textblox.SCALE_AUTO  then
			boxWidth = self.autoWidthFull
			boxHeight = self.autoHeightFull 
		else
			self.autoWidthFull = self.width
			self.autoHeightFull = self.height
		end

		
		-- Set formatted text dirty if necessary
		if  self.wrappedTextWidth ~= self.autoWidthFull  then
			self.wrappedTextWidth = self.autoWidthFull
			self.textDirty = true;
		end
		
		-- Get box RECT  (use level coords to simplify tail positioning)
		local boxRect = self:getLevelRect ()
		local boxRectMargins = self:getLevelRect (true)
		local shakeRect = offsetRect (boxRect, shakeX, shakeY)
		local shakeRectMargins = offsetRect (boxRectMargins, shakeX, shakeY)

		-- Determine whether to show the icon
		local shouldShowIcon = (self:getFinished()  and  self.showNextIcon  and  (self.inputClose  or  self.currentPage < #self.pages))
		
		-- Determine tail position
		local tailAngle = 0
		local shouldShowTail = false
				
		if  self.hasTail  then
			shouldShowTail = true
			local bitX, bitY = 1,1
			
			if  self.trackTarget ~= nil  then
				local tailTrg = self.trackTarget
				
				if  tailTrg.x ~= nil  then
					local boundsTemp = getScreenBounds (camNumber)
					local tailTrgX = tailTrg.x + (tailTrg.width or 0)*0.5
					local tailTrgY = tailTrg.y + (tailTrg.height or 0)*0.5
					self.tailX = math.min (boxRectMargins.right, math.max(boxRectMargins.left, tailTrgX)) 
					self.tailY = math.min (boxRectMargins.bottom, math.max(boxRectMargins.top, tailTrgY)) 
					
					
					if  tailTrgX > boxRectMargins.right  then  bitX = 2;  end;
					if  tailTrgX < boxRectMargins.left  then  bitX = 0;  end;
					
					if  tailTrgY > boxRectMargins.bottom  then  bitY = 2;  end;
					if  tailTrgY < boxRectMargins.top  then  bitY = 0;  end;
				end
			end	
			
			-- Determine position based on graphic			
			if  bitX == 0  then  self.tailX = boxRectMargins.left;  end;
			if  bitX == 2  then  self.tailX = boxRectMargins.right;  end;
			if  bitY == 0  then  self.tailY = boxRectMargins.top;  end;
			if  bitY == 2  then  self.tailY = boxRectMargins.bottom;  end;
			
			if  bitX == 1  and  bitY == 1  then  shouldShowTail = false;  end;
			
			-- Determine angle
			local data = 10*bitX + bitY;
			
			-- Sides
				if data == 10  then		tailAngle = 180;	end;
				if data == 12  then		tailAngle = 0;		end;
				if data == 01  then		tailAngle = 90;		end;
				if data == 21  then		tailAngle = 270;	end;
			-- Corners
				if data == 22  then		tailAngle = 315;	end;
				if data == 02  then		tailAngle = 45;		end;
				if data == 20  then		tailAngle = 225;	end;
				if data == 00  then		tailAngle = 135;	end;
		end
		
		
		-- Draw box
		if  graphX2Active  then
			
			--if  self.boxTex == nil  then  windowDebug ("NO TEXTURE");  end;
			--if  metalunaActive  then  windowDebug (tostring(shakeRectMargins));  end;
			
			-- Box
			local displayFixRect = offsetRect(shakeRectMargins, self.displayFixX,self.displayFixY)
			
			graphX2.menuBox {rect          = displayFixRect,
			                 color         = self.boxColor, 
			                 fill          = self.boxTex,
			                 border        = self.borderTable,
			                 isSceneCoords = true,
			                 z             = self.z}

			-- Tail
			if  shouldShowTail  then
				graphX2.image  {img				= self.tailTex,
								x 				= self.tailX+self.displayFixX,
								y				= self.tailY+self.displayFixY,
								z				= self.z,
								color			= self.boxColor,
								angle			= tailAngle,
								scale			= self.tailScale,
								isSceneCoords	= true}--, self.tailTex)
			end
			
			-- Next icon
			if  shouldShowIcon  then
				local startX = displayFixRect.left
				local startY = displayFixRect.top
				local dirX = 1
				local dirY = 1
				
				if  self.nextIconHalign == textblox.ALIGN_MID  then
					startX = 0.5*(displayFixRect.left + displayFixRect.right)
				end
				if  self.nextIconHalign == textblox.ALIGN_RIGHT  then
					startX = displayFixRect.right
					dirX = -1
				end
				if  self.nextIconValign == textblox.ALIGN_MID  then
					startY = 0.5*(displayFixRect.top + displayFixRect.bottom)
				end
				if  self.nextIconValign == textblox.ALIGN_BOTTOM  then
					startY = displayFixRect.bottom
					dirY = -1
				end
			
				graphX2.image  {img				= self.nextIconTex,
								x 				= startX + self.nextIconX*dirX,
								y				= startY + self.nextIconY*dirY,
								z				= self.z,
								scale			= self.nextIconScale,
								isSceneCoords	= true}
			end
			
		 elseif  graphXActive  then
			
			if  self.bind == textblox.BIND_SCREEN  then
				graphX.menuBoxScreen (shakeRectMargins.left,
									  shakeRectMargins.top,
									  shakeRectMargins.right-boxRectMargins.left,
									  shakeRectMargins.bottom-boxRectMargins.top,
									  self.boxColor, self.boxTex, self.borderTable)
			else
				graphX.menuBoxLevel  (shakeRectMargins.left,
									  shakeRectMargins.top,
									  shakeRectMargins.right-boxRectMargins.left,
									  shakeRectMargins.bottom-boxRectMargins.top,
									  self.boxColor, self.boxTex, self.borderTable)
			end
			
			--[[
			graphX.boxScreen (tailX,
							  tailY,
							  8, 
							  8,
							  self.boxColor, self.tailTex)
			]]
		end

		-- Get text positioning based on anchors
		local textX = nil
		local textY = nil
		
		---[[
		if		self.textAnchorX == textblox.HALIGN_LEFT  then
			textX = shakeRect.left
		
		elseif	self.textAnchorX == textblox.HALIGN_RIGHT  then
			textX = shakeRect.right
		
		else
			textX = (shakeRect.left + shakeRect.right)*0.5
		end

		
		if		self.textAnchorY == textblox.VALIGN_TOP  then
			textY = shakeRect.top
		
		elseif	self.textAnchorY == textblox.VALIGN_BOTTOM  then
			textY = shakeRect.bottom
		
		else
			textY = (shakeRect.top + shakeRect.bottom)*0.5
		end
		
		textX = textX --[[+ self.font.charWidth*0.5]]  + self.textOffX
		textY = textY - self.font.charHeight*0.5 + self.textOffY
		
		
		
		-- Display text
		local textToShow = string.sub(self:getTextWrapped (), 1, self.charsShown)
		self.autoWidth, self.autoHeight = textblox.printExt (textToShow, {x=textX+self.displayFixX,
																		  y=textY+self.displayFixY,
																		  z=self.z,
																		  scale=self.textScale,
																		  font=self.font,
																		  bind=textblox.BIND_LEVEL,
																		  width=self.autoWidthFull,
																		  halign=self.textAnchorX,
																		  valign=self.textAnchorY,
																		  opacity=self.textAlpha,
																		  color=self.textColor,
																		  prewrapped=true})
		
		benchmark_end (bm_start, 8, 9)
	end

	
	function TextBlock:resetText (textStr)
		self:setText (textStr)
		self.charsShown = 0
		self.finished = false
		self.finishSoundPlayed = false
		self.updatingChars = true
		self.pauseFrames = -1
		self.speed = self.defaultSpeed
	
		if  self.autoTime == true  then
			self:insertTiming ()
		end		
		
		self.filteredText = textblox.plaintext(textStr)
		self.length = string.len(textStr)
	end
	
	
	function TextBlock:insertTiming ()
		
		local newText = ""
		local insertTimingMode = true
		
		for textChunk in string.gmatch(self.text, "<*[^<>]+>*")	do
			
			-- Is a command
			if  string.find(textChunk, "<.*>") ~= nil  then
				local commandStr, amountStr = string.match (textChunk, "([^<>%s]+) ([^<>%s]+)")
				if  commandStr == nil  then
					commandStr = string.match (textChunk, "[^<>%s]+")
				end
				
				-- notiming tags
				if  commandStr == "notiming"  then
					insertTimingMode = false
				end
				if  commandStr == "/notiming"  then
					insertTimingMode = true
				end
				
				
			-- Is plaintext
			elseif  insertTimingMode == true  then
				-- Commas
				textChunk = textChunk:gsub('%, ', ',<pause '..tostring(self.midMarkDelay)..'> ')
				
				
				-- Colons and semicolons
				textChunk = textChunk:gsub('%: ', ':<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub('%; ', ';<pause '..tostring(self.endMarkDelay)..'> ')

				
				-- Ellipses
				textChunk = textChunk:gsub("%.%.%. ", 	".<pause "..tostring(self.midMarkDelay)..">"..
														".<pause "..tostring(self.midMarkDelay)..">"..
														".<pause "..tostring(self.endMarkDelay).."> ")
			
				textChunk = textChunk:gsub(" %.%.%.",  " .<pause "..tostring(self.midMarkDelay)..">"..
														".<pause "..tostring(self.midMarkDelay)..">"..
														".<pause "..tostring(self.endMarkDelay)..">")

														
				-- Parenthesis
				--textChunk = textChunk:gsub('%(', '%(<pause '..tostring(self.midMarkDelay)..'>')
				--textChunk = textChunk:gsub('%)', '%)<pause '..tostring(self.midMarkDelay)..'>')
				
				-- End punctuation
				textChunk = textChunk:gsub('%? ', '%?<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub('%?" ', '%?"<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub("%?' ", "%?'<pause "..tostring(self.endMarkDelay)..'> ')
				
				textChunk = textChunk:gsub('%! ', '%!<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub('%!" ', '%!"<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub("%!' ", "%!'<pause "..tostring(self.endMarkDelay)..'> ')
				
				textChunk = textChunk:gsub('%. ', '%.<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub('%." ', '%."<pause '..tostring(self.endMarkDelay)..'> ')
				textChunk = textChunk:gsub("%.' ", "%.'<pause "..tostring(self.endMarkDelay)..'> ')
				
				-- Ending with ellipsis
				if  string.find(textChunk, "%.%.%.", -3) ~= nil  then
					textChunk = string.sub(textChunk, 1, -4)
					textChunk = textChunk.. ".<pause "..tostring(self.midMarkDelay)..">"..
											".<pause "..tostring(self.midMarkDelay)..">"..
											".<pause "..tostring(self.endMarkDelay)..">"
				end
			end
			
			
			-- Append the string to the end of newText
			newText = newText..textChunk
		end

		
		self.text = newText
	end
	
	
	function TextBlock:setText (textStr)
		self.text = textStr
		self.textDirty = true;
	end
	
	function TextBlock:getLength ()
		return string.len (self:getTextWrapped ())
	end
	
	function TextBlock:getLengthFiltered ()
		return string.len (self:getTextFiltered ())
	end

	
	function TextBlock:playTypeSound ()
		if  (self.typeUsedChannel == nil or Audio.SfxIsPlaying(self.typeUsedChannel) == 0)  and  #self.typeSounds > 0  then
			self.typeUsedChannel = Audio.SfxPlayCh (-1, rng.irandomEntry(self.typeSoundChunks), 0)
		end
	end
	
	
	
	function TextBlock:getFinished ()
		return self:isFinished ()
	end
	
	function TextBlock:isFinished ()
		return 	self.finished
	end
	
	function TextBlock:playFinishSound ()
		if  self.finishSoundPlayed == false  then
			self.finishSoundPlayed = true
			if  (self.finishSound ~= "")  then
				Audio.playSFX (textblox.getPath (self.finishSound))
			end
		end
	end
	
	function TextBlock:finish ()
		self.pauseFrames = -1
		self.shakeFrames = 0
		self.charsShown = self:getLength ()
		self.updatingChars = false
		self.finished = true
		
		self:playFinishSound ()
		
		-- Change the page
		if  self.autoClose == true  then
			self:changePage ()
		end
		
		-- Call user code
		self:onFinish ()
	end
	
	function TextBlock:onFinish ()
		
	end
	
	function TextBlock:changePage (usedInput)
		-- If the last page, close
		if  self.currentPage >= #self.pages  then
			if  self.inputClose  or  not usedInput  then
				self:closeSelf ()
			end

		-- If not the last page, start the next
		else
			self.currentPage = self.currentPage + 1
			self:resetText (self.pages[self.currentPage])
			
			-- Prevent it 
			if  self.latestPage >= self.currentPage  then
				self:finish ()
			end
			self.latestPage = math.max(self.currentPage, self.latestPage)
		end
	end
	
	function TextBlock:previousPage ()
		-- If not on the first page, go back;  otherwise, do nothing
		if  self.currentPage > 1  then
			self.currentPage = self.currentPage - 1
			self:resetText (self.pages[self.currentPage])
			self:finish ()
		end
	end
	
	function TextBlock:closeSelf ()
		-- Undo game pausing
		if  self.pauseGame == true  then
			Misc.unpause ();
		end
		
		-- Play close sound
		if  (self.closeSound ~= "")  then
			Audio.playSFX (textblox.getPath (self.closeSound))
		end
		
		-- Delete
		self:delete ()
	end
	
	function TextBlock:delete ()
		self.deleteMe = true
	end
	
	
	function TextBlock:update ()
		local bm_start = benchmark_start()
	
		self:updateTiming ()
		
		-- Progress and close via input if configured to do so
		if  self.inputProgress == true  then  

			-- Go to the previous page by pressing altjump
			if  (inputs.state[1]["altjump"] == inputs.PRESS) then
				self:previousPage ()
			end
			
			-- Go to the next page by pressing jump, run or altrun
			if  (inputs.state[1]["jump"] == inputs.PRESS or inputs.state[1]["run"] == inputs.PRESS or inputs.state[1]["altrun"] == inputs.PRESS) then
				
				-- If not finished with the current page, finish it 
				if  not self:getFinished ()  then
					self:finish ()
				
				-- Otherwise progress through the pages
				else
					self:changePage (true)
				end
			end
		end
		
		if  self.instant  and  self:getFinished () == false  then
			self:finish ()  
		end

		
		-- Track an object if configured to do so
		if  self.trackTarget ~= nil  then
			
			-- Convert to screen binding to simplify constraining
			--self:setBind (textblox.BIND_SCREEN)
			
			local targ = self.trackTarget
			local x1 = targ.x  or  self.x
			local y1 = targ.y  or  self.y
			local w1 = targ.width   or  32
			local h1 = targ.height  or  32

			x1,y1 = self:convertCoords (x1,y1, textblox.BIND_LEVEL)
			
			myRect = self:getRect (true)
			local targRect = newRECTd ()
			targRect.left, targRect.top, targRect.right, targRect.bottom = x1, y1, x1+w1, y1+h1
			
			
			-- Snap to position
			self.x = (x1 + 0.5*w1) + self.trackXAdd
			self.y = (y1 + 0.5*h1) + self.trackYAdd
			myRect = self:getRect (true)
			
			
			-- Avoid obscuring the target
			if  self.trackAutoOffset  then
				local totalHeight = myRect.bottom - myRect.top
				local bottomHeight = myRect.bottom - self.y
				local topHeight = self.y-myRect.top
			
				local topAnchor = targRect.top - topHeight - 32
				local bottomAnchor = targRect.bottom + bottomHeight + 32
				
				--windowDebug (tostring(targRect.top - totalHeight - 32))
				
				if  targRect.top - totalHeight - 32 >= 0  then
					self.y = topAnchor
				else
					self.y = bottomAnchor
				end
				
				myRect = self:getRect (true)
			end	

			--graphX2.box {rect=myRect, color=0xFFFFCC99}
			--graphX2.box {rect=targRect, color=0x99FFFFFF}			
		end
		
		
		-- Only display when visible
		if  self.visible == true  then
			self:draw ()
			
			--Text.print("finished="..tostring(self.finished), 4, 400,300)
		end
		
		benchmark_end (bm_start, 10, 11)
	end
	
	
	function TextBlock:updateTiming ()

		-- Subtract from the pause and shake timers
		self.pauseFrames = math.max(self.pauseFrames - 1, 0)
		self.shakeFrames = math.max(self.shakeFrames - 1, 0)
	

		-- Increment typewriter effect once the pause delay is over
		if  (self.pauseFrames <= 0)  then
			
			-- If all characters have been shown, clamp the typewriter effect to full text length and stop updating
			if 	self.charsShown > self:getLength ()  then
				self.charsShown = self:getLength ()
				
				-- If hasn't started finishing, stop updating the characters and pause for the finish delay
				if  self.updatingChars == true  then
					self.updatingChars = false
					self:playFinishSound ()
					self.pauseFrames = self.finishDelay
				
				-- Once the finish delay is done, finish the block
				elseif  self.finished == false  then
					self:finish ()
				end
				
			-- Update the typewriter effect
			else			
				self.charsShown = self.charsShown + 1
				
				local text = self:getTextWrapped ()
				
				local currentChar = text:sub (self.charsShown, self.charsShown)
				if (self:getFinished() == false  and  self.charsShown < self:getLength ()  and  currentChar:match("%a") ~= nil) then
					--Text.print(currentChar, 4, 20, 100)
					self:playTypeSound ()
				end
				
				-- Skip and process commands
				local continueSkipping = true
				
				while  (continueSkipping == true)  do
					
					-- Get current character
					currentChar = text:sub (self.charsShown, self.charsShown)
					local currentEscapeChar = text:sub (self.charsShown, self.charsShown+1)
					
					-- if it's an escape character
					--if  currentEscapeChar ~= '/<'  then
					--	self.charsShown = self.charsShown + 2
					
					-- if it's the start of a command...
					if  currentChar == '<'  then
						
						-- ...First parse the command...
						local commandEnd = text:find ('>', self.charsShown)
						local fullCommand = text:sub (self.charsShown, commandEnd)
						local commandName = fullCommand:match ('%a+', 1)
						local commandArgsPlusEnd = nil
						local commandArgs = nil
						local abortNow = false
						
						if commandName ~= nil  then
							commandArgsPlusEnd = fullCommand:match ('%s.+>', 1)--commandName:len())						
							--windowDebug ("Name: " .. commandName .. "\nArgs plus end: " .. tostring(commandArgsPlusEnd))

						end
						
						if  commandArgsPlusEnd ~= nil  then						
							commandArgs = commandArgsPlusEnd:sub (2, commandArgsPlusEnd:len() - 1)
						end

						
						-- ...then perform behavior based on the command...
						-- Pause:  if no arguments, assume a full second
						if  commandName == 'pause' then
							--windowDebug (tostring(commandArgs))
							
							if  commandArgs == nil then
								commandArgs = 60
							end
							
							if  commandArgs == "mid"  then
								commandArgs = midMarkDelay
							end
							if  commandArgs == "end"  then
								commandArgs = endMarkDelay
							end
							
							--windowDebug (tostring(commandArgs))
							
							self.pauseFrames = self.pauseFrames + commandArgs
							abortNow = true
						
						
						-- change speed
						elseif  commandName == 'speed' then
							if  commandArgs == nil then
								commandArgs = 0.5
							end
							
							self.speed = commandArgs
							abortNow = true
						
						
						-- Play sound effect
						elseif  commandName == 'sound' then
							if  commandArgs ~= nil then
								local sound = Misc.resolveFile (commandArgs)
								
								if sound ~= nil  then
									Audio.playSFX (textblox.getPath (sound))
								end
							end
							
							self.pauseFrames = self.pauseFrames + commandArgs
					
					
						-- Shake
						elseif  commandName == 'shake' then
							if  commandArgs == 'screen' or commandArgs == '0' or commandArgs == nil  then
								earthquake(8)
								
							elseif  commandArgs == 'box' or commandArgs == '1'  then
								self.shakeFrames = 8
							end
						
						end					
					
					
						-- ...then add the length of the command to the displayed characters to skip the command
						if  abortNow == true  then
							continueSkipping = false
							self.charsShown = self.charsShown - 1
						end
						
						self.charsShown = self.charsShown + fullCommand:len()
					
					
					-- Otherwise, stop processing
					else
						continueSkipping = false			
					end
				end
				
				
				
				-- Pause for X frames
				local framesToPause = (1/self.speed)
				self.pauseFrames = self.pauseFrames + framesToPause
			end
			
		end	
		
	end
	
end


		
--***************************************************************************************************
--                                                                                                  *
--              OVERRIDE PROPERTIES                                                                 *
--                                                                                                  *
--***************************************************************************************************
do	
	-- Define the presets
	local pr_system =  {x=400,y=192,
						scaleMode = textblox.SCALE_AUTO, 
						--startSound = "sound\\message.ogg",
						typeSounds = {"bwip.ogg","bwip2.ogg","bwip3.ogg"},
						finishSound = "sound\\zelda-dash.ogg",   --has-item
						closeSound = "sound\\zelda-fairy.ogg",  --zelda-dash, zelda-stab, zelda-fairy
						width = 400,
						height = 350,
						bind = textblox.BIND_SCREEN,
						font = textblox.FONT_SPRITEDEFAULT3X2,
						speed = 0.75,
						boxType = textblox.BOXTYPE_MENU,
						boxColor = 0x0000FFBB,
						autoTime = true, 
						pauseGame = true, 
						inputClose = true,
						inputProgress = true,
						stayOnscreen = true,
						boxAnchorX = textblox.HALIGN_MID, 
						boxAnchorY = textblox.VALIGN_MID, 
						textAnchorX = textblox.HALIGN_TOP, 
						textAnchorY = textblox.VALIGN_LEFT,
						xMargin = 4,
						yMargin = 16,
						nextIconX = 8,
						nextIconY = 8}


	local pr_bubble =  {
						scaleMode = textblox.SCALE_AUTO, 
						typeSounds = {"bwip.ogg","bwip2.ogg","bwip3.ogg"},
						finishSound = "sound\\zelda-dash.ogg",   --has-item
						closeSound = "sound\\zelda-fairy.ogg",  --zelda-dash, zelda-stab, zelda-fairy
						width = 400,
						height = 350,
						bind = textblox.BIND_SCREEN,
						font = textblox.FONT_SPRITEDEFAULT4X2,
						speed = 0.75,
						boxType = textblox.BOXTYPE_WORDBUBBLE,
						boxColor = 0xFFFFFFFF,
						autoTime = true, 
						pauseGame = true, 
						inputClose = true,
						inputProgress = true,
						stayOnscreen = true,
						boxAnchorX = textblox.HALIGN_MID, 
						boxAnchorY = textblox.VALIGN_MID, 
						textAnchorX = textblox.HALIGN_TOP, 
						textAnchorY = textblox.VALIGN_LEFT	
					   }
	
	local pr_sign =    {
						scaleMode = textblox.SCALE_AUTO, 
						startSound = "sound\\message.ogg",
						closeSound = "sound\\zelda-fairy.ogg",  --zelda-dash, zelda-stab, zelda-fairy
						width = 400,
						height = 350,
						bind = textblox.BIND_SCREEN,
						font = textblox.FONT_SPRITEDEFAULT4X2,
						instant = true,
						boxType = textblox.BOXTYPE_SIGN,
						autoTime = true, 
						pauseGame = true, 
						inputClose = true,
						inputProgress = true,
						stayOnscreen = true,
						boxAnchorX = textblox.HALIGN_MID, 
						boxAnchorY = textblox.VALIGN_MID, 
						textAnchorX = textblox.HALIGN_TOP, 
						textAnchorY = textblox.VALIGN_LEFT,
						xMargin = 10,
						yMargin = 20
					   }

	textblox.presetProps = {
		[textblox.PRESET_SYSTEM] = pr_system,
		[textblox.PRESET_BUBBLE] = pr_bubble,
		[textblox.PRESET_SIGN]   = pr_sign
		
	}

	
	-- Define the preset to use for each NPC
	textblox.npcPresets = {
		all = textblox.PRESET_BUBBLE,
		[151] = textblox.PRESET_SIGN
	}
	
	
	-- Copy the system preset to the overrideProps table for basic mode
	textblox.overrideProps = textblox.presetProps[textblox.PRESET_SYSTEM]
end


--***************************************************************************************************
--                                                                                                  *
--              UPDATE																			    *
--                                                                                                  *
--***************************************************************************************************


textblox.waveModeCycle = 0
local everyXthFrame = 0
local eventSpawnedMessage = false

local keyState = {}

do
	function textblox.onKeyboardPress ()
	end



	function textblox.update ()
		
		-- First frame flag, queued pause
		if  firstFrameYet == false  then
			if  queuedPause  then
				Misc.pause()
			end
			firstFrameYet = true
		end
		
		-- Reset event-spawned flag
		eventSpawnedMessage = false
		
		-- Cycle control vars
		everyXthFrame = (everyXthFrame+1)%10
		local bm_start = benchmark_start()
		
		textblox.waveModeCycle = (textblox.waveModeCycle + 0.25)%360
	
	
		-- Loop through and update/delete the text blocks
		local k = 1;
		while  k <= #textblox.textBlockRegister  do
			
			local v = textblox.textBlockRegister [k]
			if  (v.deleteMe == true)  then
				table.remove (textblox.textBlockRegister, k);
			
			else
				v.index = k;
				v:update ()
				k = k+1;
			end
		end
				
		-- Run garbage collection		
		--collectgarbage("collect")
		
		-- Display debug info
		if  textblox.debug  then
			bm_vals[1] = #textblox.textBlockRegister
			debugStr = "Text Block instances: "..tostring(bm_vals[1])
			debugStr = debugStr.."<br><br>TOTAL:<br>Min/max update loop cost: "..string.format("%f", bm_vals[12]).."-"..string.format("%f", bm_vals[13])
			debugStr = debugStr.."<br>Current update loop cost: "..string.format("%f", bm_vals[14])
			debugStr = debugStr.."<br><br>PER PRINTEXT:<br>Text chunk process cost: "..string.format("%f", bm_vals[3]).."<br>Text chunk display cost: "..string.format("%f", bm_vals[5])
			debugStr = debugStr.."<br><br>PER WRAP CALL:<br>Text chunk wrap cost: "..string.format("%f", bm_vals[7])
			debugStr = debugStr.."<br><br>PER BLOCK:<br>Display cost: "..string.format("%f", bm_vals[9]).."<br>Full update cost: "..string.format("%f", bm_vals[11])
			
			textblox.printExt (debugStr, {x=10,y=80,z=10,font=textblox.FONT_SPRITEDEFAULT3})
		end
		
		local bm_time = bm_clock() - bm_start
		benchmark_end (bm_start, 12, 13)
		
		if  everyXthFrame == 0  then	bm_vals[14] = bm_time;  end;
	end	
	
	
	function textblox.onEvent (eventName)
		-- Enable event message flag
		eventSpawnedMessage = eventTriggersMessage[eventName]
		
		-- Debug events
		if  eventName == "_textblox_ToggleMessageMode"  then

			-- Cycle the mode
			textblox.overrideMode = (textblox.overrideMode + 1)%3

			-- Display message based on mode
			local m = textblox.overrideMode
			if      m == textblox.OVERRIDE_VANILLA  then
				Text.showMessageBox("Message box overriding disabled.")
			
			elseif  m == textblox.OVERRIDE_BASIC  then
				Text.showMessageBox("Basic overriding enabled.")		
			
			else
				Text.showMessageBox("Tailored overriding enabled.")
			end
		end
	end

	
	function textblox.onMessageBox(eventObj, message, targetRef)
		if textblox.overrideMessageBox == true  or  textblox.overrideMode ~= textblox.OVERRIDE_VANILLA  then
			
			--windowDebug ("MESSAGE BOX: "..message)

			-- Setup
			local propsToUse = textblox.overrideProps
			local pX = player.x + player.width*0.5
			local pY = player.y + player.height*0.5
			
			-- Determine the preset style to use (default to system)
			local presetToUse = textblox.PRESET_SYSTEM			
			
			-- Get the tracking target
			if  targetRef == nil  and  eventSpawnedMessage == false  then
				local closestDist = 9999
				for  k,v  in pairs (NPC.getIntersecting(pX-64, pY-64, pX+64, pY+64))  do
					local vX = v.x + 0.5*v.width
					local vY = v.y + 0.5*v.height
					local diagDist = math.sqrt (((pX - vX)^2) + ((pY - vY)^2))
					
					if  v:mem (0x44, FIELD_WORD) == -1  and  diagDist < closestDist  then
						targetRef = v
						closestDist = diagDist
					end
				end
				
				-- If the target was found
				if  targetRef ~= nil  then
				
					-- Disable the ! icon for the tracking target
					targetRef:mem (0x44, FIELD_WORD, 0)
					
					-- Default to the preset for that npc or the one defined for all
					presetToUse = textblox.npcPresets[targetRef.id]  or  textblox.npcPresets.all
					
					-- Try to get the preset from the data
					if  pnpcActive  then					
						
						-- If not a generator
						if  not targetRef:mem(0x64, FIELD_BOOL)  then
							local pnpcRef = targetRef
							if pnpcRef.data.textblox ~= nil  then
								presetToUse = defaultChain {2, pnpcRef.data.textblox.preset, presetToUse}
							end
						end
					end
				end
			end

						
			-- If tailored overriding, set the  props to the selected preset and set the tracking target
			if  textblox.overrideMode == textblox.OVERRIDE_TAILORED  then
				propsToUse = textblox.presetProps[presetToUse]
				propsToUse.trackTarget = v
			end
			
			
			-- Generate the Text Block
			eventObj.cancelled = true
			mem (0x00B250E4, FIELD_STRING, "")
			textblox.currentMessage = TextBlock.create (propsToUse.x,propsToUse.y, message, propsToUse)
			
			if textblox.overrideProps.pauseGame == true  then
				Misc.pause ()
			end
		end
	end
end	



		
return textblox