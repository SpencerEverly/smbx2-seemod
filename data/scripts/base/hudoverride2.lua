-------------------HUDOverride-------------------
-------Created by Hoeloe and Enjl  - 2018--------
--SMBX HUD Defaults & Override System Library----
--------------For Super Mario Bros X-------------
----------------------v2.0-----------------------

local lunajson = require("ext/lunajson")

local HUDOverride = {}
Graphics.HUD = {}

local function read(filename)
	local f = io.open(filename, "r");
	if(f) then
		local content = f:read("*all");
		f:close();
		if(content ~= "") then
			return lunajson.decode(content);
		end
	end
	
	return {};
end

HUDOverride.priority = 4.999999;

Graphics.HUD_NONE = 0;
Graphics.HUD_HEARTS = 1;
Graphics.HUD_ITEMBOX = 2;

HUDOverride.BIND = {
	LEFT = 0,
	TOP = 0,
	MID = 0.5,
	CENTRE = 0.5,
	CENTER = 0.5,
	RIGHT = 1,
	BOTTOM = 1
}

HUDOverride.multiplayerOffsets = {[Graphics.HUD_NONE] = 0, [Graphics.HUD_ITEMBOX] = 40, [Graphics.HUD_HEARTS] = 57}

HUDOverride.activeCameras = nil
HUDOverride.activePlayers = nil

HUDOverride.splitOffset = {}

local oldActivate = Graphics.activateHud

function Graphics.activateHud(setActive)
	if type(setActive) == "boolean" then
		Graphics.HUD.enabled = setActive
	elseif setActive == nil then
		Graphics.HUD.enabled = not Graphics.HUD.enabled
	else
		error("No matching overload found. Candidates: Graphics.activateHud(bool setActive), Graphics.activateHud()", 2)
	end
end

function Graphics.isHudActivated()
	return Graphics.HUD.enabled
end

_G["hud"] = Graphics.activateHud


local charHUDActions =
{
	[CHARACTER_MARIO] = {type = Graphics.HUD_ITEMBOX},
	[CHARACTER_LUIGI] = {type = Graphics.HUD_ITEMBOX},
	[CHARACTER_TOAD] = {type = Graphics.HUD_HEARTS},
	[CHARACTER_PEACH] = {type = Graphics.HUD_HEARTS},
	[CHARACTER_LINK] = {type = Graphics.HUD_HEARTS, actions = drawLinkStuff, sprites = { coins = Graphics.sprites.hardcoded["33-6"] }}
}

function Graphics.registerCharacterHUD(characterID, hudType, actions, sprites)
	charHUDActions[characterID] = {type = hudType, actions = actions, sprites = sprites};
	if(hudType == Graphics.HUD_ITEMBOX) then
		if(sprites == nil or sprites.reserveBox2P == nil) then
			reserveBox2P[characterID] = reserveBox2P[1];
		else
			reserveBox2P[characterID] = sprites.reserveBox2P;
		end
	end
end

function Graphics.getHUDType(characterID)
	local c = charHUDActions[characterID];
	if(c) then
		return c.type;
	else
		return Graphics.HUD_NONE;
	end
end

function Graphics.getHUDActions(characterID)
	local c = charHUDActions[characterID];
	if(c) then
		return c.actions;
	else
		return nil;
	end
end

