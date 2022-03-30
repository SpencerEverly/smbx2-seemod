--***************************************************************************************
--                                                                                      *
--  inputs.lua                                                                          *
--  v1.3                                                                                *
--                                                                                      *
--***************************************************************************************


--[[
    Vars:  
        inputs.locked[keystr] -- if true, SMBX does not process this input, but the state
                                 is still recorded by this library.
							 
        inputs.state[keystr]  -- the current state of that key (read-only)
		
    keystrings are same as the respective fields, all lowercase
    (I.E. player.leftKeyPressing --> "left",  player.dropItemKeyPressing --> "dropItem")
	
    state constants are inputs.UP
                        inputs.PRESS
                        inputs.HOLD
                        inputs.RELEASE
--]]



local inputs = {} --Package table

	function inputs.onInitAPI()
		registerEvent(inputs, "onLoop", "onLoop", true)
		registerEvent(inputs, "onInputUpdate", "onInputUpdate", true)
	end


	
	--***********************************************************************************
	--                                                                                  *
	--  State constants                                                                 *
	--                                                                                  *
	--***********************************************************************************
	
	do
		inputs.UP = 0
		inputs.PRESS = 1
		inputs.HOLD = 2
		inputs.RELEASE = 3
	end

	
	
	--***********************************************************************************
	--                                                                                  *
	--  State table                                                                     *
	--                                                                                  *
	--***********************************************************************************
	
	do
		inputs.state = {}
		inputs.state["up"] = inputs.UP
		inputs.state["down"] = inputs.UP
		inputs.state["left"] = inputs.UP
		inputs.state["right"] = inputs.UP
		inputs.state["jump"] = inputs.UP
		inputs.state["altjump"] = inputs.UP
		inputs.state["run"] = inputs.UP
		inputs.state["altrun"] = inputs.UP
		inputs.state["dropitem"] = inputs.UP
		inputs.state["pause"] = inputs.UP
		inputs.state["any"] = inputs.UP
		inputs.state["all"] = inputs.UP
	end

	

	--***********************************************************************************
	--                                                                                  *
	--  Lock table                                                                      *
	--                                                                                  *
	--***********************************************************************************
	
	do
		inputs.locked = {}
		inputs.locked["all"] = false
		inputs.locked["up"] = false
		inputs.locked["down"] = false
		inputs.locked["left"] = false
		inputs.locked["right"] = false
		inputs.locked["jump"] = false
		inputs.locked["altjump"] = false
		inputs.locked["run"] = false
		inputs.locked["altrun"] = false
		inputs.locked["dropitem"] = false
		inputs.locked["pause"] = false
	end
	
	
	inputs.key = {}
	
	
	inputs.debug = false
	
	
	--***********************************************************************************
	--                                                                                  *
	--  Update input                                                                    *
	--                                                                                  *
	--***********************************************************************************
	
	local anyPressed = false
	local anyHeld = false
	local anyReleased = false
		
	
	function inputs.onLoop ()
		-- Debug
		if  inputs.debug == true  then

			Text.print ("Any Press: "..tostring(anyPressed), 20, 380)
			Text.print ("Any Hold: "..tostring(anyHeld), 20, 400)
			Text.print ("Any Release: "..tostring(anyReleased), 20, 420)
			
			i = 0
			
			for k,v in pairs(inputs.state) do
			
					local debugStr = tostring(k)..": "..tostring(inputs.state[k])
					
					if  inputs.locked[k] == true  then
						debugStr = debugStr.." (L)"
					end

					Text.print (debugStr, 20, 80 + 20*i)
				i = i+1
			end
		end
	end
	

	

	function inputs.onInputUpdate ()		
		inputs.key["up"] = player.upKeyPressing
		inputs.key["down"] = player.downKeyPressing
		inputs.key["left"] = player.leftKeyPressing
		inputs.key["right"] = player.rightKeyPressing
		inputs.key["jump"] = player.jumpKeyPressing
		inputs.key["altjump"] = player.altJumpKeyPressing
		inputs.key["run"] = player.runKeyPressing
		inputs.key["altrun"] = player.altRunKeyPressing
		inputs.key["dropitem"] = player.dropItemKeyPressing
		inputs.key["pause"] = player.pauseKeyPressing
	
	
		-- STORE INPUT STATE FOR EACH KEY
		local i = 0
		anyPressed = false
		anyHeld = false
		anyReleased = false
		
		for k,v in pairs(inputs.state) do
			if  k ~= "any"  then
				if  inputs.state[k] == inputs.UP			then
					if 	inputs.key[k] == true 	then
						inputs.state[k] = inputs.PRESS
						anyPressed = true
					end
				
				elseif inputs.state[k] == inputs.PRESS		then
					inputs.state[k] = inputs.HOLD
				
				elseif inputs.state[k] == inputs.HOLD		then
					anyHeld = true
					
					if 	inputs.key[k] == false 	then
						inputs.state[k] = inputs.RELEASE
						anyReleased = true
					end
				
				elseif inputs.state[k] == inputs.RELEASE	then
					inputs.state[k] = inputs.UP
				
				end
			end
		end
		
		
		-- Any key
		if  (anyPressed == true)  and  inputs.state["any"] == inputs.UP  then
			inputs.state["any"] = inputs.PRESS
		
		elseif  (anyHeld == true)  and  inputs.state["any"] == inputs.PRESS  then
			inputs.state["any"] = inputs.HOLD

		elseif  anyPressed == false  and  anyHeld == false  and  inputs.state["any"] == inputs.HOLD  then
			inputs.state["any"] = inputs.RELEASE
		
		elseif  inputs.state["any"] == inputs.RELEASE  then
			inputs.state["any"] = inputs.UP
		end

		
		
		-- Disable locked keys
		if  inputs.locked["up"] == true         then  player.upKeyPressing = false;             end
		if  inputs.locked["down"] == true       then  player.downKeyPressing = false;           end
		if  inputs.locked["left"] == true       then  player.leftKeyPressing = false;           end
		if  inputs.locked["right"] == true      then  player.rightKeyPressing = false;          end
		if  inputs.locked["jump"] == true       then  player.jumpKeyPressing = false;           end
		if  inputs.locked["altjump"] == true    then  player.altJumpKeyPressing = false;        end
		if  inputs.locked["run"] == true        then  player.runKeyPressing = false;            end
		if  inputs.locked["altrun"] == true     then  player.altRunKeyPressing = false;         end
		if  inputs.locked["dropitem"] == true   then  player.dropItemKeyPressing = false;       end
		if  inputs.locked["pause"] == true      then  player.pauseKeyPressing = false;          end
		
		-- disable all keys
		if  inputs.locked["all"] == true        then  
			player.upKeyPressing = false;
			player.downKeyPressing = false;
			player.leftKeyPressing = false;
			player.rightKeyPressing = false; 
			player.jumpKeyPressing = false;
			player.altJumpKeyPressing = false; 
			player.runKeyPressing = false;
			player.altRunKeyPressing = false;
			player.dropItemKeyPressing = false;
			player.pauseKeyPressing = false;
		end

		
	end

return inputs