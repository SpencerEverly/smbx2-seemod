local costume = {}

function costume.onInit()
	registerEvent(costume, "onDraw");
end

function costume.onDraw()
	for _,v in ipairs(Animation.get(150)) do
		v.width = 46;
		v.height = 50;
	end
end

return costume;