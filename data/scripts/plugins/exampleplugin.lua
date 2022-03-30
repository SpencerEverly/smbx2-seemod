--Plugin managers are APIs
local example = {};

--Plugin managers will not be loaded if no plugin data exists in the current level/episode
function example.onInitAPI()
	registerEvent(example, "onStart", "onStart", false);
end

--Plugin managers will automatically be populated with a "Data" table, containing the json data stored in the plugin file
function example.onStart()
	for k,v in pairs(example.Data) do
		windowDebug(tostring(k)..": "..tostring(v))
	end
end

--Like all APIs, plugin managers should return when finished
return example;