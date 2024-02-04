local lib3d = {}

local objreader = require("ext/objreader")

local tan = math.tan
local atan = math.atan

local rad = math.rad
local deg = math.deg
local min = math.min
local max = math.max
local abs = math.abs
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil

local tableinsert = table.insert
local tableremove = table.remove

local stringsub = string.sub

local maxLights = 10

local projection = { PERSPECTIVE = 0, ORTHOGRAPHIC = 1 }
projection.PERSP = projection.PERSPECTIVE
projection.ORTHO = projection.ORTHOGRAPHIC
lib3d.projection = projection

lib3d.debug = false
lib3d.backfaceCulling = true

local debugdata = { objects = 0, verts = 0, culled = 0, inactive = 0 }

--Define shader macro constants here
lib3d.macro = { 
				--ALPHAMODE
					ALPHA_OPAQUE = 0, 
					ALPHA_CUTOFF = 0.5, 
					ALPHA_BLEND = 1,
					ALPHA_DITHER = 2,
					
				--DEBUG
					DEBUG_OFF = 0,
					DEBUG_NORMALS = 1,
					DEBUG_DEPTH = 2,
					DEBUG_POSITION = 3,
					DEBUG_UNLIT = 4,
					DEBUG_OCCLUSION = 5,
					
				--UV_MODE
					UV_UNBOUND = 0,
					UV_WRAP = 1,
					UV_CLAMP = 2
			  }

lib3d.ambientLight = Color(0.1,0.1,0.16)
lib3d.fogColor = Color(0.5,0.7,0.8,0.5)

local function comparePrefix(k)
	if k[2] == 35678 and stringsub(k[1],1,2) == "n_" then
		return stringsub(k[1],3)
	else
		return nil
	end
end

