-------------------breakingDirt------------------                             
-------------Created by Enjl  - 2017-------------
---------------Idea by CraftedPBody--------------
-----Yoshi's Island Autotiling Dirt Library------
--------------For Super Mario Bros X-------------
----------------------v1.1-----------------------

local breakingDirt = {}

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local emptyImage = Graphics.loadImage(Misc.resolveFile("graphics/stock-0.png"))

--Offsets for different table values per quarter block. Order: None, horizontal, vertical, inwards corner, full

local offsets = {}
--UL Quarter
offsets[1] = {{0,0},      {0.4,0},    {0,0.5},    {0.8,0},    {0.4,0.5}}
--UR Quarter
offsets[2] = {{0.6,0},    {0.2,0},    {0.6,0.5},  {0.8,0.25}, {0.2,0.5}}
--DL Quarter
offsets[3] = {{0,0.75},   {0.4,0.75}, {0,0.25},   {0.8,0.5},  {0.4,0.25}}
--DR Quarter
offsets[4] = {{0.6,0.75}, {0.2,0.75}, {0.6,0.25}, {0.8,0.75}, {0.2,0.25}}

local tolerance = 4

local blockRefs = {}

local ids = {}

function breakingDirt.register(id)
	table.insert(ids, id)
	blockRefs[id] = {
		subBlockTable = {},
		blockReferenceTable = {},
		origVerts = {},
		usedVerts = {},
		usedTx = {},
	}
	blockmanager.registerEvent(id, breakingDirt, "onTickEndBlock")
end

local function setIntersecting(x,y, bt)
	local b = bt.origVerts[x * 100000 + y]
	if (b) then
		b.dirty = true
	end
	return false
end

local function isVisible(v)
	return not (v.isHidden or v:mem(0x5A, FIELD_BOOL) or v:mem(0x5C, FIELD_BOOL))
end

local function getIntersecting(x,y, bt)
	local b = bt.origVerts[x * 100000 + y]
	if (b) then
		return b.visible
	end
	return false
end

local function dirtify(v, bt)
	
	local offsetX = -1
	local offsetY = -1
	if v.corner %2 == 0 then
		offsetX = 1
	end
	if v.corner >= 3 then
		offsetY = 1
	end
	local x = v.gridX + offsetX
	local y = v.gridY + offsetY
	
	setIntersecting(x, v.gridY, bt)
	setIntersecting(v.gridX, y, bt)
	setIntersecting(x, y, bt)
	v.dirty = true
end

function breakingDirt.puffRemove(v)
	blockutils.puffRemove(v)
	local subTbl = v.data._basegame.subTblRef
	if subTbl ~= nil then
		for k,t in ipairs(subTbl) do
			t.visible = false
			dirtify(t, blockRefs[v.id])
		end
	end
end

function breakingDirt.onPostBlockHit(a)
	if blockRefs[a.id] then
		if not isVisible(a) then return end
		breakingDirt.puffRemove(a)
	end
end

local function getTx(v, bt)
	local offsetX = -1
	local offsetY = -1
	if v.corner %2 == 0 then
		offsetX = 1
	end
	if v.corner >= 3 then
		offsetY = 1
	end
	local x = v.gridX + offsetX
	local y = v.gridY + offsetY
	
	local displayType = 1
	--horizontal check
	if getIntersecting(x, v.gridY, bt) then
		displayType = displayType + 1
	end
	--vertical check
	if getIntersecting(v.gridX, y, bt) then
		displayType = displayType + 2
	end
	--if successful, diagonal check
	if displayType == 4 then
		if getIntersecting(x, y, bt) then
			displayType = displayType + 1
		end
	end
	return displayType
end

