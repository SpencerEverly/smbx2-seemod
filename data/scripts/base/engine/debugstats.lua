local stats = {}

local codefiles = {}
local libs = {}

local filemap = {}

local active = false
local ready = false

local versiontext
local titleText
local activeText
local libTitleText
local libText
local activeSize
local size

local textplus

local activeColumnHeight = 10
local columnHeight = 40

local function refresh()
	if not ready then return end
	
	versiontext = textplus.layout(textplus.parse(getSMBXVersionString()))
	
	activeText = {}
	titleText = textplus.layout(textplus.parse("<color yellow>Active Code Files</color> - "..#codefiles))
	local s = ""
	
	local i = 1
	local maxCol = 1
	for _,v in ipairs(codefiles) do
		s = s.."\n    "..v
		maxCol = math.max(i,maxCol)
		i = i+1
		if i > activeColumnHeight then
			i = 1
			activeText[#activeText+1] = textplus.layout(textplus.parse(s))
			s = "\n"
		end
	end
	activeText[#activeText+1] = textplus.layout(textplus.parse(s))
	
	libTitleText = nil
	libText = {}
	if #libs > 0 then
		
		libTitleText = textplus.layout(textplus.parse("<color yellow>Active Libraries</color> - "..#libs))
		local c = ""
		i = 1
		for _,v in ipairs(libs) do
			c = c.."\n    "..v
			i = i+1
			if i > columnHeight - maxCol - 1 then
				i = 1
				libText[#libText+1] = textplus.layout(textplus.parse(c))
				c = "\n"
			end
		end
		libText[#libText+1] = textplus.layout(textplus.parse(c))
	end
	
	activeSize = {0,0}
	
	for _,v in ipairs(activeText) do
		activeSize[1] = activeSize[1] + v.width
		activeSize[2] = math.max(activeSize[2], v.height)
	end
	activeSize[1] = math.max(activeSize[1], titleText.width)
	activeSize[2] = activeSize[2] + titleText.height
	
	size = {0, activeSize[2]}
	
	if #libText > 0 then
		size[2] = size[2] + libTitleText.height + libText[1].height + 10
		for _,v in ipairs(libText) do
			size[1] = size[1] + v.width
		end
		size[1] = math.max(math.max(size[1], activeSize[1]), libTitleText.width)
	else
		size[1] = activeSize[1]
	end
end

function stats.add(name)
	if not filemap[name] then
		table.insert(codefiles, name)
		filemap[name] = true
		refresh()
	end
end

function stats.addlib(name)
	if not filemap[name] then
		table.insert(libs, name)
		filemap[name] = true
		refresh()
	end
end

function stats.onKeyboardPress(k)
	if k == VK_F2 then
		active = not active
	end
end

function stats.onDraw()
	if active then
		Graphics.drawBox{x=0, y=0, width=size[1]+40, height=size[2]+40, color=Color.black..0.6, priority=10}
		
		textplus.render{x=4, y=4, layout=versiontext, priority=10}
		
		local x = 20
		textplus.render{x=x, y=20, layout=titleText, priority=10}
		for _,v in ipairs(activeText) do
			textplus.render{x=x, y=20+titleText.height, layout=v, priority=10}
			x = x+v.width
		end
		if #libText > 0 then
			x = 20
			textplus.render{x=x, y=30+activeSize[2], layout=libTitleText, priority=10}
			for _,v in ipairs(libText) do
				textplus.render{x=x, y=30+activeSize[2]+libTitleText.height, layout=v, priority=10}
				x = x+v.width
			end
		end
	end
end

function stats.init()
	textplus = require("textplus")
	
	registerEvent(stats, "onKeyboardPress")
	registerEvent(stats, "onDraw")
	
	ready = true
	refresh()
end

return stats