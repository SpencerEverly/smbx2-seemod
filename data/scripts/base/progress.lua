---------------------------------
--! @file
--! @brief This library controls the game's achievement framework.
---------------------------------

local iniparse = require("configFileReader")
local lunajson = require("ext\\lunajson")
local textplus = require("textplus")

local progress = {};

local EPISODEPATH = Misc.episodePath():gsub([[[\/]+]], [[/]]);
local SMBXPATH = (Native.getSMBXPath() .. "/"):gsub([[[\/]+]], [[/]]);
local noGoodEpiosodeFolder = (EPISODEPATH == SMBXPATH)

local savedata;
local savepath = EPISODEPATH.."progress.json";

local maxProgress = 0


if noGoodEpiosodeFolder then
	savedata = {}
else
	--create file 
	local f = io.open(savepath,"r");
	if f == nil then
		local savefile = io.open(savepath, "w")
		savefile:write("")
		savefile:close()
	else
		f:close()
	end
	
	savefile = io.open(savepath, "r")
	local content = savefile:read("*all")
    savefile:close()
	if content ~= "" then
		savedata = lunajson.decode(content)
	else
		savedata = {}
	end
	
	
	local launcher = io.open(EPISODEPATH.."launcher/info.json", "r")
	if launcher ~= nil then
		local lcontent = launcher:read("*all")
		launcher:close()
		if content ~= "" then
			local ldata = lunajson.decode(lcontent)
			if type(ldata.maxProgress) == "number" and ldata.maxProgress > 0 then
				maxProgress = ldata.maxProgress
			end
		end
	end
end

local function listFiles(path)
	if(path == nil) then
		return {};
	end
	return Misc.listFiles(path) or {};
end

local achs = {};

local nameIndex = {};

local collectionQueue = {};

local greyscaleshader = Shader();
greyscaleshader:compileFromSource(nil, "#version 120 \n uniform sampler2D iChannel0; void main() { vec4 c = texture2D( iChannel0, gl_TexCoord[0].xy); float v = (c.r+c.g+c.b)*0.33; gl_FragColor.rgb = c.a*gl_Color.a*v*gl_Color.rgb; gl_FragColor.a = c.a*gl_Color.a; }");

function progress.onInitAPI()
	registerEvent(progress, "onEvent");
	registerEvent(progress, "onDraw");
	registerEvent(progress, "onStart");
end

local function save()
	if noGoodEpiosodeFolder then return end
	
	savedata = {};
	for k,v in pairs(achs) do
		k = tostring(k)
		if(savedata[k] == nil) then
			savedata[k] = {};
		end
		--savedata[k].name = v:getName();
		--savedata[k].desc = v:getDesc();
		--savedata[k].hidden = v.hidden;
		savedata[k].c = v.collected;
		savedata[k].s = v.collected and v.popupShown;
		for l,m in pairs(v.conditions) do
			l = tostring(l);
			if(savedata[k][l] == nil) then
				savedata[k][l] = {};
			end
			--savedata[k][l].desc = m.desc;
			if(v.collected) then
				if(m.conditiontype == "number") then
					savedata[k][l].v = m.max;
					savedata[k][l].m = m.max;
				else
					savedata[k][l].v = true;
				end
			else
				savedata[k][l].v = m.value;
				if(m.conditiontype == "number") then
					savedata[k][l].m = m.max;
				end
			end
		end
	end
	local savefile = io.open(savepath, "w+");
	savefile:write(lunajson.encode(savedata));
	savefile:close();
end

local function checkConditions(ach, delayPopup)
		local done = true;
		local hasRun = false;
		for k,v in pairs(ach.conditions) do
			hasRun = true;
			if(v.conditiontype == "number" and v.value < v.max) then
				done = false;
				break;
			elseif((v.conditiontype == "boolean" or v.conditiontype == "event") and not v.value) then
				done = false;
				break;
			end
		end
		if(done and hasRun) then
			ach:collect(delayPopup);
		end
		save();
end

local function getcondition(t,v)
	return t.conditions[v];
