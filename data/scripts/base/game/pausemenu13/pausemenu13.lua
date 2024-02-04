--pausemenu13.lua (v2.1)
--By Spencer Everly
--v2.0 introduces a more-accurate-to SMBX-1.3 pause menu.

local pausemenu13 = {}

local textplus = require("textplus")

local smwMap
pcall(function() smwMap = require("smwMap") end)

local isOnSMWMap = (smwMap ~= nil and Level.filename() == smwMap.levelFilename)
local SMWMapIsActive = (smwMap ~= nil)

pausemenu13.enabled = true --If the pause menu needs to be disabled, set this to false.
pausemenu13.isPauseMenuOpen = false --This is true when the menu is open.
pausemenu13.isPauseMenuQuittingGame = false --True when the pause menu is saving and quitting the game. If this is set to true, a black screen will be drawn throughout the screen.
pausemenu13.isPauseMenuExitingLevel = false --Same as above, except it's true when exiting a level.
pausemenu13.saveAndQuitToBrokenLauncherInstead = false --ONLY for accuracy! DO NOT SET THIS IF YOU DON'T KNOW WHAT YOU'RE DOING! Setting this to true will BREAK episodes if launching multiple episodes on the legacy menu!
pausemenu13.addExitLevelOption = true --Adds a level exit option to the pause menu. If you don't have a map, you can keep this false. If you have a Hub to use instead, see the option below.
pausemenu13.disableSounds = false --This is only true when saving and quitting or exiting a level, but you can set this to true and not play a single sound what-so-ever
pausemenu13.disableTheDisablingOfSavingWhileCheating = true --This is true to make sure the menu still saves while cheating. If false, the game won't save at all when cheating.

pausemenu13.pauseFont = textplus.loadFont("base/game/pausemenu13/font.ini") --The font used for the pause menu.
pausemenu13.pauseCursor = Graphics.loadImage(getSMBXPath().."scripts/base/game/pausemenu13/pausemenu13-arrow.png") --The arrow image used for the pause menu.

pausemenu13.saveAndQuitSFX = 14 --The sound that plays when saving and quitting the game.
pausemenu13.saveSFX = 58 --The sound that plays when saving and continuing the game.
pausemenu13.menuNavigationUpSFX = 26 --The sound that plays when moving up on an option.
pausemenu13.menuNavigationDownSFX = 26 --The sound that plays when moving down on an option.
pausemenu13.menuNavigationToQuitOptionSFX = 26 --The sound that plays when moving to the bottom option when pressing run.
pausemenu13.pauseMenuOpenSFX = 30 --The sound that plays when opening the pause menu.
pausemenu13.pauseMenuCloseSFX = 30 --The sound that plays when closing the pause menu.
pausemenu13.exitLevelSFX = 14 --The sound that plays when exiting the level.

pausemenu13.secondsUntilGameQuits = 0.5 --Seconds it takes until the game entirely quits when saving and quitting.
pausemenu13.secondsUntilLevelExit = 0.5 --Seconds it takes until the game leaves the level when selecting "Exit to Map/Hub".

pausemenu13.menuPosition = 1 --Position the menu is on. The default is 0 (This is 0 instead of 1 for SMBX 1.3 code consistency!)
pausemenu13.screenW = 800 --The width of the screen. Change this if the screen is bigger/smaller than the SMBX2 resolution.
pausemenu13.screenH = 600 --The height of the screen. Change this if the screen is bigger/smaller than the SMBX2 resolution.

pausemenu13.maxMenuItems = 0
pausemenu13.menuItems = {}

--Below is the menu height, x/y positions of the menu, and box height for the box drawing.
pausemenu13.total_menu_height = 0
pausemenu13.menu_left_X = pausemenu13.screenW / 2 - 180 + 62
pausemenu13.menu_top_Y = 0
pausemenu13.menu_box_height = 200
pausemenu13.showBlackScreen = false

--The menu text options for the pause menu.
pausemenu13.menuText = {}
pausemenu13.menuText[1] = "CONTINUE"
pausemenu13.menuText[2] = "SAVE AND CONTINUE"
pausemenu13.menuText[3] = "SAVE AND QUIT"
if mem(0x00B25728, FIELD_BOOL) then
    pausemenu13.menuText[4] = "RETURN TO HUB"
