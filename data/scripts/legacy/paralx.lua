--***************************************************************************************
--                                                                                      *
--  paralX.lua                                                                          *
--  v1.5                                                                                *
--  Documentation: http://engine.wohlnet.ru/pgewiki/ParalX.lua                          *
--                                                                                      *
--***************************************************************************************

local paralX = {}

function paralX.onInitAPI() --Is called when the api is loaded by loadAPI.
	--register event handler
	--registerEvent(string apiName, string internalEventName, string functionToCall, boolean callBeforeMain)
   
	registerEvent(paralX, "onStart", "onStart", true) --Register the init event
	registerEvent(paralX, "onLoadSection", "onLoadSection", true)
	registerEvent(paralX, "onLoop", "onLoop", true)
	registerEvent(paralX, "onKeyboardPress", "onKeyboardPress", true)
	registerEvent(paralX, "onCameraUpdate", "onCameraUpdate", false)
end

local textblox = require("textblox")


-- Enums
paralX.ALIGN_LEFT = 1
paralX.ALIGN_RIGHT = 2
paralX.ALIGN_TOP = 3
paralX.ALIGN_BOTTOM = 4
paralX.ALIGN_MID = 5


-- Debug mode and other config options
paralX.debug = false
paralX.debugState = 0
paralX.sectionsByIndex = false
paralX.useOldPositioning = false



local cameraSections = {1,1}
local origBounds = {}
local indexedParallaxes = {}

local function getOrigSectionBounds(section)
	local GM_ORIG_LVL_BOUNDS = mem(0x00B2587C, FIELD_DWORD)

	local ptr    = GM_ORIG_LVL_BOUNDS + 0x30 * section
	local left   = mem(ptr + 0x00, FIELD_DFLOAT)
	local top    = mem(ptr + 0x08, FIELD_DFLOAT)
	local bottom = mem(ptr + 0x10, FIELD_DFLOAT)
	local right  = mem(ptr + 0x18, FIELD_DFLOAT)
	return left, top, bottom, right
end

local function angle (x,y)
	return math.deg (math.atan2 (y,x)) + 90
end
local function magnitude (x,y)
		local vx = x
		local vy = y

		local length = math.sqrt(vx * vx + vy * vy);
		return length
	end
local function lengthdir_x (length, dir)
	return math.sin(math.rad(dir))*length
end
local function lengthdir_y (length, dir)
	return -math.cos(math.rad(dir))*length
end
local function lerp (minVal, maxVal, percentVal)
	return (1-percentVal) * minVal + percentVal*maxVal;
end
local function wrap (minVal, maxVal, value)
	local newVal = value
	local size = maxVal - minVal
	local wrapAmount = 0
	if      value > maxVal  then
		wrapAmount = math.abs(value-maxVal)%size
		newVal = minVal + wrapAmount
	elseif  value < minVal  then
		wrapAmount = math.abs(minVal-value)%size
		newVal = maxVal - wrapAmount
	end
	return newVal
end
local function hexToRGBATable(hex)
	if  hex == nil  then  return  nil;  end;
	return {math.floor(hex/(256*256*256))/255,(math.floor(hex/(256*256))%256)/255,(math.floor(hex/256)%256)/255,(hex%256)/255}
end
local function quadPoints (x1,y1, x2,y2, x3,y3, x4,y4)
	local pts = {}
	pts[1]  = x1;      pts[2]  = y1;
	pts[3]  = x2;      pts[4]  = y2;
	pts[5]  = x4;      pts[6]  = y4;

	pts[7]  = x4;      pts[8]  = y4;
	pts[9]  = x3;      pts[10] = y3;
	pts[11] = x2;      pts[12] = y2;

	return pts
end
local function rectPointsXYXY (x1,y1,x2,y2)
	return quadPoints (x1,y1, x2,y1, x2,y2, x1,y2)
end

local function rectPointsXYWH (x,y,w,h)
	return rectPointsXYXY (x,y, x+w,y+h)
end


local function debugText (text, properties)	
	if  paralX.debug == false  then  return;  end

	props = {}
	props.x = properties.x
	props.y = properties.y
	props.z = properties.z
	
	if  textbloxActive  then
		props.halign = properties.halign  or  textblox.HALIGN_MID
		props.valign = properties.valign  or  textblox.VALIGN_MID
		props.font = properties.font  or  textblox.FONT_SPRITEDEFAULT3--X2

		textblox.printExt (text, props)
	else
		Text.print (text, 4, props.x,props.y)
	end
end

