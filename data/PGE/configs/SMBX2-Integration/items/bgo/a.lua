local f2 = io.open("background-CUSTOM.ini")
local t = {}
for line in f2:lines() do
	t[#t + 1] = line
end
for i = 751, 1000 do
	local f = io.open("background-"..i..".ini", "w")
	for _,line in ipairs(t) do
		f:write(line .. "\n")
	end
	f:close()
end
f2:close()