local sizable = {}

Block._SetVanillaSizableRenderFlag(false)

local v = {}
local t = {}
local vc = {}
local args = {
	vertexCoords = v,
	textureCoords = t,
	primitive = Graphics.GL_TRIANGLES,
	sceneCoords = true,
	priority = -90
}

local function intersect(a, b)
	return not (
		a.x + a.width < b.x or
		b.x + b.width < a.x or
		a.y + a.height < b.y or
		b.y + b.height < a.y
	)
end

local function intersect2(x,y,w,h, r)
	return not (
		x + w < r[1] or
		r[3] < x or
		y + h < r[2] or
		r[4] < y
	)
end

local function rect(tbl, len, x1, y1, x2, y2)
	tbl[len + 1],  tbl[len + 2]  = x1, y1
	tbl[len + 3],  tbl[len + 4]  = x2, y1
	tbl[len + 5],  tbl[len + 6]  = x1, y2
	tbl[len + 7],  tbl[len + 8]  = x2, y1
	tbl[len + 9],  tbl[len + 10] = x1, y2
	tbl[len + 11], tbl[len + 12] = x2, y2
end

local function trim(tbl, len)
	for i = len + 1, #tbl do
		tbl[i] = nil
	end
end

local GM_FRAME = readmem(0x00B2BEA0, FIELD_DWORD)
local function get_frame(id)
	return readmem(GM_FRAME + 2*(id-1), FIELD_WORD)
end

local function get_frame_count(id)
	if Block.config.propertiesMap.frames then
		return Block.config[id].frames
	else
		return 1
	end
end

--[[
local GM_TIMER = readmem(0x00B2BEBC, FIELD_DWORD)
local function timer(id, val)
	return mem(GM_TIMER + 2*(id-1), FIELD_WORD, val)
end
]]

local math_min = math.min
local tableinsert = table.insert

local function corners(len, tex_width, tex_height, x, y, bw, bh, c)
	local w = math_min(32, bw/2) --width of each corner
	local h = math_min(32, bh/2) --height of each corner
	local tw, th = w/tex_width, h/tex_height --w & h, as tex coords
	local slen = len
	
	rect(v, len, x, y, x+w, y+h) --top left
	rect(t, len, 0, 0, tw, th)
	len = len + 12
	
	local x2, y2 = x + bw, y + bh --bottom right of block
	rect(v, len, x2-w, y2-h, x2, y2) --bottom right
	rect(t, len, 1-tw, 1-th, 1, 1)
	len = len + 12
	
	rect(v, len, x2-w, y, x2, y+h) --top right
	rect(t, len, 1-tw, 0, 1, th)
	len = len + 12
	
	rect(v, len, x, y2-h, x+w, y2) --bottom left
	rect(t, len, 0, 1-th, tw, 1)
	len = len + 12
	
	if c then
		for i=1,(len-slen)/2 do
			for j = 1,4 do
				vc[(slen/2 + i-1)*4 + j] = c[j]
			end
		end
	end
	
	return len
end

local function top_bottom(len, tex_width, tex_height, bx, by, bw, bh, c)
	local maxW = tex_width - 64 --max width of a segment
	local h = math_min(32, bh/2) --height of a segment
	local th = h/tex_height --h, as tex coords
	local maxX = bx + bw - 32
	local y2 = by + bh --bottom edge of block
	local slen = len
	for x = bx + 32, maxX, maxW do --left edge of each segment
		if x == maxX then
			break
		end
		local x2 = math_min(maxX, x + maxW) --right edge of each segment
		local tw = (x2 - x)/tex_width --width of each segment, as tex coords
		rect(v, len, x, by, x2, by+h) --top edge
		rect(t, len, 32/tex_width, 0, tw+32/tex_width, th)
		len = len + 12
		rect(v, len, x, y2-h, x2, y2) --bottom edge
		rect(t, len, 32/tex_width, 1-th, tw+32/tex_width, 1)
		len = len + 12
	end
	
	if c then
		for i=1,(len-slen)/2 do
			for j = 1,4 do
				vc[(slen/2 + i-1)*4 + j] = c[j]
			end
		end
	end
	
	return len
end