function paralX.getAllSections ()
	local newTabl

	if  paralX.sectionsByIndex  then
		newTabl = {1, 1, 1, 1, 1, 1, 1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1}
	else
		newTabl = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22}
	end

	return newTabl;
end


-- Parallax class
local Parallax = {}

function Parallax.__index(obj,key)
	if     (key == "color"  or  key == "colour") then
		return rawget(obj, "_color")

	elseif(key == "_type") then
		return "parallax layer";

	elseif(key == "meta") then
		return Parallax;
	else
		return rawget(Parallax, key)
	end
end
function Parallax.__newindex(obj,key,val)
	if     (key == "color"  or  key == "colour") then
		local colTable = hexToRGBATable(val)
		rawset (obj, "_color", colTable)

	elseif (key == "_type") then
		error("Cannot set the type of Parallax layer objects.",2);
	else
		rawset(obj, key, val);
	end
end




function Parallax.create (args)
	local thisParallaxObj = {}
	setmetatable (thisParallaxObj, Parallax)

	-- Control vars
	thisParallaxObj.id = #indexedParallaxes
	thisParallaxObj.visible = true

	thisParallaxObj.speedx = 0
	thisParallaxObj.speedy = 0

	thisParallaxObj.width = 0
	thisParallaxObj.height = 0

	thisParallaxObj.camDistX = 0
	thisParallaxObj.camDistY = 0


	-- Read parameters
	thisParallaxObj.name = args.name  or  "layer_"..tostring(thisParallaxObj.id)
	thisParallaxObj.image = args.image
	thisParallaxObj.color = args.color
	thisParallaxObj.frames = args.frames  or  1
	thisParallaxObj.animFrame = args.animFrame  or  0
	thisParallaxObj.animSpeed = args.animSpeed  or  0.05
	thisParallaxObj.alpha = args.alpha  or  1

	thisParallaxObj.useGl = args.useGl
	if args.useGl == nil  then  thisParallaxObj.useGl = true;  end;

	thisParallaxObj.sections = args.sections  or  paralX.getAllSections()
	if  type(args.sections) == "number"  then
		thisParallaxObj.sections = {args.sections}
	end

	thisParallaxObj.priority = args.priority  or  -96

	thisParallaxObj.shader     = args.shader
	thisParallaxObj.uniforms   = args.uniforms
	thisParallaxObj.attributes = args.attributes

	thisParallaxObj.speedX = args.speedX  or  0
	thisParallaxObj.speedY = args.speedY  or  0

	thisParallaxObj.x = args.x  or  0
	thisParallaxObj.y = args.y  or  0

	thisParallaxObj.wobbleX = args.wobbleX  or  0
	thisParallaxObj.wobbleY = args.wobbleY  or  0

	thisParallaxObj.parallaxX = args.parallaxX  or  0.75
	thisParallaxObj.parallaxY = args.parallaxY  or  0.75

	thisParallaxObj.alignX = args.alignX  or  paralX.ALIGN_LEFT
	thisParallaxObj.alignY = args.alignY  or  paralX.ALIGN_TOP

	thisParallaxObj.repeatX = args.repeatX
	thisParallaxObj.repeatY = args.repeatY
	if  thisParallaxObj.repeatX == nil  then
		thisParallaxObj.repeatX = true
	end
	if  thisParallaxObj.repeatY == nil  then
		thisParallaxObj.repeatY = true
	end

	thisParallaxObj.gapX = args.gapX  or  0
	thisParallaxObj.gapY = args.gapY  or  0

	thisParallaxObj.wrapFixX = args.wrapFixX  or  0
	thisParallaxObj.wrapFixY = args.wrapFixY  or  0

	table.insert (indexedParallaxes, thisParallaxObj)
	return thisParallaxObj;
end


function paralX.create (args)
	return Parallax.create (args)
end



function Parallax:update ()
	-- Update animation
	self.animFrame = (self.animFrame + self.animSpeed) % self.frames;

	self.width = self.image.width
	self.height = self.image.height / self.frames

	self.speedx = (self.speedx + self.speedX) % (self.width + self.gapX)
	self.speedy = (self.speedy + self.speedY) % (self.height + self.gapY)
end


function Parallax:sectionCheck (cameraIndex)
	local val = false
	local currentSection = cameraSections[cameraIndex]

	if  paralX.sectionsByIndex == false  then
		for  _,v in pairs (self.sections)  do
			if  v == currentSection  then
				val = true
				break
			end
		end
	else
		if  self.sections[math.max(1, math.min(21, currentSection))] ~= nil  then
			val = true
		end
	end

	return val;
end


