local introMan = {}

introMan.maxPlayers = 6

local introPlaying = false
local keysPresses = {
    [1] = inputConfig1.jump, --jump
    [2] = inputConfig1.run, --run
    [3] = inputConfig1.altjump, --altjump
    [4] = inputConfig1.altrun, --altrun
    [5] = inputConfig1.dropitem, --dropitem
    [6] = inputConfig1.pause, --pause
    [7] = inputConfig1.up, --up
    [8] = inputConfig1.down, --down
    [9] = inputConfig1.left, --left
    [10] = inputConfig1.right, --right
}
introMan.isKeyPressing = table.map{1,2,3,4,5,6,7,8,9,10}

function introMan.toggle(enabled)
    if enabled then
        Cheats.trigger("supermario128")
        mem(0x00B2595E, FIELD_WORD, introMan.maxPlayers)
        if not Misc.isPlayerControlsDisabled() then
            Misc.disablePlayerControls(true)
        end
        introPlaying = true
    else
        Cheats.trigger("1player")
        if Misc.isPlayerControlsDisabled() then
            Misc.disablePlayerControls(false)
        end
        introPlaying = false
    end
end

function introMan.onInitAPI()
    registerEvent(introMan,"onStart")
    registerEvent(introMan,"onDraw")
    registerEvent(introMan,"onTick")
    registerEvent(introMan,"onKeyboardKeyPress")
end

function introMan.onKeyboardKeyPress(virtualKey, strKey)
    if introPlaying then
        if inputConfig1.inputType == 0 then
            if introMan.isKeyPressing[1] then
                
            end
        end
    end
end

local Jump = 0x11C
local CanJump = 0x11E
local FireBallCD = 0x160
local RunRelease = 0x172
local SpinJump = 0x50
local Slope = 0x48
local TailCount = 0x164

local Active = 0x124
local HoldingPlayer = 0x12C

local function CheckCollision(Loc1, Loc2) --Checks a collision between two things
    return (Loc1.y + Loc1.height >= Loc2.y) and
           (Loc1.y <= Loc2.y + Loc2.height) and
           (Loc1.x <= Loc2.x + Loc2.width) and
           (Loc1.x + Loc1.width >= Loc2.x)
end

function introMan.onDraw()
    --key presses
    for i = 1, #keysPresses do
        if Misc.GetKeyState(keysPresses[i]) then --jump
            introMan.isKeyPressing[i] = true
        else
            introMan.isKeyPressing[i] = false
        end
    end
end

function introMan.onTick()
    if introPlaying then
        for k,v in ipairs(Player.get()) do
            p.downKeyPressing = false
            p.dropItemKeyPressing = false
            p.rightKeyPressing = true
            p.leftKeyPressing = false
            p.runKeyPressing = true
            p.upKeyPressing = false
            p.altRunKeyPressing = false
            p.altJumpKeyPressing = false

            local tempLocation = {}
            tempLocation.x = 0
            tempLocation.y = 0
            tempLocation.width = 0
            tempLocation.height = 0
            
            local levelX = Section(p.section).boundary.top
            local levelY = Section(p.section).boundary.bottom
            local levelWidth = Section(p.section).boundary.right - Section(0).boundary.left
            local levelHeight = Section(p.section).boundary.bottom - Section(0).boundary.top

            if (p:mem(Jump, FIELD_WORD) == 0 or p.y < levelY + 200) then
                p.jumpKeyPressing = false
            end
            
            if p.speedX < 0.5 then
                p.jumpKeyPressing = true
                if p:mem(Slope, FIELD_WORD) > 0 or p.standingNPC or p.speedY == 0 then
                    p:mem(CanJump, FIELD_BOOL, true)
                end
            end

            if p.holdingNPC == nil then
                if (p.powerup == 3 or p.powerup == 6 or p.powerup == 7) and LegacyRNG.generateNumber() * 100 > 90 then
                    if p:mem(FireBallCD, FIELD_WORD) == 0 and not p:mem(RunRelease, FIELD_BOOL) then
                        p.runKeyPressing = false
                    end
                end

                if (p.powerup == 4 or p.powerup == 5) and p:mem(TailCount, FIELD_WORD) == 0 and not p:mem(RunRelease, FIELD_BOOL) then
                    tempLocation.width = 24
                    tempLocation.height = 20
                    tempLocation.y = p.y + p.height - 22
                    tempLocation.x = p.x + p.width
                    for k,v in ipairs(NPC.get()) do
                        if v:mem(Active, FIELD_BOOL) and not NPC.config[v.id].isinteractable and not NPC.config[v.id].nohurt and v:mem(HoldingPlayer, FIELD_WORD) == 0 then
                            if CheckCollision(tempLocation, v) then
                                p:mem(RunRelease, FIELD_BOOL, true)
                            end
                            break
                        end
                    end
                end

                if p.standingNPC then
                    if NPC.config[p.standingNPC.id].grabtop then
                        p.downKeyPressing = true
                        p.runKeyPressing = true
                        p:mem(RunRelease, FIELD_BOOL, true)
                    end
                end

                if p.character == 5 then
                    if p:mem(FireballCD, FIELD_WORD) == 0 and not p:mem(RunRelease, FIELD_BOOL) then
                        tempLocation.width = 38 + p.speedX * 0.5
                        tempLocation.height = p.height - 8
                        tempLocation.y = p.y + 4
                        tempLocation.x = p.x + p.width
                        for k,v in ipairs(NPC.get()) do
                            if v:mem(Active, FIELD_BOOL) and not NPC.config[v.id].isinteractable and not NPC.config[v.id].nohurt and v:mem(HoldingPlayer, FIELD_WORD) == 0 then
                                if CheckCollision(tempLocation, v) then
                                    p:mem(RunRelease, FIELD_BOOL, true)
                                    if v.y > (p.y + p.height / 2) then
                                        p.downKeyPressing = true
                                    end
                                    break
                                end
                            end
                        end
                    end
                    if p:mem(Slope, FIELD_WORD) == 0 and p.standingNPC == nil then
                        if p.speedY < 0 then
                            tempLocation.width = 200
                            tempLocation.height = p.y - Section(0).boundary.bottom + p.height
                            tempLocation.y = Section(0).boundary.bottom
                            tempLocation.x = p.x
                            for k,v in ipairs(NPC.get()) do
                                if v:mem(Active, FIELD_BOOL) and not NPC.config[v.id].isinteractable and not NPC.config[v.id].nohurt and v:mem(HoldingPlayer, FIELD_WORD) == 0 then
                                    if CheckCollision(tempLocation, v) then
                                        p.upKeyPressing = true
                                        break
                                    end
                                end
                            end
                        elseif p.speedY > 0 then
                            tempLocation.width = 200
                            tempLocation.height = levelHeight - p.y
                            tempLocation.y = p.y
                            tempLocation.x = p.x
                            for k,v in ipairs(NPC.get()) do
                                if v:mem(Active, FIELD_BOOL) and not NPC.config[v.id].isinteractable and not NPC.config[v.id].nohurt and v:mem(HoldingPlayer, FIELD_WORD) == 0 then
                                    if CheckCollision(tempLocation, v) then
                                        p.downKeyPressing = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                
            end
        end
    end
end

return introMan