local costume = {}

function costume.onInit()
	registerEvent(costume, "onDraw");
end

function costume.onDraw()
	for _,v in ipairs(Animation.get(155)) do
		v.width = 50;
		v.height = 58;
	end
end

return costume;