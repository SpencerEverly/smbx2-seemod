--noTurnBack2.lua (v2.0)
--By Spencer Everly
--This script provides a remake of the noTurnBack option, but with additional things!

local noTurnBack2 = {}

local autoscroll = require("autoscroll")

_G.NOTURNBACK2_LEFT = "left"
_G.NOTURNBACK2_RIGHT = "right"
_G.NOTURNBACK2_UP = "up"
_G.NOTURNBACK2_DOWN = "down"
_G.NOTURNBACK2_TOPLEFT = "topleft"
_G.NOTURNBACK2_TOPRIGHT = "topright"
_G.NOTURNBACK2_BOTTOMLEFT = "bottomleft"
_G.NOTURNBACK2_BOTTOMRIGHT = "bottomright"

local levelFilename

if not isOverworld then
    levelFilename = Level.filename()
end

noTurnBack2.enabled = false --Enable this to activate everything here
noTurnBack2.turnBackSections = {}
noTurnBack2.turnBackSections[levelFilename] = {}
for i = 1,21 do
    noTurnBack2.turnBackSections[levelFilename][i] = false
end
noTurnBack2.overrideSection = false --Set to true to prevent the turn back on a certain area, useful for onLoadSection(number)
noTurnBack2.turnBack = NOTURNBACK2_LEFT --Check the global numbers above for which direction you want to have a noturnback on

local function setSectionBounds(section, left, top, bottom, right)
    local sectionObj = Section(section)
    local bounds = sectionObj.boundary
    bounds.left = left
    bounds.top = top
    bounds.bottom = bottom
    bounds.right = right
    sectionObj.boundary = bounds
end

function noTurnBack2.onInitAPI()
    registerEvent(noTurnBack2,"onStart")
    registerEvent(noTurnBack2,"onCameraDraw")
    registerEvent(noTurnBack2,"onCameraUpdate")
    registerEvent(noTurnBack2,"onDraw")
    registerEvent(noTurnBack2,"onTick")
end

noTurnBack2.originalBoundariesTop = {}
noTurnBack2.originalBoundariesBottom = {}
noTurnBack2.originalBoundariesLeft = {}
noTurnBack2.originalBoundariesRight = {}

noTurnBack2.failsafeTable = {
    1,
    2,
    3,
    4,
}

function noTurnBack2.onStart()
    for i = 0,20 do
        table.insert(noTurnBack2.originalBoundariesTop, Section(i).origBoundary.top)
        table.insert(noTurnBack2.originalBoundariesBottom, Section(i).origBoundary.bottom)
        table.insert(noTurnBack2.originalBoundariesLeft, Section(i).origBoundary.left)
        table.insert(noTurnBack2.originalBoundariesRight, Section(i).origBoundary.right)
    end
end

function noTurnBack2.onCameraUpdate()
    if not SaveData.SMASPlusPlus.game.onePointThreeModeActivated then
        for k,v in ipairs(Section.getActiveIndices()) do
            if not autoscroll.isSectionScrolling(v) then
                if noTurnBack2.enabled and not noTurnBack2.overrideSection then
                    for itwo = 1,4 do
                        if noTurnBack2.turnBack ~= noTurnBack2.failsafeTable[itwo] then --Failsafe if the turnBack argument is anything else but the things in this script
                            noTurnBack2.turnBack = "left"
                        end
                    end
                    if noTurnBack2.turnBack == "left" then
                        local fullX = camera.x
                        if camera.x >= player.sectionObj.boundary.left then
                            local x1 = fullX
                            noTurnBack2.setSectionBounds(player.section, x1, player.sectionObj.boundary.top, player.sectionObj.boundary.bottom, player.sectionObj.boundary.right)
                        end
                    elseif noTurnBack2.turnBack == "right" then
                        local fullX = camera.x
                        if camera.x <= player.sectionObj.boundary.right then
                            local x1 = fullX + 800
                            noTurnBack2.setSectionBounds(player.section, player.sectionObj.boundary.left, player.sectionObj.boundary.top, player.sectionObj.boundary.bottom, x1)
                        end
                    elseif noTurnBack2.turnBack == "up" then
                        local fullY = camera.y
                        if camera.y >= player.sectionObj.boundary.top then
                            local x1 = fullY
                            noTurnBack2.setSectionBounds(player.section, player.sectionObj.boundary.left, x1, player.sectionObj.boundary.bottom, player.sectionObj.boundary.right)
                        end
                    elseif noTurnBack2.turnBack == "down" then
                        local fullY = camera.y
                        if camera.y <= player.sectionObj.boundary.bottom then
                            local x1 = fullY + 600
                            noTurnBack2.setSectionBounds(player.section, player.sectionObj.boundary.left, player.sectionObj.boundary.top, x1, player.sectionObj.boundary.right)
                        end
                    end
                end
            else
                noTurnBack2.enabled = false
                noTurnBack2.overrideSection = true
            end
        end
    end