else
    pausemenu13.menuText[4] = "RETURN TO MAP"
end

pausemenu13.isCancelled = false

function pausemenu13.onInitAPI()
    registerEvent(pausemenu13,"onInputUpdate")
    registerEvent(pausemenu13,"onDraw")
    registerEvent(pausemenu13,"onPause")
    --registerEvent(pausemenu13,"onKeyboardPressDirect")
    if SMBX_VERSION == VER_SEE_MOD then
        registerEvent(messageBox13,"onPauseSEEMod")
        registerEvent(messageBox13,"onPostPauseSEEMod")
    end
end

function pausemenu13.addMenuOption(menuText, functionToDo) --Adds a menu item to the pause menu
    pausemenu13.maxMenuItems = pausemenu13.maxMenuItems + 1
    pausemenu13.total_menu_height = (pausemenu13.maxMenuItems) * 36 - 18;
    pausemenu13.menu_top_Y = pausemenu13.screenH / 2 - pausemenu13.total_menu_height / 2;
    table.insert(pausemenu13.menuItems, {menuText, functionToDo, pausemenu13.maxMenuItems})
end

pausemenu13.addMenuOption("CONTINUE", (function() pausemenu13.continueGame(false) end))
if not isOverworld or not isOnSMWMap then
    if pausemenu13.addExitLevelOption then
        if mem(0x00B25728, FIELD_BOOL) then
            pausemenu13.addMenuOption("RETURN TO HUB", (function() Routine.run(pausemenu13.exitLevel) end))
        else
            pausemenu13.addMenuOption("RETURN TO MAP", (function() Routine.run(pausemenu13.exitLevel) end))
        end
    end
end
pausemenu13.addMenuOption("SAVE & CONTINUE", (function() pausemenu13.continueGame(true) end))
pausemenu13.addMenuOption("SAVE & QUIT", (function() Routine.run(pausemenu13.saveAndQuitGame) end))

function pausemenu13.unpauseJumpFailsafe()
    for _,p in ipairs(Player.get()) do
        if isOverworld then
            p:mem(0x17A, FIELD_BOOL, false)
        else
            p:mem(0x11E, FIELD_BOOL, false)
        end
    end
end

function pausemenu13.saveAndQuitGame()
    SFX.play(pausemenu13.saveAndQuitSFX)
    pausemenu13.disableSounds = true
    pausemenu13.isPauseMenuQuittingGame = true
    pausemenu13.showBlackScreen = true
    Audio.SeizeStream(-1)
    Audio.MusicStop()
    Routine.wait(pausemenu13.secondsUntilGameQuits, true)
    Misc.saveGame()
    if pausemenu13.saveAndQuitToBrokenLauncherInstead then
        Misc.exitGame()
    else
        Misc.exitEngine()
    end
end

function pausemenu13.continueGame(canSave)
    if canSave == nil then
        canSave = false
    end
    if canSave then
        Misc.saveGame()
        SFX.play(pausemenu13.saveSFX)
    else
        SFX.play(pausemenu13.pauseMenuCloseSFX)
    end
    pausemenu13.isPauseMenuOpen = false
    pausemenu13.menuPosition = 1
    Misc.unpause()
    pausemenu13.unpauseJumpFailsafe()
end

function pausemenu13.exitLevel()
    SFX.play(pausemenu13.saveAndQuitSFX)
    pausemenu13.disableSounds = true
    pausemenu13.isPauseMenuExitingLevel = true
    pausemenu13.showBlackScreen = true
    Audio.SeizeStream(-1)
    Audio.MusicStop()
    Routine.wait(pausemenu13.secondsUntilLevelExit, true)
    Misc.unpause()
    if not isOverworld then
        if SMWMapIsActive then
            Level.load(smwMap.levelFilename)
        else
            Level.exit()
        end
    else
        pausemenu13.isPauseMenuOpen = false
        pausemenu13.menuPosition = 1
        Misc.unpause()
        pausemenu13.unpauseJumpFailsafe()
    end
