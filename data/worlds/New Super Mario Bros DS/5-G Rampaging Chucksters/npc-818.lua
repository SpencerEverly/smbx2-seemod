local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	frames = 6,
	framestyle = 1,
	
	gfxwidth = 104,
	gfxheight = 72,
	width = 64,
	height = 48,
	
	radius = 160,
	hp = 1,
}

function npc.onInitAPI()
	npcManager.registerHarmTypes(id,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SWORD, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA}, 
	{[HARM_TYPE_JUMP]=773,
	[HARM_TYPE_FROMBELOW]=773,
	[HARM_TYPE_NPC]=773,
	[HARM_TYPE_HELD]=773,
	[HARM_TYPE_PROJECTILE_USED]=773,
	[HARM_TYPE_TAIL]=773,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	registerEvent(npc, "onNPCHarm")
end

local IDLE = 0
local CHASE = 1

function npc.onNPCHarm(e, v, r, c)
	if v.id ~= id then return end
	
	if r == HARM_TYPE_JUMP then
		local hp = v:mem(0x148, FIELD_FLOAT)
		
		if hp > 0 then
			SFX.play(2)
			v.speedX = 0
			
			e.cancelled = true
		end
		
		v:mem(0x148, FIELD_FLOAT, hp - 1)
	end
end

function npc.onTickEndNPC(v)
	local config = NPC.config[id]
	local data = v.data._basegame
	
	if not data.init then
		v:mem(0x148, FIELD_FLOAT, config.hp - 1)
		data.init = true
	end
	
	if v.ai1 == IDLE then
		data.collider = data.collider or Colliders.Circle(v.x + v.width / 2, v.y + v.height / 2, config.radius)

		data.collider.x = v.x + v.width / 2
		data.collider.y = v.y + v.height / 2
		
		for k,p in ipairs(Player.get()) do
			if Colliders.collide(data.collider, p) then
				v.ai1 = CHASE
				v.ai5 = p.idx
				data.collider = nil
				
				return
			end 
		end
		
		v.speedX = 1 * v.direction
	else
		local p = Player(v.ai5)
		
		local px = p.x + p.width / 2
		local vx = v.x + v.width / 2
		
		if px < vx then
			v.speedX = v.speedX - 0.05
		else
			v.speedX = v.speedX + 0.05
		end
		
		for k,b in Block.iterateIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height) do
			if Block.MEGA_SMASH[b.id] then
				if not b.isHidden and b:mem(0x5A, FIELD_BOOL) == false then
					if v.speedX ~= 0 then
						if b.id == 667 then
							b:hit()
							v.speedX = v.speedX * 0.85
						else
							b:remove(true)
							v.speedX = v.speedX * 0.85
						end
					end
				end
			end
		end
		
		v.speedX = math.clamp(v.speedX, -4.5, 4.5)
	end
end

return npc