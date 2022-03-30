---------------------------------------------------
-- ACTOR CLASS LIBRARY THING                     --
-- blame rockythechao                            --
-- v1.0.1                                        --
--                                               --
-- let me know when the autodocs format is       --
-- finalized and I'll fix up the documentation   --
-- in this thing accordingly                     --
---------------------------------------------------

local animatx = require("animatx2")
local rng = require("rng")
local colliders = require("colliders")



------------------------------------------------------------------------
-- Utility functions
------------------------------------------------------------------------
local mathlerp = math.lerp  or  function(a,b,t)
	return a*(1-t) + b*t;
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



----------------------------------------------
-- Actor class
----------------------------------------------
--[[
    The Actor class is a wrapper class for animatx2 AnimInst objects that provides additional animation management and simulated physics.
    Actors are defined via 


        -------------------------------------------------------------------------------------------------------------------------------
        STATIC FUNCTIONS
        -------------------------------------------------------------------------------------------------------------------------------
        Functions                Return type                Description
        -------------------------------------------------------------------------------------------------------------------------------
        Actor{args}              Actor instance             Create a new Actor object.




        -------------------------------------------------------------------------------------------------------------------------------
        CONSTRUCTOR
        -------------------------------------------------------------------------------------------------------------------------------
        Argument                 Type                    Required        Default                     Description
        -------------------------------------------------------------------------------------------------------------------------------
        animSet                  animatx2 AnimSet        X               ---                         The AnimSet from which the AnimInst object will be created.

        state                    ActorState                              empty string                The ActorState that the Actor starts in.

        stateDefs                named table of                          empty table                 The different ActorStates that the Actor can use.
                                 ActorStates                             

        collider                 Box collider                            auto-generated              A Box collider object to serve as the Actor's collider for physics
                                                                         collider based on
                                                                         AnimSet dimensions



        -------------------------------------------------------------------------------------------------------------------------------
        ACTOR FIELDS
        -------------------------------------------------------------------------------------------------------------------------------
        Fields                   Type                    Read-only?    Description
        -------------------------------------------------------------------------------------------------------------------------------
        gfx                      AnimInst                              A reference to the Actor's animatx2 AnimInst.
        
        collider                 Box Colliders                         The Actor's collider object.

        left                     number                  X             The left edge of the collider
        right                    number                  X             The right edge of the collider
        top                      number                  X             The top edge of the collider
        bottom                   number                  X             The bottom edge of the collider
        xMid                     number                  X             The center X position of the collider
        yMid                     number                  X             The center Y position of the collider

        state                    string                                The current ActorState name.

        stateDefs                table of                              The defined ActorStates for the Actor.
                                 ActorStates                           

        direction                LunaLua direction                     The direction the actor is facing;  if set to DIR_RANDOM, will randomly choose
                                 constant                              DIR_LEFT or DIR_RIGHT.

        directionMirror          boolean                               True by default, if false the sprite is not flipped with the direction

        <x/y>Scale               number                                The <horizontal/vertical> scale of the Actor;  this affects both the gfx and collider.

        scale                    number                                An additional uniform scale multiplier for Actor;  this affects both the gfx and collider.

        speed<X/Y>               number                                The actor's <horizontal/vertical> speed.

        accel<X/Y>               number                                The actor's <horizontal/vertical> acceleration.

        maxSpeed<X/Y>            number                                The upper limit of the actor's <horizontal/vertical> speed.

        minSpeed<X/Y>            number                                The lower limit of the actor's <horizontal/vertical> speed.

        bounds                   RECTd or table                        If defined, the Actor's position is clamped to the area of this rectangle.

        canTurn                  boolean                               If false, changing the Actor's direction is disabled.

        onStart                  function                              If defined, this function is called immediately after the Actor is created.

        onTick                   function                              If defined, this function is called every tick before the physics are processed.

        onPhysicsEnd             function                              If defined, this function is called every tick after the physics are processed.

        onGfxEnd                 function                              If defined, this function is called every tick after the graphics are updated.

        onDrawEnd                 function                             If defined, this function is called every tick after the graphics are rendered.



        An ActorState is a set of functions and properties representing a distinct physical or behavioral state for the Actor. 
        It is not a formal class but merely a table of named arguments.

        -------------------------------------------------------------------------------------------------------------------------------
        ACTORSTATE FIELDS
        -------------------------------------------------------------------------------------------------------------------------------
        Fields                   Type                    Description
        -------------------------------------------------------------------------------------------------------------------------------
        onStart                  function                A function called when the Actor switches to this ActorState.  Passes in itself 
                                                         as the first argument and the Actor as the second.

        onTick                   function                A function called every tick while in this ActorState.  Passes in itself 
                                                         as the first argument and the Actor as the second.

        onExit                   function                A function called when the Actor switches away from this state.  Passes in itself 
                                                         as the first argument and the Actor as the second.

        animState                string or table of      The animation state(s) that the Actor's AnimInst switches to upon
                                 strings                 entering the ActorState.  If a table is given, a random
                                                         sequence is selected.  If undefined, an empty table, or an
                                                         invalid sequence name, the animation state is not set


        THE FOLLOWING PROPERTIES OVERRIDE THE CORRESPONDING FIELDS OF THE ACTOR CLASS
        (ADD "init_" TO MAKE THEM ONLY OVERWRITE UPON ENTERING THE ACTORSTATE):

        direction
        <min/max>Speed<X/Y>
        speed<X/Y>
        accel<X/Y>
        canTurn


        Method Functions                      Return type             Description
        -------------------------------------------------------------------------------------------------------------------------------


--]]


