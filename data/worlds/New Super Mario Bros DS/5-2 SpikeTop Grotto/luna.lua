greenTimerMS = 65*11
greentimer = false
audioplayerG = true

function onStart()
	coins1 = Layer.get("GC1")
	coins2 = Layer.get("GC2")
	coins3 = Layer.get("GC3")
	coins4 = Layer.get("GC4")
end

function onTick()
	if greentimer==true and greenTimerMS>0 then
		greenTimerMS = greenTimerMS - 1
		
		if audioplayerG == true then
			Audio.playSFX("redSwitchTimer.ogg")
			audioplayerG = false
		end
	end
	
	if greenTimerMS <= 0 then
		audioplayerG = true
		coins1:hide(false)
		coins2:hide(false)
		coins3:hide(false)
		coins4:hide(false)
		greenTimerMS = 65*11
		greentimer = false
	end
end

function onEvent(eventname)
	if eventname=="showGC1" then
		greentimer = true
	end
	
	if eventname=="showPriz" then
		greentimer = false
		greenTimerMS = 65*11
		Audio.clearSFXBuffer()
	end
end