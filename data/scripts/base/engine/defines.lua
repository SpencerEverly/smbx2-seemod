local _getDefine = Misc._getDefine
local _definesMemSet = Misc._definesMemSet
Misc._getDefine = nil
Misc._definesMemSet = nil

local defines = {}

local function makeDefine(name, address, fieldtype, default, min, max, other)
    defines[name] = other or {}
    defines[name].minVal = min or nil
    defines[name].maxVal = max or nil
    defines[name].defValue = default
    defines[name].address = address
    defines[name].size = fieldtype
end

local function makeLunaDefine(name, fieldtype, default, min, max)
    local mGet, mSet = _getDefine(name)
    makeDefine(name, nil, fieldtype, default, min, max, {
        customFuncGet = function(self) return mGet() end,
        customFuncSet = function(self, value) return mSet(value) end
    })
end

--The maximum falling speed of the player. Note that gravity is a bit of a misnomer.
makeDefine("gravity", 0x00B2C6F4, FIELD_WORD, 12, 0, nil)
-- The earthquake factor of the Level. It resets to 0 after time.
makeDefine("earthquake", 0x00B250AC, FIELD_WORD, 0, 0, nil)
-- The speed applied to a jumping player every tick during the rising part of the jump.
makeDefine("jumpspeed", 0x00B2C6E8, FIELD_FLOAT, -5.7, nil, 0)
-- The upward force for a jumping player. Counts down each tick during the jump.
makeDefine("jumpheight", 0x00B2C6DC, FIELD_WORD, 20, 0, nil)
-- The upward force for a player when bouncing off an enemy. Counts down each tick during the jump.
makeDefine("jumpheight_bounce", 0x00B2C6E2, FIELD_WORD, 20, 0, nil)
-- The upward force for a player when bouncing off a note block. Counts down each tick during the jump.
makeDefine("jumpheight_noteblock", 0x00B2C6DE, FIELD_WORD, 25, 0, nil)
-- The upward force for a player when bouncing off a green spring. Counts down each tick during the jump.
makeDefine("jumpheight_greenspring", 0x00B2C6E4, FIELD_WORD, 55, 0, nil)
-- The upward force for a player when bouncing off another player's head. Counts down each tick during the jump.
makeDefine("jumpheight_player", 0x00B2C6E0, FIELD_WORD, 22, 0, nil)
-- The normal top running speed for a player.
makeDefine("player_runspeed", 0x00B2C6EC, FIELD_FLOAT, 6.0, 0, nil)
-- The normal top walking speed for a player.
makeDefine("player_walkspeed", 0x00B2C6F0, FIELD_FLOAT, 3.0, 0, nil)
-- The gravitational force for players.
makeDefine("player_grav", 0x00B2C6F8, FIELD_FLOAT, 0.4, 0, nil)
-- The gravitational force for NPCs.
makeDefine("npc_grav", 0x00B2C878, FIELD_FLOAT, 0.26, 0, nil)
-- The speed at which shot npcs and kicked shells move.
makeDefine("projectilespeedx", 0x00B2C860, FIELD_FLOAT, 7.1, 0, nil)
-- The effect ID of the npc-to-coins function (default is the coinflip effect)
makeLunaDefine("effect_NpcToCoin", FIELD_BYTE, 11, 0, nil)
-- If the explosion effect is enabled for the zoomer (NPC-ID: 205)
makeLunaDefine("effect_Zoomer_killEffectEnabled", FIELD_BOOL, true, nil, nil)
-- The sound ID of the npc-to-coins function (default is the coin sound).
makeLunaDefine("sound_NpcToCoin", FIELD_BYTE, 14, 0, nil)
-- The coin-value for every destroyed npc in the npc-to-coins function.
makeLunaDefine("npcToCoinValue", FIELD_BYTE, 1, 0, 99)
-- How many coins get subtracted from the coin-value when the coin value hits 100 coins.
makeLunaDefine("npcToCoinValueReset", FIELD_BYTE, 100, 1, 100)
-- The score values of smb3 roulette
makeLunaDefine("smb3RouletteScoreValueStar", FIELD_DWORD, 10, 1, 12)
makeLunaDefine("smb3RouletteScoreValueMushroom", FIELD_DWORD, 6, 1, 12)
makeLunaDefine("smb3RouletteScoreValueFlower", FIELD_DWORD, 8, 1, 12)
-- How much a coin npc is worth as coins.
makeLunaDefine("coinValue", FIELD_BYTE, 1, 0, 99)
makeLunaDefine("coin5Value", FIELD_BYTE, 5, 0, 99)
makeLunaDefine("coin20Value", FIELD_BYTE, 20, 0, 99)
-- If the level is freezed. (Only you can move!)
makeDefine("levelFreeze", 0x00B2C8B4, FIELD_BOOL, false, nil, nil)
--How far all players go downward from leaving the screen until death.
makeLunaDefine("bottomEdgeOffset", FIELD_DWORD, 64, 0, nil)
-- Cheats
makeDefine("cheat_shadowmario", 0x00B2C8AA, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_ahippinandahoppin", 0x00B2C8AC, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_sonictooslow", 0x00B2C8AE, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_illparkwhereiwant", 0x00B2C8B0, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_wingman", 0x00B2C8B2, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_captainn", 0x00B2C8B6, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_flamerthrower", 0x00B2C8B8, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_flamethrower", 0x00B2C8B8, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_moneytree", 0x00B2C8BA, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_speeddemon", 0x00B2C8BE, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_donthurtme", 0x00B2C8C0, FIELD_BOOL, nil, nil, nil)
makeDefine("cheat_stickyfingers", 0x00B2C8C2, FIELD_BOOL, nil, nil, nil)
makeDefine("player_hasCheated", 0x00B2C8C4, FIELD_BOOL, nil, nil, nil)
-- Toggle grabbing for players
makeLunaDefine("player_grabSideEnabled", FIELD_BOOL, true, nil, nil)
makeLunaDefine("player_grabTopEnabled", FIELD_BOOL, true, nil, nil)
makeLunaDefine("player_grabShellEnabled", FIELD_BOOL, true, nil, nil)

