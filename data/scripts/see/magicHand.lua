--[[
    magicHand (v1.0)
    by Spencer Everly
    
    For the use of placing editor entities onto X2
]]

local magicHand = {}

local textplus = require("textplus")
local newBGOSystem
pcall(function() newBGOSystem = require("see/newBGOSystem") end)

--magicHand cursors
local pathToMagicHandCursors = getSMBXPath().."graphics/hardcoded/"
magicHand.magicHandCursors = {
    [1] = Graphics.sprites.hardcoded["39-0"].img, --blue
    [2] = Graphics.sprites.hardcoded["39-1"].img, --pink
    [3] = Graphics.sprites.hardcoded["39-2"].img, --purple
    [4] = Graphics.sprites.hardcoded["39-3"].img, --black
    [5] = Graphics.sprites.hardcoded["39-4"].img, --red
    [6] = Graphics.sprites.hardcoded["39-5"].img, --yellow
    [7] = Graphics.sprites.hardcoded["39-6"].img, --green
    [8] = Graphics.sprites.hardcoded["39-7"].img, --light-blue
    [9] = Graphics.sprites.hardcoded["42-2"].img, --white
    [10] = Graphics.sprites.hardcoded["42-1"].img, --red-yellow
    [11] = "CUSTOM", --custom
}
local currentMagicHand

--Magic Hand Constants

--Colors
_G.MAGICHAND_BLUE = 1
_G.MAGICHAND_PINK = 2
_G.MAGICHAND_PURPLE = 3
_G.MAGICHAND_BLACK = 4
_G.MAGICHAND_RED = 5
_G.MAGICHAND_YELLOW = 6
_G.MAGICHAND_GREEN = 7
_G.MAGICHAND_LIGHTBLUE = 8
_G.MAGICHAND_WHITE = 9
_G.MAGICHAND_REDYELLOW = 10

--States
_G.MAGICHAND_STATE_NORMAL = 1
_G.MAGICHAND_STATE_ERASE = 2
_G.MAGICHAND_STATE_CHOOSEID = 3
_G.MAGICHAND_STATE_CHOOSEID_LIST = 4

--**SETTINGS**

--Is the library enabled?
magicHand.enable = false
--Is the library on?
magicHand.enableSystem = false
--Enable to see some debug features
magicHand.debug = false
--The state of the magic hand. Normal for most placing activities with an entity, erase for erasing things depending on what entity you have.
magicHand.magicHandState = MAGICHAND_STATE_NORMAL
--Current Menu ID.
magicHand.currentMenuID = 0
--The grid size for placing objects.
magicHand.mainGridSize = 16
--Used for slecting NPCs/Blocks manually.
magicHand.selectedID = 0
--Used for remembering the last ID.
magicHand.rememberedLastID = 0
--The key to use for opening up the magic hand.
magicHand.keyBindingForOpening = VK_Q
--Main drawing priority for drawing things.
magicHand.drawingPriority = 7
--The delay for the mouse to click things.
magicHand.mouseDelay = 15

--**IMAGES, CURSORS**

--Use the color constants above to change the color, or if you want a custom cursor, set the cursor to 11 and see below
magicHand.cursorToUse = MAGICHAND_WHITE
--The image to use for the custom cursor while in the editor. Nil for now.
magicHand.customCursorImg = nil
--The magic hand eraser image.
magicHand.magicHandEraser = Graphics.sprites.hardcoded["42-3"].img
--The invalid NPC/Block symbol to use to indicate that this ID doesn't exist.
magicHand.invalidIDSymbol = Graphics.loadImage(getSMBXPath().."\\graphics\\hardcoded\\hardcoded-1000-1.png")

--**POSITIONS**

--The grid coordinates, depending on the grid size as seen above.
magicHand.gridCoordinates = {}
magicHand.gridCoordinates.x = 0
magicHand.gridCoordinates.y = 0

--The screen coordinates, which get the mouse positions as scene coordinates.
magicHand.screenCoordinates = Colliders.Point(0, 0)
magicHand.screenCoordinates.x = 0
magicHand.screenCoordinates.y = 0

--local values below.

--For the newBGOSystem, checking to see if redirectors exist and tune up the opacity while in magic hand mode.
local redirectorBGOs = table.map{191,192,193,194,195,196,197,198,199,221,222}
local redirectorBGOsNonMapped = {191,192,193,194,195,196,197,198,199,221,222}

--For getting the item properties the frame after it was selected.
local placedItem = Misc.getEditorPlacedItem()
local prePlacedItem

--For toggling on the magicHand via F1.
local toggleBool = false

--Menu areas.
local onMenu = {
    MENU_MAIN = 1,
    MENU_CHOOSEID_MANUAL = 2,
    MENU_HIDDEN = 3,
    MENU_CHOOSEID_LIST = 4,
}

--Colliders stuff.
local placeToNotClickMagicHand = Colliders.Box(0 + camera.x, camera.height - 50 + camera.y, 190, 50)
local mouseCollision = Colliders.Box(magicHand.screenCoordinates.x, magicHand.screenCoordinates.y, 2, 2)
local playerCollision = Colliders.Box(player.x, player.y, player.width, player.height)

--Things for the mouse menus.
local opacityWhenOnAButton = 1
local holdingLeftClick = false
local holdingRightClick = false
local leftClickTimer = 0
local entityMode = 0
local delayMouseClick = magicHand.mouseDelay

local tempIDValue = ""
local dontSpawn = false

--For a... easter egg... :)
local playerEasterEggTimer = 0

--For seeing what NPCs exist in X2.
local validNPCs = {}
local validBlocks = {}
local validBGOs = {}

