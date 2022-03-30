---
--@script Sprite

local sprite = {}

local sfind = string.find
local ssub = string.sub

local ceil = math.ceil
local floor = math.floor
local pi = math.pi
local twopi = pi*2
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local min = math.min
local max = math.max
local huge = math.huge

local insert = table.insert

--Local fast v2 creation
local v2mt = getmetatable(vector.zero2)
local function v2(x,y)
	return setmetatable({x, y}, v2mt);
end

--Local fast v3 creation
local v3mt = getmetatable(vector.zero3)
local function v3(x,y,z)
	return setmetatable({x, y, z}, v3mt);
end

---A set of useful alignment constants. Alignment fields can take any Vector2 with values between 0 and 1, or a value from this set.
-- @param TOP Align in the top-middle.
-- @param BOTTOM Align in the bottom-middle.
-- @param LEFT Align in the middle-left.
-- @param RIGHT Align in the middle-right.
-- @param CENTER Align in the middle (aliases: `CENTRE`, `MIDDLE`).
-- @param TOPLEFT Align in the top-left.
-- @param TOPRIGHT Align in the top-right.
-- @param BOTTOMLEFT Align in the bottom-left.
-- @param BOTTOMRIGHT Align in the bottom-right.
-- @table align
-- @usage Sprite.align.TOPLEFT

sprite.align = { 
					TOP = v2(0.5,0), 
					BOTTOM = v2(0.5,1), 
					LEFT = v2(0,0.5), 
					RIGHT = v2(1,0.5), 
					CENTRE = v2(0.5,0.5), 
					TOPLEFT = v2(0,0),
					TOPRIGHT = v2(1,0),
					BOTTOMLEFT = v2(0,1),
					BOTTOMRIGHT = v2(1,1)
				}

sprite.align.CENTER = sprite.align.CENTRE
sprite.align.MIDDLE = sprite.align.CENTRE


---An enum for selecting how progress bars should scale.
-- @param HORIZONTAL Scale bars horizontally.
-- @param VERTICAL Scale bars vertically.
-- @param BOTH Scale bars both horizontally and vertically.
-- @table barscale
-- @usage Sprite.barscale.HORIZONTAL

sprite.barscale = { HORIZONTAL = 1, VERTICAL = -1, BOTH = 0}


--- A Sprite object
-- @type Sprite

