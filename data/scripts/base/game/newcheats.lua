local newcheats = {};

local defs = require("expandedDefines");
local rng = require("rng");
local playerManager = require("playerManager");
local colliders = require("colliders")
local repl = require("game/repl")

if(GameData.__activatedCheats == nil) then
    GameData.__activatedCheats = {};
end

newcheats.cheatsList = {};

local groupList = {};

local cheatBuffer_raw = Misc.cheatBuffer;
local cheatbuffer;

function Misc.cheatBuffer(val)
    if(val == nil) then
        return cheatbuffer or "";
    else
        cheatbuffer = val;
    end
end

--Set to false to disable activating cheats via the cheat buffer
newcheats.enabled = true;

function newcheats.onInitAPI()
    registerEvent(newcheats, "onInputUpdate", "onInputUpdate", true);
    registerEvent(newcheats, "onStart", "onStart", true);
    registerEvent(newcheats, "onKeyboardPress", "onKeyboardPress", true);
    registerEvent(newcheats, "onDraw", "onDraw", true);
end

function newcheats.onStart()
    local hascheated = Defines.player_hasCheated;
    for k,_ in pairs(GameData.__activatedCheats) do
        newcheats.trigger(k, true);
    end
    Defines.player_hasCheated = hascheated;
end

local function updateGroups()
    for _,k in ipairs(groupList) do
        local v = newcheats.cheatsList[k];
        
        if(v.cheats ~= nil) then
            local c = 0;
            for _,w in ipairs(v.cheats) do
                local x = newcheats.cheatsList[w];
                if(type(x) == "string") then
                    x = newcheats.cheatsList[x];
                end
                if(x.active) then
                    c = c+1;
                end
            end
            if(c == 0) then
                v.active = false;
            elseif(c == #v.cheats) then
                v.active = true;
            end
            if(v.active) then
                GameData.__activatedCheats[v.id] = true;
            else
                GameData.__activatedCheats[v.id] = nil;
            end
        end
    end
end

function newcheats.onInputUpdate()
    if(cheatbuffer == nil) then
        cheatbuffer = "";
        cheatBuffer_raw("");
    end
    
    local cheatBuffer = Misc.cheatBuffer();
    if newcheats.enabled and #cheatBuffer > 0 then
        for k,v in pairs(newcheats.cheatsList) do
            if string.find(cheatBuffer, k) then
                Misc.cheatBuffer("")
                newcheats.trigger(v)
                break;
            end
        end
    end
end

function newcheats.onKeyboardPress()
    if(#cheatBuffer_raw() > 1) then
        cheatbuffer = (cheatbuffer or "")..cheatBuffer_raw():sub(2);
        cheatBuffer_raw("");
    end
end

function newcheats.onDraw()
    if Misc.isPaused() then
        cheatBuffer_raw("");
    end
end

function newcheats.get(name)
    if(newcheats.cheatsList[name]) then
        if(type(newcheats.cheatsList[name]) == "string") then
            return newcheats.get(newcheats.cheatsList[name]);
        else
            return newcheats.cheatsList[name];
        end
    elseif(type(name) == "number") then
        for _,v in pairs(newcheats.cheatsList) do
            if(v.id == name) then
                return v;
            end
        end
        return nil;
    else
        return nil;
    end
end

function newcheats.reset()
    for _,v in pairs(newcheats.cheatsList) do
        if(v.active) then
            newcheats.trigger(v);
        end
    end
end

--Trigger a cheat
function newcheats.trigger(cheat, silent)
    if(type(cheat) == "string") then
        if(newcheats.cheatsList[cheat]) then
            return newcheats.trigger(newcheats.cheatsList[cheat], silent);
        else
            return;
        end
    elseif(type(cheat) == "number") then
        return newcheats.trigger(newcheats.get(cheat), silent);
    else
        if(cheat.exclusions) then
            for _,v in ipairs(cheat.exclusions) do --exclusions are a list of cheats that are mutually exclusive to this one
                if(newcheats.cheatsList[v] and newcheats.cheatsList[v].active) then
                    newcheats.trigger(v, silent); --deactivate exclusive cheats
                end
            end
        end
        
        if(cheat.flashPlayer) then
            player:mem(0x140, FIELD_WORD, 30)
        end
        
        cheat.active = not cheat.active;
        if(cheat.isCheat and cheat.active) then
            Defines.player_hasCheated = true;
        end
        
        --onActivate is run when the cheat is typed once.
        --onDeactivate is run when the cheat is typed again, while the cheat is active.
        
        if(cheat.active) then
            if(cheat.onActivate and cheat.onActivate()) then
                cheat.active = false; --activation function should return true if the cheat finishes after running the initial function - i.e. it has no lasting effects. Cheats that are not toggleable should do this.
            end
            if(cheat.onToggle and cheat.onToggle(true)) then
                cheat.active = false; --activation function should return true if the cheat finishes after running the initial function - i.e. it has no lasting effects. Cheats that are not toggleable should do this.
            end
            if(cheat.activateSFX and not silent) then
                Audio.playSFX(cheat.activateSFX);
            end
            if(cheat.toggleSFX and not silent) then
                Audio.playSFX(cheat.toggleSFX);
            end
            EventManager.callEvent("onCheatActivate",cheat,silent)
        else
            if(cheat.onDeactivate) then
                cheat.onDeactivate();
            end
            if(cheat.onToggle) then
                cheat.onToggle(false);
            end
                
            if(cheat.deactivateSFX and not silent) then
                Audio.playSFX(cheat.deactivateSFX);
            end
            if(cheat.toggleSFX and not silent) then
                Audio.playSFX(cheat.toggleSFX);
            end
            EventManager.callEvent("onCheatDeactivate",cheat,silent)
        end
        
        if(cheat.active) then
            GameData.__activatedCheats[cheat.id] = true;
        else
            GameData.__activatedCheats[cheat.id] = nil;
        end
        
        for k,v in pairs(cheat) do
            if(defs.LUNALUA_EVENTS_MAP[k]) then
                if(cheat.active) then
                    registerEvent(cheat, k);
                else
                    unregisterEvent(cheat, k, k);
                end
            end
        end
        
        updateGroups();
    end
end

local function makecheatmt(id)
    local cheat_mt = {};
    function cheat_mt.__index(tbl,key)
        if(key == "aliases") then
            local n = table.find(newcheats.cheatsList, tbl)
            return table.findall(newcheats.cheatsList, n) or {};
        elseif(key == "id") then
            return id;
        elseif(key == "trigger") then
            return newcheats.trigger;
        end
    end
    function cheat_mt.__newindex(tbl,key,val)
        if(key == "aliases") then
            error("Cannot assign to cheat alias list. Use the addAlias or deregister functions to modify aliases.",2);
        elseif(key == "id" or key == "trigger") then
            error("Cannot change a read-only field.",2)
        else
            rawset(tbl,key,val)
        end
    end
    
    return cheat_mt;
end

--Register a new cheat
function newcheats.register(name, args)
    newcheats.cheatsList[name] = args;
    newcheats.cheatsList[name].active = false;
    newcheats.cheatsList[name].cheats = nil;
    if(newcheats.cheatsList[name].isCheat == nil) then
        newcheats.cheatsList[name].isCheat = true;
    end
    
    if(newcheats.cheatsList[name].aliases) then
        for _,v in ipairs(newcheats.cheatsList[name].aliases) do
            newcheats.cheatsList[v] = name;
        end
    end
    newcheats.cheatsList[name].aliases = nil;
    
    for k,v in pairs(newcheats.cheatsList) do
        if(v.id == name) then
            error("Cheat already exists with the id '"..name.."', under the code '"..k.."'.", 2);
        end
    end
    
    setmetatable(newcheats.cheatsList[name], makecheatmt(name));
    return newcheats.cheatsList[name];
end

function newcheats.registerGroup(name, args)
    local c = args.cheats;
    newcheats.register(name, args);
    
    newcheats.cheatsList[name].cheats = c;
    
    newcheats.cheatsList[name].onToggle = function(val)
        for _,v in ipairs(newcheats.cheatsList[name].cheats) do
            local w = newcheats.cheatsList[v];
            if(type(w) == "string") then
                w = newcheats.cheatsList[w];
            end
            if(w and w.active ~= val) then
                w:trigger();
            end
        end
    end
    table.insert(groupList, name);
    
    return newcheats.cheatsList[name];
end

local function removeGroup(name)
    local g = table.ifind(groupList, name);
    if(g) then
        table.remove(groupList, g);
    end
end

--Deregister a cheat, optionally keeping its aliases (also used to remove an alias)
function newcheats.deregister(name, keepAliases)
    if(newcheats.cheatsList[name]) then
        removeGroup(name);
        
        if(type(newcheats.cheatsList[name]) == "string") then
            if(keepAliases) then
                newcheats.cheatsList[name] = nil; --if we want to keep aliases, then we just delete this alias
            else
                newcheats.deregister(newcheats.cheatsList[name]); --if we don't want to keep aliases, then we deregister the main cheat
            end
        else
            --if we're getting rid of the cheat, we should deactivate it if necessary
            if(newcheats.cheatsList[name].active) then
                newcheats.trigger(name);
            end
            
            local newMain;
            --manage aliases
            for k,v in pairs(newcheats.cheatsList) do
                if(v == name) then    --is an alias
                    if(keepAliases) then
                        if(newMain) then
                            newcheats.cheatsList[k] = newMain;    --point the alias at the new main cheat, if it exists
                        else
                            newcheats.cheatsList[k] = newcheats.cheatsList[name];    --convert an alias into the main cheat if we haven't already
                            newMain = k;    

                            --update group cheats to new alias if we're deleting the main one, or update references to this cheat in group list
                            for l,m in ipairs(groupList) do
                                if(m == name) then
                                    groupList[l] = newMain;
                                elseif(newcheats.cheatsList[m].cheats ~= nil) then
                                    for n,o in ipairs(newcheats.cheatsList[m].cheats) do
                                        if(o == name) then
                                            newcheats.cheatsList[m].cheats[n] = newMain;
                                        end
                                    end
                                end
                            end
                        end
                    else
                        newcheats.cheatsList[k] = nil;    --if we're not keeping aliases, just delete them
                    end
                end
            end
            newcheats.cheatsList[name] = nil; --finally, deregister the cheat we passed as an argument
        end
    end
end

--Add a new alias to an existing cheat
function newcheats.addAlias(name, alias)
    if(newcheats.cheatsList[name]) then
        if(type(newcheats.cheatsList[name]) == "string") then
            newcheats.addAlias(newcheats.cheatsList[name], alias);    --we're adding an alias to an alias, so add it to the main cheat instead
        else
            newcheats.cheatsList[alias] = name;    --add a new alias
        end
    else
        error("No cheat '"..name.."' found.",2);
    end
end

--Register a player transformation cheat
function newcheats.registerPlayer(name, id, args)
    if(args == nil) then
        args = {};
    else
        args = table.deepclone(args);
    end
    args.flashPlayer = true;
    args.onActivate = function()
        --TODO: Swap with player:transform when it exists
        player.character = id;
        if(not isOverworld) then
            local a = Animation.spawn(10, player.x+player.width*0.5, player.y+player.height*0.5);
            a.x = a.x-a.width*0.5;
            a.y = a.y-a.height*0.5;
        end
        return true;
    end
    args.onToggle = nil;
    args.onDeactivate = nil;
    args.activateSFX = 34;
    args.deactivateSFX = nil;
    args.toggleSFX = nil;
    return newcheats.register(name, args)
end

--Get a list of all the cheat names
function newcheats.listCheats()
    local t = {}
    for k,_ in pairs(newcheats.cheatsList) do
        table.insert(t, k);
    end
    return t;
end

do --built-in cheats
    local shadowstar_shader = Misc.multiResolveFile("shadowstar.frag", "shaders\\cheats\\shadowstar.frag");
    local hudoverride;
    local shadowstar_onDraw;
    local shadowstar_onHUDDraw;
    if(not isOverworld) then
        function shadowstar_onDraw()
            if (isOverworld) then
                return
            end
            if(Defines.cheat_shadowmario) then
                player:render{x = x, y = y, color = Color.black, mountcolor = Color.white, drawmounts = (player:mem(0x108, FIELD_WORD) ~= 3)};
            end
        end
    else
        function shadowstar_onHUDDraw()
            if (isOverworld) then
                return
            end
            if(Defines.cheat_shadowmario and Graphics.getOverworldHudState() == WHUD_ALL) then
                
                if(hudoverride == nil) then
                    hudoverride = require("HUDOverride");
                end
                
                if(hudoverride.visible.overworldPlayer) then                            
                    hudoverride.drawHUDPlayer(player, hudoverride.priority+0.0001, Color.black);
                end
            end
        end
    end
    
    local cheat_shadowstar;
    local cheat_godmode;
    local cheat_jumpman;
    local cheat_gottagofast;
    local cheat_moneytree;
    
    do --built-in SMBX 1.3 cheats
        local function registerDefinesCheat(name, define, aliases)
            local args = { onToggle = function(val) Defines[define] = val; end, flashPlayer = true, aliases = aliases, activateSFX = 6, deactivateSFX = 5 }
            return newcheats.register(name, args)
        end
        
        local function registerHeldCheat(name, heldID, ai1)
            local t;
            t = newcheats.register(name, { onActivate = function() 
                                                        local cheat = t;
                                                        if not isOverworld then
                                                            if(player.holdingNPC == nil or not player.holdingNPC.isValid) then
                                                                local n = NPC.spawn(heldID, player.x+32, player.y, player.section);
                                                                player:mem(0x154, FIELD_WORD, n.idx+1);
                                                                n:mem(0x12C, FIELD_WORD, 1);
                                                                if(ai1 ~= nil) then
                                                                    n.ai1 = ai1;
                                                                end
                                                                cheat.timer = 32;
                                                            else
                                                                player:mem(0x154, FIELD_WORD, 0);
                                                                cheat.timer = 0;
                                                            end
                                                        else
                                                            cheat.timer = 0;
                                                        end
                                                    end,
                                        onTick = function()
                                                    GameData.__activatedCheats[t.id] = nil;
                                                    local cheat = t;
                                                    if(cheat.timer > 0) then
                                                        cheat.timer = cheat.timer - 1;
                                                        player.runKeyPressing = true;
                                                    else
                                                        newcheats.trigger(t); --turn off cheat
                                                    end
                                                end,
                                        activateSFX = 23;
                                        })
            return t;
        end

        
        local function registerItemCheat(name, id)
            return newcheats.register(name, 
                                            { onActivate = function() 
                                                                    if not isOverworld then
                                                                        if(Graphics.getHUDType(player.character) == Graphics.HUD_ITEMBOX) then
                                                                            player.reservePowerup = id;
                                                                        elseif (not isOverworld) then
                                                                            local c = camera;
                                                                            local n = NPC.spawn(id, c.x+400, c.y+32, player.section);
                                                                            n.x = n.x-n.width*0.5;
                                                                            n:mem(0x138, FIELD_WORD, 2);
                                                                        end
                                                                    end
                                                                    return true; 
                                                            end, activateSFX = 12
                                            
                                            })
        end
        
        local function registerVanillaCheat(name, toggle, isCheat)
            local args = {isCheat = isCheat}
            if(toggle) then
                args.onToggle = function() cheatBuffer_raw(name); cheatbuffer = nil; end;
            else
                args.onActivate = function() 
                                        cheatBuffer_raw(" "..name);
                                        cheatbuffer = nil; 
                                        return true; 
                                    end;
            end
            
            return newcheats.register(name, args)
        end
        
        cheat_godmode = registerDefinesCheat("donthurtme", "cheat_donthurtme");
        registerDefinesCheat("wingman", "cheat_wingman");
        cheat_gottagofast = registerDefinesCheat("sonicstooslow", "cheat_sonictooslow", { "gottagofast" });
        cheat_jumpman = registerDefinesCheat("ahippinandahoppin", "cheat_ahippinandahoppin", { "jumpman" } );
        registerDefinesCheat("speeddemon", "cheat_speeddemon");
        registerDefinesCheat("flamethrower", "cheat_flamerthrower");
        newcheats.register("stickyfingers", { onToggle = function(val) Defines.cheat_stickyfingers = val; player:mem(0x156, FIELD_BOOL, val); end, activateSFX = 6, deactivateSFX = 5, flashPlayer = true });
        
        cheat_shadowstar = newcheats.register("shadowstar", { onToggle = function(val) Defines.cheat_shadowmario = val; end, onDraw = shadowstar_onDraw, onHUDDraw = shadowstar_onHUDDraw, toggleSFX = 34, flashPlayer = true });
        
        registerHeldCheat("wherearemycarkeys", 31)
        registerHeldCheat("boingyboing", 26)
        registerHeldCheat("bombsaway", 134)
        registerHeldCheat("firemissiles", 17)
        registerHeldCheat("powhammer", 241)
        registerHeldCheat("hammerinmypants", 29)
        registerHeldCheat("rainbowrider", 195)
        registerHeldCheat("upandout", 278)
        registerHeldCheat("burnthehousedown", 279)
        registerHeldCheat("greenegg", 96, 95)
        registerHeldCheat("redegg", 96, 100)
        registerHeldCheat("blueegg", 96, 98)
        registerHeldCheat("yellowegg", 96, 99)
        registerHeldCheat("purpleegg", 96, 149)
        registerHeldCheat("pinkegg", 96, 150)
        registerHeldCheat("coldegg", 96, 228)
        registerHeldCheat("blackegg", 96, 148)
        
        registerItemCheat("needashell", 113)
        registerItemCheat("needaredshell", 114)
        registerItemCheat("needablueshell", 115)
        registerItemCheat("needayellowshell", 116)
        registerItemCheat("needaturnip", 92)
        registerItemCheat("needa1up", 90)
        registerItemCheat("needamoon", 188)
        registerItemCheat("needatanookisuit", 169)
        registerItemCheat("needahammersuit", 170)
        registerItemCheat("needamushroom", 9)
        registerItemCheat("needaflower", 14)
        registerItemCheat("needaleaf", 34)
        registerItemCheat("needanegg", 96)
        registerItemCheat("needaplant", 49)
        registerItemCheat("needagun", 22)
        registerItemCheat("needaswitch", 32)
        registerItemCheat("needaclock", 248)
        registerItemCheat("needabomb", 134)
        registerItemCheat("needashoe", 35)
        registerItemCheat("needaredshoe", 191)
        registerItemCheat("needablueshoe", 193)
        registerItemCheat("needaniceflower", 264)
        
        cheat_moneytree = newcheats.register("moneytree", { 
                        onTick = 
                        function()
                            if(mem(0x00B2C5AC, FIELD_FLOAT) == 99 and mem(0x00B2C5A8, FIELD_WORD) == 99) then --max lives and coins
                                local cheat = cheat_moneytree;
                                cheat.active = false;
                                unregisterEvent(cheat, "onTick", "onTick");
                                return;
                            end
                            GameData.__activatedCheats[cheat_moneytree.id] = nil;
                            Misc.coins(1, true)
                        end,
                        activateSFX = 6, deactivateSFX = 5 });
                        
        newcheats.register("stophittingme", { onActivate = function() local donthurtme = Defines.cheat_donthurtme; Defines.cheat_donthurtme = false; player:harm(); Defines.cheat_donthurtme = donthurtme; return true; end});
        
        newcheats.register("wariotime", { onActivate = 
                                            function()
                                                if (isOverworld) then
                                                    return true
                                                end
                                                local c = camera;
                                                for _,v in ipairs(colliders.getColliding{a = colliders.Box(c.x,c.y,c.width,c.height), b = NPC.HITTABLE, btype = colliders.NPC}) do
                                                    v:transform(10);
                                                    v.speedX = 0;
                                                    v.speedY = 0;
                                                end
                                                return true;
                                            end, activateSFX = 34})
                                            
        newcheats.register("wetwater", { onActivate =
                                            function()
                                                if (isOverworld) then
                                                    return true
                                                end
                                                for _,v in ipairs(Section.get()) do
                                                    v.backgroundID = 56;
                                                    v.musicID = 18;
                                                    v.isUnderwater = true;
                                                end
                                                playMusic(player.section)
                                                return true;
                                            end})
                                            
        newcheats.register("fairymagic", { onActivate = function() 
                                                            if (isOverworld) then
                                                                return true
                                                            end
                                                            if(player:mem(0x0C, FIELD_BOOL)) then
                                                                player:mem(0x0C, FIELD_BOOL, false); 
                                                            else
                                                                player:mem(0x0C, FIELD_BOOL, true); 
                                                                player:mem(0x10, FIELD_WORD, -1); 
                                                            end
                                                            local a = Animation.spawn(63, player.x+player.width*0.5, player.y + player.height*0.75)
                                                            
                                                            return true; 
                                                        end, activateSFX = 87, flashPlayer = true })
        
        newcheats.register("iceage", { onActivate = 
                                            function()
                                                if (isOverworld) then
                                                    return true
                                                end
                                                local c = camera;
                                                for _,v in ipairs(colliders.getColliding{a = colliders.Box(c.x,c.y,c.width,c.height), b = NPC.HITTABLE, btype = colliders.NPC}) do
                                                    v:toIce();
                                                    v.speedX = 0;
                                                    v.speedY = 0;
                                                end
                                                return true;
                                            end, activateSFX = 34})
                                            
        newcheats.register("itsrainingmen", { onActivate = 
                                            function()
                                                if (isOverworld) then
                                                    return true
                                                end
                                                local n = NPC.spawn(90,player.x-400,player.y-600,player.section);
                                                n.dontMove = true;
                                                for i = n.x+n.width,player.x+400,n.width do
                                                    n = NPC.spawn(90,i,player.y-600,player.section);
                                                    n.dontMove = true;
                                                end
                                                return true;
                                            end, activateSFX = 34})
                                            
        newcheats.register("donttypethis", { onActivate = 
                                            function()
                                                if (isOverworld) then
                                                    return true
                                                end
                                                local n = NPC.spawn(134,player.x-400,player.y-600,player.section);
                                                n.dontMove = true;
                                                for i = n.x+n.width,player.x+400,n.width do
                                                    n = NPC.spawn(134,i,player.y-600,player.section);
                                                    n.dontMove = true;
                                                end
                                                return true;
                                            end, activateSFX = 34})
                            
    --[[     --Semi-broken lua interpretation            
        newcheats.register("captainn", { 
                        onActivate = function() 
                                    local cheat = newcheats.get("captainn");
                                    cheat.lastPauseKeyPressing = true;
                                    cheat.timestop = false;
                                end,
                                
                        onDeactivate = function()
                                    local cheat = newcheats.get("captainn");
                                    --TODO: Check for pswitch music - that suggests timestop watch
                                    if(cheat.timestop and Defines.levelFreeze) then
                                        Defines.levelFreeze = false;
                                    end
                                end,
        
                        onInputUpdate = 
                                function()
                                    local cheat = newcheats.get("captainn");
                                    local pressedPause = player.pauseKeyPressing and not cheat.lastPauseKeyPressing;
                                    cheat.lastPauseKeyPressing = player.pauseKeyPressing;
                                    
                                    --TODO: Check for pswitch music - that suggests timestop watch
                                    if(Defines.levelFreeze == cheat.timestop) then
                                        player.pauseKeyPressing = false;
                                    else
                                        pressedPause = false;
                                    end
                                    
                                    if(pressedPause) then
                                        cheat.timestop = not cheat.timestop;
                                        if(not cheat.timestop) then
                                            Defines.levelFreeze = false;
                                        end
                                        Audio.playSFX(30);
                                    end
                                        
                                    if(cheat.timestop) then
                                        Defines.levelFreeze = true;
                                    end
                                end,
                                
                                activateSFX = 6, deactivateSFX = 5})
    ]]
    --[[    --Works, but os.clock resolution isn't reliable
        newcheats.register("framerate", {
                            onActivate = function()
                                local cheat = newcheats.get("framerate");
                                cheat.avgs = {};
                                cheat.idx = 1;
                            end,
                            onDraw = function()
                                local cheat = newcheats.get("framerate");
                                if(cheat.tick ~= nil) then
                                    local dt = math.max(os.clock() - cheat.tick,0.001);
                                    local fps = 1/dt;
                                    if(#cheat.avgs < 64) then
                                        table.insert(cheat.avgs, fps);
                                    else
                                        cheat.avgs[cheat.idx] = fps;
                                        cheat.idx = (cheat.idx)%64 + 1;
                                        fps = 0;
                                        for i = 1,#cheat.avgs do
                                            fps = fps + cheat.avgs[i];
                                        end
                                        Text.printWP(math.floor(fps/#cheat.avgs + 0.5), 1, 5, 5, 5);
                                    end
                                end
                                cheat.tick = os.clock();
                            end,
                            activateSFX = 6, deactivateSFX = 5, isCheat = false})
    ]]
                            
        registerVanillaCheat("captainn", true)
        registerVanillaCheat("framerate", true, false)
        
        for i = 1,7 do
            registerVanillaCheat("supermario"..tostring(2^i))
        end
        
        registerVanillaCheat("imtiredofallthiswalking")
        registerVanillaCheat("illparkwhereiwant")
        registerVanillaCheat("istillplaywithlegos")
        registerVanillaCheat("1player")
        registerVanillaCheat("2player")
                            
        newcheats.registerPlayer("itsamemario", CHARACTER_MARIO);
        newcheats.registerPlayer("itsameluigi", CHARACTER_LUIGI);
        newcheats.registerPlayer("anothercastle", CHARACTER_TOAD, {aliases = {"itsametoad"}});
        newcheats.registerPlayer("ibakedacakeforyou", CHARACTER_PEACH, {aliases = {"itsamepeach"}});
        newcheats.registerPlayer("iamerror", CHARACTER_LINK, {aliases = {"itsamelink"}});
    end

    do --built-in SMBX2 cheats

        local function act_suicide()
            for k,p in ipairs(Player.get()) do
                p:kill()
                if(not isOverworld) then
                    Explosion.spawn(p.x + 0.5 * p.width, p.y + 0.5 * p.height, 3)
                    earthquake(10)
                end
            end
            return true;
        end
        --Kills yourself
        newcheats.register("suicide", { onActivate = act_suicide, activateSFX = 22 });
        
        local function trigger_set(cheat, val)
            if(cheat and cheat.active ~= val) then
                newcheats.trigger(cheat);
                if(cheat.active) then
                    GameData.__activatedCheats[cheat.id] = nil;
                end
                return true;
            else
                return cheat ~= nil;
            end
            
        end
        
        local function tog_holytrinity(val)
            if(not trigger_set(cheat_godmode, val)) then
                Defines.cheat_donthurtme = val;
            end
            if(not trigger_set(cheat_jumpman, val)) then
                Defines.cheat_ahippinandahoppin = val;
            end
            if(not trigger_set(cheat_shadowstar, val)) then
                Defines.cheat_shadowmario = val;
            end
        end
        --Invincibility, infinite jumps, and the ability to walk through walls
        --newcheats.register("holytrinity", { onToggle = tog_holytrinity, onDraw = shadowstar_onDraw, onHUDDraw = shadowstar_onHUDDraw, toggleSFX = 34, flashPlayer = true, exclusions = {"theessentials"} } );
        newcheats.registerGroup("holytrinity", { cheats = {"shadowstar", "donthurtme", "jumpman"} } )

        local function tog_essentials(val)
            if(not trigger_set(cheat_godmode, val)) then
                Defines.cheat_donthurtme = val;
            end
            if(not trigger_set(cheat_jumpman, val)) then
                Defines.cheat_ahippinandahoppin = val;
            end
            if(not trigger_set(cheat_shadowstar, val)) then
                Defines.cheat_shadowmario = val;
            end
            if(not trigger_set(cheat_gottagofast, val)) then
                Defines.cheat_sonictooslow = val;
            end
        end
        
        --Invincibility, infinite jumps, super speed
        newcheats.registerGroup("passerby", { cheats = {"sonicstooslow", "donthurtme", "jumpman"} } )
        
        --Invincibility, infinite jumps, SUPER SPEED, and the ability to walk through walls
        --newcheats.register("theessentials", { onToggle = tog_essentials, onDraw = shadowstar_onDraw, onHUDDraw = shadowstar_onHUDDraw, toggleSFX = 34, flashPlayer = true, aliases = {"theessenjls"}, exclusions = {"holytrinity"} } );
        newcheats.registerGroup("theessentials", { cheats = {"shadowstar", "donthurtme", "jumpman", "sonicstooslow"}, aliases = {"theessenjls"} } )
    
        local function act_liveforever()
            mem(0x00B2C5AC, FIELD_FLOAT, 99)
            return true;
        end
        --Get 99 lives
        newcheats.register("liveforever", { onActivate = act_liveforever, flashPlayer = true, activateSFX = 15 });
        
        local sfx_kyaa = Misc.resolveSoundFile("kyaa");
        
        local function act_gdiredigit()
            Defines.player_hasCheated = false
            return true;
        end
        --Allow saving after using a cheat
        newcheats.register("gdiredigit", {onActivate = act_gdiredigit, activateSFX = sfx_kyaa, isCheat = false, aliases = { "redigitiscool" } });
        
        local function act_launchme()
            player.speedY = -30
            return true;
        end
        --Propel yourself upwards
        newcheats.register("launchme", {onActivate = act_launchme, activateSFX = 61});
        
        local function act_itsrainingmegan()
            local players = Player.get()
            for k,v in ipairs(Camera.get()) do
                if k == 2 and #players == 1 then break end
                for i=0, v.width, 32 do
                    NPC.spawn(427, v.x + i, v.y - 64, players[k].section)
                end
            end
            return true;
        end
        --Shower yourself in 1ups
        newcheats.register("itsrainingmegan", {onActivate = act_itsrainingmegan, activateSFX = 34});
        
        local function act_boomtheroom()
            if (isOverworld) then
                return true
            end
            Misc.doPOW()
            return true;
        end
        --Pow block yo
        newcheats.register("boomtheroom", {onActivate = act_boomtheroom, activateSFX = 34});
        
        local function act_instantswitch()
            if (isOverworld) then
                return true
            end
            Misc.doPSwitch()
            return true;
        end
        --P-switch magic
        newcheats.register("instantswitch", {onActivate = act_instantswitch, activateSFX = 34});
        
        local function act_murder()
            if(isOverworld) then
                return true;
            end
            for _, v in ipairs(NPC.get(NPC.HITTABLE, player.section)) do
                if v:mem(0x128, FIELD_WORD) ~= -1 then
                    v:kill()
                end
            end
            Defines.earthquake = 50
            return true;
        end
        --Kill everything
        newcheats.register("murder", {onActivate = act_murder, activateSFX = 22, aliases = { "redrum" } });
        
        local function act_dressup()
            local costumes = playerManager.getCostumes(player.character)
            for k, v in ipairs(costumes) do
                if v == Player.getCostume(player.character) then
                    costumes[k] = nil
                end
            end
            if(not isOverworld) then
                Animation.spawn(10, player.x, player.y)
            end
                Player.setCostume(player.character, rng.irandomEntry(costumes))
            return true;
        end
        --Wear a random costume
        newcheats.register("dressmeup", {onActivate = act_dressup, flashPlayer = true, activateSFX = 41, isCheat = false });
        
        local function act_undress()
            if(not isOverworld) then
                Animation.spawn(10, player.x, player.y)
            end
                Player.setCostume(player.character, nil)
            return true;
        end
        --Remove your costume
        newcheats.register("undress", {onActivate = act_undress, flashPlayer = true, activateSFX = 41, isCheat = false });
        
        local function act_laundryday()
            if(not isOverworld) then
                Animation.spawn(10, player.x, player.y)
            end
            
            for k,_ in pairs(playerManager.getCharacters()) do
                Player.setCostume(k, nil)
            end
            
            return true;
        end
        --Remove costumes from every character
        newcheats.register("laundryday", {onActivate = act_laundryday, flashPlayer = true, activateSFX = 41, isCheat = false});
        
        local starman;
        if(not isOverworld) then
            starman = require("NPCs/ai/starman");
        end
        
        local function act_starman()
            if(starman) then
                starman.start(player)
            end
            return true;
        end
        --Instant starman
        newcheats.register("thestarmen", {onActivate = act_starman});
        
        local function act_getdown()
            local startPos = player.y;
            repeat
                player.y = player.y + player.height;
                if(player.y > player.sectionObj.boundary.bottom) then
                    player.y = startPos;
                    break;
                end
            until(#colliders.getColliding{a=player, b=Block.SOLID, btype=colliders.BLOCK} == 0);
            return true;
        end
        --Teleport down to the next available space
        newcheats.register("getdown", {onActivate = act_getdown, aliases = { "geddan" }, flashPlayer = true, activateSFX = 34 });
        
        local function act_foundmycarkeys()
            if(isOverworld) then
                return true;
            end
            local toTeleportData = {}
            for k, v in ipairs(Section.get()) do
                if (not toTeleportData.section) then
                    for _,bgo in ipairs(BGO.getIntersecting(v.boundary.left, v.boundary.top, v.boundary.right, v.boundary.bottom)) do
                        if (bgo.id == 35) then
                            toTeleportData.section = k - 1;
                            toTeleportData.x = bgo.x;
                            toTeleportData.y = bgo.y;
                            break;
                        end
                    end
                else
                    break;
                end
            end
            
            if toTeleportData.section then
                local npc = NPC.spawn(31, toTeleportData.x, toTeleportData.y, toTeleportData.section)
                player.HeldNPCIndex = npc.idx + 1
                player.x = toTeleportData.x
                player.y = toTeleportData.y
                npc:mem(0x12C, FIELD_WORD, 1)
                player:mem(0x15A, FIELD_WORD, toTeleportData.section)
            end
            
            return true;
        end
        --Auto-get a lock exit
        newcheats.register("foundmycarkeys", {onActivate = act_foundmycarkeys});
        
        local function act_lifegoals()
            if(isOverworld) then
                return true;
            end
            local goal = NPC.spawn(197, player.x, player.y, player.section)
            goal.x = player.x + (player.width - goal.width)*0.5;
            goal.y = player.y + (player.height - goal.height)*0.5;
            
            return true;
        end
        --Auto-get a goal tape
        newcheats.register("mylifegoals", {onActivate = act_lifegoals});
        
        local function act_mysteryball()
            if(isOverworld) then
                return true;
            end
            local goal = NPC.spawn(16, player.x, player.y, player.section)
            goal.x = player.x + (player.width - goal.width)*0.5;
            goal.y = player.y + (player.height - goal.height)*0.5;
            
            return true;
        end
        --Auto-get an orb exit
        newcheats.register("mysteryball", {onActivate = act_mysteryball});
        
        local function act_itsvegas()
            if(isOverworld) then
                return true;
            end
            local goal = NPC.spawn(11, player.x, player.y, player.section)
            goal.x = player.x + (player.width - goal.width)*0.5;
            goal.y = player.y + (player.height - goal.height)*0.5;
            
            return true;
        end
        --Auto-get a roulette exit
        newcheats.register("itsvegas", {onActivate = act_itsvegas});
        
        local function act_getmeouttahere()
            if(isOverworld) then
                return true;
            end
            Level.exit();
            return true;
        end
        --End the level
        newcheats.register("getmeouttahere", {onActivate = act_getmeouttahere});
        
        local function act_rosebud()
            mem(0x00B2C5A8, FIELD_WORD, 99)
            return true;
        end
        --Get 99 coins
        newcheats.register("rosebud", {onActivate = act_rosebud, activateSFX = 14});
        
        local function act_andmyaxe()
            if (isOverworld) then
                return true
            end
            local x = camera.x;
            local y = camera.y;
            for i=x,x+800,32 do
                for j=0,rng.randomInt(0,5) do
                    NPC.spawn(178,i,y-32*j,player.section);
                end
            end
            return true;
        end
        --Spawn a bunch of axes. For giggles.
        newcheats.register("andmyaxe", {onActivate = act_andmyaxe, isCheat = false});
        
        local function tog_hadron(val)
            colliders.debug = val;
        end
        --Debug tool for displaying colliders usage
        newcheats.register("hadron", {onToggle = tog_hadron, activateSFX = 12, deactivateSFX = 4, isCheat = false});
        
        local function act_groundhog()
            if (isOverworld) then
                return true
            end
            Graphics.drawScreen{color = Color.black, primitive = Graphics.GL_TRIANGLE_FAN, priority = 10};

            mem(0x00B2C6DA, FIELD_WORD, player:mem(0x15E, FIELD_WORD));
            mem(0x00B25720, FIELD_STRING, Level.filename());
            mem(0x00B250B4, FIELD_WORD, 0);
            mem(0x00B25134, FIELD_WORD, 0);
            mem(0x00B2C89C, FIELD_WORD, 0);
            mem(0x00B2C620, FIELD_WORD, 0);
            mem(0x00B2C5B4, FIELD_WORD, -1);
           
            return true;
        end
        --Reload the level from the last warp
        newcheats.register("groundhog", {onActivate = act_groundhog});
        
        local function tog_waitinginthesky()
            if(starman) then
                if string.find(starman.sfxFile,"starman.ogg") then
                    starman.sfxFile = Misc.resolveSoundFile("waitinginthesky")
                    starman.duration[293] = lunatime.toTicks(30.5);
                else
                    starman.sfxFile = Misc.resolveSoundFile("starman")
                    starman.duration[293] = lunatime.toTicks(NPC.config[293].duration);
                end
                starman.reloadMusic()
            end
        end
        --Change the starman tune to some sweet Bowie
        newcheats.register("waitinginthesky", {onToggle = tog_waitinginthesky, toggleSFX=34});
        
        local megashroom;
        if(not isOverworld) then
            megashroom = require("NPCs\\AI\\megashroom");
        end
        
        local function act_bitemythumb()
            if(megashroom) then
                if(not player.isMega) then
                    megashroom.StartMega(player);
                else
                    megashroom.StopMega(player, true);
                end
            end
            return true;
        end
        --Get big
        newcheats.register("bitemythumb", {onActivate = act_bitemythumb});
        
        local function rinkamania_onNPCKill(_, npc, reason)
            if reason ~= 9 then
                NPC.spawn(210, npc.x, npc.y, npc:mem(0x146,FIELD_WORD));
            end
        end
        --Spawn rinkas when you kill an NPC
        newcheats.register("rinkamania", {toggleSFX = 65, flashPlayer = true, onNPCKill = rinkamania_onNPCKill})
        
        local function radicola_onTick()
            if (isOverworld) then
                return
            end
            player:mem(0x108, FIELD_WORD, 1) 
            player:mem(0x10A, FIELD_WORD, 1)
            local kya = Audio.SfxOpen(sfx_kyaa);
            for i = 1, 91 do
                Audio.sounds[i].sfx = kya;
            end
        end
        
        local function tog_radicola()
            if(not isOverworld) then
                Defines.earthquake = 10;
            end
        end

        local function deact_radicola()
            if (isOverworld) then
                return
            end
            for i = 1, 91 do
                Audio.sounds[i].sfx = nil
            end
        end
        --BOOTS AND KYA FOR EVERYONE
        newcheats.register("horikawaisradicola", {toggleSFX = 34, onToggle = tog_radicola, onDeactivate = deact_radicola, onTick = radicola_onTick})
        
        local function jumpforrinka_onKeyDown(keycode)
            if (isOverworld) then
                return
            end
            if player:isGroundTouching() and keycode == KEY_JUMP then
                local n = NPC.spawn(210, player.x+player.width*0.5, player.y + player.height + 16, player.section);
                n.x = n.x - n.width*0.5;
            end
        end
        --Press jump, get rinka
        newcheats.register("jumpforrinka", {toggleSFX = 65, flashPlayer = true, onKeyDown = jumpforrinka_onKeyDown})
        
        local function rinkamadness_onTick()
            if(not isOverworld) then
                if rng.randomInt(1, 20) == 20 then
                    local c = camera;
                    local x = c.x + c.width*0.5 + rng.randomInt(-800, 800);
                    local y = c.y + c.height*0.5 + rng.randomInt(-600, 600);
                    if(math.abs(player.x - x) > player.width*2 and math.abs(player.y - y) > player.height*2) then
                        local n = NPC.spawn(210, x, y, player.section)
                        n.x = n.x-n.width*0.5;
                        n.y = n.y-n.height*0.5;
                    end
                end
            end
        end
        --Rinkas at random 
        newcheats.register("rinkamadness", {toggleSFX = 65, flashPlayer = true, onTick = rinkamadness_onTick})
        
        local cheat_worldpeace;
        local function worldpeace_onTick()
            if(not isOverworld) then
                local cheat = cheat_worldpeace;
                local anims = Animation.get();
                
                if cheat.animCount < #anims then
                    Audio.playSFX(cheat.toggleSFX);
                end
            
                for k, v in ipairs(anims) do
                    if(not cheat.excludeIDs[v.id]) then
                        v.speedY = -2
                        v.speedX = 0
                    end
                end
                cheat.animCount = #anims
            end
        end
        --Effects float upwards and play weird noises... No I don't know either
        cheat_worldpeace = newcheats.register("worldpeace", 
        {
        toggleSFX = (Misc.resolveSoundFile("yeah")), 
        onTick = worldpeace_onTick, 
        animCount = 0, 
        excludeIDs = table.map({1, 3, 5, 10, 11, 12, 13, 21, 26, 30, 51, 54, 55, 56, 57, 58, 59, 71, 73, 74, 75, 76, 77, 78, 79, 80, 82, 100, 101, 102, 103, 104, 107, 113, 114, 129, 130, 131, 132, 133, 134, 135, 136, 139, 144, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161})
        })
            
        local cheat_getdemstars;
        local function getstars_onTick()
            if(isOverworld) then
                return;
            end
            local theNextStar, spawnedBlock;
            Defines.cheat_donthurtme = true;
            Defines.cheat_shadowmario = true;
            
            GameData.__activatedCheats[cheat_getdemstars.id] = nil;
            
            local stars = {[97]={}, [196]={}}
            
            for _, v in ipairs(NPC.get({97, 196}, -1)) do
                if v:mem(0xF0, FIELD_DFLOAT) ~= 1 and not v:mem(0x64, FIELD_BOOL) and not v.friendly then
                    table.insert(stars[v.id], v)
                end
            end
            
            if (#stars[196] >= 1 or #stars[97] >= 1) then
                local star = table.remove(stars[196], 1) or table.remove(stars[97], 1)
                if tostring(star.layerName) ~= "" then
                    Layer.get(tostring(star.layerName)):show(false)
                end
                player:mem(0x15A, FIELD_WORD, star:mem(0x146, FIELD_WORD))
                player.x = star.x
                player.y = star.y
                if (#stars[97] >= 1) then
                    mem(0x00B2C59E, FIELD_WORD, 0) --stop ending level
                end
            else
                player.speedX = 0
                player.speedY = 0
                
                local cheat = cheat_getdemstars;
                
                player:mem(0x15A, FIELD_WORD, cheat.start.section)
                player.x = cheat.start.x;
                player.y = cheat.start.y;
                
                Defines.cheat_donthurtme = cheat.start.donthurtme;
                Defines.cheat_shadowmario = cheat.start.shadowstar;
                newcheats.trigger(cheat_getdemstars); --turn off cheat
            end
        end

        local function act_getstars()
            if(isOverworld) then
                return true;
            end
            
            local cheat = cheat_getdemstars;
            cheat.start = 
            {
                x = player.x;
                y = player.y;
                section = player.section;
                donthurtme = Defines.cheat_donthurtme;
                shadowstar = Defines.cheat_shadowmario;
            };
            
            
            for _, block in ipairs(Block.get()) do
                if block.contentID == 1097 or block.contentID == 1196 then
                    block:hit()
                end
            end
            
            for _,container in ipairs(NPC.get({91, 263, 283, 284}, -1)) do
                if container.ai1 == 97 or container.ai1 == 196 then
                    NPC.spawn(container.ai1, container.x, container.y, container:mem(0x146, FIELD_WORD))
                end
            end
            
            for _,v in ipairs(NPC.get({97, 196}, -1)) do
                if v:mem(0x64, FIELD_BOOL) then
                    NPC.spawn(v.id, v.x, v.y, v:mem(0x146, FIELD_WORD))
                end
            end
            
            return false;
        end
        --Teleport around and collect all stars in the level
        cheat_getdemstars = newcheats.register("getdemstars", {onActivate = act_getstars, onTick = getstars_onTick})
        
        
        local function noclip_onTick()
            if (isOverworld) then
                return
            end
            local dx,dy = 0,0
            local walk = Defines.player_walkspeed
            local ratio = Defines.player_runspeed/walk
            if not(player.leftKeyPressing and player.rightKeyPressing) then
                if player.leftKeyPressing then
                    dx = -walk
                elseif player.rightKeyPressing then
                    dx = walk
                end
            end
            if not(player.upKeyPressing and player.downKeyPressing) then
                if player.upKeyPressing then
                    dy = -walk
                elseif player.downKeyPressing then
                    dy = walk
                end
            end
            if player.runKeyPressing then
                if player.altRunKeyPressing then
                    ratio = 2*ratio
                end
                dx = dx*ratio
                dy = dy*ratio
            end
            player.x = player.x + dx
            player.y = player.y + dy
            if dx < 0 then
                player.FacingDirection = DIR_LEFT
            elseif dx > 0 then
                player.FacingDirection = DIR_RIGHT
            end
            player.speedX = dx
        end

        local function tog_noclip(val)
            if (isOverworld) then
                return true
            end
            if val then
                player.ForcedAnimationState = 73
            else
                player.ForcedAnimationState = 0
            end
        end
        --No acceleration and walk through walls? I guess?
        newcheats.register("noclip", {onToggle = tog_noclip, toggleSFX=34, flashPlayer = true, onTick = noclip_onTick})
        
        local real_noyoshi = setmetatable({},{
            __index = function() return false end
        })
        local function tog_meatball()
            if (isOverworld) then
                return true
            end
            for k,v in ipairs(NPC.ALL) do
                real_noyoshi[v], NPC.config[v].noyoshi = NPC.config[v].noyoshi, real_noyoshi[v]
            end
        end
        --yoshi can eat everything
        newcheats.register("nowiknowhowameatballfeels", {onToggle = tog_meatball, toggleSFX = 55})
        
        local function fromthedepths_onTick()
            if (isOverworld) then
                return
            end
            for _,p in ipairs(Player.get()) do
                if p:mem(0x13E,FIELD_WORD) == 1 and p.y > p.sectionObj.boundary.bottom then
                    p:mem(0x13E,FIELD_WORD,0)
                    p.y = p.sectionObj.boundary.bottom
                    p.speedY = -20
                    Audio.SfxPlayObj(Audio.sounds[54].sfx,0)
                elseif p:mem(0x13E,FIELD_WORD) == 1 then
                    Audio.SfxPlayObj(Audio.sounds[8].sfx,0)
                end
            end
        end
        local function act_fromthedepths()
            if (isOverworld) then
                return true
            end
            Audio.sounds[8].muted = true
        end
        local function deact_fromthedepths()
            if (isOverworld) then
                return true
            end
            Audio.sounds[8].muted = false
        end
        --Jump up high when falling into a pit instead of dying
        newcheats.register("fromthedepths", {onActivate=act_fromthedepths, onDeactivate=deact_fromthedepths, toggleSFX=91, onTick=fromthedepths_onTick})
        
        local function act_newleaf()
            newcheats.reset();
            return true;
        end
                                            
        newcheats.register("fourthwall", { onActivate = 
                                            function()
                                                repl.activeInEpisode = true
                                            end, 
                                            onDeactivate =
                                            function()
                                                repl.activeInEpisode = false
                                            end, activateSFX = 67, deactivateSFX = 13})
        
        --Disable all active cheats
        newcheats.register("newleaf", {onActivate = act_newleaf, activateSFX = 44, isCheat = false})
        
        --Character filter cheats
        newcheats.registerPlayer("superfightingrobot", CHARACTER_MEGAMAN, {aliases = {"itsamemegaman", "itsamegaman"}});
        newcheats.registerPlayer("eternalgreed", CHARACTER_WARIO, {aliases = {"itsamewario"}});
        newcheats.registerPlayer("kingofthekoopas", CHARACTER_BOWSER, {aliases = {"itsamebowser"}});
        newcheats.registerPlayer("dreamtraveler", CHARACTER_KLONOA, {aliases = {"dreamtraveller", "itsameklonoa"}});
        newcheats.registerPlayer("bombingrun", CHARACTER_NINJABOMBERMAN, {aliases = {"itsamebomberman", "itsameninjabomberman"}});
        newcheats.registerPlayer("cosmicpower", CHARACTER_ROSALINA, {aliases = {"itsamerosalina"}});
        newcheats.registerPlayer("metalgear", CHARACTER_SNAKE, {aliases = {"itsamesnake"}});
        newcheats.registerPlayer("ocarinaoftime", CHARACTER_ZELDA, {aliases = {"itsamezelda"}});
        newcheats.registerPlayer("densenuclearenergy", CHARACTER_ULTIMATERINKA, {aliases = {"itsameultimaterinka"}});
        newcheats.registerPlayer("unclesam", CHARACTER_UNCLEBROADSWORD, {aliases = {"itsamebroadsword", "itsameunclebroadsword"}});
        newcheats.registerPlayer("samusisagirl", CHARACTER_SAMUS, {aliases = {"itsamesamus", "itsamemetroid"}});
    end
end
_G.Cheats = newcheats;
return newcheats;