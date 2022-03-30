local bigSwitch = {}

local npcManager = require("npcManager")
local palaceSwitch = require("npcs/ai/palaceswitch")

local npcID = NPC_ID

local settings = {id=npcID, color="pswitch", exitlevel=false, bursts=1, save=false, synchronize = false, iscustomswitch = true}

palaceSwitch.registerSwitch(settings)
return bigSwitch