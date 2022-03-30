local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}

local settings = blockmanager.setBlockSettings({
	id = blockID,
	frames = 4,
	flashcolor = Color.red,
	randomflashes = true,
	smashable = 2
})

local sound682 = Misc.resolveSoundFile("tnt")

local data682 = {timer = 192, ticks={ 1, 67, 102, 132, 147, 162, 177}};

local function icontains(t,v)
	for _,w in ipairs(t) do
		if(v == w) then
			return true;
		end
	end
	return false;
end

local tableinsert = table.insert
local verts = {}
local txs = {}
local vcol = {}

local function addVerts(x1, y1, x2, y2, t1, t2, col)
	tableinsert(verts, x1)
	tableinsert(verts, y1)
	tableinsert(verts, x2)
	tableinsert(verts, y1)
	tableinsert(verts, x1)
	tableinsert(verts, y2)
	
	tableinsert(txs, 0)
	tableinsert(txs, t1)
	tableinsert(txs, 1)
	tableinsert(txs, t1)
	tableinsert(txs, 0)
	tableinsert(txs, t2)
	
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
		
		
	tableinsert(verts, x1)
	tableinsert(verts, y2)
	tableinsert(verts, x2)
	tableinsert(verts, y1)
	tableinsert(verts, x2)
	tableinsert(verts, y2)
	
	tableinsert(txs, 0)
	tableinsert(txs, t2)
	tableinsert(txs, 1)
	tableinsert(txs, t1)
	tableinsert(txs, 1)
	tableinsert(txs, t2)
	
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
	tableinsert(vcol, col.r)
	tableinsert(vcol, col.g)
	tableinsert(vcol, col.b)
	tableinsert(vcol, col.a)
end

local function getFrame(data)
	return data.frame or math.floor(3*(1+(data.timer-data682.timer)/data682.timer))+1
end


local sectionbounds = {}
local function checkSections(v)
	if #sectionbounds == 0 then
		for k,s in ipairs(Section.getActive()) do
			local sb = s.boundary
			sectionbounds[k] = {sb.left,sb.top,sb.right,sb.bottom}
		end
	end
	for _,b in ipairs(sectionbounds) do
		if  v.x + v.width > b[1] - 32 and v.x < b[3] + 32 and
			v.y + v.height > b[2] - 32 and v.y < b[4] + 32 then
				return true
		end
	end
	return false
end

function block.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) or not checkSections(v) then return end
	local data = v.data._basegame
	
	if data.timer then
		if (data.timer > 0 or (data.timer < data682.timer and data.timer > 8)) then
			blockutils.zeroBump(v);
		end
	end
	if blockutils.isOnScreen(v) then
		if data.timer and data.timer < data682.timer and v:mem(0x56, FIELD_WORD) == 0 then
			local f = getFrame(data)
			addVerts(v.x, v.y, v.x+v.width, v.y+v.height, f/4, (f+1)/4, math.lerp(settings.flashcolor, Color.alphablack, ((3*(1+(data.timer-data682.timer)/data682.timer))%1)*2)..0)
		else
			local yoff = v:mem(0x56,FIELD_WORD)
			
			
			local c = Color.alphablack
			
			if settings.randomflashes then
				if (data.flash == nil or data.flash == 0) and RNG.randomInt(200) == 0 and not Defines.levelFreeze then
					data.flash = 4
				end
				if data.flash ~= nil and data.flash > 0 then
					c = (settings.flashcolor*(0.5*(data.flash/8)))..0
					data.flash = data.flash - 1
				end
			end
			addVerts(v.x, v.y+yoff, v.x+v.width, v.y+v.height+yoff, 0, 1/4, c)
		end
	end
end

local function startTimer(v, p)
	local obj = {cancelled = false}
	if type(p) == "Player" then
		p = p.idx
	else
		p = 0
	end
	EventManager.callEvent("onBlockHit", obj, v.idx, false, p)
	return not obj.cancelled
end

function block.onPostBlockHit(v, u, pl)
	if v.id ~= blockID then return end
	
	if pl and (pl.hasStarman or pl.isMega) then
		blockutils.detonate(v, 4)
	else
		if v.data._basegame.timer == nil then
			v.data._basegame.timer = 0
		end
	end
end

local yoshis = 
	{ 
		[95] = true,
		[98] = true,
		[99] = true,
		[100] = true,
		[148] = true,
		[149] = true,
		[150] = true,
		[228] = true
	}
	
local function setDelay(data)
	if data.timer == nil or data.timer >= 0 then
		if data.timer and data.timer > 0 then
			data.frame = getFrame(data)
		end
		data.timer = -12
	end