end

function pausemenu13.pauseUnpauseGame()
    if pausemenu13.enabled then
        pausemenu13.isPauseMenuOpen = not pausemenu13.isPauseMenuOpen
        if pausemenu13.isPauseMenuOpen then
            Misc.pause()
            SFX.play(pausemenu13.pauseMenuOpenSFX)
        elseif not pausemenu13.isPauseMenuOpen then
            Misc.unpause()
            pausemenu13.menuPosition = 1
            SFX.play(pausemenu13.pauseMenuCloseSFX)
        end
    end
end

function pausemenu13.onKeyboardPressDirect(key, repeated)
    if (Misc.GetKeyState(VK_RETURN, 1) and key == VK_P) and not repeated and Misc.inEditor() then
        pausemenu13.pauseUnpauseGame()
    end
end

function pausemenu13.onInputUpdate()
    for _,p in ipairs(Player.get()) do
        if pausemenu13.isPauseMenuOpen then
            if p.keys.run == KEYS_PRESSED then
                if pausemenu13.menuPosition ~= pausemenu13.maxMenuItems then
                    SFX.play(pausemenu13.menuNavigationToQuitOptionSFX)
                end
                pausemenu13.menuPosition = pausemenu13.maxMenuItems
            end
            if p.keys.up == KEYS_PRESSED then
                pausemenu13.menuPosition = pausemenu13.menuPosition - 1
                if pausemenu13.menuPosition < 1 then
                    pausemenu13.menuPosition = 1
                else
                    SFX.play(pausemenu13.menuNavigationUpSFX)
                end
            end
            if p.keys.down == KEYS_PRESSED then
                pausemenu13.menuPosition = pausemenu13.menuPosition + 1
                if pausemenu13.menuPosition > pausemenu13.maxMenuItems then
                    pausemenu13.menuPosition = pausemenu13.maxMenuItems
                else
                    SFX.play(pausemenu13.menuNavigationDownSFX)
                end
            end
            if p.keys.jump == KEYS_PRESSED then
                for i = 1,pausemenu13.maxMenuItems do
                    if pausemenu13.menuPosition == pausemenu13.menuItems[i][3] then
                        pausemenu13.menuItems[i][2]()
                    end
                end
            end
        end
    end
end

function pausemenu13.onDraw()
    pausemenu13.screenW = camera.width
    pausemenu13.screenH = camera.height
    if pausemenu13.isPauseMenuOpen then
        pausemenu13.menu_left_X = pausemenu13.screenW / 2 - 180 + 62
        Graphics.drawBox{x = pausemenu13.screenW / 2 - 190, y = pausemenu13.screenH / 2 - pausemenu13.menu_box_height / 2, width = 380, height = pausemenu13.menu_box_height, color = Color.black, priority = 6}
        for i = 1,pausemenu13.maxMenuItems do
            textplus.print{text = pausemenu13.menuItems[i][1], x = pausemenu13.menu_left_X, y = pausemenu13.menu_top_Y + (i - 1) * 36, priority = 6.1, xscale = 2, yscale = 2, font = pausemenu13.pauseFont}
        end
        Graphics.drawImageWP(pausemenu13.pauseCursor, pausemenu13.menu_left_X - 20, pausemenu13.menu_top_Y + ((pausemenu13.menuPosition - 1) * 36), 6.1)
    end
    if pausemenu13.showBlackScreen then
        Graphics.drawScreen{priority = 10, color = Color.black}
    end
    if pausemenu13.disableTheDisablingOfSavingWhileCheating then
        Defines.player_hasCheated = false --To make sure all cheats still save the game
    end
end

function pausemenu13.onPauseSEEMod(eventObj)
    isCancelled = eventObj.cancelled
end

function pausemenu13.onPostPauseSEEMod()
    if not pausemenu13.isCancelled and Misc.SEEModFeaturesGetBool() then
        isPauseMenuOpen = not isPauseMenuOpen
        if not Misc.inEditor() then
            pausemenu13.pauseUnpauseGame()
        end
    end
end

return pausemenu13