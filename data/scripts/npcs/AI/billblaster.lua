--- Rotating Bill Blaster
-- @module billBlaster
-- @author Sambo
-- Adds the Rotating Bill Blasters from NSMB to SMBX
-- Original graphic created by Squishy Rex
-- Animation created by Sambo

local billBlaster = {}

local npcManager = require("npcManager") -- for NPC settings and event handlers
local rng = require("rng")

--*********************************************************
--*
--*					IDs
--*
--*********************************************************

local BULLET_BILL_ID = 17
local BILL_BLASTER_ID = 438
local BILL_BLASTER_BASE_ID = 439

--*********************************************************
--*
--*					Settings
--*
--*********************************************************

billBlaster.billBlasterSharedSettings = {
	framestyle = 0,
	framespeed = 8,
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = true,
	harmlessgrab= true,
	nohurt = true,
	--nogravity = true,
	--noblockcollision = true,
	noiceball = true,
	noyoshi=true,
	
	beforefire = 96,
	afterfire = 64,
}

--*********************************************************
--*
--*					Timers
--*
--*********************************************************

billBlaster.timers = {}

-- Timer names. Used to avoid a call to pairs() every tick
billBlaster.timerNames = {}

--- Add Timer
-- Add an additional timer to billblaster. Once the new timer is added, the timer of a Bill Blaster
-- can be set to that timer by placing the following in the NPC's message field: {timer = "name"},
-- where "name" is a string containing the new timer's name.
-- @function addTimer
-- @param name The name of the timer
-- @param beforeFire The delay between when the Bill Blaster stops rotating and when it fires
-- @param afterFire The delay between when the blaster fires and when it starts rotating
function billBlaster.addTimer(name, beforeFire, afterFire)
	billBlaster.timers[name] = {beforeFire = beforeFire, afterFire = afterFire}
	-- Prevent duplicates of a timer name from being added
	for _,v in ipairs(billBlaster.timerNames) do
		if name == v then
			return
		end
	end
	table.insert(billBlaster.timerNames, name)
end

-- counter phases
--	0: waiting to fire
--	1: firing
--	2: waiting to rotate
--	3: rotating

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

-- global event handlers
--registerEvent(billBlaster, "onStart", "startTimers")
registerEvent(billBlaster, "onTickEnd", "updateTimers")

--------------------------------------------------
-- onStart Bill Blaster
--	initializes bill blasters
--------------------------------------------------
function billBlaster.onStartBillBlaster(npc)
	local data = npc.data._basegame
	local settings = npc.data._settings
	local cfg = NPC.config[npc.id]
	
	if settings.beforetimer == nil or settings.beforetimer == 0 then
		settings.beforetimer = cfg.beforefire
	end
	if settings.aftertimer == nil or settings.aftertimer == 0 then
		settings.aftertimer = cfg.afterfire
	end

	data.timer = settings.beforetimer .. "+" .. settings.aftertimer

	if billBlaster.timerNames[data.timer] == nil then
		billBlaster.addTimer(data.timer, settings.beforetimer, settings.aftertimer)
	end

	if settings.rotates == nil then
		settings.rotates = true
	end

	if npc.id == BILL_BLASTER_ID then
		if npc.direction == 0 then npc.direction = rng.irandomEntry({-1, 1}) end
		if npc.direction == DIR_LEFT then
			data.frameOffset = 0
		else
			data.frameOffset = NPC.config[BILL_BLASTER_ID].frames * .5
		end
	end
	if not settings.rotates then
		data.frame = data.frameOffset
	end
	data.init = true
end


---------------------------------------------------
-- Start Timer
--	initialize the given timer
---------------------------------------------------
function billBlaster.startTimer(timer)
	timer.phase = 0
	timer.frame = 0
	timer.clk = 0
end

---------------------------------------------------
-- Update Timers
--	updates all the timers
---------------------------------------------------
function billBlaster.updateTimers()
	for _,name in ipairs(billBlaster.timerNames) do
		local v = billBlaster.timers[name]
		if not v.phase then
			return -- There are no Bill Blasters on this timer
		end
		if v.phase == 0 then
			v.clk = (v.clk + 1) % v.beforeFire
			if v.clk == 0 then v.phase = 1 end
		elseif v.phase == 1 then
			v.phase = 2
		elseif v.phase == 2 then
			v.clk = (v.clk + 1) % v.afterFire
			if v.clk == 0 then v.phase = 3 end
		else
			local cfg = NPC.config[BILL_BLASTER_ID]
			v.clk = (v.clk + 1) % cfg.framespeed
			if v.clk == 0 then
				v.frame = (v.frame + 1) % cfg.frames
				if v.frame % (cfg.frames * .5) == 0 then
					v.phase = 0
				end
			end
		end
	end
end

return billBlaster