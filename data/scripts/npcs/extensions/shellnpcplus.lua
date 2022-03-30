local waterplus = {}
local npcManager = require("npcManager")

local tableinsert = table.insert
local shellIDs = {}

function waterplus.onInitAPI()
    registerEvent(waterplus, "onStart")
end

--catch late registrations through npc-config
function waterplus.onStart()
    --someone please make an easier way to access a list of these
    for i=1, 1000 do
        if NPC.config[i].isshell then
            tableinsert(shellIDs, i)
        end
    end
    if #shellIDs > 0 then
        registerEvent(waterplus, "onTickEnd")
    end
end

function waterplus.onTickEnd(v)
    for k,v in ipairs(NPC.get(shellIDs, Section.getActiveIndices())) do --npcmanager pls onspawn
        if Defines.levelFreeze then return end
        if v:mem(0x12A, FIELD_WORD) > 0 and v:mem(0x138, FIELD_WORD) == 0 then
            if not v.data._basegame._shellInitialized then
                v.data._basegame._shellInitialized = true
                if v.data._settings.shellStartsSpinning then
                    v.speedX = v.direction * Defines.projectilespeedx
                    v:mem(0x136, FIELD_BOOL, true)
                    SFX.play(9)
                end
            end
        else
            v.data._basegame._shellInitialized = false
        end

        --v:memdump()
    end
end

return waterplus