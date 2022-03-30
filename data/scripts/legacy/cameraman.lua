--***************************************************************************************
--** cameraman.lua                                                                     **
--** v0.3.1                                                                            **
--** Documentation: http://engine.wohlnet.ru/pgewiki/cameraman.lua                     **
--***************************************************************************************

local cameraman = {}

--**************
--** TO-DO    **
--**************
--[[
    - Further testing
    - 2-player mode compatibility
    - There was something else but I forgot
--]]



--**************
--** OVERVIEW **
--**************
--[[
    cameraman is a helper library written to simplify camera scripting in LunaLua/SMBX 2.0.
 
    This library works by creating wrapper objects for cameras.
    You may then use those to alter the behavior and tracking of the wrapped camera.
--]]


--****************************************
--** CONSTANTS AND OTHER IMPORTANT VARS **
--****************************************

cameraman.SCREEN = {width=800, height=600}
cameraman.EASE   = {
                    LINEAR=function(t)     return t;          end,

                    QUAD=function(t)       return t*t;        end,

                    CUBIC=function(t)      return t*t*t;      end,

                    QUART=function(t)      return t*t*t*t;    end,

                    QUINT=function(t)      return t*t*t*t*t;  end,

                    SIN=function(t)        return 1-(math.sin(1-t) * (math.pi*0.5));     end,

                    BACK=function(t)       return (t*t*t) - 0.25*t*math.sin(t*math.pi);  end,
                    BACK2=function(t)      return (t*t*t) - 0.50*t*math.sin(t*math.pi);  end,
                    BACK3=function(t)      return (t*t*t) - 0.75*t*math.sin(t*math.pi);  end,
                    BACK4=function(t)      return (t*t*t) - 1.00*t*math.sin(t*math.pi);  end,
                    BACK5=function(t)      return (t*t*t) - 1.25*t*math.sin(t*math.pi);  end,
                   }


local vertMods    = {zoom=1, xScale=1, yScale=1, angle=1}
local camReadonly = {xScaleTotal=1, yScaleTotal=1, xMid=1, yMid=1, left=1, top=1, right=1, bottom=1}
local playerInfo  = {}

cameraman.debug = false
local textblox      = require("textblox")
--local console       = require("console")
local playerManager = require("playerManager")


--**************************
--** REGISTER USED EVENTS **
--**************************

registerEvent(cameraman, "onStart", "onStartStart", true)
registerEvent(cameraman, "onStart", "onStartEnd", false)
registerEvent(cameraman, "onTick", "onTick", false)
registerEvent(cameraman, "onCameraUpdate", "onCameraUpdate", true)
registerEvent(cameraman, "onDraw", "onDraw", false)


--***********************
--** UTILITY FUNCTIONS **
--***********************

-- Lerp and inverse lerp
local function lerp (minVal, maxVal, percentVal)
	return minVal + (maxVal - minVal) * percentVal
end
local function invLerp (minVal, maxVal, amountVal)                   
	return  math.min(1.00000, math.max(0.0000, math.abs(amountVal-minVal) / math.abs(maxVal - minVal)))
end

-- Get the tracked center of the object, accounting for player objects with variable-height powerup states
local function getTrackedCenter (obj)
	-- Get object's position
	local w = obj.width   or  0
	local h = obj.height  or  0 

	local objX = obj.x + 0.5*w
	local objY = obj.y + 0.5*h

	-- Correct for player objects
	if  obj.powerup ~= nil  then
		local playerSet = PlayerSettings.get(playerInfo[obj.character].base, PLAYER_BIG)
		objY = obj.y + obj.height - 0.5*playerSet.hitboxHeight
	end

	return objX,objY
end

