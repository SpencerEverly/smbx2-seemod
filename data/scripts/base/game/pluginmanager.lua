local lunajson = require("ext/lunajson")

local pluginManager = {};

local __FileType = "plg";

local pluginsList = {};
local pluginsMatch = "plugin_(.+)%."..__FileType;

local loadedPlugins = {};

local function FilterPlugins(list)
	for _,p in ipairs(list) do
		local name = p:match(pluginsMatch);
		if(name) then
			pluginsList[name] = p;
		end
	end
end

if(not isOverworld) then
	FilterPlugins(Misc.listLocalFiles(".."));
end

FilterPlugins(Misc.listLocalFiles(""));

for k,v in pairs(pluginsList) do
	local f = io.open(Misc.resolveFile(v), "r");
	if(pcall(function() loadedPlugins[k] = API.load("plugins\\"..k); end)) then
		loadedPlugins[k].Data = lunajson.decode(f:read("*all"));
	else
		Misc.warn("No manager for plugin_"..k..". Plugin will be ignored.");
	end
    f:close();
end

return pluginManager;