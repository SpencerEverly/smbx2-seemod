--***************************************************************************************
--                                                                                      *
-- 	hdmx.lua                                                                            *
--  v1.0                                                                                *
--  Documentation:                                                                      *
--                                                                                      *
--***************************************************************************************


local hdmx = {}

local fb = Graphics.CaptureBuffer(800, 600)
local timeFactor = os.clock ()
local currentCam = 1
local cameraSections = {1,1}
local origBounds = {}

function hdmx.onInitAPI () --Is called when the api is loaded by loadAPI.
	registerEvent(hdmx, "onStart", "onStart", true)
	registerEvent(hdmx, "onCameraUpdate", "onCameraUpdate", true)
	registerEvent(hdmx, "onTick", "onTick", true)
end


--******************************************************************************************
--                                                                                         *
--  Math and stuffa                                                                        *
--                                                                                         *
--******************************************************************************************

local function getOrigSectionBounds(section)
	local GM_ORIG_LVL_BOUNDS = mem(0x00B2587C, FIELD_DWORD)

	local ptr    = GM_ORIG_LVL_BOUNDS + 0x30 * section
	local left   = mem(ptr + 0x00, FIELD_DFLOAT)
	local top    = mem(ptr + 0x08, FIELD_DFLOAT)
	local bottom = mem(ptr + 0x10, FIELD_DFLOAT)
	local right  = mem(ptr + 0x18, FIELD_DFLOAT)
	return left, top, bottom, right
end


local function updateCameraSections (index)
	local cam = Camera(index)
	local camSect = cameraSections[index]
	
	for i=1,21 do
		v = Section.get(i)
		if   cam.x >= v.boundary.left  and  cam.x <= v.boundary.right
		and  cam.y >= v.boundary.top  and  cam.y <= v.boundary.bottom  then	
			camSect = i
			i = 21;
		end
	end
	cameraSections[index] = camSect
end



--******************************************************************************************
--                                                                                         *
--  Start and update                                                                       *
--                                                                                         *
--******************************************************************************************

function hdmx.onStart ()
	for i=0, 20  do
		local newRect = newRECTd()
		newRect.left, newRect.top, newRect.bottom, newRect.right = getOrigSectionBounds(i)
		origBounds[i+1] = newRect
	end
end


function hdmx.onTick ()
	timeFactor = os.clock ()
end

function hdmx.onCameraUpdate (cameraIndex)
	updateCameraSections (cameraIndex)
	currentCam = cameraIndex	
end



--******************************************************************************************
--                                                                                         *
--  Effects                                                                                *
--                                                                                         *
--******************************************************************************************