-- Point scale
local function scalePoints (pts, x,y, xScale, yScale)
	local newPts = {}

	-- Scale points
	for i=1, (#pts), 2  do
		local lx = pts[i]-x
		local ly = pts[i+1]-y
		local newX = x + lx*xScale
		local newY = y + ly*yScale

		newPts[i],newPts[i+1] = newX,newY
	end

	return newPts;
end

-- Point rotation
local function rotatePoints (pts, x,y, angle)
	local newPts = {}

	local s = math.sin(angle)
	local c = math.cos(angle)

	-- Rotate points
	for i=1, (#pts), 2  do
		local lx = pts[i]-x
		local ly = pts[i+1]-y
		local newX = lx*c - ly*s
		local newY = lx*s + ly*c

		newPts[i],newPts[i+1] = newX+x,newY+y
	end

	return newPts;
end

-- Easing
local function easeInOutFormula (t, inFormula, outFormula)
	inFormula = inFormula    or  cameraman.EASE.LINEAR
	outFormula = outFormula  or  cameraman.EASE.LINEAR

	if  t < 0.5  then
		local result = inFormula (2*t)
		return (result*0.5)

	else
		local result = 1-outFormula (1-(2*(t-0.5)))
		return (result*0.5) + 0.5
	end
end

-- Debug
local function debugLog (str)
	if  cameraman.debug  then
		--Misc.dialog(str)
		--console.print(str)
	end
end


--*****************
--** EXCAM CLASS **
--*****************

local ExCamCache = {}
local ExCam = {}

function ExCam.__index(obj,key)
	if      (key == "xScaleTotal")   then
		local a=obj.zoom
		local b=obj.xScale
		return a*b
	elseif  (key == "yScaleTotal")   then
		local a=obj.zoom
		local b=obj.yScale
		return a*b
	elseif  (key == "width")         then
		local a=obj.cam.width
		return a
	elseif  (key == "zoomedWidth")   then
		local a=obj.cam.width
		local b=1/obj.xScaleTotal
		return a*b
	elseif  (key == "height")        then
		local a=obj.cam.height
		return a
	elseif  (key == "zoomedHeight")  then
		local a=obj.cam.height
		local b=1/obj.yScaleTotal
		return a*b
	
	--[[elseif  (key == "x") then
		return obj.cam.x + obj.cam.width*0.5;
	elseif  (key == "y") then
		return obj.cam.y + obj.cam.height*0.5;]]

	elseif  (key == "left")          then
		local a = obj.x - (obj.width*0.5) + obj.xOffset
		return a;
	elseif  (key == "zoomedLeft")    then
		local a = obj.x - (obj.zoomedWidth*0.5) + obj.xOffset
		return a;

	elseif  (key == "right")         then
		return obj.left + obj.width
	elseif  (key == "zoomedRight")   then
		return obj.zoomedLeft + obj.zoomedWidth

	elseif  (key == "top")           then
		local a = obj.y - (obj.height*0.5) + obj.yOffset
		return a;
	elseif  (key == "zoomedTop")     then
		local a = obj.y - (obj.zoomedHeight*0.5) + obj.yOffset
		return a;

	elseif  (key == "bottom")        then
		return obj.top + obj.height
	elseif  (key == "zoomedBottom")  then
		return obj.zoomedTop + obj.zoomedHeight

	elseif  (key == "xMid")          then
		return 0.5*(obj.left + obj.right)
	elseif  (key == "yMid")          then
		return 0.5*(obj.top + obj.bottom)

	elseif  (key == "_type")         then
		return "excamera";

	elseif  (key == "meta")          then
		return ExCam;

	elseif  (vertMods[key] ~= nil)  then
		return rawget (obj, "_"..key)

	else
		return rawget (ExCam, key)
	end
end

function ExCam.__newindex(obj,key,val)
	if     (camReadonly[key] ~= nil)  then 
		error ("The ExCam class' "..key.." property is read-only.");

	elseif  (vertMods[key] ~= nil)    then
		rawset (obj, "vertsDirty", true)
		rawset (obj, "_"..key, val)

	elseif (key == "_type")           then
		error("Cannot set the type of ExCam objects.",2);

	elseif (key == "width"  or  key == "height")  then
		error("Cannot set the width or height of ExCam objects.  Use the scale properties or change the size of the wrapped camera instead.",2);

	--[[elseif (key == "x") then
		obj.cam.x = val - obj.cam.width*0.5;
	elseif (key == "y") then
		obj.cam.y = val - obj.cam.height*0.5;]]
		
	else
		-- Basic rawset
		rawset(obj, key, val);
	end
end


------ Constructor/wrap ------
function cameraman.wrap (args)
	local p

	-- If the provided camera is already wrapped, get the ExCam from the cache but update the camera and camId just in case
	if ExCamCache[args.camId] ~= nil  then
		p = ExCamCache[args.camId]
		p.cam = args.cam  or  p.cam
		p.camId = args.camId  or  p.camId
		--debugLog("Camera already wrapped, indexed under [CAN'T TOSTRING CAMERAS]")

	else
		-- Set up the table & metatable stuff
		p = {}

		-- Wrap camera
		p.cam = args.cam
		p.camId = args.camId

		local cams = Camera.get()
		if  p.cam == nil  and  p.camId == nil  then
			error("Provide either a camera object or number when calling cameraman.wrap")

		elseif  p.cam == nil  then
			p.cam = cams[p.camId]

		elseif  p.camId == nil  then
			for k,v in pairs (cams) do
				if  v == p.cam  then
					p.camId = k
					break;
				end
			end
		end

		debugLog ("Creating new ExCam, id="..tostring(p.camId)..", cam=[CAN'T TOSTRING CAMERAS]")


		-- Properties
		p.targets = args.targets  or  Player(p.camId)

		p.autoSize = args.autoSize
		if  p.autoSize == nil  then  p.autoSize = true;  end;

		p.x       = p.cam.x + p.cam.width*0.5
		p.y       = p.cam.y + p.cam.height*0.5

		p.xOffset = 0
		p.yOffset = 0

		p._zoom   = 1
		p._xScale = 1
		p._yScale = 1

		p._angle  = 0

		p.sectionBoundX = true
		p.sectionBoundY = true

		p.active = true


		-- Submodules
		p.tracking = {
		              midX = 0,
		              midY = 0
		             }

		-- Control vars
		p.newState         = nil
		p.queue            = {}
		p.buffer           = Graphics.CaptureBuffer(cameraman.SCREEN.width, cameraman.SCREEN.height)
		p.automatic        = true
		p.routine          = nil
		p.glVerts          = {}
		p.vertsDirty       = true
		p.isTransitioning  = false

		-- Metatable and cache 
		setmetatable (p, ExCam)
		ExCamCache[p.camId] = p
	end

	-- Return
	return p
end


------ Coroutines ------
-- Set the state for an ExCam without first calling :Abort()
local function setWithoutAbort (obj, args)
	for  k,v in pairs(args)  do
		obj[k] = v
	end
end

--[[ reminder to self: cor_easeState _always_ eases position even if the args aren't defined because it 
     always sets both oldstate.x/y and .newState.x/y
--]]

local function cor_easeState (obj, args)
	-- Shallow copy the properties and fill in the blanks with the object's old properties
	local oldstate = {}
	obj.newState = {}
	for  _,k in ipairs{"x","y", "xOffset","yOffset", "targets", "angle", "zoom", "xScale","yScale", "sectionBoundX","sectionBoundY"}  do
		oldstate[k]     =              obj[k]
		if(args[k] == nil) then
			obj.newState[k] = obj[k]
		else
			obj.newState[k] = args[k]
		end
	end

	--[[
	obj.newState.sectionBoundX = args.sectionBoundX
	if  obj.newState.sectionBoundX == nil  then  obj.newState.sectionBoundX = obj.sectionBoundX;  end;

	obj.newState.sectionBoundY = args.sectionBoundY
	if  obj.newState.sectionBoundX == nil  then  obj.newState.sectionBoundY = obj.sectionBoundY;  end;
	]]


	-- Wait for the delay
	local delay = args.delay  or  0
	debugLog ("Beginning transition coroutine, delaying for "..tostring(delay).." seconds")
	Routine.wait(delay, args.runWhilePaused)

	-- Set up the easing-related stuff
	local eIn  = args.easeIn   or  args.easeBoth  or  args.ease 
	local eOut = args.easeOut  or  args.easeBoth  or  args.ease 

	-- Position management stuff
	oldstate.x = obj.tracking.midX-- + oldstate.xOffset
	oldstate.y = obj.tracking.midY-- + oldstate.yOffset

	---[[
	if  oldstate.sectionBoundX == true  then
		oldstate.x = obj:GetSectionClampedLeft(oldstate.x - 400)+400--obj.width*0.5) + obj.width*0.5
	end
	if  oldstate.sectionBoundY == true  then
		oldstate.y = obj:GetSectionClampedTop(oldstate.y - 300)+300--obj.height*0.5) + obj.height*0.5
	end
	--]]


	--oldstate.xOffset = 0
	--oldstate.yOffset = 0
	--oldstate.targets = {}

	if  args.x ~= nil  then  
		obj.tracking.midX = args.x
		obj.x = args.x
	end
	if  args.y ~= nil  then  
		obj.tracking.midY = args.y
		obj.y = args.y
	end

	-- Set the new targets in advance for easing to them
	obj.targets = obj.newState.targets

	-- Perform the transition
	obj.isTransitioning = true
	local totalTime = args.time  or  1
	local timeLeft = totalTime
	debugLog ("Delay done, starting "..tostring(timeLeft).."-second transition")

	while  (timeLeft > 0)  do

		-- Force the isTransitioning flag on
		obj.isTransitioning = true

		-- Progress time and calculate percent
		timeLeft = timeLeft - Routine.deltaTime
		local timePassed = totalTime - timeLeft
		local percent = timePassed/totalTime

		if  type(args.easeBoth) == "function"  or  type(args.easeIn) == "function"  or  type(args.easeOut) == "function"  then
			percent = easeInOutFormula(timePassed/totalTime, eIn, eOut)
		elseif  type(args.ease) == "function"  then
			percent = args.ease(timePassed/totalTime)
		end

		-- Ease properties
		for  k,v in pairs(obj.newState)  do
			if  k ~= "targets"  and  k~="sectionBoundX"  and  k~="sectionBoundY"  then
				obj[k] = lerp(oldstate[k], v, percent)
			end
		end

		-- Determine final positions for special cases
		local destX,destY = obj.newState.x, obj.newState.y

		-- Special handling for changing tracking targets
		if  obj.newState.targets ~= oldstate.targets  then
			destX = obj.tracking.midX
			destY = obj.tracking.midY
		end

		-- Special handling for section bounds clamping
		if  obj.newState.sectionBoundX == true  then
			destX = obj:GetSectionClampedLeft(destX - obj.width*0.5) + obj.width*0.5
		end
		if  obj.newState.sectionBoundY == true  then
			destY = obj:GetSectionClampedTop(destY - obj.height*0.5) + obj.height*0.5
		end

		-- Apply position lerps
		obj.x = lerp(oldstate.x, destX, percent)
		obj.y = lerp(oldstate.y, destY, percent)


		-- Yield
		--Misc.dialog("COR_EASE", obj.x)
		Routine.skip(args.runWhilePaused)
	end

	-- End transition, apply all of the new properties
	debugLog ("Transition done")
	setWithoutAbort (obj, obj.newState)
	obj.x = obj.tracking.midX
	obj.y = obj.tracking.midY
	obj.sectionBoundX = obj.newState.sectionBoundX
	obj.sectionBoundY = obj.newState.sectionBoundY
	obj.isTransitioning = false
	obj.newState = nil
	obj.routine = nil
