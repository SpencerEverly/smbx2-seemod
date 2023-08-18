local iniParse = require("configFileReader")

local paralx2 = {}

local focus = 200
local bgs = {}

--Largest possible value that is less than 1
local minlt1 = 0.999999999999999888977697537484

local sort = table.sort
local mathhuge = math.huge
local tableinsert = table.insert
local tableremove = table.remove
local abs = math.abs
local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min

paralx2.depth = {INFINITE = mathhuge, MAX = mathhuge, MIN = -focus*minlt1}

paralx2.align = {LEFT = 0, RIGHT = 1, BOTTOM = 1, TOP = 0, CENTRE = 0.5, MID = 0.5, CENTER = 0.5, MIDDLE = 0.5}

local enums = table.join(paralx2.depth, paralx2.align)

_G["BG_MAX_ID"] = 65
local bgObjs = {}

local sectionBGs = {}

local function resolveBGFile(path)
	return Misc.multiResolveFile(path, "graphics/background2/"..path)
end

local GM_ORIG_LVL_BOUNDS = mem(0x00B2587C, FIELD_DWORD)

local function getOrigSectionBounds(section)
    local ptr    = GM_ORIG_LVL_BOUNDS + 0x30 * section
    local left   = mem(ptr + 0x00, FIELD_DFLOAT)
    local top    = mem(ptr + 0x08, FIELD_DFLOAT)
    local bottom = mem(ptr + 0x10, FIELD_DFLOAT)
    local right  = mem(ptr + 0x18, FIELD_DFLOAT)
    return {left=left, top=top, bottom=bottom, right=right}
end

local function ParseIni(path)
	local layers, headerdata = iniParse.parseWithHeaders(path, {General = true, background2 = true}, enums, false, true)

	for _,l in ipairs(layers) do
		if l.img == nil then
			if l.image == nil then
				error("Background layer did not have an image file defined!", 1)
			else
				l.img = l.image
			end
		end
		if tonumber(l.img) then
			l.img = Graphics.sprites.background2[tonumber(l.img)]
		else
			local imgpath = resolveBGFile(l.img)
			if imgpath == nil then
				error("Background layer image file not found: "..l.img, 1)
			else
				l.img = Graphics.loadImage(imgpath)
			end
		end
	end

	layers.General = headerdata
	if headerdata["fill-color"] then
		headerdata["fill-color"] = Color.parse(headerdata["fill-color"])
		--headerdata["fill-color"].a = 1; --Allow alpha for edge cases
	else
		headerdata["fill-color"] = Color.black
	end

	return layers
end

function paralx2.onInitAPI()
	registerEvent(paralx2, "onCameraDraw", "onCameraDraw", false)
	registerEvent(paralx2, "onTick")

	for i=1,BG_MAX_ID do
		local ini = Misc.multiResolveFile("background2-"..i..".txt", "background2-"..i..".ini") or Misc.multiResolveFile("config/backgrounds/background2-"..i..".txt", "config/backgrounds/background2-"..i..".ini")
		
		if ini ~= nil then
			bgObjs[i] = ParseIni(ini)
		end
	end
end

--Update the virtual camera's "focal length", which alters how fast the parallax layers move based on their depth.
function paralx2.SetFocus(newFocus)
	focus = newFocus
	paralx2.depth.MIN = -focus*minlt1
end

local function CopyLayer(v)	
	return {x = v.spawnX, y = v.spawnY,
			img = v.img,
			name = v.name,
			depth = v.depth,
			fitX = v.fitX, fitY = v.fitY,
			maxParallaxX = v.maxParallaxX, maxParallaxY = v.maxParallaxY,
			sourceX = v.sourceX, sourceY = v.sourceY,
			sourceWidth = v.sourceWidth, sourceHeight = v.sourceHeight,
			priority = v.priority,
			color = v.color,
			opacity = v.opacity,
			speedX = v.speedX, speedY = v.speedY,
			parallaxX = v.parallaxX, parallaxY = v.parallaxY,
			repeatX = v.repeatX, repeatY = v.repeatY,
			padX = v.padX, pady = v.padY,
			hidden = v.hidden,
			frames = v.frames,
			framespeed = v.framespeed,
			startingFrame = v.animationFrame+1,
			margin = v.margin,
			alignX = v.alignX,
			alignY = v.alignY,
			vertshader = v.vertshader,
			fragshader = v.fragshader,
			uniforms = table.clone(v.uniforms),
			attributes = table.clone(v.attributes)}
