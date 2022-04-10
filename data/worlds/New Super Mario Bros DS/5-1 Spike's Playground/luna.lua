function onStart()
	block1 = Layer.get("block1")
	block2 = Layer.get("block2")
	block3 = Layer.get("block3")
	block4 = Layer.get("block4")
	
	snowBase = Layer.get("TopBase")
	snowLev1 = Layer.get("Top1")
	snowLev2 = Layer.get("Top2")
	snowLev3 = Layer.get("Top3")
	snowLevFinal = Layer.get("Top4")
	
	groundBase = Layer.get("GroundBase")
	groundLev1 = Layer.get("Ground1")
	groundLev2 = Layer.get("Ground2")
	groundLev3 = Layer.get("Ground3")
	
	timer = resetTimer()
	timerTrigger = false
end

function onEvent(eventname)
	if eventname == "test" then
		timerTrigger = true
		if block1.isHidden then
			timer = resetTimer()
			block1:show(false)
			snowBase:hide(false)
			snowLev1:show(false)
			groundBase:show(false)
		elseif block2.isHidden then
			timer = resetTimer()
			block2:show(false)
			snowLev1:hide(false)
			groundLev1:show(false)
			snowLev2:show(false)
		elseif block3.isHidden then
			timer = resetTimer()
			block3:show(false)
			snowLev2:hide(false)
			groundLev2:show(false)
			snowLev3:show(false)
		elseif block4.isHidden then
			timer = resetTimer()
			block4:show(false)
			snowLev3:hide(false)
			groundLev3:show(false)
			snowLevFinal:show(false)
		else
			timer = resetTimer()
		end
	end
end

function onTick()
	if timerTrigger == true then
		timer=timer-1
		if timer <= 0 then
			timerTrigger = false
			timer = resetTimer()
			block1:hide(false)
			block2:hide(false)
			block3:hide(false)
			block4:hide(false)
			
			snowBase:show(false)
			snowLev1:hide(false)
			snowLev2:hide(false)
			snowLev3:hide(false)
			snowLevFinal:hide(false)
			groundBase:hide(false)
			groundLev1:hide(false)
			groundLev2:hide(false)
			groundLev3:hide(false)
		end
	end
end

function resetTimer()
	return 325
end