end

local levelTablesWithNoTurnbacks = {
    "levelsGoHere.lvlx",
    "youCanPutAnything.lvlx",
    "inThisTable.lvlx",
    "thatCanHaveANoTurnBack.lvlx",
}

function noTurnBack2.onTick() --If you want a certain level or more, make a table with level filenames on it. A sample table is included above.
    --This is a sample table used for applying no-turn-backs on levels.
    --if table.icontains(levelTablesWithNoTurnbacks,Level.filename()) and not noTurnBack2.overrideSection then
        --noTurnBack2.enabled = true
    --end
    
    
    --These here are episode specific.
    if table.icontains(smasTables.__smb1Levels,Level.filename()) and not noTurnBack2.overrideSection then
        noTurnBack2.enabled = true
    end
    if table.icontains(smasTables.__smbllLevels,Level.filename()) and not noTurnBack2.overrideSection then
        noTurnBack2.enabled = true
    end
    if table.icontains(smasTables.__smbspecialLevels,Level.filename()) and not noTurnBack2.overrideSection then
        noTurnBack2.enabled = true
    end
    
    
    
    if noTurnBack2.overrideSection then
        noTurnBack2.enabled = false
    end
end

function noTurnBack2.sectionsWithNoPlayers()
    local nonPlayeredSections = {}
    local playeredSections = Section.getActiveIndices()
    for i = 0,20 do
        if playeredSections[i] ~= i then
            table.insert(nonPlayeredSections, i)
        end
    end
    return nonPlayeredSections
end

function noTurnBack2.reviveOriginalBoundaries()
    for k,v in ipairs(noTurnBack2.sectionsWithNoPlayers()) do
        if not autoscroll.isSectionScrolling(v) then
            if noTurnBack2.enabled and not noTurnBack2.overrideSection then
                for _,p in ipairs(Player.get()) do
                    local sectionObj = Section(v)
                    local bounds = sectionObj.boundary
                    bounds.left = noTurnBack2.originalBoundariesLeft[v + 1]
                    bounds.top = noTurnBack2.originalBoundariesTop[v + 1]
                    bounds.bottom = noTurnBack2.originalBoundariesBottom[v + 1]
                    bounds.right = noTurnBack2.originalBoundariesRight[v + 1]
                    sectionObj.boundary = bounds
                end
            end
        end
    end
end

function noTurnBack2.onDraw()
    for k,v in ipairs(noTurnBack2.sectionsWithNoPlayers()) do
        if not autoscroll.isSectionScrolling(v) then
            if noTurnBack2.enabled and not noTurnBack2.overrideSection then
                for _,p in ipairs(Player.get()) do
                    if p.sectionObj.idx ~= v then
                        local sectionObj = Section(v)
                        local bounds = sectionObj.boundary
                        bounds.left = noTurnBack2.originalBoundariesLeft[v + 1]
                        bounds.top = noTurnBack2.originalBoundariesTop[v + 1]
                        bounds.bottom = noTurnBack2.originalBoundariesBottom[v + 1]
                        bounds.right = noTurnBack2.originalBoundariesRight[v + 1]
                        sectionObj.boundary = bounds
                    end
                end
            end
        end
    end
end

return noTurnBack2