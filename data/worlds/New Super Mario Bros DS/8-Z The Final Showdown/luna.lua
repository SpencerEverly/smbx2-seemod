isUpsidedown = false --Checks to see which side the Castle is facing
burnerTimer = 0 --Timer used by both Burners.
checkHideBurners = false --Both checks are to prevent hiding layers every tick
checkHidePlatforms = false
isPlatformActive = false --Checks to see if the player has pushed the block to show the platform

function onStart()
	B1 = Layer.get("Burner_Start") --First Burners
	B2 = Layer.get("Burner_Initial")
	B3 = Layer.get("Burner_Flame")
	
	B4 = Layer.get("Burner2_Start") --Second Burners
	B5 = Layer.get("Burner2_Initial")
	B6 = Layer.get("Burner2_Flame")
	
	P1 = Layer.get("Platform1") --Platforms
	P2 = Layer.get("Platform2")
end

function onEvent(eventname)
	if eventname=="FlipToDefault" then --Flips castle Right Side Up (Same side as when you start the level)
		isUpsidedown = false
		hideEverything()
	elseif eventname=="FlipToBlue" then --Flips the Castle Upside Down
		isUpsidedown = true
		hideEverything()
	end
	
	if eventname=="ActivatePlatforms" then --When the player hits the Event block
		isPlatformActive = true
	end
end

function onTick()
	burnerTimer = burnerTimer+1
	if player.section == 2 then
		checkHideBurners = false 
		if isUpsidedown==false then --Right Side Up Settings
			if checkHidePlatforms==false and isPlatformActive==true then --Does this if Player has activated Platforms. Only does this once to prevent lag
				P1:show(false)
				checkHidePlatforms=true
			end
			if burnerTimer == 1 then --Goes from Start to Initial to Flame to Initial then Hides all
				B1:show(true)
			elseif burnerTimer == 65 then
				B2:show(false)
				B1:hide(true)
				Audio.playSFX(42)
			elseif burnerTimer == 73 then
				B3:show(false)
				B2:hide(true)
			elseif burnerTimer == 138 then
				B2:show(false)
				B3:hide(true)
			elseif burnerTimer == 146 then
				B2:hide(true)
			elseif burnerTimer > 312 then
				burnerTimer = 0
			end
		elseif isUpsidedown==true then --Upside Down Settings
			if checkHidePlatforms==false and isPlatformActive==true then --Does this if Player has activated Platforms. Only does this once to prevent lag
				P2:show(false)
				checkHidePlatforms=true
			end
			if burnerTimer == 1 then --Goes from Start to Initial to Flame to Initial then Hides all
				B4:show(true)
			elseif burnerTimer == 65 then
				B5:show(false)
				B4:hide(true)
				Audio.playSFX(42)
			elseif burnerTimer == 73 then
				B6:show(false)
				B5:hide(true)
			elseif burnerTimer == 138 then
				B5:show(false)
				B6:hide(true)
			elseif burnerTimer == 146 then
				B5:hide(true)
			elseif burnerTimer > 312 then
				burnerTimer = 0
			end
		end
	else
		if checkHideBurners == false then --Prevents Lag
			hideEverything()
			checkHideBurners = true
		end
		if checkHidePlatforms == true then --Prevents Lag
			checkHidePlatforms = false
		end
	end
end

function hideEverything() --Hides these layers whenever the player is not in Section 2 (Area with Burners)
	B1:hide(false)
	B2:hide(false)
	B3:hide(false)
	B4:hide(false)
	B5:hide(false)
	B6:hide(false)
	
	P1:hide(false)
	P2:hide(false)
end