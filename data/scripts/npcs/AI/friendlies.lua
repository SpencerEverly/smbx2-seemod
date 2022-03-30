local npcManager = require("npcManager")

local friendlies = {}

friendlies.ids = {}

function friendlies.register(id)
    npcManager.registerEvent(id, friendlies, "onTickEndNPC")
    friendlies.ids[id] = true
end

function friendlies.onTickEndNPC(v)
	if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	if v.collidesBlockBottom then
		v.speedX = 0
	end
end

return friendlies