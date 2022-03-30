-- Bill Blaster Base
local bb = {}

local npcManager = require("npcManager") -- for NPC settings and event handlers
local billBlaster = require("npcs/ai/billBlaster")

local npcID = NPC_ID

local billBlasterBaseSettings = {
	id = npcID,
	frames = 2,
	width = 28,
	height = 32,
	isheavy = 1
}
npcManager.setNpcSettings(table.join(billBlasterBaseSettings,billBlaster.billBlasterSharedSettings))

--*********************************************************
--*
--*					Event Handlers
--*
--*********************************************************

npcManager.registerEvent(npcID, bb, "onTickNPC", "onTickBillBlasterBase")

-------------------------------------------------
-- onTick Bill Blaster Base
-------------------------------------------------
function bb.onTickBillBlasterBase(npc)
	if Defines.levelFreeze then return end
	local data = npc.data._basegame
	local settings = npc.data._settings
	if npc:mem(0x138, FIELD_WORD) > 0 then
		data.init = false
		return
	end
	if not data.init then
		billBlaster.onStartBillBlaster(npc)
	end
	
	local timer = billBlaster.timers[data.timer]
	if not timer.frame then
		billBlaster.startTimer(timer)
	end

	npc.speedX = npc.speedX * 0.96
	if math.abs(npc.speedX) < 0.1 then
		npc.speedX = 0
	end
	
	-- animation
	npc.animationTimer = 0 -- disable vanilla animation
	if settings.rotates then
		npc.animationFrame = (timer.frame + (data.frameOffset or 0)) % NPC.config[npcID].frames
	else
		npc.animationFrame = 0
	end
end

return bb