--Values to replace with new values, when getting properties.
local editorValues = {
    [1] = {oldStr = "ID:", newStr = "id"},
    [2] = {oldStr = "X:", newStr = "x"},
    [3] = {oldStr = "Y:", newStr = "y"},
    [4] = {oldStr = "D:", newStr = "direction"},
    [5] = {oldStr = "FD:", newStr = "friendly"},
    [6] = {oldStr = "NM:", newStr = "dontMove"},
    [7] = {oldStr = "BS:", newStr = "legacyBoss"},
    [8] = {oldStr = "MG:", newStr = "message"},
    [9] = {oldStr = "GE:", newStr = "generatorEnabled"},
    [10] = {oldStr = "GD:", newStr = "generatorDirection"},
    [11] = {oldStr = "GM:", newStr = "generatorWaitTime"},
    [12] = {oldStr = "GT:", newStr = "generatorType"},
    [13] = {oldStr = "LR:", newStr = "currentLayer"},
    [14] = {oldStr = "LA:", newStr = "attachToLayer"},
    [15] = {oldStr = "EA:", newStr = "eventActivate"},
    [16] = {oldStr = "ED:", newStr = "eventDeath"},
    [17] = {oldStr = "ET:", newStr = "eventTalk"},
    [18] = {oldStr = "EE:", newStr = "eventLayerEmpty"},
    [19] = {oldStr = "W:", newStr = "width"},
    [20] = {oldStr = "H:", newStr = "height"},
}

local editorValuesAllValues = {
    ["id"] = 0,
    ["x"] = 0,
    ["y"] = 0,
    ["direction"] = -1,
    ["friendly"] = 0,
    ["dontMove"] = 0,
    ["legacyBoss"] = 0,
    ["message"] = "",
    ["generatorEnabled"] = 0,
    ["generatorDirection"] = 0,
    ["generatorWaitTime"] = 0,
    ["generatorType"] = 1,
    ["currentLayer"] = "Default",
    ["attachToLayer"] = "",
    ["eventActivate"] = "",
    ["eventDeath"] = "",
    ["eventTalk"] = "",
    ["eventLayerEmpty"] = "",
    ["width"] = 0,
    ["height"] = 0,
}

local editorMessageValuesToReplace = {
    [1] = {oldStr = "\\,", newStr = ","},
    [2] = {oldStr = "\\\"", newStr = "\""},
    [3] = {oldStr = "\\n", newStr = "/n"},
    [4] = {oldStr = "\"", newStr = ""},
}

--More stuff for getting the item properties the frame after it was selected.
local timeTillNextChange = 0

--The saved information for the entity.
local savedEditorEntity = {}

--The menu choices for the magic hand.
local menuChoices = {}

--local functions below.

--This splits a string more accurately than using string.split.
local function splitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

--This finds a part of a string from a table.
local function findStringPartFromTable(tbl, value, shouldFindIndex)
    for k,v in ipairs(tbl) do
        if not shouldFindIndex then
            if string.find(v, value) then
                return v
            end
        else
            if string.find(v, value) then
                return k
            end
        end
    end
    return nil
end

--This checks if the magic hand state is MAGICHAND_STATE_NORMAL or MAGICHAND_STATE_ERASE, and sets the cursor based on each one.
local function checkEraseStatusForCursor()
    if magicHand.enableSystem then
        if magicHand.magicHandState == MAGICHAND_STATE_NORMAL then
            if magicHand.cursorToUse < #magicHand.magicHandCursors then
                Misc.setCursor(magicHand.magicHandCursors[magicHand.cursorToUse], 0, 0)
            else
                if magicHand.customCursorImg ~= nil then
                    Misc.setCursor(magicHand.customCursorImg, 0, 0)
                else
                    Misc.setCursor(magicHand.magicHandCursors[MAGICHAND_WHITE], 0, 0)
                end
            end
        elseif magicHand.magicHandState == MAGICHAND_STATE_ERASE then
            Misc.setCursor(magicHand.magicHandEraser, 2, 0)
        end
    end
end

--Converts a number from the entity listing to a boolean.
local function numberToBool(number)
    if number == 0 then
        return false
    else
        return true
    end
end

--Converts a boolean to a number from the entity listing.
local function boolToNumber(number)
    if number then
        return 1
    else
        return 0
    end
end

--Sets spawned settings for an entity.
local function setSpawnedSettings(entity, entitySettings)
    if entitySettings.direction ~= nil then
        entity.direction = entitySettings.direction
    end
    if entitySettings.friendly ~= nil then
        entity.friendly = numberToBool(entitySettings.friendly)
    end
    if entitySettings.dontMove ~= nil then
        entity.dontMove = numberToBool(entitySettings.dontMove)
    end
    if entitySettings.legacyBoss ~= nil then
        entity.legacyBoss = numberToBool(entitySettings.legacyBoss)
    end
    if entitySettings.message ~= nil then
        entity.message = entitySettings.message
    end
    if entitySettings.generatorEnabled ~= nil then
        entity.isGenerator = numberToBool(entitySettings.generatorEnabled)
    end
    if entitySettings.generatorDirection ~= nil then
        entity.generatorDirection = entitySettings.generatorDirection
    end
    if entitySettings.generatorWaitTime ~= nil then
        entity.generatorInterval = entitySettings.generatorWaitTime
    end
    if entitySettings.generatorType ~= nil then
        entity.generatorType = entitySettings.generatorType
    end
    if entitySettings.currentLayer ~= nil then
        entity.layerName = entitySettings.currentLayer
    end
    if entitySettings.attachToLayer ~= nil then
        entity.attachedLayerName = entitySettings.attachToLayer
    end
    if entitySettings.eventActivate ~= nil then
        entity.activateEventName = entitySettings.eventActivate
    end
    if entitySettings.eventDeath ~= nil then
        entity.deathEventName = entitySettings.eventDeath
    end
    if entitySettings.eventTalk ~= nil then
        entity.talkEventName = entitySettings.eventTalk
    end
    if entitySettings.eventLayerEmpty ~= nil then
        entity.noMoreObjInLayer = entitySettings.eventLayerEmpty
    end
end