local function constructFrameVerts(bt)
	bt.usedVerts = {}
	bt.usedTx = {}
	bt.origVerts = {}
	local camTable = Camera.get()
	for k,s in ipairs(bt.subBlockTable) do
		for _, v in ipairs(s) do
			if v.inCam and v.visible then
				bt.origVerts[v.gridX * 100000 + v.gridY] = v
			end
		end
	end
	
	for _, u in ipairs(bt.blockReferenceTable) do
		local inCam = false
		local x1 = u.x
		local y1 = u.y
		local fullW = 2* bt.blockWidth
		local fullH = 2* bt.blockHeight
		for k,v in ipairs(camTable) do
			local x2 = v.x
			local y2 = v.y
			if x1 + fullW >= x2 - bt.blockWidth
			and y1 + fullH >= y2 - bt.blockHeight
			and x1 <= x2 + v.width + fullW + bt.blockWidth
			and y1 <= y2 + v.height + fullH + bt.blockHeight then
				inCam = true
			end
		end
		for k,v in ipairs(u.subTable) do
			if v.visible then
				v.inCam = inCam
			end
			if v.visible and v.inCam then
				dirtify(v, bt)
			end
		end
		if u.subTable[1].visible and inCam then
			--get appearance
			for k,v in ipairs(u.subTable) do
				if v.dirty then
					v.displayType = getTx(v, bt)
					v.dirty = false
				end
				--vt, tx
				local x = v.x
				local y = v.y
				local x2 = v.x + bt.blockWidth
				local y2 = v.y + bt.blockHeight
				
				local offsetX = offsets[v.corner][v.displayType][1]
				local offsetY = offsets[v.corner][v.displayType][2]
				local offsetX2 = offsetX + 0.2
				local offsetY2 = offsetY + 0.25
				
				--upLeft
				table.insert(bt.usedVerts,			x)
				table.insert(bt.usedVerts, 		y)
				
				table.insert(bt.usedTx, 			offsetX)
				table.insert(bt.usedTx, 			offsetY)
				
				
				for j=1,2 do
					--upRight
					table.insert(bt.usedVerts, 	x2)
					table.insert(bt.usedVerts, 	y)
					
					table.insert(bt.usedTx, 		offsetX2)
					table.insert(bt.usedTx, 		offsetY)
					
					--downLeft
					table.insert(bt.usedVerts, 	x)
					table.insert(bt.usedVerts, 	y2)
					
					table.insert(bt.usedTx, 		offsetX)
					table.insert(bt.usedTx, 		offsetY2)
				end
				--downRight
				table.insert(bt.usedVerts, 		x2)
				table.insert(bt.usedVerts, 		y2)
				
				table.insert(bt.usedTx, 			offsetX2)
				table.insert(bt.usedTx, 			offsetY2)
			end
		end
	end
end

function initBlock(v, bt)
	local r = {}
	local s = {}
	table.insert(bt.subBlockTable, s)
	r.subTable = s
	r.x = v.x
	r.y = v.y
	
	for i=0, 3 do
		local e = {x = v.x + (bt.blockWidth * (i%2)),
				y =  v.y + (bt.blockHeight * math.floor(i/2)),
				corner = i + 1,
				visible = isVisible(v)}
		e.gridX = math.floor(e.x /bt.blockWidth)
		e.gridY = math.floor(e.y /bt.blockHeight)
		e.displayType = 0
		e.dirty = true
		e.ref = r
		table.insert(s, e)
		bt.origVerts[e.gridX * 100000 + e.gridY] = e
	end
	
	v.data._basegame.subTblRef = s
	v.data._basegame.content = v.contentID
	v.contentID = 0
	table.insert(bt.blockReferenceTable, r)
end

function breakingDirt.onStart()
	for _,i in ipairs(ids) do
		local bt = blockRefs[i]
		bt.blockWidth = 0.5 * Block.config[i].width
		bt.blockHeight = 0.5 * Block.config[i].height
		
		for k,v in Block.iterate(i) do
			initBlock(v, bt)
		end
		bt.texture = Graphics.sprites.block[i].img
		Graphics.sprites.block[i].img = emptyImage
		constructFrameVerts(bt)
	end
end

function breakingDirt.onTickEndBlock(v)
	local tbl = v.data._basegame.subTblRef
	if tbl == nil then
		initBlock(v, blockRefs[v.id])
		tbl = v.data._basegame.subTblRef
	end
	if isVisible(v) then
		local bt = blockRefs[v.id]
		local x = v.x
		local y = v.y
		for i,w in ipairs(tbl) do
			if w.inCam then
				local x2, y2 = w.x, w.y
				w.x = x + (bt.blockWidth * ((i-1)%2))
				w.y = y + (bt.blockWidth * math.floor((i-1) * 0.5))
				w.gridX = math.floor(w.x/bt.blockWidth)
				w.gridY = math.floor(w.y/bt.blockWidth)
				w.visible = true
				if (w.x ~= x2 or w.y ~= y2) then
					v.dirty = true
				end
			end
		end
		local r = tbl[1].ref
		r.x = x
		r.y = y
	elseif tbl[1].visible then
		for i,w in ipairs(tbl) do
			w.visible = false
		end
	end
end

function breakingDirt.onTickEnd()
	for k,v in ipairs(ids) do
		constructFrameVerts(blockRefs[v])
	end
end

function breakingDirt.onDraw()
	for k,v in ipairs(ids) do
		if #blockRefs[v].usedVerts > 0 then
			Graphics.glDraw{
				sceneCoords = true,
				primitive = Graphics.GL_TRIANGLES,
				priority = -65,
				texture = blockRefs[v].texture,
				vertexCoords = blockRefs[v].usedVerts,
				textureCoords = blockRefs[v].usedTx
			}
		end
	end
end

function breakingDirt.onInitAPI()
	registerEvent(breakingDirt,"onStart","onStart")
	registerEvent(breakingDirt,"onTickEnd","onTickEnd")
	registerEvent(breakingDirt,"onDraw","onDraw")
	registerEvent(breakingDirt, "onPostBlockHit")
end

return breakingDirt