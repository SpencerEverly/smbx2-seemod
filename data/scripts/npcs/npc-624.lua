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
    framespeed = 6,
    nofireball=1,
    noiceball=1,
    noyoshi=1,
    spinjumpsafe = true,
    speed = 1,
    score = 0,
    cliffturn = true
})

npcManager.registerHarmTypes(npcID, 
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD,HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, 
	{
	    [HARM_TYPE_HELD]=268,
	    [HARM_TYPE_PROJECTILE_USED]=268,
	    [HARM_TYPE_NPC]=268,
	    [HARM_TYPE_HELD]=268,
	    [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});

function snailicorn.onInitAPI()
	npcManager.registerEvent(npcID, snailicorn, "onTickEndNPC")
    registerEvent(snailicorn, "onNPCHarm")
end

local function update(v)
	if Defines.levelFreeze then return end
	
	if not snailai.init(v) then return end
	
	local data = v.data._basegame
	
	if data.state == snailai.STATE.IDLE then
        data.timer = data.timer - 1
        if (not data.bounced) and (v.collidesBlockRight or v.collidesBlockLeft) then
            data.bounced = v.direction
            data.timer = 2
        elseif data.timer <= 0 then
            data.bounced = false
        end
        v.speedX = (data.bounced or v.direction) * 4
        if data.bounced then v.speedX = 0.4 * v.speedX end
    else
        v.speedX = v.direction * 0.2 * 4
        if v.collidesBlockBottom and v.speedY == 0 then
            data.state = snailai.STATE.IDLE
            data.bounced = false
            return
        end
    end
end

function snailicorn.onTickEndNPC(v)
	update(v)
	snailai.updateAnimation(v, v.data._basegame.bounced)
end

function snailicorn.onNPCHarm(eventObj, v, killReason, culprit)
    if snailai.hurt(eventObj, v, killReason, npcID) then
		local data = v.data._basegame
		
		if data.bounced then
			v.direction = data.bounced
		end
		
		v.direction = -v.direction
		v.speedY = -3
		data.state = snailai.STATE.HURT
		data.bounced = false
		
	end
end

return snailicorn