local function left_right(len, tex_width, tex_height, bx, by, bw, bh, c)
	local maxH = tex_height - 64 --max height of a segment
	local x2 = bx + bw --right edge of block
	local w = math_min(32, bw/2) --width of a segment
	local tw = w/tex_width --w, as tex coords
	local maxY = by + bh - 32
	local slen = len
	for y = by + 32, maxY, maxH do --top edge of each segment
		if y == maxY then
			break
		end
		local y2 = math_min(by + bh - 32, y + maxH) --bottom edge of each segment
		local th = (y2 - y)/tex_height --height of each segment, as tex coords
		rect(v, len, bx, y, bx+w, y2) --left edge
		rect(t, len, 0, 32/tex_height, tw, th+32/tex_height)
		len = len + 12
		rect(v, len, x2-w, y, x2, y2) --right edge
		rect(t, len, 1-tw, 32/tex_height, 1, th+32/tex_height)
		len = len + 12
	end	
	if c then
		for i=1,(len-slen)/2 do
			for j = 1,4 do
				vc[(slen/2 + i-1)*4 + j] = c[j]
			end
		end
	end
	return len
end

local function fill(len, tex_width, tex_height, bx, by, bw, bh, c)
	local maxW, maxH = tex_width - 64, tex_height - 64 --maximum dimensions of one segment
	local maxX = bx + bw - 32
	local maxY = by + bh - 32
	local slen = len
	for x = bx + 32, maxX, maxW do --left edge of each segment
		if x == maxX then
			break
		end
		for y = by + 32, maxY, maxH do --top edge of each segment
			if y == maxY then
				break
			end
			local x2 = math_min(bx + bw - 32, x + maxW) --right edge of each segment
			local y2 = math_min(by + bh - 32, y + maxH) --left edge of each segment
			
			rect(v, len, x, y, x2, y2) --fill
			rect(t, len, 32/tex_width, 32/tex_height, (x2 - x +32)/tex_width, (y2 - y + 32)/tex_height)
			len = len + 12
		end
	end
	if c then
		for i=1,(len-slen)/2 do
			for j = 1,4 do
				vc[(slen/2 + i-1)*4 + j] = c[j]
			end
		end
	end
	return len
end

local sprites = Graphics.sprites.block

local function populate(block, id, img, bx, by, bw, bh, c)
	args.texture = img
	local tex_width, tex_height = args.texture.width, args.texture.height --dimensions of one frame of the texture
	tex_height = tex_height / get_frame_count(id)
	
	local len = 0
	len = corners(len, tex_width, tex_height, bx, by, bw, bh, c)
	if bw > 64 then
		len = top_bottom(len, tex_width, tex_height, bx, by, bw, bh, c)
	end
	if bh > 64 then
		len = left_right(len, tex_width, tex_height, bx, by, bw, bh, c)
	end
	local fill_idx = len
	if bw > 64 and bh > 64 then
		len = fill(len, tex_width, tex_height, bx, by, bw, bh, c)
	end
	trim(v, len)
	trim(t, len)
	return fill_idx
end


local function populate_vert(block)
	args.texture = sprites[block.id].img
	local tex_width, tex_height = args.texture.width, args.texture.height --dimensions of one frame of the texture
	tex_height = tex_height / get_frame_count(block.id)
	local len = 0
	local x, y = block.x, block.y --top left of block
	local x2, y2 = x + block.width, y + block.height --bottom right of block
	local y_, y2_ = y + 32, y2 - 32 --bottom of top edge, top of bottom edge
	rect(v, len, x, y, x2, y_) --top edge
	rect(t, len, 0, 0, 1, 32/tex_height)
	len = len + 12
	rect(v, len, x, y2_, x2, y2) --bottom edge
	rect(t, len, 0, 1-32/tex_height, 1, 1)
	len = len + 12
	local maxH = tex_height - 64 --max height of a segment
	for i = y_, y2_, maxH do --top edge of each segment
		if i == y2_ then
			break
		end
		local i2 = math_min(y2_, i + maxH) --bottom edge of each segment
		local th = (i2 - i)/tex_height --height of each segment, as tex coords
		rect(v, len, x, i, x2, i2) --middle bit
		rect(t, len, 0, 32/tex_height, 1, th+32/tex_height)
		len = len + 12
	end
	trim(v, len)
	trim(t, len)
	return 24
end

