local dbg = {}

local function ineditor()
	return mem(0x00B2C62A, FIELD_WORD) == 0;
end

Misc.showWarnings = true;
Misc.logWarnings = true;

do --WARNINGS
	local msgq = {}
	local twarnstack = {};

	local textplus = require("textplus");

	local starttime;
	local lasttime;
	local warningOutputPath;

	local warninglog = "";
	local warnlayout = nil;

	local function updateLog()
		local i = 1;
		local m = "";
		while i <= #twarnstack do
			twarnstack[i].t = twarnstack[i].t - (os.clock()-lasttime);
			if(twarnstack[i].t <= 0) then
				table.remove(twarnstack,i);
			else
				if(i > #twarnstack-54) then
					if(m == "") then
						m = twarnstack[i].m;
					else
						m = m.."\n"..twarnstack[i].m;
					end
				end
				i = i + 1;
			end
		end
		if(warninglog ~= m) then
			warninglog = m;
			
			warnlayout = textplus.layout(textplus.parse(m, {color=Color.red}));
		end
	end
		
	function dbg.onInitAPI()
		registerEvent(dbg, "onExitLevel", "onExit", true);
		registerEvent(dbg, "onKeyboardPress", "onKeyboardPress", false);
		registerEvent(dbg, "onDraw", "onDraw", false);
		starttime = os.clock();
		lasttime = os.clock();
		
		updateLog();
	end

	function dbg.onKeyboardPress(keycode)
		if(keycode == VK_F6)then
			Misc.showWarnings = not Misc.showWarnings;
		end
	end

	function dbg.suppressWarnings(val)
		if(val == false) then
			Misc.logWarnings = true;
			Misc.showWarnings = true;
		else
			Misc.logWarnings = false;
			Misc.showWarnings = false;
		end
	end

	function dbg.warn(msg,offset)
		if(Misc.logWarnings or Misc.showWarnings) then
			if(offset == nil) then
				offset = 1;
			end
			msg = tostring(msg);
			local baseinfo = debug.getinfo(1);
			
			local m = debug.traceback();
			local _,i = m:find("in function 'warn'");
			i = i+1;
			m = "stack traceback:"..m:sub(i);
			
			local message;
			if(msg ~= nil) then
				message = ": "..msg;
			else
				message = ""
			end
			local tick = lunatime.tick();
			local info = debug.getinfo(offset+1);
			
			if(Misc.logWarnings) then
				table.insert(msgq, {m=tick.."t - Warning"..message.."\n"..m, rm = "\\b "..tick.."t - \\cf2 Warning"..message.."\\b0 \\cf1".."\n"..m})
			end
			
			if(msg ~= nil) then
				if(#msg > 60) then
					msg = msg:sub(0,57).."...";
				end
				message = ": "..msg.." - ";
			else
				msg = "";
				message = "arning: "
			end
			local tm = info.short_src:sub(info.short_src:match(".*[/\\]()") or 0)..": "..info.currentline;
			if(warningOutputPath == nil) then
				warningOutputPath = "logs\\WARNING_"..os.date("%Y-%m-%d_%H-%M-%S")..".txt";
			end
			table.insert(twarnstack, {m=tick.."t - Warning"..message..tm, t=5})
		end
	end

	function dbg.onExit()
		if(#msgq > 0 and Misc.logWarnings) then
			local m = "";
			local rm = "";
			for k,v in ipairs(msgq) do
				m = m..v.m;
				rm = rm..v.rm;
				if(k < #msgq) then
					m = m.."\n\n";
					rm = rm.."\n\n";
				end
			end
			Audio.MusicStop();
			Audio.SfxStop(-1);
			
			local f;
			m = "Execution ran for "..(os.clock()-starttime).."s ("..lunatime.tick().." ticks), and produced "..#msgq.." warnings:\n\n\n"..m;
			rm = "Execution ran for \\b "..(os.clock()-starttime).."s ("..lunatime.tick().." ticks)\\b0 , and produced \\b "..#msgq.." warnings\\b0 :\n\n\n"..rm;
			if(not pcall(function() f = io.open(getSMBXPath().."\\"..warningOutputPath,"w") end)) then
				error("Could not generate Warning file.")
			else
				f:write(m);
				f:close();
			end
			if(ineditor()) then
				rm = rm:gsub("\n","\\line ");
				Misc.showRichDialog(#msgq.." Warnings Logged","{\\rtf1{\\colortbl;\\red0\\green0\\blue0;\\red255\\green100\\blue0;}"..rm.."}", true);
			end
		end
	end

	function dbg.onDraw()
		if(ineditor() and #twarnstack > 0) then
			updateLog();
			
			lasttime = os.clock();
			
			if(Misc.showWarnings and warnlayout ~= nil) then
				textplus.render{x=4,y=4,layout=warnlayout,sceneCoords=false,priority=10};
			end
		end
	end
end


do --DIALOG
	local convertString;
	function convertString(val, history, depth)
		if(type(val) == "table") then
			local mt = getmetatable(val);
			if(mt and mt.__tostring) then
				return tostring(val);
			else
				local t = {};
				local largest = 0;
				for k,v in pairs(val) do
					if(depth < 10 and type(v) == "table" and not table.icontains(history, v)) then
						table.insert(history, v);
						t[k] = convertString(v, history, depth+1);
					else
						t[k] = tostring(v);
					end
					if(type(k) ~= "number") then
						largest = -1;
					elseif(k > largest) then
						largest = k;
					end
				end
				local split = ", ";
				local open = "{ ";
				local clse = " }";
				
				local isordered = largest >= 0
				if #t ~= largest then
					isordered = false
				else
					for i = 1,largest do
						if not t[i] then
							isordered = false
							break
						end
					end
				end
				if(not isordered) then
					local t2 = t;
					t = {};
					local i = 1;
					for k,v in pairs(t2) do
						if(depth < 10 and type(k)== "table" and not table.icontains(history, k)) then
							table.insert(history, k);
							t[i] = convertString(k, history, depth+1).." = "..v;
						else
							t[i] = tostring(k).." = "..v;
						end
							
						i = i+1;
					end
					split = ",   ";
					open = "{ ";
					clse = " }";
				end
				
				return open..table.concat(t, split)..clse;
			end
		else
			return tostring(val);
		end
	end

	local printer = {};
	function dbg.dialog(...)
		local t = {...};
		local largest = 0;
		for k,_ in pairs(t) do
			if(k > largest) then
				largest = k;
			end
		end
		
		if(largest == 0) then
			Text.windowDebug("nil");
		else
			local idx = 1;
			for i = 1,largest do
				printer[idx] = convertString(t[i], {t[i]}, 0);
				idx = idx + 1;
			end
			for i = #printer,idx,-1 do
				printer[i] = nil;
			end
			if(not pcall(Text.windowDebug,table.concat(printer, "\n"))) then
				error("Dialog window was closed. Selecting 'Cancel' will close the Lua environment.", 2)
			end
		end
	end
	
	function dbg.richDialog(title, content, readonly)
		if readonly == nil then
			readonly = true
			
			if content == nil then
				content = title
				title = "Dialog Window"
			elseif type(content) == "boolean" then
				readonly = content
				content = title
				title = "Dialog Window"
			end
		end
		
		if content == nil then
			content = "nil"
		else
			content = convertString(content, {content}, 0);
		end

		if(not pcall(Misc.showRichDialog, title, content, readonly)) then
			error("Dialog window was closed. Selecting 'Cancel' will close the Lua environment.", 2)
		end
	end
end

Misc.warn = dbg.warn;
Misc.suppressWarnings = dbg.suppressWarnings;
Misc.dialog = dbg.dialog;
Misc.richDialog = dbg.richDialog;

return dbg;