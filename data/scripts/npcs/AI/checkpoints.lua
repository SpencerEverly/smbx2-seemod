local cps = require("checkpoints")
local utils = require("npcs/npcutils")

local checkpoint = {}

local regIDs = {}
local stateIDs = {}

function checkpoint.addID(id, stateful)
	if stateful then
		stateIDs[id] = true
	else
		regIDs[id] = true
	end
end

function checkpoint.getActiveID()
	--Get the current active checkpoint ID
	local currentcheckpoint = cps.getActive()
	if currentcheckpoint then
		currentcheckpoint = currentcheckpoint.id
	end
	
	return currentcheckpoint
end

checkpoint.doLayerMove = utils.applyLayerMovement
--Move checkpoints with layers


function checkpoint.onNPCKill(eventobj,c,reason)
	local id = c.id
	if regIDs[id] or stateIDs[id] then
		local cancel = true
		if reason == 9 then
			for _,p in ipairs(Player.get()) do
			
				if Colliders.collide(c, p) or Colliders.slash(p,c) or Colliders.downSlash(p,c) then
					if c.data._basegame.checkpoint ~= nil then
						c.data._basegame.checkpoint:collect(p)
						
						if stateIDs[id] then
							--If we collected a flag checkpoint, set the flag state
							if c.data._basegame.state == nil or c.data._basegame.state == 0 then
								c.data._basegame.state = 1
								c.data._basegame.frame = 0
							end
						else
							--If we collected a SMW checkpoint, let it die
							cancel = false
						end
						
					end
					
					--Spawn sparkles
					if regIDs[id] or (c.data._basegame.state == 1 and c.data._basegame.frame == 0 and c.data._basegame.checkpoint ~= nil) then
						local a = Animation.spawn(78, c.x + c.width*0.5, c.y + c.height*0.5)
						a.x = a.x - a.width*0.5
						a.y = a.y - a.height*0.5
					end
					
				end
			end
		end
		
		--If we need to, cancel the death event
		if stateIDs[id] or (c.data._basegame.checkpoint ~= nil and not c.data._basegame.checkpoint.collected) then
			eventobj.cancelled = cancel
		end
	end
	
end

return checkpoint