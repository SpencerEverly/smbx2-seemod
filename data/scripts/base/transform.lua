---
--@script Transform

local transform = {}

local sqrt = math.sqrt
local remove = table.remove
local insert = table.insert
local clamp = math.clamp

local rawset = rawset
local ipairs = ipairs


--Local fast v2 creation
local v2mt = getmetatable(vector.zero2)
local function v2(x,y)
	return setmetatable({x, y}, v2mt);
end

--Local fast v3 copy
local function cv2(v)
	return setmetatable({v[1], v[2]}, v2mt)
end

--Local fast v3 creation
local v3mt = getmetatable(vector.zero3)
local function v3(x,y,z)
	return setmetatable({x, y, z}, v3mt);
end

--Local fast v3 copy
local function cv3(v)
	return setmetatable({v[1], v[2], v[3]}, v3mt)
end

--Local fast v4 creation
local v4mt = getmetatable(vector.zero4)
local function v4(x,y,z,w)
	return setmetatable({x, y, z, w}, v4mt);
end

--Local fast v4 copy
local function cv4(v)
	return setmetatable({v[1], v[2], v[3], v[4]}, v4mt)
end

--Local quat creation
local quat = vector.quat

--Local fast quat copy
local quatmt = getmetatable(vector.quatid)
local function cquat(q)
	return setmetatable({q[1], q[2], q[3], q[4], __nrm = true }, quatmt)
end

--Local fast mat3 creation
local mat3mt = getmetatable(vector.id3)
local function mat3(a,b,c,d,e,f,g,h,i)
	return setmetatable({a,b,c,d,e,f,g,h,i}, mat3mt)
end

--Local fast mat3 copy
local function cmat3(m)
	local t = {}
	for i,v in ipairs(m) do
		t[i] = v
	end
	return setmetatable(t, mat3mt)
end

--local fast mat3xmat3 mul
local function m3mul(a,b)
	local m = mat3(0,0,0,0,0,0,0,0,0)
	
	for i=1,3,1 do
		for j=1,3,1 do
			for k=1,3,1 do
				m[i + (j-1)*3] = m[i + (j-1)*3] + a[i + (k-1)*3]*b[k + (j-1)*3]
			end
		end
	end
	
	return m
end

--Local fast mat4 creation
local mat4mt = getmetatable(vector.id4)
local function mat4(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p)
	return setmetatable({a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p}, mat4mt)
end

--Local fast mat4 copy
local function cmat4(m)
	local t = {}
	for i,v in ipairs(m) do
		t[i] = v
	end
	return setmetatable(t, mat4mt)
end


--local fast mat4xmat4 mul
local function m4mul(a,b)
	local m = mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	
	for i=1,4,1 do
		for j=1,4,1 do
			for k=1,4,1 do
				m[i + (j-1)*4] = m[i + (j-1)*4] + a[i + (k-1)*4]*b[k + (j-1)*4]
			end
		end
	end
	
	return m
end

local function tfTypecheck(a, n)
	if a ~= nil and type(a) ~= "Transform" then
		error("Type 'Transform' expected, found: "..type(a), n+1)
	end
end

local function tf3dTypecheck(a, n)
	if a ~= nil and type(a) ~= "Transform3D" then
		error("Type 'Transform3D' expected, found: "..type(a), n+1)
	end
end

--NOTE: currently b does nothing as it's not passed down via ipairs calls
local function iterate(tbl, b)
	--[[if b then
		local t = {}
		local fringe = {}
		for _,v in ipairs(tbl.children) do
			insert(fringe,v)
		end
		while #fringe > 0 do
			local f = fringe[1]
			remove(fringe,1)
			insert(t,f)
			for _,v in ipairs(tbl.children) do
				insert(fringe,v)
			end
		end
		return ipairs(t)
	else
	]]
		return ipairs(tbl.children)
	--end
end
	
local function tflen(tbl) 
	return #tbl.children 
end
	

