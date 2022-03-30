-- Written by Saturnyoshi
-- "Inspired" by and some code stolen from Spinda

local npcManager = require("npcManager")
local snifitAI = require("npcs/ai/snifit")

local snifits = {}
local npcID = NPC_ID

local settings = {
    id = npcID,
    burst = 2,
    interval = 28,
    jumps = true,
    prepare = false
}

local harmtypes = {
    [HARM_TYPE_SWORD] = 10,
    [HARM_TYPE_PROJECTILE_USED] = 220,
    [HARM_TYPE_SPINJUMP] = 10,
    [HARM_TYPE_TAIL] = 220,
    [HARM_TYPE_FROMBELOW] = 220,
    [HARM_TYPE_HELD] = 220,
    [HARM_TYPE_NPC] = 220,
    [HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmtypes), harmtypes)

snifitAI.register(settings)
return snifits