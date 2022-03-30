local colliders = require("colliders")

local berries = {}

local berryIDs = {}

local berryInfo = {}

local playerInfo = {
    {yoshiCollider = nil, waiting = false},
    {yoshiCollider = nil, waiting = false},
}

function berries.register(id, rewardFunction)
    table.insert(berryIDs, id)
    
    local info = {}
    info.counter = 0
    info.rewardFunction = rewardFunction

	berryInfo[id] = info
end

function berries.onInitAPI()
	registerEvent(berries, "onNPCKill")
	registerEvent(berries, "onTickEnd")
	playerInfo[1].yoshiCollider = colliders.Box(0,0,4,4)
	playerInfo[2].yoshiCollider = colliders.Box(0,0,4,4)
end

function berries.onTickEnd()
	for k,p in ipairs(Player.get()) do
        if p:mem(0x108, FIELD_WORD) == 3 then
			if playerInfo[k] == nil then
				playerInfo[k] = {yoshiCollider = colliders.Box(0,0,4,4), waiting = false}
			end
			if playerInfo[k].waiting then
				p:mem(0x74, FIELD_WORD, 1)
				if p:isGroundTouching() then
					playerInfo[k].waiting(p)
					playerInfo[k].waiting = false
				end
			elseif p:mem(0x74, FIELD_WORD) == 0 and p:mem(0xB4, FIELD_WORD) == 0 and p:mem(0xB8, FIELD_WORD) == 0 then
                playerInfo[k].yoshiCollider.x = p.x + p:mem(0x6E, FIELD_WORD) + 14
				playerInfo[k].yoshiCollider.y = p.y + p:mem(0x70, FIELD_WORD) + 18
				for _,v in ipairs (colliders.getColliding{
					a=playerInfo[k].yoshiCollider,
					b=berryIDs,
					btype=colliders.NPC
				}) do
					if not v.friendly and not v.isHidden and not v:mem(0x64, FIELD_BOOL) then
						p:mem(0x160, FIELD_WORD, 30)
						p:mem(0x74, FIELD_WORD, 2)
						v:kill(9)
						SFX.play(55)
						SFX.play(14)
					end
				end
			end
		end
	end
end

function berries.onNPCKill(killObj, knpc, killReason)
	if berryInfo[knpc.id] and killReason == 9 and knpc:mem(0x12A, FIELD_WORD) > 0 and not knpc.friendly then
		for k,p in ipairs(Player.get()) do
			if p:mem(0x108, FIELD_WORD) == 3 and p:mem(0x160, FIELD_WORD) == 30 and p:mem(0x74, FIELD_WORD) == 2 then
                berryInfo[knpc.id].counter = (berryInfo[knpc.id].counter + 1) % NPC.config[knpc.id].limit
				if berryInfo[knpc.id].counter == 0 then
					playerInfo[k].waiting = berryInfo[knpc.id].rewardFunction
				end
				break
			end
		end
	end
end

return berries