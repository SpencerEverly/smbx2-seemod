-- Powerups
for k,v in ipairs({273, 187, 186, 90, 249, 185, 184, 9, 183, 182, 14, 277, 264, 170, 287, 169, 34}) do
    NPC.config[v].powerup = true
end

-- Bindoswitch
NPC.config[32].iscustomswitch = true
NPC.config[238].iscustomswitch = true

-- Honkin Chonkers
NPC.config[21].isheavy = 1
NPC.config[37].isheavy = 2
NPC.config[58].isheavy = 1
NPC.config[67].isheavy = 4
NPC.config[68].isheavy = 8
NPC.config[69].isheavy = 4
NPC.config[70].isheavy = 8
NPC.config[71].isheavy = 1
NPC.config[72].isheavy = 1
NPC.config[73].isheavy = 1
NPC.config[78].isheavy = 4
NPC.config[79].isheavy = 2
NPC.config[80].isheavy = 4
NPC.config[81].isheavy = 4
NPC.config[82].isheavy = 4
NPC.config[83].isheavy = 8
NPC.config[84].isheavy = 2
NPC.config[164].isheavy = 1

-- Elementals
NPC.config[12].ishot = true
NPC.config[12].durability = -1
NPC.config[13].ishot = true
NPC.config[85].ishot = true
NPC.config[85].durability = 2
NPC.config[87].ishot = true
NPC.config[87].durability = -1
NPC.config[108].ishot = true
NPC.config[108].durability = 5
NPC.config[206].ishot = true
NPC.config[206].durability = -1
NPC.config[210].ishot = true
NPC.config[210].durability = 2
NPC.config[246].ishot = true
NPC.config[246].durability = 2
NPC.config[259].ishot = true
NPC.config[259].durability = -1
NPC.config[260].ishot = true
NPC.config[260].durability = -1
NPC.config[276].ishot = true
NPC.config[276].durability = 2
NPC.config[282].ishot = true
NPC.config[282].durability = -1

NPC.config[265].iscold = true

return {}