end


------ Setters ------

-- Transitions the ExCam's properties back to the defaults
function ExCam:Reset (args)
	if  args == nil  then
		args = {}
	end
	local resetArgs = table.join (args, {zoom=1, angle=0, xOffset=0, yOffset=0, sectionBoundX=true, sectionBoundY=true, targets=player})

	self:ClearQueue ()
	self:Transition (resetArgs)
end

-- Stops the current transition coroutine (if any), leaving the camera's state as it is mid-transition
function ExCam:Abort ()
	if self.routine ~= nil  then
		self.routine:abort()
		self.routine = nil
	end
	self.isTransitioning = false
	self.newState = nil
end

-- Stops the current transition coroutine (if any) and applies the new state
function ExCam:Finish ()
	if self.routine ~= nil  then
		setWithoutAbort (self, self.newState)
		self:Abort ()
		self.isTransitioning = false
		self.newState = nil
	end
end

-- Stops the current transition coroutine (if any) and immediately applies a new state
function ExCam:Set (args)
	self:Abort ()
	setWithoutAbort (self, args)
end

-- Stops the current transition coroutine (if any) and immediately starts transitioning to a new state
function ExCam:Transition (args)
	self:Abort()
	local cor = Routine.run(cor_easeState, self, args)
	self.routine = cor
