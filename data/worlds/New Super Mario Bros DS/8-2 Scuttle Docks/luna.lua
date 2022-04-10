function onStart()
	block1 = Layer.get("block1")
	block2 = Layer.get("block2")
	block3 = Layer.get("block3")
	block4 = Layer.get("block4")
	
	secret1 = Layer.get("smallPipe")
	timer = resetTimer()
	timerTrigger = false
end

function onEvent(eventname)
	if eventname == "test" then
		timerTrigger = true
		if block1.isHidden then
			timer = resetTimer()
			block1:show(false)
		elseif block2.isHidden then
			timer = resetTimer()
			block2:show(false)
		elseif block3.isHidden then
			timer = resetTimer()
			block3:show(false)
		elseif block4.isHidden then
			timer = resetTimer()
			block4:show(false)
		else
			timer = resetTimer()
		end
	end
	
	if eventname=="WaterUp" or eventname=="Water2Up" or eventname=="Water3Up" or eventname=="Water4Up" then
		Audio.playSFX("redSwitchTimer.ogg")
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
		end
	end
end

function resetTimer()
	return 325
end