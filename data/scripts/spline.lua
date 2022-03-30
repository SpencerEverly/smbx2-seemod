--- A library for creating hermite spline curves for a variety of uses.
-- @module spline

local spline = {}

local sqrt = math.sqrt
local floor = math.floor
local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp
local huge = math.huge

local typelist = {}

do

	local v2mt = getmetatable(vector.zero2)
	local v3mt = getmetatable(vector.zero3)
	local v4mt = getmetatable(vector.zero4)
	
	local function v2()
		return setmetatable({0,0}, v2mt)
	end
	local function v3()
		return setmetatable({0,0,0}, v3mt)
	end
	local function v4()
		return setmetatable({0,0,0,0}, v4mt)
	end
	
	typelist.Vector2 =  v2
	typelist.Vector3 =  v3
	typelist.Vector4 =  v4
end

do --SEGMENT

	--- A single hermite segment, consisting of a pair of control points and tangents. Points can be `number`, `Vector2`, `Vector3`, or `Vector4`, but must all share the same type.
	-- @type Segment

	---
	-- @tparam number x The x position of the spline segment.
	-- @tparam number y The y position of the spline segment.
	-- @tparam number length The arc length of the spline segment.
	-- @param start The start point of the spline segment.
	-- @param stop The end point of the spline segment.
	-- @param startTan The starting tangent of the spline segment.
	-- @param stopTan The ending tangent of the spline segment.
	-- @table _

	--- Evaluates a spline segment. Returns a value of the same type as the control points. Equivalent to `mySegment(t)`.
	-- @function Segment:evaluate
	-- @tparam number t The spline parameter between 0 and 1.
	-- @usage local p = mySegment:evaulate(0.5)
	-- @usage local p = mySegment(0.5)
	local function segeval(c, t)
		return 	(t*t*(2*t  - 3) + 1)	* c.start 		+ 
				t*t*(-2*t  + 3)			* c.stop 		+ 
				t*(   t*t  - 2*t + 1)	* c.startTan 	+ 
				t*t*(   t  - 1)			* c.stopTan		+ c.y
	end

	local function segveceval(c, t)
		local v = c.__splinetype()
		
		for i,w in ipairs(v) do
			v[i] = (t*t*(2*t  - 3) + 1)		* c.start[i] 		+ 
					t*t*(-2*t  + 3)			* c.stop[i] 		+ 
					t*(   t*t  - 2*t + 1)	* c.startTan[i] 	+ 
					t*t*(   t  - 1)			* c.stopTan[i]
		end
		
		v[1] = v[1]+c.x
		v[2] = v[2]+c.y
		
		return v
	end

	
	--- Draws a spline segment to the screen.
	-- @function Segment:draw
	-- @tparam[opt=50] int steps The number of steps to take while drawing. Fewer is faster, but less accurate.
	-- @tparam[opt] number priority The priority to draw the segment at.
	-- @tparam[opt] Color color The color to draw the segment in.
	-- @tparam[opt=false] bool sceneCoords Whether or not to draw in world space or screen space.
	-- @usage mySegment:draw(50, -50)
	local drawpoints = {}
	local function segdraw(c, steps, priority, color, sceneCoords)
		steps = steps or 50
		local ps = drawpoints
		local idx = 1
		local ds = 1/steps
		local s = 0
		for i = 0,steps do
			local p = c:evaluate(s)
			s = s+ds
			
			ps[idx] = p[1]
			ps[idx+1] = p[2]
			
			idx = idx+2
		end
		
		for i = #ps,idx,-1 do
			ps[i] = nil
		end
		
		Graphics.glDraw{vertexCoords = ps, color=color or Color.white, primitive = Graphics.GL_LINE_STRIP, priority = priority, sceneCoords = sceneCoords}
	end
	
	local function segnumdraw(c, steps, priority, color, sceneCoords)
		steps = steps or 50
		local ps = drawpoints
		local idx = 1
		local ds = 1/steps
		local s = 0
		for i = 0,steps do
			local p = c:evaluate(s)
			s = s+ds
			
			ps[idx] = s*800+c.x
			ps[idx+1] = p
			
			idx = idx+2
		end
		
		for i = #ps,idx,-1 do
			ps[i] = nil
		end
		
		Graphics.glDraw{vertexCoords = ps, color=color or Color.white, primitive = Graphics.GL_LINE_STRIP, priority = priority, sceneCoords = sceneCoords}
	end
	
	local segnumlength
	local segveclength
	local segnumclosest
	local segvecclosest
	do
		local function numdtstep(c,t)
			return 	6*(t*t - t)			* c.start		+
					6*(t - t*t) 		* c.stop		+
					(3*t*t - 4*t + 1)	* c.startTan	+
					(3*t*t - 2*t)		* c.stopTan
		end	
		
		local function vecdt(c,t,i)
			return  6*t*(t - 1)			* c.start[i]	+
				    6*t*(1 - t) 		* c.stop[i]		+
				   (t*(3*t - 4) + 1)	* c.startTan[i]	+
				    t*(3*t - 2)			* c.stopTan[i]
		end
		
		local function vecdtstep(c,t)
			local r = 0
			for i,_ in ipairs(c.start) do
				local z = vecdt(c,t,i)
				r = r + z*z
			end
				
			return sqrt(r)
		end
	
		--Approximate arc length
		local function seglength(c, f)
			-- f(t)  = (2s-2e+g+h)t^3    +  (3e-3s-2g-h)t^2   +  gt  +  s
			-- f'(t) = (6s-6e+3g+3h)t^2  +  (6e-6s-4g-2h)t	  +  g
			-- f'(t) = 6s(tt-t) + 6e(t-tt) + g(3tt-4t+1) + h(3tt-2t)
			-- Length = Integral(Sqrt(f'(t)^2))
			-- Length ~ (1/3N) Sum(f'(0) + 4(f'(dt) + f'(3dt) + f'(5dt) + ...) + 2(f'(2dt) + f'(4dt) + f'(6dt) + ...) + f'(1)) (via Simpson's Rule)
			
			local l = 0
			local step = 11/10000
			local vl = 0
			local m = 3
			for t = 0,1,step do
				if t > step then
					l = l+m*vl
				end
				
				vl = f(c,t)
			
				l = l+vl
				
				m = 4-m
			
			end
			
			return l*step/3
		end	

		function segnumlength(c)
			local l = 0
			local step = 11/10000
			local vl = 0
			local m = 3
			for t = 0,1,step do
				m = segeval(c,t)
				l = l + abs(m - vl)
				vl = m
			end
			
			return l
		end

		function segveclength(c)
			return seglength(c, vecdtstep)
		end
		
		local function segnumdist(c,t,p)
			return abs(segeval(c,t)-p)
		end
		
		local function segvecdist(c,t,p)
			local v = segveceval(c,t)
			for i,w in ipairs(v) do
				v[i] = w-p[i]
			end
			return v.sqrlength
		end
		
		--- Finds the closest point on a spline segment to the supplied point. Returns the spline parameter, followed by the point on the spline segment.
		-- @function Segment:closest
		-- @param point A point of the same type as the control points.
		-- @return number,value
		-- @usage local t,pt = mySegment:closest(vector(100,300))
		local function segdist(c,p,f)
			local s,m,e = 0,0.5,1
			local d
			local t = 0
				
			local dista = f(c,s,p)
			local distb = f(c,m,p)
			local distc = f(c,e,p)
			
			d = max(dista,distb,distc)
			
			local iters = 0
			
			while d > 0.1 and iters < 500 do
				
				if dista < distb and dista < distc then
					t = s
					e = m
					m = (s+e)*0.5
					d = d-dista
					
					distc = distb
					distb = f(c,m,p)
				elseif distc < dista and distc < distb then
					t = e
					s = m
					m = (s+e)*0.5
					d = d-distc
					
					dista = distb
					distb = f(c,m,p)
				else -- if distb < dista and distb < distc then
					t = m
					
					s = (s+m)*0.5
					e = (e+m)*0.5
					d = d-distb
					
					dista = f(c,s,p)
					distc = f(c,e,p)
				end
				
				iters = iters + 1
			end
			
			return t, c:evaluate(t)
			
		end
		
		function segnumclosest(c,p)
			return segdist(c,p,segnumdist)
		end
		
		function segvecclosest(c,p)
			return segdist(c,p,segvecdist)
		end
		
	end

	local seg_mt = {}

	function seg_mt.__index(tbl,key)
		if key == "length" then
			return tbl.__length(tbl)
		end
	end

	function seg_mt.__newindex(tbl,key)
		if key == "length" then
			error("Cannot directly set the length of a spline segment. Try manipulating the control points.", 2)
		end
	end

	function seg_mt.__len(t)
		return t.__length(t)
	end
	function seg_mt.__call(c,t)
		return c:evaluate(t)
	end

	--SEE BOTTOM OF FILE FOR DOCS
	function spline.segment(args)
		local t = { x = args.x or 0, y = args.y or 0, start = args.start, stop = args.stop, startTan = args.startTan, stopTan = args.stopTan }
		
		local typ = type(args.start)
		
		if typ == "number" then
			t.draw = segnumdraw
			t.evaluate = segeval
			t.__length = segnumlength
			t.closest = segnumclosest
		elseif typelist[typ] then
			t.__splinetype = typelist[typ]
			t.draw = segdraw
			t.evaluate = segveceval
			t.__length = segveclength
			t.closest = segvecclosest
		else
			error("Spline control points must be either numbers or vectors.",2)
		end
		
		
		return setmetatable(t, seg_mt)
	end
end


do --SPLINE
	
	--- A hermite spline consisting of a list of control points and tangents. Points may be simple values, or tables of values containing position and shared tangent or position and in and out tangents. Values can be `number`, `Vector2`, `Vector3`, or `Vector4`, but must all share the same type.
	-- @type Spline

	---
	-- @tparam number x The x position of the spline.
	-- @tparam number y The y position of the spline.
	-- @tparam number length The arc length of the spline.
	-- @tparam table points The list of spline control points.
	-- @tparam number smoothness The smoothness of auto-computed tangents (normally between 0 and 1).
	-- @table _

	local function cloneval(x)
		local t = typelist[type(x)]
		if t == nil then
			return x
		else
			local v = t()
			for i,w in ipairs(x) do
				v[i] = w
			end
			return v
		end
	end
	
	local function recalc(t)
		local smoothness = t.__smoothness
		local s = t.__points[1]
		
		local st
		
		t.__count = #t.__points
		t.__starttype = 1
		if type(s) == "table" then
		
			t.__starttype = min(#s, 2)
			
			st = s[2]
			s = s[1]
		end
			
		local typ = type(s)
		local isVector = false
		
		if typelist[typ] then
			s = cloneval(s)
			t.__splinetype = typelist[typ]
			isVector = true
		end
		
		if st == nil then
			if isVector then
				st = t.__splinetype()
			else
				st = 0
			end
		end
		
		local idx = 1
		
		for i=2,#t.__points do
			
			local v = t.__points[i]
			
			if type(v) == "table" and #v > 1 then
				local n = #v
				
				if n == 2 or (n > 1 and i == #t.__points) then --Position with shared tangent
					local e = cloneval(v[1])
					local et = cloneval(v[2])
					
					t.__segments[idx] = { spline.segment{start=s, startTan=st, stop = e, stopTan = et}, 2 }
					t.__segments[idx][3] = t.__segments[idx][1].length
					idx = idx + 1
					s = e
					st = et
				else --Position with differing tangents
					local e = cloneval(v[1])
					local et = cloneval(v[2])
					
					t.__segments[idx] = { spline.segment{start=s, startTan=st, stop = e, stopTan = et}, 3 }
					t.__segments[idx][3] = t.__segments[idx][1].length
					idx = idx + 1
					
					s = e
					st = cloneval(v[3])
				end
			 --Single value provided - position with computed tangents
			elseif i < #t.__points then
				if type(v) == "table" then
					v = v[1]
				end

				local e = cloneval(v)
				local e2 = t.__points[i+1]
				if type(e2) == "table" then
					e2 = e2[1]
				end
				
				local et = (e2-s)*smoothness
				
				t.__segments[idx] = { spline.segment{start=s, startTan = st, stop = e, stopTan = et}, 1 }
				t.__segments[idx][3] = t.__segments[idx][1].length
				idx = idx + 1
				
				s = e
				st = et
				
			--Single value and also the end point
			else
				if type(v) == "table" then
					v = v[1]
				end

				local e = cloneval(v)
				local et = (e-s)*smoothness
				
				t.__segments[idx] = { spline.segment{start=s, startTan = st, stop = e, stopTan = et}, 1 }
				t.__segments[idx][3] = t.__segments[idx][1].length
				idx = idx + 1
			end
		end
		
		for i = #t.__segments,idx,-1 do
			t.__segments[i] = nil
		end
		
		t.__lendirty = true
		t.__dirty = false
	end
	
	local function checkDirt(c)
		if c.__dirty then
			return true
		end
		
		if c.__count ~= #c.__points then
			c.__dirty = true
			return true
		end
		
		local v = c.__points[1]
		local seg = c.__segments[1][1]
		
		local mode = c.__starttype
		local p
		
		if type(v) == "table" then
			if mode ~= #v then
				c.__dirty = true
				return true
			else
				p = v[1]
			end
		else
			if mode ~= 1 then
				c.__dirty = true
				return true
			else
				p = v
			end
		end
		
		if seg.start ~= p or (mode > 1 and seg.startTan ~= v[2]) then
			c.__dirty = true
			return true
		end
		
		for i=2,#c.__points do
			v = c.__points[i]
			seg = c.__segments[i-1]
			
			mode = seg[2]
			seg = seg[1]
			
			if type(v) == "table" then
				if mode ~= #v then
					c.__dirty = true
					return true
				else
					p = v[1]
				end
			else
				if mode ~= 1 then
					c.__dirty = true
					return true
				else
					p = v
				end
			end
			
			if seg.stop ~= p or (mode > 1 and seg.stopTan ~= v[2]) or (mode > 2 and c.__segments[i][1].startTan ~= v[3]) then
				c.__dirty = true
				return true
			end
		end
		
		return false
	end
	
	local function checkAndRebuild(c)
		if checkDirt(c) then
			recalc(c)
		end
	end
	
	local function getlen(c)	
		checkAndRebuild(c)
		if c.__lendirty then
			local l = 0
			for k,v in ipairs(c.__segments) do
				l = l+v[3]
			end
			c.__lendirty = false
			c.__length = l
		end
		return c.__length
	end
	
	--- Evaluates a spline. Returns a value of the same type as the control points. Equivalent to `mySpline(t)`.
	-- @function Spline:evaluate
	-- @tparam number t The spline parameter between 0 and 1.
	-- @usage local p = mySpline:evaulate(0.5)
	-- @usage local p = mySpline(0.5)
	local function eval(c, t)		
		checkAndRebuild(c)
		t = clamp(t,0,1)*getlen(c)
		
		local val
		
		local rl = 0
		for k,v in ipairs(c.__segments) do
			if t < rl then
				break
			else
				val = v
				rl = rl+v[3]
			end
		end
		
		t = (t-rl)/val[3] + 1
	
		val[1].x = c.x
		val[1].y = c.y
		return val[1](t)
	end
	
	local function getvecpt(p)
		return p[1], p[2]
	end
	
	local function getnumpt(p, s, x)
		return s*800+x, p
	end
	
	--- Draws a spline to the screen.
	-- @function Spline:draw
	-- @tparam[opt] int steps The number of steps to take while drawing. Fewer is faster, but less accurate. If not supplied, the step number will be automatically computed from the total spline length.
	-- @tparam[opt] number priority The priority to draw the segment at.
	-- @tparam[opt] Color color The color to draw the segment in.
	-- @tparam[opt=false] bool sceneCoords Whether or not to draw in world space or screen space.
	-- @tparam[opt=false] bool showControlPoints Whether or not to draw the control points of the spline.
	-- @tparam[opt=false] bool showTangents Whether or not to draw the tangents of the spline.
	-- @usage mySpline:draw(50, -50)
	local drawpoints = {}
	local ctrlpts = {}
	local tanpts = {}
	local function dodraw(c, f, steps, priority, color, sceneCoords, showctrlpts, showtgts)
	
		local x,y = c.x, c.y
	
		local tlen = getlen(c)
		steps = steps or floor(tlen*0.25)
		
		local ps = drawpoints
		local idx = 1
		local ds = 1/steps
		local s = 0
		for i = 0,steps do
			local p = eval(c,s)
			
			ps[idx], ps[idx+1] = f(p, s, c.x)
			s = s+ds
			idx = idx+2
		end
		
		for i = #ps,idx,-1 do
			ps[i] = nil
		end
		
		Graphics.glDraw{vertexCoords = ps, color=color or Color.white, primitive = Graphics.GL_LINE_STRIP, priority = priority, sceneCoords = sceneCoords}
		
		if showctrlpts or showtgts then
			local l = 0
			local idx = 1
			local tidx = 1
			local cidx = 1
			local sz = 3
			local ln = 0
			local lsln = 0
			
			local x,y = c.x, c.y
			
			local isnumber = type(c.__segments[1][1].start)=="number"
			
			for i=1,#c.__segments do
					local v = c.__segments[i]
					local s = v[1]
					ln = v[3]
					local px,py = f(s.start, l/tlen, 0)
					
					if showctrlpts then
						ctrlpts[idx] 	= x+px-sz
						ctrlpts[idx+1] 	= y+py-sz
						ctrlpts[idx+2]	= x+px+sz
						ctrlpts[idx+3] 	= y+py-sz	
						ctrlpts[idx+4] 	= x+px-sz
						ctrlpts[idx+5] 	= y+py+sz
						
						ctrlpts[idx+6] 	= x+px-sz
						ctrlpts[idx+7] 	= y+py+sz
						ctrlpts[idx+8] 	= x+px+sz
						ctrlpts[idx+9] 	= y+py-sz	
						ctrlpts[idx+10] = x+px+sz
						ctrlpts[idx+11] = y+py+sz
						
						idx = idx + 12
					end
					
					if showtgts then
						local ex,ey = f(s.stop, (l+ln)/tlen, 0)
						local psx,psy = f(s.startTan, lsln/tlen, 0)
						local pex,pey = f(-s.stopTan, -ln/tlen, 0)
						
						ps[tidx]   = x+px
						ps[tidx+1] = y+py
						ps[tidx+2] = x+px+psx
						ps[tidx+3] = y+py+psy
						
						ps[tidx+4] = x+ex
						ps[tidx+5] = y+ey
						ps[tidx+6] = x+ex+pex
						ps[tidx+7] = y+ey+pey
						
						tidx = tidx+8
						
						local m = v[2]
						local m2 = 1
						if i > 1 then
							m2 = c.__segments[i-1][2]
						else
							m2 = c.__starttype
						end
						
						local b = (m2 == 1) and 1 or 0
						local g = (m2 > 1) and 1 or (m2 == 1) and 0.5 or 0
						local r = (m2 == 2) and 1 or 0
					
						tanpts[cidx]   = r
						tanpts[cidx+1] = g
						tanpts[cidx+2] = b
						tanpts[cidx+3] = 1
						tanpts[cidx+4] = r
						tanpts[cidx+5] = g
						tanpts[cidx+6] = b
						tanpts[cidx+7] = 1
						
						b = (m == 1) and 1 or 0
						g = (m == 2) and 1 or (m == 1) and 0.5 or 0
						r = (m > 1) and 1 or 0
						
						tanpts[cidx+8]  = r
						tanpts[cidx+9]  = g
						tanpts[cidx+10] = b
						tanpts[cidx+11] = 1
						tanpts[cidx+12] = r
						tanpts[cidx+13] = g
						tanpts[cidx+14] = b
						tanpts[cidx+15] = 1
						
						cidx = cidx + 16
					end
					
					l = l+ln
					lsln = ln
			end
			
			if showtgts then
				for i = #ps,tidx,-1 do
					ps[i] = nil
				end
				for i = #tanpts,cidx,-1 do
					tanpts[i] = nil
				end
			
				Graphics.glDraw{vertexCoords = ps, vertexColors = tanpts, primitive = Graphics.GL_LINES, priority = priority, sceneCoords = sceneCoords}
			end
			if showctrlpts then
			
				local v = c.__segments[#c.__segments]
				local s = v[1]
				local px,py = f(s.stop, l/tlen, 0)
				
				ctrlpts[idx] 	= x+px-sz
				ctrlpts[idx+1] 	= y+py-sz
				ctrlpts[idx+2] 	= x+px+sz
				ctrlpts[idx+3] 	= y+py-sz	
				ctrlpts[idx+4] 	= x+px-sz
				ctrlpts[idx+5] 	= y+py+sz
					
				ctrlpts[idx+6] 	= x+px-sz
				ctrlpts[idx+7] 	= y+py+sz
				ctrlpts[idx+8] 	= x+px+sz
				ctrlpts[idx+9]  = y+py-sz	
				ctrlpts[idx+10] = x+px+sz
				ctrlpts[idx+11] = y+py+sz
					
				idx = idx + 12
			
				for i = #ctrlpts,idx,-1 do
					ctrlpts[i] = nil
				end
				
				Graphics.glDraw{vertexCoords = ctrlpts, color=color or Color.white, priority = priority, sceneCoords = sceneCoords}
			end
		end
	end
	
	local function draw(c, steps, priority, color, sceneCoords, showctrlpts, showtgts)
		dodraw(c, getvecpt, steps, priority, color, sceneCoords, showctrlpts, showtgts)
	end
	
	local function numdraw(c, steps, priority, color, sceneCoords, showctrlpts, showtgts)
		dodraw(c, getnumpt, steps, priority, color, sceneCoords, showctrlpts, showtgts)
	end
	
	--- Steps along the spline a fixed distance, starting from a given parameterised point. Will return the new parameter followed by the computed point. Can be used to step along a spline at a predetermined speed.
	-- @function Spline:step
	-- @tparam number speed The distance to step along the spline. Negative values will step backwards.
	-- @tparam number t The parameterised starting point along the spline, between 0 and 1.
	-- @return number,value
	-- @usage local t,pt = mySpline:step(1,0.5)
	local function step(c, f, speed, t)
		if speed == 0 then
			return t
		end

		t = clamp(t,0,1)
		
		local s = eval(c,t)
		local thresh = 0.001
		
		local dt = speed/getlen(c)
		
		speed = speed*speed
		t = t+dt
		
		local iters = 0
		local s2 = s
		
		while t <= 1 and t >= 0 and iters < 500 do
				
			s2 = eval(c,t)
				
			local d = f(s2, s) - speed
				
			if d > thresh then
				t = t-dt
				-- Subdivide the step.
				-- 0.5 seems the most obvious, but 1/3 produces fewer iterations on average, and proportional subdivision produces higher on average.
				dt = dt*0.33333
				t = t+dt
			elseif d < -thresh then
				t = t+dt
			else
				break
			end
			
			iters = iters + 1
		end
			
		return t, s2
	end
	
	
	
	local function vecdist(s,s2)
		local d = 0
		for i,w in ipairs(s2) do
			local v = w-s[i]
			d = d+v*v
		end
		return d
	end
	
	local function numdist(s,s2)
		return abs(s2 - s)
	end
	
	local function vecstep(c, speed, t)
		return step(c, vecdist, speed, t)
	end
	
	local function numstep(c, speed, t)
		return step(c, numdist, speed, t)
	end
	
	--- Finds the closest point on a spline to the supplied point. Returns the spline parameter, followed by the point on the spline.
	-- @function Spline:closest
	-- @param point A point of the same type as the control points.
	-- @return number,value
	-- @usage local t,pt = mySpline:closest(vector(100,300))
	local function closest(c, p, f)
		local m = huge
		local mt = 0
		local mid = 0
		local mpt = nil
		for k,v in ipairs(c.__segments) do
			v = v[1]
			local t,pt = v:closest(p)
			local d = f(p,pt)
			if d < m then
				m = d
				mt = t
				mid = k
				mpt = pt
			end
		end
		
		local l = 0
		for i = 1,mid-1 do
			l = l + c.__segments[i][3]
		end
		
		local t = (l + mt*c.__segments[mid][3])/c.length
		
		return t,mpt
	end
	
	local function numclosest(c,p)
		return closest(c,p,numdist)
	end
	
	local function vecclosest(c,p)
		return closest(c,p,vecdist)
	end
	
	local spline_mt = {}
	
	function spline_mt.__index(tbl,key)
		if key == "length" then
			return getlen(tbl)
		elseif key == "points" then
			return tbl.__points
		elseif key == "smoothness" then
			return tbl.__smoothness
		end
	end
	
	function spline_mt.__newindex(tbl,key,val)
		if key == "length" then
			error("Cannot directly set the length of a spline. Try manipulating the control points.", 2)
		elseif key == "points" then
			tbl.__points = val
			tbl.__dirty = true
			tbl.__lendirty = true
		elseif key == "smoothness" then
			tbl.__smoothness = val
			tbl.__dirty = true
			tbl.__lendirty = true
		end
	end
	
	spline_mt.__call = eval
	
	--SEE BOTTOM OF FILE FOR DOCS
	function spline.new(args)
		local t = { x = args.x or 0, y = args.y or 0, __points = args.points, __dirty = true, __lendirty = true, __length = 0, __count = 0 }
		
		t.__segments = {}
		
		t.__smoothness = args.smoothness or 0.5
		
		recalc(t)
		
		t.evaluate = eval
		
		local s = t.__points[1]
		
		if type(s) == "table" then
			s = s[1]
		end
		
		local typ = type(s)
		if typ == "number" then
			t.draw = numdraw
			t.step = numstep
			t.closest = numclosest
		else
			t.draw = draw
			t.step = vecstep
			t.closest = vecclosest
		end
		
		return setmetatable(t, spline_mt)
	end
end


--- Functions.
-- @section Functions

--- Creates a hermite spline segment.
-- @function Spline.segment
-- @return @{Segment}
-- @tparam table args
-- @param args.start The start point of the spline segment.
-- @param args.stop The end point of the spline segment.
-- @param args.startTan The starting tangent of the spline segment.
-- @param args.stopTan The ending tangent of the spline segment.
-- @tparam[opt=0] number args.x The x position of the spline segment.
-- @tparam[opt=0] number args.y The y position of the spline segment.
-- @usage mySegment = Spline.segment{start=vector(0,0), stop=vector(100,100), startTan=vector(100,0), stopTan=vector(0,100)}

--- Creates a hermite spline.
-- @function Spline.new
-- @return @{Spline}
-- @tparam table args
-- @tparam table args.points The list of spline control points.
-- @tparam[opt=0.5] number args.smoothness The smoothness of auto-computed tangents (normally between 0 and 1).
-- @tparam[opt=0] number args.x The x position of the spline.
-- @tparam[opt=0] number args.y The y position of the spline.
-- @usage mySpline = Spline.new{points = { vector(0,0), vector(100,100), vector(200,0) }, smoothness = 1}
-- @usage mySpline = Spline.new{points = { {vector(0,0), vector(0,100)}, {vector(100,100),vector(100,0),vector(100,100)}, vector(200,0) }}


--- Creates a hermite spline.
-- @function Spline
-- @return @{Spline}
-- @tparam table args
-- @tparam table args.points The list of spline control points.
-- @tparam[opt=0.5] number args.smoothness The smoothness of auto-computed tangents (normally between 0 and 1).
-- @tparam[opt=0] number args.x The x position of the spline.
-- @tparam[opt=0] number args.y The y position of the spline.
-- @usage mySpline = Spline{points = { vector(0,0), vector(100,100), vector(200,0) }, smoothness = 1}
-- @usage mySpline = Spline{points = { {vector(0,0), vector(0,100)}, {vector(100,100),vector(100,0),vector(100,100)}, vector(200,0) }}


local global_mt = {}

global_mt.__call = function(s, args) return spline.new(args) end

setmetatable(spline, global_mt)

return spline