local function populate_horz(block)
	args.texture = sprites[block.id].img
	local tex_width, tex_height = args.texture.width, args.texture.height --dimensions of one frame of the texture
	tex_height = tex_height / get_frame_count(block.id)
	local len = 0
	local x, y = block.x, block.y --top left of block
	local x2, y2 = x + block.width, y + block.height --bottom right of block
	local x_, x2_ = x + 32, x2 - 32 --right of left edge, left of right edge
	rect(v, len, x, y, x_, y2) --left edge
	rect(t, len, 0, 0, 32/tex_width, 1)
	len = len + 12
	rect(v, len, x2_, y, x2, y2) --right edge
	rect(t, len, 1-32/tex_width, 0, 1, 1)
	len = len + 12
	local maxW = tex_width - 64 --max width of a segment
	for i = x_, x2_, maxW do --left edge of each segment
		if i == x2_ then
			break
		end
		local i2 = math_min(x2_, i + maxW) --right edge of each segment
		local tw = (i2 - i)/tex_width --width of each segment, as tex coords
		rect(v, len, i, y, i2, y2) --middle bit
		rect(t, len, 32/tex_width, 0, tw+32/tex_width, 1)
		len = len + 12
	end
	trim(v, len)
	trim(t, len)
	return 24
end

local function animate(id)
	local frames = get_frame_count(id)
	if frames == 1 then
		return
	end
	local offset = get_frame(id) / frames
	for i = 2, #t, 2 do
		t[i] = offset + t[i]/frames
	end
end

function sizable.onInitAPI()
	registerEvent(sizable, "onDraw", "onDraw", false)
end

local cam1 = { }
local cam2 = { }

function sizable.drawSizable(block, cam, priority, target, color, shader)
	if (not block.isHidden) then
		cam1[1] = cam.x
		cam1[2] = cam.y
		cam1[3] = cam1[1]+cam.width
		cam1[4] = cam1[2]+cam.height
		local bx,by,bw,bh = block.x,block.y,block.width,block.height
		if (intersect2(bx, by, bw, bh, cam1)) then
			local draw, horz, vert = false, false, false
			local fill_idx
			local bid = block.id
			--[[
			if false then
				fill_idx = populate_vert(block)
				draw = true
				vert = true
			elseif false then
				fill_idx = populate_horz(block)
				draw = true
				horz = true
			]]
			local img = sprites[bid].img
			if color then
				args.vertexColors = vc
			else
				args.vertexColors = nil
			end
			if img.width > 64 and img.height > 64 then
				fill_idx = populate(block, bid, img, bx, by, bw, bh, color)
				trim(vc, #v*2)
				draw = true
				horz, vert = true, true
			end
			if draw then
				animate(bid)
				args.target = target
				args.shader = shader
				args.priority = priority or args.priority
				Graphics.glDraw(args)
				args.priority = -90
				args.target = nil
				args.shader = nil
			end
			args.vertexColors = nil
		end
	end
end

function sizable.onDraw()
	cam1[1] = camera.x
	cam1[2] = camera.y
	cam1[3] = cam1[1]+camera.width
	cam1[4] = cam1[2]+camera.height
	
	local issplit = camera2.isSplit
	if issplit then
		cam2[1] = camera2.x
		cam2[2] = camera2.y
		cam2[3] = cam2[1]+camera2.width
		cam2[4] = cam2[2]+camera2.height
	end
	
	for _,block in Block.iterateSizable() do
		if (not block.isHidden) then
			local bx,by,bw,bh = block.x,block.y,block.width,block.height
			if (intersect2(bx, by, bw, bh, cam1) or (issplit and intersect2(bx, by, bw, bh, cam2))) then
				local draw, horz, vert = false, false, false
				local fill_idx
				local bid = block.id
				--[[
				if false then
					fill_idx = populate_vert(block)
					draw = true
					vert = true
				elseif false then
					fill_idx = populate_horz(block)
					draw = true
					horz = true
				]]
				local img = sprites[bid].img
				if img.width > 64 and img.height > 64 then
					fill_idx = populate(block, bid, img, bx, by, bw, bh)
					draw = true
					horz, vert = true, true
				end
				if draw then
					animate(bid)
					Graphics.glDraw(args)
				end
			end
		end
	end
end

return sizable
