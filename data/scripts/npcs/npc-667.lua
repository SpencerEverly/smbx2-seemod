local prs = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

local rinkaConfig = npcManager.setNpcSettings {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 28,
	width = 28,
	height = 32,
	frames = 6,
	framestyle = 0,
	ignorethrownnpcs = true,
	jumphurt = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nogravity = true,
	nohurt = true,
	noblockcollision = true,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.cyan,
	ishot = true,
	durability = 2
}

npcManager.registerHarmTypes(npcID, {
	HARM_TYPE_PROJECTILE_USED
}, {
	[HARM_TYPE_PROJECTILE_USED] = 254
})

npcManager.registerEvent(npcID, prs, "onTickNPC", "tickRinka")

--Player Rinka

local function initRinka(v)
	local data = v.data._basegame
	data.triggered = false
	data.thrownBy = nil
end

function prs.tickRinka(v)
	
	local data = v.data._basegame
	if data.triggered == nil then
		initRinka(v)
	end
	
	--local npcList = NPC.get(NPC.HITTABLE, v:mem(0x146, FIELD_WORD)) --Gallery of shame.
	
	if not data.triggered then
		local closestDistance
		local closestNpc
		local x, y = v.x + 0.5 * v.width, v.y + 0.5 * v.height
		for _, secondNPC in NPC.iterateIntersecting(x - 400, y - 400, x + 400, y + 400) do
			local cx, cy = secondNPC.x+secondNPC.width/2, secondNPC.y+secondNPC.height/2
			if (secondNPC ~= v
			and not secondNPC:mem(0x128, FIELD_BOOL))
			and not (secondNPC:mem(0x12C, FIELD_WORD) > 0)
			and (not secondNPC.friendly)
			and (not secondNPC.isHidden)
			and (secondNPC:mem(0x124, FIELD_BOOL))
			and ((cx - x)*v.direction >= 0)
			and (v:mem(0x12C, FIELD_WORD) ~= data.thrownBy) then
				local distance = vector(cx - x, cy - y).sqrlength
				if closestDistance == nil or closestDistance > distance then
					closestDistance = distance
					closestNpc = secondNPC
				end
			end
		end
		
		local speedVect
		if closestNpc then
			speedVect = vector.v2(closestNpc.x + 0.5 * closestNpc.width - v.x - 0.5 * v.width, closestNpc.y + 0.5 * closestNpc.height - v.y - 0.5 * v.height):normalize()
		else
			speedVect = vector.randomDir2()
			speedVect.x = math.abs(speedVect.x)*v.direction
		end
		v.speedX = speedVect.x * 4
		v.speedY = speedVect.y * 4 * NPC.config[v.id].speed
		data.triggered = true
	end
	
	for k,secondNPC in ipairs(Colliders.getColliding{
		a=v,
		b=NPC.HITTABLE, -- Yikes.
		btype=Colliders.NPC
	}) do
		if (not secondNPC:mem(0x128, FIELD_BOOL)) and (not secondNPC.friendly) and (not secondNPC.isHidden) and (secondNPC:mem(0x124, FIELD_BOOL)) and (secondNPC:mem(0x12C, FIELD_WORD) ~= data.thrownBy) then
			secondNPC:harm(HARM_TYPE_NPC)
			v:kill(HARM_TYPE_PROJECTILE_USED)
			break
		end
	end
end

return prs
