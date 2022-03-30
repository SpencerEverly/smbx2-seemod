local bigSwitch = {}

local npcManager = require("npcManager")
local palaceSwitch = require("npcs/ai/palaceswitch")

local npcID = NPC_ID

local settings = {id=npcID, color="green", blockon=728, blockoff=729, iscustomswitch = true}

palaceSwitch.registerSwitch(settings)
return bigSwitch