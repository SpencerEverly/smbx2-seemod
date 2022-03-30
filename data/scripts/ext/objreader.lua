local objreader = {}

local tableinsert = table.insert
local tableremove = table.remove

objreader.axis = { POS_X = 0, POS_Y = 1, POS_Z = 2, NEG_X = 3, NEG_Y = 4, NEG_Z = 5, V_DOWN = 6, V_UP = 7 }

local function triangulate(verts, vs)

	local fs = {}
	
	--Assumes verts are convex
	for i = 3,#verts[1] do
		local vtb = { verts[1][1], verts[1][i-1], verts[1][i] }
		local ntb = nil
		local ttb = nil
		if verts[2] ~= nil then
			ttb = { verts[2][1], verts[2][i-1], verts[2][i] }
		end
		if verts[3] ~= nil then
			ntb = { verts[3][1], verts[3][i-1], verts[3][i] }
		end
		
		tableinsert(fs, { vtb, ttb,  ntb})
	end
	
	return fs
	
	--Alt triangulation. Slow and probably not great
	--[[
	for k,v in ipairs(verts[1]) do
		tableinsert(fs[1][1], v)
		tableinsert(fs[1][2], verts[2][k])
		tableinsert(fs[1][3], verts[3][k])
	end
	
	while #(fs[1][1]) > 3 do
		local minangle = 360
		local minidx = -1
		for i = 1,#(fs[1][1]) + 2 do
			local idx = i
			local jdx = i+1
			local kdx = i+2
			if i > #(fs[1][1]) then
				idx = i-#(fs[1][1])
			end
			if i >= #(fs[1][1]) then
				jdx = jdx-#(fs[1][1])
			end
			if i >= #(fs[1][1])-1 then
				kdx = kdx-#(fs[1][1])
			end
			
			local a = vs[ (fs[1][1])[idx] ]
			local b = vs[ (fs[1][1])[jdx] ]
			local c = vs[ (fs[1][1])[kdx] ]
			
			local fn1 = a-b
			local fn2 = c-b
			local n = fn1:cross(fn2):normalise()
			
			local angle = math.atan2((fn1:cross(fn2)):dot(n), fn1:dot(fn2))
			if angle > 0 and angle < minangle then
				minangle = angle
				minidx = jdx
			end
		end
		
		if minidx > -1 then
			local lft = minidx-1
			local rgt = minidx+1
			
			if lft < 1 then
				lft = #fs[1][1]
			end
			
			if rgt > #fs[1][1] then
				rgt = 1
			end
			
			tableinsert(fs, { {fs[1][1][lft], fs[1][1][minidx], fs[1][1][rgt]}, {fs[1][2][lft], fs[1][2][minidx], fs[1][2][rgt]}, {fs[1][3][lft], fs[1][3][minidx], fs[1][3][rgt]} })
			
			tableremove(fs[1][1], minidx)
			tableremove(fs[1][2], minidx)
			tableremove(fs[1][3], minidx)
		end
	end
	
	return fs
	--]]
	
end