--local fringe = {}
local function setDirty(tf, noLocal)
	--[[
	fringe[1] = tf
	for i = 2,#fringe do
		fringe[i] = nil
	end
	
	while #fringe > 0 do
		local f = fringe[#fringe]
		
		--rawset(f, "__dirty", true)
		--rawset(f, "__invdirty", true)
		f.__dirty = true
		f.__invdirty = true
			
		if not noLocal then
			--rawset(f, "__locdirty", true)
			--rawset(f, "__invlocdirty", true)
			f.__locdirty = true
			f.__invlocdirty = true
		end
		
		fringe[#fringe] = nil
		
		for _,v in ipairs(f.children) do
			insert(fringe, v)
		end
	end
	
	]]
	
	tf.__dirty = true
	tf.__invdirty = true
			
	if not noLocal then
		--rawset(f, "__locdirty", true)
		--rawset(f, "__invlocdirty", true)
		tf.__locdirty = true
		tf.__invlocdirty = true
	end
	
	
	for _,v in ipairs(tf.children) do
		setDirty(v, noLocal)
	end
end

local function isChild(tf, c)
	--[[
	fringe[1] = tf
	for i = 2,#fringe do
		fringe[i] = nil
	end

	while #fringe > 0 do
		local v = fringe[#fringe]
		if v == c then
			return true
		else
			fringe[#fringe] = nil
			for _,w in ipairs(v.children) do
				insert(fringe, w)
			end
			
		end
	end
	]]
	
	if tf == c then
		return true
	else
		for _,v in ipairs(tf) do
			if isChild(v,c) then
				return true
			end
		end
	end
	
	return false
end


local function getSibling(tf)
	if tf.__parent == nil then
		return 0
	else
		return table.ifind(tf.__parent.children, tf) or 0
	end
end

local function setSibling(tf, idx)
	if tf.__parent ~= nil then
		idx = clamp(idx, 1, #tf.__parent.children)
		local id = table.ifind(tf.__parent.children, tf)
		if id ~= nil then
			remove(tf.__parent.children, id)
			insert(tf.__parent.children, idx, tf)
		end
	end
end

local function setFirstSibling(tf)
	setSibling(tf,1)
end

local function setLastSibling(tf)
	if tf.__parent ~= nil then
		setSibling(tf,#tf.__parent.children)
	end
end
	
local function getRoot(tf)
	local t = tf
	while t.__parent ~= nil do
		t = t.__parent
	end
	
	return t
end

do --3D transforms
	
	
--- A 3D Transform object
-- @type Transform3D

---
-- @tparam Mat4 obj2world (READ-ONLY) The object-space to world-space transformation matrix, effectively the transform's state matrix.
-- @tparam Mat4 world2obj (READ-ONLY)The world-space to object-space transformation matrix, effectively the inverse transform's state matrix.
-- @tparam Vector3 position The object-space position of the transform.
-- @tparam Quaternion rotation The object-space rotation of the transform.
-- @tparam Vector3 scale The object-space scale of the transform.
-- @tparam Vector3 wposition The world-space position of the transform. Can only be modified via direct assignment.
-- @tparam Quaternion wrotation The world-space rotation of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 wscale The world-space scale of the transform. Can only be modified via direct assignment.
-- @tparam Transform3D parent The parent object of the transform. Will be `nil` if no parent exists.
-- @tparam Vector3 forward The object-space forward vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 up The object-space up vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 right The object-space right vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 wforward The world-space forward vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 wup The world-space up vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector3 wright The world-space right vector of the transform. Can only be modified via direct assignment.
-- @tparam int siblingIdx The sibling index of the transform (i.e. the position in the parent's children list).
-- @tparam Transform3D root (READ-ONLY) The top-level object of the scene hierarchy (effectively the topmost "parent" object).
-- @table _
	
	local getMat
	
	local function checkDirty(tf)
		local c = tf.__comp
		
		local update = false
		for i = 1,3 do
			for j = 1,3 do
				if c[i][j] ~= tf[i][j] then
					update = true
					break
				end
			end
			if update then
				break
			end
		end
		
		if update or c[2][4] ~= tf[2][4] then
			c[1] = cv3(tf[1])
			c[2] = cquat(tf[2])
			c[3] = cv3(tf[3])
			setDirty(tf)
		end
	end
	
	local function isDirty(tf)
		if tf.__dirty or (tf.__parent ~= nil and isDirty(tf.__parent)) then
			return true
		else
			checkDirty(tf)
			return tf.__dirty
		end
	end
	
	local function isDirtyLocal(tf)
		if tf.__locdirty then
			return true
		else
			checkDirty(tf)
			return tf.__locdirty
		end
	end
	
	local function isInvDirty(tf)
		if tf.__invdirty or (tf.__parent ~= nil and isInvDirty(tf.__parent)) then
			return true
		else
			checkDirty(tf)
			return tf.__invdirty
		end
	end
	
	local function isInvDirtyLocal(tf)
		if tf.__invlocdirty then
			return true
		else
			checkDirty(tf)
			return tf.__invlocdirty
		end
	end

	local function calcMatLocal(tf)
		local m = tf[2]:tomat4()
		
		--Faster equivalent to matrix multiplication, making assumptions about the nature of the matrices we're multiplying (assumptions which necessarily hold)
		
		local sc = tf[3]
		--Apply scale mod
		for s = 1,3 do
			local v = sc[s]
			for i = 1,3 do
				m[i+(s-1)*4] = m[i+(s-1)*4]*v
			end
		end
		
		
		local p = tf[1]
		--Apply position
		for i = 1,3 do
			m[12+i] = p[i]
		end
		
		--Mp * Mr * Ms - Application order = Scale > Rotation > Position
		rawset(tf, "__matloc", m)
		tf.__locdirty = false
		--rawset(tf, "__locdirty", false)
	end
	
	local function invrot2mat4(q)
		local w = q[1]
		local x = -q[2]
		local y = -q[3]
		local z = -q[4]

		local w2 = w*w
		local x2 = x*x
		local y2 = y*y
		local z2 = z*z
		
		return mat4(w2+x2-y2-z2, 2*(x*y+w*z), 2*(x*z-w*y), 0,		2*(x*y-w*z), w2-x2+y2-z2, 2*(y*z+w*x), 0,		2*(x*z+w*y), 2*(y*z-w*x), w2-x2-y2+z2, 0,		0,0,0,1)
	end

	local function calcInvMatLocal(tf)
		local m = invrot2mat4(tf[2])
		
		--Faster equivalent to matrix multiplication, making assumptions about the nature of the matrices we're multiplying (assumptions which necessarily hold)
		
		local sc = tf[3]
		--Apply scale mod
		for s = 1,3 do
			local v = sc[s]
			for i = 1,3 do
				m[s+(i-1)*4] = m[s+(i-1)*4]/v
			end
		end
		
		
		local p = tf[1]
		--Apply position
		for i = 1,3 do
			m[12+i] = -m[i]*p[1] - m[4+i]*p[2] - m[8+i]*p[3]
		end
		
		
		rawset(tf, "__invmatloc", m)
		tf.__invlocdirty = false
		--rawset(tf, "__invlocdirty", false)
	end

--- Returns the object-space to parent-space transformation matrix.
-- @function Transform3D:getMatLocal
-- @return Mat4
	local function getMatLocal(tf)
		if tf.__matloc == nil or isDirtyLocal(tf) then
			calcMatLocal(tf)
		end
		
		return tf.__matloc
	end
	
--- Returns the parent-space to object-space transformation matrix.
-- @function Transform3D:getInvMatLocal
-- @return Mat4
	local function getInvMatLocal(tf)
		if tf.__invmatloc == nil or isInvDirtyLocal(tf) then
			calcInvMatLocal(tf)
		end
		
		return tf.__invmatloc
	end
	
	local function getPosFromMat(m)
		return v3(m[13], m[14], m[15])
	end
	
	local function getScaleFromMat(m)
		local s = vector.zero3
		for i = 1,3 do
			local t = 0
			for j = 1,3 do
				local v = m[j + (i-1)*4]
				t = t + v*v
			end
			s[i] = sqrt(t)
		end
		
		return s
	end
	
	local function getRotAndScaleFromMat(m)
		local s = getScaleFromMat(m)
		local r = vector.id3
		
		for i = 1,3 do
			for j = 1,3 do
				r[j + (i-1)*3] = m[j + (i-1)*4]/s[i]
			end
		end
		
		r = quat(r)
		
		return r,s
	end

	local function getFromMat(m)
		local p = getPosFromMat(m)
		local r,s = getRotAndScaleFromMat(m)
		
		return p,r,s
	end

	local function calcMat(tf)
		local m = getMatLocal(tf)
		
		local p = tf.__parent
		
		while p do
			if p.__mat ~= nil and not isDirty(p) then
				m = m4mul(p.__mat, m)
				break
			else
				m = m4mul(getMatLocal(p), m)
				p = p.__parent
			end
		end
		
		rawset(tf, "__mat", m)
		tf.__dirty = false
		--rawset(tf, "__dirty", false)
	end

	
--- Returns the object-space to world-space transformation matrix.
-- @function Transform3D:getMat
-- @return Mat4
	getMat = function(tf)
		if tf.__mat == nil or isDirty(tf) then
			calcMat(tf)
		end
		return tf.__mat
	end
	
	local function calcInvMat(tf)
		local m = getInvMatLocal(tf)
		
		local p = tf.__parent
		
		while p do
			if p.__invmat ~= nil and not isInvDirty(p) then
				m = m4mul(m, p.__invmat)
				break
			else
				m = m4mul(m, getInvMatLocal(p))
				p = p.__parent
			end
		end
		
		rawset(tf, "__invmat", m)
		tf.__invdirty = false
		--rawset(tf, "__invdirty", false)
	end
	

--- Returns the world-space to object-space transformation matrix.
-- @function Transform3D:getInvMat
-- @return Mat4
	local function getInvMat(tf)
		--equivalent to:
		--return getMat(tf).inverse
		
		if tf.__invmat == nil or isInvDirty(tf) then
			calcInvMat(tf)
		end
		return tf.__invmat
	end

--- Attaches an object as a child of the transform.
-- @function Transform3D:addChild
-- @tparam Transform3D child The child transform to attach (will be removed from its current parent if it has one).
-- @tparam[opt=true] bool keepWorld Whether the child should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage myTransform:addChild(myOtherTransform)
-- @usage myTransform:addChild(myOtherTransform, false)
	local function addChild(tfp, tfc, keepWorld)
		tf3dTypecheck(tfp, 2)
		tf3dTypecheck(tfc, 2)
		if tfp == tfc then 
			tfp = nil 
		end
		
		if keepWorld == nil then
			keepWorld = true
		end
		
		if tfp ~= nil and isChild(tfc, tfp) then
			addChild(nil, tfp)
		end
		
		if keepWorld then
			
			local m = getMat(tfc)
			
			if tfp ~= nil then
				m = m4mul(getInvMat(tfp), m)
			end
		
			--Get world space mat and multiply with inverse of new parent mat
			local p,r,s = getFromMat(m)
			
			tfc[1] = p
			tfc[2] = r
			tfc[3] = s
		end
		
		if tfc.__parent ~= nil then
			remove(tfc.__parent.children, table.ifind(tfc.__parent.children, tfc))
		end
		
		if tfp ~= nil then
			insert(tfp.children, tfc)
		end
		rawset(tfc, "__parent", tfp)
		setDirty(tfc, not keepWorld)
	end

--- Sets the parent of the transform.
-- @function Transform3D:setParent
-- @tparam[opt] Transform3D parent The parent transform to attach to (will remove the transform from its current parent if it has one). Supplying `nil` will remove the transform from its parent.
-- @tparam[opt=true] bool keepWorld Whether the transform should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage myTransform:setParent(myOtherTransform)
-- @usage myTransform:setParent(myOtherTransform, false)
-- @usage myTransform:setParent(nil)
	local function setParent(tf, parent, keepWorld)
		tf3dTypecheck(tf, 2)
		tf3dTypecheck(parent, 2)
		addChild(parent, tf, keepWorld)
	end
	
	local function lookInDir(tf, dir, up)
		if dir == nil then
			up = up:normalise()
			dir = (tf.forward^up)^up
		end
		if up == nil then
			dir = dir:normalise()
			up = (tf.up^dir)^dir
		end
		local q = quat()
		q:lookTo(dir,up)
		return q
	end
	
	local function getWorldPos(tf)
		if tf.__parent == nil then
			return cv3(tf[1])
		end
		local m = getMat(tf)
		return v3(m[13],m[14],m[15])
	end
	
	local function getWorldScale(tf)
		if tf.__parent == nil then
			return cv3(tf[3])
		end
		local m = getMat(tf)
		local s = vector.zero3
		for i = 1,3 do
			local t = 0
			local n = (i-1)*4
			for j = 1,3 do
				t = t + m[n + j]*m[n + j]
			end
			s[i] = sqrt(t)
		end
		return s
	end
	
	local function getWorldRot(tf)
		if tf.__parent == nil then
			return cquat(tf[2])
		end
		local s = getWorldScale(tf)
		local m = getMat(tf)
		local r = vector.id3
			
		for i = 1,3 do
			local n = (i-1)*4
			local n2 = (i-1)*3
			for j = 1,3 do
				r[n2 + j] = m[n + j]/s[i]
			end
		end
		
		return quat(r)
	end
	
	
	local function setWorldPos(tf, v)
		if tf.__parent == nil then
			tf[1] = cv3(v)
		else
			local m = getMat(tf)
			m = cmat4(m)
			m[13] = v[1]
			m[14] = v[2]
			m[15] = v[3]
			
			m = m4mul(getInvMat(tf.__parent), m)
			local p = getPosFromMat(m)
			
			tf[1][1] = p[1]
			tf[1][2] = p[2]
			tf[1][3] = p[3]
		end
		setDirty(tf)
	end
	
	local function setWorldScale(tf, v)
		if tf.__parent == nil then
			tf[3] = cv3(v)
		else
			local s = getWorldScale(tf)
			tf[3][1] = tf[3][1] * v[1]/s[1]
			tf[3][2] = tf[3][2] * v[2]/s[2]
			tf[3][3] = tf[3][3] * v[3]/s[3]
		end
		setDirty(tf)
	end
	
	local function setWorldRot(tf, v)
		if tf.__parent == nil then
			tf[2] = cquat(v)
		else
			local m = getMat(tf)
			m = cmat4(m)
			
			local s = getWorldScale(tf)
			
			local w = v[1]
			local x = v[2]
			local y = v[3]
			local z = v[4]

			local w2 = w*w
			local x2 = x*x
			local y2 = y*y
			local z2 = z*z
			
			m[1] = 	(w2+x2-y2-z2)	* s[1]
			m[2] = 	2*(x*y+w*z)		* s[1]
			m[3] = 	2*(x*z-w*y)		* s[1]
			
			m[5] = 	2*(x*y-w*z)		* s[2]
			m[6] = 	(w2-x2+y2-z2)	* s[2]
			m[7] = 	2*(y*z+w*x)		* s[2]
			
			m[9] = 	2*(x*z+w*y)		* s[3]
			m[10] = 2*(y*z-w*x)		* s[3]
			m[11] = (w2-x2-y2+z2)	* s[3]
			
			m = m4mul(getInvMat(tf.__parent),m)
			local r = getRotAndScaleFromMat(m)
			
			tf[2] = r
		end
		setDirty(tf)
	end
	
--- Rotates the transform by the given quaternion.
-- @function Transform3D:rotate
-- @tparam Quaternion q The quaternion rotation to apply.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space.
-- @usage myTransform:rotate(myQuaternion, true)

--- Rotates the transform by the given angle around the given axis.
-- @function Transform3D:rotate
-- @tparam Vector3 axis The axis of rotation.
-- @tparam number angle The angle to rotate in degrees.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space.
-- @usage myTransform:rotate(vector.up3, 30, true)

--- Rotates the transform by the rotation given by the supplied initial and final vectors.
-- @function Transform3D:rotate
-- @tparam Vector3 initial The vector denoting the direction to start from.
-- @tparam Vector3 final The vector denoting the direction to finish at. After applying this rotation to the `initial` vector, it will point in this direction.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space.
-- @usage myTransform:rotate(vector.up3, vector.right3, true)

--- Rotates the transform by the given rotation matrix
-- @function Transform3D:rotate
-- @tparam Mat3 matrix The rotation matrix to apply.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space.
-- @usage myTransform:rotate(myMatrix, true)

--- Rotates the transform by the given roll, pitch, and yaw.
-- @function Transform3D:rotate
-- @tparam number roll The roll to rotate by (around the x-axis) in degrees.
-- @tparam number pitch The pitch to rotate by (around the y-axis) in degrees.
-- @tparam number yaw The yaw to rotate by (around the z-axis) in degrees.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space.
-- @usage myTransform:rotate(10, 20, 30, true)
	local function rotate(tf, x, y, z, worldspace)
		if worldspace == nil then
			if type(y) == "boolean" then
				worldspace = y
				y = nil
				z = nil
			elseif type(z) == "boolean" then
				worldspace = z
				z = nil
			end
		end
		
		if worldspace then
			setWorldRot(tf, quat(x,y,z)*getWorldRot(tf))
		else
			tf[2] = tf[2]*quat(x,y,z)
			setDirty(tf)
		end
	end

--- Moves the transform by the given vector.
-- @function Transform3D:translate
-- @tparam Vector3 v The motion vector to apply.
-- @tparam[opt=false] bool worldspace Whether the motion should be applied in world-space.
-- @usage myTransform:translate(vector.up3, true)
	local function translate(tf, v, worldspace)
		if worldspace then
			local w = getWorldPos(tf)
			for i = 1,3 do
				w[i] = w[i]+v[i]
			end
			setWorldPos(tf, w)
		else
			for i = 1,3 do
				tf[1][i] = tf[1][i]+v[i]
			end
			setDirty(tf)
		end
	end
	
--- Applies the rotation and scale (but not position) to a given vector.
-- @function Transform3D:transformVector
-- @tparam Vector3 v The vector to apply the transform to.
-- @return Vector3
-- @usage myTransform:transformVector(vector.up3)
	local function tfvector(tf, v)
		local m = getMat(tf)
		local t = vector.zero3
			for i=1,3,1 do
				local n = (i-1)*4
				local vi = v[i]
				for j=1,3,1 do
					t[j] = t[j] + vi*m[n + j]
				end
			end
		return t
	end
	
--- Applies the rotation (but not position or scale) to a given vector.
-- @function Transform3D:transformDirection
-- @tparam Vector3 v The vector to apply the transform to.
-- @return Vector3
-- @usage myTransform:transformDirection(vector.up3)

--- Applies the rotation (but not position or scale) to a given vector.
-- @function Transform3D:transformDir
-- @tparam Vector3 v The vector to apply the transform to.
-- @return Vector3
-- @usage myTransform:transformDir(vector.up3)
	local function tfdir(tf, d)
		return tfvector(tf,d):normalise()
	end
	
--- Applies the rotation, position, and scale transform to a given vector.
-- @function Transform3D:transformPoint
-- @tparam Vector3 v The vector to apply the transform to.
-- @return Vector3
-- @usage myTransform:transformPoint(vector.up3)

--- Applies the rotation, position, and scale transform to a given vector.
-- @function Transform3D:apply
-- @tparam Vector3 v The vector to apply the transform to.
-- @return Vector3
-- @usage myTransform:apply(vector.up3)
	local function tfpoint(tf, p)
		local m = getMat(tf)
		p = tfvector(tf, p)
		for i = 1,3 do
			p[i] = p[i]+m[12+i]
		end
		return p
	end
	
--- Applies the inverse rotation and scale (but not position) to a given vector.
-- @function Transform3D:invTransformVector
-- @tparam Vector3 v The vector to apply the inverse transform to.
-- @return Vector3
-- @usage myTransform:invTransformVector(vector.up3)
	local function invtfvector(tf, v)
		local m = getInvMat(tf)
		local t = vector.zero3
			for i=1,3,1 do
				local n = (i-1)*4
				local vi = v[i]
				for j=1,3,1 do
					t[j] = t[j] + vi*m[n + j]
				end
			end
		return t
	end
	
--- Applies the inverse rotation (but not position or scale) to a given vector.
-- @function Transform3D:invTransformDirection
-- @tparam Vector3 v The vector to apply the inverse transform to.
-- @return Vector3
-- @usage myTransform:invTransformDirection(vector.up3)

--- Applies the inverse rotation (but not position or scale) to a given vector.
-- @function Transform3D:invTransformDir
-- @tparam Vector3 v The vector to apply the inverse transform to.
-- @return Vector3
-- @usage myTransform:invTransformDir(vector.up3)
	local function invtfdir(tf, d)
		return invtfvector(tf,d):normalise()
	end
	
--- Applies the inverse rotation, position, and scale transform to a given vector.
-- @function Transform3D:invTransformPoint
-- @tparam Vector3 v The vector to apply the inverse transform to.
-- @return Vector3
-- @usage myTransform:invTransformPoint(vector.up3)
	local function invtfpoint(tf, p)
		local t = getInvMat(tf)*v4(p[1], p[2], p[3], 1)
		return v3(t[1],t[2],t[3])
	end
	
	
--- Rotates the transform to look at the given vector position.
-- @function Transform3D:lookAt
-- @tparam Vector3 v The vector to look towards.
-- @usage myTransform:lookAt(myPosition)
	local function lookAt(tf, b)
		local d = (b-getWorldPos(tf)):normalise()
		local u = d^tf.wup^d
		local q = quat()
		q:lookTo(d,u)
		setWorldRot(tf, q)
	end
	
--- Removes all children from the transform.
-- @function Transform3D:detachChildren
	local function detachChildren(tf)
		for _,v in ipairs(tf.children) do
			addChild(nil, v)
		end
	end
	
	
--- Gets the sibling index (index into the parent's children list) of the object. Returns 0 if no parent exists.
-- @function Transform3D:getSiblingIndex
-- @return int

--- Sets the sibling index (index into the parent's children list) of the object. Other siblings will be shifted to accommodate.
-- @function Transform3D:setSiblingIndex
-- @tparam int index The new sibling index.

--- Sets the sibling index such that this transform will be first in the parent's children list.
-- @function Transform3D:setFirstSibling

--- Sets the sibling index such that this transform will be last in the parent's children list.
-- @function Transform3D:setLastSibling

	local tfmt = {}

	tfmt.__index = function(tbl,key)
		if key == "getMat" then
			return getMat
		elseif key == "obj2world" then
			return getMat(tbl)
		elseif key == "getMatLocal" then
			return getMatLocal
		elseif key == "getInvMat" then
			return getInvMat
		elseif key == "world2obj" then
			return getInvMat(tbl)
		elseif key == "getInvMatLocal" then
			return getInvMatLocal
		elseif key == "setDirty" then
			return setDirty
		elseif key == "addChild" then
			return addChild
		elseif key == "setParent" then
			return setParent
		elseif key == "position" then
			return tbl[1]
		elseif key == "rotation" then
			return tbl[2]
		elseif key == "scale" then
			return tbl[3]
		elseif key == "wposition" then
			return getWorldPos(tbl)
		elseif key == "wscale" then
			return getWorldScale(tbl)
		elseif key == "wrotation" then
			return getWorldRot(tbl)
		elseif key == "parent" then
			return tbl.__parent
		elseif key == "forward" then
			return tbl.rotation*vector.forward3
		elseif key == "up" then
			return tbl.rotation*vector.up3
		elseif key == "right" then
			return tbl.rotation*vector.right3
		elseif key == "wforward" then
			return getWorldRot(tbl)*vector.forward3
		elseif key == "wup" then
			return getWorldRot(tbl)*vector.up3
		elseif key == "wright" then
			return getWorldRot(tbl)*vector.right3
		elseif key == "lookAt" then
			return lookAt
		elseif key == "rotate" then
			return rotate
		elseif key == "translate" then
			return translate
		elseif key == "transformPoint" or key == "apply" then
			return tfpoint
		elseif key == "transformVector" then
			return tfvector
		elseif key == "transformDirection" or key == "transformDir" then
			return tfdir
		elseif key == "detachChildren" then
			return detachChildren
		elseif key == "getSiblingIndex" then
			return getSibling
		elseif key == "setSiblingIndex" then
			return setSibling
		elseif key == "siblingIdx" then
			return getSibling(tbl)
		elseif key == "setFirstSibling" then
			return setFirstSibling
		elseif key == "setLastSibling" then
			return setLastSibling
		elseif key == "invTransformPoint" then
			return invtfpoint
		elseif key == "invTransformVector" then
			return invtfvector
		elseif key == "invTransformDirection" or key == "invTransformDir" then
			return invtfdir
		elseif key == "root" then
			return getRoot(tf)
		end
	end

	tfmt.__newindex = function(tbl,key,val)
		if key == "position" then
			tbl[1] = val
			setDirty(tbl)
		elseif key == "rotation" then
			tbl[2] = val
			setDirty(tbl)
		elseif key == "scale" then
			tbl[3] = val
			setDirty(tbl)
		elseif key == "parent" then
			tf3dTypecheck(val, 2)
			addChild(val, tbl)
		elseif key == "forward" then
			tbl.rotation = lookInDir(tbl, val, tbl.up)
		elseif key == "up" then
			tbl.rotation = lookInDir(tbl, tbl.forward, val)
		elseif key == "right" then
			val = val:normalise()
			local f = val^tbl.forward^val
			tbl.rotation = lookInDir(tbl, f, f^val)
		elseif key == "wposition" then
			setWorldPos(tbl, val)
		elseif key == "wscale" then
			setWorldScale(tbl,val)
		elseif key == "wrotation" then
			setWorldRot(tbl, val)
		elseif key == "wforward" then
			setWorldRot(tbl, quat(vector.forward3, val))
		elseif key == "wup" then
			setWorldRot(tbl, quat(vector.up3, val))
		elseif key == "wright" then
			setWorldRot(tbl, quat(vector.right3, val))
		elseif key == "siblingIdx" then
			return setSibling(tbl, val)
		end
	end

	tfmt.__ipairs = iterate
	tfmt.__pairs = iterate
	
	tfmt.__tostring = function(tbl)
		return "{ Position: "..tostring(tbl[1]) ..",\nRotation: "..tostring(tbl[2].euler)..",\nScale: "..tostring(tbl[3]).." }"
	end
	tfmt.__len = tflen
	
	tfmt.__type = "Transform3D"
	
	function transform.new3d(position, rotation, scale)
		local t = {position or vector.zero3, rotation or vector.quatid, scale or vector.one3, children = {}, __dirty = true, __invdirty = true, __locdirty = true, __invlocdirty = true}
		t.__comp = {cv3(t[1]), cquat(t[2]), cv3(t[3])}
		
		setmetatable(t,tfmt)
		
		return t
	end
end


do	--2D transforms
	
	
--- A 2D Transform object
-- @type Transform

---
-- @tparam Mat3 obj2world (READ-ONLY) The object-space to world-space transformation matrix, effectively the transform's state matrix.
-- @tparam Mat3 world2obj (READ-ONLY)The world-space to object-space transformation matrix, effectively the inverse transform's state matrix.
-- @tparam Vector2 position The object-space position of the transform.
-- @tparam number rotation The object-space rotation of the transform in degrees.
-- @tparam Vector2 scale The object-space scale of the transform.
-- @tparam Vector2 wposition The world-space position of the transform. Can only be modified via direct assignment.
-- @tparam number wrotation The world-space rotation of the transform in degrees. Can only be modified via direct assignment.
-- @tparam Vector2 wscale The world-space scale of the transform. Can only be modified via direct assignment.
-- @tparam Transform parent The parent object of the transform. Will be `nil` if no parent exists.
-- @tparam Vector2 up The object-space up vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector2 right The object-space right vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector2 wup The world-space up vector of the transform. Can only be modified via direct assignment.
-- @tparam Vector2 wright The world-space right vector of the transform. Can only be modified via direct assignment.
-- @tparam int siblingIdx The sibling index of the transform (i.e. the position in the parent's children list).
-- @tparam Transform root (READ-ONLY) The top-level object of the scene hierarchy (effectively the topmost "parent" object).
-- @table _
	
	local getMat
	
	local sin = math.sin
	local cos = math.cos
	local rad = math.rad
	local deg = math.deg
	local atan2 = math.atan2
	
	local function checkDirty(tf)
		local c = tf.__comp
		
		local update = false
		for i = 1,3,2 do
			for j = 1,2 do
				if c[i][j] ~= tf[i][j] then
					update = true
					break
				end
			end
			if update then
				break
			end
		end
		
		if  update or c[2] ~= tf[2] then
			tf.__comp[1] = cv2(tf[1])
			tf.__comp[2] = tf[2]
			tf.__comp[3] = cv2(tf[3])
			setDirty(tf)
		end
	end
	
	local function isDirty(tf)
		if tf.__dirty or (tf.__parent ~= nil and isDirty(tf.__parent)) then
			return true
		else
			checkDirty(tf)
			return tf.__dirty
		end
	end
	
	local function isDirtyLocal(tf)
		if tf.__locdirty then
			return true
		else
			checkDirty(tf)
			return tf.__locdirty
		end
	end
	
	local function isInvDirty(tf)
		if tf.__invdirty or (tf.__parent ~= nil and isInvDirty(tf.__parent)) then
			return true
		else
			checkDirty(tf)
			return tf.__invdirty
		end
	end
	
	local function isInvDirtyLocal(tf)
		if tf.__invlocdirty then
			return true
		else
			checkDirty(tf)
			return tf.__invlocdirty
		end
	end
	
	local function rotmat(r)
		r = rad(r)
		local s = sin(r)
		local c = cos(r)
		
		return mat3(c,s,0,  -s,c,0,  0,0,1)
	end

	local function calcMatLocal(tf)
		local m = rotmat(tf[2])
		
		--Faster equivalent to matrix multiplication, making assumptions about the nature of the matrices we're multiplying (assumptions which necessarily hold)
		
		local sc = tf[3]
		--Apply scale mod
		for s = 1,2 do
			local v = sc[s]
			for i = 1,2 do
				m[i+(s-1)*3] = m[i+(s-1)*3]*v
			end
		end
		
		
		local p = tf[1]
		--Apply position
		for i = 1,2 do
			m[6+i] = p[i]
		end
		
		--Mp * Mr * Ms - Application order = Scale > Rotation > Position
		rawset(tf, "__matloc", m)
		tf.__locdirty = false
		--rawset(tf, "__locdirty", false)
	end
	
	local function calcInvMatLocal(tf)
		local m = rotmat(-tf[2])
		
		--Faster equivalent to matrix multiplication, making assumptions about the nature of the matrices we're multiplying (assumptions which necessarily hold)
		
		local sc = tf[3]
		--Apply scale mod
		for s = 1,2 do
			local v = sc[s]
			for i = 1,2 do
				m[s+(i-1)*3] = m[s+(i-1)*3]/v
			end
		end
		
		
		local p = tf[1]
		--Apply position
		for i = 1,2 do
			m[6+i] = -m[i]*p[1] - m[3+i]*p[2]
		end
		
		
		rawset(tf, "__invmatloc", m)
		tf.__invlocdirty = false
		--rawset(tf, "__invlocdirty", false)
	end
	
--- Returns the parent-space to object-space transformation matrix.
-- @function Transform:getInvMatLocal
-- @return Mat3
	local function getInvMatLocal(tf)
		if tf.__invmatloc == nil or isInvDirtyLocal(tf) then
			calcInvMatLocal(tf)
		end
		
		return tf.__invmatloc
	end

--- Returns the object-space to parent-space transformation matrix.
-- @function Transform:getMatLocal
-- @return Mat3
	local function getMatLocal(tf)
		if tf.__matloc == nil or isDirtyLocal(tf) then
			calcMatLocal(tf)
		end
		
		return tf.__matloc
	end
	
	local function getPosFromMat(m)
		return v2(m[7], m[8])
	end
	
	local function getScaleFromMat(m)
		local s = vector.zero2
		for i = 1,2 do
			local t = 0
			for j = 1,2 do
				local v = m[j + (i-1)*3]
				t = t + v*v
			end
			s[i] = sqrt(t)
		end
		
		return s
	end
	
	local function getRotAndScaleFromMat(m)
		local s = getScaleFromMat(m)
		local r = deg(atan2(m[2]/s[1], m[5]/s[2]))
		
		return r,s
	end

	local function getFromMat(m)
		local p = getPosFromMat(m)
		local r,s = getRotAndScaleFromMat(m)
		
		return p,r,s
	end

	local function calcMat(tf)
		local m = getMatLocal(tf)
		
		local p = tf.__parent
		
		while p do
			if p.__mat ~= nil and not isDirty(p) then
				m = m3mul(p.__mat, m)
				break
			else
				m = m3mul(getMatLocal(p), m)
				p = p.__parent
			end
		end
		
		rawset(tf, "__mat", m)
		tf.__dirty = false
		--rawset(tf, "__dirty", false)
	end

--- Returns the object-space to world-space transformation matrix.
-- @function Transform:getMat
-- @return Mat3
	getMat = function(tf)
		if tf.__mat == nil or isDirty(tf) then
			calcMat(tf)
		end
		return tf.__mat
	end
	
	local function calcInvMat(tf)
		local m = getInvMatLocal(tf)
		
		local p = tf.__parent
		
		while p do
			if p.__invmat ~= nil and not isInvDirty(p) then
				m = m3mul(m, p.__invmat)
				break
			else
				m = m3mul(m, getInvMatLocal(p))
				p = p.__parent
			end
		end
		
		rawset(tf, "__invmat", m)
		tf.__invdirty = false
		--rawset(tf, "__invdirty", false)
	end
	

--- Returns the world-space to object-space transformation matrix.
-- @function Transform:getInvMat
-- @return Mat3
	local function getInvMat(tf)
		--equivalent to:
		--return getMat(tf).inverse
		
		if tf.__invmat == nil or isInvDirty(tf) then
			calcInvMat(tf)
		end
		return tf.__invmat
	end

--- Attaches an object as a child of the transform.
-- @function Transform:addChild
-- @tparam Transform child The child transform to attach (will be removed from its current parent if it has one).
-- @tparam[opt=true] bool keepWorld Whether the child should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage myTransform:addChild(myOtherTransform)
-- @usage myTransform:addChild(myOtherTransform, false)
	local function addChild(tfp, tfc, keepWorld)
		tfTypecheck(tfp, 2)
		tfTypecheck(tfc, 2)
		if keepWorld == nil then
			keepWorld = true
		end
		
		if tfp ~= nil and isChild(tfc, tfp) then
			addChild(nil, tfp)
		end
		
		if keepWorld then
			
			local m = getMat(tfc)
			
			if tfp ~= nil then
				m = m3mul(getInvMat(tfp), m)
			end
		
			--Get world space mat and multiply with inverse of new parent mat
			local p,r,s = getFromMat(m)
			
			tfc[1] = p
			tfc[2] = r
			tfc[3] = s
		end
		
		if tfc.__parent ~= nil then
			remove(tfc.__parent.children, table.ifind(tfc.__parent.children, tfc))
		end
		
		if tfp ~= nil then
			insert(tfp.children, tfc)
		end
		rawset(tfc, "__parent", tfp)
		setDirty(tfc, not keepWorld)
	end

--- Sets the parent of the transform.
-- @function Transform:setParent
-- @tparam[opt] Transform parent The parent transform to attach to (will remove the transform from its current parent if it has one). Supplying `nil` will remove the transform from its parent.
-- @tparam[opt=true] bool keepWorld Whether the transform should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage myTransform:setParent(myOtherTransform)
-- @usage myTransform:setParent(myOtherTransform, false)
-- @usage myTransform:setParent(nil)
	local function setParent(tf, parent, keepWorld)	
		tfTypecheck(tf, 2)
		tfTypecheck(parent, 2)
		addChild(parent, tf, keepWorld)
	end
	
	local function lookInDir(dir)
		return deg(atan2(dir[2], dir[1]))-90
	end
	
	local function getWorldPos(tf)
		if tf.__parent == nil then
			return cv2(tf[1])
		end
		local m = getMat(tf)
		return v2(m[7],m[8])
	end
	
	local function getWorldScale(tf)
		if tf.__parent == nil then
			return cv2(tf[3])
		end
		local m = getMat(tf)
		local s = vector.zero2
		for i = 1,2 do
			local t = 0
			local n = (i-1)*3
			for j = 1,2 do
				t = t + m[n + j]*m[n + j]
			end
			s[i] = sqrt(t)
		end
		return s
	end
	
	local function getWorldRot(tf)
		if tf.__parent == nil then
			return tf[2]
		end
		local s = getWorldScale(tf)
		local m = getMat(tf)
		
		return deg(atan2(m[2]/s[1], m[5]/s[2]))
	end
	
	local function setWorldPos(tf, v)
		if tf.__parent == nil then
			tf[1] = cv2(v)
		else
			local m = getMat(tf)
			m = cmat3(m)
			m[7] = v[1]
			m[8] = v[2]
			
			m = m3mul(getInvMat(tf.__parent), m)
			local p = getPosFromMat(m)
			
			tf[1][1] = p[1]
			tf[1][2] = p[2]
		end
		setDirty(tf)
	end
	
	local function setWorldScale(tf, v)
		if tf.__parent == nil then
			tf[3] = cv2(v)
		else
			local s = getWorldScale(tf)
			tf[3][1] = tf[3][1] * v[1]/s[1]
			tf[3][2] = tf[3][2] * v[2]/s[2]
		end
		setDirty(tf)
	end
	
	local function setWorldRot(tf, v)
		if tf.__parent == nil then
			tf[2] = v
		else
			local m = getMat(tf)
			m = cmat3(m)
			
			local sc = getWorldScale(tf)
			
			local a = rad(v)
			local c = cos(a)
			local s = sin(a)
			
			m[1] = c	* sc[1]
			m[2] = s	* sc[1]
			m[4] = -s	* sc[2]
			m[5] = c	* sc[2]
			
			m = m3mul(getInvMat(tf.__parent), m)
			local r = getRotAndScaleFromMat(m)
			
			tf[2] = r
		end
		setDirty(tf)
	end
	
--- Rotates the transform by the given angle.
-- @function Transform:rotate
-- @tparam number angle The angle to rotate by.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space (this is extremely unlikely to be necessary).
-- @usage myTransform:rotate(myAngle)
	local function rotate(tf, a, worldspace)
		if worldspace then
			setWorldRot(tf, getWorldRot(tf)+a)
		else
			tf[2] = tf[2]+a
			setDirty(tf)
		end
	end

--- Moves the transform by the given vector.
-- @function Transform:translate
-- @tparam Vector2 v The motion vector to apply.
-- @tparam[opt=false] bool worldspace Whether the motion should be applied in world-space.
-- @usage myTransform:translate(vector.up2, true)
	local function translate(tf, v, worldspace)
		if worldspace then
			local w = getWorldPos(tf)
			for i = 1,2 do
				w[i] = w[i]+v[i]
			end
			setWorldPos(tf, w)
		else
			for i = 1,2 do
				tf[1][i] = tf[1][i]+v[i]
			end
			setDirty(tf)
		end
	end
	
--- Applies the rotation and scale (but not position) to a given vector.
-- @function Transform:transformVector
-- @tparam Vector2 v The vector to apply the transform to.
-- @return Vector2
-- @usage myTransform:transformVector(vector.up2)
	local function tfvector(tf, v)
		local m = getMat(tf)
		local t = vector.zero2
			for i=1,2,1 do
				local n = (i-1)*3
				local vi = v[i]
				for j=1,2,1 do
					t[j] = t[j] + vi*m[n + j]
				end
			end
		return t
	end
	
--- Applies the rotation (but not position or scale) to a given vector.
-- @function Transform:transformDirection
-- @tparam Vector2 v The vector to apply the transform to.
-- @return Vector2
-- @usage myTransform:transformDirection(vector.up2)

--- Applies the rotation (but not position or scale) to a given vector.
-- @function Transform:transformDir
-- @tparam Vector2 v The vector to apply the transform to.
-- @return Vector2
-- @usage myTransform:transformDir(vector.up2)
	local function tfdir(tf, d)
		return tfvector(tf,d):normalise()
	end
	
--- Applies the rotation, position, and scale transform to a given vector.
-- @function Transform:transformPoint
-- @tparam Vector2 v The vector to apply the transform to.
-- @return Vector2
-- @usage myTransform:transformPoint(vector.up2)

--- Applies the rotation, position, and scale transform to a given vector.
-- @function Transform:apply
-- @tparam Vector2 v The vector to apply the transform to.
-- @return Vector2
-- @usage myTransform:apply(vector.up2)
	local function tfpoint(tf, p)
		local m = getMat(tf)
		p = tfvector(tf, p)
		for i = 1,2 do
			p[i] = p[i]+m[6+i]
		end
		return p
	end
	
--- Applies the inverse rotation and scale (but not position) to a given vector.
-- @function Transform:invTransformVector
-- @tparam Vector2 v The vector to apply the inverse transform to.
-- @return Vector2
-- @usage myTransform:invTransformVector(vector.up2)
	local function invtfvector(tf, v)
		local m = getInvMat(tf)
		local t = vector.zero2
			for i=1,2,1 do
				local n = (i-1)*3
				local vi = v[i]
				for j=1,2,1 do
					t[j] = t[j] + vi*m[n + j]
				end
			end
		return t
	end
	
--- Applies the inverse rotation (but not position or scale) to a given vector.
-- @function Transform:invTransformDirection
-- @tparam Vector2 v The vector to apply the inverse transform to.
-- @return Vector2
-- @usage myTransform:invTransformDirection(vector.up2)

--- Applies the inverse rotation (but not position or scale) to a given vector.
-- @function Transform:invTransformDir
-- @tparam Vector2 v The vector to apply the inverse transform to.
-- @return Vector2
-- @usage myTransform:invTransformDir(vector.up2)
	local function invtfdir(tf, d)
		return invtfvector(tf,d):normalise()
	end
	
--- Applies the inverse rotation, position, and scale transform to a given vector.
-- @function Transform:invTransformPoint
-- @tparam Vector2 v The vector to apply the inverse transform to.
-- @return Vector2
-- @usage myTransform:invTransformPoint(vector.up2)
	local function invtfpoint(tf, p)
		local t = getInvMat(tf)*v3(p[1],p[2],1)
		return v2(t[1],t[2])
	end
	
--- Rotates the transform to look at the given vector position.
-- @function Transform:lookAt
-- @tparam Vector2 v The vector to look towards.
-- @usage myTransform:lookAt(myPosition)
	local function lookAt(tf, b)
		local d = (b-getWorldPos(tf)):normalise()
		setWorldRot(tf, lookInDir(d))
	end
	
--- Removes all children from the transform.
-- @function Transform:detachChildren
	local function detachChildren(tf)
		for _,v in ipairs(tf.children) do
			addChild(nil, v)
		end
	end
	
--- Gets the sibling index (index into the parent's children list) of the object. Returns 0 if no parent exists.
-- @function Transform:getSiblingIndex
-- @return int

--- Sets the sibling index (index into the parent's children list) of the object. Other siblings will be shifted to accommodate.
-- @function Transform:setSiblingIndex
-- @tparam int index The new sibling index.

--- Sets the sibling index such that this transform will be first in the parent's children list.
-- @function Transform:setFirstSibling

--- Sets the sibling index such that this transform will be last in the parent's children list.
-- @function Transform:setLastSibling
	
	local tfmt = {}

	tfmt.__index = function(tbl,key)
		if key == "getMat" then
			return getMat
		elseif key == "obj2world" then
			return getMat(tbl)
		elseif key == "getMatLocal" then
			return getMatLocal
		elseif key == "getInvMat" then
			return getInvMat
		elseif key == "world2obj" then
			return getInvMat(tbl)
		elseif key == "getInvMatLocal" then
			return getInvMatLocal
		elseif key == "setDirty" then
			return setDirty
		elseif key == "addChild" then
			return addChild
		elseif key == "setParent" then
			return setParent
		elseif key == "position" then
			return tbl[1]
		elseif key == "rotation" then
			return tbl[2]
		elseif key == "scale" then
			return tbl[3]
		elseif key == "wposition" then
			return getWorldPos(tbl)
		elseif key == "wscale" then
			return getWorldScale(tbl)
		elseif key == "wrotation" then
			return getWorldRot(tbl)
		elseif key == "parent" then
			return tbl.__parent
		elseif key == "up" then
			return tbl.rotation*vector.up2
		elseif key == "right" then
			return tbl.rotation*vector.right2
		elseif key == "wup" then
			local r = rad(getWorldRot(tbl))
			return v2(-sin(r), cos(r))
		elseif key == "wright" then
			local r = rad(getWorldRot(tbl))
			return v2(cos(r), sin(r))
		elseif key == "lookAt" then
			return lookAt
		elseif key == "rotate" then
			return rotate
		elseif key == "translate" then
			return translate
		elseif key == "transformPoint" or key == "apply" then
			return tfpoint
		elseif key == "transformVector" then
			return tfvector
		elseif key == "transformDirection" or key == "transformDir" then
			return tfdir
		elseif key == "detachChildren" then
			return detachChildren
		elseif key == "getSiblingIndex" then
			return getSibling
		elseif key == "setSiblingIndex" then
			return setSibling
		elseif key == "siblingIdx" then
			return getSibling(tbl)
		elseif key == "setFirstSibling" then
			return setFirstSibling
		elseif key == "setLastSibling" then
			return setLastSibling
		elseif key == "invTransformPoint" then
			return invtfpoint
		elseif key == "invTransformVector" then
			return invtfvector
		elseif key == "invTransformDirection" or key == "invTransformDir" then
			return invtfdir
		elseif key == "root" then
			return getRoot(tf)
		end
	end

	tfmt.__newindex = function(tbl,key,val)
		if key == "position" then
			tbl[1] = val
			setDirty(tbl)
		elseif key == "rotation" then
			tbl[2] = val
			setDirty(tbl)
		elseif key == "scale" then
			tbl[3] = val
			setDirty(tbl)
		elseif key == "parent" then
			tfTypecheck(val, 2)
			addChild(val, tbl)
		elseif key == "up" then
			tbl.rotation = lookInDir(val:normalise())
		elseif key == "right" then
			tbl.rotation = lookInDir(val:normalise())+90
		elseif key == "wposition" then
			setWorldPos(tbl, val)
		elseif key == "wscale" then
			setWorldScale(tbl,val)
		elseif key == "wrotation" then
			setWorldRot(tbl, val)
		elseif key == "wup" then
			return setWorldRot(tbl, lookInDir(val:normalise()))
		elseif key == "wright" then
			return setWorldRot(tbl, lookInDir(val:normalise())+90)
		elseif key == "siblingIdx" then
			return setSibling(tbl, val)
		end
	end

	
	tfmt.__ipairs = iterate
	tfmt.__pairs = iterate

	tfmt.__tostring = function(tbl)
		return "{ Position: "..tostring(tbl[1]) ..",\nRotation: "..tostring(tbl[2])..",\nScale: "..tostring(tbl[3]).." }"
	end
	tfmt.__len = tflen
	
	tfmt.__type = "Transform"
	
	
	function transform.new2d(position, rotation, scale)
		local t = {position or vector.zero2, rotation or 0, scale or vector.one2, children = {}, __dirty = true, __invdirty = true, __locdirty = true, __invlocdirty = true}
		t.__comp = {cv2(t[1]), t[2], cv2(t[3])}
		
		setmetatable(t,tfmt)
		
		return t
	end
end

function transform.new(position, rotation, scale)
	if position == nil and rotation == nil and scale == nil then
		return transform.new2d()
	elseif type(position) == "Vector3" or type(rotation) == "Quaternion" or type(scale) == "Vector3" then
		return transform.new3d(position, rotation, scale)
	else
		return transform.new2d(position, rotation, scale)
	end
end


--- Functions.
-- @section Functions

--- Creates a @{Transform3D} object.
-- @function transform.new3d
-- @tparam[opt=zero3] Vector3 position The position of the transform.
-- @tparam[opt=identity] Quaternion rotation The rotation of the transform.
-- @tparam[opt=one3] Vector3 scale The scale of the transform.
-- @usage Transform.new3d(vector.zero3, vector.quatid, vector.one3)

--- Creates a @{Transform} object.
-- @function transform.new2d
-- @tparam[opt=zero2] Vector2 position The position of the transform.
-- @tparam[opt=0] number rotation The rotation of the transform in degrees.
-- @tparam[opt=one2] Vector2 scale The scale of the transform.
-- @usage Transform.new2d(vector.zero2, 0, vector.one2)


--- Creates a @{Transform} object.
-- @function transform.new
-- @tparam[opt=zero2] Vector2 position The position of the transform.
-- @tparam[opt=0] number rotation The rotation of the transform in degrees.
-- @tparam[opt=one2] Vector2 scale The scale of the transform.
-- @usage Transform.new(vector.zero2, 0, vector.one2)

--- Creates a @{Transform3D} object. If no arguments are supplied, a 2D @{Transform} object will be generated.
-- @function transform.new
-- @tparam[opt=zero3] Vector3 position The position of the transform.
-- @tparam[opt=identity] Quaternion rotation The rotation of the transform.
-- @tparam[opt=one3] Vector3 scale The scale of the transform.
-- @usage Transform.new(vector.zero3, vector.quatid, vector.one3)

local global_mt = {
	__call = function(a, p,r,s)
		return transform.new(p,r,s)
	end
}

setmetatable(transform, global_mt)

return transform