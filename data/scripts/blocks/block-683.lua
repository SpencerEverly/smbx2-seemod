local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}

local settings = blockmanager.setBlockSettings({
	id = blockID,
	flashcolor = Color.green..0.5,
	randomjumps = true,
	smashable = 2
})

function block.onPostBlockHit(v)	
	if v.id ~= blockID then return end
	
	local data = v.data._basegame
	if(data.timer == nil) then
		blockutils.detonate(v, 5)
		data.timer = 0
		blockutils.zeroBump(v)
	end
end

local tableinsert = table.insert
local verts = {}

local function addVerts(x1, y1, x2, y2)
	tableinsert(verts, x1)
	tableinsert(verts, y1)
	tableinsert(verts, x2)
	tableinsert(verts, y1)
	tableinsert(verts, x1)
	tableinsert(verts, y2)
		
		
	tableinsert(verts, x1)
	tableinsert(verts, y2)
	tableinsert(verts, x2)
	tableinsert(verts, y1)
	tableinsert(verts, x2)
	tableinsert(verts, y2)
end

local bounceSounds
local bounceSFX = 0

function block:onPostExplosionBlock(c, pl)
	local data = self.data._basegame
	if data.timer == nil and Colliders.collide(c.collider,self) then
		if c.strong or pl.idx > 0 then
			blockutils.detonate(self, 5)
		else
			data.timer = 0
			blockutils.zeroBump(self)
		end
	end	
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

function block.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data._basegame

	if data.timer then
		if data.timer < 12 then
			blockutils.zeroBump(v)
			data.timer = data.timer + 1
			if data.timer == 0 then
				blockutils.detonate(v, 5)
			end
		else
			blockutils.detonate(v, 5)
		end
	elseif checkSections(v) then
		for _,w in ipairs(NPC.getIntersecting(v.x, v.y-6, v.x+v.width, v.y+v.height+7)) do
			local cfg = NPC.config[w.id]
			if not cfg.iscollectablegoal and not cfg.isinteractable and (not cfg.noblockcollision or cfg.ishot) and w:mem(0x138,FIELD_WORD) == 0 then
				if w:mem(0x136,FIELD_BOOL) then
					w:harm(HARM_TYPE_PROJECTILE_USED)
				end
				blockutils.detonate(v, 5)
				break
			end
		end
		
		for _,w in ipairs(Player.get()) do
			if Colliders.slash(w, v) or Colliders.downSlash(w, v) then
				blockutils.detonate(v, 5)
			end
		end
	end
	
	if settings.randomjumps and not Defines.levelFreeze then
		if (data.bounce == nil or data.bounce == 0) and RNG.randomInt(300) == 0 and bounceSFX < 30 and blockutils.isOnScreen(v) then
			data.bounceheight = RNG.randomInt(2,5)
			data.bounce = data.bounceheight*2
			if bounceSounds == nil then
				bounceSounds = {}
				for i = 1,3 do
					bounceSounds[i] = Audio.SfxOpen(Misc.resolveSoundFile("nitro-bounce-"..i))
				end
			end
			if bounceSFX < 5 then
				SFX.play(RNG.irandomEntry(bounceSounds), data.bounceheight/15)
			end
			bounceSFX = bounceSFX + 20
		end
	end
	
	if data.bounce ~= nil and data.bounce > 0 and not Defines.levelFreeze then
		data.bounce = data.bounce-1
		v:mem(0x56,FIELD_WORD, -math.abs(data.bounceheight-(data.bounceheight-data.bounce)))
	end
end

function block.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data._basegame
	if(data.timer) then
		blockutils.zeroBump(v)
	end
	
	if blockutils.isOnScreen(v) then
		addVerts(v.x, v.y+v:mem(0x56,FIELD_WORD), v.x+v.width, v.y+v.height+v:mem(0x56,FIELD_WORD))
	end
end

local flashtimer = 0
function block.onDraw()	

	for i = 1,#sectionbounds do
		sectionbounds[i] = nil
	end
	
	local t = math.sin(flashtimer*0.05)
	if not Defines.levelFreeze then
		flashtimer = flashtimer + 1
	end
	Graphics.glDraw{vertexCoords=verts, vertexColors=vcol, sceneCoords=true, priority=-65, color=math.lerp(settings.flashcolor, Color.alphawhite, t*t)}
	
	for i=1,#verts do
		verts[i] = nil
	end
	
	if bounceSFX > 0 then
		bounceSFX = bounceSFX - 1
	end
end

function block.onCollideBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	blockutils.detonate(v, 5)
end

local function idfilter(v)
	return v.id == blockID and not v.isHidden and not v:mem(0x5A, FIELD_BOOL)
end
function block.onPostNPCKill(v, rsn)
	if rsn ~= 4 and rsn ~= 3 then return end
	
	for _,w in ipairs(blockutils.checkNPCCollisions(v, idfilter)) do
		block.onCollideBlock(w)
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onTickBlock")
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
    blockmanager.registerEvent(blockID, block, "onDrawBlock")
    blockmanager.registerEvent(blockID, block, "onPostExplosionBlock")
    registerEvent(block, "onPostBlockHit")
    registerEvent(block, "onPostNPCKill")
    registerEvent(block, "onDraw")
end

return block