end

local function setcondition(t,index,value, delayPopup)
	local c = t:getCondition(index);
	if(c) then
		if(c.conditiontype == "number") then
			c.value = math.min(c.max, value);
		elseif(c.conditiontype == "boolean" or c.conditiontype == "event") then
			c.value = value;
		end
		checkConditions(t, delayPopup);
	else
		Misc.warn("No condition with ID "..index.." exists for this achievement.")
	end
end

local function resetcondition(t,index)
	local c = t:getCondition(index);
	if(c) then
		if(c.conditiontype == "number") then
			c.value = 0;
		elseif(c.conditiontype == "boolean" or c.conditiontype == "event") then
			c.value = false;
		end
		checkConditions(t);
	else
		Misc.warn("No condition with ID "..index.." exists for this achievement.")
	end
end

--reset, but don't uncollect, achievement progress
local function resetachievement(t)
	for k,_ in pairs(t.conditions) do
		t:resetCondition(t,k);
	end
end

local function progresscondition(t,index, delayPopup)
	local c = t:getCondition(index);
	if(c) then
		if(c.conditiontype == "number") then
			c.value = math.min(c.max, c.value+1);
		elseif(c.conditiontype == "boolean" or c.conditiontype == "event") then
			c.value = true;
		end
		checkConditions(t, delayPopup);
	else
		Misc.warn("No condition with ID "..index.." exists for this achievement.")
	end
end

local function drawicon(t, x, y, w, h, priority)
	local icon;
	local shader;
	if(t.collected) then
		icon = t.icon;
	elseif(t.lockedicon == nil) then
		icon = t.icon;
		shader = greyscaleshader;
	else
		icon = t.lockedicon;
	end
	
	if icon == nil then
		icon = Graphics.sprites.hardcoded[55].img
	end
	
	Graphics.glDraw{vertexCoords = {x, y, x+w, y, x+w, y+h, x, y+h}, textureCoords = {0,0,1,0,1,1,0,1}, texture = icon, priority = priority, shader = shader, primitive = Graphics.GL_TRIANGLE_FAN}
end

local function getname(t)
	if(not t.collected and t.hidden) then
		return "Hidden Achievement";
	else
		return t.name;
	end
end

local function getdescription(t)
	if(not t.collected and t.hidden) then
		return "Unlock to find out more about this achievement.";
	elseif(t.collected and t.collectedDescription ~= nil) then
		return t.collectedDescription;
	else
		return t.description;
	end
end

local function forcecollect(t,delayPopup)
		if(delayPopup == nil) then
			delayPopup = false;
		end
		rawset(t, "__CLTD", true);
		rawset(t, "__PSHWN", not delayPopup);
		if(not delayPopup) then
			table.insert(collectionQueue,{t=0,ach=t});
		end
		save();
end

local function collect(t, delayPopup)
	if(t.collected) then
		return;
	else
		forcecollect(t, delayPopup);
	end
end

local function genAchMT(data)
	local mt = {};
	mt.__index = function(t,k)
		if(k == "name") then
			return data.name;
		elseif(k == "id") then
			return data.id;
		elseif(k == "description") then
			return data.description;
		elseif(k == "collectedDescription") then
			return data.collectedDescription;
		elseif(k == "hidden") then
			return data.hidden;
		elseif(k == "icon") then
			return data.icon;
		elseif(k == "lockedicon") then
			return data.lockedicon;
		elseif(k == "conditions") then
			return data.conditions;
		elseif(k == "collected") then
			return t.__CLTD;
		elseif(k == "popupShown") then
			return t.__PSHWN;
		elseif(k == "getCondition") then
			return getcondition;
		elseif(k == "setCondition") then
			return setcondition;
		elseif(k == "resetCondition") then
			return resetcondition;
		elseif(k == "reset") then
			return resetachievement;
		elseif(k == "progressCondition") then
			return progresscondition;
		elseif(k == "collect") then
			return collect;
		elseif(k == "drawIcon") then
			return drawicon;
		elseif(k == "getName") then
			return getname;
		elseif(k == "getDesc" or k == "getDescription") then
			return getdescription;
		end
	end
	
	mt.__newindex = function(t,k,v)
		Misc.warn("Achievments cannot be modified at runtime.", 2);
	end
	
	return mt;
