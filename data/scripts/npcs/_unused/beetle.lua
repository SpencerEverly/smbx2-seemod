local beetle = {}

function beetle.onInitAPI()
    registerEvent(beetle, "onTick", "ceilingCheck")
end

function beetle.ceilingCheck()
	playercenter = player.x + player.width/2
	beetles = NPC.get(207, -1)
	for _,v in ipairs(beetles) do
		if (v.id ~= 23 and v:mem(0x0A, FIELD_WORD) == 2) then
			v.id = 23
		end
		if(playercenter >= v.x-32 and playercenter <= v.x+32 and player.y > v.y) then
			if v.id ~= 173 then
				if v:mem(0x0E, FIELD_WORD) == 2 or v:mem(0x0C, FIELD_WORD) == 2 or v:mem(0x10, FIELD_WORD) == 2 then
				v.id = 173
				end
			end
		end
	end
	
	fallingshell = NPC.get(173,-1)
	for _,v in ipairs(fallingshell) do
	blockbeneath = Block.getIntersecting(v.x+8,v.y+8,v.x+v.width-8,v.y+v.height+128)
		if #blockbeneath > 0 and v.id ~= 172 then
		v.id = 172
		end
	end
	
	shells = NPC.get(172, -1)
	for _,v in ipairs(shells) do
	vwrapper = v
		if vwrapper.data.movement == nil then
			vwrapper.data.movement = 0
		end
		if v:mem(0x0A, FIELD_WORD) == 0 and vwrapper.data.movement == 0 then
			v:mem(0x156, FIELD_WORD, 99)
		end
		if v:mem(0x0A, FIELD_WORD) == 2 and vwrapper.data.movement == 0 and v.speedX == 0 then
			if(playercenter >= v.x) then
				v.speedX = 7
				vwrapper.data.movement = 1
				v:mem(0x156, FIELD_WORD, 0)
			elseif(playercenter <= v.x) then
				v.speedX = -7
				vwrapper.data.movement = 1
				v:mem(0x156, FIELD_WORD, 0)
			end
		end
		if v:mem(0x0A, FIELD_WORD) == 2 and vwrapper.data.movement == 0 and v.speedX == 0 then
			if(playercenter >= v.x) then
				v.speedX = 7
				vwrapper.data.movement = 1
				v:mem(0x156, FIELD_WORD, 0)
			elseif(playercenter <= v.x) then
				v.speedX = -7
				vwrapper.data.movement = 1
				v:mem(0x156, FIELD_WORD, 0)
			end
		end
	end
end

return beetle