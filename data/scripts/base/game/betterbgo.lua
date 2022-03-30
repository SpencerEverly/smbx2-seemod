local iniparse = require("configFileReader")
local bgoconfig = require("game/bgoconfig")

local betterbgo = {};

BGO._SetVanillaBGORenderFlag(false)

function betterbgo.onInitAPI()
	registerEvent(betterbgo, "onDraw", "onDraw", false);
	registerEvent(betterbgo, "onCameraDraw", "onCameraDraw", false);
end

local bgotimer = {};
local bgoframe = {};

--[[ --For one draw call per visible BGO ID version
--glDraw args for specific BGO IDs - weak to allow garbage collection
local bgoArrays = setmetatable({}, {__mode="v"})
--Strong copy of bgoArrays values - only lasts for one frame and prevents data being GC'd mid use
local bgoArrayCache = {}
--]]

--Sprites for specific BGO IDs
local bgoArrays = {}
--List of active IDs
local bgoArrayCache = {}

local rawframes = bgoconfig.__frames
local rawframespeed = bgoconfig.__framespeed
local rawheight = bgoconfig.__height
local rawwidth = bgoconfig.__width
local rawpriority = bgoconfig.__priority

local tableinsert = table.insert
local max = math.max
local glDraw = Graphics.glDraw
local getBGOs = BGO.getIntersecting
local ipairs = ipairs

for k=1,BGO_MAX_ID do
	bgotimer[k] = 0
	bgoframe[k] = 0
end

function betterbgo.onDraw()
	for id=1,BGO_MAX_ID do
		local f = rawframes[id];
		if(f > 1) then
			bgotimer[id] = bgotimer[id] + 1;
			if(bgotimer[id] >= rawframespeed[id]) then
				bgotimer[id] = 0;
				bgoframe[id] = bgoframe[id]+1;
				if(bgoframe[id] >= f) then
					bgoframe[id] = 0;
				end
			end
		else
			bgoframe[id] = 0;
		end
	end
	
end

--[[ --One draw call per visible BGO ID - causes sorting issues since all BGOs of a given ID are drawn together
function betterbgo.onCameraDraw(camidx)
	local c = Camera.get()[camidx];
	local cw = c.width;
	local ch = c.height;
	
	if(cw > 0 and ch > 0) then
		local cx = c.x;
		local cy = c.y;
		
		for i,v in ipairs(getBGOs(cx,cy,cx+cw,cy+ch)) do
			if(not v.isHidden) then
				local id = v.id;
				
				local h = rawheight[id];
				local w = rawwidth[id];
				v.width = w;
				v.height = h;
				if(w > 0 and h > 0) then
					local x1 = v.x;
					local y1 = v.y;
					local ti = h*(max(0,bgoframe[id]));
					local frames = rawframes[id]
					
					local a = bgoArrays[id]
					
					if a == nil then
						local img = Graphics.sprites.background[id].img
						local t = { vertexCoords = {}, textureCoords = {}, texture = img, sceneCoords = true, priority = rawpriority[id], __tw = 1/img.width, __th = 1/img.height, __idx = 1}
						tableinsert(bgoArrayCache, t)
						bgoArrays[id] = t
						a = t
					elseif a.texture == nil then
						tableinsert(bgoArrayCache, a)
						img = Graphics.sprites.background[id].img
						a.texture = img
						a.__tw = 1/img.width
						a.__th = 1/img.height
					end
					
					do
						local ts = a.textureCoords
						local vs = a.vertexCoords
						
						local _i = a.__idx
						
						vs[_i],    vs[_i+1]   = x1,   y1
						vs[_i+2],  vs[_i+3]   = x1+w, y1
						vs[_i+4],  vs[_i+5]   = x1,   y1+h
						vs[_i+6],  vs[_i+7]   = x1,   y1+h
						vs[_i+8],  vs[_i+9]   = x1+w, y1
						vs[_i+10], vs[_i+11]  = x1+w, y1+h
						
						--Texel size
						local txw = a.__tw
						local txh = a.__th
						
						local t1 = ti * txh
						local t2 = t1 + 1/frames
						
						--Reduce texel size for quarter-texel inset
						txh = txh*0.25
						txw = txw*0.25
						t1 = t1 + txh
						t2 = t2 - txh
						
						ts[_i],	   ts[_i+1]	  = txw,	  t1
						ts[_i+2],  ts[_i+3]	  = 1-txw,	  t1
						ts[_i+4],  ts[_i+5]	  = txw,	  t2
						ts[_i+6],  ts[_i+7]	  = txw,	  t2
						ts[_i+8],  ts[_i+9]	  = 1-txw,	  t1
						ts[_i+10], ts[_i+11]  = 1-txw,	  t2
					
						a.__idx = _i+12
					end
					--Graphics.drawImageToSceneWP(sprites[id],x1,y1,0,ti,w,h,1,rawpriority[id]);
				end
			end
		end
		
		for i=1,#bgoArrayCache do
			local a = bgoArrayCache[i]
			for j=a.__idx,#a.vertexCoords do
				a.vertexCoords[j] = nil
				a.textureCoords[j] = nil
			end
			glDraw(a)
			a.__idx = 1
			a.texture = nil
			bgoArrayCache[i] = nil
		end
	end
end
--]]

function betterbgo.onCameraDraw(camidx)
	local c = Camera(camidx);
	local cw = c.width;
	local ch = c.height;
	
	if(cw > 0 and ch > 0) then
		local cx = c.x;
		local cy = c.y;
		
		for i,v in ipairs(getBGOs(cx,cy,cx+cw,cy+ch)) do
			if(not v.isHidden) then
				local id = v.id;
				
				local h = rawheight[id];
				local w = rawwidth[id];
				v.width = w;
				v.height = h;
				if(w > 0 and h > 0) then
					local x1 = v.x;
					local y1 = v.y;
					local ti = h*(max(0,bgoframe[id]));
					local frames = rawframes[id]
					
					local a = bgoArrays[id]
					
					if a == nil then
						tableinsert(bgoArrayCache, id)
						bgoArrays[id] = Graphics.sprites.background[id].img
						a = bgoArrays[id]
					end
					
					Graphics.drawImageToSceneWP(a,x1,y1,0,ti,w,h,1,rawpriority[id]);
				end
			end
		end
		
		for i=1,#bgoArrayCache do
			bgoArrays[bgoArrayCache[i]] = nil
			bgoArrayCache[i] = nil
		end
	end
end

return betterbgo;