function hdmx.wave (props)

	-- Defaults and setup
	if props == nil  then  props = {};  end
	
	local getDepth = props.getDepth or 0
	local drawDepth = props.drawDepth or 0
	
	local speed = props.speed or 1
	local xDensity = props.xDensity or 4
	local yDensity = props.yDensity or 4
	local xStrength = props.xStrength or 4
	local yStrength = props.yStrength or 4
	local xOffset = props.xOffset or 0
	local yOffset = props.yOffset or -0.0625
	
	local numCols = props.cols or 8
	local numRows = props.rows or 8

	local shading = props.shading
	if  shading == nil  then  shading = true;  end;
	
	local debugging = props.debug
	if  debugging == nil  then  debugging = false;  end;
	
	local tint = props.tint  or  {1.0, 1.0, 1.0, 1.0}

	
	-- Control vars
	local colWidth = 800/numCols
	local rowHeight = 600/numRows
	
	local cam = Camera(currentCam)
	local camSection = cameraSections[currentCam]
	local origBound = origBounds[camSection]
	
	local camOffX, camOffY = cam.x-origBound.left, cam.y-origBound.top
	
	local camClampDiffX = camOffX - (camOffX % (colWidth*2))
	local camClampDiffY = camOffY - (camOffY % (rowHeight*2))
	
	local vertWraps = camClampDiffY/rowHeight
	
	
	-- Generate poly
	local vertPoints = {}
	local texPoints = {}
	local vertColors = {}
	
	for  i=-2,numCols+4  do
		for  k=-2,numRows+4  do
			
			-- Calculate points
			local camOffU = (camOffX % (colWidth*2))/800
			local camOffV = (camOffY % (rowHeight*2))/600
									
			local u1,v1 = (i-1)/numCols, (k-1)/numRows
			local u2,v2 = (i)/numCols, (k)/numRows
			
			local uAdd,vAdd = (camOffX % (colWidth*2))/(colWidth*numCols), (camOffY % (rowHeight*2))/(rowHeight*numRows)

			
			local xOff1 = math.sin(speed*math.rad(360*(0.5*timeFactor + xOffset + xDensity*(u1 - uAdd))))--+ xDensity*(u1) + xOffset + camOffU)))
			local xOff2 = math.sin(speed*math.rad(360*(0.5*timeFactor + xOffset + xDensity*(u2 - uAdd)))) --+ xDensity*(u2) + xOffset + camOffU)))
			local yOff1 = math.sin(speed*math.rad(360*(0.5*timeFactor + yOffset + yDensity*(v1 - vAdd)))) --+ yDensity*(v1) + yOffset + camOffV)))
			local yOff2 = math.sin(speed*math.rad(360*(0.5*timeFactor + yOffset + yDensity*(v2 - vAdd)))) --+ yDensity*(v2) + yOffset + camOffV)))
			
			local x1,y1 = u1*800 + xOff1*xStrength,   v1*600 + yOff1*yStrength
			local x2,y2 = u2*800 + xOff2*xStrength,   v2*600 + yOff2*yStrength

			u1,v1 = u1-camOffU, v1-camOffV
			u2,v2 = u2-camOffU, v2-camOffV

			x1,y1 = x1-800*camOffU, y1-600*camOffV
			x2,y2 = x2-800*camOffU, y2-600*camOffV
			
			
			-- Verts tri 1
			table.insert(vertPoints, x1)
			table.insert(vertPoints, y1)
			
			table.insert(vertPoints, x2)
			table.insert(vertPoints, y1)
			
			table.insert(vertPoints, x1)
			table.insert(vertPoints, y2)
			
			
			-- verts tri 2
			table.insert(vertPoints, x1)
			table.insert(vertPoints, y2)
			
			table.insert(vertPoints, x2)
			table.insert(vertPoints, y1)
			
			table.insert(vertPoints, x2)
			table.insert(vertPoints, y2)
			

			-- UVs tri 1
			table.insert(texPoints, u1)
			table.insert(texPoints, v1)
			
			table.insert(texPoints, u2)
			table.insert(texPoints, v1)
			
			table.insert(texPoints, u1)
			table.insert(texPoints, v2)
			
			
			-- UVs tri 2
			table.insert(texPoints, u1)
			table.insert(texPoints, v2)
			
			table.insert(texPoints, u2)
			table.insert(texPoints, v1)
			
			table.insert(texPoints, u2)
			table.insert(texPoints, v2)
		end
	end


	-- Capture and draw
	fb:captureAt(getDepth)
	
	-- Vertex cols for debugging vs shading
	if  debugging  then
		for i=1,#texPoints  do
			vertColors[2*(i-1)+1] = 0.8+0.2*math.random(10)/10
			vertColors[2*(i-1)+2] = 0.8+0.2*math.random(10)/10
		end
		
		Graphics.glDraw {vertexCoords=vertPoints, texture=fb, textureCoords=texPoints,
						primitive=Graphics.GL_TRIANGLES, priority=drawDepth, vertexColors=vertColors, color=tint}
	end
	
	Graphics.glDraw {vertexCoords=vertPoints, texture=fb, textureCoords=texPoints,
					primitive=Graphics.GL_TRIANGLES, priority=drawDepth, color=tint}
end

return hdmx