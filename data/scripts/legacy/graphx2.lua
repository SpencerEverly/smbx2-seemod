--***************************************************************************************
--                                                                                      *
--  graphX2.lua                                                                         *
--  1.2.2                                                                               *
--                                                                                      *
--***************************************************************************************

local graphX2 = {}
local vectr = API.load ("vectr")
local mathX = API.load ("mathematX")

graphX2.resourcePath     = "..\\..\\..\\scripts\\legacy\\graphX\\"
graphX2.resourcePathOver = "..\\..\\scripts\\legacy\\graphX\\"

graphX2.imageWidths = {}
graphX2.imageHeights = {}



function graphX2.getPath (filename)		
	--windowDebug ("TEST")
	
	local localPath = Misc.resolveFile (filename)  
					
	if  localPath  ~=  nil  then
		return localPath
	end
	
	if isOverworld == true  then
		return graphX2.resourcePathOver..filename
	end
	
	return graphX2.resourcePath..filename
end


--***************************************************************************************************
--                                                                                                  *
--   ENUMS                                                                                          *
--                                                                                                  *
--***************************************************************************************************
graphX2.ALIGN_MID = 0
graphX2.ALIGN_TOP = 1
graphX2.ALIGN_BOTTOM = 2
graphX2.ALIGN_LEFT = 3
graphX2.ALIGN_RIGHT = 4


graphX2.MENU_FILL = Graphics.loadImage(graphX2.getPath("menuFillA.png"))
graphX2.BORDER_UL = Graphics.loadImage(graphX2.getPath("menuBorderUL.png"))
graphX2.BORDER_UR = Graphics.loadImage(graphX2.getPath("menuBorderUR.png"))
graphX2.BORDER_DL = Graphics.loadImage(graphX2.getPath("menuBorderDL.png"))
graphX2.BORDER_DR = Graphics.loadImage(graphX2.getPath("menuBorderDR.png"))
graphX2.BORDER_U = Graphics.loadImage(graphX2.getPath("menuBorderU.png"))
graphX2.BORDER_D = Graphics.loadImage(graphX2.getPath("menuBorderD.png"))
graphX2.BORDER_L = Graphics.loadImage(graphX2.getPath("menuBorderL.png"))
graphX2.BORDER_R = Graphics.loadImage(graphX2.getPath("menuBorderR.png"))


--***************************************************************************************************
--                                                                                                  *
--   MISC FUNCTIONS                                                                                 *
--                                                                                                  *
--***************************************************************************************************
	
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

function graphX2.worldToScreen (x,y)
	local b = getScreenBounds ();
	local x1 = x-b.left;
	local y1 = y-b.top;
	return x1,y1;
end	