end

local function loadAchs(p)
	local files = listFiles(p);
	
	for _,v in ipairs(files) do
		v = string.lower(v);
		local n = tonumber(string.match(v, "^ach%-(%d+)%.ini$"));
		if(n) then
			achs[n] = iniparse.rawParse(p.."\\"..v);
			if(achs[n]) then
				if(achs[n].name == nil) then
					achs[n].name = "Achievement "..n;
				end
				if(achs[n].description == nil) then
					if(achs[n].desc == nil) then
						achs[n].description = "Perform the required task to unlock this achievement.";
					else
						achs[n].description = achs[n].desc;
						achs[n].desc = nil;
					end
				end
				if(achs[n].collectedDescription == nil) then
					if(achs[n]["collected-description"] ~= nil) then
						achs[n].collectedDescription = achs[n]["collected-description"];
						achs[n]["collected-description"] = nil;
					elseif(achs[n]["collected-desc"] ~= nil) then
						achs[n].collectedDescription = achs[n]["collected-desc"];
						achs[n]["collected-desc"] = nil;
					end
				end
				if(achs[n].hidden == nil) then
					achs[n].hidden = false;
				end
				if(nameIndex[achs[n].name]) then
					Misc.warn("Achievement with the name '"..achs[n].name.."' already exists.")
				end
				nameIndex[achs[n].name] = n;
				local conditions = {};
				local a = tostring(n);
				for l,m in pairs(achs[n]) do
					local b = string.match(l:lower(),"condition%-(%d+)$");
					if(b) then
						local cond = tonumber(b);
						if(type(m) == "number") then
							local t = {};
							if(savedata[a] and savedata[a][b]) then
								t.value = math.min(savedata[a][b].v or 0, m);
								savedata[a][b].v = t.value;
								savedata[a][b].m = m;
							else
								t.value = 0;
							end
							t.max = m;
							t.conditiontype = "number";
							if(conditions[cond] and conditions[cond].desc) then
								t.desc = conditions[cond].desc;
							end
							conditions[cond] = t;
						elseif(type(m) == "boolean") then
							local t = {};
							if(savedata[a] and savedata[a][b]) then
								t.value = savedata[a][b].v;
								if(t.value == nil) then
									t.value = false;
								end
								savedata[a][b].v = t.value;
							else
								t.value = false;
							end
							t.conditiontype = "boolean";
							if(conditions[cond] and conditions[cond].desc) then
								t.desc = conditions[cond].desc;
							end
							conditions[cond] = t;
						elseif(type(m) == "string") then
							local t = {};
							if(savedata[a] and savedata[a][b]) then
								t.value = savedata[a][b].v;
								if(t.value == nil) then
									t.value = false;
								end
								savedata[a][b].v = t.value;
							else
								t.value = false;
							end
							t.event = m;
							t.conditiontype = "event";
							if(conditions[cond] and conditions[cond].desc) then
								t.desc = conditions[cond].desc;
							end
							conditions[cond] = t;
						end
						achs[n]["condition-"..b] = nil;
					end
					b = string.match(l:lower(),"condition%-(%d+)-desc$");
					if(b) then
						local cond = tonumber(b);
						if(savedata[a] and savedata[a][b]) then
							savedata[a][b].desc = m;
						end
						if(conditions[cond] == nil) then
							conditions[cond] = {}
						end
						conditions[cond].desc = m;
					end
				end
				achs[n].conditions = conditions;
				if(savedata[a]) then
					achs[n].collected = savedata[a].c;
					achs[n].popupShown = savedata[a].s;
				end
				if(achs[n].collected == nil) then
					achs[n].collected = false;
				end
				if(achs[n].popupShown == nil) then
					achs[n].popupShown = false;
				end
			end
		end
	end
end