-- Toggle Link shield
makeLunaDefine("player_link_shieldEnabled", FIELD_BOOL, true, nil, nil)
-- Toggle Link turning into a fairy on a vine
makeLunaDefine("player_link_fairyVineEnabled", FIELD_BOOL, true, nil, nil)
-- Rupee stuff
makeLunaDefine("block_hit_link_rupeeID1", FIELD_WORD, 251, 0, 1000)
makeLunaDefine("block_hit_link_rupeeID2", FIELD_WORD, 252, 0, 1000)
makeLunaDefine("block_hit_link_rupeeID3", FIELD_WORD, 253, 0, 1000)
makeLunaDefine("kill_drop_link_rupeeID1", FIELD_WORD, 251, 0, 1000)
makeLunaDefine("kill_drop_link_rupeeID2", FIELD_WORD, 252, 0, 1000)
makeLunaDefine("kill_drop_link_rupeeID3", FIELD_WORD, 253, 0, 1000)
-- NPC despawn timer
makeDefine("npc_despawntimer", 0x00B2C85A, FIELD_WORD, 180, -1, nil)
-- Ticks during which a thrown NPC cannot hurt the player who threw it.
makeDefine("npc_throwfriendlytimer", 0x00B2C85C, FIELD_WORD, 30, 0, nil)
-- Speed of walker NPCs
makeDefine("npc_walkerspeed", 0x00B2C868, FIELD_FLOAT, 1.2, 0, nil)
-- Speed of mushroom NPCs
makeDefine("npc_mushroomspeed", 0x00B2C870, FIELD_FLOAT, 1.8, 0, nil)
-- P-Switch
makeDefine("pswitch_duration", 0x00B2C87C, FIELD_WORD, 777, 0, nil)
makeLunaDefine("pswitch_music", FIELD_BOOL, true, nil, nil)

makeDefine("weak_lava", nil, FIELD_BOOL, false, nil, nil, {
    customFuncGet = function(self)
        return Misc._getWeakLava()
    end,
    customFuncSet = function(self, value)
        Misc._setWeakLava(value)
    end
})

--(Re)sets a define
local function setDefine(defTable, value)
    local theValue = nil
    if(value ~= nil)then
        theValue = value
    else
        theValue = defTable.defValue
        if(theValue == nil)then
            return
        end
    end
    if(defTable.customFuncSet)then
        defTable:customFuncSet(theValue)
    else
        -- for when mem calls get locked down:
        -- try writing the value using a special function that has a whitelisted set of addresses
        local setMem = _definesMemSet(defTable.address, theValue)
        if not setMem then
            -- if the address wasn't whitelisted, attempt standard write into program memory
            mem(defTable.address, defTable.size, theValue)
        end
    end
    
end

local function getDefine(defTable)
    if(defTable.customFuncGet)then
        return defTable:customFuncGet()
    else
        return mem(defTable.address, defTable.size)    
    end
end

--The actual host code
local definesLib  = setmetatable({
    -- On Level startup reset all defines
    onInitAPI = function()
        for _,defineTable in pairs(defines) do
            setDefine(defineTable)
        end
    end

}, {
    --Neat function to modify a define
    __newindex = function (tarTable, key, value)
        --A bunch of error checking
        assert(key)
        local theDefine = defines[key]
        if not theDefine then
            error("Field \""..tostring(key).."\" does not exist!", 2)
        end
        if type(value) ~= "number" and type(value) ~= "boolean" and type(value) ~= "nil" then
            error("Value is not a number: Need number or boolean, got "..type(value).."!", 2)
        end
        if theDefine.minVal and (value ~= nil) then
            if theDefine.minVal > value then
                error("Value "..value.." is smaller than the minimum value of "..theDefine.minVal.."!", 2)
            end
        end
        if theDefine.maxVal and (value ~= nil) then
            if theDefine.maxVal < value then
                error("Value "..value.." is bigger than the maximum value of "..theDefine.maxVal.."!", 2)
            end
        end
        --Set the actual define
        setDefine(theDefine, value)
    end,

    __index = function (tarTable, key)
        assert(key)
        local theDefine = defines[key]
        if not theDefine then
            error("Field \""..tostring(key).."\" does not exist!", 2)
        end
        
        return getDefine(theDefine)
    end
})

return definesLib