local Actor = {}     -- class object
local ActorMT = {}   -- instance metatable

local params = {
	underscored = {direction=1},
	readonly = {gfxwidth=1, gfxheight=1, xScaleTotal=1,yScaleTotal=1, speedXSign=1,speedYSign=1, accelXSign=1,accelYSign=1, colliderDirty=1, contactUp=1, contactDown=1, contactLeft=1, contactRight=1},
	static = {},

	general = {
		fields = {
			x=1,y=1,
			z=1,depth=1,priority=1,
			xScale=1, yScale=1, scale=1,

			directionMirror=1,

			xOffsetGfx=1,yOffsetGfx=1,

			-- actorstate
			state=1, stateDefs=1,

			-- collision
			xAlign=1,yAlign=1,
			width=1, height=1,bounds=1,

			-- events
			onTick=1,onPhysicsEnd=1,onGfxEnd=1,onDrawEnd=1,

			-- debug
			name=1,
			debug=1
		},
		defaults = {
			x=-999999,y=-999999,z=0,
			xScale=1,yScale=1,scale=1,
			xOffsetGfx=0, yOffsetGfx=0,

			xAlign=animatx.ALIGN.MID,
			yAlign=animatx.ALIGN.BOTTOM,

			directionMirror=true,
			debug=false
		},
		aliases = {priority="z", depth="z"}
	},

	gfx = {
		fields = {
			animSet=1,

			xScale=1, yScale=1, scale=1,

			xRotate=1, yRotate=1,
			angle=1,

			animState=1,

			sceneCoords=1
		},
		defaults = {
			xScale=1, yScale=1, scale=2,
			sceneCoords=true
		},
		aliases = {
			sheet="image", animState="state"
		}
	},

	physics = {
		fields = {  -- if == 2, are default properties when not in a state
			direction=1,

			accelX=1,accelY=1,
			frictionX=1,frictionY=1,
			speedX=1,speedY=1,
			maxSpeedX=1, maxSpeedY=1, --maxSpeedFwd=2,
			minSpeedX=1, minSpeedY=1, --minSpeedFwd=2, 
			canTurn=1, canCollide=1
		},
		defaults = {
			direction=DIR_RIGHT,

			accelX=0,accelY=0,
			frictionX=0,frictionY=0,
			speedX=0,speedY=0,
			minSpeedX=-math.huge,minSpeedY=-math.huge,
			maxSpeedX=math.huge,maxSpeedY=math.huge,
			canTurn=true, canCollide=true
		},
		aliases = {}
	}
}


local function filterArgs (groupName, args)
	local filtered = {}

	-- Process the properties in this group
	for  k,v in pairs(params[groupName].fields)  do

		-- If the property is an alias, change the key to that of the aliased property
		local key = k
		if  params[groupName].aliases[k] ~= nil  then
			key = params[groupName].aliases[k]
		end

		-- Apply any default value if the property isn't defined in the arguments
		local val = args[key]
		if  val == nil  then
			val = params[groupName].defaults[key]
		end

		-- Apply underscores where necessary
		if  params.readonly[key] ~= nil  or  params.underscored[key] ~= nil  then
			key = "_"..key
		end
		filtered[key] = val
	end

	return filtered;
