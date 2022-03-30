-- WIP MAP MANAGER
-- v0.1

local mapmanager = {}


local levelCache
local levelPosCache = {}


SaveData._map = SaveData._map  or  {}


function mapmanager.getLevelsIntersecting(x1,y1,x2,y2,ids)
	-- Get the filtered sample of levels
	local levels
	if  ids ~= nil  then
		local levels = Level.get(ids)
	else
		local levels = Level.get()
	end

	-- Loop through the levels
	local results = {}
	for  k,v in ipairs(levels)  do
		if  v.x >= x1  and  v.x <= x2  and  v.y >= y1  and  v.y <= y2  then
			results[#results+1] = v
		end
	end

	return results
end


function mapmanager.getLevelAt(x,y)
	for  k,v in ipairs(Level.get())  do
		if  v.x == x  and  v.y == y  then
			return v;
		end
	end
end



return mapmanager;