end

-- Clear out the queue
function ExCam:ClearQueue ()
	self.queue = {}
end

-- Add a new state to the queue
function ExCam:Queue (args)
	table.insert(self.queue, args)
end


-- Getters
function ExCam:GetSectionClampedLeft (x)
	local pastBoundsX = self.width  - self.zoomedWidth
	return math.min(player.sectionObj.boundary.right-self.width+pastBoundsX*0.5, math.max(player.sectionObj.boundary.left-pastBoundsX*0.5, x))
end

function ExCam:GetSectionClampedTop (y)
	local pastBoundsY = self.height - self.zoomedHeight
	return math.min(player.sectionObj.boundary.bottom-self.height+pastBoundsY*0.5, math.max(player.sectionObj.boundary.top-pastBoundsY*0.5, y))
end

function ExCam:SceneToScreenPoint (x,y)
	local newPts = {x-self.cam.x, y-self.cam.y}
	newPts = scalePoints (newPts, 400,300, self.xScaleTotal,self.yScaleTotal)
	newPts = rotatePoints (newPts, 400,300, math.rad(self.angle))
	return newPts[1],newPts[2]
end

function ExCam:CameraToScreenPoint (x,y)
	local newPts = {x, y}
	newPts = rotatePoints (newPts, 400,300, math.rad(-self.angle))
	newPts = scalePoints (newPts, 400,300, 1/self.xScaleTotal,1/self.yScaleTotal)
	return newPts[1], newPts[2]
