eventtrigger = true

function onEvent(eventname) 
	if (eventname == "redSwitch_On" and eventtrigger == true) or (eventname == "Coin2Down" and eventtrigger == true) then
		Audio.playSFX("redSwitchTimer.ogg")
		eventtrigger = false
	elseif eventname == "redSwitch_Off" or eventname == "Coin2Up" then
		eventtrigger = true
	end
end