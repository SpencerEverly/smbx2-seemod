if not isOverworld then
	return {}
end

local switchpalace = {}

local ids = {33, 34, 35, 36}

switchpalace.ids = {
	yellow = ids[1],
	blue = ids[2],
	green = ids[3],
	red = ids[4]
}

switchpalace.colors = {
	[switchpalace.ids.yellow] = "yellow",
	[switchpalace.ids.blue] = "blue",
	[switchpalace.ids.green] = "green",
	[switchpalace.ids.red] = "red"
}

switchpalace.disablePressed = true

SaveData._basegame = SaveData._basegame or {}
SaveData._basegame.bigSwitch = SaveData._basegame.bigSwitch or {}
local SwitchData = SaveData._basegame.bigSwitch
GameData._basegame = GameData._basegame or {}
GameData._basegame.bigSwitch = GameData._basegame.bigSwitch or {}
local PressData = GameData._basegame.bigSwitch

local function setFrame(id, val)
	mem(mem(0x00B2BFD8, FIELD_DWORD) + 2*(id-1), FIELD_WORD, val)
end

function switchpalace.onInitAPI()
	registerEvent(switchpalace, "onInputUpdate")
	registerEvent(switchpalace, "onTick")
end

local signalObj = "__switchpalace_routine_signal"

local function wait(seconds)
	Misc.pause()
	for i = 1, lunatime.toTicks(seconds) do
		player.keys.left = false
		player.keys.right = false
		player.keys.jump = false
		Routine.waitSignal(signalObj)
	end
	player.keys.left = false
	player.keys.right = false
	player.keys.jump = false
	Misc.unpause()
end

local function switchEffect(id)
	wait(0.5)
	SFX.play(37)
	setFrame(id, 1)
	wait(0.5)
end

local firstFrame = true
function switchpalace.onInputUpdate()
	Routine.signal(signalObj)
	if firstFrame then
		firstFrame = false
	else
		return
	end
	local queue = {}
	for _,id in ipairs(ids) do
		local color = switchpalace.colors[id]
		if SwitchData[color] and not PressData[color] then
			setFrame(id, 1)
		else
			setFrame(id, 0)
			if PressData[color] then
				table.insert(queue, id)
				PressData[color] = nil
			end
		end
	end
	for _,id in ipairs(queue) do
		Routine.run(switchEffect, id)
	end
end
	
function switchpalace.onTick()
	if not switchpalace.disablePressed then return end
	local level = world.levelObj
	if not level then return end
	local color = switchpalace.colors[level:mem(0x30, FIELD_WORD)]
	if not color then return end
	if SwitchData[color] then
		player.keys.jump = false
	end
end

return switchpalace