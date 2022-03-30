local smallSwitch = {}

local npcManager = require("npcManager")
local ssw = require("npcs/ai/smallswitch")

local npcID = NPC_ID

local settings = { --What have I got in my pocket?
	id = npcID,
	blockon = 177,
	blockoff = 178,
	effect = 213,
	color="green",
	iscustomswitch = true
}
ssw.registerSwitch(settings)

return smallSwitch