function Graphics.getHUDOffset(playerIdx, isSplit)
	if (#activePlayers > 1 and not isSplit) then
		local offset = HUDOverride.multiplayerOffsets[Graphics.getHUDType(activePlayers[playerIdx].character)];
		if(playerIdx == 1) then
			offset = -offset;
		end
		return offset;
	else
		return 0;
	end
end

local HUD = {}

local function getBounds(thisModule)
	local l,r,t,b
	
	for k,v in ipairs(thisModule._children) do
		local l2, r2, t2, b2 = v:getBounds()
		if l == nil or l2 < l then
			l = l2
		end
		if r == nil or r2 < r then
			r = r2
		end
		if t == nil or t2 < t then
			t = t2
		end
		if b == nil or b2 < b then
			b = b2
		end
	end
	
	return l,r,t,b
end

local function getSize(thisModule)
	local l,r,t,b = thisModule:getBounds()
	
	return r-l, t-b
end

local function getImage(img)
	if type(img) == "table" and img.img then
		return img.img
	else
		return img
	end
end

function HUDOverride.getDrawProperties(thisModule, thisPlayer, thisCam, priority, isSplit)
	local textIsNil = thisModule.text == nil
	local imageIsNil = thisModule.image == nil
	
	if textIsNil and imageIsNil then
		return
	end
	
	local img = getImage(thisModule.image)
	
	local drawProps = {}
	
	if (not textIsNil) then
		local count = #(tostring(thisModule.text))
		thisModule.width = count * 16 + (count-1) * 2
		thisModule.height = 16
	else
		thisModule.width = thisModule.width or img.width
		thisModule.height = thisModule.height or img.height
	end
	
	drawProps.x = thisCam.width * 0.5 + thisModule.worldX +
				  (HUDOverride.splitOffset[thisModule.splitOffset] or 0) -
				  thisModule.bindX * thisModule.width
				  
	drawProps.y = thisModule.worldY -
				  thisModule.bindY * thisModule.height
	drawProps.priority = priority
	
	if textIsNil then
		drawProps.type = RTYPE_IMAGE
		drawProps.image = img
		drawProps.width = thisModule.width
		drawProps.height = thisModule.height
		drawProps.sourceX = thisModule.sourceX
		drawProps.sourceY = thisModule.sourceY
		drawProps.opacity = thisModule.opacity
	elseif imageIsNil then
		drawProps.type = RTYPE_TEXT
		drawProps.text = thisModule.text
		drawProps.fontType = thisModule.fontType
	end
	return drawProps
end

local function drawHUDInternal(thisModule, thisPlayer, thisCam, priority, isSplit)
	local drawProps = HUDOverride.getDrawProperties(thisModule, thisPlayer, thisCam, priority, isSplit)
	if drawProps then
		Graphics.draw(drawProps)
	end
end

local function drawChildren(m, thisPlayer, thisCam, priority, isSplit)
	for k,v in ipairs(m.children) do
		if v.enabled then
			v.worldX = m.worldX + v.x
			v.worldY = m.worldY + v.y
			
			v:draw(thisPlayer, thisCam, HUDOverride.priority, isSplit)
			v:_drawChildren(thisPlayer, thisCam, HUDOverride.priority, isSplit)
		end
	end
end

function HUDOverride.resolveJson(filename)
	return Misc.multiResolveFile("config/hud/".. filename, filename)
end

local function register(parentModule, name, stringKeyOrNamespace)
	parentModule = parentModule or HUD
	if (parentModule[name]) then
		error("Object " .. name .. " is already registered to this module.")
		return
	end
	
	local newModule = {}
	local moduleType = type(stringKeyOrNamespace)
	
	if moduleType == "table" then
		newModule = stringKeyOrNamespace
	elseif moduleType == "string" then
		newModule = read(HUDOverride.resolveJson(stringKeyOrNamespace))
	end
	
	newModule.children = {_parent = newModule}
	newModule._childSet = {}
	
	newModule.register = register
	newModule.deregister = deregister
	
	for k,v in pairs(newModule) do
		if type(v) == "table" and v.module then
			newModule[k] = nil
			newModule:register(k, v)
		end
	end
	
	if type(newModule.image) == "string" then
		newModule.image = Misc.resolveFile(newModule.image) or Graphics.sprites.hardcoded[newModule.image]
	end
	
	--shortcut
	newModule.enabled = newModule.enabled
	if newModule.enabled == nil then newModule.enabled = true end
	
	newModule.x = newModule.x or 0
	newModule.y = newModule.y or 0
	newModule.bindX = newModule.bindX or HUDOverride.BIND.LEFT
	newModule.bindY = newModule.bindY or HUDOverride.BIND.TOP
	newModule.splitOffset = newModule.splitOffset or 0
	
	newModule.draw = drawHUDInternal
	
	if moduleType == "table" then	
		if stringKeyOrNamespace.drawHUD then		
			registerCustomEvent(stringKeyOrNamespace, "drawHUD")
			newModule.draw = stringKeyOrNamespace.drawHUD
		end
	end
	
	newModule._drawChildren = drawChildren
	setmetatable(newModule, {__index = newModule._children})
	
	table.insert(parentModule.children, newModule)
	parentModule._childSet[name] = newModule
	
	return newModule
end

local function deregister (parentModule, name)
	local parent = parentModule or HUD
	if (not parent[name]) then
		error(name .. "not found in specified module.")
	end
	local childIdx = 0
	for k,v in pairs(parentModule._childSet) do
		if k == name then
			break
		end
		childIdx = childIdx + 1
	end
	
	table.remove(parentModule.children, childIdx)
	parentModule._childSet[name] = nil
end

function HUDOverride.onDraw()
	HUDOverride.activeCameras = Camera.get()
	HUDOverride.activePlayers = Player.get()
end

function HUDOverride.onHUDDraw(camIdx)
	
	local thisPlayer = HUDOverride.activePlayers[camIdx]
	local thisCam = HUDOverride.activeCameras[camIdx]
	
	local isSplit = (thisCam.width < 800) or (thisCam.height < 600)
	HUDOverride.splitOffset = {0,0}

	if #HUDOverride.activePlayers > 1 and not isSplit then
		HUDOverride.splitOffset[1] = -HUDOverride.multiplayerOffsets[Graphics.getHUDType(HUDOverride.activePlayers[1].character)];
		HUDOverride.splitOffset[2] = HUDOverride.multiplayerOffsets[Graphics.getHUDType(HUDOverride.activePlayers[2].character)]
		for i=1, 2 do
			local acts = Graphics.getHUDActions(HUDOverride.activePlayers[i].character);
			if(acts) then
				acts(i, thisCam, HUDOverride.activePlayers[i], priority, isSplit, #HUDOverride.activePlayers);
			end
		end
	else
		local acts = Graphics.getHUDActions(thisPlayer.character);
		if(acts) then
			acts(camIdx, thisCam, thisPlayer, priority, isSplit, #activePlayers);
		end
	end
		
	if HUD.enabled then
		HUD:_drawChildren(thisPlayer, thisCam, HUDOverride.priority, isSplit)
	end
end

function HUDOverride.onInitAPI()
	--TODO: Change onHUDDraw to "true" when onHUDUpdate is implemented
	registerEvent(HUDOverride, "onHUDDraw", "onHUDDraw", false)
	registerEvent(HUDOverride, "onDraw", "onDraw", false)

	if(oldActivate) then
		--oldActivate(false)
	end

	SaveData._basegame = SaveData._basegame or {}

	if SaveData._basegame.hud == nil then
		SaveData._basegame.hud = {}
		SaveData._basegame.hud.score = 0
		SaveData._basegame.starcoin = {}
	end
	
	do
		local baseModule = {}
		baseModule.enabled = true
		baseModule.children = {_parent = baseModule}
		baseModule._childSet = {}
		
		setmetatable(baseModule, {__index = baseModule._children})
		
		--shortcut
		baseModule.register = register
		baseModule.deregister = deregister
		
		baseModule._drawChildren = drawChildren
		baseModule.x = 0
		baseModule.y = 0
		baseModule.worldX = 0
		baseModule.worldY = 0
		
		HUD = baseModule
	end
	
	Graphics.HUD = HUD:register("_basegame", "_default.json")
	
	local hud_coins = require("hud/coins")
	--[[
	local hud_items = require("hud/itembox")
	local hud_keys = require("hud/keys")
	local hud_lives = require("hud/lives")
	local hud_map = require("hud/overworld")
	local hud_score = require("hud/score")
	local hud_starcoins = require("hud/starcoins")
	local hud_stars = require("hud/stars")
	local hud_bombs = require("hud/bombs")
	]]
end

return HUDOverride
