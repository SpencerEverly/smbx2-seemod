local autoscroll = require("autoscroll")

function onEvent(eventname)
if eventname == "autoscroller" then
	autoscroll.scrollRight(1)
end
end

function onTick()
	if player.deathTimer > 0 then return end
	if player:mem(0x148,FIELD_WORD) > 0 and player:mem(0x14C,FIELD_WORD) > 0 then
		player:kill()
	end
end