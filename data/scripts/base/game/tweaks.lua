----------------- HELLO FRIENDS ---------------------
-------------- I AM "THE SHIT CODE" -----------------
----- ARE YOU ENJOYING YOUR TIME IN THE FILES? ------
---- WELL NOW YOU WON'T BECAUSE THIS CODE SUCKS -----


-- tweaks.lua
-- created by pyro
-- available keywords:

-- startingCharacter
-- startingPowerup
-- startingMount
-- startingMountColor
-- filterReserveBox
-- playerGravModifier
-- npcGravModifier
-- fallSpeedModifier
-- jumpModifier
-- bounceModifier
-- timer
-- timerResult
-- timerEvent
-- useNSMBHitSystem
-- breathMeter
-- smwCamera
-- showHud
-- section(section number)Speed
-- section(section number)Direction
-- showDeaths

-- API init --
local configFileReader = require("configFileReader")
local timerApi = require("timer")
local autoscroll = require("autoscroll")

local tweaks = {}

local triggeredTweak = false;
local t = 0
local finish = false
local minute = 0
local second = 0
local cent = 0

function tweaks.onInitAPI()
	registerEvent(tweaks, "onStart", "onStart", false)
	registerEvent(tweaks, "onTick", "onTick", false)
	registerEvent(tweaks, "onDraw", "onDraw", false)
	registerEvent(tweaks, "onLoadSection", "onLoadSection", false)
	registerEvent(tweaks, "onNPCKill", "onNPCKill", false)
end

-- Setup --
local tweakFile = 0;
local haveTweaks = false
if Misc.resolveFile("tweaks.ini") ~= nil then
	haveTweaks = true
	tweakFile = configFileReader.parseTxt("tweaks.ini")
end

local autoscrollSpeed = 0;
local autoscrollDirection = 0;

if haveTweaks then
	autoscrollSpeed = {tweakFile.section1Speed,tweakFile.section2Speed,tweakFile.section3Speed,tweakFile.section4Speed,tweakFile.section5Speed,tweakFile.section6Speed,tweakFile.section7Speed,tweakFile.section8Speed,tweakFile.section9Speed,tweakFile.section10Speed,tweakFile.section11Speed,tweakFile.section12Speed,tweakFile.section13Speed,tweakFile.section14Speed,tweakFile.section15Speed,tweakFile.section16Speed,tweakFile.section17Speed,tweakFile.section18Speed,tweakFile.section19Speed,tweakFile.section20Speed,tweakFile.section21Speed}
	autoscrollDirection = {tweakFile.section1Direction,tweakFile.section2Direction,tweakFile.section3Direction,tweakFile.section4Direction,tweakFile.section5Direction,tweakFile.section6Direction,tweakFile.section7Direction,tweakFile.section8Direction,tweakFile.section9Direction,tweakFile.section10Direction,tweakFile.section11Direction,tweakFile.section12Direction,tweakFile.section13Direction,tweakFile.section14Direction,tweakFile.section15Direction,tweakFile.section16Direction,tweakFile.section17Direction,tweakFile.section18Direction,tweakFile.section19Direction,tweakFile.section20Direction,tweakFile.section21Direction,}
end
	
-- Apply tweaks --
function tweaks.onStart()
	if haveTweaks then
		if tweakFile.startingCharacter ~= nil then
			player.character = tweakFile.startingCharacter;
		end
		if tweakFile.startingPowerup ~= nil then
			player.powerup = tweakFile.startingPowerup;
		end
		if tweakFile.filterReserveBox == 1 then
			player:mem(0x158,FIELD_WORD,0)
		end
		if tweakFile.fallSpeedModifier ~= nil then
			Defines.gravity = Defines.gravity * tweakFile.fallSpeedModifier;
		end
		if tweakFile.playerGravModifier ~= nil then
			Defines.player_grav = Defines.player_grav * tweakFile.playerGravModifier;
		end
		if tweakFile.npcGravModifier ~= nil then
			Defines.npc_grav = Defines.npc_grav * tweakFile.npcGravModifier;
		end
		if tweakFile.startingMount ~= nil then
			player:mem(0x108,FIELD_WORD,tweakFile.startingMount)
		end
		if tweakFile.startingMountColor ~= nil then
			player:mem(0x10A,FIELD_WORD,tweakFile.startingMountColor)
		end
		if tweakFile.jumpModifier ~= nil then
			Defines.jumpheight = Defines.jumpheight * tweakFile.jumpModifier;
		end
		if tweakFile.bounceModifier ~= nil then
			Defines.jumpheight_bounce = Defines.jumpheight_bounce * tweakFile.bounceModifier;
		end
		if tweakFile.timer ~= nil then
			timerApi.activate(tweakFile.timer);
		end
		if tweakFile.useNSMBHitSystem == 1 then
			local altpsystem = require("altpsystem")
			altpsystem.usingSystem = altpsystem.SYSTEM_DS
		end
		if tweakFile.smwCamera == 1 then
			local SMWcamera = require("Tweaks//SMWcamera")
		end
		if tweakFile.breathMeter == 1 then
			local LsBreathMeter = require("LsBreathMeter")
			LsBreathMeter.hudBreath(true)
		end
		if tweakFile.showHud == 0 then
			hud(false)
		end
		if tweakFile.showDeaths == 1 then
			local deathTracker = require("deathTracker")
		end
	end
end

function tweaks.onTick()
	if haveTweaks then
	
		if tweakFile.speedrunTimer == 1 then
			if not finish then
				t = t + 1
			end

			minute = math.floor(t/(60000/15.6))
			if minute < 10 then
				minute = "0"..tostring(minute)
			else
				minute = tostring(minute)
			end

			second = math.floor((t/(1000/15.6))) % 60
			if second < 10 then
				second = "0"..tostring(second)
			else
				second = tostring(second)
			end

			cent = math.floor((100 * t/(1000/15.6))) %100   
			if cent < 10 then
				cent = "0"..tostring(cent)
			else
				cent = tostring(cent)
			end
		end
	end
end

function tweaks.onDraw()
	if haveTweaks then
		if tweakFile.speedrunTimer == 1 then
			Text.print("(-- "..minute..":"..second.."."..cent.." --)" ,3,259,77)
			Text.print("(-- "..minute..":"..second.."."..cent.." --)" ,3,259,75)
		end
	end
end

function tweaks.onNPCKill(eventObj,npc,killReason)
	if haveTweaks then
		if (npc.id == 11 or npc.id == 97 or npc.id == 16 or npc.id == 41 or npc.id == 197) and (tweakFile.speedrunTimer == 1) then
			finish = true
		end
	end
end

function tweaks.onLoadSection()
	if haveTweaks then
		if autoscrollSpeed[player.section+1] ~= nil then
			if autoscrollDirection[player.section+1] == 4 then
				autoscroll.scrollUp(tonumber(autoscrollSpeed[player.section+1]), nil, player.section)
			elseif autoscrollDirection[player.section+1] == 3 then
				autoscroll.scrollLeft(tonumber(autoscrollSpeed[player.section+1]), nil, player.section)
			elseif autoscrollDirection[player.section+1] == 2 then
				autoscroll.scrollDown(tonumber(autoscrollSpeed[player.section+1]), nil, player.section)
			else
				autoscroll.scrollRight(tonumber(autoscrollSpeed[player.section+1]), nil, player.section)
			end
		end
	end
end

return tweaks;