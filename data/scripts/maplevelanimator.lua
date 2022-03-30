if not isOverworld then
	return {}
end

local levelanimator = {}

levelanimator.ids = {
	37, 38, 39, 40
}

levelanimator.framecount = {
	[37] = 6,
	[38] = 6,
	[39] = 6,
	[40] = 6
}

local currentframe = 0
local recordframe = 0

function levelanimator.register(id, frames)
	levelanimator.ids[#levelanimator.ids + 1] = id
	levelanimator.framecount[id] = frames
end

local function setFrame(id, val)
	mem(mem(0x00B2BFD8, FIELD_DWORD) + 2*(id-1), FIELD_WORD, val)
end

function levelanimator.onInitAPI()
	registerEvent(levelanimator, "onDraw")
end

function levelanimator.onDraw()
	currentframe = currentframe + 0.075
	if math.floor(currentframe) > recordframe then
		recordframe = math.floor(currentframe)
		for _, id in ipairs(levelanimator.ids) do
			setFrame(id, recordframe % levelanimator.framecount[id])
		end
		recordframe = currentframe
	end
end

return levelanimator