---
-- @tparam number x The x coordinate of the sprite.
-- @tparam number y The y coordinate of the sprite.
-- @tparam Texture texture The sprite texture to use (aliases: `image`).
-- @tparam Vector2 position The object-space position of the sprite.
-- @tparam number rotation The object-space rotation of the sprite in degrees.
-- @tparam Vector2 scale The object-space scale of the sprite.
-- @tparam number width The width of the sprite (only used for box-type sprites).
-- @tparam number height The height of the sprite (only used for box-type sprites).
-- @tparam number radius The radius of the sprite (only used for circle-type sprites).
-- @tparam table(Vector2) verts The vertex list defining the sprite shape (only used for poly-type sprites).
-- @tparam Vector2 wposition The world-space position of the sprite. Can only be modified via direct assignment.
-- @tparam number wrotation The world-space rotation of the sprite.
-- @tparam Vector2 wscale The world-space scale of the sprite. Can only be modified via direct assignment.
-- @tparam Vector2 pivot The relative pivot position of the sprite object (not used in poly-type sprites) (aliases: `align`).
-- @tparam Vector2 texpivot The relative pivot position of the sprite texture (aliases: `texalign`).
-- @tparam Texture bordertexture The texture to use for the border image (not used in poly-type sprites) (aliases: `borderimage`).
-- @tparam number borderwidth The width of the sprite border. Set to 0 to use no border (not used in poly-type sprites).
-- @tparam int/table frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @tparam Transform transform The sprite object's transform.
-- @tparam Transform textransform The sprite object's texture transform.
-- @tparam integer vertexCount The number of vertices in the sprite object.
-- @tparam Vector2 texposition The relative position of the texture.
-- @tparam number texrotation The relative rotation of the texture in degrees.
-- @tparam Vector2 texscale The relative scale of the texture in pixels.
-- @tparam Vector2 texwposition The world-space position of the texture. Can only be modified via direct assignment.
-- @tparam number texwrotation The world-space rotation of the texture in degrees.
-- @tparam Vector2 texwscale The world-space scale of the texture in pixels. Can only be modified via direct assignment.
-- @tparam Transform parent The parent transform of the sprite. Will be `nil` if no parent exists.
-- @tparam Vector2 up The object-space up vector of the sprite. Can only be modified via direct assignment.
-- @tparam Vector2 right The object-space right vector of the sprite. Can only be modified via direct assignment.
-- @tparam Vector2 wup The world-space up vector of the sprite. Can only be modified via direct assignment.
-- @tparam Vector2 wright The world-space right vector of the sprite. Can only be modified via direct assignment.
-- @tparam int siblingIdx The sibling index of the sprite (i.e. the position in the parent's children list).
-- @tparam Transform root (READ-ONLY) The top-level transform of the scene hierarchy (effectively the topmost "parent" object).
-- @table _


--List of variable aliases for consistency.
local varaliases = 	{
						texture = "image",
						pivot = "align",
						texpivot = { "texturepivot", "imgpivot", "texalign", "texturealign", "imgalign" },
						bordertexture = "borderimage"
					}
					
local invaliases = {}

for k,v in pairs(varaliases) do
	if type(v) == "string" then
		invaliases[v] = k
	else
		for _,v2 in ipairs(v) do
			invaliases[v2] = k
		end
	end
end


--UPDATE TO MATCH `tffuncs` TABLE

--- Attaches an object as a child of the sprite transform.
-- @function Sprite:addChild
-- @tparam Transform child The child transform to attach (will be removed from its current parent if it has one).
-- @tparam[opt=true] bool keepWorld Whether the child should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage mySprite:addChild(myTransform)
-- @usage mySprite:addChild(myTransform, false)


--- Sets the parent of the sprite transform.
-- @function Sprite:setParent
-- @tparam[opt] Transform parent The parent transform to attach to (will remove the transform from its current parent if it has one). Supplying `nil` will remove the transform from its parent.
-- @tparam[opt=true] bool keepWorld Whether the sprite should keep its world transform when attaching. This will likely cause its local transform to change, but its global position, rotation, and scale to remain constant.
-- @usage mySprite:setParent(myTransform)
-- @usage mySprite:setParent(myTransform, false)
-- @usage mySprite:setParent(nil)


--- Rotates the sprite by the given angle.
-- @function Sprite:rotate
-- @tparam number angle The angle to rotate by.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space (this is extremely unlikely to be necessary).
-- @usage mySprite:rotate(myAngle)

--- Moves the sprite by the given vector.
-- @function Sprite:translate
-- @tparam Vector2 v The motion vector to apply.
-- @tparam[opt=false] bool worldspace Whether the motion should be applied in world-space.
-- @usage mySprite:translate(vector.up2, true)


--- Removes all children from the sprite transform.
-- @function Sprite:detachChildren
	
	
--- Gets the sibling index (index into the parent's children list) of the object. Returns 0 if no parent exists.
-- @function Sprite:getSiblingIndex
-- @return int


--- Sets the sibling index (index into the parent's children list) of the object. Other siblings will be shifted to accommodate.
-- @function Sprite:setSiblingIndex
-- @tparam int index The new sibling index.


--- Sets the sibling index such that this sprite transform will be first in the parent's children list.
-- @function Sprite:setFirstSibling


--- Sets the sibling index such that this sprite transform will be last in the parent's children list.
-- @function Sprite:setLastSibling


--List of transform functions to be directly supported.
local tffuncs = { 
					"getMat",
					"getMatLocal",
					"getInvMat",
					"getInvMatLocal",
					"addChild",
					"setParent",
					"rotate",
					"translate",
					"detachChildren",
					"getSiblingIndex",
					"setSiblingIndex",
					"setFirstSibling",
					"setLastSibling"
				}




--UPDATE TO MATCH `textffuncs` TABLE

--- Rotates the texture by the given angle.
-- @function Sprite:texrotate
-- @tparam number angle The angle to rotate by.
-- @tparam[opt=false] bool worldspace Whether the rotation should be applied in world-space (this is extremely unlikely to be necessary).
-- @usage mySprite:texrotate(myAngle)

--- Moves the texture by the given vector.
-- @function Sprite:textranslate
-- @tparam Vector2 v The motion vector to apply.
-- @tparam[opt=false] bool worldspace Whether the motion should be applied in world-space.
-- @usage mySprite:textranslate(vector.up2, true)				
				
--List of texture transform functions to be directly supported.
local textffuncs = 	{ 
						"rotate",
						"translate"
					}
				
do


	local fs = #tffuncs	
	for _,v in ipairs(tffuncs) do
		tffuncs[v] = function(s, a, b) return s.transform[v](s.transform, a, b) end
	end
	
	for i = 1,fs do
		tffuncs[i] = nil
	end
	
	fs = #textffuncs	
	for _,v in ipairs(textffuncs) do
		textffuncs["tex"..v] = function(s, a, b) return s.textransform[v](s.textransform, a, b) end
	end
	
	for i = 1,fs do
		textffuncs[i] = nil
	end
end

local function getValue(args, key)
	local val = args[key]
	if val ~= nil then 
		return val
	else
		key = varaliases[key]
		if key ~= nil then
			if type(key) == "string" then
				return args[key]
			else
				for _,v in ipairs(key) do
					val = args[v]
					if val ~= nil then
						return val
					end
				end
			end
		end
	end
end

local function getKey(key)
	return invaliases[key] or key
end
	
local function getFrames(f)
	if f == nil then
		return 1,1
	end
	
	if type(f) == "number" then
		return 1,f
	else
		return f[1] or 1, f[2] or 1
	end
end

--Local inplace mat3*v3 multiplication
local vref = {0,0,1}
local vstore = {0,0,1}
local function apply(m, x, y)
		vstore[1] = x
		vstore[2] = y
		
		for i = 1,2 do
			vref[i] = 0
		end
		
		local c = 0
		for i=1,3 do
			local s = vstore[i]
			for j=1,3 do
				vref[j] = vref[j] + s * m[c + j]
			end
			c = c+3
		end
		
		return vref
end

--local matmul = getmetatable(vector.id3).__mul

local getInvMatLocal
local getMat
local setParent

local newtf = Transform.new2d

--Local gets for matrices
do
	local tfmt = newtf()
	
	getInvMatLocal = tfmt.getInvMatLocal
	getMat = tfmt.getMat
	setParent = tfmt.setParent
end


local glDraw = Graphics.glDraw
local copyDrawTable = Graphics.__copyDrawTable
local drawverts = {}
local drawts = {}
local borderverts = {}
local drawtbl = {}


--- Draws a sprite to the screen. Accepts the same arguments as `Graphics.glDraw` (except for `vertexCoords`, `textureCoords`, `texture`, and `primitive`), plus those listed here.
-- @function Sprite:draw
-- @tparam[opt] table args
-- @tparam[opt=1] int/table args.frame The frame to draw. A table value is interpreted as an x,y coordinate, while a number is a vertical frame number.
-- @tparam[opt] Color args.bordercolor The color to tint the sprite border.
-- @tparam[opt] Shader args.bordershader The shader to apply to the sprite border.
-- @tparam[opt=uniforms] table args.borderuniforms The uniforms to pass to the sprite border shader.
-- @tparam[opt=attributes] table args.borderattributes The attributes to pass to the sprite border shader.
-- @usage mySprite:draw()
-- @usage mySprite:draw{color = Color.red, frame = {1,2}, sceneCoords = true}
local function spriteDraw(s, args)
	args = args or {}
	local vs = drawverts
	local idx = 1
	local m = getMat(s.transform)
	
	local w,h = s.__basis.getsize(s)
	local bvs = s.__basis.getverts(s)
	
	local pivot = s.pivot
	
	for _,v in ipairs(bvs) do
		--local vt = matmul(m, v3mul((v[1]-pivot[1])*w, (v[2]-pivot[1])*h))
		local vt = apply(m, (v[1]-pivot[1])*w, (v[2]-pivot[2])*h)
		vs[idx] = vt[1]
		vs[idx+1] = vt[2]
		idx = idx+2
	end
	
	for i=#vs,idx,-1 do
		vs[i] = nil
	end
	
	
	local ts
	if s.texture ~= nil then
		ts = drawts
		idx = 1
		local tm = getInvMatLocal(s.textransform)
		
		local fmx,fmy = getFrames(s.frames)
		local fx,fy = getFrames(args.frame)
		
		fx = min(max(fx,1),fmx)
		fy = min(max(fy,1),fmy)
		
		fmx = 1/fmx
		fmy = 1/fmy
		
		local texpivot = s.texpivot
		
		for _,v in ipairs(bvs) do
			--local vt = matmul(tm, v3mul((v[1]-pivot[1])*w, (v[2]-pivot[2])*h))
			local vt = apply(tm, (v[1]-pivot[1])*w, (v[2]-pivot[2])*h)
			ts[idx] = (vt[1]+texpivot[1] + fx-1)*fmx
			ts[idx+1] = (vt[2]+texpivot[2] + fy-1)*fmy
			idx = idx+2
		end
		
		for i=#vs,idx,-1 do
			vs[i] = nil
		end
	end
	
	copyDrawTable(args, drawtbl)
	
	drawtbl.vertexCoords = vs
	drawtbl.textureCoords = ts
	drawtbl.sceneCoords = drawtbl.sceneCoords or args.scene
	drawtbl.texture = s.texture
	drawtbl.primitive = s.__basis.primitive
	
	glDraw(drawtbl)
	
	if s.borderwidth > 0 then
		local prim
		ts, prim = s.__basis.getborderverts(s,bvs,borderverts)
		
		idx = 1
		
		for _,v in ipairs(borderverts) do
			--local vt = matmul(m, v3mul((v[1]-pivot[1])*w, (v[2]-pivot[2])*h))
			local vt = apply(m, (v[1]-pivot[1])*w, (v[2]-pivot[2])*h)
			vs[idx] = vt[1]
			vs[idx+1] = vt[2]
			
			idx = idx + 2
		end
		
		for i = #vs,idx,-1 do
			vs[i] = nil
		end
	
		drawtbl.vertexCoords = vs
		drawtbl.textureCoords = ts
		drawtbl.texture = s.bordertexture
		drawtbl.primitive = prim
		
		drawtbl.vertexColors = nil
		drawtbl.color = args.bordercolor
		drawtbl.shader = args.bordershader
		drawtbl.uniforms = args.borderuniforms or args.uniforms
		drawtbl.attributes = args.borderattributes or args.attributes
		
		glDraw(drawtbl)
	end
end


local function polyDraw(s, args)
	args = args or {}
	local vs = drawverts
	local idx = 1
	local m = getMat(s.transform)
	
	local bvs = s.__basis.getverts(s)
	
	for _,v in ipairs(bvs) do
		--local vt = matmul(m, v3mul(v[1], v[2]))
		local vt = apply(m, v[1], v[2])
		vs[idx] = vt[1]
		vs[idx+1] = vt[2]
		idx = idx+2
	end
	
	for i = #vs,idx,-1 do
		vs[i] = nil
	end
	
	local fx,fy = getFrames(args.frame)
	local fmx,fmy = getFrames(s.frames)
	
	fmx = 1/fmx
	fmy = 1/fmy
	
	local ts
	if s.texture ~= nil then
		ts = drawts
		idx = 1
		local tm = getInvMatLocal(s.textransform)
		for _,v in ipairs(bvs) do
			--local vt = matmul(tm, v3mul(v[1], v[2]))	
			local vt = apply(tm, v[1], v[2])
			ts[idx] = (vt[1]+s.texpivot[1] + fx-1)*fmx
			ts[idx+1] = (vt[2]+s.texpivot[2] + fy-1)*fmy
			idx = idx+2
		end
		
		for i = #ts,idx,-1 do
			ts[i] = nil
		end
	end

	copyDrawTable(args, drawtbl)
	
	drawtbl.vertexCoords = vs
	drawtbl.textureCoords = ts
	drawtbl.sceneCoords = drawtbl.sceneCoords or args.scene
	drawtbl.texture = s.texture
	drawtbl.primitive = s.__basis.primitive
	
	Graphics.glDraw(drawtbl)
end

local sprite_mt = {}

sprite_mt.__index = function(tbl,key)
	if key == "x" then
		return tbl.transform[1][1]
	elseif key == "y" then
		return tbl.transform[1][2]
	elseif key == "width" or key == "height" or key == "radius" then
		return tbl.__basis[key]
	elseif invaliases[key] then
		return tbl[getKey(key)]
	elseif key == "vertexCount" then
		return tbl:getVertexCount()
	elseif tffuncs[key] then
		return tffuncs[key]
	elseif textffuncs[key] then
		return textffuncs[key]
	elseif sfind(key, "^tex") ~= nil then
		key = ssub(key, 4)
		local t = tbl.textransform[key]
		if type(t) == "function" then
			return nil
		else
			return t
		end
	else 
		local t = tbl.transform[key]
		if type(t) == "function" then
			return nil
		else
			return t
		end
	end
end

sprite_mt.__newindex = function(tbl,key,val)
	if key == "x" then
		tbl.transform[1][1] = val
	elseif key == "y" then
		tbl.transform[1][2] = val	
	elseif key == "width" and tbl.__basis.width ~= nil and val ~= nil then
		local w = tbl.__basis.width
		
		if tbl.textransform.scale[1] == 0 then
			tbl.textransform.scale[1] = w
		else
			tbl.textransform.scale[1] = w*val/tbl.textransform.scale[1]
		end
		tbl.__basis.width = val
	elseif key == "height" and tbl.__basis.height ~= nil and val ~= nil then
		local h = tbl.__basis.height
		
		if tbl.textransform.scale[2] == 0 then
			tbl.textransform.scale[2] = h
		else
			tbl.textransform.scale[2] = h*val/tbl.textransform.scale[2]
		end
		tbl.__basis.height = val
	elseif key == "radius" and tbl.__basis.radius ~= nil and val ~= nil then
		local r = tbl.__basis.radius
		
		if tbl.textransform.scale[1] == 0 then
			tbl.textransform.scale[1] = 2*r
		else
			tbl.textransform.scale[1] = 2*r*val/tbl.textransform.scale[1]
		end
		if tbl.textransform.scale[2] == 0 then
			tbl.textransform.scale[2] = 2*r
		else
			tbl.textransform.scale[2] = 2*r*val/tbl.textransform.scale[2]
		end
		tbl.__basis.radius = val
	elseif key == "texture" then
		rawset(tbl, "texture", val)
	elseif invaliases[key] then
		tbl[getKey(key)] = val
	elseif sfind(key, "^tex") ~= nil then
		key = ssub(key, 4)
		local t = tbl.textransform[key]
		if type(t) ~= "function" then
			tbl.textransform[key] = val
		end
	else
		local t = tbl.transform[key]
		if type(t) ~= "function" then
			tbl.transform[key] = val
		end
	end
end

sprite_mt.__len = function(tbl) return tbl:getVertexCount() end

local function setupSprite(args, img, w, h, animframes, defaultpivot, prim)
	local pos = args.position
	if pos == nil and args.x ~= nil or args.y ~= nil then
		pos = v2(args.x or 0, args.y or 0)
	end
	
	local texscale = v2(1,1)
	
	if img ~= nil then
		texscale[1] = w
		texscale[2] = h
	end
	
	local piv = getValue(args, "pivot") or defaultpivot
	local tpiv = getValue(args, "texpivot") or defaultpivot
	
	local framesx, framesy = getFrames(animframes)
	
	local t = 	{	
					transform = newtf(pos, args.rotation or 0, v2(1,1)), 
					texture = img,
					pivot = piv,
					textransform = newtf(v2(texscale[1]*(tpiv[1]-piv[1]), texscale[2]*(tpiv[2]-piv[2])), 0, texscale),
					texpivot = tpiv,
					__basis = {primitive = prim},
					borderwidth = args.borderwidth or 0,
					bordertexture = args.bordertexture or args.borderimage,
					frames = animframes
				}
				
	setParent(t.textransform, t.transform, false)
		
	return t
end


do --BOX
	local boxVerts = { v2(0,0), v2(1,0), v2(1,1), v2(0,1) }

	local function getSizeBox(t)
		return t.width,t.height
	end

	local function getVertsBox(t)
		return boxVerts
	end
	
	local function getVertCountBox(t)
		return 4
	end
	
	local trd = 0.33333333333
	--local bordertx = { 0,0, trd,trd,    1,0, 1-trd,trd,    1,1, 1-trd,1-trd,    0,1, trd,1-trd,    0,0, trd,trd }
	
						--	0,1,2	2,1,3
						--	2,3,4	2,4,5
	local bordertx = { 
						0,trd, 			0,0, 		trd,trd,			trd,trd, 		0,0, 		trd,0,	
						trd,trd, 		trd,0, 		1-trd,0,			trd,trd,		1-trd,0,	1-trd,trd,
						
						1-trd,0,		1,0,		1-trd,trd,			1-trd,trd,		1,0,		1,trd,
						1-trd,trd,		1,trd,		1,1-trd,			1-trd,trd,		1,1-trd,	1-trd,1-trd,
						
						1,1-trd,		1,1,		1-trd,1-trd,		1-trd,1-trd,	1,1,		1-trd,1,
						1-trd,1-trd,	1-trd,1,	trd,1,				1-trd,1-trd,	trd,1,		trd,1-trd,
						
						trd,1,			0,1,		trd,1-trd,			trd,1-trd,		0,1,		0,1-trd,
						trd,1-trd,		0,1-trd,	0,trd,				trd,1-trd,		0,trd,		trd,trd
						
						
					 }
	
	local function getBorderVertsBox(t, verts, vs)
		local w = t.borderwidth/t.width
		local h = t.borderwidth/t.height
		
		local idx = 1
		
		local sx,sy = -1,-1
		local fx,fy = 1,0
		local t
		for i = 1,4 do
			local v = verts[i]
			
			local x,y = v[1],v[2]
			
			if i == 1 then
				vs[1] 	= v2(x+fx*w*sx, y+fy*h*sy)
				vs[2] 	= v2(x+w*sx, y+h*sy)
				vs[3] 	= v2(x,y)
			else
				vs[idx] 	= vs[idx-2]
				vs[idx+1] 	= v2(x+w*sx, y+h*sy)
				vs[idx+2] 	= vs[idx-1]
			end
			
			vs[idx+3] = vs[idx+2]
			vs[idx+4] = vs[idx+1]
			
			t = fx
			fx = fy
			fy = t
			
			vs[idx+5] = v2(x+fx*w*sx, y+fy*h*sy)
			
			vs[idx+6] = vs[idx+2]
			vs[idx+7] = vs[idx+5]
			
			if i==4 then
				vs[idx+8] = vs[1]
				vs[idx+9] = vs[idx+2]
				vs[idx+10] = vs[1]
				vs[idx+11] = vs[3]
			else
				local v_2 = verts[i+1]
				local x2,y2 = v_2[1],v_2[2]
				vs[idx+8] = v2(x2+fx*w*sx, y2+fy*h*sy)
				vs[idx+9] = vs[idx+2]
				vs[idx+10] = vs[idx+8]
				vs[idx+11] = v2(x2,y2)
			end
			
			idx = idx+12
			
			t = sy
			sy = sx
			sx = -t
		end
		
		for i = #vs,idx,-1 do
			vs[i] = nil
		end
		--[[
		local sx,sy = -1,-1
		for i=1,4 do
			local v = verts[i]
			
			vs[idx] = v2(v[1]+sx*w, v[2]+sy*h)
			vs[idx+1] = v2(v[1], v[2])
			idx = idx+2
			
			local t = sy
			sy = sx
			sx = -t
		end
		
		vs[idx] = vs[1]
		vs[idx+1] = vs[2]
		
		for i = #vs,idx+2,-1 do
			vs[i] = nil
		end
		]]
		
		
		
		return bordertx, Graphics.GL_TRIANGLES
	end

	--SEE BOTTOM OF FILE FOR DOCS
	function sprite.box(args)
		args = args or {}
		local w,h = args.width, args.height
		
		local img = getValue(args, "texture")
		local framesx,framesy = getFrames(args.frames)
		
		if img ~= nil then
			w = w or img.width/framesx
			h = h or img.height/framesy
		else
			w = w or 128
			h = h or 128
		end
		
		local t = setupSprite(args, img, w, h, args.frames, sprite.align.TOPLEFT, Graphics.GL_TRIANGLE_FAN)
					
		--t.width = w
		--t.height = h
					
		t.getVertexCount = getVertCountBox
		
		t.__basis.getsize = getSizeBox
		t.__basis.getverts = getVertsBox
		t.__basis.getborderverts = getBorderVertsBox
		t.__basis.width = w
		t.__basis.height = h
		
		t.draw = spriteDraw

		setmetatable(t, sprite_mt)
		
		return t
	end
end

do --CIRCLE
	local function getSizeCircle(t)
		return t.radius*2, t.radius*2
	end
	
	local function calcDensity(t)
		local r = t.radius+t.borderwidth
		local ws = t.wscale
		r = r * max(ws[1], ws[2])
		
		return ceil(sqrt(r)*4)
	end

	local function getVertsCircle(t)
		local density = calcDensity(t)
		
		local vs = {v2(0.5,0.5)}
		local dt = 1/density*twopi
		local theta = 0
		for i=0,density do
			insert(vs, v2((1+sin(theta))*0.5, (1-cos(theta))*0.5))
			theta = theta + dt
		end
		
		return vs
	end
	
	local ts = {}
	local function getBorderVertsCircle(t, verts, vs)
		
		local w = t.borderwidth/(t.radius*2)
		
		local dt = twopi/(#verts-2)
		local theta = 0
		local x = 0
		
		idx = 1
		
		tdx = 1
		
		for i = 2,#verts do
			local v = verts[i]
			
			vs[idx] = v2(v[1] + sin(theta)*w, v[2] -cos(theta)*w)
			vs[idx+1] = v2(v[1], v[2])
			
			--NOTE: This is susceptible to distortion from affine texture mapping.
			--However, distortino is proportional to sin(dt), and the density
			--calculation pushes dt towards 0. This means that the affine
			--distortion is negligible in practice.
			ts[tdx] = x
			ts[tdx+1] = 0
			ts[tdx+2] = x
			ts[tdx+3] = 1
			
			idx = idx + 2
			tdx = tdx + 4
			
			x = 1-x
			theta = theta + dt
		end
		
		for i = #vs,idx,-1 do
			vs[i] = nil
		end
		
		for i = #ts,tdx,-1 do
			ts[i] = nil
		end
		
		return ts, Graphics.GL_TRIANGLE_STRIP
	end
	
	local function getVertCountCircle(t)
		return calcDensity(t)+2
	end

	--SEE BOTTOM OF FILE FOR DOCS
	function sprite.circle(args)
		args = args or {}
		local d = args.radius
		
		local framesx,framesy = getFrames(args.frames)
		local img = getValue(args, "texture")
		if img ~= nil then
			d = d or min(img.width/framesx, img.height/framesy)*0.5
		else
			d = d or 64
		end
		
		local t = setupSprite(args, img, d*2, d*2, args.frames or 1, sprite.align.CENTRE, Graphics.GL_TRIANGLE_FAN)
					
		--t.radius = d
		
		t.getVertexCount = getVertCountCircle
		
		t.__basis.getsize = getSizeCircle
		t.__basis.getverts = getVertsCircle
		t.__basis.getborderverts = getBorderVertsCircle
		t.__basis.radius = d
		
		t.draw = spriteDraw

		setmetatable(t, sprite_mt)
		
		return t
	end
end

do --POLY
	
	local function findPolySize(verts)
		local minx,miny,maxx,maxy = huge,huge,-huge,-huge
		
		for _,v in ipairs(verts) do
			if v[1] < minx then
				minx = v[1]
			elseif v[1] > maxx then
				maxx = v[1]
			end
			
			if v[2] < miny then
				miny = v[2]
			elseif v[2] > maxy then
				maxy = v[2]
			end
		end
		
		return maxx-minx, maxy-miny, minx, miny
	end
	
	local function getVertsPoly(t)
		return t.verts
	end
	
	local function getVertCountPoly(t)
		return #t.verts
	end
	
	--SEE BOTTOM OF FILE FOR DOCS
	function sprite.poly(args)
		local w,h = findPolySize(args.verts)
		local img = getValue(args, "texture")
		local t = setupSprite(args, img, w, h, args.frames or 1, sprite.align.CENTRE, args.primitive or Graphics.GL_TRIANGLE_FAN)
		
		t.textransform.position = v2(0,0)
		t.verts = args.verts
		
		t.getVertexCount = getVertCountPoly
		
		t.__basis.getsize = findPolySize
		t.__basis.getverts = getVertsPoly
		
		t.draw = polyDraw

		setmetatable(t, sprite_mt)
		
		return t
	end
end

do --PROGRESS BAR
	
		
	--- A progress bar object
	-- @type Bar

	---
	-- @tparam number x The x coordinate of the bar.
	-- @tparam number y The y coordinate of the bar.
	-- @tparam number value The value to display on the bar, between 0 and 1.
	-- @tparam number trailvalue The value of the trail bar, between 0 and 1.
	-- @tparam barscale scaletype Which directions the bar should scale in.
	-- @tparam number trailspeed How fast the trail should update. 0 means no trail displayed.
	-- @tparam Texture texture The texture to use for the bar (aliases: `image`).
	-- @tparam Texture bgtexture The texture to use for the bar background (aliases: `bgimage`).
	-- @tparam Texture trailtexture The texture to use for the bar trail (aliases: `trailimage`).
	-- @tparam Vector2 position The object-space position of the bar.
	-- @tparam number rotation The object-space rotation of the bar in degrees.
	-- @tparam Vector2 scale The object-space scale of the bar.
	-- @tparam number width The width of the bar.
	-- @tparam number height The height of the bar.
	-- @tparam Vector2 wposition The world-space position of the bar. Can only be modified via direct assignment.
	-- @tparam number wrotation The world-space rotation of the bar.
	-- @tparam Vector2 wscale The world-space scale of the bar. Can only be modified via direct assignment.
	-- @tparam Vector2 pivot The relative pivot position of the bar object (aliases: `align`).
	-- @tparam Vector2 barpivot The relative pivot position of the bar itself, used to determine how the bar scales (aliases: `baralign`).
	-- @tparam Texture bgbordertexture The texture to use for the background border image. If `nil`, the `bgtexture` field will be used  (aliases: `bgborderimage`).
	-- @tparam Transform transform The bar object's root transform.
	-- @tparam Transform parent The parent transform of the bar. Will be `nil` if no parent exists.
	-- @tparam Vector2 up The object-space up vector of the bar. Can only be modified via direct assignment.
	-- @tparam Vector2 right The object-space right vector of the bar. Can only be modified via direct assignment.
	-- @tparam Vector2 wup The world-space up vector of the bar. Can only be modified via direct assignment.
	-- @tparam Vector2 wright The world-space right vector of the bar. Can only be modified via direct assignment.
	-- @tparam int siblingIdx The sibling index of the bar (i.e. the position in the parent's children list).
	-- @tparam Transform root (READ-ONLY) The top-level transform of the scene hierarchy (effectively the topmost "parent" object).
	-- @tparam bool pausetrail Set to true to pause trail updates.
	-- @tparam bool autopausetrail If true, trail updates will pause when the game is paused.
	-- @table _
	
	--List of variable aliases for bar objects for consistency.
	local baraliases = 	{
							texture = "image",
							pivot = "align",
							barpivot = "baralign",
							bgtexture = "bgimage",
							bgbordertexture = "bgborderimage",
							trailtexture = "trailimage"
						}
						
	local invbaraliases = {}

	for k,v in pairs(baraliases) do
		if type(v) == "string" then
			invbaraliases[v] = k
		else
			for _,v2 in ipairs(v) do
				invbaraliases[v2] = k
			end
		end
	end
	
	local function getSubValue(args, prefix, key)
		local val = args[prefix..key]
		if val ~= nil then 
			return val
		else
			key = varaliases[key]
			if key ~= nil then
				if type(key) == "string" then
					return args[prefix..key]
				else
					for _,v in ipairs(key) do
						val = args[prefix..v]
						if val ~= nil then
							return val
						end
					end
				end
			end
		end
	end
	
	

	--- Draws a progress bar to the screen. Accepts the same arguments as `Graphics.glDraw` (except for `vertexCoords`, `textureCoords`, `texture`, and `primitive`), plus those listed here.
	-- @function Bar:draw
	-- @tparam[opt] table args
	-- @tparam[opt] Color args.barcolor The color of the bar.
	-- @tparam[opt] Color args.bgcolor The color of the bar background.
	-- @tparam[opt] Color args.trailcolor The color of the bar trail.
	-- @tparam[opt] Shader args.bgshader The shader to apply to the bar background.
	-- @tparam[opt=uniforms] table args.bguniforms The uniforms to pass to to the bar background shader.
	-- @tparam[opt=attributes] table args.bgattributes The attributes to pass to to the bar background shader.
	-- @tparam[opt] Shader args.trailshader The shader to apply to the bar trail.
	-- @tparam[opt=uniforms] table args.trailuniforms The uniforms to pass to to the bar trail shader.
	-- @tparam[opt=attributes] table args.trailattributes The attributes to pass to to the bar trail shader.
	-- @usage myBar:draw()
	-- @usage myBar:draw{barcolor = Color.blue, bgcolor = Color.black}
	local tb = {}
	local function drawBar(b,a)
		a = a or {}
		
		
		copyDrawTable(a, tb)
	
		tb.color = a.bgcolor
		tb.bordercolor = a.bgcolor
		
		if b.bg.texture == nil then
			tb.color = a.bgcolor or Color.darkgrey
			tb.bordercolor = a.bgcolor or Color.black
		end
		
		tb.shader = a.bgshader
		tb.uniforms = a.bguniforms or a.uniforms
		tb.attributes = a.bgattributes or a.attributes
		
		tb.bordershader = tb.shader
		tb.borderuniforms = tb.uniforms
		tb.borderattributes = tb.attributes
		
		b.bg:draw(tb)
		
		local v = min(max(b.value,0),1)
		
		if b.trailspeed > 0 then
			tb.color = a.color or a.trailcolor
			if b.trailbar.texture == nil then
				tb.color = tb.color or Color.red
			end
			
			local vt = min(max(b.trailvalue,0),1)
			
			if not b.pausetrail and (not b.autopausetrail or not Misc.isPaused())then
				local spd = lunatime.toSeconds(b.trailspeed)
				if v > vt then
					b.trailvalue = min(v,b.trailvalue+spd)
				elseif v < vt then
					b.trailvalue = max(v,b.trailvalue-spd)
				end
			end
			
			if v > vt then
				local t = vt
				vt = v
				v = t
			end
			
			if b.scaletype >= 0 then
				b.trailbar.scale[1] = vt
			end
			if b.scaletype <= 0 then
				b.trailbar.scale[2] = vt
			end
			
			tb.shader = a.trailshader
			tb.uniforms = a.trailuniforms or a.uniforms
			tb.attributes = a.trailattributes or a.attributes
			
			b.trailbar:draw(tb)
		end
		
		if b.scaletype >= 0 then
			b.bar.scale[1] = v
		end
		if b.scaletype <= 0 then
			b.bar.scale[2] = v
		end
		
		tb.color = a.color or a.barcolor
		if b.bar.texture == nil then
			tb.color = tb.color or Color.green
		end
		
		tb.shader = a.shader
		tb.uniforms = a.uniforms
		tb.attributes = a.attributes
		
		b.bar:draw(tb)
	end
	
	
	local bar_mt = {}

	bar_mt.__index = function(tbl,key)
		if key == "x" then
			return tbl.transform[1][1]
		elseif key == "y" then
			return tbl.transform[1][2]
		elseif invbaraliases[key] then
			return tbl[invbaraliases[key] or key]
		elseif key == "width" or key == "height" then
			return tbl.bar[key]
		elseif key == "barpivot" then
			return v2(tbl.bar.pivot)
		elseif key == "pivot" then
			return v2(tbl.bg.pivot)
		elseif key == "bgtexture" then
			return tbl.bg.texture
		elseif key == "bgbordertexture" then
			return tbl.bg.bordertexture
		elseif key == "borderwidth" then
			return tbl.bg.borderwidth
		elseif key == "trailtexture" then
			return tbl.trailbar.texture
		elseif tffuncs[key] then
			return tffuncs[key]
		else 
			local t = tbl.transform[key]
			if type(t) == "function" then
				return nil
			else
				return t
			end
		end
	end

	bar_mt.__newindex = function(tbl,key,val)
		if key == "x" then
			tbl.transform[1][1] = val
		elseif key == "y" then
			tbl.transform[1][2] = val
		elseif invbaraliases[key] then
			tbl[invbaraliases[key] or key] = val
		elseif key == "width" or key == "height" then
			if key == "width" then
				tbl.bar.x = tbl.bar.x*val/tbl.bar.width
				tbl.trailbar.x = tbl.bar.x
			else
				tbl.bar.y = tbl.bar.y*val/tbl.bar.height
				tbl.trailbar.y = tbl.bar.y
			end
			
			tbl.bar[key] = val
			tbl.bg[key] = val
			tbl.trailbar[key] = val
			
			if tbl.bg.bordertexture == nil and tbl.bg.texture ~= nil and tbl.bg.borderwidth > 0 then
				tbl.bg.texscale[1] = 3*tbl.bg[key].width
				tbl.bg.texscale[2] = 3*tbl.bg[key].height
			end
		elseif key == "barpivot" then
			tbl.bar.x = (val[1]-tbl.bg.pivot[1])*tbl.bar.width
			tbl.bar.y = (val[2]-tbl.bg.pivot[2])*tbl.bar.height
			tbl.trailbar.x = tbl.bar.x
			tbl.trailbar.y = tbl.bar.y
			tbl.bar.pivot = val
		elseif key == "pivot" then
			tbl.bar.x = (tbl.bar.pivot[1]-val[1])*tbl.bar.width
			tbl.bar.y = (tbl.bar.pivot[2]-val[2])*tbl.bar.height
			tbl.trailbar.x = tbl.bar.x
			tbl.trailbar.y = tbl.bar.y
			tbl.bg.pivot = val
		elseif key == "bgtexture" then
			tbl.bg.texture = val
		elseif key == "bgbordertexture" then
			tbl.bg.bordertexture = val
		elseif key == "borderwidth" then
			tbl.bg.borderwidth = val
		elseif key == "trailtexture" then
			tbl.trailbar.texture = val
		else
			local t = tbl.transform[key]
			if type(t) ~= "function" then
				tbl.transform[key] = val
			end
		end
	end

	--SEE BOTTOM OF FILE FOR DOCS
	function sprite.bar(args)
		args = args or {}
		local pos = v2(args.x or 0, args.y or 0)
		local t = {	transform = newtf(pos, args.rotation or 0, v2(1,1)), value = args.value or 1, trailvalue = args.value or 1, scaletype = args.scaletype or sprite.barscale.HORIZONTAL, trailspeed=args.trailspeed or 0, pausetrail = false, autopausetrail = true}
		
		local bgimg = getSubValue(args,"bg","texture")
		local bgbimg = getSubValue(args,"bg","bordertexture")
		
		local bwidth = args.borderwidth or 2
		local bscale = v2(1,1)
		local w,h = args.width or 128, args.height or 16
		
		if bgbimg == nil and bgimg ~= nil and bwidth > 0 then
			bgbimg = bgimg
			bscale[1] = 3*w
			bscale[2] = 3*h
		end
		
		local pivot = getValue(args,"pivot") or sprite.align.TOPLEFT
		local barpivot = getSubValue(args, "bar", "pivot") or sprite.align.LEFT
		
		t.bg = sprite.box{	pivot=pivot, 
							width=w, height=h,
							texture=bgimg,
							texpivot=sprite.align.CENTRE,
							borderwidth=bwidth,
							bordertexture=bgbimg
						 }
		t.bg.texscale = bscale
		
		t.bar=sprite.box{x=(barpivot[1]-pivot[1])*t.bg.width,y=(barpivot[2]-pivot[2])*t.bg.height,pivot=barpivot,width=t.bg.width,height=t.bg.height, texture=getValue(args,"texture")}
		
		t.trailbar=sprite.box{x=t.bar.x,y=t.bar.y,pivot=barpivot,width=t.bar.width,height=t.bar.height, texture=getSubValue(args,"trail","texture")}
		
		t.bg:setParent(t.transform, false)
		t.bar:setParent(t.transform, false)
		t.trailbar:setParent(t.transform, false)
		
		t.draw = drawBar
		
		setmetatable(t, bar_mt)
		
		return t
	end

end

--- Functions.
-- @section Functions


--- Creates a box-type sprite object.
-- @function Sprite.box
-- @return @{Sprite}
-- @tparam[opt] table args
-- @tparam[opt] number args.width The width of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128.
-- @tparam[opt] number args.height The height of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128.
-- @tparam[opt] Vector2 args.position The position of the sprite.
-- @tparam[opt=0] number args.x The x position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.y The y position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.rotation The rotation of the sprite.
-- @tparam[opt] Texture args.texture The texture to use for the sprite.
-- @tparam[opt=TOPLEFT] Vector2 args.pivot The pivot location for the sprite to anchor itself to.
-- @tparam[opt=TOPLEFT] Vector2 args.texpivot The pivot location for the sprite texture to anchor itself to.
-- @tparam[opt] int/table args.frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @tparam[opt=0] number args.borderwidth The width of the sprite border (0 means no border).
-- @tparam[opt] Texture args.bordertexture The texture to use for the sprite border. Textures will be split into thirds, and stretched around the sprite box (aliases: `borderimage`).
-- @usage mySprite = Sprite.box{texture=myImage, pivot=Sprite.args.CENTER}

--- Creates a circle-type sprite object.
-- @function Sprite.circle
-- @return @{Sprite}
-- @tparam[opt] table args
-- @tparam[opt] number args.radius The radius of the circle. If not supplied, this will default to the size of one frame of the supplied texture, or 64.
-- @tparam[opt] Vector2 args.position The position of the sprite.
-- @tparam[opt=0] number args.x The x position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.y The y position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.rotation The rotation of the sprite.
-- @tparam[opt] Texture args.texture The texture to use for the sprite.
-- @tparam[opt=CENTER] Vector2 args.pivot The pivot location for the sprite to anchor itself to.
-- @tparam[opt=CENTER] Vector2 args.texpivot The pivot location for the sprite texture to anchor itself to.
-- @tparam[opt] int/table args.frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @tparam[opt=0] number args.borderwidth The width of the sprite border (0 means no border).
-- @tparam[opt] Texture args.bordertexture The texture to use for the sprite border. Textures will be tiled, flipping back and forth, around the sprite circle (aliases: `borderimage`).
-- @usage mySprite = Sprite.circle{texture=myImage, radius=32, pivot=Sprite.args.CENTER}


--- Creates a poly-type sprite object.
-- @function Sprite.poly
-- @return @{Sprite}
-- @tparam table args
-- @tparam table(Vector2) args.verts A list of vertices defining the object shape.
-- @tparam[opt] Vector2 args.position The position of the sprite.
-- @tparam[opt=0] number args.x The x position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.y The y position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.rotation The rotation of the sprite.
-- @tparam[opt] Texture args.texture The texture to use for the sprite.
-- @tparam[opt=CENTER] Vector2 args.texpivot The pivot location for the sprite texture to anchor itself to.
-- @tparam[opt] int/table args.frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @usage mySprite = Sprite.poly{verts = {vector(0,0), vector(100,100), vector(-100,100)}, texture=myImage}


--- Creates a progress bar.
-- @function Sprite.bar
-- @return @{Bar}
-- @tparam[opt] table args
-- @tparam[opt=128] number args.width The width of the bar.
-- @tparam[opt=16] number args.height The height of the bar.
-- @tparam[opt=0] number args.x The x position of the bar.
-- @tparam[opt=0] number args.y The y position of the bar.
-- @tparam[opt=0] number args.rotation The rotation of the bar.
-- @tparam[opt=1] number args.value The value to display on the bar.
-- @tparam[opt=1] barscale args.scaletype Which directions the bar should scale in.
-- @tparam[opt=TOPLEFT] Vector2 args.pivot The pivot location for the bar to anchor itself to (aliases: `align`).
-- @tparam[opt=LEFT] Vector2 args.barpivot The pivot location for the bar to scale itself against (aliases: `baralign`).
-- @tparam[opt=2] number args.borderwidth The width of the border around the bar background.
-- @tparam[opt=0] number args.trailspeed The speed of the bar trail (0 means no trail).
-- @tparam[opt] Texture args.texture The texture to use for the bar.
-- @tparam[opt] Texture args.bgtexture The texture to use for the background.
-- @tparam[opt] Texture args.bgbordertexture The texture to use for the background border (will use `bgtexture`, scaled accordingly, if not supplied).
-- @tparam[opt] Texture args.trailtexture The texture to use for the bar trail.
-- @usage myBar = Sprite.bar{x = 400, y = 500, pivot = Sprite.align.BOTTOM}


--- Creates a box object and draws it to the screen. Accepts the same arguments as `Graphics.glDraw` (except for `vertexCoords`, `textureCoords`, `texture`, and `primitive`), plus those listed here. This function is slow, and it is preferable to use @{Sprite.box}.
-- @function Sprite.draw
-- @tparam[opt] table args
-- @tparam[opt] number args.width The width of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128.
-- @tparam[opt] number args.height The height of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128.
-- @tparam[opt] Vector2 args.position The position of the sprite.
-- @tparam[opt=0] number args.x The x position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.y The y position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.rotation The rotation of the sprite.
-- @tparam[opt] Texture args.texture The texture to use for the sprite.
-- @tparam[opt=TOPLEFT] Vector2 args.pivot The pivot location for the sprite to anchor itself to.
-- @tparam[opt=TOPLEFT] Vector2 args.texpivot The pivot location for the sprite texture to anchor itself to.
-- @tparam[opt] int/table args.frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @tparam[opt=1] int/table args.frame The frame to draw. A table value is interpreted as an x,y coordinate, while a number is a vertical frame number.
-- @tparam[opt=0] number args.borderwidth The width of the sprite border (0 means no border).
-- @tparam[opt] Texture args.bordertexture The texture to use for the sprite border. Textures will be split into thirds, and stretched around the sprite box (aliases: `borderimage`).
-- @tparam[opt] Color args.bordercolor The color to tint the sprite border.
-- @tparam[opt] Shader args.bordershader The shader to apply to the sprite border.
-- @tparam[opt=uniforms] table args.borderuniforms The uniforms to pass to the sprite border shader.
-- @tparam[opt=attributes] table args.borderattributes The attributes to pass to the sprite border shader.
-- @usage Sprite.draw{texture = myImage, x = player.x, y = player.y, sceneCoords = true}
function sprite.draw(args)
	sprite.box(args):draw(args)
end


--- Creates a sprite object depending on arguments. If a `radius` is supplied, a circle-type object will be created. If a `verts` list is supplied, a poly-type object will be created. Otherwise, a box-type object will be created.
-- @function Sprite
-- @return @{Sprite}
-- @tparam[opt] table args
-- @tparam[opt] number args.width The width of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128. Only used for box-type objects.
-- @tparam[opt] number args.height The height of the box. If not supplied, this will default to the size of one frame of the supplied texture, or 128. Only used for box-type objects.
-- @tparam[opt] number args.radius The radius of the circle. Only used for circle-type objects.
-- @tparam[opt] table(Vector2) args.verts A list of vertices defining the object shape. Only used for poly-type objects.
-- @tparam[opt] Vector2 args.position The position of the sprite.
-- @tparam[opt=0] number args.x The x position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.y The y position of the sprite (only used if `position` is `nil`).
-- @tparam[opt=0] number args.rotation The rotation of the sprite.
-- @tparam[opt] Texture args.texture The texture to use for the sprite.
-- @tparam[opt=TOPLEFT] Vector2 args.pivot The pivot location for the sprite to anchor itself to. Not used for poly-type objects.
-- @tparam[opt=TOPLEFT] Vector2 args.texpivot The pivot location for the sprite texture to anchor itself to.
-- @tparam[opt] int/table args.frames The number of frames to use. Setting this to a number will assume the frame layout is a vertical list (such as SMBX NPCs). Using a two-element table will treat this as a row/column counter.
-- @tparam[opt=0] number args.borderwidth The width of the sprite border (0 means no border). Not used for poly-type objects.
-- @tparam[opt] Texture args.bordertexture The texture to use for the sprite border. If a box-type object, textures will be split into thirds, and stretched around the sprite box. If a circle-type object, textures will be tiled, flipping back and forth, around the sprite circle. Not used for poly-type objects (aliases: `borderimage`).
-- @usage mySprite = Sprite.box{texture=myImage, pivot=Sprite.args.CENTER}

local global_mt = {}

function global_mt.__call(t, args)
	if args.radius ~= nil then
		return sprite.circle(args)
	elseif args.verts ~= nil then
		return sprite.poly(args)
	else
		return sprite.box(args)
	end
end

setmetatable(sprite, global_mt)

return sprite