do --Material
	local tablesort = table.sort
	
	local function setUniform(mat, key, val)
		for _,v in ipairs(mat.uniformmap) do
			if v[1] == key or v[3] == key then
				mat.uniforms[v[1]] = val
				return
			end
		end
		error("Uniform "..key.." could not be found.", 2)
	end
	
	local function getUniform(mat, key)
		return mat.uniforms[key] or mat.uniforms["n_"..key]
	end

	local function setAttribute(mat, key, val)
		for _,v in ipairs(mat.attributemap) do
			if v == key then
				mat.attributes[key] = val
				return
			end
		end
		error("Attribute "..key.." could not be found.", 2)
	end
	
	local function getAttribute(mat, key)
		return mat.attributes[key]
	end
	
	local mat_mt = {}
	
	function mat_mt.__index(tbl, key)
		return getUniform(tbl, key)
	end
	
	function mat_mt.__newindex(tbl, key, val)
		setUniform(tbl, key, val)
	end
	
	mat_mt.__type = "Material3D"
	
	--Store compiled shader and attribute pairs
	local shaderRegister = {}
	
	local function sortregister(a,b)
		return a[1] < b[1]
	end
	
	local reservedUniforms = table.map{	"cam_nearclip", "cam_farclip", "cam_position", "_dir_lightDirection", "_dir_lightColor", "_pnt_lightPosition", "_pnt_lightColor", "_ambientLight", "obj2world", "world2obj", "mat_mvp", "mat_p" }
	local reservedAttributes = table.map{ "_vertexdata", "_normaldata", "_tangentdata" }
	
	function lib3d.Material(shader, uniforms, attributes, macros)
		local t = {}
		t.getUniform = getUniform
		t.setUniform = setUniform
		t.getAttribute = getAttribute
		t.setAttribute = setAttribute
		
		if type(shader) == "Material3D" then
			t.shader = shader.shader
			t.uniformmap = table.iclone(shader.uniformmap)
			t.uniforms = {}
			for _,k in ipairs(t.uniformmap) do
				if k[3] ~= nil then
					t.uniforms[k[1]] = shader.uniforms[k[1]] or shader.uniforms[k[3]]
				else
					t.uniforms[k[1]] = shader.uniforms[k[1]]
				end
			end
			
			t.attributemap = table.iclone(shader.attributemap)
			t.attributes = {}
			for _,k in ipairs(t.attributemap) do
				t.attributes[k] = shader.attributes[k]
			end
		else
			do
				--Convert the macros to a simple list and copy them
				local mcrs = {}
				local macromap = {}
				for k,v in pairs(macros or {}) do
					tableinsert(macromap, {k,v})
					mcrs[k] = v
				end
				
				mcrs.SHADER = shader
				mcrs.NUM_LIGHTS = maxLights
				
				--Sort the macro list and insert the shader on the end
				tablesort(macromap, sortregister)
				
				tableinsert(macromap, {"SHADER", shader})
				
				--Scan the shader register
				for _,v in ipairs(shaderRegister) do
					--For each entry in the shader register, scan the macro list backwards
					--(it's done backwards so that the SHADER value is checked first)
					local found = true
					for i = #v[1],1,-1 do
						--If any value does not match, this is not an appropriate cache
						if macromap[i] == nil or v[1][i][1] ~= macromap[i][1] or v[1][i][2] ~= macromap[i][2] then
							found = false
							break
						end
					end
					
					--If we found a cache, use it
					if found then
						t.shader = v[2]
						break
					end
				end
				
				--If we didn't find a cache, compile a new shader and push it to the shader register
				if t.shader == nil then
					local s = Shader()
					s:compileFromFile("shaders/lib3d/project.vert", "shaders/lib3d/project.frag", mcrs)
					t.shader = s
					
					tableinsert(shaderRegister, {macromap, t.shader})
				end
			
			end
			
			--Make maps of uniforms and attributes for fast concatenation during drawing
			uniforms = uniforms or {}
			t.uniforms =  {}
			t.uniformmap = { {"texture", 35678 --[[sampler2d]]}, {"color", 35666--[[vec4]]} }
			
			t.attributes = attributes or {}
			t.attributemap = {}
			local lst = t.shader:getUniformInfo()
			for _,v in ipairs(lst) do
				if not reservedUniforms[v.rawName] then
					local tb = {v.rawName, v.type}
					
					--Store prefix aliased name in uniform table
					tb[3] = comparePrefix(tb)
					
					tableinsert(t.uniformmap, tb)
					
					if tb[3] ~= nil then
						t.uniforms[v.rawName] = uniforms[v.rawName] or uniforms[tb[3]]
					else
						t.uniforms[v.rawName] = uniforms[v.rawName]
					end
				end
			end
			
			t.uniforms.texture = uniforms.texture
			t.uniforms.color = uniforms.color
			
			lst = t.shader:getAttributeInfo()
			for _,v in ipairs(lst) do
				if not reservedAttributes[v.rawName] then
					tableinsert(t.attributemap, v.rawName)
				end
			end
			
		end
		
		setmetatable(t, mat_mt)
		return t
	end
	
	lib3d.defaultMaterial = lib3d.Material(nil, {roughness=1,occlusion=1,metallic=0,emissive=0})
end

local objlist = {}
local dirlightlist = {}
local pntlightlist = {}

do --Object creation
	local mesh_mt = {}
	
	function mesh_mt.__index(tbl, key)
		if key == "x" then
			return tbl.transform[1][1]
		elseif key == "y" then
			return tbl.transform[1][2]
		elseif key == "z" then
			return tbl.transform[1][2]
		elseif key == "position" then
			return tbl.transform[1]
		elseif key == "rotation" then
			return tbl.transform[2]
		elseif key == "scale" then
			return tbl.transform[3]
		elseif key == "material" then
			return tbl.materials[1] or lib3d.defaultMaterial
		end
	end
	
	function mesh_mt.__newindex(tbl, key, val)
		if key == "x" then
			tbl.transform[1][1] = val
		elseif key == "y" then
			tbl.transform[1][2] = val
		elseif key == "z" then
			tbl.transform[1][2] = val
		elseif key == "position" then
			tbl.transform[1] = val
		elseif key == "rotation" then
			tbl.transform[2] = val
		elseif key == "scale" then
			tbl.transform[3] = val
		elseif key == "material" then
			tbl.materials[1] = val
		end
	end
	
	mesh_mt.__type = "Mesh3D"
	
	local function destroyObj(obj)
		obj.isValid = false
	end
	
	lib3d.import = { axis = objreader.axis }
	
	local function findBoundingSphere(vs)
		local minx,miny,minz,maxx,maxy,maxz = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge
		for k,v in ipairs(vs) do
			if v.x < minx then
				minx = v.x
			end
			if v.x > maxx then
				maxx = v.x
			end
			if v.y < miny then
				miny = v.y
			end
			if v.y > maxy then
				maxy = v.y
			end
			if v.z < minz then
				minz = v.z
			end
			if v.z > maxz then
				maxz = v.z
			end
		end

		local w,h,d = (maxx-minx), (maxy-miny), (maxz-minz)
		
		--return radius followed by centre
		return sqrt(w*w + h*h + d*d)/2, vector.v4((maxx+minx)/2, (maxy+miny)/2, (maxz+minz)/2, 1)
	end
	
	
	--Converts obj-style face list and values into flattened arrays with other useful information
	local function parseMesh(t, vs, txs, nrms, cols, fl)
	
		if vs == nil then
			error("No vertices supplied to mesh constructor.",3)
		end
		
		--[[ old code that was very poor	
		local r = 0
		for _,v in ipairs(vs) do
			local l = v.sqrlength
			if l > r then
				r = l
			end
		end
		]]
		
		local r, c = findBoundingSphere(vs)
		t._clip_aabs = r
		t._clip_aabs_centre = c
		
		t.faces = #fl
		
		t.verts = {}
		t.normals = {}
		if txs ~= nil then
			t.texcoords = {}
		end
		if cols ~= nil then
			t.colors = {}
		end
		t.tangents = {}
		t.facenormals = {}
		
		
		for k,v in ipairs(fl) do
			--Compute face normal
			do
				--Take cross product of face vertices (i.e. compute from winding order)
				local fn1 = vs[ v[1][1] ] - vs[ v[1][3] ]
				local fn2 = vs[ v[1][2] ] - vs[ v[1][3] ]
				local n = fn1:cross(fn2):normalise()
				t.facenormals[(k-1)*3 + 1] = n[1]
				t.facenormals[(k-1)*3 + 2] = n[2]
				t.facenormals[(k-1)*3 + 3] = n[3]
				
				
				--Old method averaging normals doesn't work if normals aren't the same
				--[[
				for i = 1,3 do
					local n = t.normals[ v[3][i] ]
					fn[1] = fn[1] + n[1]
					fn[2] = fn[2] + n[2]
					fn[3] = fn[3] + n[3]
				end
				--]]
			end
			
			
			--Flatten arrays
			do
				for i = 1,3 do
					t.verts[(k-1)*9 + (i-1)*3 + 1] = vs[ v[1][i] ][1]
					t.verts[(k-1)*9 + (i-1)*3 + 2] = vs[ v[1][i] ][2]
					t.verts[(k-1)*9 + (i-1)*3 + 3] = vs[ v[1][i] ][3]
					
					if nrms and v[3] then
						t.normals[(k-1)*9 + (i-1)*3 + 1] = nrms[ v[3][i] ][1]
						t.normals[(k-1)*9 + (i-1)*3 + 2] = nrms[ v[3][i] ][2]
						t.normals[(k-1)*9 + (i-1)*3 + 3] = nrms[ v[3][i] ][3]
					else
						--Todo: use adjacent faces to compute smooth normals
						t.normals[(k-1)*9 + (i-1)*3 + 1] = t.facenormals[(k-1)*3 + 1]
						t.normals[(k-1)*9 + (i-1)*3 + 2] = t.facenormals[(k-1)*3 + 2]
						t.normals[(k-1)*9 + (i-1)*3 + 3] = t.facenormals[(k-1)*3 + 3]
					end
					
					if txs then
						if v[2] then
							t.texcoords[(k-1)*6 + (i-1)*2 + 1] = txs[ v[2][i] ][1]
							t.texcoords[(k-1)*6 + (i-1)*2 + 2] = txs[ v[2][i] ][2]
						else
							t.texcoords[(k-1)*6 + (i-1)*2 + 1] = 0
							t.texcoords[(k-1)*6 + (i-1)*2 + 2] = 0
						end
					end
					
					if cols then
						if v[4] then
							t.colors[(k-1)*12 + (i-1)*4 + 1] = cols[ v[4][i] ][1]
							t.colors[(k-1)*12 + (i-1)*4 + 2] = cols[ v[4][i] ][2]
							t.colors[(k-1)*12 + (i-1)*4 + 3] = cols[ v[4][i] ][3]
							t.colors[(k-1)*12 + (i-1)*4 + 4] = cols[ v[4][i] ][4]
						else
							t.colors[(k-1)*12 + (i-1)*4 + 1] = 1
							t.colors[(k-1)*12 + (i-1)*4 + 2] = 1
							t.colors[(k-1)*12 + (i-1)*4 + 3] = 1
							t.colors[(k-1)*12 + (i-1)*4 + 4] = 1
						end
					end
				end
			end
			
			--Compute tangents
			if v[2] ~= nil then
				for i = 1,3 do
					local fwd = i+1
					local bwd = i-1
					
					if fwd > 3 then
						fwd = 1
					end
					
					if bwd < 1 then
						bwd = 3
					end
					
					local e1 = vs[v[1][fwd]] - vs[v[1][i]]
					local e2 = vs[v[1][bwd]] - vs[v[1][i]]
					
					local duv1 = txs[v[2][fwd]] - txs[v[2][i]]
					local duv2 = txs[v[2][bwd]] - txs[v[2][i]]
					
					local div = (duv1[1]*duv2[2] - duv2[1]*duv1[2])
					local f
					if div == 0 then
						f = 0
					else
						f = 1/div
					end
					
					local tgt = vector.v3(f * (duv2[2]*e1[1] - duv1[2]*e2[1]), f * (duv2[2]*e1[2] - duv1[2]*e2[2]), f * (duv2[2]*e1[3] - duv1[2]*e2[3])):normalise()
					
					if tgt.x == 0 and tgt.y == 0 and tgt.z == 0 then
						tgt.x = 1
						tgt.y = 0
						tgt.z = 0
					end

					t.tangents[(k-1)*9 + (i-1)*3 + 1] = tgt[1]
					t.tangents[(k-1)*9 + (i-1)*3 + 2] = tgt[2]
					t.tangents[(k-1)*9 + (i-1)*3 + 3] = tgt[3]
				end
			else
				t.tangents[(k-1)*9 + 1] = 1
				t.tangents[(k-1)*9 + 2] = 0
				t.tangents[(k-1)*9 + 3] = 0
				t.tangents[(k-1)*9 + 4] = 1
				t.tangents[(k-1)*9 + 5] = 0
				t.tangents[(k-1)*9 + 6] = 0
				t.tangents[(k-1)*9 + 7] = 1
				t.tangents[(k-1)*9 + 8] = 0
				t.tangents[(k-1)*9 + 9] = 0
			end
		end
	end
	
	--Loads a mesh that can be repeatedly fed into `lib3d.Mesh` calls via the `meshdata` argument
	function lib3d.loadMesh(path, importsettings)
		if not path:match("^%a:") then
			if isOverworld then
				path = Misc.episodePath()..path
			else
				path = Level.folderPath()..path
			end
		end
		
		local d = objreader.load(path, importsettings)
		local t = {}
		parseMesh(t, d.v, d.vt, d.vn, d.vc, d.f)
		return t
	end

	function lib3d.Mesh(args)
		local s = args.scale
		if type(s) == "number" then
			s = vector.v3(s,s,s)
		end
		local t = 	{
						transform = Transform(args.position or vector.zero3, args.rotation or vector.quatid, s or vector.one3),
						materials = args.materials or {args.material or lib3d.defaultMaterial},
						active = true,
						isValid = true
					}
		
		
		local meshdata = args.meshdata
		
		if meshdata == nil and args.path ~= nil then
			meshdata = lib3d.loadMesh(args.path, args.importsettings)
		end
		
		if meshdata ~= nil then
			t._clip_aabs = meshdata._clip_aabs
			t._clip_aabs_centre = meshdata._clip_aabs_centre
			t.faces = meshdata.faces	
			t.verts = meshdata.verts
			t.normals = meshdata.normals
			t.texcoords = meshdata.texcoords
			t.colors = meshdata.colors
			t.tangents = meshdata.tangents
			t.facenormals = meshdata.facenormals
		else
			parseMesh(t, args.verts, args.texcoords, args.normals, args.colors, args.facelist)
		end
		
		t._clip_lastclip = 1
		t.destroy = destroyObj
		
		setmetatable(t, mesh_mt)
		
		tableinsert(objlist, t)
		return t
	end
	
	
	do --Primitive shape constructors
	
		local function makeshapeargs(args)
			local t = {}
			t.position = args.position
			t.rotation = args.rotation
			t.scale = args.scale
			t.materials = args.materials
			if t.materials == nil and args.material then
				t.materials = {args.material}
			end
			return t
		end
		
		function lib3d.Box(args)
			local t = makeshapeargs(args)
			
			local w = (args.width or args.size or 1)*0.5
			local h = (args.height or args.size or 1)*0.5
			local d = (args.depth or args.size or 1)*0.5
			
			t.verts =   { 
							vector.v3(-w,-h,-d), vector.v3(w,-h,-d), vector.v3(-w,h,-d), vector.v3(w,h,-d),
							vector.v3(-w,-h,d), vector.v3(w,-h,d), vector.v3(-w,h,d), vector.v3(w,h,d)
						}
			
			t.normals = {
							vector.v3(1,0,0), vector.v3(-1,0,0), vector.v3(0,1,0), vector.v3(0,-1,0), vector.v3(0,0,1), vector.v3(0,0,-1)
						}
						
			t.facelist = {
							{{1,3,2},nil,{6,6,6}}, {{3,4,2},nil,{6,6,6}},
							{{2,4,6},nil,{1,1,1}}, {{4,8,6},nil,{1,1,1}},
							{{2,6,1},nil,{4,4,4}}, {{6,5,1},nil,{4,4,4}},
							{{5,7,1},nil,{2,2,2}}, {{7,3,1},nil,{2,2,2}},
							{{4,3,8},nil,{3,3,3}}, {{3,7,8},nil,{3,3,3}},
							{{6,8,5},nil,{5,5,5}}, {{8,7,5},nil,{5,5,5}}
						 }
			
			do
				local uv = args.uv or lib3d.uv.TILE
				
				if uv == lib3d.uv.TILE then
					t.texcoords = 	{
										
										vector.v2(0,0), vector.v2(1,0), vector.v2(0,1), vector.v2(1,1)
									}
					for i = 1,#t.facelist,2 do
						t.facelist[i][2] = {1,3,2}
						t.facelist[i+1][2] = {3,4,2}
					end
					
				elseif uv == lib3d.uv.UNWRAP then
					t.texcoords = 	{
										vector.v2(0.33333333,0.5), vector.v2(0.66666667,0.5), vector.v2(0.33333333,0.75), vector.v2(0.66666667,0.75),
										vector.v2(0.66666667,0.5), vector.v2(1,0.5), vector.v2(0.66666667,0.75), vector.v2(1,0.75),
										vector.v2(0.66666667,0.5), vector.v2(0.33333333,0.5), vector.v2(0.66666667,0.25), vector.v2(0.33333333,0.25),
										vector.v2(0,0.5), vector.v2(0.33333333,0.5), vector.v2(0,0.75), vector.v2(0.33333333,0.75),
										vector.v2(0.66666667,0.75), vector.v2(0.66666667,1),  vector.v2(0.33333333,0.75), vector.v2(0.33333333,1),
										vector.v2(0.66666667,0.25), vector.v2(0.33333333,0.25), vector.v2(0.66666667,0), vector.v2(0.33333333,0),
									}
								
					local offset = 0
					for i = 1,#t.facelist,2 do
						t.facelist[i][2] = {offset+1,offset+3,offset+2}
						t.facelist[i+1][2] = {offset+3,offset+4,offset+2}
						offset=offset+4
					end
					
				end
			end
			
			return lib3d.Mesh(t)
		end
		
		local cos = math.cos
		local sin = math.sin
		local pi = math.pi
		
		lib3d.uv = { TILE = 0, UNWRAP = 1 }
		
		function lib3d.Sphere(args)
			local t = makeshapeargs(args)
			
			local r = args.radius or 1
			
			local vdiv = max(args.vdiv or args.subdivide or floor(3*math.pow(r,0.333333)), 3)
			local hdiv = max(args.hdiv or args.subdivide or floor(3*math.pow(r,0.333333) + 1), 4)
			
			t.verts =   { vector.v3(0,-r,0) }
			t.normals = { vector.v3(0,-1,0) }
			t.facelist = {}
			
			local edges = args.smoothnormals
			if edges == nil then
				edges = true
			end
			
			do
				for i = 1,vdiv do
					local a = i * pi/(vdiv+1)
					
					local v = vector.v3(0,-cos(a),-sin(a))
					for j = 1,hdiv do
						local n = v:rotate(0,j * 360/hdiv,0)
						
						if edges then
							tableinsert(t.normals, n)
						else
							local a2 = (i+0.5) * pi/(vdiv+1)
							tableinsert(t.normals, vector.v3(0,-cos(a2),-sin(a2)):rotate(0,(j+0.5) * 360/hdiv,0))
						end
						tableinsert(t.verts, n*r)
					end
				end
				tableinsert(t.verts, vector.v3(0,r,0))
				tableinsert(t.normals, vector.v3(0,1,0))
				
				for j = 1,hdiv do
					local j2 = j+1
					if j2 > hdiv then
						j2 = 1
					end
					if edges then
						tableinsert(t.facelist, {{1,j2+1,j+1},nil,{1,j2+1,j+1}})
					else
						tableinsert(t.facelist, {{1,j2+1,j+1},nil,{j+1,j+1,j+1}})
					end
				end
				
				local n = 1
				for i = 1,vdiv-1 do
					for j = 1,hdiv do
						local j2 = j+1
						if j2 > hdiv then
							j2 = 1
						end
						if edges then
							tableinsert(t.facelist, {{n+j,n+j2,n+hdiv+j},nil,{n+j,n+j2,n+hdiv+j}})
							tableinsert(t.facelist, {{n+hdiv+j,n+j2,n+hdiv+j2},nil,{n+hdiv+j,n+j2,n+hdiv+j2}})
						else
							tableinsert(t.facelist, {{n+j,n+j2,n+hdiv+j},nil,{n+j,n+j,n+j}})
							tableinsert(t.facelist, {{n+hdiv+j,n+j2,n+hdiv+j2},nil,{n+j,n+j,n+j}})
						end
					end
					n = n + hdiv
				end
				
				n = #t.verts - hdiv - 1
				for j = 1,hdiv do
					local j2 = j+1
					if j2 > hdiv then
						j2 = 1
					end
					tableinsert(t.facelist, {{n+j,n+j2,n+hdiv+1},nil,{n+j,n+j2,n+hdiv+1}})
				end
				
			end
			

			
			do
				local uv = args.uv or lib3d.uv.UNWRAP
				
				if uv == lib3d.uv.TILE then
				
					t.texcoords = 	{
										
										vector.v2(0,0), vector.v2(1,0), vector.v2(0,1), vector.v2(1,1), vector.v2(0.5,0), vector.v2(0.5,1)
									}
					for i = 1,hdiv do
						t.facelist[i][2] = {5,4,3}
					end
					for i = hdiv+1,#t.facelist - hdiv,2 do
						t.facelist[i][2] = {3,1,4}
						t.facelist[i+1][2] = {4,1,2}
					end
					for i = #t.facelist - hdiv,#t.facelist do
						t.facelist[i][2] = {2,1,6}
					end
					
				elseif uv == lib3d.uv.UNWRAP then
				
					t.texcoords = 	{}
					for i = 1,hdiv do
						tableinsert(t.texcoords, vector.v2(1 - ((i-0.5)/hdiv) , 0))
					end
					
					local capoffset = hdiv

					for i = 1,vdiv do
						local a = i * pi/(vdiv+1)
						
						local v = vector.v3(0,-cos(a),-sin(a))
						for j = 1,hdiv+1 do
							tableinsert(t.texcoords, vector.v2(1 - (j-1)/hdiv , i/(vdiv+1)))
						end
					end
					
					for i = 1,hdiv do
						tableinsert(t.texcoords, vector.v2(1 - ((i-0.5)/hdiv) , 1))
					end
					
					local idx = 1
					for j = 1,hdiv do
						local j2 = j+1
						
						t.facelist[idx][2] = {j, j2+hdiv, j+hdiv}
						idx = idx+1
					end
					
					local n = hdiv
					for i = 1,vdiv-1 do
						for j = 1,hdiv do
							local j2 = j+1
							
							t.facelist[idx][2] = {n+j,n+j2,n+hdiv+1+j}
							t.facelist[idx+1][2] = {n+hdiv+1+j,n+j2,n+hdiv+1+j2}
							idx = idx+2
						end
						n = n + hdiv+1
					end
					
					n = #t.texcoords - 2 * hdiv - 1
					for j = 1,hdiv do
						local j2 = j+1
						
						t.facelist[idx][2] = {n+j,n+j2,n+hdiv+j+1}
						idx = idx+1
					end
					
				end
			end
			
			return lib3d.Mesh(t)
		end
		
		function lib3d.Cylinder(args)
			local t = makeshapeargs(args)
			
			local r = args.radius or 1
			local h = (args.height or args.size or 1)*0.5
			
			local s = max(args.subdivide or 12, 3)
			
			t.verts =   { vector.v3(0,-h,0), vector.v3(0,h,0) }
			
			t.normals = { vector.v3(0,-1,0), vector.v3(0,1,0) }
			
			t.facelist = {}
			
			local edges = args.smoothnormals
			if edges == nil then
				edges = true
			end
			
			local v = vector.v3(0,0,r)
			if s%2 == 0 then
				v = v:rotate(0,180/s,0)
			end
			for i = 1,s do
				local n = v:rotate(0, i * 360/s, 0)
				t.verts[#t.verts+1] = vector(n.x,-h,n.z)
				t.verts[#t.verts+1] = vector(n.x,h,n.z)
				if not edges then
					t.normals[#t.normals+1] = n:rotate(0,180/s,0):normalise()
				else
					t.normals[#t.normals+1] = n:normalise()
				end
				
				local n1 = 2*i + 1
				local n2 = n1 + 2
				
				local nrm1 = i+2
				local nrm2 = i+3
				
				if i == s then
					n2 = 3
					nrm2 = 3
				end
				
				if not edges then
					nrm2 = nrm1
				end
				
				t.facelist[#t.facelist+1] = {{1,n2,n1},nil,{1,1,1}}
				t.facelist[#t.facelist+1] = {{2,n1+1,n2+1},nil,{2,2,2}}
				
				t.facelist[#t.facelist+1] = {{n1,n2,n1+1},nil,{nrm1,nrm2,nrm1}}
				t.facelist[#t.facelist+1] = {{n2+1,n1+1,n2},nil,{nrm2,nrm1,nrm2}}
				
			end
			
			do
				local uv = args.uv or lib3d.uv.TILE
				
				if uv == lib3d.uv.TILE then
					t.texcoords = 	{ vector.v2(0.5,0.5) }
					
					local v = vector.v2(0,1)
					if s%2 == 0 then
						v = v:rotate(180/s)
					end
					local tv = v:normalise()
					for i = 1,s do
						t.texcoords[#t.texcoords+1] = (tv:rotate(i * 360/s)*0.5) + vector.v2(0.5,0.5)
						t.texcoords[#t.texcoords+1] = vector.v2((i-1)/s, 0)
						t.texcoords[#t.texcoords+1] = vector.v2((i-1)/s, 1)
						
						local nxt = 3*i + 2
						local nxtSid = 3*i + 3
						if i == s then
							nxt = 2
							nxtSid = 3*s+2
						end
						t.facelist[(i-1)*4 + 1][2] = {1, nxt, 3*(i-1) + 2} 
						t.facelist[(i-1)*4 + 2][2] = {1, 3*(i-1) + 2, nxt}
						
						t.facelist[(i-1)*4 + 3][2] = {3*(i-1) + 3, nxtSid, 3*(i-1) + 4} 
						t.facelist[(i-1)*4 + 4][2] = {nxtSid + 1, 3*(i-1) + 4, nxtSid}
					end
					
					t.texcoords[#t.texcoords+1] = vector.v2(1, 0)
					t.texcoords[#t.texcoords+1] = vector.v2(1, 1)
					
				elseif uv == lib3d.uv.UNWRAP then
				
					t.texcoords = 	{ vector.v2(0.5,0.1666667), vector.v2(0.5,0.8333333) }
					
					local v = vector.v2(0,1)
					if s%2 == 0 then
						v = v:rotate(180/s)
					end
					local tv = v:normalise()
					for i = 1,s do
						t.texcoords[#t.texcoords+1] = (tv:rotate(i * 360/s)*0.1666667) + vector.v2(0.5,0.1666667)
						t.texcoords[#t.texcoords+1] = (tv:rotate(i * 360/s)*0.1666667) + vector.v2(0.5,0.8333333)
						t.texcoords[#t.texcoords+1] = vector.v2((i-1)/s, 0.3333333)
						t.texcoords[#t.texcoords+1] = vector.v2((i-1)/s, 0.6666667)
						
						local nxt = 4*i + 3
						local nxtSid = 4*i + 5
						if i == s then
							nxt = 3
							nxtSid = 4*s+3
						end
						t.facelist[(i-1)*4 + 1][2] = {1, nxt, 4*(i-1) + 3} 
						t.facelist[(i-1)*4 + 2][2] = {2, 4*(i-1) + 4, nxt + 1}
						
						t.facelist[(i-1)*4 + 3][2] = {4*(i-1) + 5, nxtSid, 4*(i-1) + 6} 
						t.facelist[(i-1)*4 + 4][2] = {nxtSid + 1, 4*(i-1) + 6, nxtSid}
					end
					
					t.texcoords[#t.texcoords+1] = vector.v2(1, 0.3333333)
					t.texcoords[#t.texcoords+1] = vector.v2(1, 0.6666667)
					
				end
			end
			return lib3d.Mesh(t)
		end
		
		function lib3d.Quad(args)
			local t = makeshapeargs(args)
			
			local w = (args.width or args.size or 1)*0.5
			local h = (args.height or args.size or 1)*0.5
			local d = (args.normal or vector.v3(0,0,-1)):normalise()
			
			local rot = vector.quat(vector.v3(0,0,-1), d)
			
			t.verts =   { 
							rot*vector.v3(-w,-h,0), rot*vector.v3(w,-h,0), rot*vector.v3(-w,h,0), rot*vector.v3(w,h,0)
						}
			
			t.normals = {
							d
						}
						
			t.texcoords = {
										
							vector.v2(0,0), vector.v2(1,0), vector.v2(0,1), vector.v2(1,1)
						  }
						
			t.facelist = {
							{{1,3,2},{1,3,2},{1,1,1}}, {{3,4,2},{3,4,2},{1,1,1}}
						 }
			
			return lib3d.Mesh(t)
		end
		
		function lib3d.Plane(args)
			local t = makeshapeargs(args)
			
			local w = (args.width or args.size or 1)*0.5
			local h = (args.height or args.size or 1)*0.5
			local sx = max(args.hdiv or args.subdivide or 8, 0)
			local sy = max(args.vdiv or args.subdivide or 8, 0)
			local d = (args.normal or vector.v3(0,0,-1)):normalise()
			
			local rot = vector.quat(vector.v3(0,0,-1), d)
			
			t.verts =   { }
			t.texcoords = { }
			
			sx = sx+1
			sy = sy+1
			
			for j = 0,sy do
				for i = 0,sx do
					t.verts[#t.verts+1] = rot*vector.v3(i*(2*w/sx) - w , j*(2*h/sy)- h, 0)
					t.texcoords[#t.texcoords+1] = vector.v2(i/sx,j/sx)
				end
			end
			
			t.normals = {
							d
						}
						
			t.facelist = { }
			
			for j = 1,sy do
				for i = 1,sx-1 do
					t.facelist[#t.facelist+1] = {{(j-1)*(sx+1) + i, j*(sx+1) + i, (j-1)*(sx+1) + i + 1}, {(j-1)*(sx+1) + i, j*(sx+1) + i, (j-1)*(sx+1) + i + 1}, {1,1,1}}
					t.facelist[#t.facelist+1] = {{j*(sx+1) + i, j*(sx+1) + i + 1, (j-1)*(sx+1) + i + 1}, {j*(sx+1) + i, j*(sx+1) + i + 1, (j-1)*(sx+1) + i + 1}, {1,1,1}}
				end
			end
			
			return lib3d.Mesh(t)
		end
	end
	
	local lighttype = { DIRECTIONAL = 0, POINT = 1 }
	lib3d.lighttype = lighttype
	
	local light_mt = {}
	light_mt.__type = "Light3D"
	
	--Create a new light
	function lib3d.Light(args)
		local typ = args.lighttype or 0
		
		local t = {transform = Transform(args.position or vector.zero3, args.rotation or vector.quatid, vector.one3)}
		t.active = true
		t.isValid = true
		
		t.destroy = destroyObj
		
		if typ == lighttype.DIRECTIONAL then
			t.color = args.color or Color.white
			t.brightness = args.brightness or 10
			if #dirlightlist >= maxLights then
				Misc.warn("Maximum number of directional lights reached. Light may be ignored in rendering.", 2)
			end
			tableinsert(dirlightlist, t)
		elseif typ == lighttype.POINT then
			t.color = args.color or Color.white
			t.brightness = args.brightness or 10
			t.radius = args.radius or 256
			if #pntlightlist >= maxLights then
				Misc.warn("Maximum number of point lights reached. Light may be ignored in rendering.", 2)
			end
			tableinsert(pntlightlist, t)
		else
			error("Unknown light type provided.",2)
		end
		
		setmetatable(t, light_mt)
		return t
	end
end

local null_mesh_mt = {}
local null_light_mt = {}

do
	local function nullidx(tbl, key)
		if key == "isValid" then
			return false
		end
		error("Cannot access a destroyed object.", 2)
	end
	local function nullnewidx()
		error("Cannot access a destroyed object.", 2)
	end
	
	null_light_mt.__index = nullidx
	null_mesh_mt.__index = nullidx
	null_light_mt.__newindex = nullnewidx
	null_mesh_mt.__newindex = nullnewidx
	null_light_mt.__type = "Light3D"
	null_mesh_mt.__type = "Mesh3D"
end



do	--Cameras and drawing

	--Local "getMat" functions for some speedup
	local getMat
	local getInvMat
	do
		local tf = Transform.new3d()
		
		getMat = tf.getMat
		getInvMat = tf.getInvMat
	end

	local mvmat = vector.mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	local mvpmat = vector.mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	local vpmat = vector.mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
	local pmat = vector.mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

	--Local mat4xmat4
	local function mul4(a,b,out)
		for i=1,4,1 do
			for j=1,4,1 do
				for k=1,4,1 do
					out[i + (j-1)*4] = out[i + (j-1)*4] + a[i + (k-1)*4]*b[k + (j-1)*4]
				end
			end
		end
	end

	
--PROJECTION
	
	--Compute ModelView matrix
	local function getMVMat(obj, cam)
		for i=1,16 do
			mvmat[i] = 0
		end
		
		local a = getInvMat(cam.transform)
		local b = getMat(obj.transform)
		
		mul4(a,b,mvmat)

		return mvmat
	end

	
	--Compute perspective projection matrix
	local function getProjPMat(cam)
		local zn = cam.nearclip
		local zf = cam.farclip
		local t = 1/tan(cam.fov*0.00872664625)
		
		pmat[1] = -t
		pmat[6] = -t*cam.width/cam.height
		pmat[11] = (zn+zf)/(zn-zf)
		pmat[12] = -1
		pmat[15] = (2*zn*zf)/(zf-zn)
		pmat[16] = 0
		
		--[[ 
			--Perspective projection matrix
			--NOTE: t is multiplied by -aspect to account for inverted coordinate spaces.
			
			t/aspect			0				0				0
				0				t				0				0
				0				0    	(zn+zf)/(zn-zf)	  2*zn*zf/(zf-zn)
				0				0			    -1				0
		--]]
		
		 
	end

	
	--Compute orthographic projection matrix
	local function getOrthPMat(cam)
		local zn = cam.nearclip
		local zf = cam.farclip
		
		pmat[1] = 2/cam.orthosize[1]
		pmat[6] = 2/cam.orthosize[2]
		pmat[11] = 2/(zf-zn)
		pmat[12] = 0
		pmat[15] = (zn+zf)/(zn-zf)
		pmat[16] = 1
		
		--[[ 
			--Orthographic projection matrix
		
			 2/width			0				0				0
				0			 2/height			0				0
				0				0    		2/(zf-zn)	  (zn+zf)/(zn-zf)
				0				0			    0				1
		--]]
	end

	--Get Projection matrix
	local function getPMat(cam)
		return pmat
	end

	--Compute Projection matrix
	local function recalcPMat(cam)
		if cam.projection == projection.ORTHO then
			getOrthPMat(cam)
		else
			getProjPMat(cam)
		end
	end

	--Compute ViewProjection (and View) matrix
	local function getVPMat(cam)
		for i=1,16 do
			vpmat[i] = 0
		end
		
		local vm = getInvMat(cam.transform)
		mul4(pmat,vm,vpmat)

		return vpmat, vm
	end

	--Compute ModelViewProjection (and ModelView) matrix
	local function getMVPMat(obj, cam)
		for i=1,16 do
			mvmat[i] = 0
			mvpmat[i] = 0
		end
		
		mul4(getInvMat(cam.transform), getMat(obj.transform), mvmat)
		mul4(pmat, mvmat, mvpmat)

		return mvpmat, mvmat
	end


	
--FRUSTUM CULLING

	
	--Compute viewing frustum planes
	local function getFrustum(m, invert)
		local fs = { {}, {}, {}, {}, {}, {} }
		
		for i = 1,4 do
			--near
			fs[1][i] = m[4*i]+m[4*i - 1]
			--left
			fs[2][i] = m[4*i]+m[4*i - 3]
			--right
			fs[3][i] = m[4*i]-m[4*i - 3]
			--top
			fs[4][i] = m[4*i]-m[4*i - 2]
			--bottom
			fs[5][i] = m[4*i]+m[4*i - 2]
			--far
			fs[6][i] = m[4*i]-m[4*i - 1]
		end
		
		for i = 1,6 do
			local p = fs[i]
			local r = 1/sqrt(p[1]*p[1]+p[2]*p[2]+p[3]*p[3])
			if invert then
				r = -r
			end
			p[1] = p[1]*r
			p[2] = p[2]*r
			p[3] = p[3]*r
			p[4] = p[4]*r
		end
		
		return fs
	end

	
	--Check if an object's BoundingSphere is inside the viewing frustum
	local function checkClip(obj, fs)
		local m = getMat(obj.transform)
		
		--Extract largest scale factor from matrix
		local s = 0
		for i = 1,3 do
			local t = 0
			local n = (i-1)*4
			for j = 1,3 do
				t = t + m[n + j]*m[n + j]
			end
			s = max(s,abs(t))
		end
		--Extend radius by largest scale factor (use square radius)
		local r = sqrt(obj._clip_aabs*obj._clip_aabs*s)
		
		--Apply the transform to the centre of the bounding sphere (inlined mat4*v4 computation)
		local c = {0,0,0}
		for i=1,3,1 do
			for j=1,4,1 do
				c[i] = c[i] + obj._clip_aabs_centre[j]*m[i + (j-1)*4];
			end
		end

		--Check each frustum plane with the transformed sphere, starting with whichever caused clipping last
		for i = obj._clip_lastclip, obj._clip_lastclip+5 do
			local idx = i-(6*floor((i-1)/6))
			local pl = fs[idx]
			
			if (pl[1]*c[1] + pl[2]*c[2] + pl[3]*c[3] + pl[4]) > r then
				obj._clip_lastclip = idx
				return false
			end
		end
		return true
	end
	

	
--LIGHTING

	local getLights
	do
		local dir_ld = {}
		local dir_lc = {}

		local pnt_lp = {}
		local pnt_lc = {}
		
		--Destroy a light object if it's invalid
		local function destroyLight(v)
			for k,_ in pairs(v) do
				v[k] = nil
			end
			setmetatable(v, null_light_mt)
		end
		
		--Compute and format light information to be passed to the shader
		--POSSIBLE IMPROVEMENTS: allow lights to be prioritised by distance 
		--(note that this may mean computing lights per object, rather than per camera)
		function getLights()
			do --Directional lights
				local diridx = 1
				local colidx = 1
				
				local i = 1
				while dirlightlist[i] ~= nil do
					local v = dirlightlist[i]
					
					if not v.isValid then
						destroyLight(v)
						tableremove(dirlightlist, i)
						i = i-1
					elseif v.active then
						local f = v.transform.wforward
						dir_ld[diridx] 	 = f[1]
						dir_ld[diridx+1] = f[2]
						dir_ld[diridx+2] = f[3]
						
						dir_lc[colidx] 	 = v.color[1]
						dir_lc[colidx+1] = v.color[2]
						dir_lc[colidx+2] = v.color[3]
						dir_lc[colidx+3] = v.brightness
						
						diridx = diridx+3
						colidx = colidx+4
						
						--Stop light array being too long
						if diridx > maxLights*3 then
							break
						end
					end
					i = i+1
				end	
				
				for i = diridx,maxLights*3 do
					dir_ld[i] = 0
				end
				for i = colidx,maxLights*4 do
					dir_lc[i] = 0
				end
			end
			
			do	--Point lights
				local idx = 1
				local i = 1
				while pntlightlist[i] ~= nil do
					local v = pntlightlist[i]
					
					if not v.isValid then
						destroyLight(v)
						tableremove(pntlightlist, i)
						i = i-1
					elseif v.active then
						local p = v.transform.wposition
						pnt_lp[idx]   = p[1]
						pnt_lp[idx+1] = p[2]
						pnt_lp[idx+2] = p[3]
						pnt_lp[idx+3] = v.radius
						
						pnt_lc[idx]   = v.color[1]
						pnt_lc[idx+1] = v.color[2]
						pnt_lc[idx+2] = v.color[3]
						pnt_lc[idx+3] = v.brightness
						
						idx = idx+4
						
						--Stop light array being too long
						if idx > maxLights*4 then
							break
						end
					end
					i = i+1
				end
				
				for i = idx,maxLights*4 do
					pnt_lp[i] = 0
					pnt_lc[i] = 0
				end
			end
			
			return dir_ld,dir_lc,pnt_lp,pnt_lc
		end
	end


--VERTEX DATA

	local getVertData
	do

		local vlist = {}
		local tlist = {}
		local clist = {}
		local nlist = {}
		local tgtlist = {}
		local invmvmat = vector.mat4(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
		local camfwd = vector.zero3

		--Compute the dot product of the face normal based on relative camera position (used for perspective backface culling)
		local function facedot(px, py, pz, nx, ny, nz)
			return (px - invmvmat[13])*nx + (py - invmvmat[14])*ny + (pz - invmvmat[15])*nz
		end
		
		--Compute the dot product of the face normal based on the camera direction (used for orthographics backface culling)
		local function dirdot(nx,ny,nz)
			return invmvmat[9]*nx + invmvmat[10]*ny + invmvmat[11]*nz
		end
		
		--Check if a face is pointing towards the camera
		local function checkbackface(ortho, vx, vy, vz, fx, fy, fz)
			if ortho then
				return dirdot(fx,fy,fz) < 0
			else
				return facedot(vx, vy, vz, fx, fy, fz) < 0
			end
		end

		--Check for backface culling, and format vertex data for drawing
		function getVertData(obj, cam)
			if not lib3d.backfaceCulling then
				return 2*#obj.verts/3,obj.verts,obj.texcoords,obj.colors,obj.normals,obj.tangents
			else
				for i=1,16 do
					invmvmat[i] = 0
				end
				--Compute object space position of camera
				mul4(getInvMat(obj.transform), getMat(cam.transform), invmvmat)
				
				local ortho = cam.projection == projection.ORTHO
				
				local vi = 1
				local ti = 1
				local ci = 1
				
				local vs = obj.verts
				local ts = obj.texcoords
				local cs = obj.colors
				local ns = obj.normals
				local tgs = obj.tangents
				local fns = obj.facenormals
				
				local r,g,b,a = 1,1,1,1
				if cs then
					local c = obj.materials[1].color
					if c then
						r = c[1]/c[4]
						g = c[2]/c[4]
						b = c[3]/c[4]
						a = c[4]
					end
				end
				
				--Iterate over faces and push relevant data
				for k = 0,obj.faces-1 do
					--Check for backface culling
					 
					local fx,fy,fz = fns[k*3 + 1], fns[k*3 + 2], fns[k*3 + 3]
					local vx,vy,vz = vs[k*9 + 1], vs[k*9 + 2], vs[k*9 + 3]
					
					if (ortho and invmvmat[9]*fx + invmvmat[10]*fy + invmvmat[11]*fz < 0) 
					or (not ortho and (vx - invmvmat[13])*fx + (vy - invmvmat[14])*fy + (vz - invmvmat[15])*fz < 0) then
					
					--if checkbackface(ortho, vs[k*9 + 1], vs[k*9 + 2], vs[k*9 + 3], fns[k*3 + 1], fns[k*3 + 2], fns[k*3 + 3]) then
					
						--Loop over the 3 vertices in this face to see if it's actually in front of the camera
						local clip = true
						for i = 0,2 do
							if (vs[k*9 + i*3 + 1]-invmvmat[13])*invmvmat[9] + (vs[k*9 + i*3 + 2]-invmvmat[14])*invmvmat[10] + (vs[k*9 + i*3 + 3]-invmvmat[15])*invmvmat[11] >= 0 then
								clip = false
								break
							end
						end
						
						if not clip then
							--Loop over the 3 vertices in each face and push data to the relevant lists
							for i = 0,2 do
								do					--vertex position
									vlist[vi] 	= vs[k*9 + i*3 + 1]
									vlist[vi+1] = vs[k*9 + i*3 + 2]
									vlist[vi+2] = vs[k*9 + i*3 + 3]
								end
								do					--normal direction
									nlist[vi]	= ns[k*9 + i*3 + 1]
									nlist[vi+1]	= ns[k*9 + i*3 + 2]
									nlist[vi+2]	= ns[k*9 + i*3 + 3]
								end
								do					--tangent direction
									tgtlist[vi]   = tgs[k*9 + i*3 + 1]
									tgtlist[vi+1] = tgs[k*9 + i*3 + 2]
									tgtlist[vi+2] = tgs[k*9 + i*3 + 3]
								end
								if ts ~= nil then	--texture coord
									tlist[ti] 	= ts[k*6 + i*2 + 1]
									tlist[ti+1] = ts[k*6 + i*2 + 2]
								end
								if cs ~= nil then	--vertex color
									clist[ci]	= cs[k*12 + i*4 + 1]*r
									clist[ci+1]	= cs[k*12 + i*4 + 2]*g
									clist[ci+2]	= cs[k*12 + i*4 + 3]*b
									clist[ci+3]	= cs[k*12 + i*4 + 4]*a
								end
								
								vi = vi+3
								ti = ti+2
								ci = ci+4
							end
						end
					end
				end
				
				--Clear junk data from lists
				for i = #vlist,vi,-1 do
					vlist[i] = nil
					nlist[i] = nil
					tgtlist[i] = nil
				end
				
				for i = #tlist,ti,-1 do
					tlist[i] = nil
				end
				
				for i = #clist,ci,-1 do
					clist[i] = nil
				end
				
				if ts ~= nil then
					ts = tlist
				end
				if cs ~= nil then
					cs = clist
				end
				
				return ti-1,vlist,ts,cs,nlist,tgtlist
			end
		end
	end


--DRAWING
	
	--Destroy a mesh object if it's invalid
	local function destroyMesh(v)
		for k,_ in pairs(v) do
			v[k] = nil
		end
		setmetatable(v, null_mesh_mt)
	end
	
	local blank_normal = Graphics.CaptureBuffer(1,1,true)
	local blank_texture = Graphics.CaptureBuffer(1,1,true)
	Graphics.drawBox{x=0,y=0,width=1,height=1,color=Color.white,target=blank_texture,priority=-100}
	Graphics.drawBox{x=0,y=0,width=1,height=1,color=Color(0.5,0.5,1),target=blank_normal,priority=-100}
	
	
	local function getUniformOrDefault(mat, k)
		local t = mat.uniforms[k[1]]
		--Find default sampler
		if t == nil and k[2] == 35678 then
		
			--If registered as a normal map, try the un-prefixed name, or use the blank normal map
			if k[3] ~= nil then
				return mat.uniforms[k[3]] or blank_normal
				
			--Otherwise use blank white
			else
				return blank_texture
			end
		end
		return t
	end
	
	local uniformlist = {}
	local attributelist = {}
	local verts = {}
	local drawargs = { uniforms = uniformlist, attributes = attributelist, vertexCoords = verts, depthTest=true }
	local debugCache = {}
	
	--3D draw function - this is perhaps the most important bit
	local function drawCam_internal(cam, priority, dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol, dbg)
	
		if dbg then
			debugCache.verts = debugdata.verts
			debugCache.objects = debugdata.objects
			debugCache.culled = debugdata.culled
			debugCache.inactive = debugdata.inactive
			debugdata.verts = 0
			debugdata.objects = 0
			debugdata.culled = 0
			debugdata.inactive = 0
		end
		
		recalcPMat(cam)
		
		local vp = getVPMat(cam)
		local frustum = getFrustum(vp, cam.projection == projection.ORTHO)
		cam.target:clear(priority)
		
		--Set camera-bound draw arguments
		do
		uniformlist.cam_nearclip 		= cam.nearclip
		uniformlist.cam_farclip 		= cam.farclip
		uniformlist.mat_p 				= pmat
		uniformlist.cam_position		= cam.transform.wposition
		uniformlist._dir_lightDirection = dir_lightDir
		uniformlist._dir_lightColor		= dir_lightCol
		uniformlist._pnt_lightPosition 	= pnt_lightPos
		uniformlist._pnt_lightColor 	= pnt_lightCol
		uniformlist._ambientLight 		= lib3d.ambientLight
		
		drawargs.target					= cam.target
		drawargs.priority				= priority
		end
		
		local i = 1
		while objlist[i] ~= nil do
			local o = objlist[i]
			if not o.isValid then
				destroyMesh(o)
				tableremove(objlist, i)
			elseif o.active then
				if checkClip(o, frustum) then
					local o2w = getMat(o.transform)
					local w2o = getInvMat(o.transform)
					local mvp,mv = getMVPMat(o, cam)
					
					local vc,vs,ts,cs,ns,tgts = getVertData(o, cam)

					if vc > 0 then
					
						if lib3d.debug or dbg then
							debugdata.verts = debugdata.verts + vc
							debugdata.objects = debugdata.objects + 1
						end
					
						for j=#verts+1,vc do
							verts[j] = 0
						end
						
						for j=#verts,1 + vc, -1 do
							verts[j] = nil
						end
						
						uniformlist.obj2world 			= o2w
						uniformlist.world2obj 			= w2o
						uniformlist.mat_mvp 			= mvp
						
						attributelist._vertexdata 		= vs
						attributelist._normaldata 		= ns
						attributelist._tangentdata 		= tgts
						
						drawargs.vertexColors			= cs
						drawargs.textureCoords			= ts
						
						for midx,m in ipairs(o.materials) do
							if midx > 1 and cs then
								--Have to update vertex colors. Sadly this is super expensive while we're using CPU backface culling.
								local r,g,b,a = 1,1,1,1
								local c = m.color
								if c then
									r = c[1]/c[4]
									g = c[2]/c[4]
									b = c[3]/c[4]
									a = c[4]
								end
								local ortho = cam.projection == projection.ORTHO
								
								local ci = 1
								
								local vs = o.verts
								local cs = o.colors
								local fns = o.facenormals
								local clist = drawargs.vertexColors
								
								for k = 0,o.faces-1 do
									--Check for backface culling
									
									
									local fx,fy,fz = fns[k*3 + 1], fns[k*3 + 2], fns[k*3 + 3]
									local vx,vy,vz = vs[k*9 + 1], vs[k*9 + 2], vs[k*9 + 3]
									
									if (ortho and invmvmat[9]*fx + invmvmat[10]*fy + invmvmat[11]*fz < 0) 
									or (not ortho and (vx - invmvmat[13])*fx + (vy - invmvmat[14])*fy + (vz - invmvmat[15])*fz < 0) then
									
									--if checkbackface(ortho, vs[k*9 + 1], vs[k*9 + 2], vs[k*9 + 3], fns[k*3 + 1], fns[k*3 + 2], fns[k*3 + 3]) then
									
										--vertex color
										clist[ci]	= cs[k*12 + (i-1)*4 + 1]*r
										clist[ci+1]	= cs[k*12 + (i-1)*4 + 2]*g
										clist[ci+2]	= cs[k*12 + (i-1)*4 + 3]*b
										clist[ci+3]	= cs[k*12 + (i-1)*4 + 4]*a
										ci = ci+4
									end
								end
							end
						
							for _,k in ipairs(m.uniformmap) do
								
								uniformlist[k[1]] = getUniformOrDefault(m, k)
							end
							
							if uniformlist._fog == nil then
								uniformlist._fog = lib3d.fogColor
							end
							
							--[[
							local fv = uniformlist._fog.a
							
							if isNearCamera then
								uniformlist._fog.a = 0
							end
							]]			
							for _,k in ipairs(m.attributemap) do
								attributelist[k] = m.attributes[k]
							end
							
							drawargs.texture 				= m.uniforms.texture or blank_texture
							drawargs.shader					= m.shader
							drawargs.color					= m.uniforms.color
							
							Graphics.glDraw	(drawargs)
										
							
							--uniformlist._fog.a = fv
							
							for _,k in ipairs(m.uniformmap) do
								uniformlist[k[1]] = nil
							end	
							
							for _,k in ipairs(m.attributemap) do
								attributelist[k] = nil
							end
						end
					end
				elseif lib3d.debug or dbg then
					debugdata.culled = debugdata.culled + 1
				end
				i = i+1
			else	
				if lib3d.debug or dbg then
					debugdata.inactive = debugdata.inactive + 1
				end
				i = i+1
			end
		end
		
		if dbg then
			local s = "Objects: "
			Text.print(s, 610, 10)
			s = "Visible: "..tostring(debugdata.objects)
			Text.print(s, 790-18*#s, 28)
			s = "Inactive: "..tostring(debugdata.inactive)
			Text.print(s, 790-18*#s, 46)
			s = "Culled: "..tostring(debugdata.culled)
			Text.print(s, 790-18*#s, 64)
			
			s = "Tris: "..tostring(ceil(debugdata.verts/3))
			Text.print(s, 790-18*#s, 96)
			
			
			debugdata.verts = debugCache.verts + debugdata.verts
			debugdata.objects = debugCache.objects + debugdata.objects
			debugdata.culled = debugCache.culled + debugdata.culled
			debugdata.inactive = debugCache.inactive + debugdata.inactive
		end
	end
	
	--Camera.draw
	local function doDraw(cam, priority, dbg)
		if not cam.active then return end
		priority = priority or -100
		local dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol = getLights()
		drawCam_internal(cam, priority, dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol, dbg)
	end
	
	--Clears a camera's render target
	local function clearCamera(cam, priorty)
		cam.target:clear(priorty)
	end
	
	--Gets the focal length of the camera - objects positioned this far in front of the camera will match the 2D game environment in depth
	local function getFocalLength(cam)
		return cam.width*0.5/tan(rad(cam.fov*0.5))
	end
	
	local cam_mt = {}
	cam_mt.__type = "Camera3D"
	
	function cam_mt.__index(tbl,key)
		if key == "flength" then
			return getFocalLength(tbl)
		elseif key == "renderscale" then
			return tbl.target.width/tbl.width
		end
	end
	
	function cam_mt.__newindex(tbl,key,val)
		if key == "flength" then
			tbl.fov = 2*deg(atan(tbl.width/(val*2)))
		elseif key == "renderscale" then
			tbl.target = Graphics.CaptureBuffer(floor(tbl.width*val),floor(tbl.height*val))
		end
	end

	
	--Create a new camera - objects will be drawn to camera.target when camera:draw is called
	function lib3d.Camera(args)
		local framebufferwidth,framebufferheight = Graphics.getMainFramebufferSize()
		local width = args.width or framebufferwidth
		local height = args.height or framebufferheight

		local c = 	{ 
						fov = args.fov or 45, orthosize = args.orthosize or vector.v2(width,height), 
						projection = args.projection or projection.PERSP, 
						farclip = args.farclip or 10000, nearclip = args.nearclip or 100, 
						transform = Transform(args.position or vector.zero3, args.rotation or vector.quatid, vector.one3), 
						width = width, height = height, 
						active = true
					}
				
		local renderscale = args.renderscale or 1
		c.target = Graphics.CaptureBuffer(floor(width*renderscale),floor(height*renderscale))
		
		c.getFocalLength = getFocalLength
		c.draw = doDraw
		c.clear = clearCamera
		c.project = lib3d.project
		
		setmetatable(c, cam_mt)
		return c
	end

	--Automatic main camera - can be disabled by setting it to inactive
	lib3d.camera = lib3d.Camera{ fov = 45, projection = projection.PERSP, farclip = 10000, nearclip = 100, renderscale = 2 }
	
	lib3d.dualCamera = true

	
	--Main camera draw function, called automatically
	function lib3d.onCameraDraw(idx)
		if not (idx == 1 and lib3d.camera.active) then return end
		
		debugdata.verts = 0
		debugdata.objects = 0
		debugdata.culled = 0
		debugdata.inactive = 0
		
		local dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol = getLights()
		
		local nc
		if lib3d.dualCamera then
			nc = lib3d.camera.nearclip
			lib3d.camera.nearclip = getFocalLength(lib3d.camera) - 2
		end
		
		drawCam_internal(lib3d.camera, -95, dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol)
		Graphics.drawScreen{texture = lib3d.camera.target, priority = -95}
		
		if lib3d.dualCamera then
			local fc = lib3d.camera.farclip
			lib3d.camera.farclip = lib3d.camera.nearclip + 2
			lib3d.camera.nearclip = nc
			
			drawCam_internal(lib3d.camera, 0, dir_lightDir, dir_lightCol, pnt_lightPos, pnt_lightCol)
			Graphics.drawScreen{texture = lib3d.camera.target, priority = 0}
			
			lib3d.camera.farclip = fc
		end
		
		if lib3d.debug then
			local s = "Objects: "
			Text.print(s, 610, 10)
			s = "Visible: "..tostring(debugdata.objects)
			Text.print(s, 790-18*#s, 28)
			s = "Inactive: "..tostring(debugdata.inactive)
			Text.print(s, 790-18*#s, 46)
			s = "Culled: "..tostring(debugdata.culled)
			Text.print(s, 790-18*#s, 64)
			
			s = "Tris: "..tostring(ceil(debugdata.verts/3))
			Text.print(s, 790-18*#s, 96)
		end
	end

	--Recreate the main camera when necessary, making sure to retain the old settings
	function lib3d.onFramebufferResize(width,height)
		local oldCamera = lib3d.camera
		
		lib3d.camera = lib3d.Camera{
			fov = oldCamera.fov, farclip = oldCamera.farclip, nearclip = oldCamera.nearclip,
			projection = oldCamera.projection, renderscale = oldCamera.renderscale,
			orthosize = vector(oldCamera.orthosize.x/oldCamera.width*width, oldCamera.orthosize.y/oldCamera.height*height),

			position = oldCamera.transform.position,
			rotation = oldCamera.transform.rotation,
			scale = oldCamera.transform.scale,
		}
		lib3d.camera.active = oldCamera.active
	end
	
	--Software project point
	function lib3d.project(cam, v)
		
		recalcPMat(cam)
		local vp = getVPMat(cam)*vector.v4(v)
		vp[1] = vp[1]/vp[4]
		vp[2] = vp[2]/vp[4]
		
		return vector.v2((vp[1]+1)*cam.width*0.5, (vp[2]+1)*cam.height*0.5)
	end
end

function lib3d.onInitAPI()
	registerEvent(lib3d, "onCameraDraw", "onCameraDraw", false)
	registerEvent(lib3d, "onFramebufferResize")
end

return lib3d