local objgrammar
local obj
local settings
do

	local function parse_vert(x,y,z)
		x,y,z = tonumber(x), tonumber(y), tonumber(z)
				
		if settings.upaxis == objreader.axis.POS_X then
			local t = y
			y = -x
			x = t
		elseif settings.upaxis == objreader.axis.POS_Y then
			y = -y
			z = -z
		elseif settings.upaxis == objreader.axis.POS_Z then
			local t = y
			y = -z
			z = t
		elseif settings.upaxis == objreader.axis.NEG_X then
			local t = y
			y = x
			x = -t
		elseif settings.upaxis == objreader.axis.NEG_Z then
			local t = y
			y = z
			z = -t
		end

		tableinsert(obj.v, vector.v3(x*settings.scale[1],y*settings.scale[2],z*settings.scale[3]))
	end

	local function parse_tex(x,y)
		x = tonumber(x)
		y = tonumber(y)
		if settings.uvorient == objreader.axis.V_UP then
			y = 1-y
		end
		
		tableinsert(obj.vt, vector.v2(x, y))
	end

	local function parse_norm(x,y,z)
		x,y,z = tonumber(x), tonumber(y), tonumber(z)
				
		if settings.upaxis == objreader.axis.POS_X then
			local t = y
			y = -x
			x = t
		elseif settings.upaxis == objreader.axis.POS_Y then
			y = -y
			z = -z
		elseif settings.upaxis == objreader.axis.POS_Z then
			local t = y
			y = -z
			z = t
		elseif settings.upaxis == objreader.axis.NEG_X then
			local t = y
			y = x
			x = -t
		elseif settings.upaxis == objreader.axis.NEG_Z then
			local t = y
			y = z
			z = -t
		end
		
		tableinsert(obj.vn, vector.v3(x,y,z))
	end

	local function parse_face(t)
		local f = {{},{},{}}
		
		for k,v in ipairs(t) do
			for l,w in ipairs(v) do
				f[l][k] = tonumber(w)
			end
		end

		if #f[1] >= 3 then
			if #f[2] < #f[1] then
				f[2] = nil
			end
					
			if #f[3] < #f[1] then
				f[3] = nil
			end
					
			tableinsert(obj.f, f)
		end
	end

	local newline = lpeg.P("\r\n") + lpeg.P("\n")
	local space = lpeg.S(" \t")
	local any = lpeg.R("\000\255")
	local arg = space^1*(lpeg.C((any-space-newline)^1))
	local sep = lpeg.P("/")

	objgrammar = lpeg.P
							{
								"body",
								body = lpeg.Ct((lpeg.V("line")*newline)^0 * lpeg.V("line")^-1),
								line = (lpeg.V("vertex")+lpeg.V("texcoord")+lpeg.V("normal")+lpeg.V("face")+lpeg.V("unparsed")+"")*space^0,
								vertex = (lpeg.P("v")*lpeg.Cg(arg^3)) / parse_vert,
								texcoord = (lpeg.P("vt")*lpeg.Cg(arg^2)) / parse_tex,
								normal = (lpeg.P("vn")*lpeg.Cg(arg^3)) / parse_norm,
								face = (lpeg.P("f")*lpeg.Ct((space^1*lpeg.Ct(lpeg.C((any-sep-space-newline)^0)*sep*lpeg.C((any-sep-space-newline)^0)*(sep*lpeg.C((any-sep-space-newline)^0))^-1))^1)) / parse_face,
								unparsed = (any-newline)^1
							}
end

function objreader.load(file, stgs)
	stgs = stgs or {}
	
	stgs.upaxis = stgs.upaxis or objreader.axis.POS_Y
	stgs.uvorient = stgs.uvorient or objreader.axis.V_UP
	stgs.scale = stgs.scale or vector.one3

	if type(stgs.scale) == "number" then
		stgs.scale = vector.v3(stgs.scale, stgs.scale, stgs.scale)
	end
	
	
	local f = io.open(file, "r")
	if f then 
		local data = f:read("*a")
		f:close()
		
		return objreader.parse(data, stgs)
	else
		error("File could not be found: "..file, 2)
	end
	
end

function objreader.parse(object, stgs)
	settings = stgs
	obj = 
	{
		v	= {}, 	-- Verts 				x,y,z,(w)=1
		vt	= {}, 	-- Tex coords 			u,v,  (w)=0
		vn	= {}, 	-- Normals 			 	x,y,z
	  --vp	= {}, 	-- Param-space verts 	u,    (v),(w) -- UNSUPPORTED
		f	= {}, 	-- Faces				
	}
	
	
	--Do parse (data is stored in obj)
	lpeg.match(objgrammar, object)
	
	
	--Triangulation of n-gons
	local newfaces = {}
	
	--Loop over all faces
	local i = 1
	while i <= #obj.f do
		local v = obj.f[i]
		
		--Triangulate if vertex count > 3
		if #v[1] > 3 then
			--Find new triangulated faces and insert them to newfaces list
			local ts = triangulate(v, obj.v)
			for _,w in ipairs(ts) do
				tableinsert(newfaces, w)
			end
			
			--Remove original face
			tableremove(obj.f,i)
		else
			i = i+1
		end
	end
	
	--Add new faces
	for _,v in ipairs(newfaces) do
		tableinsert(obj.f, v)
	end

	return obj
end

return objreader