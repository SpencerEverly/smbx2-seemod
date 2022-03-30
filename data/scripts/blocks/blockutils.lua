local blockutils = {}

local blockmanager = require("base/game/blockeventmanager")
local sizable
local tableinsert = table.insert
local mathhuge = math.huge
local mathmin = math.min
local mathabs = math.abs

-- Returns if the block is currently visible on the specified camera.
function blockutils.visible(cam, x, y, w, h)
	if x < cam.x-w then
		return false;
	elseif x > cam.x+cam.width then
		return false;
	elseif y < cam.y-h then
		return false;
	elseif y > cam.y+cam.height then
		return false;
	else
		return true;
	end
end

-- Sets the block's layer.
function blockutils.setLayer(v, newLayer)
	v:mem(0x18,FIELD_STRING, newLayer)
end

local defaultHiddenSwitch = {
	[690] = true
}
local switchedIDs = {}
local switchedIDMap = {}

local bumpingList = {}

-- For management of block switching.
function blockutils.queueSwitch(solid, nonsolid)	
	if switchedIDMap[solid] or switchedIDMap[nonsolid] then return end

	tableinsert(switchedIDs, solid)
	tableinsert(switchedIDs, nonsolid)
	switchedIDMap[solid] = nonsolid
	switchedIDMap[nonsolid] = solid
end

function blockutils.resolveSwitchQueue()
	if #switchedIDs > 0 then
		for k,v in Block.iterateByFilterMap(switchedIDMap) do
			v.id = switchedIDMap[v.id]
		end
		switchedIDs = {}
		switchedIDMap = {}
	end
end

-- Returns an estimate of the block's section. Blocks have no "section" field, so we find whichever section is closest. Prioritises earlier sections in the case where sections overlap.
function blockutils.getBlockSection(v)
	local dist = mathhuge
	local current = 0
	for i = 0,20 do
		local b = Section(i).boundary
		
		--Block sits within the section
		if  v.x+v.width >= b.left and v.x <= b.right
		and v.y+v.height >= b.top and v.y <= b.bottom then
			return i
		else
		--Find smallest axis and assume it sits in that section
			local d = mathmin(mathabs(b.left - (v.x+v.width)), mathabs(v.x - b.right), mathabs(b.top - (v.y+v.height)), mathabs(v.y - b.bottom))
			if d < dist then
				dist = d
				current = i
			end
		end
	end
	return current
end

-- Returns an estimate of the block's section by assuming the block exists in one of the player's sections and choosing the closest one.
function blockutils.getClosestPlayerSection(v)	
	local section = player.section
	
	if player2 and player2.section ~= player.section then
		local p1 = vector.v2(player.x - v.x, player.y - v.y)
		local p2 = vector.v2(player2.x - v.x, player2.y - v.y)
		
		if p2.sqrlength < p1.sqrlength then
			section = player2.section
		end
	end
	return section
end

function blockutils.hiddenFilter(v)
    return not v.isHidden and not v:mem(0x5A, FIELD_BOOL)
end

-- Uses either the contentID field or the basegame content field to spawn the appropriate NPC in the middle of the block's coordinates.
function blockutils.spawnNPC(v)
	local section = blockutils.getClosestPlayerSection(v)

	local id = v.contentID
	if v.data._basegame.content then
		id = v.data._basegame.content
	end
	
	if id > 1000 then
		NPC.spawn(id-1000,v.x + 0.5 * v.width - 0.5 * NPC.config[id - 1000].width, v.y + 0.5 * v.height - 0.5 * NPC.config[id - 1000].height,section)
	elseif id >= 1 and id < 100 then
		for i=1,id do
			local coin = NPC.spawn(10,v.x + 0.5 * v.width - 0.5 * NPC.config[10].width, v.y + 0.5 * v.height - 0.5 * NPC.config[10].height, section)
			coin.speedX = RNG.randomInt(-3,3)
			coin.speedY = RNG.randomInt(-5,-1)
			coin.ai1 = 1;
		end
	end
end

local kirbyExplosionSound = Misc.resolveSoundFile("kirbybomb")

-- A puff-based removal event. Contents are dropped from the block's location. Plays kirbybomb.ogg
function blockutils.puffRemove(v)
	SFX.play(kirbyExplosionSound)
	Animation.spawn(10,v.x,v.y);
	
	blockutils.spawnNPC(v)
	v:remove();
end

