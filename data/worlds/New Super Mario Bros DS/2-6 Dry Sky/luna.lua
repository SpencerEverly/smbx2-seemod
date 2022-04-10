local autoscroll = require("autoscroll")

function onEvent(eventname)
	if eventname=="MovePlatform" then
		autoscroll.scrollRight(1.5)
	end
	if eventname=="trigger" then
		autoscroll.scrollRight(1.25)
	end
	if eventname=="trigger2" then
		autoscroll.scrollRight(0.9)
	end
end

function onTick()
	if player.deathTimer > 0 then return end
	if player:mem(0x148,FIELD_WORD) > 0 and player:mem(0x14C,FIELD_WORD) > 0 then
		player:kill()
	end
end

--5600