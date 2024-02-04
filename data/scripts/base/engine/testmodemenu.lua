----------------------
-- FFI DECLARATIONS --
----------------------
ffi.cdef[[
typedef struct _FFITestModePlayerSettings {
	short identity;
	short powerup;
	short mountType;
	short mountColor;
} FFITestModePlayerSettings;

typedef struct _FFITestModeSettings {
	int playerCount;
	bool showFPS;
	bool godMode;
	FFITestModePlayerSettings players[2];
	unsigned int entranceIndex;
    bool enabled;
    wchar_t* levelPath;
} FFITestModeSettings;

FFITestModeSettings* LunaLuaGetTestModeSettings(void);
void LunaLuaSetTestModeSettings(const FFITestModeSettings* pTestModeSettings);
void LunaLuaTestModeExit(void);
void LunaLuaTestModeRestart(void);
void LunaLuaTestModeContinue(void);
void LunaLuaTestModeSkip(void);
]]
local LunaDLL = ffi.load("LunaDll.dll")

-- Proof of concept?
local textplus = require("textplus")
local function textPrint(t, x, y, color)
	textplus.print{text=t, x=x, y=y, plaintext=true, xscale=2, yscale=2, color=color, priority = 10}
end

local function textPrintCentered(t, x, y, color)
	textplus.print{text=t, x=x, y=y, plaintext=true, pivot=vector.v2(0.5,0.5), xscale=2, yscale=2, color=color, priority = 10}
end

local function blink()
	return (lunatime.drawtick() % 32) < 15
end

local colorfilter = Shader()
local filterBuffer = Graphics.CaptureBuffer()

local controlConfigOpen = false
local controlConfigCount = 0
local controlConfigs = { 	[0] = "Press any button to start",
							"Jump",
							"Run",
							"Alt Jump",
							"Alt Run",
							"Drop Item",
							"Pause",
							"Press any button to confirm"
						}
						
local configButtons = 	{	
							{ img = 0, pos = vector.v2(64, 14) },
							{ img = 0, pos = vector.v2(44, -6) },
							{ img = 0, pos = vector.v2(84, -6) },
							{ img = 0, pos = vector.v2(64, -26) },
							{ img = 1, pos = vector.v2(-34, 2) },
							{ img = 1, pos = vector.v2(-6, 2) }
						}
						
local currentController = nil
local currentConfig = {}

local function writeButtonConfigs()
	if currentController == nil then
		return
	else
		local t = nil
		
		if currentController[2] == 2 then
			t = inputConfig2
		else
			t = inputConfig1
		end
		
		if t.inputType == 0 then
			return
		else
			t.jump = currentConfig[1]
			t.run = currentConfig[2]
			t.altjump = currentConfig[3]
			t.altrun = currentConfig[4]
			t.dropitem = currentConfig[5]
			t.pause = currentConfig[6]
			currentConfig = {}
		end
	end
	
end

--------------------
-- EVENT HANDLERS --
--------------------

local testModeMenu = {}
local allowContinue = true
local menus = {}
local selectedLine = 1
local selectedMenu = 1
local returnPressedState = false
local escPressedState = false
local entrances = {}
local camerapos
local playerpos

local selectedSetting = nil
local showRespawnLoc = false

testModeMenu.active = false

local skipActive = false

local function resetPosition()
	if playerpos ~= nil then
		player.x = playerpos.x
		player.y = playerpos.y
		player.section = playerpos.section
		playerpos = nil
	end
	if camerapos ~= nil then
		camera.x = camerapos.x
		camera.y = camerapos.y
		camerapos = nil
	end
end

local continueItem = {
	draw="Continue",
	activate=function()
		SFX.play(30)
		resetPosition()
		LunaDLL.LunaLuaTestModeContinue()
		testModeMenu.active = false
		
		-- Avoid jumping when continuing
		player:mem(0x11E, FIELD_WORD, 0)
		if player2 ~= nil and player2.isValid then
			player2:mem(0x11E, FIELD_WORD, 0)
		end
	end
}

local skipFrameItem = {
	draw="Skip Frame",
	activate=function()
		resetPosition()
		LunaDLL.LunaLuaTestModeSkip()
		testModeMenu.active = false
		
		-- Avoid jumping when skipping
		player:mem(0x11E, FIELD_WORD, 0)
		if player2 ~= nil and player2.isValid then
			player2:mem(0x11E, FIELD_WORD, 0)
		end
	end
}

local restartItem = {
	draw="Restart",
	activate=function()
		LunaDLL.LunaLuaTestModeRestart()
	end
}

local skipItem = {
	draw="Frame Advance",
	activate=function()
		skipActive = true
		showRespawnLoc = false
	end
}

local exitItem = {
	draw="Exit",
	activate=function()
		LunaDLL.LunaLuaTestModeExit()
	end
}