-- Kirby detonations detonate adjacent blocks of specific IDs in cardinal directions.
function blockutils.kirbyDetonate(v, idFilter)
	local _,_,cs1 = Colliders.collideBlock(Colliders.Box(v.x-2,v.y+2,v.width+4,v.height-4), idFilter, blockutils.hiddenFilter);
	local _,_,cs2 = Colliders.collideBlock(Colliders.Box(v.x+2,v.y-2,v.width-4,v.height+4), idFilter, blockutils.hiddenFilter);
	for _,w in ipairs(cs1) do
		if(w ~= v) then
			w.data._basegame.timer = 0
		end
	end
	for _,w in ipairs(cs2) do
		if(w ~= v) then
			w.data._basegame.timer = 0
		end
	end
	blockutils.puffRemove(v);
	Defines.earthquake = 2
end

-- Hits a block if it's intersecting with a bomb explosion
function blockutils.hitExplosion(v)
	if not blockutils.hiddenFilter(v) then
		return false;
	end
	--[[
	for _,w in ipairs(Effect.get({69})) do
		if w.timer >= 59 then
			local box = Colliders.Circle(w.x + 0.5 * w.width,w.y + 0.5 * w.height, 50)
			if Colliders.collide(v,box) then
				return true
			end
		end
	end]]
	for _,w in ipairs(Explosion.get()) do
		if Colliders.collide(v,w.collider) then
			return true
		end
	end
end

-- Calls upon a bomb explosion in the block's location
function blockutils.detonate(v, typ)
	blockutils.spawnNPC(v)
	local x = v.x+v.width*0.5
	local y = v.y+v.height*0.5
	v:remove()
	Explosion.spawn(x,y,typ or 2)
end

-- Zeroes out an ongoing bump event
function blockutils.zeroBump(v)
	v:mem(0x52,FIELD_WORD,0)
	v:mem(0x54,FIELD_WORD,0)
	v:mem(0x56,FIELD_WORD,0)
end

-- Performs a bump animation
function blockutils.bump(v)
	if v:mem(0x54, FIELD_WORD) == 0 then --don't bump if a bump is already happening
		v:mem(0x52,FIELD_WORD,-12)
		v:mem(0x54,FIELD_WORD,12)
		v:mem(0x56,FIELD_WORD,0)
		tableinsert(bumpingList, v)
	end
end

-- For bumping blocks during time freeze
function blockutils.bumpDuringTimefreeze(v)
	if(Defines.levelFreeze) then

		v:mem(0x56,FIELD_WORD,-(v:mem(0x52,FIELD_WORD)+v:mem(0x54,FIELD_WORD)));

		if(v:mem(0x52,FIELD_WORD) < 0) then
			v:mem(0x52,FIELD_WORD,math.min(v:mem(0x52,FIELD_WORD)+4,0));
		elseif(v:mem(0x54,FIELD_WORD) > 0) then
			v:mem(0x54,FIELD_WORD,math.max(v:mem(0x54,FIELD_WORD)-4,0));
		end
	end
end

local frameOffset = mem(0x00B2BEA0,FIELD_DWORD)
-- For management of the global block animation
function blockutils.setBlockFrame(id,frame)
	local frameLoc = frameOffset+(2*(id-1));
	mem(frameLoc,FIELD_WORD,frame);
end

function blockutils.getBlockFrame(id)
	local frameLoc = frameOffset+(2*(id-1));
	return mem(frameLoc,FIELD_WORD);
end

local cambounds = { camera.bounds, camera2.bounds }
function blockutils.isOnScreen(v, buffer)
	for _,c in ipairs(cambounds) do
		if  v.x + v.width > c.left - (buffer or 32) and v.x < c.right + (buffer or 32) and
			v.y + v.height > c.top - (buffer or 32) and v.y < c.bottom + (buffer or 32) then
				return true
		end
	end
	return false
end

function blockutils.isInActiveSection(v)
	for _,s in ipairs(Section.getActive()) do
		local b = s.boundary
		if  v.x + v.width > b.left - 32 and v.x < b.right + 32 and
			v.y + v.height > b.top - 32 and v.y < b.bottom + 32 then
				return true
		end
	end
	return false
end

-- Clears the block's content field and stores it. Remembers content while preventing bumping.
function blockutils.storeContainedNPC(v)
	if v.contentID ~= 0 then
		v.data._basegame.content = v.contentID
		v.contentID = 0; --prevent bonking from below
	end
end

-- Plays a sound effect only if a block with this ID is onscreen.
function blockutils.playSound(id,s,v)
	blockmanager.pushSound(id,s,v or 1)
end

-- Returns a collider shaped around the block (not valid across multiple frames or calls)
function blockutils.getHitbox(b, swell)
	return blockmanager.getBlockHitbox(b.id, b.x, b.y, b.width, b.height, swell or 0)