local function setSpawnedSettingsActual(entity)
    savedEditorEntity.direction = savedEditorEntity.direction
    savedEditorEntity.friendly = boolToNumber(savedEditorEntity.friendly)
    savedEditorEntity.dontMove = boolToNumber(savedEditorEntity.dontMove)
    savedEditorEntity.legacyBoss = boolToNumber(savedEditorEntity.legacyBoss)
    savedEditorEntity.message = savedEditorEntity.message
    savedEditorEntity.generatorEnabled = boolToNumber(savedEditorEntity.isGenerator)
    savedEditorEntity.generatorDirection = savedEditorEntity.generatorDirection
    savedEditorEntity.generatorWaitTime = savedEditorEntity.generatorInterval
    savedEditorEntity.generatorType = savedEditorEntity.generatorType
    savedEditorEntity.currentLayer = savedEditorEntity.layerName
    savedEditorEntity.attachToLayer = savedEditorEntity.attachedLayerName
    savedEditorEntity.eventActivate = savedEditorEntity.activateEventName
    savedEditorEntity.eventDeath = savedEditorEntity.deathEventName
    savedEditorEntity.eventTalk = savedEditorEntity.talkEventName
    savedEditorEntity.eventLayerEmpty = savedEditorEntity.noMoreObjInLayer
end

--This is for calculating the grid positions.
local function ffEqual(i, j)
    return ((i - j > -0.1) and (i - j < 0.1))
end

--The function that calculates magicHand.gridCoordinates.
local function MouseMove()
    local mouseX = Misc.getCursorPosition()[1]
    local mouseY = Misc.getCursorPosition()[2]

    magicHand.gridCoordinates.x = math.floor(mouseX / magicHand.mainGridSize + 0.5) * magicHand.mainGridSize + camera.x
    magicHand.gridCoordinates.y = math.floor(mouseY / magicHand.mainGridSize + 0.5) * magicHand.mainGridSize + camera.y
end

local function hoveringOverArea(x1, y1, width1, height1, x2, y2, width2, height2) --Checks a collision between two things
    return (y1 + height1 >= y2) and
           (y1 <= y2 + height2) and
           (x1 <= x2 + width2) and
           (x1 + width1 >= x2)
end

local function drawBoxChoice(id, x, y, width, height, color, func, menuID)
    if not hoveringOverArea(x, y, width, height, Misc.getCursorPosition()[1], Misc.getCursorPosition()[2], 2, 2) then
        opacityWhenOnAButton = 0.75
    elseif not holdingLeftClick then
        opacityWhenOnAButton = 0.85
    else
        opacityWhenOnAButton = 0.92
    end

    if runOnDelay == nil then
        runOnDelay = false
    end

    Graphics.drawBox{
        x = x,
        y = y,
        width = width,
        height = height,
        color = color..opacityWhenOnAButton,
        priority = magicHand.drawingPriority + 0.5,
    }

    menuChoices[id] = {x = x, y = y, width = width, height = height, color = color, runFunc = func, menuID = menuID}
end

local function goToHandMode()
    SFX.play(74)
    magicHand.rememberedLastID = magicHand.selectedID
    magicHand.selectedID = 0
    magicHand.magicHandState = MAGICHAND_STATE_NORMAL
end

local function goToEraseMode()
    SFX.play(74)
    magicHand.magicHandState = MAGICHAND_STATE_ERASE
end

local function switchEntityMode()
    SFX.play(74)
    SFX.play(73)
    entityMode = entityMode + 1
    if newBGOSystem == nil then
        if entityMode > 2 then
            entityMode = 1
        end
        if entityMode < 1 then
            entityMode = 1
        end
    else
        if entityMode > 3 then
            entityMode = 1
        end
        if entityMode < 1 then
            entityMode = 1
        end
    end
end

local function enterEntityID()
    SFX.play(74)
    SFX.play(47)
    tempIDValue = ""
    magicHand.currentMenuID = onMenu.MENU_CHOOSEID_MANUAL
    magicHand.magicHandState = MAGICHAND_STATE_CHOOSEID
end

local function entityIDList()
    SFX.play(74)
    SFX.play(47)
    magicHand.currentMenuID = onMenu.MENU_CHOOSEID_LIST
    magicHand.magicHandState = MAGICHAND_STATE_CHOOSEID_LIST
end

local function grabEntity(v)
    if entityMode == 1 then
        local id = v.id
        setSpawnedSettingsActual(v)
        v:kill(HARM_TYPE_VANISH)
        SFX.play(23)
        magicHand.selectedID = id
    elseif entityMode == 2 then
        local id = v.id
        setSpawnedSettingsActual(v)
        v:delete()
        SFX.play(23)
        magicHand.selectedID = id
    elseif entityMode == 3 and newBGOSystem then
        local id = v.id
        newBGOSystem.remove(v.idx)
        SFX.play(23)
        magicHand.selectedID = id
    end
end

local function getNPCWidthOrHeight(value, widthOrHeight)
    if widthOrHeight == 1 and NPC.config[value].gfxwidth > 0 then
        return NPC.config[value].gfxwidth
    elseif widthOrHeight == 1 and NPC.config[value].gfxwidth <= 0 then
        return NPC.config[value].width
    elseif widthOrHeight == 2 and NPC.config[value].gfxheight > 0 then
        return NPC.config[value].gfxheight
    elseif widthOrHeight == 2 and NPC.config[value].gfxheight <= 0 then
        return NPC.config[value].height
    end
end

local function showMenu()
    SFX.play(74)
    magicHand.currentMenuID = onMenu.MENU_MAIN
end

local function hideMenu()
    SFX.play(74)
    magicHand.currentMenuID = onMenu.MENU_HIDDEN
end

local function getMenuDimensionsForColliders()
    if magicHand.currentMenuID == onMenu.MENU_MAIN then
        return Colliders.Box(0 + camera.x, camera.height - 50 + camera.y, 190, 50)
    elseif magicHand.currentMenuID == onMenu.MENU_HIDDEN then
        return Colliders.Box(0 + camera.x, camera.height - 8 + camera.y, 190, 8)
    end
end

