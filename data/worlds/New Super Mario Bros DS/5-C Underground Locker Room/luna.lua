currentBlock = 0
timer = 0
isBlockAddingActive = false

function onTick()
	if isBlockAddingActive == true then
		timer = timer + 1
		while currentBlock < 52 and timer == 25 do
			timer = 0
			currentBlock=currentBlock+1
			eventBlock = Layer.get("Block" .. tostring(currentBlock))
			eventBlock:show(false)
			Audio.playSFX(4)
		end
	end
end
	
function onEvent(eventname)
	if eventname == "StartAdding" then
		isBlockAddingActive = true
		Audio.playSFX(32)
	end
end