local function loadAchIcons(p)
	local files = listFiles(p);
	for _,v in ipairs(files) do
		v = string.lower(v);
		local n = tonumber(string.match(v, "ach%-(%d+)%.png$"));
		if(achs[n]) then
			achs[n].icon = Graphics.loadImage(p.."\\"..v);
		end
		
		local n = tonumber(string.match(v, "ach%-(%d+)l%.png$"));
		if(achs[n]) then
			achs[n].lockedicon = Graphics.loadImage(p.."\\"..v);
		end
	end
end

do
	--Load achievements - loaded later = higher priority
	loadAchs(EPISODEPATH.."achievements");
	--loadAchs(EPISODEPATH);
	
	loadAchIcons(EPISODEPATH.."achievements");
	--loadAchIcons(EPISODEPATH);
	
	for n,v in pairs(achs) do
		local data = {};
		data.__CLTD = achs[n].collected;
		data.__PSHWN = achs[n].popupShown;
		achs[n].id = n;
		setmetatable(data, genAchMT(achs[n]));
		achs[n] = data;
	end
	
	save();

end

function progress.onEvent(name)
	for _,v in pairs(achs) do
		for l,m in pairs(v.conditions) do
			if(m.conditiontype == "event" and m.event == name) then
				v:progressCondition(l);
			end
		end
	end
end

progress.ALIGN_LEFT = 0;
progress.ALIGN_RIGHT = 1;
progress.ALIGN_CENTRE = 2;

function progress.drawDefaultPopup(achievement, t, x, y, align, z)
	local iconSize = 64;
	local textSize = 256;
	local size = iconSize+textSize;
	local hs = iconSize*0.5
	local bgc = {0,0.6,1,0.66};
	
	local steps = {15,30,145,160,170}
	
	if(t < steps[1] or (t >= steps[4] and t < steps[5])) then
		local p;
		if(t < steps[1]) then
			p = t/steps[1];
		else
			p = 1-(t-steps[4])/(steps[5]-steps[4]);
		end
		local h = math.lerp(0,iconSize,p);
		Graphics.glDraw{vertexCoords={x-hs-2,y-h*0.5-2,x-hs+iconSize+2,y-h*0.5-2,x-hs+iconSize+2,y+h*0.5+2,x-hs-2,y+h*0.5+2}, primitive = Graphics.GL_TRIANGLE_FAN, color=bgc, priority = z}
		y = y + math.lerp(hs,0,p)
		achievement:drawIcon(x-hs,y-hs,iconSize,h,z);
	elseif(t < steps[2] or (t >= steps[3] and t < steps[4])) then
		local p;
		if(t < steps[2]) then
			p = (t - steps[1])/(steps[2]-steps[1]);
		else
			p = 1-((t - steps[3])/(steps[4]-steps[3]));
		end
		if(align == progress.ALIGN_CENTRE) then
			x = math.lerp(x,x-(textSize)*0.5,p);
			size = math.lerp(iconSize,size,p);
			Graphics.glDraw{vertexCoords={x-hs-2,y-hs-2,x-hs+size+2,y-hs-2,x-hs+size+2,y+hs+2,x-hs-2,y+hs+2}, primitive = Graphics.GL_TRIANGLE_FAN, color=bgc, priority = z}
		elseif(align == progress.ALIGN_RIGHT) then
			x = math.lerp(x,x-(textSize),p);
			size = math.lerp(iconSize,size,p);
			Graphics.glDraw{vertexCoords={x-hs-2,y-hs-2,x-hs+size+2,y-hs-2,x-hs+size+2,y+hs+2,x-hs-2,y+hs+2}, primitive = Graphics.GL_TRIANGLE_FAN, color=bgc, priority = z}
		elseif(align == progress.ALIGN_LEFT) then
			size = math.lerp(iconSize,size,p);
			Graphics.glDraw{vertexCoords={x-hs-2,y-hs-2,x-hs+size+2,y-hs-2,x-hs+size+2,y+hs+2,x-hs-2,y+hs+2}, primitive = Graphics.GL_TRIANGLE_FAN, color=bgc, priority = z}
		end
		achievement:drawIcon(x-hs,y-hs,iconSize,iconSize,z);
	elseif(t < steps[3]) then
		if(align == progress.ALIGN_CENTRE) then
			x = x-(textSize)*0.5;
		elseif(align == progress.ALIGN_RIGHT) then
			x = x-(textSize);
		end
		Graphics.glDraw{vertexCoords={x-hs-2,y-hs-2,x-hs+size+2,y-hs-2,x-hs+size+2,y+hs+2,x-hs-2,y+hs+2}, primitive = Graphics.GL_TRIANGLE_FAN, color=bgc, priority = z}
		achievement:drawIcon(x-hs,y-hs,iconSize,iconSize,z);
		textplus.print{text = "ACHIEVEMENT UNLOCKED<br>"..achievement:getName(), x=x+hs+8,y=y, maxWidth=textSize, xscale=2, yscale=2, pivot={0,0.5}, priority=z}
		--textblox.printExt("<b>ACHIEVEMENT UNLOCKED</b><br>"..achievement:getName(),{x=x+hs+8,y=y,width=textSize,font=textblox.FONT_SPRITEDEFAULT4X2,valign=textblox.VALIGN_MID,color=0xFFFFFFFF,priority=z})
	else
		return true;
	end
	return false;
