local smallSwitch = {}

local npcManager = require("npcManager")
local ssw = require("npcs/ai/smallswitch")

local npcID = NPC_ID

local settings = { --What have I got in my pocket?
	id = 451,
	blockon = 171,
	blockoff = 172,
	effect = 212,
	color="yellow",
	iscustomswitch = true
}
ssw.registerSwitch(settings)

return smallSwitch
