local pipecannon = API.load("pipecannon")
local autoscroll = require("autoscroll")
local camera = Camera.get()[1]

pipecannon.exitspeed = {23,0,19,15,15}
pipecannon.angle = {[3]=45,[4]=-25,[5]=18}

function onEvent(eventname)
	if eventname=="AutoscrollRight" then
		autoscroll.scrollRight(1)
	end
end

function onTick()
	if player.deathTimer > 0 then return end
	if player:mem(0x148,FIELD_WORD) > 0 and player:mem(0x14C,FIELD_WORD) > 0 then
		player:kill()
	end
end