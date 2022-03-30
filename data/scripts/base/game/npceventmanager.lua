local manager = {}

local tableremove = table.remove
local tableinsert = table.insert

if(isOverworld) then
	function manager.register() end --Prevents a crash if NPC code tries to run on the overworld
else
	local expandedDefines = require("expandedDefines")


	local eventsList = {};
	local npcsList = {};

	local npcKeys = {};
	
	local registeredNPCs = {};
	local registeredCount = 0;

	local events = {};
	
	local refreshList = nil;
	
	local function updateNPCregister(v)
		local id = v.id;
		if(not v.isGenerator and registeredNPCs[v] == nil) then
		
			--Add NPC to events list
			for _,l in ipairs(expandedDefines.LUNALUA_EVENTS) do
				local w = eventsList[l]
				if w ~= nil then
					if(w[id] ~= nil) then
						tableinsert(npcsList[l], v);
					end
				end
			end
			
			--Add a linked list element to the end of the registeredNPCs table
			local last = registeredNPCs[1]
			registeredNPCs[v] = {id, last};
			
			--Update the index of the old "last" element, or if there wasn't one, set the "first" element
			if last ~= nil then
				registeredNPCs[last][3] = v
			else
				registeredNPCs[0] = v
			end
			
			--Update the "last" index pointer
			registeredNPCs[1] = v
			
			registeredCount = registeredCount + 1;
		end
	end
	
	local function refreshEvents_internal(t)
		local removalList = nil;
		
		--Validate state of existing NPCs, queueing them for removal if their ID changes or they are no longer valid
		do
			--registeredNPCs is a linked list that can be indexed by lookup - registeredNPCs[0] is the first index,  registeredNPCs[1] is the last index
			local k = registeredNPCs[0]
			while k ~= nil do
				local v = registeredNPCs[k]
				if(not k.isValid or k.id ~= v[1]) then
					
					local cur = registeredNPCs[k]
					if cur ~= nil then
						--Remove the NPC from the table
					
						local prevnpc = cur[2]
						local nxtnpc = cur[3]
					
						local prev = registeredNPCs[prevnpc]
						local nxt = registeredNPCs[nxtnpc]
						
						--Update previous entry's "next" pointer
						--If there is no previous entry, update the "first" index
						if prev == nil then
							registeredNPCs[0] = nxtnpc
						else
							prev[3] = nxtnpc
						end
						
						--Update next entry's "previous" pointer
						--If there is no next entry, update the "last" index
						if nxt == nil then
							registeredNPCs[1] = prevnpc
						else
							nxt[2] = prevnpc
						end
						
						--Remove the element from the list
						registeredNPCs[k] = nil;
					
						registeredCount = registeredCount - 1;
					end
					
					if(k.isValid) then --npc has changed ID, so queue it for removal (this isn't necessary for isValid checks)
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
		
		--Remove queued NPCs that are not valid or consistent from the event tables
		if(removalList ~= nil) then
			for _,v in ipairs(expandedDefines.LUNALUA_EVENTS) do
				local w = npcsList[v]
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
		
		--Register new NPCs
		if t == nil then
			for _,v in NPC.iterateByFilterMap(npcKeys) do
				updateNPCregister(v)
			end
		else
			for i = 1,#t do
				updateNPCregister(t[i])
			end
		end
	end

	local function event(name, a, b, c, d)
		local i = 1;
		while i <= #npcsList[name] do
			local v = npcsList[name][i];
			if(v.isValid) then
				local events = eventsList[name][v.id];
				if(events == nil) then --NPC has transformed to something that doesn't use this event
					tableremove(npcsList[name],i);
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
				tableremove(npcsList[name],i);
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

	local function makeEvent(name)
		return function(a, b, c, d) event(name, a, b, c, d) end
	end

	function manager.register(id, tbl, eventName, apiEvent)
		if(eventsList[eventName] == nil) then
			events[eventName] = makeEvent(eventName);
			registerEvent(events, eventName, eventName, false);
			eventsList[eventName] = {};
			npcsList[eventName] = {};
		end
		if(eventsList[eventName][id] == nil) then
			eventsList[eventName][id] = {};
		
			npcKeys[id] = true
		end
		tableinsert(eventsList[eventName][id], {api = tbl, name = apiEvent});
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
			elseif(type(t) == "NPC") then
				tableinsert(refreshList, t);
			else
				error("Invalid argument given to function 'refreshEvents'. Expected nil, table, or NPC.", 3);
			end	
		end
	end
	
	function manager.update()
		refreshEvents_internal();
	end
end

return manager;