local function getMount(settings)
	local t = settings.mountType
	local c = settings.mountColor
	
	if t == 0 or t == 2 then
		return 0
	elseif t == 1 then
		return c
	elseif t == 3 then
		return 3+c
	end
end
				
local canuseyoshi
local noboots

local function populateMountslist()
	if canuseyoshi == nil then
		canuseyoshi = { 
						[CHARACTER_MARIO] = true, 
						[CHARACTER_LUIGI] = true, 
						[CHARACTER_WARIO] = true,
						[CHARACTER_ZELDA] = true,
						[CHARACTER_UNCLEBROADSWORD] = true
					}
		noboots = 	{
						[CHARACTER_LINK] = true,
						[CHARACTER_BOWSER] = true,
						[CHARACTER_SNAKE] = true,
						[CHARACTER_SAMUS] = true
					}
	end
end
				
local function setMount(settings, n)
	local maxmt = 11
	
	if not canuseyoshi[settings.identity] then
		maxmt = 3
	end
	
	if noboots[settings.identity] then
		maxmt = 0
	end

	if n > maxmt then
		n = 0
	elseif n < 0 then
		n = maxmt
	end
	
	local t
	local c
	
	if n == 0 then
		t = 0
		c = 0
	elseif n < 4 then
		t = 1
		c = n
	else
		t = 3
		c = n-3
	end
	
	settings.mountType = t
	settings.mountColor = c
end

local function selectObj(self)
	selectedSetting = self
end