end

function block:onPostExplosionBlock(c, pl)
	if Colliders.collide(c.collider,self) then
		if c.strong or pl.idx > 0 then
			blockutils.detonate(self, 4)
		else
			setDelay(self.data._basegame)
		end
	end
end

function block.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data._basegame
	
	if v:mem(0x54,FIELD_WORD) == 12 then
		setDelay(data)
	end
	
	if data.timer then
		blockutils.zeroBump(v)
		if data.timer < data682.timer then
			if data.timer <= 0 or not Defines.levelFreeze then
				data.timer = data.timer+1
				if icontains(data682.ticks,data.timer) then
					SFX.play(sound682)
				end
			end
			if data.timer == data682.timer or data.timer == 0 then
				blockutils.detonate(v, 4)
			end
		end
	elseif checkSections(v) then
		blockutils.zeroBump(v)
		local collider = blockutils.getHitbox(v, 1)
	
		--TODO: Replace with better bouncing
		for _,w in ipairs(Player.get()) do
			if w.speedY > 0 and w.x < v.x+v.width and w.x + w.width > v.x and Colliders.bounce(w, collider) then
				if w.hasStarman or w.isMega then
					Colliders.bounceResponse(w)
					blockutils.detonate(v, 4)
					break
				elseif startTimer(v) then
					Colliders.bounceResponse(w)
					break
				end
			end
			
			if Colliders.slash(w, collider) or Colliders.downSlash(w, collider) then
				blockutils.detonate(v, 4)
			end
		end
		
		--Makes NPCs bounce (or immediately detonate the TNT)
		for _,w in ipairs(NPC.getIntersecting(v.x, v.y-6, v.x+v.width, v.y+v.height+7)) do
			local cfg = NPC.config[w.id]
			if not cfg.iscollectablegoal and not cfg.isinteractable then
				if cfg.ishot then
					blockutils.detonate(v, 4)
					if w:mem(0x136,FIELD_BOOL) then
						w:harm(HARM_TYPE_PROJECTILE_USED)
					end
					break
				elseif not cfg.noblockcollision and w.speedY > 0 and w.y+w.height < v.y and Colliders.bounce(w, collider) then
					if startTimer(v) then
						Colliders.bounceResponse(w, 4)
						
						if yoshis[w.id] and w.ai1 == 0 then
							w.ai1 = 1
							SFX.play(49)
						end
						
						break
					end
				end
			end
		end
	end
end

function block.onCollideBlock(v,n)
	if n.__type == "NPC" then
		if n:mem(0x136,FIELD_BOOL) then
			if not NPC.SHELL_MAP[n.id] or n.y + n.height > v.y then
				if NPC.config[n.id].ishot then
					blockutils.detonate(v, 4)
				else
					startTimer(v)
				end
			end
		elseif NPC.config[n.id].ishot then
			blockutils.detonate(v, 4)
		end
	elseif type(n) == "Player" and (n.hasStarman or n.isMega) then
		blockutils.detonate(v, 4)
	end
end

local drawTable = {vertexCoords = verts, textureCoords = txs, sceneCoords=true, priority=-65}
function block.onDraw()

	for i = 1,#sectionbounds do
		sectionbounds[i] = nil
	end

	mem(mem(0x00B2BEA0,FIELD_DWORD)+(2*(blockID-1)),FIELD_WORD,4)
	
	drawTable.texture=Graphics.sprites.block[682].img
	drawTable.vertexColors = nil
	
	Graphics.glDraw(drawTable)
	
	drawTable.texture = nil
	drawTable.vertexColors = vcol
	Graphics.glDraw(drawTable)
	
	for i=1,#verts do
		verts[i] = nil
		txs[i] = nil
		vcol[2*i - 1] = nil
		vcol[2*i] = nil
	end
end

local function idfilter(v)
	return v.id == blockID and not v.isHidden and not v:mem(0x5A, FIELD_BOOL)
end
function block.onPostNPCKill(v, rsn)
	if rsn ~= 4 and rsn ~= 3 then return end
	
	for _,w in ipairs(blockutils.checkNPCCollisions(v, idfilter)) do
		block.onCollideBlock(w,v)
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
    blockmanager.registerEvent(blockID, block, "onTickBlock")
    blockmanager.registerEvent(blockID, block, "onDrawBlock")
    blockmanager.registerEvent(blockID, block, "onPostExplosionBlock")
    registerEvent(block, "onPostBlockHit", "onPostBlockHit", false)
    registerEvent(block, "onPostNPCKill")
    registerEvent(block, "onDraw")
end

return block