local npcManager = require("npcManager")
local snailai = require("npcs/ai/snailicorn")

local snailicorn = {}
local npcID = NPC_ID

npcManager.setNpcSettings ({
    id = npcID,
    gfxheight = 40,
    gfxwidth = 48,
    width = 32,
    height = 32,
    frames = 3,
    framestyle = 1,
    nofireball=1,
    noiceball=1,
    noyoshi=1,
    spinjumpsafe = true,
    score = 0,
    cliffturn = true
})

npcManager.registerHarmTypes(npcID, 
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD,HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, 
	{
	    [HARM_TYPE_HELD]=267,
	    [HARM_TYPE_PROJECTILE_USED]=267,
	    [HARM_TYPE_NPC]=267,
	    [HARM_TYPE_HELD]=267,
	    [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});

function snailicorn.onInitAPI()
	npcManager.registerEvent(npcID, snailicorn, "onTickEndNPC")
	registerEvent(snailicorn, "onNPCHarm")
end

local function update(v)
	if Defines.levelFreeze then return end
	
	if not snailai.init(v, true) then return end
	
	local data = v.data._basegame
	
	local cfg = NPC.config[v.id]

    if data.state == snailai.STATE.IDLE then
	
        v.speedX = cfg.speed * 0.4 * v.direction
        data.timer = data.timer + 1
		
        if data.timer == 0 then
            v.direction = -v.direction
        end
		
        if data.timer % 32 == 0 and (not v.dontMove) and (not v.friendly) then
		
            data.visionCollider.x = v.x + 0.5 * v.width - 0.5 * data.visionCollider.width + (0.5 * v.width + 0.5 * data.visionCollider.width) * v.direction
            data.visionCollider.y = v.y
			
            for k,p in ipairs(Player.get()) do
			
                if Colliders.collide(data.visionCollider, p) then
				
                    data.timer = 0
                    data.target = p.x + 0.5 * p.width
                    data.chaseDirection = v.direction
                    data.timer = 0
                    data.state = snailai.STATE.CHASING
                    v.speedX = 0
                    v.speedY = -4
                    return
					
                end
				
            end
			
        end
		
    elseif data.state == snailai.STATE.CHASING then
	
        if v.collidesBlockBottom then
            v.speedX = 2.2 * cfg.speed * v.direction
        end

        if v.direction ~= data.chaseDirection then
            data.state = snailai.STATE.IDLE
            data.chaseDirection = nil
            return
        end
		
        if (data.chaseDirection == 1 and v.x + 0.5 * v.width > data.target)
        or (data.chaseDirection == -1 and v.x + 0.5 * v.width < data.target) then
            data.state = snailai.STATE.IDLE
            data.timer = -65
            data.chaseDirection = nil
            return
        end
		
    else
	
        if math.sign(v.speedX) ~= data.chaseDirection then
            v.speedX = -v.speedX
            v.x = v.x + 2 * v.speedX
        end
		
        v.speedX = v.speedX * 0.96
        if math.abs(v.speedX) < 0.1 then
            data.state = snailai.STATE.IDLE
            v.speedX = 0
            data.chaseDirection = nil
            return
        end
		
    end
end

function snailicorn.onTickEndNPC(v)
	update(v)
    snailai.updateAnimation(v, v.data._basegame.chaseDirection)
end

function snailicorn.onNPCHarm(eventObj, v, killReason, culprit)
	if snailai.hurt(eventObj, v, killReason, npcID) then
	
		local data = v.data._basegame

		if culprit then
			if culprit.x + 0.5 * culprit.width > v.x + 0.5 * v.width then
				data.chaseDirection = -1
			else
				data.chaseDirection = 1
			end
		else
			data.chaseDirection = -v.direction
		end

		v.speedX = -6 * data.chaseDirection
		data.state = snailai.STATE.HURT
		
	end
end

return snailicorn