end


-----------------------------------------------------
-- METAMETHODS                                     
-----------------------------------------------------
do

	ActorMT.__type = "Actor object"

	-----------------------------------------------------
	-- READ HANDLING                                   
	-----------------------------------------------------
	function ActorMT.__index(obj,key)

		-- Check for index aliases
		if      (params.gfx.aliases[key] ~= nil)       then
			return obj.gfx[params.gfx.aliases[key]];

		elseif  (params.physics.aliases[key] ~= nil)   then
			return obj[params.physics.aliases[key]];

		elseif  (params.general.aliases[key] ~= nil)   then
			return obj[params.general.aliases[key]];


		-- Special properties
		elseif  (key == "left")          then
			return obj.collider.x
		elseif  (key == "top")           then
			return obj.collider.y
		elseif  (key == "right")         then
			return obj.collider.x + obj.collider.width
		elseif  (key == "bottom")        then
			return obj.collider.y + obj.collider.height

		elseif  (key == "xMid")          then
			return obj.collider.x + obj.collider.width*0.5
		elseif  (key == "yMid")          then
			return obj.collider.y + obj.collider.height*0.5

		elseif  (key == "contactUp")     then
			return (obj.bounds ~= nil  and  obj.bounds.top ~= nil  and  obj.top <= obj.bounds.top)

		elseif  (key == "contactDown")   then
			return (obj.bounds ~= nil  and  obj.bounds.bottom ~= nil  and  obj.bottom >= obj.bounds.bottom)

		elseif  (key == "contactLeft")   then
			return (obj.bounds ~= nil  and  obj.bounds.left ~= nil  and  obj.left <= obj.bounds.left)

		elseif  (key == "contactRight")  then
			return (obj.bounds ~= nil  and  obj.bounds.right ~= nil  and  obj.right >= obj.bounds.right)

		elseif  (key == "direction")   then
			return obj._direction

		elseif  (key == "speedXSign")  then
			if  obj.speedX == 0  then  
				return 0
			else
				return obj.speedX/math.abs(obj.speedX)
			end
		elseif  (key == "speedYSign")  then
			if  obj.speedY == 0  then  
				return 0
			else
				return obj.speedY/math.abs(obj.speedY)
			end

		elseif  (key == "accelXSign")  then
			if  obj.accelX == 0  then  
				return 0
			else
				return obj.accelX/math.abs(obj.accelX)
			end
		elseif  (key == "accelYSign")  then
			if  obj.accelY == 0  then  
				return 0
			else
				return obj.accelY/math.abs(obj.accelY)
			end

		elseif  (key == "xScaleTotal") then
			local a=obj.scale
			local b=obj.xScale
			return a*b
		elseif  (key == "yScaleTotal") then
			local a=obj.scale
			local b=obj.yScale
			return a*b

		else -- basic rawget on class
			return rawget(Actor, key)
		end
	end


	-----------------------------------------------------
	-- WRITE HANDLING                                  --
	-----------------------------------------------------
	function ActorMT.__newindex (obj,key,val)


		-- Check for aliases
		if      (params.gfx.aliases[key] ~= nil)       then
			obj.gfx[params.gfx.aliases[key]] = val;

		elseif  (params.physics.aliases[key] ~= nil)   then
			obj[params.physics.aliases[key]] = val;

		elseif  (params.general.aliases[key] ~= nil)   then
			return obj[params.general.aliases[key]];


		-- Static properties
		elseif  (params.static[key] ~= nil  and  obj ~= Actor)  then
			error ("The "..key.." property is static.");


		-- Read-only properties
		elseif  (params.readonly[key] ~= nil)  then
			error ("The Actor class' "..key.." property is read-only.");

		elseif  (key == "_meta") then
			error("Cannot override the Actor metatable.", 2);


		-- Direction
		elseif  (key == "direction")   then

			-- canTurn
			if  obj.canTurn ~= false   then
				if  val == DIR_RANDOM  then
					val = rng.randomEntry{DIR_LEFT,DIR_RIGHT}

				else
					rawset (obj, "_direction", val)
				end
			end


		else
			-- Basic rawset on instance
			rawset(obj, key, val);
		end
	end


	-----------------------------------------------------
	-- CONSTRUCTOR                                     --
	-----------------------------------------------------
	setmetatable (Actor, {__call = function (class, args)

		-- Create the actor instance and load the general Actor args
		local inst = filterArgs("general", args)
		inst.stateDefs = inst.stateDefs  or  {}


		-- Get the gfx properties
		local animArgs = filterArgs("gfx", args)
		animArgs.xAlign = args.xAlignGfx  or  animatx.ALIGN.MID
		animArgs.yAlign = args.yAlignGfx  or  animatx.ALIGN.BOTTOM


		-- Create the AnimInst and apply the gfx properties
		inst.gfx = args.animSet:Instance (animArgs)
		inst.gfx.object = inst


		-- Get the width and height (based on the gfx if necessary)
		inst.width = args.width  or  inst.gfx.set.width
		inst.height = args.height  or  inst.gfx.set.height

		-- Create the collider
		inst.collider = args.collider  or  colliders.Box(inst.x,inst.y, inst.width,inst.height)
		
		-- Process the physics properties
		inst._defaultPhysics = {}
		for  k,v in pairs (params.physics.fields)  do
			if  v == 2  then
				inst._defaultPhysics[k] = args[k]  or  params.physics.defaults[k]
			end
			inst[k] = args[k]  or  params.physics.defaults[k]
		end


		-- Hacky fix for direction and other such properties
		for  k,_ in pairs (params.underscored)  do
			if  inst[k] ~= nil  and  inst["_"..k] == nil  then
				inst["_"..k] = inst[k]
				inst[k] = nil
			end
		end


		-- Assign the metatable
		setmetatable(inst, ActorMT)

		-- Take advantage of the metatable to initialize misc stuff
		inst.direction = args.direction

		-- Call an onStart function if one was provided
		if  inst.onStart ~= nil  then
			inst:onStart()
		end

		-- Return
		return inst;
	end
	})
