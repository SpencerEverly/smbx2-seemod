isBlockHit1 = false
isBlockHit2 = false
isBlockHit3 = false
isBlockHit4 = false
timer=0

greenTimerMS = 65*11
greentimer = false
audioplayerG = true


function onStart()
	S1_1 = Layer.get("Spike1_1")
	S1_2 = Layer.get("Spike1_2")
	S1_3 = Layer.get("Spike1_3")
	S1_4 = Layer.get("Spike1_4")
	
	S2_1 = Layer.get("Spike2_1")
	S2_2 = Layer.get("Spike2_2")
	S2_3 = Layer.get("Spike2_3")
	S2_4 = Layer.get("Spike2_4")
	
	S3_1 = Layer.get("Spike3_1")
	S3_2 = Layer.get("Spike3_2")
	S3_3 = Layer.get("Spike3_3")
	S3_4 = Layer.get("Spike3_4")
	
	S4_1 = Layer.get("Spike4_1")
	S4_2 = Layer.get("Spike4_2")
	S4_3 = Layer.get("Spike4_3")
	S4_4 = Layer.get("Spike4_4")
	
	coins1 = Layer.get("GC1")
	coins2 = Layer.get("GC2")
	coins3 = Layer.get("GC3")
	coins4 = Layer.get("GC4")
end

function onTick()
	timer=timer+1
	--130,143,273,286
	if timer>286 then
		timer=0
	end
	
	if isBlockHit1==false then
		if timer==0 then
			S1_1:show(true)
			S1_4:hide(true)
		elseif timer==130 then
			S1_2:show(true)
			S1_1:hide(true)
		elseif timer==143 then
			S1_3:show(true)
			S1_2:hide(true)
		elseif timer==273 then
			S1_4:show(true)
			S1_3:hide(true)
		end
	end
	
	if isBlockHit2==false then
		if timer==1 then
			S2_1:show(true)
			S2_4:hide(true)
		elseif timer==131 then
			S2_2:show(true)
			S2_1:hide(true)
		elseif timer==144 then
			S2_3:show(true)
			S2_2:hide(true)
		elseif timer==274 then
			S2_4:show(true)
			S2_3:hide(true)
		end
	end
	
	if isBlockHit3==false then
		if timer==286 then
			S3_1:show(true)
			S3_4:hide(true)
		elseif timer==129 then
			S3_2:show(true)
			S3_1:hide(true)
		elseif timer==142 then
			S3_3:show(true)
			S3_2:hide(true)
		elseif timer==272 then
			S3_4:show(true)
			S3_3:hide(true)
		end
	end
	
	if isBlockHit4==false then
		if timer==0 then
			S4_3:show(true)
			S4_2:hide(true)
		elseif timer==130 then
			S4_4:show(true)
			S4_3:hide(true)
		elseif timer==143 then
			S4_1:show(true)
			S4_4:hide(true)
		elseif timer==273 then
			S4_2:show(true)
			S4_1:hide(true)
		end
	end
	
	
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
	if eventname=="CancelBlock1" then
		isBlockHit1=true
		S1_1:hide(true)
		S1_2:hide(true)
		S1_3:hide(true)
		S1_4:hide(true)
	end
	
	if eventname=="CancelBlock2" then
		isBlockHit2=true
		S2_1:hide(true)
		S2_2:hide(true)
		S2_3:hide(true)
		S2_4:hide(true)
	end
	
	if eventname=="CancelBlock3" then
		isBlockHit3=true
		S3_1:hide(true)
		S3_2:hide(true)
		S3_3:hide(true)
		S3_4:hide(true)
	end
	
	if eventname=="CancelBlock4" then
		isBlockHit4=true
		S4_1:hide(true)
		S4_2:hide(true)
		S4_3:hide(true)
		S4_4:hide(true)
	end
	
	if eventname=="Gc1" then
		greentimer = true
	end
	
	if eventname=="ShowSpring" then
		greentimer = false
		greenTimerMS = 65*11
		Audio.clearSFXBuffer()
	end
end