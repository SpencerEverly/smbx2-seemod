local autoscroll = require("autoscroll")
local camera = Camera.get()[1]

function onEvent(eventname)
	if eventname=="autoscrollStart" then
		autoscroll.scrollRight(1)
	end
end

function onLoadSection1()
	camera.x = player.x
	camera.y = player.y
end

function onTick()
	if player.deathTimer > 0 then return end
	if player:mem(0x148,FIELD_WORD) > 0 and player:mem(0x14C,FIELD_WORD) > 0 then
		player:kill()
	end
end