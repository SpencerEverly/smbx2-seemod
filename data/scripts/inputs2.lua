--***************************************************************************************
--                                                                                      *
--  inputs2.lua                                                                         *
--  v2.1d                                                                               *
--                                                                                      *
--***************************************************************************************

--Spun off from inputs.lua by Rockythechao - now supports multiplayer!

--[[
    Vars:  
        inputs.locked[playerIndex][keystr] -- if true, SMBX does not process this input, but the state
                                 is still recorded by this library.
							 
        inputs.frozen[playerIndex][keystr] -- if true, the state is not updated but SMBX still processes this input.
							 
        inputs.state[playerIndex][keystr]  -- the current state of that key (read-only)
		
    keystrings are same as the respective fields, all lowercase
    (I.E. player.leftKeyPressing --> "left",  player.dropItemKeyPressing --> "dropItem")
	
    state constants are inputs2.UP
                        inputs2.PRESS
                        inputs2.HOLD
                        inputs2.RELEASE
--]]



local inputs2 = {} --Package table

	inputs2.hijackEvents = false
	inputs2.debug = false

	function inputs2.onInitAPI()
		registerEvent(inputs2, "onStart", "onStart", false)
		registerEvent(inputs2, "onLoop", "onLoop", true)
		registerEvent(inputs2, "onInputUpdate", "onInputUpdate", true)
		registerEvent(inputs2, "onEvent", "onEvent", true)
	end


	
	--***********************************************************************************
	--                                                                                  *
	--  State constants and input names                                                 *
	--                                                                                  *
	--***********************************************************************************
	
	do
		inputs2.UP = 0
		inputs2.PRESS = 1
		inputs2.HOLD = 2
		inputs2.RELEASE = 3
		
		inputs2.names = {"up", "down", "left", "right", "jump", "altjump", "run", "altrun", "dropitem", "pause", "all"}
	end
	local stateKeys = {"up", "down", "left", "right", "jump", "altjump", "run", "altrun", "dropitem", "pause", "any"}
	local maxNumPlayers = 1

	
	--***********************************************************************************
	--                                                                                  *
	--  Getting input override data from SMBX events                                    *
	--                                                                                  *
	--***********************************************************************************
	local eventCommands = {}
	local currentEventCommands = {}
	local currentEventOverrides = false
	
	local function getEventProperties ()
		
		-- loop through the event array
		local GM_EVENTS_PTR = mem (0x00B2C6CC, FIELD_DWORD)
		
		local allEventsString = ""
		for  i=0, 100  do
		   local ptr         = GM_EVENTS_PTR + 0x588*i
		   local namePtr     = ptr + 0x04
		   local nameString  = tostring(mem (namePtr, FIELD_STRING))
			
			---[[
			if  string.len (nameString) == 0  and  i > 0  then
				break;
			else
				-- For debugging, list the event names
				allEventsString = allEventsString .. "\nNAME = "..nameString
				
				-- get all the input data and index it by event name (since that's what onEvent gives us)
				eventCommands[nameString] = {
					up       = mem(ptr + 0x55C, FIELD_BOOL),
					down     = mem(ptr + 0x55E, FIELD_BOOL),
					left     = mem(ptr + 0x560, FIELD_BOOL),
					right    = mem(ptr + 0x562, FIELD_BOOL),
					jump     = mem(ptr + 0x564, FIELD_BOOL),
					altjump  = mem(ptr + 0x566, FIELD_BOOL),
					run      = mem(ptr + 0x568, FIELD_BOOL),
					altrun   = mem(ptr + 0x56A, FIELD_BOOL),
					dropitem = mem(ptr + 0x56C, FIELD_BOOL),
					pause    = mem(ptr + 0x56E, FIELD_BOOL)
				}
				
				-- NOW GO, MY BRETHEREN! SCORCH THE EARTH, MASSACRE THE INNOCENTS, SCRIBBLE ALL OVER THEIR FINE CHINA WITH PERMANENT MARKERS, LEAVE NO SURVIVORS SO OUR DARK AND BLOODY CONQUEST MAY REMAIN UNOPPOSED FROM HERE TO THE HALLOWED RUINS OF ANCIENT BABBLOPOLIS
				mem(ptr + 0x55C, FIELD_BOOL, false)
				mem(ptr + 0x55E, FIELD_BOOL, false)
				mem(ptr + 0x560, FIELD_BOOL, false)
				mem(ptr + 0x562, FIELD_BOOL, false)
				mem(ptr + 0x564, FIELD_BOOL, false)
				mem(ptr + 0x566, FIELD_BOOL, false)
				mem(ptr + 0x568, FIELD_BOOL, false)
				mem(ptr + 0x56A, FIELD_BOOL, false)
				mem(ptr + 0x56C, FIELD_BOOL, false)
				mem(ptr + 0x56E, FIELD_BOOL, false)
			end
			--]]
			
		end		
		
		-- Output the event names list
		--windowDebug (allEventsString)
	end
	
	
	--***********************************************************************************
	--                                                                                  *
	--  Initialize state, lock and freeze tables                                        *
	--                                                                                  *
	--***********************************************************************************
	
	local function initPlayer(i)
			inputs2.locked[i] = {}
			inputs2.frozen[i] = {}

			inputs2.state[i] = {}
			inputs2.key[i] = {}
			inputs2.frozenBool[i] = {}
			
			for _,v in ipairs (inputs2.names)  do
				inputs2.locked[i][v] = false
				inputs2.frozen[i][v] = false
				
				inputs2.state[i].any = inputs2.UP
				
				if  v ~= "all"  then
					inputs2.state[i][v] = inputs2.UP
					inputs2.frozenBool[i][v] = false
				end
			end
	end
	
	do
		inputs2.locked = {}
		inputs2.frozen = {}

		inputs2.state = {}
		inputs2.key = {}
		inputs2.frozenBool = {}
		
		for i=1, math.min (#Player.get()+1, 2) do
			initPlayer(i);
		end	
	end
	
	
	function initializeExtraTables(playerNum)
		-- Initialize new tables for additional players
		if  playerNum > maxNumPlayers  then
			for i = maxNumPlayers+1, playerNum+1  do
				initPlayer (i)
			end
			maxNumPlayers = playerNum
		end
	end
	

	
	--***********************************************************************************
	--                                                                                  *
	--  Update input                                                                    *
	--                                                                                  *
	--***********************************************************************************
	
	local function applyLock (playerObj, playerKey, playerNum, state)
		
		-- If the input is locked
		if  inputs2.locked[playerNum][state]  or  inputs2.locked[playerNum]["all"]  then
			playerObj[playerKey] = inputs2.frozenBool[playerNum][state]  or  false;
		
		-- Event-based overriding
		elseif  playerNum == 1  and  currentEventOverrides  then
			playerObj[playerKey] = currentEventCommands[state];
		end
		
	end
	
	do
		function inputs2.onStart ()
			if  inputs2.hijackEvents  then  getEventProperties ();  end;
		end
	
		function inputs2.onEvent (eventName)
			-- Assign the input data corresponding to the current event
			currentEventCommands = eventCommands[eventName]
			
			if(currentEventCommands == nil) then
				return;
			end
			
			-- Check if any of the flags are true;  if so, this means the event overrides player controls
			currentEventOverrides = false
			for k,v in pairs (currentEventCommands) do
				if  v == true  then
					currentEventOverrides = true
					break;
				end
			end
		end
	
	
		function inputs2.onLoop ()
			local playerNum = Player.count()
			initializeExtraTables(playerNum)
			
			-- Debug
			if  inputs2.debug == true  then
				for l = 1,playerNum  do
					local i = 0
					
					for _,k in ipairs(stateKeys) do
						local debugStr = tostring(k)..": "..tostring(inputs2.state[l][k])
						
						if  inputs2.locked[l][k] == true  then
							debugStr = debugStr.." (L)"
						end
						if  inputs2.frozen[l][k] == true  then
							debugStr = debugStr.." (F)"
						end
						
						Text.print (debugStr, 20 + 500*(l-1), 80 + 20*i)
						
						i = i+1
					end
				end
			end
		end
	
		function inputs2.onInputUpdate ()	
			local players = Player.get()
			initializeExtraTables(#players)
			
			for playerNum, playerObj in ipairs(players) do
			
				
				-- GET INPUT STATE FROM PLAYER OBJECT
				inputs2.key[playerNum]["up"] = playerObj.upKeyPressing
				inputs2.key[playerNum]["down"] = playerObj.downKeyPressing
				inputs2.key[playerNum]["left"] = playerObj.leftKeyPressing
				inputs2.key[playerNum]["right"] = playerObj.rightKeyPressing
				inputs2.key[playerNum]["jump"] = playerObj.jumpKeyPressing
				inputs2.key[playerNum]["altjump"] = playerObj.altJumpKeyPressing
				inputs2.key[playerNum]["run"] = playerObj.runKeyPressing
				inputs2.key[playerNum]["altrun"] = playerObj.altRunKeyPressing
				inputs2.key[playerNum]["dropitem"] = playerObj.dropItemKeyPressing
				inputs2.key[playerNum]["pause"] = playerObj.pauseKeyPressing
				
			
				-- STORE INPUT STATE FOR EACH KEY
				local anyPressed = false
				local anyHeld = false
				local anyReleased = false
				
				for _,k in ipairs(stateKeys) do
					local v = inputs2.state[playerNum][k]
					
					-- If the input is frozen, determine the hard input states based on the soft states
					local isFrozen = (inputs2.frozen[playerNum][k]  or  inputs2.frozen[playerNum]["all"])
					if  isFrozen  then
						
						-- Only true if the button is held or being pressed
						inputs2.frozenBool[playerNum][k] = (inputs2.state[playerNum][k] == inputs2.PRESS  or  inputs2.state[playerNum][k] == inputs2.DOWN)
					
					
					-- If the input is not frozen, update the soft states and reset the hard states
					else
						-- Set the stored frozen bool to nil
						inputs2.frozenBool[playerNum][k] = nil
					
						-- Button up
						if  inputs2.state[playerNum][k] == inputs2.UP			then
							if 	inputs2.key[playerNum][k] == true 	then
								inputs2.state[playerNum][k] = inputs2.PRESS
								anyPressed = true
							end
						
						-- Button pressed
						elseif inputs2.state[playerNum][k] == inputs2.PRESS		then
							inputs2.state[playerNum][k] = inputs2.HOLD
							anyHeld = true
						
						-- Button held
						elseif inputs2.state[playerNum][k] == inputs2.HOLD		then
							anyHeld = true
							if 	inputs2.key[playerNum][k] == false 	then
								inputs2.state[playerNum][k] = inputs2.RELEASE
								anyReleased = true
							end
						
						-- Button released
						elseif inputs2.state[playerNum][k] == inputs2.RELEASE	then
							inputs2.state[playerNum][k] = inputs2.UP
						end
					end
				end
				
				
				-- Set the state of any
				if  (anyPressed == true)  and  inputs2.state[playerNum].any == inputs2.UP  then
					inputs2.state[playerNum].any = inputs2.PRESS

				elseif  (anyHeld == true)  and  inputs2.state[playerNum].any == inputs2.PRESS  then
					inputs2.state[playerNum].any = inputs2.HOLD

				elseif  anyPressed == false  and  anyHeld == false  and  inputs2.state[playerNum].any == inputs2.HOLD  then
					inputs2.state[playerNum].any = inputs2.RELEASE

				elseif  inputs2.state[playerNum].any == inputs2.RELEASE  then
					inputs2.state[playerNum].any = inputs2.UP
				end
				
				
				-- Override keys that are locked or frozen
				applyLock(playerObj, "upKeyPressing",       playerNum, "up")
				applyLock(playerObj, "downKeyPressing",     playerNum, "down")
				applyLock(playerObj, "leftKeyPressing",     playerNum, "left")
				applyLock(playerObj, "rightKeyPressing",    playerNum, "right")
				applyLock(playerObj, "jumpKeyPressing",     playerNum, "jump")
				applyLock(playerObj, "altJumpKeyPressing",  playerNum, "altjump")
				applyLock(playerObj, "runKeyPressing",      playerNum, "run")
				applyLock(playerObj, "altRunKeyPressing",   playerNum, "altrun")
				applyLock(playerObj, "dropItemKeyPressing", playerNum, "dropitem")
				applyLock(playerObj, "pauseKeyPressing",    playerNum, "pause")
			end
		end
	end

return inputs2