local switchcolors = {}
local blockutils = require("blocks/blockutils")

switchcolors.colors = {
    yellow = 1,
    blue = 2,
    green = 3,
    red = 4,
}

local switchColorCount = 4

local colorSwitchHandlers = {}

function switchcolors.registerColor(name)
    if switchcolors.colors[name] == nil then
        switchcolors.colors[name] = switchColorCount + 1
        switchColorCount = switchColorCount + 1
        colorSwitchHandlers[switchColorCount] = {}
    end

    local handler = function() switchcolors.onColorSwitch(switchcolors.colors[name]) end

    table.insert(colorSwitchHandlers, handler)

    return handler, switchcolors.colors[name]
end

registerEvent(switchcolors, "onColorSwitch")

function switchcolors.onColorSwitch(color)
    switchcolors.onSwitch(color)
end

function switchcolors.switch(id1, id2)
    blockutils.queueSwitch(id1, id2)
end

--palaces

switchcolors.palaceColors = {
    yellow = 1,
    blue = 2,
    green = 3,
    red = 4
}

local palaceColorCount = 4

local palaceSwitchHandlers = {}

function switchcolors.registerPalace(name)
    if switchcolors.colors[name] == nil then
        switchcolors.palaceColors[name] = palaceColorCount + 1
        palaceColorCount = palaceColorCount + 1
        palaceSwitchHandlers[switchColorCount] = {}
    end

    local handler = function() switchcolors.onPalaceSwitch(switchcolors.palaceColors[name]) end

    table.insert(palaceSwitchHandlers, handler)

    return handler, switchcolors.palaceColors[name]
end

--custom events

function switchcolors.onInitAPI()
	registerCustomEvent(switchcolors, "onSwitch")
    registerCustomEvent(switchcolors, "onPalaceSwitch")
end

return switchcolors