function circleToTris(x,y,r, detail)
	--local debugString = ""
	
	if  detail == nil  then
		detail = 1
	end
	
	local x1 = x
	local y1 = y;
	local pts = {};
	
	local m = math.ceil(math.sqrt(r/(1/detail)));
	if(m < 1) then m = 1; end
	local s = (math.pi/2)/m;
	local ind = 1;
	local xmult = 1;
	local ymult = -1;
	for n=1,4 do
		local lx = 0;
		local ly = 1;
		for i=1,m do
			local xs = math.cos((math.pi/2)-s*i);
			local ys = math.sin((math.pi/2)-s*i);
			pts[ind] = x1;
			pts[ind+1] = y1;
			pts[ind+2] = x1+xmult*r*lx;
			pts[ind+3] = y1+ymult*r*ly;
			pts[ind+4] = x1+xmult*r*xs;
			pts[ind+5] = y1+ymult*r*ys;
			ind = ind+6;
			lx = xs;
			ly = ys;
		end
		if xmult == 1 then
			if ymult == -1 then
				ymult = 1;
			elseif ymult == 1 then
				xmult = -1;
			end
		elseif xmult == -1 then
			if ymult == -1 then
				xmult = 1;
			elseif ymult == 1 then
				ymult = -1;
			end
		end
	end
	
	--[[
	for i=1,#pts do
		debugString = debugString..tostring(pts[i])..", "..tostring(pts[i+1]).."\n"
	end
	windowDebug (tostring(#pts).."\n\n"..debugString)
	]]
	return pts;
end

function graphX2.getSize (tex)
	local texW,texH = 2,2;
	local pixels = {}
	
	if  tex ~= nil  then
		if  graphX2.imageWidths[tex] == nil  then
			pixels,texW,texH = Graphics.getPixelData(tex);
			graphX2.imageWidths[tex] = texW
			graphX2.imageHeights[tex] = texH
		else
			texW,texH = graphX2.imageWidths[tex],graphX2.imageHeights[tex]
		end
	else
		error("Cannot get size of nil texture")
	end
	
	return texW,texH
end

local function coordsToPoints(x1,y1,x2,y2)
	local pts = {};
	pts[1] = x1; 	pts[2] = y1;
	pts[3] = x2;	pts[4] = y1;
	pts[5] = x1;	pts[6] = y2;
	
	pts[7] = x1;	pts[8] = y2;
	pts[9] = x2;	pts[10] = y2;
	pts[11] = x2; 	pts[12] = y1;
	
	return pts;
end

local function boxToPoints(x,y,w,h)
	return  coordsToPoints(x,y,x+w,y+h)
end

local function deepcopy (orig)
	local orig_type = type(orig)
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
	local orig_type = type(orig)
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



--***************************************************************************************************
--                                                                                                  *
--   COLOR FUNCTIONS                                                                                *
--                                                                                                  *
--***************************************************************************************************

function graphX2.lerpColor (col1, col2, amount)
	local table1 = mathX.hexColorToTable (col1)
	local table2 = mathX.hexColorToTable (col2)
	local table3 = {
					[1] = mathX.lerp (table1[1], table2[1], amount),
					[2] = mathX.lerp (table1[2], table2[2], amount),
					[3] = mathX.lerp (table1[3], table2[3], amount),
					[4] = mathX.lerp (table1[4], table2[4], amount)
					}

	local finalHex = mathX.rgbaTableToHex (table3)
	return finalHex
end


--***************************************************************************************************
--                                                                                                  *
--   COMMON PROPERTIES OF ALL GRAPHX2 DRAW FUNCTIONS:                                               *
--   isSceneCoords = if true, draws the element at scene coordinates                                *
--   color = tint of the drawn element (default 0xFFFFFFFF)                                         *
--                                                                                                  *
--***************************************************************************************************

graphX2.globalProps = {
	isSceneCoords = true,
	color = 0xFFFFFFFF
}


--***************************************************************************************************
--                                                                                                  *
--   PRIMITIVE DRAWING FUNCTIONS                                                                    *
--                                                                                                  *
--   Common properties:                                                                             *
--   getTables = if true, doesn't draw & returns the points, UVs and vcol tables for the polygon    *
--                (only applies to primitives & poly)                                               *
--   vcols = vertex colors (array)                                                                  *
--   u = texture x offset (percent, default 0)                                                      *
--   v = texture y offset (percent, default 0)                                                      *
--   uvs = table of uv points                                                                       *
--   tex = texture image (LuaImageResource)                                                         *
--   texAngle = texture angle (degrees, default 0)                                                  *
--   texScale = scale of texture (default 1)                                                        *
--   texScaleX = horizontal scale of texture (default 1)                                            *
--   texScaleY = vertical scale of texture (default 1)                                              *
--   texAnchorX = horizontal alignment of texture (default graphX2.ALIGN_MID)                       *
--   texAnchorY = vertical alignment of texture (default graphX2.ALIGN_MID)                         *
--   lineColor = color of the outline (default 0x000000FF)                                          *
--   lineWidth = width of the outline (default 0)                                                   *
--   tile = if true, tile the texture (not currently working)                                       *
--   z = render priority                                                                            *
--                                                                                                  *
--***************************************************************************************************


--   graphX2.box -- Unique properties:                                                              
--   rect = RECTd bounds (alternative to x,y,w,h)
--   x = upper-left corner
--   y = upper-right corner
--   w = width
--   h = height

function graphX2.box (properties)
	local props = deepCopyWithCheck (properties)
	
	if  props.rect == nil  then
		props.rect = newRECTd()
		props.rect.left = 0
		props.rect.top = 0
		props.rect.right = 10
		props.rect.bottom = 10
	end
	
	props.x = props.x  or  props.rect.left
	props.y = props.y  or  props.rect.top
	props.w = props.w  or  props.rect.right - props.rect.left
	props.h = props.h  or  props.rect.bottom - props.rect.top
	
	props.points = boxToPoints(props.x,props.y, props.w,props.h)		
	return graphX2.poly (props)
end


--   graphX2.quad -- Unique properties:                                                              
--   points = table of points (only counts the first 8 indexes)

function graphX2.quad (properties)
	local props = deepCopyWithCheck (properties)
	local points = props.points
		
	local x1,x2,x3,x4 = points[1],points[3],points[5],points[7];
	local y1,y2,y3,y4 = points[2],points[4],points[6],points[8];
	
	local pts = {};
	pts[1] = x1; 	pts[2] = y1;
	pts[3] = x2;	pts[4] = y2;
	pts[5] = x3;	pts[6] = y3;
	pts[7] = x3;	pts[8] = y3;
	pts[9] = x4;	pts[10] = y4;
	pts[11] = x1;	pts[12] = y1;
	
	props.points = pts
	return graphX2.poly (props)
end


--   graphX2.line -- Unique properties:                                                              
--   points = table of points (only counts the first 4 indexes)
--   length = length of line (use with angle as alternative to points)
--   angle = direction of line (degrees, use with length as alternative to points)
--   startWidth = width of line at the beginning (default 2)
--   endWidth = width of line at the end (default 2)

function graphX2.line (properties)
	local props = deepCopyWithCheck (properties)
	
	-- Get coords
	local points = props.points
	local length = props.length  
	local angle = props.angle  
	local x1,x2,y1,y2
	
	if  points ~= nil  then
		x1,y1,x2,y2 = points[1],points[2],points[3],points[4];
		
		if  #points == 4  then
			length = mathX.magnitude (x2-x1,y2-y1)
			angle = mathX.angle (x2-x1,y2-y1)
		elseif  #points >= 2  and  length ~= nil  and  angle ~= nil  then
			x2,y2 = mathX.lengthdir(length,angle)
			x2 = x2+x1
			y2 = y2+y1
		else
			return;
		end
	else
		return;
	end
	
	-- Other properties		
	local w1 = props.startWidth  or  props.w1  or  props.w  or  2
	local w2 = props.endWidth    or  props.w2  or  props.w  or  2
	
	
	-- Calculate points
	local pts = boxToPoints (x1-0.5*w1, y1, w1, length);
	pts[5] = x1-0.5*w2
	pts[7] = pts[5]
	pts[9] = pts[7]+w2
	
	-- Rotate points
	pts = mathX.rotatePoints (pts, x1,y1, angle)
	
	-- Re-assign points and draw
	props.points = pts
	props.uvs = nil
	return graphX2.poly (props)
end


--   graphX2.circle -- Unique properties:                                                              
--   x = center x position (default 0)
--   y = center y position (default 0)
--   r = radius (default 1)

function graphX2.circle (properties)
	local props = deepCopyWithCheck (properties)

	local x = props.x or 0
	local y = props.y or 0
	local r = props.r or 1
		
	props.points = circleToTris (x,y,r)
	return graphX2.poly (props)
end


--   graphX2.poly -- Unique properties:                                                              
--   points = table of points

function graphX2.poly (properties)
	local props = deepCopyWithCheck (properties)

	-- Convert screen points to scene points
	local points = props.points
	
	if props.isSceneCoords  then
		for i=1, #points, 2 do 
			local x1,y1 = graphX2.worldToScreen (points[i], points[i+1]);
			points[i],points[i+1] = x1,y1
		end
	end
	
	-- Get the rest of the properties
	local uAdd = props.u or 0
	local vAdd = props.v or 0
	local uvs = props.uvs
	
	local z = props.z or 1.0
	
	local tex = props.tex
	local texAngle = props.texAngle or 0
	local texAnchorX = props.texAnchorX or graphX2.ALIGN_MID
	local texAnchorY = props.texAnchorY or graphX2.ALIGN_MID
	local texScaleX = props.texScaleX or props.texScale or 1
	local texScaleY = props.texScaleY or props.texScale or 1
	
	local lineCol = props.lineColor or 0x000000FF
	local lineW = props.lineWidth or 0
	local col = props.color or graphX2.globalProps.color
	local vcols = props.vcols
	local tile = props.tile
	
	local getTables = props.getTables
	
	if  getTables == nil  then
		getTables = false
	end
	if  tile == nil  then
		tile = false
	end

		-- Convert colors to new format for new gl draw function if necessary
		local newCol, newVcols
		if  type(col) == "table"  then
			newCol = col
		else
			newCol = mathX.hexColorToTable (col)		
		end
		
		-- vertex color conversion if necessary
		if  vcols~= nil  then
			if  #vcols ~= #points*2  then
				newVcols = {}
				for p=1,#vcols do
					local tempCol = mathX.hexColorToTable (vcols[p])
					local indx = 4*(p-1)
					newVcols[indx + 1] = tempCol[1]
					newVcols[indx + 2] = tempCol[2]
					newVcols[indx + 3] = tempCol[3]
					newVcols[indx + 4] = tempCol[4]
				end
			else
				newVcols = vcols
			end
		end
				
		-- Don't bother drawing if alpha is 0 to save on calculations
		if  newCol[4] <= 0  then  return  end
		
		-- If the UVs aren't already defined, do so
		if  uvs == nil  then
			
			-- Get UV bounds
			local x1,x2,y1,y2 = points[1],points[1],points[2],points[2];
			
			for i=1, #points, 2 do 
			
				-- Left- and rightmost
				if  points[i] < x1  then 
					x1 = points[i]
				end
				if  points[i] > x2  then 
					x2 = points[i]
				end
				
				-- Top- and bottommost
				if  points[i+1] < y1  then 
					y1 = points[i+1]
				end
				if  points[i+1] > y2  then 
					y2 = points[i+1]
				end
			end
			
			
			-- Calculate texture positioning
			local shapeW,shapeH = x2-x1, y2-y1;
			local xMid,yMid = (x1+x2)*0.5, (y1+y2)*0.5;

			if  texAnchorX == graphX2.ALIGN_LEFT  then
				xMid = x1
				uAdd = uAdd-0.5
			end
			if  texAnchorX == graphX2.ALIGN_RIGHT  then
				xMid = x2
				uAdd = uAdd+0.5
			end
			if  texAnchorY == graphX2.ALIGN_TOP  then
				yMid = y1
				vAdd = vAdd-0.5
			end
			if  texAnchorY == graphX2.ALIGN_BOTTOM  then
				yMid = y2
				vAdd = vAdd+0.5
			end
			
			
			local texW,texH = 2,2;
			if   tex ~= nil  then
				texW,texH = graphX2.getSize (tex)
			end

			local texL,texR,texT,texB = x1,x2,y1,y2;
			

			texW,texH = texW*texScaleX, texH*texScaleY;
			
			if  tile == false  then
				texW,texH = shapeW, shapeH;		
			end
			
			
			
			texL = xMid - texW*(0.5)
			texR = texL+texW;
			texT = yMid - texH*(0.5)
			texB = texT+texH;
			
			if  texW == 0  or  texH == 0  then
				return
			end
			
			
			-- Calculate non-rotated uvs
			uvs = {}
			for i=1, (#points), 2  do
				local rotX = points[i]
				local rotY = points[i+1]
				
				local newU, newV = mathX.invLerpUnclamped (texL,texR, rotX), mathX.invLerpUnclamped (texT,texB, rotY);
				
				
				uvs[i] = newU + uAdd;
				uvs[i+1] = newV + vAdd;
			end		
		end
		
		-- Rotate UVs
		if  (texAngle%360) ~= 0  then
			local angleAdd = (texAngle) * (math.pi/180);
			local cosMult, sinMult = math.cos(angleAdd), math.sin(angleAdd)
				
			for i=1, (#points), 2  do
				-- Rotate UVs
				local newU = 0.5 + cosMult * (uvs[i] - 0.5) - sinMult * (uvs[i+1] - 0.5);
				local newV = 0.5 + sinMult * (uvs[i] - 0.5) + cosMult * (uvs[i+1] - 0.5);			
				
				uvs[i] = newU;
				uvs[i+1] = newV;
			end
		end
		
		-- Draw lines
		if  lineW > 0  then
			for i=1, (#points), 2  do
				if i+2 < #points  then
					graphX2.line {points={points[i],points[i+1],points[i+2],points[i+3]}, w1=lineW,w2=lineW, color=lineCol}
				end
			end
		end
			
		-- Draw the poly/return the tables
		if  getTables  then
			return points, uvs, vcols;
		else
			--windowDebug (tostring(#points)..", "..tostring(#newVcols))
			Graphics.glDraw {vertexCoords=points, isSceneCoords, textureCoords=uvs, vertexColors=newVcols, texture=tex, priority=z, color=newCol}
			return nil, nil, nil;
		end
end


--   graphX2.arrow -- Unique properties:                                                              
--   points = table of points (only counts the first 4 indexes)
--   tipWidth = width of arrow tip (default 12)
--   tipLength = length of arrow tip (default 30)
--   properties of graphX2.line

function graphX2.arrow (properties)
	local props = deepCopyWithCheck (properties)

	local points = props.points
	local x1,y1,x2,y2 = points[1],points[2],points[3],points[4]
	local w1 = props.startWidth     or  props.w1  or  6
	local w2 = props.endWidth       or  props.w2  or  6
	local w3 = props.tipWidth       or  props.w3  or  12
	local tipL = props.tipLength    or  30
	local col = props.color         or  0xFFFFFFFF
	local lineW = props.lineWidth   or  0
	local lineCol = props.lineColor or  0x000000FF
	local z = props.z

	local v = vectr.v2(x2-x1,y2-y1)
	local angle = -mathX.angle(v.x,v.y)

	local pLineX1  = x2-mathX.lengthdir_x(tipL,angle)
	local pLineY1  = y2-mathX.lengthdir_y(tipL,angle)
	local pArrowX1 = x2
	local pArrowY1 = y2
	
	local pLineX2  = x2-mathX.lengthdir_x(tipL-lineW,angle)
	local pLineY2  = y2-mathX.lengthdir_y(tipL-lineW,angle)
	local pArrowX2 = x2-mathX.lengthdir_x(lineW*4,angle)
	local pArrowY2 = y2-mathX.lengthdir_y(lineW*4,angle)
	
	if  lineW > 0  then
		-- Outline
		graphX2.line {points={x1,y1,pLineX1,pLineY1}, w1=w1, w2=w2, color=lineCol, z=z}
		graphX2.line {points={pLineX1,pLineY1,pArrowX1,pArrowY1}, w1=w3, w2=0, color=lineCol, z=z}
		-- Fill
		graphX2.line {points={x1,y1,pLineX2,pLineY2}, w1=w1-(2*lineW), w2=w2-(2*lineW), color=col, z=z}
		graphX2.line {points={pLineX2,pLineY2,pArrowX2,pArrowY2}, w1=w3-(2*lineW), w2=0, color=col, z=z}
	else
		graphX2.line {points={x1,y1,pLineX1,pLineY1}, w1=w1, w2=w2, color=col, z=z}
		graphX2.line {points={pLineX1,pLineY1,pArrowX1,pArrowY1}, w1=w3, w2=0, color=col, z=z}
	end
end



--***************************************************************************************************
--                                                                                                  *
--   IMAGE DRAWING FUNCTIONS                                                                        *
--                                                                                                  *
--   Properties:                                                                                    *
--   img = image (LuaImageResource)                                                                 *
--   column = column of frame on sprite sheet (default 1)                                           *
--   row = row of frame on sprite sheet (default 1)                                                 *
--   columns = number of columns on sprite sheet (default 1)                                        *
--   rows = row of frame on sprite sheet (default 1)                                                *
--   skewX = amount of horizontal skew (default 0)                                                  *
--   skewY = amount of vertical skew (default 0)                                                    *
--   skewX = amount of horizontal skew (default 0)                                                  *
--   x = x coordinate (default 400)                                                                 *
--   y = y coordinate (default 300)                                                                 *
--   angle = rotation (default 0)                                                                   *
--   anchorX = horizontal alignment (default graphX2.ALIGN_MID)                                     *
--   anchorY = vertical alignment (default graphX2.ALIGN_MID)                                       *
--   scale = image scale (default 1)                                                                *
--   scaleX = horizontal image scale (default nil, overrides scale if defined)                      *
--   scaleY = vertical image scale (default nil, overrides scale if defined)                        *
--   width = fixed width                                                                            *
--   height = fixed height                                                                          *
--   isSceneCoords = if true, uses scene coordinates                                                *
--                                                                                                  *
--***************************************************************************************************

function graphX2.image (properties)
	local props = deepCopyWithCheck (properties)

	-- If no image, don't bother
	if  props.img == nil  then  return  end
	
	-- Get other properties
	local cols = props.rows  or  1
	local rows = props.columns  or  1
	local column = props.row  or  1
	local row = props.column  or  1
	
	local skewX = props.skewX  or  0
	local skewY = props.skewY  or  0
	
	local x = props.x  or  400
	local y = props.y  or  300
	local angle = props.angle
	local imgWInit,imgHInit = graphX2.getSize (props.img)
	
	if  rows ~= 1  or  cols ~= 1  then
		imgWInit = imgWInit/rows
		imgHInit = imgHInit/cols
	end
	
	local imgW,imgH = imgWInit,imgHInit
	local anchorX = props.anchorX  or  graphX2.ALIGN_MID
	local anchorY = props.anchorY  or  graphX2.ALIGN_MID
	
	
		
	-- Determine the points of the poly based on scale and alignment
	local x1,y1 = x,y
	
	-- Scale
	if  props.scale ~= nil  then
		imgW = imgWInit*props.scale
		imgH = imgHInit*props.scale
	end
	if  props.scaleX ~= nil  then
		imgW = imgWInit*props.scaleX
	end			
	if  props.scaleY ~= nil  then
		imgH = imgHInit*props.scaleY
	end
	
	-- Exact width or height
	if  props.width ~= nil  then
		imgW = props.width
	end			
	if  props.height ~= nil  then
		imgH = props.height
	end
	
	-- Don't bother if either scale is zero
	if  imgW == 0  or  imgH == 0  then
		return
	end
	
	-- Horizontal alignment
	if     anchorX == graphX2.ALIGN_MID    then
		x1 = x - 0.5*(imgW)
	elseif anchorX == graphX2.ALIGN_RIGHT  then  
		x1 = x - imgW
	end
	
	-- Vertical alignment
	if     anchorY == graphX2.ALIGN_MID    then
		y1 = y - 0.5*(imgH)
	elseif anchorY == graphX2.ALIGN_BOTTOM  then  
		y1 = y - imgH		
	end

	
	-- non-GL option
	if  props.noGL == true  or  Graphics.isOpenGLEnabled () == false  then
		--[[
		local uw,vh = imgWInit, imgHInit
			
		Graphics.draw {type=RTYPE_IMAGE, }
		--]]
		return nil, nil, nil
	else
	
		local pts = boxToPoints (x1,y1, imgW,imgH)
		
		
		-- Skew
		if  skewX ~= 0  then
			pts[1] = pts[1] + skewX*0.5
			pts[3] = pts[3] + skewX*0.5
			
			pts[7] = pts[7] - skewX*0.5
			pts[9] = pts[9] - skewX*0.5
		end
		
		if  skewY ~= 0  then
			pts[2] = pts[2] + skewY*0.5
			pts[6] = pts[6] + skewY*0.5
			pts[8] = pts[8] + skewY*0.5
			
			pts[4] = pts[4] - skewY*0.5
			pts[10] = pts[10] - skewY*0.5
			pts[12] = pts[12] - skewY*0.5
		end
		
		
		-- Determine UVs based on sheet properties
		local sheetU,sheetV,sheetW,sheetH = 0,0,1,1
		if  (rows ~= 1  or  cols ~= 1)  then
			sheetU = (row-1)/rows
			sheetV = (column-1)/cols
			sheetW = 1/rows
			sheetH = 1/cols
		end
		local uvs = boxToPoints (sheetU,sheetV, sheetW,sheetH)

		
		-- Rotate points if necessary
		if  props.angle ~= nil  then
			pts = mathX.rotatePoints (pts, x,y, angle)
		end
		
		
		-- Finally, draw the poly
		props.points = pts
		props.uvs = uvs
		props.tex = props.img
		return graphX2.poly (props)
	end
end


--***************************************************************************************************
--                                                                                                  *
--   UI DRAWING FUNCTIONS                                                                           *
--                                                                                                  *
--   Common properties:                                                                             *
--   x,y,w,h = x, y, width and height                                                               *
--                                                                                                  *
--***************************************************************************************************


--   graphX2.menuBox -- Unique properties:                                                              
--   rect = alternate to x,y,w,h
--   fill = the background texture of the menu box
--   color = tint of the fill (default 0xFFFFFFFF)
--   border = property table for border (see graphX2.border)

function graphX2.menuBox (properties)
	local props = deepCopyWithCheck (properties)
	
	if  props.rect == nil  then
		props.rect = newRECTd()
		props.rect.left = 400
		props.rect.top = 300
		props.rect.right = 402
		props.rect.bottom = 302
	end
	
	props.x = props.x  or  props.rect.left
	props.y = props.y  or  props.rect.top
	props.w = props.w  or  props.rect.right - props.rect.left
	props.h = props.h  or  props.rect.bottom - props.rect.top
	
	local x1 = props.x
	local y1 = props.y
	local w1 = props.w
	local h1 = props.h
	
	local col1 = props.color  or  0xFFFFFFFF
	local texImg = props.fill  or  graphX2.MENU_FILL
	
	x1 = math.min(x1,x1+w1)
	y1 = math.min(y1,y1+h1)
	
	
	-- Fill
	graphX2.box {x=x1, y=y1, z=props.z, w=math.abs(w1), h=math.abs(h1), tex=texImg, color=col1, isSceneCoords=props.isSceneCoords}
				
	-- Border
	local borderTable = props.border or {}
	borderTable.x = x1
	borderTable.y = y1
	borderTable.w = w1
	borderTable.h = h1
	borderTable.color = borderTable.col  or  col1
	borderTable.z = props.z
	borderTable.isSceneCoords = props.isSceneCoords
	graphX2.border (borderTable)
end


--   graphX2.border -- Unique properties:                                                              
--   ulImg = upper-left corner image  (LuaImageResource)
--   uImg  = top edge image           (LuaImageResource)
--   urImg = upper-right corner image (LuaImageResource)
--   rImg  = right edge image         (LuaImageResource)
--   drImg = lower-right corner image (LuaImageResource)
--   dImg  = bottom edge image        (LuaImageResource)
--   dlImg = lower-left corner image  (LuaImageResource)
--   lImg  = left edge image          (LuaImageResource)
--   thick = thickness of border (default 4)

function graphX2.border (properties)
	local props = deepCopyWithCheck (properties)
		
	-- Get properties
	local ulImg = props.ulImg  or  graphX2.BORDER_UL
	local uImg  = props.uImg   or  graphX2.BORDER_U
	local urImg = props.urImg  or  graphX2.BORDER_UR
	local rImg  = props.rImg   or  graphX2.BORDER_R
	local drImg = props.drImg  or  graphX2.BORDER_DR
	local dImg = props.dImg   or  graphX2.BORDER_D
	local dlImg = props.dlImg  or  graphX2.BORDER_DL
	local lImg = props.lImg   or  graphX2.BORDER_L

	local th   = props.thick  or  4
	if  th <= 0  then  return;  end	
	
	local col1 = props.color  or  0xFFFFFFFF
	
	if  props.rect == nil  then
		props.rect = newRECTd()
		props.rect.left = 400
		props.rect.top = 300
		props.rect.right = 402
		props.rect.bottom = 302
	end
	
	local x = props.x  or  props.rect.left
	local y = props.y  or  props.rect.top
	local w = props.w  or  props.rect.right - props.rect.left
	local h = props.h  or  props.rect.bottom - props.rect.top
	
	local x1 = math.min(x,x+w)-th
	local x2 = x
	local x3 = math.max(x,x+w)
	local x4 = x3+th

	local y1 = math.min(y,y+h)-th
	local y2 = y
	local y3 = math.max(y,y+h)
	local y4 = y3+th
	
	-- Corners
	graphX2.box {x=x1, y=y1, w=th, h=th, z=props.z, color=col1, tex=ulImg, isSceneCoords=props.isSceneCoords} -- Upper-left
	graphX2.box {x=x3, y=y1, w=th, h=th, z=props.z, color=col1, tex=urImg, isSceneCoords=props.isSceneCoords} -- Upper-right
	graphX2.box {x=x1, y=y3, w=th, h=th, z=props.z, color=col1, tex=dlImg, isSceneCoords=props.isSceneCoords} -- Lower-left
	graphX2.box {x=x3, y=y3, w=th, h=th, z=props.z, color=col1, tex=drImg, isSceneCoords=props.isSceneCoords} -- Lower-right
	
	-- Edges
	graphX2.box {x=x1, y=y2, w=th, h=h, z=props.z, color=col1, tex=lImg, isSceneCoords=props.isSceneCoords} -- Left
	graphX2.box {x=x2, y=y1, w=w, h=th, z=props.z, color=col1, tex=uImg, isSceneCoords=props.isSceneCoords} -- Top
	graphX2.box {x=x3, y=y2, w=th, h=h, z=props.z, color=col1, tex=rImg, isSceneCoords=props.isSceneCoords} -- Right
	graphX2.box {x=x2, y=y3, w=w, h=th, z=props.z, color=col1, tex=dImg, isSceneCoords=props.isSceneCoords} -- Bottom
end


--   graphX2.progressBar -- Unique properties:                                                              
--   amount = percentage filled (default 0.5)
--   align  = direction the bar fills from (default graphX2.ALIGN_LEFT)
--   border = property table for border (see graphX2.border)

function graphX2.progressBar (properties)
	local props = deepCopyWithCheck (properties)

	local x1 = props.x  or  400
	local y1 = props.y  or  300
	local w1 = props.w  or  2
	local h1 = props.h  or  2
	
	local col1 = props.color  or  props.col  or  0x00BB00FF
	props.color = 0xFFFFFF00
	
	local amount = props.amount  or  0.5
	local align = props.align  or  graphX2.ALIGN_LEFT
	
	-- border
	graphX2.menuBox (props)
	
	-- bar
	if     align == graphX2.ALIGN_LEFT    then
		props.w = w1*amount
	elseif align == graphX2.ALIGN_RIGHT   then
		props.w = w1*amount
		props.x = x1 + (w1 - props.w)
	elseif align == graphX2.ALIGN_TOP     then
		props.h = h1*amount
	elseif align == graphX2.ALIGN_BOTTOM  then
		props.h = h1*amount
		props.y = y1 + (h1 - props.h)
	end
	
	props.color = col1
	graphX2.box (props)
end



--***************************************************************************************************
--                                                                                                  *
--   MISC OLD FUNCTIONS FOR COMPATIBILITY                                                           *
--                                                                                                  *
--***************************************************************************************************
do
	function graphX2.menuBoxLevel (x,y,w,h, col, fillTex, borderTable)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.menuBoxScreen (x1,y1,w,h, col, fillTex, borderTable)
	end
	
	function graphX2.menuBoxScreen (x,y,w,h, col, fillTex, borderTable)
		local texImg = fillTex or graphX.MENU_FILL
		
		local x1 = math.min(x,x+w)
		local y1 = math.min(y,y+h)
		
		-- Fill
		graphX.boxScreen (x1,y1,math.abs(w),math.abs(h), col, texImg)
					
		-- Border
		graphX.menuBorderScreen (x,y,w,h, borderTable)
	end

	function graphX2.getDefBorderTable ()
		local props = {}
			
		-- Get properties
		props.ulImg = graphX2.BORDER_UL
		props.uImg  = graphX2.BORDER_U
		props.urImg = graphX2.BORDER_UR
		props.rImg  = graphX2.BORDER_R
		props.drImg = graphX2.BORDER_DR
		props.dImg  = graphX2.BORDER_D
		props.dlImg = graphX2.BORDER_DL
		props.lImg  = graphX2.BORDER_L

		props.th    = 4
		props.col   = 0xFFFFFFFF
		props.color = props.col
		
		return props;
	end
end



return graphX2;