local manager = {}

local tableremove = table.remove
local tableinsert = table.insert

if(isOverworld) then
	function manager.register() end --Prevents a crash if Block code tries to run on the overworld
else
	local expandedDefines = require("expandedDefines")


	local eventsList = {};
	local blockList = {};

	local blockKeys = {};
	
	local registeredBlocks = {};
	local registeredCount = 0;

	local events = {};
	
	local refreshList = nil;
	
	local function updateBlockRegister(v)
		local id = v.id;
		if(registeredBlocks[v] == nil) then
		
			--Add Block to events list
			for _,l in ipairs(expandedDefines.LUNALUA_EVENTS) do
				local w = eventsList[l]
				if w ~= nil then
					if(w[id] ~= nil) then
						tableinsert(blockList[l], v);
					end
				end
			end
			
			--Add a linked list element to the end of the registeredBlocks table
			local last = registeredBlocks[1]
			registeredBlocks[v] = {id, last};
			
			--Update the index of the old "last" element, or if there wasn't one, set the "first" element
			if last ~= nil then
				registeredBlocks[last][3] = v
			else
				registeredBlocks[0] = v
			end
			
			--Update the "last" index pointer
			registeredBlocks[1] = v
			
			registeredCount = registeredCount + 1;
		end
	end
	
	local function refreshEvents_internal(t)
		local removalList = nil;
		
		--Validate state of existing blocks, queueing them for removal if their ID changes or they are no longer valid
		do
			--registeredBlocks is a linked list that can be indexed by lookup - registeredBlocks[0] is the first index,  registeredBlocks[1] is the last index
			local k = registeredBlocks[0]
			while k ~= nil do
				local v = registeredBlocks[k]
				if(not k.isValid or k.id ~= v[1]) then
					
					local cur = registeredBlocks[k]
					if cur ~= nil then
						--Remove the block from the table
					
						local prevblk = cur[2]
						local nxtblk = cur[3]
					
						local prev = registeredBlocks[prevblk]
						local nxt = registeredBlocks[nxtblk]
						
						--Update previous entry's "next" pointer
						--If there is no previous entry, update the "first" index
						if prev == nil then
							registeredBlocks[0] = nxtblk
						else
							prev[3] = nxtblk
						end
						
						--Update next entry's "previous" pointer
						--If there is no next entry, update the "last" index
						if nxt == nil then
							registeredBlocks[1] = prevblk
						else
							nxt[2] = prevblk
						end
						
						--Remove the element from the list
						registeredBlocks[k] = nil;
					
						registeredCount = registeredCount - 1;
					end
					
					if(k.isValid) then --Block has changed ID, so queue it for removal (this isn't necessary for isValid checks)
						if(removalList == nil) then
							removalList = {};
						end
						removalList[k] = true;
					end
				end
				
				--Step through the linked list
				k = v[3]
				
			end
		end
		
		--Remove queued blocks that are not valid or consistent from the event tables
		if(removalList ~= nil) then
			for _,v in ipairs(expandedDefines.LUNALUA_EVENTS) do
				local w = blockList[v]
				if w ~= nil then
					local j = #w;
					while j >= 1 do
						if(removalList[w[j]]) then
							tableremove(w,j);
						end
						j = j-1;
					end
				end
			end
		end
		
		--Register new blocks
		if t == nil then
			for _,v in Block.iterateByFilterMap(blockKeys) do
				updateBlockRegister(v)
			end
		else
			for i = 1,#t do
				updateBlockRegister(t[i])
			end
		end
	end

	local function event(name, a, b, c, d)
		local i = 1;
		while i <= #blockList[name] do
			local v = blockList[name][i];
			if(v.isValid) then
				local events = eventsList[name][v.id];
				if(events == nil) then --Block has transformed to something that doesn't use this event
					tableremove(blockList[name],i);
				else
					for j = 1,#events do
						local w = events[j]
						if w.api[w.name] ~= nil then
							w.api[w.name](v, a, b, c, d);
						end
					end
					i = i + 1;
				end
			else
				tableremove(blockList[name],i);
			end
		end
		
		if(refreshList ~= nil) then
			if(#refreshList == 0) then
				refreshEvents_internal()
			else
				refreshEvents_internal(refreshList);
			end
			refreshList = nil;
		end
		
	end

	local function custom_event(name, call, a, b, c)
		local i = 1;
		while i <= #blockList[name] do
			local v = blockList[name][i];
			if(v.isValid) then
				local events = eventsList[name][v.id];
				if(events == nil) then --Block has transformed to something that doesn't use this event
					tableremove(blockList[name],i);
				else
					for j = 1,#events do
						local w = events[j]
						if w.api[w.name] ~= nil then
							call(w.api[w.name], v, a, b, c);
						end
					end
					i = i + 1;
				end
			else
				tableremove(blockList[name],i);
			end
		end
		
		if(refreshList ~= nil) then
			if(#refreshList == 0) then
				refreshEvents_internal()
			else
				refreshEvents_internal(refreshList);
			end
			refreshList = nil;
		end
		
	end

	-- Potentially ugly implementation of onCollideBlock
	
	local col_box = Colliders.Box(0,0,1,1)
	local col_tri = Colliders.Tri(0,0,{0,0},{0,1},{1,0})

	local function getBlockHitbox(id, x, y, wid, hei, swell)
		local cfg = Block.config[id]
		if cfg.floorslope == -1 then --Slope bottomleft to topright floor
			local vs = col_tri.v
			local cx = (0 + wid + wid)/3
			local cy = (hei + 0 + hei)/3
			
			local h = math.sqrt(wid*wid + hei*hei)/3
			local s = (h+swell)/h
			--local s = math.max((wid + swell)/wid, (hei + swell)/hei)
			
			vs[1][1] = (0  -cx)*s + cx
			vs[1][2] = (hei-cy)*s + cy

			vs[2][1] = (wid-cx)*s + cx
			vs[2][2] = (0  -cy)*s + cy

			vs[3][1] = (wid-cx)*s + cx
			vs[3][2] = (hei-cy)*s + cy	
			
			col_tri.minX = vs[1][1]
			col_tri.maxX = vs[2][1]
			col_tri.minY = vs[2][2]
			col_tri.maxY = vs[1][2]
			
			--[[			
			vs[1][1] = wid*0.5*(1 - s)
			vs[1][2] = hei*0.5*(1 + s)

			vs[2][1] = wid*0.5*(1 + s)
			vs[2][2] = hei*0.5*(1 - s)

			vs[3][1] = wid*0.5*(1 + s)
			vs[3][2] = hei*0.5*(1 + s)
			]]

			col_tri.x = x
			col_tri.y = y

			return col_tri

		elseif cfg.floorslope == 1 then --Slope topleft to bottomright floor
			local vs = col_tri.v
			local cx = (0 + wid + 0)/3
			local cy = (0 + hei + hei)/3
			
			local h = math.sqrt(wid*wid + hei*hei)/3
			local s = (h+swell)/h
			--local s = math.max((wid + swell)/wid, (hei + swell)/hei)

			vs[1][1] = (0  -cx)*s + cx
			vs[1][2] = (0  -cy)*s + cy

			vs[2][1] = (wid-cx)*s + cx
			vs[2][2] = (hei-cy)*s + cy	

			vs[3][1] = (0  -cx)*s + cx
			vs[3][2] = (hei-cy)*s + cy	
			
			col_tri.minX = vs[1][1]
			col_tri.maxX = vs[2][1]
			col_tri.minY = vs[1][2]
			col_tri.maxY = vs[2][2]
			
			--[[
			vs[1][1] = wid*0.5*(1 - s)
			vs[1][2] = hei*0.5*(1 - s)

			vs[2][1] = wid*0.5*(1 + s)
			vs[2][2] = hei*0.5*(1 + s)

			vs[3][1] = wid*0.5*(1 - s)
			vs[3][2] = hei*0.5*(1 + s)
			]]

			col_tri.x = x
			col_tri.y = y

			return col_tri

		elseif cfg.ceilingslope == -1 then --Slope bottomleft to topright ceil
			local vs = col_tri.v
			local cx = (0 + wid + 0)/3
			local cy = (0 + 0 + hei)/3
			
			local h = math.sqrt(wid*wid + hei*hei)/3
			local s = (h+swell)/h
			--local s = math.max((wid + swell)/wid, (hei + swell)/hei)
			
			vs[1][1] = (0  -cx)*s + cx
			vs[1][2] = (0  -cy)*s + cy

			vs[2][1] = (wid-cx)*s + cx
			vs[2][2] = (0  -cy)*s + cy

			vs[3][1] = (0  -cx)*s + cx
			vs[3][2] = (hei-cy)*s + cy
			
			col_tri.minX = vs[1][1]
			col_tri.maxX = vs[2][1]
			col_tri.minY = vs[1][2]
			col_tri.maxY = vs[3][2]
			
			--[[
			vs[1][1] = wid*0.5*(1 - s)
			vs[1][2] = hei*0.5*(1 - s)

			vs[2][1] = wid*0.5*(1 + s)
			vs[2][2] = hei*0.5*(1 - s)

			vs[3][1] = wid*0.5*(1 - s)
			vs[3][2] = hei*0.5*(1 + s)
			]]

			col_tri.x = x
			col_tri.y = y

			return col_tri

		elseif cfg.ceilingslope == 1 then --Slope topleft to bottomright ceil
			local vs = col_tri.v
			local cx = (0 + wid + wid)/3
			local cy = (0 + 0 + hei)/3
			
			local h = math.sqrt(wid*wid + hei*hei)/3
			local s = (h+swell)/h
			--local s = math.max((wid + swell)/wid, (hei + swell)/hei)

			vs[1][1] = (0  -cx)*s + cx
			vs[1][2] = (0  -cy)*s + cy

			vs[2][1] = (wid-cx)*s + cx
			vs[2][2] = (0  -cy)*s + cy

			vs[3][1] = (wid-cx)*s + cx
			vs[3][2] = (hei-cy)*s + cy
			
			col_tri.minX = vs[1][1]
			col_tri.maxX = vs[2][1]
			col_tri.minY = vs[1][2]
			col_tri.maxY = vs[3][2]
			
			--[[
			vs[1][1] = wid*0.5*(1 - s)
			vs[1][2] = hei*0.5*(1 - s)

			vs[2][1] = wid*0.5*(1 + s)
			vs[2][2] = hei*0.5*(1 - s)

			vs[3][1] = wid*0.5*(1 + s)
			vs[3][2] = hei*0.5*(1 + s)
			]]

			col_tri.x = x
			col_tri.y = y

			return col_tri

		else
		
			col_box.width = wid + swell
			col_box.height = hei + swell
			col_box.x = x - swell * 0.5
			col_box.y = y - swell * 0.5

			return col_box

		end
	end
	
	manager.getBlockHitbox = getBlockHitbox

	local function collidingNPCFilter(n)
		return not n.isHidden and (n.collidesBlockBottom or n.collidesBlockUp or n.collidesBlockLeft or n.collidesBlockRight or n:mem(0x120,FIELD_BOOL));
	end

	local function call_onCollide(f, v, a, b, c)
		if not v.isValid or v.isHidden or v:mem(0x5A, FIELD_BOOL) or v:mem(0x5C, FIELD_BOOL) then return end
		
		for _,w in ipairs(Player.get()) do
			if(w.isValid and v:collidesWith(w) ~= 0) then
				f(v, w);
			end
		end
		local c = Colliders.getColliding {
			a = getBlockHitbox(v.id, v.x, v.y, v.width, v.height, 0.3),
			btype = Colliders.NPC,
			filter = collidingNPCFilter
		}
		for _,w in ipairs(c) do
			f(v, w);
		end
	end

	local calls = { --Allows us to register events in addition to regular events
	}

	local externalCalls = { --If another library ought to trigger the event, like in the case of onEvent
		onCollide = function(id) Block.config[id]._cancollide = true end,
	}

	local function makeEvent(name)
		return function(a, b, c, d) event(name, a, b, c, d) end
	end

	local function makeCustomEvent(name, call)
		return function(a, b, c, d) custom_event(name, call, a, b, c, d) end
	end

	function manager.register(id, tbl, eventName, apiEvent)
		if externalCalls[eventName] then
			externalCalls[eventName](id)
		end
		if(eventsList[eventName] == nil) then
			if calls[eventName] then
				events[eventName] = makeCustomEvent(eventName, calls[eventName]);
			elseif not externalCalls[eventName] then
				events[eventName] = makeEvent(eventName);
				registerEvent(events, eventName, eventName, false);
			end
			eventsList[eventName] = {};
			blockList[eventName] = {};
		end
		if(eventsList[eventName][id] == nil) then
			eventsList[eventName][id] = {};
		
			--Insert ID to ID list if necessary (if the eventsList table for this ID isn't nil, then we can guarantee this has been done already)
			local insertToAll = true;
			
			--TODO: Comment this out and replace it with the line below once Block.iterateByFilterMap exists
			--[[
			for i = 1,#blockKeys do
				if(blockKeys[i] == id) then
					insertToAll = false;
					break;
				end
			end
			if(insertToAll) then
				tableinsert(blockKeys, id);
			end
			]]
			blockKeys[id] = true
		end
		tableinsert(eventsList[eventName][id], {api = tbl, name = apiEvent});
	end

	function manager.callExternalEvent(name, obj, a, b, c)
		if eventsList[name] == nil then
			error("Event " .. name .. " does not exist.")
			return
		end
		if eventsList[name][obj.id] == nil then
			error("Event " .. name .. " not registered for block of ID" .. obj.id .. ".")
			return
		end
		for k,v in ipairs(eventsList[name][obj.id]) do
			v.api[v.name](obj, a, b, c)
		end
	end

	function manager.onInitAPI()
		registerEvent(manager, "onStart", "update", true);
		registerEvent(manager, "onTickEnd", "update", true);
	end
	
	function manager.refreshEvents(t)
		if(t == nil) then
			refreshList = {};
		elseif(refreshList == nil or #refreshList > 0) then
			if(refreshList == nil) then
				refreshList = {};
			end
			
			if(type(t) == "table") then
				for i = 1,#t do
					tableinsert(refreshList, t[i]);
				end
			elseif(type(t) == "Block") then
				tableinsert(refreshList, t);
			else
				error("Invalid argument given to function 'refreshEvents'. Expected nil, table, or Block.", 3);
			end	
		end
	end
	

	local soundmap = {}
	local soundfiltermap = {}
	local soundslist = {}
	local anysounds = false
	
	function manager.pushSound(id, s, v)
		if soundmap[id] == nil then
			soundmap[id] = {}
			soundfiltermap[id] = true
			tableinsert(soundslist, id)
			anysounds = true
		end
		tableinsert(soundmap[id], {s, v})
	end
	
	local function playQueuedSounds()
		if anysounds then
		
			local playsounds = {}
			local foundmap = {}
			local foundsounds = {}
			
			for _,c in ipairs(Camera.get()) do
				if c.idx == 1 or c:mem(0x20, FIELD_BOOL) then
					for _,v in Block.iterateIntersecting(c.x - 64, c.y - 64, c.x + c.width + 64, c.y + c.height + 64) do
						local id = v.id
						if soundmap[id] and not foundmap[id] and not v.isHidden then
							for _,s in ipairs(soundmap[v.id]) do
								if foundsounds[s[1]] == nil then
									tableinsert(playsounds, s[1])
									foundsounds[s[1]] = s[2]
								elseif s[2] > foundsounds[s[1]] then
									foundsounds[s[1]] = s[2]
								end
							end
							foundmap[v.id] = true
						end
					end
				end
			end

			for _,v in ipairs(playsounds) do
				SFX.play(v, foundsounds[v])
			end

			anysounds = false
			
			for i = 1,#soundslist do
				soundfiltermap[soundslist[i]] = nil
				soundmap[soundslist[i]] = nil
				soundslist[i] = nil
			end
		end
	end

	function manager.update()
		refreshEvents_internal();
		if events.onCollide then
			events.onCollide()
		end
		
		playQueuedSounds()
	end
end

return manager;