function onEvent(eventname)
	if eventname == "WaterUp1" then
		Audio.clearSFXBuffer()
		Audio.playSFX("redSwitchTimer.ogg")
	elseif eventname == "WaterUp2" then
		Audio.clearSFXBuffer()
		Audio.playSFX("redSwitchTimer.ogg")
	end
end