--The toggle used to either enable the magic hand, or not.
function magicHand.toggle(enabled, cursorColor)
    local boolWasNil = false

    if enabled == nil then
        enabled = false
        boolWasNil = true
    end
    if cursorColor == nil then
        cursorColor = MAGICHAND_WHITE
    end
    
    if type(cursorColor) == "number" then
        if cursorColor > #magicHand.magicHandCursors then
            error("Must specify a valid cursor color (Up to "..tostring(#magicHand.magicHandCursors)..")")
            return
        end
    end

    if enabled and not boolWasNil then
        if type(cursorColor) == "number" and cursorColor < #magicHand.magicHandCursors then
            magicHand.cursorToUse = cursorColor
            Misc.setCursor(magicHand.magicHandCursors[cursorColor], 0, 0)
        elseif type(cursorColor) == "string" then
            magicHand.cursorToUse = 11
            magicHand.customCursorImg = Graphics.loadImage(cursorColor)
            Misc.setCursor(magicHand.customCursorImg, 0, 0)
        end
        magicHand.currentMenuID = onMenu.MENU_MAIN
        magicHand.enableSystem = true
        if newBGOSystem then
            for k,v in ipairs(newBGOSystem.get(redirectorBGOsNonMapped)) do
                if redirectorBGOs[v.id] then
                    v.opacity = 0.5
                end
            end
        end
    elseif not enabled and not boolWasNil then
        Misc.setCursor(nil)
        magicHand.enableSystem = false
        magicHand.currentMenuID = 0
        if newBGOSystem then
            for k,v in ipairs(newBGOSystem.get(redirectorBGOsNonMapped)) do
                if redirectorBGOs[v.id] then
                    v.opacity = 0
                end
            end
        end
    end
end

--The main function that gets the entity information. Don't call this a lot on onTick/onDraw for a long time, otherwise the game will crash due to an overflow.
function magicHand.checkEditorEntity()
    if Misc.inEditor() then
        prePlacedItem = Misc.getEditorPlacedItem()
        
        if prePlacedItem == "nil" then
            return {}
        end

        local draftTable = {}
        local finalTable = {}

        local splitValues

        local tbl = json.decode(prePlacedItem)
        for values in tbl.sendItemPlacing:gmatch("([^\n]+)") do 
            table.insert(draftTable, values)
        end
        if (draftTable[1] ~= "nil" and draftTable[1] ~= nil) then
            splitValues = splitString(draftTable[2], ";")

            for i = 1,#editorValues do
                local tempValue = editorValues[i]
                local tempIndex = findStringPartFromTable(splitValues, editorValues[i].oldStr, true)
                if tempIndex ~= nil then
                    local tempStr = string.gsub(splitValues[tempIndex], editorValues[i].oldStr, "")
                    draftTable[tempValue.newStr] = tempStr
                end
            end
            
            if draftTable.id == nil then
                draftTable.id = editorValuesAllValues["id"]
            end
            
            if draftTable[1] == "NPC" then
                if draftTable.direction == nil then
                    draftTable.direction = editorValuesAllValues["direction"]
                end
                if draftTable.friendly == nil then
                    draftTable.friendly = editorValuesAllValues["friendly"]
                end
                if draftTable.dontMove == nil then
                    draftTable.dontMove = editorValuesAllValues["dontMove"]
                end
                if draftTable.legacyBoss == nil then
                    draftTable.legacyBoss = editorValuesAllValues["legacyBoss"]
                end
                if draftTable.generatorEnabled == nil then
                    draftTable.generatorEnabled = editorValuesAllValues["generatorEnabled"]
                end
                if draftTable.generatorDirection == nil then
                    draftTable.generatorDirection = editorValuesAllValues["generatorDirection"]
                end
                if draftTable.generatorWaitTime == nil then
                    draftTable.generatorWaitTime = editorValuesAllValues["generatorWaitTime"]
                end
                if draftTable.generatorType == nil then
                    draftTable.generatorType = editorValuesAllValues["generatorType"]
                end
            end
            
            if draftTable[1] == "BLOCK" then
                if draftTable.width == nil then
                    draftTable.width = editorValuesAllValues["width"]
                end
                
                if draftTable.height == nil then
                    draftTable.height = editorValuesAllValues["height"]
                end
            end
            
            for i = 1,#editorMessageValuesToReplace do
                if draftTable[1] == "NPC" then
                    if draftTable.message ~= nil then
                        draftTable.message = string.gsub(draftTable.message, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.message = editorValuesAllValues["message"]
                    end
                    if draftTable.eventActivate ~= nil then
                        draftTable.eventActivate = string.gsub(draftTable.eventActivate, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.eventActivate = editorValuesAllValues["eventActivate"]
                    end
                    if draftTable.eventDeath ~= nil then
                        draftTable.eventDeath = string.gsub(draftTable.eventDeath, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.eventDeath = editorValuesAllValues["eventDeath"]
                    end
                    if draftTable.eventTalk ~= nil then
                        draftTable.eventTalk = string.gsub(draftTable.eventTalk, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.eventTalk = editorValuesAllValues["eventTalk"]
                    end
                    if draftTable.eventLayerEmpty ~= nil then
                        draftTable.eventLayerEmpty = string.gsub(draftTable.eventLayerEmpty, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.eventLayerEmpty = editorValuesAllValues["eventLayerEmpty"]
                    end
                    if draftTable.attachToLayer ~= nil then
                        draftTable.attachToLayer = string.gsub(draftTable.attachToLayer, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                    else
                        draftTable.attachToLayer = editorValuesAllValues["attachToLayer"]
                    end
                end
                
                if draftTable.currentLayer ~= nil then
                    draftTable.currentLayer = string.gsub(draftTable.currentLayer, editorMessageValuesToReplace[i].oldStr, editorMessageValuesToReplace[i].newStr)
                else
                    draftTable.currentLayer = editorValuesAllValues["currentLayer"]
                end
            end
            
            finalTable = {
                entityType = draftTable[1],
                id = tonumber(draftTable.id),
                x = tonumber(draftTable.x),
                y = tonumber(draftTable.y),
                width = tonumber(draftTable.width),
                height = tonumber(draftTable.height),
                direction = tonumber(draftTable.direction),
                friendly = tonumber(draftTable.friendly),
                dontMove = tonumber(draftTable.dontMove),
                legacyBoss = tonumber(draftTable.legacyBoss),
                message = draftTable.message,
                generatorEnabled = tonumber(draftTable.generatorEnabled),
                generatorDirection = tonumber(draftTable.generatorDirection),
                generatorWaitTime = tonumber(draftTable.generatorWaitTime),
                generatorType = tonumber(draftTable.generatorType),
                currentLayer = draftTable.currentLayer,
                attachToLayer = draftTable.attachToLayer,
                eventActivate = draftTable.eventActivate,
                eventDeath = draftTable.eventDeath,
                eventTalk = draftTable.eventTalk,
                eventLayerEmpty = draftTable.eventLayerEmpty,
            }

            return finalTable

        else
            return {}
        end
    else
        return {}
    end
end

function magicHand.onInitAPI()
    registerEvent(magicHand,"onStart")
    registerEvent(magicHand,"onTick")
    registerEvent(magicHand,"onDrawEnd")
    registerEvent(magicHand,"onDraw")
    registerEvent(magicHand,"onExit")
    registerEvent(magicHand,"onMouseButtonEvent")
    registerEvent(magicHand,"onMouseWheelEvent")
    registerEvent(magicHand,"onKeyboardKeyPress")
    registerEvent(magicHand,"onKeyboardPressDirect")
    
    if Misc.inEditor() then
        magicHand.enable = true
    end
end

_G.MAX_NPCS = 2000
_G.MAX_BLOCKS = 2000

function magicHand.onStart()
    --We need to generate valid NPCs/Blocks for us to get everything in order
    for i = 1, NPC_MAX_ID do
        if Graphics.sprites.npc[i].img ~= nil then
            table.insert(validNPCs, i, -1)
        end
    end
    for i = 1, BLOCK_MAX_ID do
        if Graphics.sprites.block[i].img ~= nil then
            table.insert(validBlocks, i, -1)
        end
    end
    for i = 1, BGO_MAX_ID do
        if Graphics.sprites.background[i].img ~= nil then
            table.insert(validBGOs, i, -1)
        end
    end
end

function magicHand.onMouseWheelEvent(wheel, delta)
    if magicHand.enableSystem then
        if wheel == 0 then
            if delta == 120 then
                magicHand.selectedID = magicHand.selectedID + 1
            elseif delta == -120 then
                magicHand.selectedID = magicHand.selectedID - 1
            end
        end
    end
end

local numberKeys = table.map{
    VK_0,VK_1,VK_2,VK_3,VK_4,VK_5,VK_6,VK_7,VK_8,VK_9,VK_0,96,97,98,99,100,101,102,103,104,105,
}

function magicHand.onKeyboardPressDirect(keyCode, isHolding, chara)
    if magicHand.magicHandState == MAGICHAND_STATE_CHOOSEID then
        if numberKeys[keyCode] then
            tempIDValue = tempIDValue..tostring(chara)
        end

        if keyCode == 8 then --Backspace key
            tempIDValue = tempIDValue:sub(1, -2)
        end
        
        if keyCode == 13 then --Enter key
            magicHand.rememberedLastID = magicHand.selectedID
            magicHand.selectedID = tonumber(tempIDValue)
            tempIDValue = ""
            Misc.unpause()
            magicHand.currentMenuID = onMenu.MENU_MAIN
            magicHand.magicHandState = MAGICHAND_STATE_NORMAL
        end
    end
end

function magicHand.onKeyboardKeyPress(virtualKey, strKey)
    if virtualKey == magicHand.keyBindingForOpening then
        toggleBool = not toggleBool
        magicHand.toggle(toggleBool)
        if toggleBool then
            if SMBX_VERSION == VER_SEE_MOD then --Misc.runWhenUnfocused isn't in Beta 5 yet
                Misc.runWhenUnfocused(true)
            end
            SFX.play("sound/extended/toggle-on-magicHand.ogg")
        else
            if SMBX_VERSION == VER_SEE_MOD then
                Misc.runWhenUnfocused(false)
            end
            SFX.play("sound/extended/toggle-off-magicHand.ogg")
        end
    end
end

function magicHand.onDrawEnd()
    if timeTillNextChange == 1 then
        --Make sure that we only get the entity when the item changes ONCE, otherwise Lua will overflow when this is ran a lot
        savedEditorEntity = magicHand.checkEditorEntity()
        magicHand.rememberedLastID = magicHand.selectedID
        magicHand.selectedID = savedEditorEntity.id
        if savedEditorEntity.entityType == "NPC" then
            entityMode = 1
        elseif savedEditorEntity.entityType == "BLOCK" then
            entityMode = 2
        elseif savedEditorEntity.entityType == "BGO" and newBGOSystem then
            entityMode = 3
        else
            entityMode = 1
            magicHand.selectedID = 0
        end
    end

    timeTillNextChange = timeTillNextChange + 1
    placedItem = Misc.getEditorPlacedItem()

    if prePlacedItem ~= placedItem then
        prePlacedItem = Misc.getEditorPlacedItem()
        timeTillNextChange = 0
    end
end

--[[

button:
    0 = Left click
    1 = Right click

state:
    0 = Clicking only once
    1 = Holding the mouse click

]]

local function LeftClickStuff()
    if magicHand.selectedID == 0 and magicHand.currentMenuID == onMenu.MENU_MAIN then
        if magicHand.magicHandState == MAGICHAND_STATE_NORMAL and not Colliders.collide(placeToNotClickMagicHand, mouseCollision) then
            if entityMode == 1 then --NPC
                for k,v in ipairs(NPC.get()) do
                    if Colliders.collide(v, mouseCollision) then
                        grabEntity(v)
                    end
                end
            elseif entityMode == 2 then --BLOCK
                for k,v in ipairs(Block.get()) do
                    if Colliders.collide(v, mouseCollision) then
                        grabEntity(v)
                    end
                end
            elseif entityMode == 3 and newBGOSystem then --BGO
                for k,v in ipairs(BGO.get()) do
                    if Colliders.collide(v, mouseCollision) then
                        grabEntity(v)
                    end
                end
            end
        end
    elseif magicHand.selectedID > 0 then
        if magicHand.magicHandState == MAGICHAND_STATE_NORMAL and not Colliders.collide(placeToNotClickMagicHand, mouseCollision) then
            if not dontSpawn then
                if entityMode == 1 and validNPCs[magicHand.selectedID] ~= nil and validNPCs[magicHand.selectedID] == -1 then --NPC
                    local spawnedNPC = NPC.spawn(magicHand.selectedID, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y, player.section)
                    setSpawnedSettings(spawnedNPC, savedEditorEntity)
                elseif entityMode == 2 and validBlocks[magicHand.selectedID] ~= nil and validBlocks[magicHand.selectedID] == -1 then --Block
                    local spawnedBlock = Block.spawn(magicHand.selectedID, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y)
                    setSpawnedSettings(spawnedBlock, savedEditorEntity)
                elseif entityMode == 3 and validBGOs[magicHand.selectedID] ~= nil and validBGOs[magicHand.selectedID] == -1 and newBGOSystem then --BGO, only supported on newBGOSystem
                    newBGOSystem.spawn(magicHand.selectedID, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y)
                end
            end
        end
    end
end

function magicHand.onMouseButtonEvent(button, state)
    if magicHand.enableSystem then
        placeToNotClickMagicHand = getMenuDimensionsForColliders()
        mouseCollision = Colliders.Box(magicHand.screenCoordinates.x, magicHand.screenCoordinates.y, 2, 2)
        if button == 1 and state == 1 then --Clicking the right-clicker on the mouse
            holdingRightClick = true
            if magicHand.magicHandState == MAGICHAND_STATE_ERASE then
                local tempID = 0
                tempID = magicHand.selectedID
                magicHand.selectedID = magicHand.rememberedLastID
                magicHand.rememberedLastID = tempID
                magicHand.magicHandState = MAGICHAND_STATE_NORMAL
            end
        elseif button == 1 and state == 0 then --Not clicking the right-clicker on the mouse
            holdingRightClick = false
        end

        if button == 0 and state == 1 then --Clicking the left-clicker on the mouse
            holdingLeftClick = true
            if delayMouseClick == 0 then
                for i = 1,#menuChoices do
                    if hoveringOverArea(menuChoices[i].x, menuChoices[i].y, menuChoices[i].width, menuChoices[i].height, Misc.getCursorPosition()[1], Misc.getCursorPosition()[2], 2, 2) then
                        if menuChoices[i].runFunc ~= nil and menuChoices[i].menuID == magicHand.currentMenuID then
                            Routine.run(menuChoices[i].runFunc)
                            delayMouseClick = magicHand.mouseDelay
                        end
                    end
                end
            end
            LeftClickStuff()
        elseif button == 0 and state == 0 then --Not clicking the leftclicker on the mouse
            holdingLeftClick = false
            timer = 0
        end
    end
end

function magicHand.onDraw()
    if magicHand.enableSystem then
        --used to delay running functions
        if delayMouseClick > 0 then
            delayMouseClick = delayMouseClick - 1
        end

        --used to get the scene space coordinates for the cursor position
        magicHand.screenCoordinates.x = (Misc.getCursorPosition()[1] + camera.x)
        magicHand.screenCoordinates.y = (Misc.getCursorPosition()[2] + camera.y)

        --used to get the coordinates based on the grid count
        MouseMove()

        --these are used for erasing entities
        checkEraseStatusForCursor()
        
        if newBGOSystem == nil then
            if entityMode > 2 then
                entityMode = 1
            end
            if entityMode < 1 then
                entityMode = 1
            end
        else
            if entityMode > 3 then
                entityMode = 1
            end
            if entityMode < 1 then
                entityMode = 1
            end
        end

        --these are used for the magic hand main menu
        if magicHand.currentMenuID == onMenu.MENU_MAIN then
            --Menu bar
            Graphics.drawBox{
                x = 0,
                y = camera.height - 50,
                width = 190,
                height = 50,
                color = Color.lightgray..0.45,
                priority = magicHand.drawingPriority,
            }

            --Choice boxes

            --Selector
            drawBoxChoice(1, 10, camera.height - 40, 36, 36, Color.darkgray, goToHandMode, magicHand.currentMenuID)
            Graphics.drawImageWP(magicHand.magicHandCursors[MAGICHAND_WHITE], 12, camera.height - 34, magicHand.drawingPriority + 0.6)

            --Eraser
            drawBoxChoice(2, 50, camera.height - 40, 36, 36, Color.darkgray, goToEraseMode, magicHand.currentMenuID)
            Graphics.drawImageWP(magicHand.magicHandEraser, 56, camera.height - 36, magicHand.drawingPriority + 0.6)

            --Entity selector
            drawBoxChoice(3, 90, camera.height - 40, 36, 36, Color.darkgray, switchEntityMode, magicHand.currentMenuID)
            if entityMode == 1 then
                Graphics.drawImageWP(Graphics.sprites.npc[1].img, 92, camera.height - 38, 0, 0, NPC.config[1].width, NPC.config[1].height, magicHand.drawingPriority + 0.6)
            elseif entityMode == 2 then
                Graphics.drawImageWP(Graphics.sprites.block[1].img, 92, camera.height - 38, 0, 0, Block.config[1].width, Block.config[1].height, magicHand.drawingPriority + 0.6)
            elseif entityMode == 3 and newBGOSystem then
                Graphics.drawImageWP(Graphics.sprites.background[1].img, 92, camera.height - 38, 0, 0, BGO.config[1].width, BGO.config[1].height, magicHand.drawingPriority + 0.6)
            end

            --ID selector
            drawBoxChoice(4, 130, camera.height - 40, 36, 36, Color.darkgray, entityIDList, magicHand.currentMenuID)
            textplus.print{x = 139, y = camera.height - 31, text = "ID", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}

            --Hide menu button
            textplus.print{x = 88, y = camera.height - 50, text = "^", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
            drawBoxChoice(5, 0, camera.height - 50, 190, 8, Color.lightgray, hideMenu, magicHand.currentMenuID)
        elseif magicHand.currentMenuID == onMenu.MENU_CHOOSEID_MANUAL then
            if magicHand.magicHandState == MAGICHAND_STATE_CHOOSEID then
                Graphics.drawBox{
                    x = (camera.width / 2) - 140,
                    y = (camera.height / 2) - 140,
                    width = 280,
                    height = 120,
                    color = Color.lightbrown..0.45,
                    priority = magicHand.drawingPriority,
                }

                textplus.print{x = (camera.width / 2) - 130, y = (camera.height / 2) - 130, text = "Enter the ID using the", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
                textplus.print{x = (camera.width / 2) - 130, y = (camera.height / 2) - 108, text = "numbers on your keyboard.", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
                
                textplus.print{x = (camera.width / 2) - 130, y = (camera.height / 2) - 70, text = tempIDValue, xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
                
                local tempIDValueNum = tonumber(tempIDValue)
                
                if (tempIDValueNum ~= nil and tempIDValueNum > 0) then
                    if entityMode == 1 then
                        if validNPCs[tempIDValueNum] ~= nil and validNPCs[tempIDValueNum] == -1 then
                            local npcImg = Graphics.sprites.npc[tempIDValueNum].img
                            
                            if npcImg ~= nil then
                                Graphics.drawImageWP(npcImg, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, getNPCWidthOrHeight(tempIDValueNum, 1), getNPCWidthOrHeight(tempIDValueNum, 2), 0.5, magicHand.drawingPriority + 1)
                                dontSpawn = false
                            else
                                dontSpawn = true
                            end
                        else
                            dontSpawn = false
                            Graphics.drawImageWP(magicHand.invalidIDSymbol, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, magicHand.invalidIDSymbol.width, magicHand.invalidIDSymbol.height, 0.5, magicHand.drawingPriority + 1)
                        end
                    elseif entityMode == 2 then
                        if validBlocks[tempIDValueNum] ~= nil and validBlocks[tempIDValueNum] == -1 then
                            local blockImg = Graphics.sprites.block[tempIDValueNum].img
                            
                            if blockImg ~= nil then
                                Graphics.drawImageWP(blockImg, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, Block.config[tempIDValueNum].width, Block.config[tempIDValueNum].height, 0.5, magicHand.drawingPriority + 1)
                                dontSpawn = false
                            else
                                dontSpawn = true
                            end
                        else
                            dontSpawn = false
                            Graphics.drawImageWP(magicHand.invalidIDSymbol, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, magicHand.invalidIDSymbol.width, magicHand.invalidIDSymbol.height, 0.5, magicHand.drawingPriority + 1)
                        end
                    elseif entityMode == 3 and newBGOSystem then
                        if validBGOs[tempIDValueNum] ~= nil and validBGOs[tempIDValueNum] == -1 then
                            local bgoImg = Graphics.sprites.background[tempIDValueNum].img
                            
                            if bgoImg ~= nil then
                                Graphics.drawImageWP(bgoImg, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, BGO.config[tempIDValueNum].width, BGO.config[tempIDValueNum].height, 0.5, magicHand.drawingPriority + 1)
                                dontSpawn = false
                            else
                                dontSpawn = true
                            end
                        else
                            dontSpawn = false
                            Graphics.drawImageWP(magicHand.invalidIDSymbol, (camera.width / 2) - 40, (camera.height / 2) - 70, 0, 0, magicHand.invalidIDSymbol.width, magicHand.invalidIDSymbol.height, 0.5, magicHand.drawingPriority + 1)
                        end
                    end
                end
            end
        elseif magicHand.currentMenuID == onMenu.MENU_HIDDEN then
            --Show menu button
            textplus.print{x = 88, y = camera.height - 8, text = "^", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
            drawBoxChoice(6, 0, camera.height - 8, 190, 8, Color.lightgray, showMenu, magicHand.currentMenuID)
        elseif magicHand.currentMenuID == onMenu.MENU_CHOOSEID_LIST then
            if magicHand.magicHandState == MAGICHAND_STATE_CHOOSEID_LIST then
                textplus.print{x = (camera.width / 2) - 85, y = (camera.height / 2) - 110, text = "Choose ID manually", xscale = 2, yscale = 2, priority = magicHand.drawingPriority + 0.6}
                drawBoxChoice(7, (camera.width / 2) - 140, (camera.height / 2) - 140, 280, 90, Color.teal, enterEntityID, magicHand.currentMenuID)
            end
        end
        
        if magicHand.debug then
            Text.print("GRIDX: "..tostring(magicHand.gridCoordinates.x), 100, 100)
            Text.print("GRIDY: "..tostring(magicHand.gridCoordinates.y), 100, 120)

            Text.print("MOUSEX: "..tostring(Misc.getCursorPosition()[1]), 100, 160)
            Text.print("MOUSEY: "..tostring(Misc.getCursorPosition()[2]), 100, 180)
        end
    end
end

function magicHand.onTick()
    if magicHand.enableSystem then
        placeToNotClickMagicHand = getMenuDimensionsForColliders()
        mouseCollision = Colliders.Box(magicHand.screenCoordinates.x, magicHand.screenCoordinates.y, 2, 2)
        playerCollision = Colliders.Box(player.x, player.y, player.width, player.height)
        if (savedEditorEntity ~= {}) then
            if entityMode == 1 then
                savedEditorEntity.entityType = "NPC"
            elseif entityMode == 2 then
                savedEditorEntity.entityType = "BLOCK"
            elseif entityMode == 3 and newBGOSystem then
                savedEditorEntity.entityType = "BGO"
            end
            if (magicHand.selectedID ~= nil and magicHand.selectedID > 0) then
                if magicHand.magicHandState == MAGICHAND_STATE_NORMAL and not Colliders.collide(placeToNotClickMagicHand, mouseCollision) then
                    if savedEditorEntity.entityType == "NPC" and validNPCs[magicHand.selectedID] ~= nil and validNPCs[magicHand.selectedID] == -1 then --NPC
                        local npcImg = Graphics.sprites.npc[magicHand.selectedID].img
                        
                        if npcImg ~= nil then
                            Graphics.drawImageToSceneWP(npcImg, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y, 0, 0, getNPCWidthOrHeight(magicHand.selectedID, 1), getNPCWidthOrHeight(magicHand.selectedID, 2), 0.5, magicHand.drawingPriority + 1)
                            dontSpawn = false
                        else
                            dontSpawn = true
                        end
                    elseif savedEditorEntity.entityType == "BLOCK" and validBlocks[magicHand.selectedID] ~= nil and validBlocks[magicHand.selectedID] == -1 then
                        local blockImg = Graphics.sprites.block[magicHand.selectedID].img
                        
                        if blockImg ~= nil then
                            Graphics.drawImageToSceneWP(blockImg, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y, 0, 0, Block.config[magicHand.selectedID].width, Block.config[magicHand.selectedID].height, 0.5, magicHand.drawingPriority + 1)
                            dontSpawn = false
                        else
                            dontSpawn = true
                        end
                    elseif savedEditorEntity.entityType == "BGO" and newBGOSystem then --Only supported with the newBGOSystem
                        local bgoImg = Graphics.sprites.background[magicHand.selectedID].img
                        
                        if bgoImg ~= nil then
                            Graphics.drawImageToSceneWP(bgoImg, magicHand.gridCoordinates.x, magicHand.gridCoordinates.y, 0, 0, BGO.config[magicHand.selectedID].width, BGO.config[magicHand.selectedID].height, 0.5, magicHand.drawingPriority + 1)
                            dontSpawn = false
                        else
                            dontSpawn = true
                        end
                    end
                    if holdingLeftClick then
                        leftClickTimer = leftClickTimer + 1
                        if leftClickTimer == 1 then
                            
                        end
                    else
                        leftClickTimer = 0
                    end
                end
            elseif magicHand.selectedID < 0 then
                magicHand.selectedID = 0
            end
            
            if magicHand.selectedID > 0 then
                if entityMode == 1 then
                    if validNPCs[magicHand.selectedID] == nil then
                        magicHand.selectedID = magicHand.selectedID + 1
                        if magicHand.selectedID > #validNPCs then
                            magicHand.selectedID = 0
                        end
                    end
                elseif entityMode == 2 then
                    if validBlocks[magicHand.selectedID] == nil then
                        magicHand.selectedID = magicHand.selectedID + 1
                        if magicHand.selectedID > #validBlocks then
                            magicHand.selectedID = 0
                        end
                    end
                elseif entityMode == 3 and newBGOSystem then
                    if validBGOs[magicHand.selectedID] == nil then
                        magicHand.selectedID = magicHand.selectedID + 1
                        if magicHand.selectedID > #validBGOs then
                            magicHand.selectedID = 0
                        end
                    end
                end
            end

            if magicHand.magicHandState == MAGICHAND_STATE_ERASE and not Colliders.collide(placeToNotClickMagicHand, mouseCollision) then
                if holdingLeftClick then
                    local rngSpark = RNG.randomInt(1,20)
                    local rngSparkMovement = RNG.randomInt(1,1.2)
                    
                    local randomValue = RNG.randomInt(1,6) - 1
                    
                    if randomValue >= 2 then
                        local spark = Effect.spawn(80, magicHand.screenCoordinates.x, magicHand.screenCoordinates.y, player.section, false, true)
                        spark.speedX = LegacyRNG.generateNumber() * 4 - 2
                        spark.speedY = LegacyRNG.generateNumber() * 4 - 2
                    end
                    
                    if entityMode == 1 then --NPC
                        local hitNPCs = Colliders.getColliding{a = magicHand.screenCoordinates, b = hitNPCs, btype = Colliders.NPC}
                        
                        for _,npc in ipairs(hitNPCs) do
                            if not NPC.config[npc.id].iscoin then
                                npc:kill()
                            else
                                local effect = Effect.spawn(78, npc.x, npc.y, player.section, false, true)
                                npc:kill()
                            end
                        end
                    elseif entityMode == 2 then --Block
                        local hitBlocks = Colliders.getColliding{a = magicHand.screenCoordinates, b = hitBlocks, btype = Colliders.BLOCK}
                        
                        for _,block in ipairs(hitBlocks) do
                            block:remove(true)
                        end
                    elseif entityMode == 3 then --BGO, only supported on newBGOSystem
                        if newBGOSystem then
                            for k,v in ipairs(newBGOSystem.get()) do
                                local mouseCollision = Colliders.Box(magicHand.screenCoordinates.x, magicHand.screenCoordinates.y, 10, 10)
                                local bgoCollision = Colliders.Box(v.x, v.y, v.width, v.height)
                                if Colliders.collide(mouseCollision, bgoCollision) then
                                    Effect.spawn(10, v.x - (BGO.config[v.id].width * 0.5), v.y - (BGO.config[v.id].height))
                                    newBGOSystem.remove(v.idx)
                                    SFX.play(36)
                                end
                            end
                        end
                    end
                    if Colliders.collide(mouseCollision, playerCollision) then
                        if magicHand.debug then
                            Text.print("Player hurt impact: "..tostring(playerEasterEggTimer), 100, 200)
                        end
                        playerEasterEggTimer = playerEasterEggTimer + 1
                        if playerEasterEggTimer >= 2000 then
                            playerEasterEggTimer = 1000
                            SFX.play(76)
                            player:harm()
                        end
                    else
                        playerEasterEggTimer = 0
                    end
                else
                    leftClickTimer = 0
                end
            end
        end
    end
end

function magicHand.onExit()
    if magicHand.enableSystem and toggleBool then
        magicHand.toggle(false)
    end
end

return magicHand