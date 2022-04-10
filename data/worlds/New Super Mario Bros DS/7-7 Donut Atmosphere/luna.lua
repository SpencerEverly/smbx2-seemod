local autoscroll = require("autoscroll")

function onEvent(eventname)
	if eventname=="autoscrollStart" then
		autoscroll.scrollRight(1)
	elseif eventname=="autoscroll2" then
		autoscroll.scrollUp(0.7)
	elseif eventname=="autoscroll3" then
		autoscroll.scrollLeft(1)
	elseif eventname=="autoscroll4(Checkpoint)" then
		autoscroll.scrollUp(0.5)
	elseif eventname=="autoscroll5" then
		autoscroll.scrollRight(0.8599)
	elseif eventname=="autoscroll6" then
		autoscroll.scrollUp(0.5)
		istimerActive=true
	elseif eventname=="autoscroll7" then
		autoscroll.scrollRight(1)
	end
end

function onTick()
	if player.deathTimer > 0 then return end
	if player:mem(0x148,FIELD_WORD) > 0 and player:mem(0x14C,FIELD_WORD) > 0 then
		player:kill()
	end
end