end

--! @brief Overridable function for drawing achievement popups. Return true when the popup is complete.
--! @param achievement The achievement object to be drawn.
--! @param t Number of frames that have passed since collection.
--! @return Return true or false depending on whether the popup has finished drawing.
function progress.drawPopup(achievement,t)
	return progress.drawDefaultPopup(achievement, t, 800-32, 112, progress.ALIGN_RIGHT, 10);
end

function progress.onStart()
	for _,v in pairs(achs) do
		if(v.collected and not v.popupShown) then
			forcecollect(v);
		end
	end
end

function progress.onDraw()
	
	if(collectionQueue[1]) then
		if(progress.drawPopup(collectionQueue[1].ach, collectionQueue[1].t)) then
			table.remove(collectionQueue,1);
		else
			collectionQueue[1].t = collectionQueue[1].t+1;
		end
	end
end

--! @brief Retrieve a single or all achievement objects.
--! @param index The desired achievement object's index.
--! @return Returns the achievement of the specified index. If no index is provided, this function returns all achievements.
function progress.getAchievements(index)
	if(index == nil) then
		return table.clone(achs);
	else
		return progress.getAchievement(index);
	end
end

--! @brief Retrieve a single achievement object.
--! @param index The desired achievement object's index.
--! @return Returns the achievement of the specified index.
function progress.getAchievement(index)
	if(type(index) == "string") then
		index = nameIndex[index];
	end
	return achs[index];
end

local aclass = {}

local gmt = {}

function gmt.__index(t,k)
	if k == "get" then
		return progress.getAchievements
	elseif k == "drawPopup" then
		return progress.drawPopup
	elseif k == "drawDefaultPopup" then
		return progress.drawDefaultPopup
	end
end

function gmt.__newindex(t,k,v)
	if k == "get" or k == "drawDefaultPopup" then
		return
	elseif k == "drawPopup" then
		progress.drawPopup = v
	else
		rawset(t,k,v)
	end
end

function gmt.__call(t, id)
	return achs[id]
end

setmetatable(aclass, gmt)
_G["Achievements"] = aclass

local prog = {}
local pmt = {}
pmt.__index = function(t,k)
	if k == "progress" then
		return SaveData.__progress
	elseif k == "savename" then
		return SaveData.__savefilename
	elseif k == "maxProgress" then
		return maxProgress
	end
end
pmt.__newindex = function(t,k,v)
	if k == "value" then
		SaveData.__progress = v
	elseif k == "savename" then
		SaveData.__savefilename = v
	elseif k == "maxProgress" then
		error("The field "..k.." is read-only.", 2)
	end
end

setmetatable(prog, pmt)
_G["Progress"] = prog

return progress;