function Parallax:sortSections ()
	-- Only sort once
	if self.sorted == true  then
		return

	else
		local checkVals = {}
		local indexedVals = {}

		-- Get sorted list of the keys/values
		for  k,v in pairs(self.sections)  do

			-- If by value
			if  paralX.sectionsByIndex == false  then
				if  indexedVals[v] == nil  then
					table.insert(checkVals, v)
					indexedVals[v] = 1
				end

			-- If by key
			else
				table.insert(checkVals, k)
			end
		end
		table.sort(checkVals)

		self.sortedVals = checkVals
		self.sorted = true
		return
	end
end


function Parallax:sectionString ()
	local str = ""

	-- If not a valid table, return the type
	if  type(self.sections) ~= "table"  then  
		return "not a table";
	end

	-- Get sorted list of the keys/values
	self:sortSections ()

	if  #self.sortedVals <= 0  then  return "none";  end


	-- Loop through and add the ranges to the string
	local rangeStart = nil
	local rangePrev = nil

	for  _,v in ipairs(self.sortedVals)  do

		-- First item
		if  rangeStart == nil  then
			rangeStart = v

		else 
			-- If starting a new range of consecutive numbers, print the previous one
			if  v ~= rangePrev + 1  then

				-- If this isn't the first range, separate with a comma
				if  str ~= ""  then  str = str..",";  end

				-- Concatenate the range
				str = str..tostring (rangeStart)
				if  rangePrev > rangeStart + 1  then
					str = str.."-"..tostring(rangePrev)
				elseif  rangePrev == rangeStart + 1  then
					str = str..","..tostring(rangePrev)
				end

				-- Reset the range start
				rangeStart = v
			end
		end

		rangePrev = v
	end

	-- Last range
		-- If this isn't the first range, separate with a comma
		if  str ~= ""  then  str = str..",";  end

		-- Concatenate the range
		str = str..tostring (rangeStart)
		if  rangePrev > rangeStart + 1  then
			str = str.."-"..tostring(rangePrev)
		elseif  rangePrev == rangeStart + 1  then
			str = str..","..tostring(rangePrev)
		end


	-- Finally, return the string
	return str;
end


function Parallax:getMidCoords (cameraIndex, shouldWrap)
	if  shouldWrap == nil  then  shouldWrap = true;  end;

	local w = self.image.width
	local h = self.image.height / self.frames

	if  paralX.useOldPositioning  then
		local w = self.width
		local h = self.height

		local mX = -self.parallaxX * (camera.x + 200000) + w + self.x + self.speedx + self.wobbleX
		local mY = -self.parallaxY * (camera.y + 200000) + self.y + self.speedy + self.wobbleY

		if  self.repeatX == true  then
			mX = mX % (w + self.gapX)
		end
		if  self.repeatY == true  then
			mY = mY % (h + self.gapY)
		end

		return mX,mY

	else
		local sectBounds = origBounds[cameraSections[cameraIndex]-1]  or  Section(cameraSections[cameraIndex]-1).boundary
		local boundsW = sectBounds.right - sectBounds.left
		local boundsH = sectBounds.bottom - sectBounds.top
		local boundsMidX = 0.5*(sectBounds.left + sectBounds.right)
		local boundsMidY = 0.5*(sectBounds.top + sectBounds.bottom)

		local cam = Camera(cameraIndex)

		local camDistX = cam.x - sectBounds.left
		local camDistY = cam.y - sectBounds.top

		local offsetX = self.x + self.speedx + self.wobbleX
		local offsetY = self.y + self.speedy + self.wobbleY	

		-- Apply alignment
		if  self.alignX == paralX.ALIGN_RIGHT  then
			camDistX = (cam.x + cam.width) - sectBounds.right
			offsetX = offsetX - self.width + cam.width
		end
		if  self.alignX == paralX.ALIGN_MID  then
			camDistX = (cam.x + 0.5*cam.width) - boundsMidX
			offsetX = offsetX - self.width*0.5 + cam.width*0.5
		end
		if  self.alignY == paralX.ALIGN_BOTTOM  then
			camDistY = (cam.y + cam.height) - sectBounds.bottom
			offsetY = offsetY - self.height + cam.height -- + self.height--*self.parallaxY
		end
		if  self.alignY == paralX.ALIGN_MID  then
			camDistY = (cam.y + 0.5*cam.height) - boundsMidY
			offsetY = offsetY - self.height*0.5 + cam.height*0.5
		end

		local mX = -self.parallaxX * (camDistX) + offsetX
		local mY = -self.parallaxY * (camDistY) + offsetY	


		-- Store camera distance x and y for debugging
		self.camDistX = camDistX
		self.camDistY = camDistY

		-- Apply wrapping
		if  shouldWrap  then
			if  self.repeatX == true  then
				mX = wrap(-w - self.gapX, 0, mX)
			end
			if  self.repeatY == true  then
				mY = wrap(-h - self.gapY, 0, mY)
			end
		end

		return mX,mY
	end

	--[[
	local props
	if  textbloxActive  then
		props = {x=10, y=200+20*(self.id-1)+10*(cameraIndex-1), }
	else
		props = {x=200, y=200+20*(self.id-1)+10*(cameraIndex-1)}
	end
	debugText (self.name..": "..tostring(math.floor(mX))..", "..tostring(math.floor(mY)), {x=200, y=200 + 20*(self.id-1) + 10*(cameraIndex-1)})
	]]
	--local mX = -self.parallaxX * (Camera.get()[cameraIndex].x - Section(cameraSections[cameraIndex]).boundary.left) + self.x + self.speedx + self.wobbleX
	--local mY = -self.parallaxY * (Camera.get()[cameraIndex].y - Section(cameraSections[cameraIndex]).boundary.top) + self.y + self.speedy + self.wobbleY		
