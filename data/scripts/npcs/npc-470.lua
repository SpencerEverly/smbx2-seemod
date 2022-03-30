-- Written by Saturnyoshi
-- "Inspired" by and some code stolen from Spinda

local npcManager = require("npcManager")
local snifitAI = require("npcs/ai/snifit")

local snifits = {}
local npcID = NPC_ID

local settings = {
    id = npcID,
    cliffturn = true
}

local harmtypes = {
    [HARM_TYPE_SWORD] = 10,
    [HARM_TYPE_PROJECTILE_USED] = 219,
    [HARM_TYPE_SPINJUMP] = 10,
    [HARM_TYPE_TAIL] = 219,
    [HARM_TYPE_FROMBELOW] = 219,
    [HARM_TYPE_HELD] = 219,
    [HARM_TYPE_NPC] = 219,
    [HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmtypes), harmtypes)

snifitAI.register(settings)
return snifits