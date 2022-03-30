local smallSwitch = {}

local npcManager = require("npcManager")
local ssw = require("npcs/ai/smallswitch")

local npcID = NPC_ID

local settings = { --What have I got in my pocket?
	id = npcID,
	blockon = 180,
	blockoff = 181,
	effect = 214,
	color="red",
	iscustomswitch = true
}
ssw.registerSwitch(settings)

return smallSwitch