end


function Parallax:draw (cameraIndex)
	if  self.image == nil  then
		Text.print ("Nil image", 4, 400,300)
		return
	end

	local cam = Camera(cameraIndex)
	local camW = cam.width
	local camH = cam.height
	local hCamW = camW*0.5
	local hCamH = camH*0.5

	local w = self.image.width
	local h = self.image.height / self.frames

	local numTilesX = 1
	local numTilesY = 1

	-- Section check
	local validSection = self:sectionCheck (cameraIndex)

	-- Only draw in given section
	if  validSection  then	
		local mX, mY = self:getMidCoords (cameraIndex)

		if  self.repeatX == true  then
			numTilesX = math.ceil(camW/w)+2
		end
		if  self.repeatY == true  then
			numTilesY = math.ceil(camH/h)+2
		end


		-- Debug drawing
		if  paralX.debug == true  then
			--Text.print(tostring(mX), 4, 20, 100)
			--Text.print(tostring(mY), 4, 20, 120)

			if  mX ~= nil  and  mY ~= nil  then
				local mX1 = mX
				if 	self.repeatX  then
					mX1 = mX1 + w + self.gapX
				end
				local arrowAngle = angle (mX1-hCamW, mY-hCamH)

				--[[
				if graphx2Active  then
					graphX2.arrow {points={hCamW,hCamH,mX1,mY}, w1=6, w2=6, w3=15, z=4, lineWidth=2, lineColor=0x00000099, tipLength=30, color=0xFFFFFF99}

				elseif  graphxActive  then
					local vertexPtsA1 = {hCamW,  hCamH,
										mX1-12,  mY,
										mX1+12,  mY,
										hCamW,   hCamH}

					local vertexPtsB1 = {hCamW,  hCamH,
										mX1,     mY-12,
										mX1,     mY+12,
										hCamW,   hCamH}

					local vertexPtsA2 = {hCamW,  hCamH,
										mX1-10,  mY,
										mX1+10,  mY,
										hCamW,   hCamH}

					local vertexPtsB2 = {hCamW,  hCamH,
										mX1,     mY-10,
										mX1,     mY+10,
										hCamW,   hCamH}

					--Text.print(tostring(math.ceil(vertexPtsA[1]))..", "..tostring(math.ceil(vertexPtsA[2])), 4, 20, 120)
					--Text.print(tostring(math.ceil(vertexPtsA[3]))..", "..tostring(math.ceil(vertexPtsA[4])), 4, 20, 140)
					--Text.print(tostring(math.ceil(vertexPtsA[5]))..", "..tostring(math.ceil(vertexPtsA[6])), 4, 20, 160)
					--Text.print(tostring(math.ceil(vertexPtsA[7]))..", "..tostring(math.ceil(vertexPtsA[8])), 4, 20, 180)

					graphX.polyExt (vertexPtsA1, {z=4, color=0x00000055})
					graphX.polyExt (vertexPtsB1, {z=4, color=0x00000055})
					graphX.polyExt (vertexPtsA2, {z=4, color=0xFFFFFF55})
					graphX.polyExt (vertexPtsB2, {z=4, color=0xFFFFFF55})
				end
				--]]

				-- Debug info
				local sectStr = self:sectionString ()

				local textLength = math.min (hCamW-150, magnitude(mX1-hCamW,mY-hCamH)-70)
				local posX,posY = hCamW+lengthdir_x (textLength,arrowAngle), hCamH+lengthdir_y (textLength,arrowAngle)
				local props = {x=posX, y=posY}
				local text = ""

				if  paralX.debugState == 0  then
					text = self.name
				end
				if  paralX.debugState == 1  then
					text = tostring(math.floor(mX1))..","..tostring(math.floor(mY))
				end
				if  paralX.debugState == 2  then
					text = "visible: "..tostring(self.visible)
				end
				if  paralX.debugState == 3  then
					text = "sections: "..sectStr
				end
				if  paralX.debugState == 4  then
					text = "camDist: "..tostring(math.floor(self.camDistX))..","..tostring(math.floor(self.camDistY))
				end

				if  textbloxActive  then
					text = "<color 0xFFAAFFFF><i><b>"..self.name.."</i></b><color 0xFFFFFFFF><br>"..tostring(math.floor(mX1))..", "..tostring(math.floor(mY).."; vis: "..tostring(self.visible).."<br>Sections: "..sectStr.."<br>CamDist: "..tostring(math.floor(self.camDistX))..","..tostring(math.floor(self.camDistY)))
					props.halign = textblox.HALIGN_MID
					props.valign = textblox.VALIGN_MID
					props.bind = textblox.BIND_SCREEN
					props.z = 4.1
				end

				debugText (text, props)
			end
		end


		-- Draw
		if  self.visible  then
			if  self.useGl  then
				local alphaBlend = {1,1,1,self.alpha}
				if  self.color ~= nil  then
					alphaBlend = {self.color[1], self.color[2], self.color[3], self.color[4]*self.alpha}
				end
				local newUVs = rectPointsXYWH(0,math.floor(self.animFrame)/self.frames, 1,1/self.frames)

				local allVerts, allUVs = {},{}

				local drawProps = {color=alphaBlend,
				                   texture=self.image,
				                   priority=self.priority,
				                   shader=self.shader,
				                   attributes=self.attributes,
				                   uniforms=self.uniforms,
				                   opacity=self.alpha}

				for k=1,numTilesX do
					for l=1,numTilesY do
						local x1 = mX + (k-1-self.wrapFixX)*(w+self.gapX)
						local y1 = mY + (l-1-self.wrapFixY)*(h+self.gapY)

						local newVerts = rectPointsXYWH(x1,y1,w,h)
						for  i=1,#newVerts  do
							allVerts[#allVerts+1] = newVerts[i]
							allUVs[#allUVs+1] = newUVs[i]
						end
					end
				end
				drawProps.vertexCoords  = allVerts
				drawProps.textureCoords = allUVs
				Graphics.glDraw (drawProps)


			else
				local drawProps = {x=mX, y=mY, type=RTYPE_IMAGE,
				                   image=self.image,
				                   --isSceneCoordinates=true,
				                   priority=self.priority,
				                   sourceX=0, sourceY=h*math.floor(self.animFrame),
				                   sourceHeight=h, opacity=self.alpha}

				for k=1,numTilesX do
					for l=1,numTilesY do
						drawProps.x = mX + (k-1-self.wrapFixX)*(w+self.gapX)
						drawProps.y = mY + (l-1-self.wrapFixY)*(h+self.gapY)
						Graphics.draw (drawProps)
					end
				end
			end
		end

	end
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
	
	-- Debug
	if  paralX.debug  then
		local props = {x=0.5*cam.width, y=0.5*cam.height}
		local text = "Current section: "..tostring(camSect)
		if  textbloxActive  then
			text = "<b>Current section: "..tostring(camSect).."</b>"
			props.halign = textblox.HALIGN_MID
			props.valign = textblox.VALIGN_MID
			props.bind = textblox.BIND_SCREEN
			props.z = 4.1
		end

		debugText (text, props)
	end
end



function paralX.onStart ()
	for i=1, 21  do
		local newRect = newRECTd()
		newRect.left, newRect.top, newRect.bottom, newRect.right = getOrigSectionBounds(i)
		origBounds[i] = newRect
	end
end


function paralX.onKeyboardPress (vk)
	if  vk == VK_DOWN  then
		paralX.debugState = (paralX.debugState+1) %5
	end
end


function paralX.onLoop ()
	for k,v in pairs(indexedParallaxes) do
		v:update ()
	end
end

function paralX.onCameraUpdate (cameraIndex)
	updateCameraSections (cameraIndex)
	
	for k,v in pairs(indexedParallaxes) do
		v:draw (cameraIndex)
	end
end


return paralX;