end

	
local npcCollider = Colliders.Box(0,0,1,1)
function blockutils.checkNPCCollisions(v, filter)
	npcCollider.x = v.x - 4
	npcCollider.y = v.y - 4
	npcCollider.width = v.width + 8
	npcCollider.height = v.height + 8
	return Colliders.getColliding{a = npcCollider, btype = Colliders.BLOCK, filter = filter }
end

--Drawing block mask stuff
if not isOverworld then	
	local blockConfigs
	
	local maskShader = Misc.resolveFile("shaders/effects/mask.frag")
	local voronoiShader = Misc.resolveFile("shaders/effects/voronoi.frag")
	local distanceShader = Misc.resolveFile("shaders/effects/distancefield.frag")
	local blockdraw = {priority=-100, sceneCoords=true, primitive=Graphics.GL_TRIANGLES}
		
	local bsprites = Graphics.sprites.block
	local BlockIterateIntersecting = Block.iterateIntersecting
	local mask = {}	
	
	local blocktarget = Graphics.CaptureBuffer(800,600)
	local blocktarget2 = Graphics.CaptureBuffer(800,600)
	
	local voronoitarget = Graphics.CaptureBuffer(800,600)
	local masktarget = Graphics.CaptureBuffer(800,600)
	
	local glDraw = Graphics.glDraw
	local blocklist = {}
	local blockmap = {}
	
	local maskcolors = { [false] = Color.red, [true] = Color.green, [1] = Color.blue }
	
	local function isNotBlack(s)
		local n = tonumber(s)
		if n then
			return n > 0
		elseif s ~= "alphablack" and s ~= "black" and s ~= "transparent" and Color[s] then
			return true
		elseif type(s) == "Color" then
			return s[1] ~= 0 or s[2] ~= 0 or s[3] ~= 0
		else
			n = tonumber(stringsub(s, 2))
			if n then
				return n > 0
			else
				return false
			end
		end
	end

	local function hasLight(tbl)
		local radius = tbl.lightradius
		local brightness = tbl.lightbrightness
		if radius ~= nil and brightness ~= nil and radius > 0 and brightness > 0 then
			return isNotBlack(tbl.lightcolor or 255)
		else
			return false
		end
	end
		
	local function maskCfgCheck(id)
		if blockConfigs[id] == nil then
			local cfg = Block.config[id]
			blockConfigs[id] = { cfg.sizable, cfg.noshadows or hasLight(cfg) }
		end
				
		return blockConfigs[id]
	end
	
	Block.maskFilter = { solid = true, sizable = true, noshadows = true }
	
	--Draw blocks to the scene to use as a mask
	function blockutils.getMask(cam, useDistanceField)
		if sizable == nil then
			sizable = require("base/game/sizable")
		end
	
		if mask[cam.idx] and mask[cam.idx][useDistanceField] then
			return mask[cam.idx][useDistanceField]
		end
		if type(maskShader) == "string" then
			local t = maskShader
			maskShader = Shader()
			maskShader:compileFromFile(nil, t)
			blockdraw.shader = maskShader
		end
		
		if useDistanceField and type(voronoiShader)=="string" then
			t = voronoiShader
			voronoiShader = Shader()
			voronoiShader:compileFromFile(nil, t)
			
			t = distanceShader
			distanceShader = Shader()
			distanceShader:compileFromFile(nil, t)
		
			blocktarget2:clear(10)
			Graphics.drawScreen{color=Color.black, target = voronoitarget, priority = -100}
		end
		
		local target
		if useDistanceField then
			target = voronoitarget
		else
			target = blocktarget
		end
		
		target:clear(10)
		
		for _,v in ipairs(blocklist) do
			blockmap[v].dirty = true
		end
		local idx = 1
		
		local cx,cy,cw,ch = cam.x,cam.y,cam.width,cam.height
		local f = Block.maskFilter
		
		blockConfigs = {}
		for _,v in BlockIterateIntersecting(cx,cy,cx+cw,cy+ch) do
			local id = v.id
			if not v.isHidden and not v:mem(0x5A, FIELD_BOOL) then
				local cfg = maskCfgCheck(id)
				if not cfg[1] and (f.solid or f.noshadows) then
					if cfg[2] or f.solid then
						local map = blockmap[id]
						if map == nil then
							map = {dirty = true, verts = {}, txs = {}, cols = {}}
							blockmap[id] = map
						end
						
						local w,h = v.width, v.height
						if map.dirty then
							local frame = readmem(readmem(0x00B2BEA0,FIELD_DWORD)+(2*(id-1)),FIELD_WORD)
							local img = Darkness.shadowMaps[id] or bsprites[id].img
							local ty = (h/img.height)
							local ty2 = ty*(frame+1)
							ty = ty*frame
							
							map.frame = frame
							map.img = img
							map.ty1 = ty
							map.ty2 = ty2
							map.idx = 1
							map.dirty = false
							blocklist[idx] = id
							idx = idx + 1
						end
							
						local x,y = v.x,v.y+v:mem(0x56,FIELD_WORD)
						
						local verts = map.verts
						local txs = map.txs
						local cols = map.cols
						local vidx = map.idx
						local ty = map.ty1
						local ty2 = map.ty2
						
						verts[vidx],	verts[vidx+1] 	= x,	y
						verts[vidx+2],	verts[vidx+3] 	= x+w,	y
						verts[vidx+4],	verts[vidx+5] 	= x,	y+h
						verts[vidx+6],	verts[vidx+7] 	= x,	y+h
						verts[vidx+8],	verts[vidx+9] 	= x+w,	y
						verts[vidx+10],	verts[vidx+11] 	= x+w,	y+h
						
						txs[vidx],		txs[vidx+1]	 	= 0,	ty
						txs[vidx+2],	txs[vidx+3]	 	= 1,	ty
						txs[vidx+4],	txs[vidx+5]	 	= 0,	ty2
						txs[vidx+6],	txs[vidx+7]	 	= 0,	ty2
						txs[vidx+8],	txs[vidx+9]	 	= 1,	ty
						txs[vidx+10],	txs[vidx+11] 	= 1,	ty2
						
						local cidx = (vidx-1)/2
						local c = maskcolors[cfg[2]]
						
						for i = 1,6 do
							for j = 1,4 do
								cols[(cidx + i-1)*4 + j] = c[j]
							end
						end
						
						map.idx = vidx+12
					end
				elseif f.sizable then
					sizable.drawSizable(v, cam, -100, target, maskcolors[1], maskShader)
				end
			end
		end
		
		for i = 1,idx-1 do
			local v = blockmap[blocklist[i]]
			
			for j=#v.verts,v.idx,-1 do
				v.verts[j] = nil
				v.txs[j] = nil
				v.cols[j*2] = nil
				v.cols[j*2-1] = nil
			end
			blockdraw.vertexCoords = v.verts
			blockdraw.textureCoords = v.txs
			blockdraw.vertexColors = v.cols
			blockdraw.texture = v.img
			blockdraw.target = target
				
			glDraw(blockdraw)
			blockdraw.vertexColors = nil
		end
		
		if useDistanceField then
			local stepSize = 0.5
			for i=1,10 do
				Graphics.drawScreen{texture = target, target = blocktarget2, shader = voronoiShader, uniforms = {stepSize=stepSize}, prioirty = -100}
				stepSize = stepSize*0.5
				local t = blocktarget
				blocktarget = blocktarget2
				blocktarget2 = t
			end
			
			Graphics.drawScreen{texture=target, prioirty=-100, shader = distanceShader, target = masktarget}
			
			mask[cam.idx] = mask[cam.idx] or {}
			mask[cam.idx][true] = masktarget
			return masktarget
			
		else
			mask[cam.idx] = mask[cam.idx] or {}
			mask[cam.idx][false] = target
			return target
			
		end
	end
	
	registerEvent(blockutils, "onDrawEnd")
	
	function blockutils.onDrawEnd()
		mask[1] = nil
		mask[2] = nil
	end
end
	
	
registerEvent(blockutils, "onTickEnd", "onTickEnd", true)
registerEvent(blockutils, "onCameraDraw", "onCameraDraw", true)

function blockutils.onCameraDraw(camidx)
	cambounds[camidx] = Camera(camidx).bounds
end


function blockutils.onTickEnd()
	for i=#bumpingList,1,-1 do
		local v = bumpingList[i]
		if v:mem(0x54,FIELD_WORD) <= 0 then
			table.remove(bumpingList,i)
		elseif v:mem(0x52,FIELD_WORD) < 0 then
			v:mem(0x52,FIELD_WORD, v:mem(0x52,FIELD_WORD) + 4)
			v:mem(0x56,FIELD_WORD, v:mem(0x56,FIELD_WORD) - 4)
		else
			v:mem(0x54,FIELD_WORD, v:mem(0x54,FIELD_WORD) - 4)
			v:mem(0x56,FIELD_WORD, v:mem(0x56,FIELD_WORD) + 4)
		end
		
		if v:mem(0x54,FIELD_WORD) <= 0 then
			table.remove(bumpingList,i)
		end
	end
end

return blockutils