end

local shaderlist = {}

local layermt = {}
layermt.__index = function(tbl, key)
					if key == "image" then
						if type(tbl.img) == "table" then
							return tbl.img.img
						else
							return tbl.img
						end
					elseif key == "GetArgs" or key == "getArgs" then
						return CopyLayer
					else
						return rawget(tbl,key)
					end
				end

layermt.__newindex = function(tbl, key, val)
					if key == "image" then
						tbl.img = val
					elseif key == "GetArgs" or key == "getArgs" then
						error("Cannot re-assign base function "..key,2)
					else
						rawset(tbl,key, val)
					end
				end

layermt.__type = "BackgroundLayer"

local function checkShader(l)
	if l.vertshader or l.fragshader then
		local shaderid = (l.vertshader or "nil")..":"..(l.fragshader or "nil")
		if shaderlist[shaderid] == nil then
			local s = Shader()
			s:compileFromFile(l.vertshader, l.fragshader)
			shaderlist[shaderid] = s
		end
		
		return shaderlist[shaderid]
	end
	return nil
end

--Background:add{} with named arguments:
--img						[[REQUIRED: the image to draw in this layer]]
--name						[[A name for the layer, used by Background:Get. Defaults to "Layer#", where # is the layer index]]
--x, y						[[layer offset from top left of boundary, defaults to 0,0]]
--depth						[[Depth at which to position the layer (0 = in line with scene, >0 = behind scene, <0 = in front of scene), computed from fit if not supplied, default of depth.INFINITE if fit is disabled]]
--fitX, fitY				[[Should the layer attempt to fit its parallaxing to the boundaries?]]
--priority					[[Render priority, computed from depth if not supplied]]
--color						[[A color to tint this layer, defaults to white]]
--opacity					[[How transparent this layer should be. Multiplies with the color argument opacity, defaults to 1]]
--speedX, speedY			[[How fast this layer should move of its own volition, defauts to 0,0]]
--parallaxX, parallaxY		[[Override for parallax scrolling speed (0 = no scrolling, 1 = scroll with scene, >1 = scroll faster than scene)]]
--maxParallaxX, maxParallaxY[[Maximum parallax scrolling speed (0 = no scrolling, 1 = scroll with scene, >1 = scroll faster than scene)]]
--repeatX, repeatY			[[How many repeats of this image should be applied? 0 or true = infinite repeats, 1 = no repeats, >1 = n repeats]]
--padX, padY				[[Padding to place between repeated images]]
--marginLeft, marginRight	[[Padding to the side of the layer]]
--marginTop, marginBottom	[[Padding to the top/bottom of the layer]]
--margin					[[A table containing all 4 margins, named]]
--hidden					[[Should this layer be hidden? Defaults to false]]
--frames					[[Number of animation frames, defaults to 1]]
--framespeed				[[Frame timer between animation frames, defaults to 8]]
--startingFrame				[[Starting animation frame, defaults to 1]]
--alignX, alignY			[[Alignment for the x and y coordinates. Defaults to LEFT/TOP]]
local function AddLayer(bg, args)
	local l = {}
	l.name = args.name or "Layer"..(#bg.layers + 1)
	l.x = args.x or 0
	l.y = args.y or 0
	l.spawnX = l.x
	l.spawnY = l.y
	
	l.depth = args.depth
	l.fitX = args.fitX
	l.fitY = args.fitY
	l.maxParallaxX = args.maxParallaxX or 0
	l.maxParallaxY = args.maxParallaxY or 0
	
	if l.depth == nil and not l.fitX and not l.fitY then
		l.depth = mathhuge
	end
	
	l.sourceX = args.sourceX or 0
	l.sourceY = args.sourceY or 0
	l.sourceWidth = args.sourceWidth or 0
	l.sourceHeight = args.sourceHeight or 0
	
	l.frames = args.frames or 1
	if l.frames < 1 then 
		l.frames = 1
	end
	l.framespeed = args.framespeed or 8
	l.animationFrame = (args.startingFrame or 1) - 1
	l.animationTimer = l.framespeed - 1
	
	l.priority = args.priority
	
	l.img = args.img or args.image
	if l.img == nil then 
		error("No image supplied to parallax layer.",2) 
	end
	
	l.color = Color.parse(args.color or Color.white)
	l.opacity = args.opacity or 1;
	
	l.margin = args.margin or {left=0, right=0, top=0, bottom=0}
	l.margin.left = args.marginLeft or l.margin.left or 0
	l.margin.right = args.marginRight or l.margin.right or 0
	l.margin.top = args.marginTop or l.margin.top or 0
	l.margin.bottom = args.marginBottom or l.margin.bottom or 0
	
	l.alignX = args.alignX or paralx2.align.LEFT
	l.alignY = args.alignY or paralx2.align.TOP
	
	l.speedX = args.speedX or 0
	l.speedY = args.speedY or 0
	
	l.parallaxX = args.parallaxX
	l.parallaxY = args.parallaxY
	
	l.repeatX = args.repeatX
	if not l.repeatX then 
		l.repeatX = 1
	elseif l.repeatX == true then --Yes this does need to be == true
		l.repeatX = 0
	end
	l.repeatY = args.repeatY
	if not l.repeatY then 
		l.repeatY = 1
	elseif l.repeatY == true then --Yes this does need to be == true
		l.repeatY = 0 
	end

	l.padX = args.padX or 0
	l.padY = args.padY or 0

	l.hidden = args.hidden
	if l.hidden == nil then l.hidden = false end

	l.debug = args.debug
	
	l.vertshader = args.vertshader
	l.fragshader = args.fragshader
	
	checkShader(l)
	
	l.attributes = args.attributes or {}
	l.uniforms = args.uniforms or {}

	setmetatable(l,layermt)

	tableinsert(bg.layers, l)

	return l
end

local function CloneBG(bg)
	local newbg = paralx2.Background(bg.section, bg.bounds, bg.fillColor)
	for _,v in ipairs(bg.layers) do
		AddLayer(newbg, v:getArgs())
	end
	return newbg
end

local function FindLayerIndex(bg, name)
	for k,v in ipairs(bg.layers) do
		if v.name == name then
			return k
		end
	end
	return nil
end

local function FindLayer(bg,name)
	if name == nil then
		return table.iclone(bg.layers)
	end
	local i
	if type(name) == "number" then
		i = name
	else
		i = FindLayerIndex(bg,name)
	end
	return bg.layers[i]
end

local function RemoveLayer(bg, layer)
	if type(layer) == "table" then
		layer = table.ifind(bg.layers, layer)
	elseif type(layer) == "string" then
		layer = FindLayerIndex(bg,layer)
	end
	if layer ~= nil then
		tableremove(bg.layers, layer)
	end
end

local bgmt = {}
bgmt.__index = function(tbl, key)
					if key == "add" or key == "Add" then
						return AddLayer
					elseif key == "Clone" or key == "clone" then
						return CloneBG
					elseif key == "Get" or key == "get" then
						return FindLayer
					elseif key == "Remove" or key == "remove" then
						return RemoveLayer
					else
						return rawget(tbl,key)
					end
				end

bgmt.__newindex = function(tbl, key, val)
					if key == "add" or key == "Add" or key == "Clone" or key == "clone" or key == "Get" or key == "get" or key == "Remove" or key == "remove" then
						error("Cannot re-assign base function "..key,2)
					else
						rawset(tbl,key, val)
					end
				end
				
bgmt.__type = "Background"

local function CreateBG(section, bounds, fillColor, layers)
	if section ~= nil and bounds == nil and fillColor == nil and layers == nil then
		layers = section
		section = -1
	end
	if section == nil or section < -1 then section = -1 end

	if bounds ~= nil and (bounds.left == nil or bounds.right == nil or bounds.top == nil or bounds.bottom == nil) then
		if type(bounds) == "Color" then
			layers = fillColor
			fillColor = bounds
		else
			layers = bounds
			fillColor = Color.black
		end
		bounds = nil
	end

	if layers == nil and type(fillColor) == "table" then
		layers = fillColor
		fillColor = Color.black
	end

	if fillColor == nil then
		fillColor = Color.black
	end

	local bg = {layers = {}, section = section, bounds = bounds, fillColor = fillColor, hidden = false}

	setmetatable(bg, bgmt)

	for _,v in ipairs(layers) do
		AddLayer(bg, v)
	end

	return bg
end

function paralx2.Background(section, bounds, fillColor, ...)

	local lyrs
	if type(fillColor) ~= "Color" then
		lyrs = {fillColor,...}
		fillColor = Color.black
	else
		lyrs = {...}
	end

	local bg = CreateBG(section, bounds, fillColor, lyrs)

	tableinsert(bgs, bg)

	return bg
end

local function ComputeLayerWidth(l, w, h)
	local img = l.img
	if type(img) == "table" then
		img = img.img
	end
	if w == nil then
		w = img.width + l.padX
	end
	if h == nil then
		h = (img.height/l.frames) + l.padY
	end
	--Compute layer size based on image width, repeats, and padding
	if l.repeatX > 0 then
		w = w*l.repeatX - l.padX
	end
	if l.repeatY > 0 then
		h = h*l.repeatY - l.padY
	end
	w = w + l.margin.left + l.margin.right
	h = h + l.margin.top + l.margin.bottom
	return w,h
end

local function ComputeFitDepth(l, w, h, cw, ch, bounds, sb)
	if not l.fitX and not l.fitY then
		return 0
	else
		if bounds == nil then bounds = sb end

		local dx = 0
		local dy = 0
		if l.fitX then
			dx = ((sb.right - sb.left) - (bounds.right - bounds.left) - (cw-w))/(sb.right-sb.left-cw)
			if abs(dx) == mathhuge or dx ~= dx then 
				dx = 0 
			end
			if l.maxParallaxX > 0 and dx > l.maxParallaxX then
				dx = l.maxParallaxX
			end
		end
		if l.fitY then
			dy = ((sb.bottom - sb.top) - (bounds.bottom - bounds.top) - (ch-h))/(sb.bottom-sb.top-ch)
			if abs(dy) == mathhuge or dy ~= dy then 
				dy = 0 
			end
			if l.maxParallaxY > 0 and dy > l.maxParallaxY then
				dy = l.maxParallaxY
			end
		end
		return max(dx, dy)
	end
end

local function CompareDepth(a,b,cw,ch,bounds,section)
	local sb = section.origBoundary--getOrigSectionBounds(section)
	local w1,h1 = ComputeLayerWidth(a)
	local w2,h2 = ComputeLayerWidth(b)
	local da = a.depth or ComputeFitDepth(a,w1,h1,cw,ch,bounds,sb)
	local db = b.depth or ComputeFitDepth(b,w2,h2,cw,ch,bounds,sb)
	return da > db
end


local verts = {}
local txs = {}
local drawargs = {vertexCoords = verts, textureCoords = txs, color = {1,1,1,1}}
	
local function DrawLayer(l, camera, section, bounds)
	if l.depth ~= nil and l.depth/focus <= -1 then return end --Don't bother drawing layers that are behind the "camera"

	local img = l.img
	if type(img) == "table" then
		img = img.img
	end

	--ix,iy = Size of image only
	local iw = img.width
	local ih = img.height / l.frames
	if l.sourceHeight > 0 then
		ih = l.sourceHeight / l.frames
	end
	if l.sourceWidth > 0 then
		ih = l.sourceWidth / l.frames
	end

	--lx,ly = Size of one layer segment (image + padding)
	local lw = iw + l.padX
	local lh = ih + l.padY

	--w,h = Size of entire layer, including repeats, margins, and padding
	local w,h = ComputeLayerWidth(l, lw, lh)

	--cx,cy,cw,ch = Cached camera information
	local c = camera
	local cx = c.x
	local cy = c.y
	local cw = c.width
	local ch = c.height

	--d = Depth comptued parallax speed
	local d
	--p = LunaLua Render priority
	local p = 0

	--sb = Section boundary
	local sb = section.origBoundary--getOrigSectionBounds(section)
	local usingSection = false
	--bounds = Background boundary (often the same as section boundary, but not necessarily)
	if bounds == nil then
		bounds = sb
		usingSection = true
	end

	--sw,sh = Section width and height
	local sw = sb.right - sb.left
	local sh = sb.bottom - sb.top
	--bw,bh = Boundary width and height
	local bw = bounds.right - bounds.left
	local bh = bounds.bottom - bounds.top

	--Compute speed based on depth if depth was supplied
	if l.depth ~= nil then
		d = l.depth/focus

		d = d + 1
		d = 1/(d*d)
	--Compute depth based on fit requirements otherwise (d = 0 (Infinite depth) if no fit)
	else
		d = ComputeFitDepth(l,w,h,c.width,c.height,bounds,sb)
	end
	
	--Early termination for layers that are positioned behind the camera
	if d ~= d or (l.depth and l.depth <= -focus) then
		if l.debug then
			Text.print(l.name..": Clipped (behind camera)", 0, 0)
		end
		return
	end

	--Determine render priority
	if l.priority then
		p = l.priority
	elseif d <= 1 then
		p = -101
	else
		p = 0
	end

	--speedx,speedy = Parallax speeds
	local speedx = l.parallaxX or d
	local speedy = l.parallaxY or d
	--xoffset,yoffset = Layer offset from anchor position
	local xoffset = l.x
	local yoffset = l.y

	local vcw = c.width
	local vch = c.height
	
	local voffset = c.renderY
	local hoffset = c.renderX
	if player2 and player2.isValid and player2.section ~= player.section then
		vch = ch
		voffset = 0
	end

	--Compute speed based on fit requirements
	if l.fitX then
		speedx = (sw - bw - (vcw-w))/(sw-vcw)
		if abs(speedx) == mathhuge or speedx ~= speedx then --Speed is infinite or NaN
			speedx = 0
			xoffset = (bw - w)*abs(l.alignX - 1)
		end
		
		if l.maxParallaxX > 0 and speedx > l.maxParallaxX then
			speedx = l.maxParallaxX
		end
	end
	if l.fitY then
		speedy = (sh - bh - (vch-h))/(sh-vch)
		if abs(speedy) == mathhuge or speedy ~= speedy then --Speed is infinite or NaN
			speedy = 0
			--centers in every circumstance. one could multiply just with the align value to align relative to that
			yoffset = (bh - h)*abs(l.alignY - 1)
		end
		
		if l.maxParallaxY > 0 and speedy > l.maxParallaxY then
			speedy = l.maxParallaxY
		end
	end

	--Adjust layer position based on margins and alignment
	xoffset = xoffset + l.margin.left + (bw-w)*l.alignX
	yoffset = yoffset + l.margin.top + (bh-h)*l.alignY

	--Adjust section alignments based on alignment conditions, so that "right" aligned layers align when the camera is on the right of the section.
	local sx = sb.left*(1-l.alignX) + (sb.right-vcw)*l.alignX
	local sy = sb.top*(1-l.alignY) + (sb.bottom-vch)*l.alignY

	--Round up repeat numbers so they always give enough images
	local repX = ceil(l.repeatX)
	local repY = ceil(l.repeatY)
	
	--Compute draw position in screen space
	local x = (bounds.left-sx) + xoffset - (cx-sx)*speedx - hoffset*(1-speedx)
	local y = (bounds.top-sy) + yoffset - (cy-sy)*speedy - voffset*(1-speedy)

	if l.debug then
		Text.print(l.name..": (x = "..x..", y = "..y..")", 0, 0)
	end

	--Compute minimum repeats to cover the screen if repeats are infinite
	if repX <= 0 then
		if x < -lw then
			x = -((-x)%lw)
		end
		if x > 0 then
			x = (x%lw)-lw
		end
		--[[while(x < -lw) do
			x = x+lw;
		end
		while(x > 0) do
			x = x-lw;
		end]]
		repX = ceil((cw-x)/lw)
	end
	--Compute minimum repeats to cover the screen if repeats are infinite
	if repY <= 0 then
	
		if y < -lh then
			y = -((-y)%lh)
		end
		if y > 0 then
			y = (y%lh)-lh
		end
		
		--[[while y > 0 do
			y = y - lh
		end
		
		while y < - lh do
			y = y+lh
		end
		while y > 0 do
			y = y-lh
		end]]
		repY = ceil((ch-y)/lh)
	end

	x = floor(x)
	y = floor(y)
	
	local realSectionBounds = section.boundary

	local idx = 1
	
	--Compute cropping and draw to screen
	for i = 1,repX do
		local imgw = iw
		local initx = x
		--Don't draw to the left of the camera
		if x < 0 then
			imgw = imgw + x
			x = 0
		end
		
		--Also don't draw to the left of the boundary
		local bl = bounds.left
		if usingSection then
			bl = min(bl, realSectionBounds.left)
		end
		
		if x < bl-cx then
			imgw = imgw - bl + cx + x
			x = bl-cx
		end
		local xoff = iw-imgw + l.sourceX
		
		local br = bounds.right
		if usingSection then
			br = max(br, realSectionBounds.right)
		end
		
		--Don't draw to the right of the camera or boundary
		imgw = min(imgw, cw-x, br-x-cx)

		--Is image on screen horizontally?
		if imgw > 0 and x < cw then
			local firsty = y
			for j = 1,repY do
				local imgh = ih					
				local inity = y
				
				--Don't draw above the camera
				if y < 0 then
					imgh = imgh + y
					y = 0
				end
				
				--Also don't draw above the boundary
				local bt = bounds.top
				if usingSection then
					bt = min(bt, realSectionBounds.top)
				end
				if y < bt-cy then
					imgh = imgh - bt + cy + y
					y = bt-cy
				end
				local yoff = ih-imgh + l.animationFrame*ih + l.sourceY
				
				local bb = bounds.bottom
				if usingSection then
					bb = max(bb, realSectionBounds.bottom)
				end
				
				--Don't draw below the camera or boundary
				imgh = min(imgh, ch-y, bb-y-cy)
				--Is image on screen vertically?
				if imgh > 0 and y < ch then
					--Crop image to screen and boundary and draw
					--Graphics.drawImageWP(img, ceil(x), ceil(y), xoff, yoff, imgw, imgh, l.opacity, p)
					local clx,cly = ceil(x), ceil(y)
				
					verts[idx] = clx
					verts[idx+1] = cly
					verts[idx+2] = clx + imgw
					verts[idx+3] = cly
					verts[idx+4] = clx
					verts[idx+5] = cly + imgh
					verts[idx+6] = clx
					verts[idx+7] = cly + imgh
					verts[idx+8] = clx + imgw
					verts[idx+9] = cly
					verts[idx+10] = clx + imgw
					verts[idx+11] = cly + imgh
					
					local spw, sph = img.width,img.height
					
					txs[idx] = xoff/spw
					txs[idx+1] = yoff/sph
					txs[idx+2] = (xoff + imgw)/spw
					txs[idx+3] = yoff/sph
					txs[idx+4] = xoff/spw
					txs[idx+5] = (yoff + imgh)/sph
					txs[idx+6] = xoff/spw
					txs[idx+7] = (yoff + imgh)/sph
					txs[idx+8] = (xoff + imgw)/spw
					txs[idx+9] = yoff/sph
					txs[idx+10] = (xoff + imgw)/spw
					txs[idx+11] = (yoff + imgh)/sph
					
					idx = idx+12
				elseif y > ch then
					break
				end
				--Update y position for repeating images (sub 0.5 to fix seams)
				y = ceil(inity + lh - 0.5)
			end
			--Reset y position so it's not offset for the next horizontal row
			y = firsty
		elseif x > cw then
			break
		end
		--Update x position for repeating images (sub 0.5 to fix seams)
		x = ceil(initx + lw - 0.5)
	end
	
	for i = #verts,idx,-1 do
		verts[i] = nil
		txs[i] = nil
	end
	drawargs.texture = img
	drawargs.priority = p
	drawargs.color[1] = l.color.r
	drawargs.color[2] = l.color.g
	drawargs.color[3] = l.color.b
	drawargs.color[4] = l.color.a * l.opacity
	drawargs.shader = checkShader(l)
	drawargs.uniforms = l.uniforms
	drawargs.attributes = l.attributes
	Graphics.glDraw(drawargs)
end

local function UpdateBG(v)
	for _,l in ipairs(v.layers) do
		if not l.hidden then
			l.x = l.x + l.speedX
			l.y = l.y + l.speedY
			if l.frames > 1 then
				l.animationFrame = min(l.animationFrame, l.frames-1)
				if l.framespeed >= 0 then
					if l.animationTimer <= 0 then
						l.animationTimer = l.framespeed
						l.animationFrame = (l.animationFrame+1)%l.frames
					end
					l.animationTimer = l.animationTimer - 1
				end
			else
				l.animationFrame = 0
			end
		end
	end
end

function paralx2.onTick()
	local activeSectionIndicies = Section.getActiveIndices()
	for _,s in ipairs(activeSectionIndicies) do
		if sectionBGs[s] ~= nil then
			local bg = sectionBGs[s].bg
			if not bg.hidden then
				UpdateBG(bg)
			end
		end
	end

	table.insert(activeSectionIndicies, -1)
	for _,v in ipairs(bgs) do
		for _,s in ipairs(activeSectionIndicies) do
			if v.section == s and not v.hidden then
				UpdateBG(v)
			end
		end
	end
end

function paralx2.get(section)
	local sectionbg = Section(section).backgroundID
	if bgObjs[sectionbg] ~= nil then
		if sectionBGs[section] == nil then
			sectionBGs[section] = {id=sectionbg, bg = CreateBG(section, bgObjs[sectionbg].General["fill-color"], bgObjs[sectionbg])}
		end
		return sectionBGs[section].bg
	else
		return nil
	end
end

function paralx2.set(section, bg)
	sectionBGs[section] = bg
end

local function DrawBG(v, camera, section, camwidth, camheight)
	if(v.bounds == nil) then
		Graphics.drawScreen{color = v.fillColor, priority = -101}
	else
		Graphics.drawBox{color = v.fillColor, priority = -101, x = v.bounds.left, y = v.bounds.top, w = v.bounds.right-v.bounds.left, h = v.bounds.bottom - v.bounds.top, sceneCoords = true}
	end
	sort(v.layers, function(a,b) return CompareDepth(a,b,camera.width,camera.height,v.bounds,section) end)
	for _,w in ipairs(v.layers) do
		if(not w.hidden) then
			DrawLayer(w, camera, section, v.bounds);
		end
	end
end

--TODO: Change this to a two-step "gather layers" from all backgrounds, then sort, then draw. Allow an option for backgrounds to "overwrite", so they are drawn on a separate queue.
function paralx2.onCameraDraw(camidx)
	local p = Player(camidx)
	local c = Camera(camidx)
	local section = Section(p.section)
	local sectionbg = section.backgroundID
	
	if sectionBGs[p.section] and sectionBGs[p.section].id ~= sectionbg then
		sectionBGs[p.section] = nil
	end
	
	if bgObjs[sectionbg] ~= nil then
		if sectionBGs[p.section] == nil then
			sectionBGs[p.section] = {id=sectionbg, bg = CreateBG(p.section, bgObjs[sectionbg].General["fill-color"], bgObjs[sectionbg])}
		end
		local bg = sectionBGs[p.section].bg
		if not bg.hidden then
			DrawBG(bg, c, section, c.width--[[c.width]], c.height--[[c.height]])
		end
	end
	for _,v in ipairs(bgs) do
		for _,s in ipairs({p.section, -1}) do
			if v.section == s and not v.hidden then
				DrawBG(v, c, section, c.width--[[c.width]], c.height--[[c.height]])
			end
		end
	end
end

local global_mt = {
	__index = function(tbl, key)
		if key == "focus" then
			return focus
		end
	end,

	__newindex = function(tbl, key, val)
		if key == "focus" then
			paralx2.SetFocus(val)
		end
	end,
	
	__call = function(tbl, section, bounds, fillColor, ...)
		return paralx2.Background(section, bounds, fillColor, ...)
	end
}

setmetatable(paralx2, global_mt)
if Section.__initBackground then
	Section.__initBackground(paralx2)
end

Misc._SetVanillaBackgroundRenderFlag(false)

return paralx2