end


-----------------------------------------------------
-- GENERAL METHOD FUNCTIONS                        --
-----------------------------------------------------
do
	function Actor:_pickAnimState (propsDef, name)
		local typeof = type(propsDef.animState)

		if      typeof == "table"  then
			return rng.randomEntry(propsDef.animState)

		elseif  typeof == "string"  or  typeof == "nil"  then
			return propsDef.animState

		else
			error([[The animState property of ActorState "]]..self.state..[[" needs to be a string, a table of strings, or nil.]])
			return nil
		end
	end
end


-----------------------------------------------------
-- STATE MANAGEMENT                                --
-----------------------------------------------------
do
	function Actor:StartState (newState)
		-- End current state
		if  self.state ~= nil  then
			self:EndState ()
		end

		-- Change the state
		self.state = newState
		self._stateProps = {}


		-- If a valid state, apply functions and properties
		local propsDef = self.stateDefs[self.state]
		if  propsDef ~= nil  then

			-- Run onStart if defined
			if  propsDef.onStart ~= nil  then
				propsDef.onStart(propsDef, self)
			end

			-- Apply animation state
			local animState = Actor:_pickAnimState (propsDef, self.state)
			if  animState ~= nil  then
				self.gfx:startState {state=animState, force=true, resetTimer=true, commands=true, name=self.name, source="STARTING ACTOR STATE "..newState}
			end

			-- Copy the persistent properties to a cache, filtering out functions and applying init_ props immediately
			for  k,v in pairs (propsDef)  do
				if  type(v) ~= "function"  and  k ~= "animState"  and  k~= "data"  then
					local _,_,isInit,propertyName = string.find(k, "(init%_*)(.*)")
					if  isInit ~= nil  then
						self[propertyName] = v
					else
						self._stateProps[propertyName] = v
					end
				end
			end
		end
	end

	function Actor:EndState ()
		local props = self._stateProps
		if  props ~= nil  then
			if  props.onExit ~= nil  then
				props.onExit(props,self)
			end
		end

		self.state = nil
		self._stateEvent = nil
	end
end


	-----------------------------------------------------
	-- EVENTS                                          --
	-----------------------------------------------------
