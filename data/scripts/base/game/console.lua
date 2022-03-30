--***************************************************************************************
--                                                                                      *
-- 	console.lua                                                                         *
--  v2.4                                                                                *
--  Documentation: http://wohlsoft.ru/pgewiki/console.lua                               *
--                                                                                      *
--***************************************************************************************

local imagic = require("imagic")
local textblox = require("textblox")
local rng = require("base/rng")

local console = {}

function console.onInitAPI()
	registerEvent(console, "onKeyboardPress", "onKeyboardPress", true)
	registerEvent(console, "onCameraUpdate", "onCameraUpdate", true)
	registerEvent(console, "onStart", "onStart", true)
	registerEvent(console, "onInputUpdate", "onInputUpdate", true)
end

console.enabledInEpisode = false
console.pauseWhenActive = false --change this to true once Misc.pause no longer interferes with onKeyboardPress
console.startPopup = true
console.active = false
console.log = {"Type a command and press <color yellow>enter<color default> to run it. Type <color green>/h<color default> for additional info."}
console.inputString = ""

local canUseConsole = false

local playerLog = {}
local popupQueue = {}
local popupTimer = 0
local startPopupTriggered = false
local blinkTimer = 0
local capslock = false
local shiftHeld = false
local logScroll = 0
local prevEntry = 0

local screenTintBox = imagic.Box{x=0,y=0,width=800,height=600, z=6, color=0x000000DD, scene=false}
local bottomBox = imagic.Box{x=0,y=580,width=800,height=25, z=6.2, color=0x00000099, scene=false}