local function drawSelector(self, x, y, m, mult)
	mult = mult or 8.5
	if selectedSetting == self then
		textPrint("<", x+32,y)
		textPrint(">", x+32+#tostring(m)*mult + 42,y)
	end
			
	textPrint(m, x+58,y)
end

local idItem = {
	draw=function(self, x, y, settings)
			Graphics.drawImageWP(Graphics.sprites.hardcoded["30-6"].img, x, y, 0, 0, 16, 16, 10)
			drawSelector(self, x, y, settings.identity)
		end,
	activate=selectObj,
	get=function(settings)
		return settings.identity
	end,
	set=function(settings, n)
		if n > 16 then 
			n = 1
		elseif n < 1 then 
			n = 16
		end
		settings.identity = n
		
		setMount(settings, getMount(settings))
	end
}

local powerupItem = {
	draw=function(self, x, y, settings)
			Graphics.drawImageWP(Graphics.sprites.hardcoded["30-6"].img, x, y, 0, 16, 16, 16, 10)
			drawSelector(self, x, y, settings.powerup)
		end,
	activate=selectObj,
	get=function(settings)
		return settings.powerup
	end,
	set=function(settings, n)
		if n > 7 then 
			n = 1
		elseif n < 1 then 
			n = 7
		end
		settings.powerup = n
	end
}

local mountItem = {
	draw=function(self, x, y, settings)
			if not noboots[settings.identity] then
				Graphics.drawImageWP(Graphics.sprites.hardcoded["30-6"].img, x, y, 0, 32, 16, 16, 10)
				drawSelector(self, x, y, getMount(settings))
			end
		end,
	activate=selectObj,
	get = getMount,
	set = setMount
}


local playerCountItem = {
							draw=function(self, x, y, settings)
								textPrint("Players", x, y)
								drawSelector(self, x + 48, y, settings.playerCount)
							end,
							activate=selectObj,
							get=function(settings)
								return settings.playerCount
							end,
							set=function(settings, n)
								if n > 2 then 
									n = 1
								elseif n < 1 then 
									n = 2
								end
								settings.playerCount = n
							end
						}
	
local checkpoints

local startingViaCheckpoint = (mem(0x00B250B0, FIELD_STRING) == mem(0x00B2C618, FIELD_STRING))
local hasVanillaMidpoint = nil
local vanillamppos

function testModeMenu.onStart()
	local n = NPC.get(192)
    hasVanillaMidpoint = startingViaCheckpoint or (#n > 0)
	if #n > 0 then
		vanillamppos = {x = n[1].x + n[1].width * 0.5, y = n[1].y + n[1].height * 0.5, section = n[1]:mem(0x146, FIELD_WORD)}
	elseif startingViaCheckpoint then
		vanillamppos = {x = player.x + player.width*0.5, y = player.y - 32, section = player.section}
	end
end

local function getEntranceListIndexBySettings(settings)
	local activecheckpoint = checkpoints.getActive()
	local activemidpoint = (activecheckpoint == nil and mem(0x00B250B0, FIELD_STRING) == mem(0x00B2C618, FIELD_STRING))
	
	for i,v in ipairs(entrances) do
		if ((v.warp ~= 0 or (activecheckpoint == nil and not activemidpoint)) and v.warp == settings.entranceIndex) 
		or (settings.entranceIndex == 0 and (v.checkpoint ~= nil and (v.checkpoint == activecheckpoint or (activemidpoint and v.checkpoint == 0)))) then
			return i
		end
	end
	return 1
end
local entranceIndexItem = {
							draw=function(self, x, y, settings)
								local n = getEntranceListIndexBySettings(settings)
								textPrint("Start at", x, y)
								drawSelector(self, x + 48, y, entrances[n].name)
							end,
							activate=selectObj,
							get=getEntranceListIndexBySettings,
							set=function(settings, n)
								if n > #entrances then 
									n = 1
								elseif n < 1 then 
									n = #entrances
								end
								
								if entrances[n].warp == nil then
									settings.entranceIndex = 0
								else
									settings.entranceIndex = entrances[n].warp
								end
								
								if entrances[n].checkpoint ~= nil then
									mem(0x00B250B0, FIELD_STRING, mem(0x00B2C618, FIELD_STRING))
									if entrances[n].checkpoint ~= 0 then
										cdata = GameData.__checkpoints[Level.filename()]
										if cdata.current ~= nil then
											cdata[tostring(cdata.current)] = nil
										end
										cdata[tostring(entrances[n].checkpoint.id)] = true
										cdata.current = entrances[n].checkpoint.id
									end
								else
									checkpoints.reset()
									mem(0x00B250B0, FIELD_STRING, "")
								end
							end
						}
						
local colorFilters = 	{ 

							{ name = "None" }, 
							{ name = "Protanopia", 		matrix = vector.mat3(0.56667, 0.55833, 0,  		0.43333, 0.44167, 0.24167, 		0,     0,       0.75833) 	},
							{ name = "Protanomaly", 	matrix = vector.mat3(0.81667, 0.33333, 0,  		0.18333, 0.66667, 0.125, 		0,     0,       0.875) 		},
							{ name = "Deuteranopia", 	matrix = vector.mat3(0.625,   0.70,    0,  		0.375,   0.30,    0.30, 		0,     0,       0.70) 		},
							{ name = "Deuteranomaly", 	matrix = vector.mat3(0.80,    0.25833, 0,  		0.20,    0.74167, 0.14167, 		0,     0,       0.85833) 	},
							{ name = "Tritanopia", 		matrix = vector.mat3(0.95,    0,       0,  		0.05,    0.43333, 0.475, 		0,     0.56667, 0.525) 		},
							{ name = "Tritanomaly", 	matrix = vector.mat3(0.96667, 0,       0,  		0.03333, 0.73333, 0.18333, 		0,     0.26667, 0.81667) 	},
							{ name = "Achromatopsia", 	matrix = vector.mat3(0.299,   0.299,   0.299,   0.587,   0.587,   0.587, 		0.114, 0.114,   0.114) 		},
							{ name = "Achromatomaly", 	matrix = vector.mat3(0.618,   0.163,   0.163,   0.32,    0.775,   0.32, 		0.062, 0.062,   0.516) 		}
							
						}

local colorFilterItem = {
							draw=function(self, x, y, settings)
								textPrint("Filter", x, y)
								drawSelector(self, x + 48, y, colorFilters[GameData.__testMenu.colorfilter + 1].name, 8.9)
							end,
							activate=selectObj,
							get=function(settings)
								return GameData.__testMenu.colorfilter + 1
							end,
							set=function(settings, n)
								if n > #colorFilters then 
									n = 1
								elseif n < 1 then 
									n = #colorFilters
								end
								GameData.__testMenu.colorfilter = n - 1
							end
						}
						


local controlConfigItem = {
							draw="Calibrate Controller",
							activate=function()
								controlConfigOpen = true
								controlConfigCount = 0
								currentController = nil
							end
						}
					
						
function testModeMenu.onStartTestModeMenu(newAllowContinue, skipEnded)
	camerapos = {x = camera.x, y = camera.y}
	playerpos = {x = player.x, y = player.y, section = player.section}
	showRespawnLoc = false
	
	GameData.__testMenu = GameData.__testMenu or {}
	GameData.__testMenu.colorfilter = GameData.__testMenu.colorfilter or 0
	allowContinue = newAllowContinue
	testModeMenu.active = true
	escPressedState = false

	-- If returning from end of skip, old menu state is mostly fine, but update camerapos/playerpos above and such
	if (skipEnded) then
		return
	end

	-- Check entrances
	entrances = {}
	entrances[#entrances+1] = {warp=0, name="Start"} -- Default
	
	
	if checkpoints == nil then
		checkpoints = require("base/checkpoints")
	end
	
	local cpcount = 0
	for i,v in ipairs(checkpoints.get()) do
		entrances[#entrances+1] = {checkpoint=v, name="Checkpoint "..i}
		cpcount = cpcount + 1
	end
	
	--1.3 checkpoints are only valid if there are no Lua checkpoints 
	if cpcount == 0 then
		if hasVanillaMidpoint then
			entrances[#entrances+1] = {checkpoint=0, name="Midpoint"}
		end
	end
	
	for i,v in ipairs(Warp.get()) do
		local warpType = v.warpType
		 
		 -- Only warp types 1 & 2 are valid to enter the level via (not 0)
		 if (warpType == 1) or (warpType == 2) then
			entrances[#entrances+1] = {warp=i, name="Warp "..i}
		 end
	end
	-- TODO: Detect midpoints/multipoints and add to 'entrances' table, with appropriate logic added to entranceIndexItem
	
	-- Build menu lines
	local main = { width = 250, settingsIdx = nil }
	
	if (allowContinue) then
		main[#main+1] = continueItem
	end
	main[#main+1] = restartItem
	main[#main+1] = playerCountItem
	if (#entrances > 1) then
		-- Only show "Start at" when there are more than one option
		main[#main+1] = entranceIndexItem
	end
	main[#main+1] = colorFilterItem
	if (allowContinue) then
		main[#main+1] = skipItem
	end
	main[#main+1] = controlConfigItem
	main[#main+1] = exitItem
	
	
	local p1 = { width = 100, settingsIdx = 0 }
	
	p1[#p1+1] = idItem
	p1[#p1+1] = powerupItem
	p1[#p1+1] = mountItem
	
	
	local p2 = { width = 110, settingsIdx = 1 }
	
	p2[#p2+1] = table.clone(idItem)
	p2[#p2+1] = table.clone(powerupItem)
	p2[#p2+1] = table.clone(mountItem)
	
	
	menus[1] = main
	menus[2] = p1
	menus[3] = p2
	
	-- Set state
	selectedMenu = 1
	selectedLine = 1
	returnPressedState = false
	
	SFX.play(30)
end

local playerManager

--[[ --Keeping this around just because it provides useful insight
local function updateHeight(p)
	local basechar = playerManager.getBaseID(p.character)
	local mountSettings = PlayerSettings.get(basechar, 2)
	local useduck = p:mem(0x12E, FIELD_BOOL)
	if p.mount == 1 then
		if basechar == CHARACTER_TOAD or basechar == CHARACTER_PEACH then
			if useduck then
				p.height = 30
			else
				p.height = 54
			end
		else
			if useduck then
				p.height = mountSettings.hitboxDuckHeight
			else
				p.height = mountSettings.hitboxHeight
			end
		end
	elseif p.mount == 3 then
		if useduck then
			p.height = 31
		elseif p.powerup == 1 then
			p.height = mountSettings.hitboxHeight
		else
			p.height = 60
		end
	end
end
--]]


--TODO: UNCOMMENT THIS BLOCK WHEN HITBOXES ARE PROPERLY SEPARATED AND PLAYERSETTINGS WORKS PROPERLY.
--[[
local function getHeight(settings)
	local basechar = playerManager.getBaseID(settings.identity)
	local mountSettings = PlayerSettings.get(basechar, 2)
	if settings.mountType == 1 then
		if basechar == CHARACTER_TOAD or basechar == CHARACTER_PEACH or (settings.powerup == 1 and basechar == CHARACTER_LUIGI) then
			return 54
		else
			return mountSettings.hitboxHeight
		end
	elseif settings.mountType == 3 then
		if settings.powerup == 1 then
			return mountSettings.hitboxHeight
		else
			return 60
		end
	end
	return nil
end

local function drawPlayerFrame(x,y,framex,framey,settings)
	local basechar = playerManager.getBaseID(settings.identity)
	local ps = PlayerSettings.get(basechar, settings.powerup)
	local xOffset = ps:getSpriteOffsetX(framex, framey)
	local yOffset = ps:getSpriteOffsetY(framex, framey)
	
	local h = getHeight(settings)
	if h == nil then
		h = ps.hitboxHeight
	end
	
	local dh = 100
	local yshift = 0
	if settings.mountType == 1 then
		dh = h-26-yOffset
	elseif settings.mountType == 3 then
		yshift = h-72
		Graphics.drawImageWP(Graphics.sprites.yoshib[settings.mountColor].img, x - 16, y + 26, 0, 224, 32, 32, 10)
		Graphics.drawImageWP(Graphics.sprites.yoshit[settings.mountColor].img, x + 4, y - 4, 0, 160, 32, 32, 10)
	end
		
	Graphics.drawImageWP(Graphics.sprites[playerManager.getName(settings.identity)][settings.powerup].img, math.floor(x + xOffset - ps.hitboxWidth*0.5), math.floor(y + yOffset + yshift + 56 - h), framex*100, framey*100, 100, dh, 10)
	
	if settings.mountType == 1 then
		Graphics.drawImageWP(Graphics.sprites.hardcoded["25-"..settings.mountColor].img, x - 16, y + 56 - 30, 0, 64, 32, 32, 10)
	end
end

local function drawPlayer(x,y, settings)

	if playerManager == nil then
		playerManager = require("playerManager")
	end

	if settings.mountType == 3 then
		drawPlayerFrame(x,y,7,9,settings)
	else
		drawPlayerFrame(x,y,5,0,settings)
	end
end
--]]
	
	

local function setHeight(p, powerup, mount)
	local basechar = playerManager.getBaseID(p.character)
	local mountSettings = PlayerSettings.get(basechar, 2)
	if mount == 1 then
		if basechar == CHARACTER_TOAD or basechar == CHARACTER_PEACH or (powerup == 1 and basechar == CHARACTER_LUIGI) then
			p.height = 54
		else
			p.height = mountSettings.hitboxHeight
		end
	elseif mount == 3 then
		if powerup == 1 then
			p.height = mountSettings.hitboxHeight
		else
			p.height = 60
		end
	end
	return mount == 1 or mount == 3
end

local function drawPlayer(x,y, settings)

	if playerManager == nil then
		playerManager = require("playerManager")
	end

	local f = 1
	if settings.mountType == 3 then
		f = 30
	end
	--[[
	local c = player.character
	local p = player.powerup
	local mt = player.mount
	local mc = player.mountColor
	player.character = settings.identity
	player.powerup = settings.powerup
	player.mount = settings.mountType
	player.mountColor = settings.mountColor
	]]
	
	local mountyoffset = player:mem(0x10E,FIELD_WORD)
	local mountbodyy = player:mem(0x78, FIELD_WORD)
	local mountheadxoffset = player:mem(0x6E,FIELD_WORD)
	local mountheadyoffset = player:mem(0x70,FIELD_WORD)
	
	local oldheight = player.height
	
	local oldheight2
	if player2 ~= nil and player2.isValid then
		oldheight2 = player2.height
	end
	
	local oldchar = player.character
	
	if settings.mountType == 3 then
		if player.mount == 3 and player.direction == 1 then
			player:mem(0x6E,FIELD_WORD,16)
		else
			player:mem(0x6E,FIELD_WORD,-24)
		end
		if settings.powerup == 1 then
			player:mem(0x78, FIELD_WORD, 24)
			player:mem(0x10E,FIELD_WORD, -18)
			player:mem(0x70,FIELD_WORD, -8)
		else
			player:mem(0x78, FIELD_WORD, 30)
			player:mem(0x10E,FIELD_WORD, -12)
			player:mem(0x70,FIELD_WORD, -2)
		end
	else
		player:mem(0x10E,FIELD_WORD,0)
	end	
	
	player.character = settings.identity
	
	
	
	if player.character ~= oldchar then
		playerManager.refreshHitbox(player.character)
	end
	local basechar = playerManager.getBaseID(player.character)
	local ps = PlayerSettings.get(basechar, settings.powerup)
	
	local h
	
	
	
	--[[
	local mountSettings = PlayerSettings.get(basechar, 2)
	
	if settings.mountType == 1 then
		h = mountSettings.hitboxHeight
	elseif settings.mountType == 3 then
		if settings.powerup == 1 then
			h = mountSettings.hitboxHeight
		else
			h = 60
		end
	end
	]]
	
	local baseheight = player.height
	
	if setHeight(player, settings.powerup, settings.mountType) then
		h = player.height
	else
		h = ps.hitboxHeight
	end
	local mf = player:mem(0x110, FIELD_WORD)
	local headf = player:mem(0x72, FIELD_WORD)
	
	if player.mount ~= 3 then
		player:mem(0x110, FIELD_WORD, 2)
		player:mem(0x72, FIELD_WORD, 0)
	end
	player:render	{	x = x - ps.hitboxWidth*0.5, y = y + 56 - h, 
						frame = f, direction = 1, sceneCoords=false, priority=1, 
						powerup = settings.powerup,
						mount = settings.mountType, mounttype = settings.mountColor,
						ignorestate = true,
						priority = 10
					}
	player:mem(0x110, FIELD_WORD, mf)
	player:mem(0x72, FIELD_WORD, headf)
	--[[
	player.character = c
	player.powerup = p
	player.mount = mt
	player.mountColor = mc
	]]
	
	player.height = baseheight
	
	player:mem(0x10E,FIELD_WORD, mountyoffset)
	player:mem(0x78, FIELD_WORD, mountbodyy)
	player:mem(0x6E,FIELD_WORD, mountheadxoffset)
	player:mem(0x70,FIELD_WORD, mountheadyoffset)
	
	
	player.character = oldchar
	
	playerManager.refreshHitbox(player.character)
	h = player.height
	player.height = oldheight
	
	player.y = player.y + h - player.height
	
	--I think this is necessary because of the hitbox modifications
	if player2 ~= nil and player2.isValid then
		playerManager.refreshHitbox(player2.character)
		
		h = player2.height
		player2.height = oldheight2
		
		player2.y = player2.y + h - player2.height
	end
	
end

local lockSelect = false

function testModeMenu.getScreenSize()
    if SMBX_VERSION == VER_SEE_MOD then
        return Graphics.getFramebufferSize()
    else
        return {800, 600}
    end
end

function testModeMenu.calculateCameraDimensions(value, isWidthOrHeight)
    if value == nil then
        error("Must have a value for Screen.calculateCameraDimensions!")
        return
    else
        if isWidthOrHeight == nil then
            error("Must have a width or height for Screen.calculateCameraDimensions! You must use a string value for this (Or a number), like e.g. \"width\" or \"height\", or 1 or 2.")
            return
        end
        local originalWidth = 800
        local originalHeight = 600
        
        local pixelDifferenceWidth = originalWidth / testModeMenu.getScreenSize()[1]
        local pixelDifferenceHeight = originalHeight / testModeMenu.getScreenSize()[2]
        
        local additionalWidth = testModeMenu.getScreenSize()[1] - originalWidth
        local additionalHeight = testModeMenu.getScreenSize()[2] - originalHeight
        
        local extendedWidth = additionalWidth / 2
        local extendedHeight = additionalHeight / 2
        
        if (isWidthOrHeight == "width" or isWidthOrHeight == 1) then
            return value + extendedWidth
        elseif (isWidthOrHeight == "height" or isWidthOrHeight == 2) then
            return value + extendedHeight
        else
            error("This is not a valid value for isWidthOrHeight. You must use a string value for this (Or a number), like e.g. \"width\" or \"height\", or 1 or 2.")
            return
        end
    end
end

function testModeMenu.onTestModeMenu()
	if controlConfigOpen then
		
		local w = 400
		local h = 256
		
		local xPos = testModeMenu.calculateCameraDimensions(400 - w*0.5, 1)
		local yPos = testModeMenu.calculateCameraDimensions(300 - h*0.5, 2)
		
		Graphics.drawBox{x = xPos, y = yPos - 20, width = w, height = h, color={0,0,0,0.5}, priority = 10}
		Graphics.drawImageWP(Graphics.sprites.hardcoded["57-0"].img, camera.width*0.5 - 128, 300 - 64 - 40, 10)
		
		textPrintCentered("Calibrate Controller", testModeMenu.calculateCameraDimensions(400, 1), yPos + 10)
		
		textPrintCentered(controlConfigs[controlConfigCount], testModeMenu.calculateCameraDimensions(400, 1), yPos + 160)
		
		if configButtons[controlConfigCount] then
			local v = configButtons[controlConfigCount]
			Graphics.drawImageWP(Graphics.sprites.hardcoded["57-1"].img, testModeMenu.calculateCameraDimensions(400 + v.pos.x, 1), testModeMenu.calculateCameraDimensions(300-40 + v.pos.y, 2), 0, 20*v.img, 20, 20, 10)
		end
		
		textPrintCentered("Press ESC to cancel", testModeMenu.calculateCameraDimensions(400, 1), yPos + 210)
		
		if escPressedState then
			controlConfigOpen = false
			SFX.play(30)
		end
	elseif skipActive then
		Graphics.drawBox{x = 0, y = 0, width = testModeMenu.getScreenSize()[1], height = 32, color={0,0,0,0.5}, priority = 10}
		textPrintCentered("Any Key - Advance      Pause - Back", testModeMenu.calculateCameraDimensions(400, 1), testModeMenu.calculateCameraDimensions(18, 2))
		if player.rawKeys.pause == KEYS_PRESSED then
			SFX.play(30)
			skipActive = false
		else
			for _,v in pairs(player.rawKeys) do
				if v == KEYS_PRESSED then
					SFX.play(71)
					LunaDLL.LunaLuaTestModeSkip()
					break
				end
			end
		end
	else
		
		populateMountslist()
		
		local testModeSettings = LunaDLL.LunaLuaGetTestModeSettings()
		
		local w = 0
		local h = 0
		
		local menuCount = 0
		
		for k,v in ipairs(menus) do
			if v.settingsIdx == nil then
				v.settings = testModeSettings
			else
				v.settings = testModeSettings.players[v.settingsIdx]
			end
			w = w + v.width
			h = math.max(h, #v)
			
			if v.settingsIdx == nil or v.settingsIdx+1 <= testModeSettings.playerCount then
				menuCount = menuCount + 1
			end
		end
		
		h = h*18 + 64 + 60
		w = w + 40
		
		local xPos = testModeMenu.calculateCameraDimensions(400 - w*0.5, 1)
		local yPos = testModeMenu.calculateCameraDimensions(300 - h*0.5, 2)
		
		Graphics.drawBox{x = xPos, y = yPos - 20, width = w, height = h, color={0,0,0,0.5}, priority = 10}
		
		
		xPos = xPos + 20
		yPos = yPos + 8
		
		for i=1,testModeSettings.playerCount do
			drawPlayer(xPos + 300 + (i-1)*menus[2].width, yPos, testModeSettings.players[i-1])
		end
		
		textPrint("Testing Menu", xPos + 20, yPos + 10)
		
		yPos = yPos + 64

		local returnPressed = returnPressedState
		returnPressedState = false
		
		local dirtySettings = false
		
		local maxLine = #menus[selectedMenu]
		
		if menus[selectedMenu].settingsIdx ~= nil and noboots[menus[selectedMenu].settings.identity] then
			maxLine = maxLine-1
		end
		
		if allowContinue and (escPressedState or ((player.rawKeys.pause == KEYS_PRESSED) and not ((inputConfig1.inputType == 0) and (inputConfig1.pause == VK_RETURN)))) then
			selectedSetting = nil
			skipActive = false
			showRespawnLoc = false
			SFX.play(30)
			resetPosition()
			LunaDLL.LunaLuaTestModeContinue()
			testModeMenu.active = false
		elseif selectedSetting == nil then
			if not lockSelect and ((player.rawKeys.jump == KEYS_PRESSED) or (player.rawKeys.altJump == KEYS_PRESSED) or (returnPressed)) then
				local item = menus[selectedMenu][selectedLine]
				if (item) and (item.activate) then
					item:activate()
					SFX.play(71)
				end
			elseif (player.rawKeys.up == KEYS_PRESSED) then
				selectedLine = selectedLine - 1
				if (selectedLine < 1) then
					selectedLine = maxLine
				end
				SFX.play(71)
			elseif (player.rawKeys.down == KEYS_PRESSED) then
				selectedLine = selectedLine + 1
				if (selectedLine > maxLine) then
					selectedLine = 1
				end
				SFX.play(71)
			elseif player.rawKeys.right == KEYS_PRESSED then
				if (selectedMenu < menuCount) then
					selectedMenu = math.min(selectedMenu + 1, menuCount)
					maxLine = #menus[selectedMenu]
					if (selectedLine > maxLine) then
						selectedLine = maxLine
					end
					SFX.play(71)
				end
			elseif player.rawKeys.left == KEYS_PRESSED then
				if (selectedMenu > 1) then
					selectedMenu = math.max(selectedMenu - 1, 1)	
					maxLine = #menus[selectedMenu]
					if (selectedLine > maxLine) then
						selectedLine = maxLine
					end
					SFX.play(71)
				end
			end
			
			if not allowContinue then
				showRespawnLoc = true
			elseif selectedMenu == 1 and selectedLine == 1 then
				showRespawnLoc = false
			end
			
		else
			
			if (selectedMenu == 1 and selectedLine == 4) or not allowContinue then
				showRespawnLoc = true
			end
			
			if not lockSelect and ((player.rawKeys.jump == KEYS_PRESSED) or (player.rawKeys.altJump == KEYS_PRESSED) or (returnPressed)) then
				selectedSetting = nil
				SFX.play(71)
			elseif player.rawKeys.right == KEYS_PRESSED then
				selectedSetting.set(menus[selectedMenu].settings, selectedSetting.get(menus[selectedMenu].settings)+1)
				dirtySettings = true
				SFX.play(71)
			elseif player.rawKeys.left == KEYS_PRESSED then
				selectedSetting.set(menus[selectedMenu].settings, selectedSetting.get(menus[selectedMenu].settings)-1)
				dirtySettings = true
				SFX.play(71)
			end
		end
			
		
		if lockSelect and ((player.rawKeys.jump == KEYS_RELEASED and not player.rawKeys.altJump) or (player.rawKeys.altJump == KEYS_RELEASED and not player.rawKeys.jump)) then	
			lockSelect = false
		end
		
		local x = xPos
		local y = yPos

		for k,v in ipairs(menus) do
			y = yPos
			if v.settingsIdx == nil or v.settingsIdx+1 <= testModeSettings.playerCount then
				for idx,text in ipairs(v) do
					
					if k == selectedMenu and idx == selectedLine and (selectedSetting or blink()) then
						local color = nil
						if (selectedSetting) then
							color = {1, 1, 0, 1}
						end
						textPrint(">", x, y, color)
					end
					if type(text.draw) == "string" then
						textPrint(text.draw, x+20, y)
					else
						text:draw(x+20, y, v.settings)
					end
					
					y = y + 20
				end
				x = x + v.width
			end
		end
		
		if dirtySettings then
			LunaDLL.LunaLuaSetTestModeSettings(testModeSettings)
		end
	end
	
	returnPressedState = false
	escPressedState = false
end

function testModeMenu.onKeyboardPressDirect(k, repeated)
	if repeated then return end
	
	if (k == VK_RETURN) then
		returnPressedState = true
	elseif (k == VK_ESCAPE) then
		escPressedState = true
	end
end

function testModeMenu.onControllerButtonPress(btn, pnum, controller)
	if controlConfigOpen then
		if controlConfigCount == 0 then
			currentController = { controller, pnum }
			controlConfigCount = 1
			return
		elseif currentController == nil then
			currentController = { controller, pnum }
		end
		
		if currentController[1] == controller and currentController[2] == pnum then
			if controlConfigCount < #controlConfigs then
				currentConfig[controlConfigCount] = btn
				controlConfigCount = controlConfigCount + 1
			else
				controlConfigOpen = false
				SFX.play(20)
				writeButtonConfigs()
				lockSelect = true
			end
		end
	end
end

local function getStartingPosition(idx)
    local GM_PLAYER_POS = mem(0xB25148, FIELD_DWORD)
    local x = mem(GM_PLAYER_POS+idx*48 + 0x0, FIELD_DFLOAT)
    local y = mem(GM_PLAYER_POS+idx*48 + 0x8, FIELD_DFLOAT)
    local h = mem(GM_PLAYER_POS+idx*48 + 0x10, FIELD_DFLOAT)
    local w = mem(GM_PLAYER_POS+idx*48 + 0x18, FIELD_DFLOAT)
    return x, y, w, h
end

function testModeMenu.onCameraUpdate(idx)
	if idx == 1 then
		if testModeMenu.active then
			local s
			
			if showRespawnLoc then
				local cp = checkpoints.getActive()
				if cp then
					camera.x = cp.x
					camera.y = cp.y
					
					s = cp.section
				else
					local settings = LunaDLL.LunaLuaGetTestModeSettings()
					
					if settings.entranceIndex > 0 then
						local w = Warp.get()[settings.entranceIndex]
						if w ~= nil and w.isValid then
							camera.x = w.exitX + 16
							camera.y = w.exitY + 16
						
							s = Section.getIdxFromCoords(w.exitX,w.exitY,32,32)
						else
							local px,py,pw,ph = getStartingPosition(0)
							camera.x = px + pw*0.5
							camera.y = py + ph*0.5
						
							s = Section.getIdxFromCoords(px,py,pw,ph)
						end
					elseif mem(0x00B250B0, FIELD_STRING) == mem(0x00B2C618, FIELD_STRING) then
						if vanillamppos then
							camera.x = vanillamppos.x
							camera.y = vanillamppos.y
							
							s = vanillamppos.section
						end
					else
						local px,py,pw,ph = getStartingPosition(0)
						camera.x = px + pw*0.5
						camera.y = py + ph*0.5
					
						s = Section.getIdxFromCoords(px,py,pw,ph)
					end
				end
			else
				if skipActive then
					camerapos.x = camera.x
					camerapos.y = camera.y
				end
				camera.x = camerapos.x + camera.width*0.5
				camera.y = camerapos.y + camera.height*0.5
				
				s = playerpos.section
			end
				
			if s then
				player.section = s
				local b = Section(s).boundary
				camera.x = math.clamp(camera.x - camera.width*0.5, b.left, b.right-camera.width)
				camera.y = math.clamp(camera.y - camera.height*0.5, b.top, b.bottom-camera.height)
			end
		end
	end
end

function testModeMenu.onCameraDraw(idx)
	if idx == 1 then
		if GameData.__testMenu ~= nil and GameData.__testMenu.colorfilter ~= nil and GameData.__testMenu.colorfilter > 0 then
			if not colorfilter._isCompiled then
				colorfilter:compileFromFile(nil, "shaders/colormatrix.frag")
			end
			filterBuffer:captureAt(10)
			Graphics.drawScreen{texture = filterBuffer, shader = colorfilter, uniforms = { matrix = colorFilters[GameData.__testMenu.colorfilter+1].matrix }, priority = 10 }
		end
	end
end

function testModeMenu.onFramebufferResize(width, height)
	filterBuffer = Graphics.CaptureBuffer(width, height)
end

registerEvent(testModeMenu, "onStart", "onStart", true)
registerEvent(testModeMenu, "onTick", "onTick", true)
registerEvent(testModeMenu, "onCameraDraw", "onCameraDraw", false)
registerEvent(testModeMenu, "onCameraUpdate", "onCameraUpdate", false)
registerEvent(testModeMenu, "onStartTestModeMenu", "onStartTestModeMenu", false)
registerEvent(testModeMenu, "onTestModeMenu", "onTestModeMenu", false)
registerEvent(testModeMenu, "onKeyboardPressDirect", "onKeyboardPressDirect", false)
registerEvent(testModeMenu, "onControllerButtonPress", "onControllerButtonPress", false)
registerEvent(testModeMenu, "onFramebufferResize", "onFramebufferResize", true)

return testModeMenu