end

function ExCam:CameraToScenePoint (x,y)
	local newX,newY = self:CameraToScreenPoint (x,y)
	return newX+self.cam.x, newY+self.cam.y
end


-- Update
function ExCam:Update()
	--Misc.dialog ("UPDATE", "CAM ID:", self.camId, " ", "DOES SELF.CAM EXIST:", self.cam ~= nil, " ", "WIDTH:", self.width)
	if  self.cam == nil  then  
		return;
	end

	-- Update the current state/transitions between states based on the queue
	self:UpdateQueue ()

	-- Determine the center position of the current tracking target(s)
	self:UpdateTracking ()

	-- Position the camera based on the tracking position and offset
	self:UpdateCamPos ()

	-- Determine the verts for the gldraw rect based on zoom, scale and rotation
	self:UpdateTransforms ()
end


function ExCam:UpdateQueue()
	if  self.routine == nil  and  #self.queue > 0  then
		debugLog ("Starting a transition ("..tostring(#self.queue-1).." left in the queue)")
		local nextSet = self.queue[1]
		table.remove(self.queue, 1)
		self:Transition (nextSet)
	end
end

function ExCam:UpdateTracking()
	local targType = type(self.targets)

	-- If null, just use the current position
	if      targType == "nil"  then
		--windowDebug("NIL")
		self.tracking = {targets={}, midX=self.x, midY=self.y}

	elseif  targType == "table"  then

		-- If an empty list, just use the current position
		if     #self.targets == 0  then
			--windowDebug("TABLE 0")
			self.tracking = {targets={}, midX=self.x, midY=self.y}

		-- If a list of only one target, just use that target's position
		elseif #self.targets == 1  then
			--windowDebug("TABLE 1")
			local mX,mY = getTrackedCenter(self.targets[1])
			self.tracking = {targets=self.targets, midX=mX, midY=mY}

		-- If multiple, get the combined average position
		else
			local addedX,addedY = 0,0
			for  _,v in pairs(self.targets)  do
				-- Get the position
				local objX,objY = getTrackedCenter(v)

				-- Add the positions for averaging
				addedX = addedX + objX
				addedY = addedY + objY
			end

			-- Get the average
			--windowDebug("TABLE MULT")
			self.tracking = {targets=self.targets, midX=addedX/#self.targets, midY=addedY/#self.targets}
		end

	-- If not a list, assume a single object
	elseif  self.targets.x ~= nil  and  self.targets.width ~= nil  then
		--windowDebug("VALID OBJECT")
		local mX,mY = getTrackedCenter(self.targets)
		self.tracking = {targets={self.targets}, midX=mX, midY=mY}

	-- If all else fails, just use the current position
	else
		--windowDebug("INVALID OBJECT")
		self.tracking = {targets={}, midX=self.x, midY=self.y}
	end

	if  self.isTransitioning == false  then
		self.x = self.tracking.midX
		self.y = self.tracking.midY
	end
end

function ExCam:UpdateCamPos()

	--[[
	if  self.isTransitioning  then
		Misc.dialog ("UPDATE CAM POSITION", self.x)--"CAM ID:", self.camId, " ", "DOES SELF.CAM EXIST:", self.cam ~= nil, " ", "WIDTH:", self.width)
	end
	--]]

	if  self.active == true  then
		self.cam.x = self:GetSectionClampedLeft (self.left)
		if  self.sectionBoundX == false  or  (self.isTransitioning  and  self.newState.sectionBoundX == false)  then
			self.cam.x = self.left
		end

		self.cam.y = self:GetSectionClampedTop (self.top)
		if  self.sectionBoundY == false  or  (self.isTransitioning  and  self.newState.sectionBoundY == false)  then
			self.cam.y = self.top
		end
	end

end

function ExCam:UpdateTransforms()
	if  self.vertsDirty  then
		self.vertsDirty = false

		local newVerts = {0,          0, 
		                  self.width, 0,
		                  0,          self.height,

		                  self.width, 0,
		                  0,          self.height,
		                  self.width, self.height}


		if  self.zoom ~= 1  or  self.xScale ~= 1  or  self.yScale ~= 1  then
			newVerts = scalePoints (newVerts, self.width*0.5,self.height*0.5, self.xScaleTotal, self.yScaleTotal)
		end
		if  self.angle ~= 0  then
			newVerts = rotatePoints (newVerts, self.width*0.5,self.height*0.5, math.rad(self.angle))
		end

		self.glVerts = newVerts
	end
end


function ExCam:Draw ()
	local p = -0.000001;
	self.buffer:captureAt(p)

	Graphics.glDraw{primitive=Graphics.GL_TRIANGLES, vertexCoords={0,0,800,0,0,600,800,0,0,600,800,600}, color={0,0,0,1}, priority=p}
	Graphics.glDraw{primitive=Graphics.GL_TRIANGLES, textureCoords={0,0,1,0,0,1,1,0,0,1,1,1}, vertexCoords=self.glVerts, texture=self.buffer, priority=p}

	if  cameraman.debug  then
		textblox.printExt ("ID: "..tostring(self.camId).."<br>X: "..tostring(math.ceil(self.x)).."<br>Y: "..tostring(math.ceil(self.y))
		                                               .."<br>XOFF: "..tostring(self.xOffset).."<br>YOFF: "..tostring(self.yOffset)
		                                               .."<br>ZOOM: "..tostring(self.zoom)
		                                               .."<br>XSCALE: "..tostring(self.xScale).."<br>YSCALE: "..tostring(self.yScale)
		                                               .."<br>ANGLE: "..tostring(self.angle)
		                                               .."<br>X IS SECTION-BOUND: "..tostring(self.sectionBoundX)
		                                               .."<br>Y IS SECTION-BOUND: "..tostring(self.sectionBoundY)
		                                               .."<br>"
		                                               .."<br>MID-TRANSITION: "..tostring(self.isTransitioning)
		                                               .."<br>NEWSTATE TABLE: "..tostring(self.newState)
		                                               .."<br>ROUTINE SET: "..tostring(self.routine ~= nil)
		                                               .."<br>QUEUE SIZE: "..tostring(#self.queue), {x=10,y=10,z=0.1, font=textblox.defaultSpritefont[3][1]})

		-- Draw tracking shapes
		local cX,cY = self:SceneToScreenPoint(self.x,self.y)
		for  k,v in pairs(self.tracking.targets)  do
			local mX1,mY1 = getTrackedCenter(v)
			local mX,mY = self:SceneToScreenPoint(mX1,mY1)

			local vertexPts   = {cX,    cY,
			                    mX-12,  mY,
			                    mX+12,  mY,

			                    cX,     cY,
			                    mX,     mY-12,
			                    mX,     mY+12,

			                    cX,     cY,
			                    mX-12,  mY,
			                    mX+12,  mY,

			                    cX,     cY,
			                    mX,     mY-12,
			                    mX,     mY+12}

			Graphics.glDraw{primitive=Graphics.GL_TRIANGLES, vertexCoords=vertexPts, color={1,1,1,0.25}, priority=0, sceneCoords=false}
		end
	end
end

function cameraman.onStartStart()
	debugLog("<color rainbow>cameraman.lua debugging enabled")
	playerInfo = playerManager.getCharacters()

	--[[  commenting this out until we can figure out why this stuff ain't initializing properly

	if(#playerInfo == 0) then
		return;
	end

	for camIndex = 1,#Camera.get() do
		local camObj = Camera.get()[camIndex]
		local ex = cameraman.wrap{cam=camObj, camId=camIndex}
		--ex:Update()

		if  camIndex <= #Player.get()  then
			cameraman.playerCam[camIndex] = ex
		end
	end
	--]]
end
function cameraman.onStartEnd()
	debugLog ("START END")
	playerInfo = playerManager.getCharacters()

	--[[
	if(#playerInfo == 0) then
		return;
	end

	for camIndex = 1,#Camera.get() do
		local camObj = Camera.get()[camIndex]
		local ex = cameraman.wrap{cam=camObj, camId=camIndex}
		--ex:Update()

		if  camIndex <= #Player.get()  then
			cameraman.playerCam[camIndex] = ex
		end
	end
	--]]
end


cameraman.playerCam = {}

function cameraman.onCameraUpdate (camIndex)
	if(#playerInfo == 0) then
		return;
	end
	
	local camObj = Camera(camIndex)
	local ex = cameraman.wrap{cam=camObj, camId=camIndex}
	ex:Update()

	if  camIndex <= #Player.get()  then
		cameraman.playerCam[camIndex] = ex
	end
	
	if  ex.active == true  then
		ex:Draw()
	end
end
--[[
function cameraman.onDraw ()
	for  k,v in pairs(ExCamCache)  do
	end

end]]

local lastCacheTally = 0
function cameraman.onTick ()
	local tally = 0
	for  k,v in pairs (ExCamCache)  do
		tally = tally+1
	end

	if  lastCacheTally ~= tally  then
		lastCacheTally = tally
		debugLog("ExCamCache size = "..tostring(tally))
	end
end


return cameraman