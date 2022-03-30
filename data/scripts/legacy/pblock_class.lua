local Block = {}

local pblock = require("pblock")
local Base = _G.Block

setmetatable(Block, {
	__call = function(self, idx)
		return pblock.wrap(Base(idx))
	end
})

Block.count = Base.count
Block.bumpable = Base.bumpable

function Block.spawn(a, b, c)
	return pblock.wrap(Base.spawn(a, b, c))
end

local function makeListWrapper(func)
	return function(a, b, c, d)
		local t = {}
		for _,v in ipairs(func(a, b, c, d)) do
			t[#t + 1] = pblock.wrap(v)
		end
		return t
	end
end

local function makeIterWrapper(func)
	return function(a, b, c, d)
		local t = {}
		for _,v in func(a, b, c, d) do
			t[#t + 1] = pblock.wrap(v)
		end
		return ipairs(t)
	end
end

Block.get = makeListWrapper(Base.get)
Block.getIntersecting = makeListWrapper(Base.getIntersecting)
Block.getByFilterMap = makeListWrapper(Base.getByFilterMap)

Block.iterate = makeIterWrapper(Base.iterate)
Block.iterateIntersecting = makeIterWrapper(Base.iterateIntersecting)
Block.iterateByFilterMap = makeIterWrapper(Base.getByFilterMap)

_G.Block = Block
return Block