do
	function Actor:update()
		if  self.onTick ~= nil  then
			self:onTick()
		end

		self:updateState()
		self:updatePhysics()
		if  self.onPhysicsEnd ~= nil  then
			self:onPhysicsEnd()
		end

		self:updateGfx()
		if  self.onGfxEnd ~= nil  then
			self:onGfxEnd()
		end
	end

	function Actor:updateState()
		-- Apply default physics
		for k,v in pairs(self._defaultPhysics)  do
			self[k] = self[k]  or  v
		end

		-- Apply state overrides
		local props = self.stateDefs[self.state]
		if  props ~= nil  then

			-- Apply property overrides
			for k,v in pairs(props)  do
				if  type(v) ~= "function"  then
					self[k] = v
				end
			end

			-- Run event
			if  props.onTick ~= nil  then
				props.onTick(props,self)
			end
		end
	end

	function Actor:updatePhysics()

		-- updated speeds
		for  _,v in ipairs {"x","y"}  do
			local q = {}
			local upperV     = string.upper(v)

			q.spd            = self["speed"..upperV]
			q.absSpd         = math.abs(q.spd)
			q.fric           = self["friction"..upperV]
			q.accel          = self["accel"..upperV]
			q.absAccel       = math.abs(q.accel)
			q.minSpd         = self["minSpeed"..upperV]
			q.maxSpd         = self["maxSpeed"..upperV]


			--Misc.dialog(q)


			-- Apply friction and acceleration based on current speed and accel
			if  q.spd == 0  then
				if  q.fric < q.absAccel  then
					q.info = "Accelerating from zero"
					q.finalAccel = q.accel - q.fric
					q.spd = q.finalAccel
				end

			else
				q.spdDir = q.spd/math.abs(q.spd)
				if  q.fric > q.absAccel  then
					q.finalDecel = q.fric - q.absAccel
					if  q.finalDecel >= q.absSpd  then
						q.info = "Stopping from friction"
						q.spd = 0
					else
						q.info = "Slowing from friction"
						q.spd = q.spd - (q.finalDecel * q.spdDir)
					end

				elseif  q.fric < q.absAccel  then
					q.info = "Accelerating"
					q.finalAccel = q.accel - (q.fric * q.spdDir)
					q.spd = q.spd + q.finalAccel
				end
			end

			-- Apply min/max speed
			q.spd = math.max(math.min(q.spd, q.maxSpd), q.minSpd)

			-- Apply speed
			self["speed"..upperV] = q.spd


			-- Debug
			--Misc.dialog{info=q.info, speed=q.spd}
		end



		-- Apply forward min/max speed
		--[[
		if  self.minSpeedFwd ~= nil  then
			if  self.speedFwd < self.minSpeedFwd  then
				self.speedFwd = self.minSpeedFwd
			end
		end
		if  self.maxSpeedFwd ~= nil  then
			if  self.speedFwd > self.maxSpeedFwd  then
				self.speedFwd = self.maxSpeedFwd
			end
		end
		--]]


		-- Perform movement
		self.x = self.x + self.speedX
		self.y = self.y + self.speedY


		-- Box stuff
		local box = self.collider


		-- Resize collider
		box.width = self.width-- * math.abs(self.xScaleTotal)
		box.height = self.height-- * math.abs(self.yScaleTotal)


		-- Get collider padding
		local padL, padR = 0,box.width
		local padU, padD = 0,box.height

		if      self.xAlign == animatx.ALIGN.MID     then
			padL, padR = 0.5*box.width,0.5*box.width

		elseif  self.xAlign == animatx.ALIGN.RIGHT   then
			padL, padR = box.width,0
		end

		if      self.yAlign == animatx.ALIGN.MID     then
			padU, padD = 0.5*box.height,0.5*box.height

		elseif  self.yAlign == animatx.ALIGN.BOTTOM  then
			padU, padD = box.height,0
		end


		-- Clamp position to bounds based on collider's relative position
		--[[
		if  self.bounds ~= nil  then
			if  self.bounds.left  then
				self.x = math.max (self.bounds.left + padL,  self.x)
			end
			if  self.bounds.right  then
				self.x = math.min (self.bounds.right - padR,  self.x)
			end
			if  self.bounds.top  then
				self.x = math.max (self.bounds.top + padU,  self.y)
			end
			if  self.bounds.bottom  then
				self.x = math.min (self.bounds.bottom - padD,  self.y)
			end
		end
		--]]


		-- Set collider position
		box.x = self.x - padL
		box.y = self.y - padU
	end

	function Actor:updateGfx()
		local gfx = self.gfx

		-- Override AnimInst scale properties based on own + direction
		gfx.xScale = self.xScale
		if  self.directionMirror  then
			gfx.xScale = gfx.xScale * self.direction
		end
		gfx.yScale = self.yScale
		gfx.scale = self.scale

		-- Depth
		gfx.z = self.z

		-- Position
		gfx.objectLastX = nil
		gfx.objectLastY = nil
		gfx:move()
		
		gfx.x = gfx.x + self.xOffsetGfx
		gfx.y = gfx.y + self.yOffsetGfx

		-- Animate even when not being rendered
		if  not gfx.frozen  then
			gfx:animate()
		end
	end

	function Actor:draw()
		if  self.debug  then


			-- shorthand vars
			local cx1,cy1, cw,ch = self.collider.x, self.collider.y, self.collider.width, self.collider.height
			local cx2,cy2 = cx1+cw, cy1+ch

			local cam = camera


			-- Position relative to screen center
			if  cam ~= nil  then
				local camX,camY = cam.x+400, cam.y+300

				local mX,mY = (cx1+cx2)*0.5, (cy1+cy2)*0.5
				if  not self.gfx.sceneCoords  then
					mX = mX+camX
					mY = mY+camY
				end

				local vertexPts   = {camX,  camY,
				                    mX-12,  mY,
				                    mX+12,  mY,

				                    camX,   camY,
				                    mX,     mY-12,
				                    mX,     mY+12,

				                    camX,   camY,
				                    mX-12,  mY,
				                    mX+12,  mY,

				                    camX,   camY,
				                    mX,     mY-12,
				                    mX,     mY+12}

				Graphics.glDraw{primitive=Graphics.GL_TRIANGLES, vertexCoords=vertexPts, color={1,1,1,0.25}, priority=0, sceneCoords=true}
			end

			-- Grounded indicator
			if  contactDown  then
				Graphics.glDraw {
				                 vertexCoords  = rectPointsXYXY(cx1,cy2-2, cx2,cy2+2),
				                 color         = {1,1,0.25,0.5},
				                 primitive     = Graphics.GL_TRIANGLES,
				                 priority      = self.z,
				                 sceneCoords   = true
				                }
			end

			-- Bbox rect
			Graphics.glDraw {
			                 vertexCoords  = rectPointsXYWH(cx1,cy1,cw,ch),
			                 color         = {1,0.25,1,0.5},
			                 primitive     = Graphics.GL_TRIANGLES,
			                 priority      = self.z,
			                 sceneCoords   = true
			                }

			-- Position
			Graphics.glDraw {
			                 vertexCoords  = rectPointsXYWH(self.x-2,self.y-2,4,4),
			                 color         = {1,0.25,1,0.5},
			                 primitive     = Graphics.GL_TRIANGLES,
			                 priority      = self.z,
			                 sceneCoords   = true
			                }
			--]]

			---[[
			--local debugProps = {
				--tostring(self.gfx.xOffset),
				--tostring(self.gfx.yOffset),
				--tostring(self.gfx.frame),
				--tostring(self.gfx.step),
				--tostring(self.gfx.xScaleTotal),
				--tostring(self.directionMirror),
				--tostring(self.direction),
				--"L="..tostring(DIR_LEFT),
				--"R="..tostring(DIR_RIGHT)
				--"grounded = "..tostring(self.bounds ~= nil  and  self.collision.bottom == self.bounds.bottom)
				--"bounds="..tostring(self.bounds),
				--self.state,
				--self.gfx.state,
				--"x,y,w,h="..tostring(self.x)..","..tostring(self.y)..","..tostring(self.width)..","..tostring(self.height),
				--"bbox="..tostring(self.collision.x)..","..tostring(self.collision.y)..","..tostring(self.collision.x2)..","..tostring(self.collision.y2),
				--"bbox x,y,w,h="..tostring(self.collision.x)..","..tostring(self.collision.y)..","..tostring(self.collision.width)..","..tostring(self.collision.height),
				--"bbox offset="..tostring(self.collision.offsetX)..","..tostring(self.collision.offsetY),
				--"gfx offset="..tostring(self.gfx.xOffset)..","..tostring(self.gfx.yOffset)
			--}
			
			--for k,v in ipairs(debugProps)  do
			--	Graphics.draw{type = RTYPE_TEXT, fontType=3, priority = -0.1, x = self.x, y = self.y-15*k, isSceneCoordinates = true, text = v}
			--end
			--]]
		end
		--self.gfx.debug = self.debug
		self.gfx:render()	
		
		if  self.onDrawEnd ~= nil  then
			self:onDrawEnd()
		end
	end
	Actor.Draw = Actor.draw;
end

return Actor