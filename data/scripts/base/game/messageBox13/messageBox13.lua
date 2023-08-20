local messageBox13 = {}

local textplus = require("textplus")
local tplusUtils = require("textplus/tplusutils")

--Whether a message box is on or not.
messageBox13.messageBoxOn = false
--The message shown on the screen
messageBox13.message = ""
--The page marker, used with the <page> tag
messageBox13.currentPageMarker = 1
--Calculated when showing a message
messageBox13.maxBoxHeight = 0
--The drawing priority for the message box.
messageBox13.priority = 5
--The box image for the message box.
messageBox13.boxImage = Graphics.sprites.hardcoded[46].img
--The font used for the message box.
messageBox13.font = textplus.loadFont("messageBox13/hardcoded-45-3-textplus.ini")

local isCancelled = false

function messageBox13.onInitAPI()
    registerEvent(messageBox13,"onMessageBox")
    registerEvent(messageBox13,"onDraw")
    registerEvent(messageBox13,"onInputUpdate")
    if SMBX_VERSION == VER_SEE_MOD then
        registerEvent(messageBox13,"onMessageBoxSEEMod")
        registerEvent(messageBox13,"onPostMessageBoxSEEMod")
    end
end

local customTags = {}
function customTags.page(fmt, out, args)
    out[#out+1] = {page=true} -- Add page tag to stream
    return fmt
end

messageBox13.characterNames = {
    [1]  = "Mario",
    [2]  = "Luigi",
    [3]  = "Peach",
    [4]  = "Toad",
    [5]  = "Link",
    [6]  = "Megaman",
    [7]  = "Wario",
    [8]  = "Bowser",
    [9]  = "Klonoa",
    [10] = "Yoshi",
    [11] = "Rosalina",
    [12] = "Snake",
    [13] = "Zelda",
    [14] = "Steve",
    [15] = "Uncle Broadsword",
    [16] = "Samus",
}

function customTags.characterName(fmt,out,args)
    local text = ""

    for index,p in ipairs(Player.get()) do
        text = text.. (messageBox13.characterNames[p.character] or "Player")

        if index < Player.count()-1 then
            text = text.. ", "
        elseif index < Player.count() then
            text = text.. " and "
        end
    end

    local segment = tplusUtils.strToCodes(text)
    segment.fmt = fmt

    out[#out+1] = segment

    return fmt
end

function messageBox13.parseTextForDialogMessage(text, args)
	local formattedText = textplus.parse(text, {font = messageBox13.font, xscale=1, yscale=1, color=Color.white}, customTags, {"page","characterName"})

	local pages = {}
	local page = {}
	for _,seg in ipairs(formattedText) do
		if seg.page then
			pages[#pages+1] = page
			page = {}
		else
			page[#page+1] = seg
		end
	end
	pages[#pages+1] = page
	
	return pages
end

function messageBox13.getDialogMessage(text)
    text = text or ""
    if maxWidth == nil then
        maxWidth = 27 * 17
    end
    
    --Create page list
    local pages = messageBox13.parseTextForDialogMessage(text)

    --Layout the pages
    for i=1,#pages do
        pages[i] = textplus.layout(pages[i], maxWidth)
    end
    
    return pages
end

function messageBox13.onDraw()
    if messageBox13.messageBoxOn then
        messageBox13.drawMessageBox()
    end
end

function messageBox13.onInputUpdate()
    local currentDialog = messageBox13.getDialogMessage(messageBox13.message)
    for _,p in ipairs(Player.get()) do
        if messageBox13.messageBoxOn then
            if p.keys.jump == KEYS_PRESSED and messageBox13.currentPageMarker < #currentDialog then
                messageBox13.currentPageMarker = messageBox13.currentPageMarker + 1
                SFX.play(26)
            elseif p.keys.jump == KEYS_PRESSED and messageBox13.currentPageMarker >= #currentDialog then
                messageBox13.closeMessageBox()
            end
        end
    end
end

function messageBox13.activateMessageBox(message)
    messageBox13.message = message
    messageBox13.currentPageMarker = 1
    SFX.play(47)
    Misc.pause()
    messageBox13.messageBoxOn = true
end

function messageBox13.closeMessageBox()
    messageBox13.messageBoxOn = false
    messageBox13.currentPageMarker = 1
    messageBox13.message = ""
    Misc.unpause()
    for _,p in ipairs(Player.get()) do
        p:mem(0x11E, FIELD_BOOL, false)
    end
end

function messageBox13.drawMessageBox()
    local currentDialog = messageBox13.getDialogMessage(messageBox13.message)
    
    local TextBoxW = messageBox13.boxImage.width
    local UseGFX = true
    local ScreenW = camera.width
    local ScreenH = camera.height
    
    if (ScreenW < messageBox13.boxImage.width) then
        TextBoxW = ScreenW - 50
        UseGFX = false
    end
    
    local charWidth = 18;
    local lineHeight = 17;

    local BoxY = 0;
    local BoxY_Start = ScreenH / 2 - 150;

    if(BoxY_Start < 60) then
        BoxY_Start = 60
    end

    --Draw background all at once:
    --how many lines are there?
    local lineStart = 0; -- start of current line
    local lastWord = 0; -- planned start of next line
    local numLines = 0; -- n lines
    local maxChars = ((TextBoxW - 24) / charWidth) + 1; -- 27 by default
    -- Text size without a NULL terminator
    
    local textSize = (#messageBox13.message - 1)

    --PASS ONE: determine the number of lines
    --Wohlstand's updated algorithm, no substrings, reasonably fast
    
    for i = lineStart + 1, #messageBox13.message, maxChars do
        numLines = numLines + 1
    end

    --Draw the background now we know how many lines there are.
    local totalHeight = numLines * lineHeight + 20

    --carefully render the background image...
    Graphics.drawBox{
        x = ScreenW / 2 - TextBoxW / 2,
        y = BoxY_Start,
        width = TextBoxW,
        height = 20,
        sourceWidth = TextBoxW,
        sourceHeight = 20,
        texture = messageBox13.boxImage,
        sourceX = 0,
        sourceY = 0,
        priority = messageBox13.priority,
    }
    local rndMidH = (currentDialog[messageBox13.currentPageMarker].height - 20)
    local gfxMidH = (messageBox13.boxImage.height - 40)
    local vertReps = (rndMidH / gfxMidH + 1)
    
    for i = 0, vertReps do
        Graphics.drawBox{
            x = ScreenW / 2 - TextBoxW / 2,
            y = BoxY_Start + 20 + rndMidH,
            sourceWidth = TextBoxW,
            sourceHeight = 20,
            texture = messageBox13.boxImage,
            sourceX = 0,
            sourceY = messageBox13.boxImage.height - 20,
            priority = messageBox13.priority,
        }
    end
    
    for i = 0, math.floor(vertReps) - 1 do
        Graphics.drawBox{
            x = ScreenW / 2 - TextBoxW / 2,
            y = BoxY_Start + 20 + i * gfxMidH,
            width = TextBoxW,
            sourceHeight = rndMidH - i * gfxMidH,
            texture = messageBox13.boxImage,
            sourceX = 0,
            sourceY = 20,
            priority = messageBox13.priority,
        }
    end
    
    --PASS TWO: draw the lines
    --Wohlstand's updated algorithm
    --modified to not allocate/copy a bunch of strings
    
    local firstLine = true
    BoxY = BoxY_Start + 10 + lineHeight
    
    textplus.render{x = ScreenW/2 - TextBoxW / 2 + 12, y = 160, layout = currentDialog[messageBox13.currentPageMarker], priority = messageBox13.priority + 0.001}
end

function messageBox13.onMessageBox(eventObj, content, player, npcTalkedTo)
    --eventObj.cancelled = true
    --messageBox13.activateMessageBox(content)
end

function messageBox13.onMessageBoxSEEMod(eventObj, content, player, npcTalkedTo)
    isCancelled = eventObj.cancelled
end

function messageBox13.onPostMessageBoxSEEMod(content, player, npcTalkedTo)
    if not isCancelled and Misc.SEEModFeaturesGetBool() then
        messageBox13.activateMessageBox(content)
    end
end

return messageBox13