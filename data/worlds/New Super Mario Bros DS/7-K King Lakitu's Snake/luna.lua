burnersActivated=false
SFXplayable=false

function onEvent(eventname)
	if eventname=="ActivateBurners" then --Once the first burner is visible, this event plays.
		triggerEvent("Burner_Warning")
		triggerEvent("BurnerAlt_Empty")
		burnersActivated=true
	end
	
	if eventname=="DeactivateBurners" then --This does not actually deactivate burners, it only mutes the sound so that it appears that the burners are deactivated. This only happens once you enter the final doors.
		burnersActivated=false
	end
	
	if eventname=="Burner_TransitionToFull" or eventname=="BurnerAlt_TransitionToFull" then --Plays audio when fire is visible
		SFXplayable=true
	else
		SFXplayable=false
	end
end

function onTick()
	for k,v in pairs (NPC.get(284)) do
 
		if v:mem(0x12A, FIELD_WORD) == 1 then
	
			v:mem(0x12A, FIELD_WORD, 180)
		
		end
	end

	if burnersActivated==true then --Makes sure to play audio appropriatly.
		if SFXplayable==true then
			Audio.playSFX(42)
			SFXplayable=false
		end
	end
end