local blockmanager = require("blockmanager")

local table_insert = table.insert

local blockID = BLOCK_ID

local onef0 = {}

--disable vanilla collision
blockmanager.setBlockSettings({
    id = blockID,
    passthrough = true,
	ediblebyvine = true, -- edible by mutant vine
})

local speedYChangeList = {}

function onef0.onInitAPI()
    blockmanager.registerEvent(blockID, onef0, "onStartBlock")
    blockmanager.registerEvent(blockID, onef0, "onTickEndBlock")
    registerEvent(onef0, "onTickEnd")
end

local activeSections = {}

local getsections = Section.getActiveIndices
function onef0.onTickEnd()
	local i = 1
	for k,v in ipairs(getsections()) do
		activeSections[i] = Section(v)
		i = i + 1
	end
	for k,v in ipairs(speedYChangeList) do
		if v and v.isValid and (not v.collidesBlockBottom) and v:mem(0x12C, FIELD_WORD) == 0 and v.data._basegame.newblocks then
			v.y = v.data._basegame.newblocks.y
			if v.id == v.data._basegame.newblocks.id then
				if v.speedX ~= 0 and (math.sign(v.speedX) ~= v.direction) then
					v.direction = math.sign(v.speedX)
				end
				local speed = math.abs(v.data._basegame.newblocks.speedX)
				local oldSpeed = math.abs(v.speedX)
				if oldSpeed > speed then
					v.speedX = oldSpeed * v.direction
				else
					v.speedX = speed * v.direction
				end
			end
			v.speedY = v.data._basegame.newblocks.speedY
		end
	end
	speedYChangeList = {}
end

function onef0.onStartBlock(v)
	v.data._basegame.collider = Colliders.Box(v.x,v.y - 1,v.width,1)
end

function onef0.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data._basegame
	
	if data.collider == nil then
		data.collider = Colliders.Box(v.x,v.y - 1,v.width,1)
	end
	
	local l = v.layerObj
	if l and (not l:isPaused()) and (l.speedX ~= 0 or l.speedY ~= 0) then
		data.collider.x = data.collider.x + l.speedX;
		data.collider.y = data.collider.y + l.speedY;
	end
	local x, y = v.x, v.y
	for _,s in ipairs(activeSections) do
		local b = s.boundary
		if x + v.width >= b.left and y + v.height >= b.top and x <= b.right and y <= b.bottom then
			for k,q in ipairs(Colliders.getColliding{
				a=data.collider,
				b=allNPCs,
				btype=Colliders.NPC,
				filter=function(other)
					return (not other.isHidden) and not (NPC.config[other.id].nogliding) and other:mem(0x12A, FIELD_WORD) > 0 and not other.isGenerator and--[[other:mem(0x12C, FIELD_WORD) == 0 and]] other:mem(0x138, FIELD_WORD) == 0 and other.y + other.height <= y + 8 and other.speedY > 0
				end
			}) do
				q.data._basegame = q.data._basegame or {}
				q.data._basegame.newblocks = q.data._basegame.newblocks or {}
				q.data._basegame.newblocks.speedX = q.speedX
				q.data._basegame.newblocks.speedY = q.speedY
				q.data._basegame.newblocks.y = v.y - q.height
				q.data._basegame.newblocks.id = q.id
				q.speedY = v.y - q.y - q.height - Defines.npc_grav - 0.0000000001 --correctly landing on ledges after gliding...
				if q.data._basegame.lineguide and q.data._basegame.lineguide.attachedNPCs then
					for k,n in ipairs(q.data._basegame.lineguide.attachedNPCs) do
						n.speedY = 0
					end
				end
				table_insert(speedYChangeList, q)
			end
			break
		end
	end
end

return onef0