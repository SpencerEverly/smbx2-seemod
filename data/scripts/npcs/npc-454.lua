local smallSwitch = {}

local npcManager = require("npcManager")
local ssw = require("npcs/ai/smallswitch")

local npcID = NPC_ID

local settings = { --What have I got in my pocket?
	id = npcID,
	blockon = 174,
	blockoff = 175,
	effect = 215,
	color="blue",
	iscustomswitch = true
}
ssw.registerSwitch(settings)

return smallSwitch