-- Cheats
local function keysToValues (commandTable)
	local list = {}
	
	for  k,v in pairs(commandTable)  do
		table.insert(list, #list+1, k)
	end
	
	return list
end

local function mergeLists (commandTable, addTo)
	local firstList = addTo
	if  firstList == nil  then  firstList = {};  end;
	
	for  k,v in pairs(commandTable)  do
		table.insert(firstList, #firstList+1, v)
	end
	
	return firstList
end

local function makeCommandLogList (commandTable, addTo)
	local logList = addTo
	if  logList == nil  then  logList = {};  end;
	
	local cheatListStr = ""
	local numOnLine = 0
	for  k,v in ipairs(commandTable)  do
		if  cheatListStr == ""  then
			cheatListStr = "<color green>"..v.."<color default>"
		else
			cheatListStr = cheatListStr..", <color green>"..v.."<color default>"
		end
		numOnLine = numOnLine+1
		
		if  numOnLine == 5  then
			table.insert(logList, 1, "  "..cheatListStr.."<color default>,")
			cheatListStr = ""
			numOnLine = 0
		end
	end
	
	-- Print remaining
	if  numOnLine > 0  then
		table.insert(logList, 1, "  "..cheatListStr)
	end
	
	return logList
end

console.extraCommands = {}

local cheatChecks = {};
local vanillaCheatLogList;
function console.onStart()
	local vanillaCheats = Cheats.listCheats();
	
	for k,v in ipairs(vanillaCheats) do
		cheatChecks[v] = true
	end
	
	table.sort(vanillaCheats)
	vanillaCheatLogList = makeCommandLogList (vanillaCheats)
	vanillaCheatLogList[1] = vanillaCheatLogList[1]:sub(1,-2)
end


-- Use this function to write to the console
function console.print(str)
	table.insert(console.log, 1, str)
end


-- Use this function to trigger a pop-up
function console.popup(str, force)
	popupTimer = 300
	if  force == true  then
		popupQueue[1] = str
	else
		table.insert(popupQueue, str)
	end
end


-- Default functions
function console.check(str)
	
	-- Make a table of extra command checks
	local exChecks = {}
	for k,v in pairs(console.extraCommands) do
		if  type(v) == "function"  then
			exChecks[k] = true
		end
	end


	local idx = str:find(" ")
	local cmd = str:sub(1, idx - 1)
	local arg = str:sub(idx + 1)
	local args = arg:split(" ")

	-- General help
	if       cmd == "/h"  then
		console.print("")
		console.print("<color cyan>----CONSOLE.LUA HELP--------------------------------------<color default>")
		console.print("Press <color yellow>tab<color default> to toggle the command console.")
		console.print("When the console is active, type a command and press <color yellow>enter<color default> to run it.")
		console.print("Use the <color yellow>up<color default> and <color yellow>down<color default> arrow keys to scroll through the command history.")
		console.print("Use the <color yellow>left<color default> and <color yellow>right<color default> arrow keys to load previously-entered commands.")
		console.print("Press <color yellow>delete<color default> to clear the input string.")
		console.print("")
		console.print("Commands:")
		console.print("  <color green>/h<color default> to display this list")
		console.print("  <color green>/c<color default> to display all default SMBX cheat codes")
		console.print("  <color green>/x<color default> to display additional commands for loaded APIs")
		console.print("  <color green>/s<color default> to save the console log to a text file")
	
	-- Cheat list
	elseif   cmd == "/c"  then
		console.print("")
		console.print("<color cyan>----CHEAT CODES--------------------------------------<color default>")
		for i=0,#vanillaCheatLogList-1  do
			console.print(vanillaCheatLogList[#vanillaCheatLogList-i])
		end
	
	-- Extra command list
	elseif   cmd == "/x"  then
		
		console.print("")
		console.print("<color cyan>----API COMMANDS--------------------------------------<color default>")
		console.print("To add a command to this list, insert it into the table <color yellow>console.extraCommands<color default>")
		if  #console.extraCommands ~= 0  then
			local exCommandList = makeCommandLogList (console.extraCommands)
			for i=0,#exCommandList-1  do
				console.print(exCommandList[#exCommandList-i])
			end
		else
			console.print("  <color yellow>No commands in the list")
		end


	-- Save log
	elseif   cmd == "/s"  then
		local filenameStr = "consoleApi-"..os.date("%Y-%m-%d_%H-%M-%S")..".log"
		local f = io.open(filenameStr, "w")
		for  i=0,#console.log-1  do
			local decoloredLine = string.gsub(console.log[#console.log-i], "<color.->", "")
			f:write(decoloredLine.."\n")
		end
		f:close()
		console.print("Log saved to <color yellow>"..filenameStr.."<color default>.")
	
	elseif   cmd == "/exec" then
		local chunk, err = load(arg)
		if chunk then
			console.print(chunk())
		else
			console.print(err)
		end

	-- If it matches a vanilla cheat, indicate it
	elseif  cheatChecks[cmd] ~= nil  then
		console.print("<color cyan>CHEAT ENTERED:"..cmd)

	-- If it matches an extra command, indicate it
	elseif  exChecks[cmd] ~= nil  then
		console.print("<color yellow>EXTRA COMMAND ENTERED:"..cmd)
		console.extraCommands[cmd]()


	-- If it doesn't match any of the built-in commands or cheats, just print it to the console
	else
		console.print(str)
	end
end

function console.onInputUpdate()
	if console.active then
		if player.rawKeys.dropItem == KEYS_PRESSED then
			player.rawKeys.dropItem = KEYS_UNPRESSED
		end
	end
end

local rngkey = rng.randomInt(1,7)

function console.onKeyboardPress(vk)
	--windowDebug ("sup dawg")
	local clearBuffer = true
	
	-- If the console is active...
	if  console.active  then
		SFX.play("console_keypress"..rngkey)
		-- Disable the console if tab is pressed
		if  vk == VK_TAB  then
			console.active = false
			if  console.pauseWhenActive  then
				Misc.unpause ()
			end	
			
		-- Otherwise, if enter, send the command to the cheat buffer
		elseif  vk == VK_RETURN  then
			if  console.inputString ~= ""  then
				clearBuffer = false
				Misc.cheatBuffer(console.inputString)
				table.insert(playerLog, 1, console.inputString)
				console.check (console.inputString)
				console.inputString = ""
				prevEntry = 0
				SFX.play("_OST/_Sound Effects/console/console_keypressenter.ogg")
			end
		
		-- Otherwise, if backspace, remove the latest character
		elseif  vk == VK_BACK  then
			if  string.len (console.inputString) > 0  then
				console.inputString = string.sub(console.inputString, 1, -2)
				SFX.play("_OST/_Sound Effects/console/console_keypressbackspace.ogg")
			end
		
		-- Otherwise, if delete, clear the input string
		elseif  vk == VK_DELETE  then
			console.inputString = ""
			SFX.play("_OST/_Sound Effects/console/console_keypress7.ogg")
		
		-- Otherwise, if vert arrows, scroll the log up and down
		elseif  vk == VK_DOWN  then
			if  #console.log > 20  then
				logScroll = math.max(logScroll-25, 0)
			end
		elseif  vk == VK_UP  then
			if  #console.log > 20  then
				logScroll = math.min(logScroll+25, 25*(#console.log-20))
			end
		
		-- Otherwise, if horz arrows, select previous entries
		elseif  vk == VK_LEFT  then
			prevEntry = math.min(prevEntry+1, #playerLog)
			console.inputString = playerLog[prevEntry]  or  ""
			
		elseif  vk == VK_RIGHT  then
			prevEntry = math.max(prevEntry-1, 0)
			if  prevEntry == 0  then
				console.inputString = ""
			else
				console.inputString = playerLog[prevEntry]
			end
		
		-- Otherwise, ignore the following characters
		elseif  vk == VK_SHIFT  or  vk == VK_CONTROL  or  vk == VK_CAPSLOCK  or  vk == VK_CAPS  then
		
		-- Otherwise, add the character pressed to the input string
		else
			local charToAdd = string.sub(Misc.cheatBuffer(), -1)
			console.inputString = console.inputString..charToAdd
		end

		-- Clear the cheat buffer
		if  clearBuffer  then  Misc.cheatBuffer("");  end;
		
		
	-- If the console is inactive...
	else
		-- Enable the console if tab is pressed
		if  vk == VK_TAB  and  canUseConsole  then
			console.active = true
			if  console.pauseWhenActive  then
				Misc.pause ()
			end
		end
	end
end

function console.onCameraUpdate (cameraIndex)

	-- Trigger the start popup if enabled
	if  startPopup  and  startPopupTriggered == false  then
		startPopupTriggered = true
		console.popup("Press <color yellow>tab<color default> to toggle the command console.")
	end

	-- Check whether the player can access the console (either the player is testing through the editor or the episode/level's code enables it)
	canUseConsole = (mem(0x00B2C62A, FIELD_WORD) == 0  or  console.enabledInEpisode)

	if  console.active  then

		-- Remove the start info
		popupTimer = 0

		-- Display the overlay
		screenTintBox:Draw(6,0x000000BB)
		bottomBox:Draw(6.2,0x000000FF)

		-- Control the blinking
		blinkTimer = (blinkTimer+1)%60
		local inputStr = console.inputString
		if  blinkTimer < 30  then
			inputStr = inputStr.."_"
		end

		-- Print the current text
		textblox.printExt (inputStr, {x=10,y=600,z=7, valign=textblox.ALIGN_BOTTOM, bind=textblox.BIND_SCREEN, font=textblox.FONT_SPRITEDEFAULT4X2})

		-- Print the previous log entries
		for  k,v  in ipairs(console.log)  do
			textblox.printExt (v, {x=10, y=600 - 25*k + logScroll, z=6.1, valign=textblox.ALIGN_BOTTOM, bind=textblox.BIND_SCREEN, font=textblox.FONT_SPRITEDEFAULT4X2, color=0x000000FF, ignoreTags={"color"}})
			textblox.printExt (v, {x=8,  y=598 - 25*k + logScroll, z=6.1, valign=textblox.ALIGN_BOTTOM, bind=textblox.BIND_SCREEN, font=textblox.FONT_SPRITEDEFAULT4X2, color=0xFFFFFFFF})
		end

	else

		-- Count down the popup timer and move to the next message in the queue when done
		popupTimer = math.max(0, popupTimer-1)
		if  popupTimer == 0  and  #popupQueue > 0  then
			table.remove(popupQueue, 1)
			popupTimer = 300
		end

		if  canUseConsole  and  #popupQueue > 0  then
			bottomBox:Draw(6.2,0x00000099)

			textblox.printExt (popupQueue[1], {x=10, y=602, z=7, valign=textblox.ALIGN_BOTTOM, bind=textblox.BIND_SCREEN, font=textblox.FONT_SPRITEDEFAULT4X2, color=0x000000FF, ignoreTags={"color"}})
			textblox.printExt (popupQueue[1], {x=8,  y=600, z=7, valign=textblox.ALIGN_BOTTOM, bind=textblox.BIND_SCREEN, font=textblox.FONT_SPRITEDEFAULT4X2, color=0xFFFFFFFF})
		end

		-- Reset the blink timer
		blinkTimer = 0
	end
end

return console