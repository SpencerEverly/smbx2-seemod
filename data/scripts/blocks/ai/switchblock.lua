local suits = {}

local switchcolors = require("switchcolors")

local switchesMap = {}

suits.KINDS = {"SWITCH", "PALACE"}

function suits.register(id, kind)
	switchesMap[id] = kind
end

function suits.onInitAPI()
	registerEvent(suits, "onPostBlockHit")
end

--[[
local function memArray(address, idx)
	return mem(address,FIELD_DWORD)+(2*(idx-1))
end
]]

function suits.onPostBlockHit(v, fromUpper, playerOrNil)
	if not switchesMap[v.id] then return end
	SFX.play(32)

	switchcolors.switch(Block.config[v.id].onswitchid, Block.config[v.id].offswitchid)
	local color = Block.config[v.id].color
	if switchesMap[v.id] == "PALACE" then
		local _
		local col = switchcolors.palaceColors[color]
		if col == nil then
			_, col = switchcolors.registerPalace(color)
		end
		switchcolors.onPalaceSwitch(col)
	elseif switchesMap[v.id] == "SWITCH" then
		local _
		local col = switchcolors.colors[color]
		if col == nil then
			_, col = switchcolors.registerColor(color)
		end
		switchcolors.onSwitch(col)
	end
end
--[[
function suits.onTick()	
	--Animation code
	--TODO: port this to block manager when it exists
	for _,v in ipairs(switches) do
		local timerLoc = memArray(0x00B2BEBC, v)
		local frameLoc = memArray(0x00B2BEA0, v)
		
		local timer = mem(timerLoc,FIELD_WORD)-1
		mem(timerLoc,FIELD_WORD,timer)
		if (timer <= 0) then
			local frame = mem(frameLoc,FIELD_WORD) + 1
			if(frame >= 4) then
				frame = 0;
			end
			mem(frameLoc,FIELD_WORD,frame)
			mem(timerLoc,FIELD_WORD,8)
		end
	end
end]]

return suits