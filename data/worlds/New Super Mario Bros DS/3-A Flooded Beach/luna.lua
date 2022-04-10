function onStart()
	secret1 = Layer.get("smallPipe")
end

function onTick()
	if player.powerup == 1 then
		secret1:show(true)
	elseif player.powerup ~= 1 then
		secret1:hide(true)
	end
end